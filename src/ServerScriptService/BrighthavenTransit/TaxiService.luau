local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local HttpService=game:GetService("HttpService")
local Fleet=require(script.Parent:WaitForChild("TransitFleet"))
local Lanes=require(script.Parent:WaitForChild("LaneNetwork")).ForTaxi()
local Money=require(game.ServerScriptService.Brighthaven:WaitForChild("MoneyService"))
local Locations=require(ReplicatedStorage.Brighthaven:WaitForChild("MapLocations"))
local Practice=require(ReplicatedStorage.Brighthaven.TutorialPractice)
local FARE=Money.Fare
local Service={}
local rides,limits,busy={},{},{}
local notice=ReplicatedStorage.Brighthaven.Transit:WaitForChild("TaxiNotice")
local templates=game.ServerStorage:WaitForChild("BrighthavenTaxiTemplates")
local function flat(point) return Vector3.new(point.X,0,point.Z) end
local function message(player,text)
    if player.Parent then player:SetAttribute("TaxiMessage",text) end
end
local function state(ride,value)
    ride.State=value;ride.Player:SetAttribute("TaxiState",value)
    if ride.Vehicle then ride.Vehicle:SetAttribute("TaxiState",value) end
    if ride.Prompt then ride.Prompt.Enabled=value=="Waiting" end
end
local function curb(point,direction)
    local sidewalks=workspace:FindFirstChild("BrighthavenSidewalks")
    if not sidewalks then return nil end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={sidewalks}
    local right=CFrame.lookAt(point,point+direction).RightVector
    for _,offset in ipairs({6,8,10,12,15,18,21,24,27,30,34,38,42}) do
        local p=point+right*offset
        local hit=workspace:Raycast(Vector3.new(p.X,-90,p.Z),Vector3.new(0,-85,0),params)
        if hit then return hit.Position end
    end
end
function Service.Stops(position,maxGap)
    local candidates={}
    for _,edge in ipairs(Lanes.SpawnEdges) do
        local delta=edge.Finish-edge.Start
        if delta.Magnitude>32 then
            local t=math.clamp((flat(position)-edge.Start):Dot(delta)/delta:Dot(delta),.08,.92)
            local point=edge.Start+delta*t
            local stop=curb(point,edge.Direction)
            local gap=stop and (flat(stop)-flat(position)).Magnitude
            if gap and gap<(maxGap or 250) then table.insert(candidates,{Position=point,Direction=edge.Direction,Curb=stop,Gap=gap,Edge=edge}) end
        end
    end
    table.sort(candidates,function(a,b) return a.Gap<b.Gap end)
    return candidates
end
local function exitFrame(ride,point)
    local h,root=ride.Humanoid,ride.Character:FindFirstChild("HumanoidRootPart")
    local leg=h.RigType==Enum.HumanoidRigType.R6 and ride.Character:FindFirstChild("Left Leg")
    local height=h.HipHeight+(root and root.Size.Y/2 or 1)+(leg and leg.Size.Y or 0)+.2
    return CFrame.lookAt(point+Vector3.new(0,height,0),point+Vector3.new(0,height,0)+ride.Vehicle:GetPivot().LookVector)
end
local function finish(ride,arrived,refund,point)
    if rides[ride.Player]~=ride or ride.Finishing then return end
    ride.Finishing=true
    local player=ride.Player
    for _,connection in ipairs(ride.Connections) do connection:Disconnect() end
    local h=ride.Humanoid
    if h and h.Parent then
        local weld=ride.Seat and ride.Seat:FindFirstChild("SeatWeld")
        if weld then weld:Destroy() end
        h.Sit=false;h.AutoRotate=ride.AutoRotate;h.WalkSpeed=ride.WalkSpeed
        if ride.WalkSpeed==16 or ride.WalkSpeed==26 then h.WalkSpeed=player:GetAttribute("Sprinting") and 26 or 16 end
        h:SetStateEnabled(Enum.HumanoidStateType.Jumping,ride.Jumping)
        local root=ride.Character:FindFirstChild("HumanoidRootPart")
        if point and root and h.Health>0 and player.Character==ride.Character then
            local destination=exitFrame(ride,point)
            local oldAnchored=root.Anchored
            root.Anchored=true;root.CFrame=destination
            root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
            notice:FireClient(player,"Exit",destination,ride.Character)
            task.delay(.3,function()
                if root.Parent then
                    if player.Character==ride.Character then root.CFrame=destination end
                    root.Anchored=oldAnchored
                    if not oldAnchored and root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto() end
                end
            end)
        end
    end
    local refunded=false
    if refund and ride.Paid then
        refunded=Money.Change(player,FARE,"ride:refund:"..ride.Id)
        if not refunded then warn("[BrightHaven Taxi] Refund could not save",player.UserId,ride.Id) end
    end
    rides[player]=nil
    player:SetAttribute("BrighthavenRiding",nil);player:SetAttribute("BrighthavenRideVehicle",nil)
    player:SetAttribute("BrighthavenRideWaiting",nil);player:SetAttribute("TaxiState",nil);player:SetAttribute("TaxiDestination",nil)
    player:SetAttribute("TaxiKind",nil);player:SetAttribute("TaxiVehicle",nil)
    player:SetAttribute("TaxiApproachLength",nil);player:SetAttribute("TaxiPickupRevision",nil)
    player:SetAttribute("TaxiPickupPosition",nil);player:SetAttribute("TaxiDestinationId",nil)
    if arrived and ride.Destination.Id=="school" then player:SetAttribute("SchoolShuttleArrived",true) end
    if arrived then message(player,"You arrived at the "..ride.Destination.Name.." roadside stop!")
    elseif refund then message(player,refunded and "The ride ended. Your 10 coins were returned." or "The ride ended. Your coins could not be saved. Please rejoin.")
    else message(player,ride.Paid and "You are safely off the ride." or "Pickup canceled. No coins spent.") end
    task.delay(.5,function() if ride.Vehicle and ride.Vehicle.Parent then ride.Vehicle:Destroy() end end)
end
local function pathLength(points)
    local total=0;for i=2,#points do total+=(points[i].Position-points[i-1].Position).Magnitude end;return total
end
local function approachRoute(ride)
    local candidates={}
    for _,edge in ipairs(Lanes.SpawnEdges) do
        local delta=edge.Finish-edge.Start
        for _,t in ipairs({.25,.6,.85}) do
            local at=edge.Start+delta*t
            local gap=(at-ride.Pickup.Position).Magnitude
            if gap>=70 and gap<600 and Fleet.CanSpawnAt(at,26) then
                table.insert(candidates,{Position=at,Direction=edge.Direction,Gap=gap})
            end
        end
    end
    table.sort(candidates,function(a,b) return a.Gap<b.Gap end)
    local best,bestLength
    for i,from in ipairs(candidates) do
        if i>32 then break end
        local ok,path=pcall(Lanes.Between,from.Position,from.Direction,ride.Pickup.Position,ride.Pickup.Direction)
        if ok and #path>=2 then
            local length=pathLength(path)
            if length>=60 and (not bestLength or length<bestLength) then best,bestLength=path,length end
        end
    end
    return best
end
local function reroutePickup(ride)
    local character=ride.Player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root or os.clock()-ride.LastReroute<5 or (flat(root.Position)-flat(ride.Pickup.Curb)).Magnitude<38
        or (flat(root.Position)-flat(ride.PickupPlayerPosition)).Magnitude<32 then return end
    ride.LastReroute=os.clock()
    local current=ride.Vehicle and ride.Vehicle:GetPivot()
    -- Re-plan on a straight lane; a turning driver completes the turn first.
    if current then
        local straight=false
        for _,edge in ipairs(Lanes.SpawnEdges) do
            local d=edge.Finish-edge.Start
            local t=math.clamp((flat(current.Position)-edge.Start):Dot(d)/d:Dot(d),0,1)
            if current.LookVector:Dot(edge.Direction)>.98 and (edge.Start+d*t-flat(current.Position)).Magnitude<2 then straight=true;break end
        end
        if not straight then return end
    end
    local target=Locations.Position(ride.Destination)
    local nearby=Service.Stops(root.Position,220)
    if not nearby[1] or (flat(nearby[1].Curb)-flat(ride.Pickup.Curb)).Magnitude<16 then return false end
    for i,pickup in ipairs(nearby) do
        if i>8 then break end
        local ok,approach=true,nil
        if current then ok,approach=pcall(Lanes.Between,flat(current.Position),current.LookVector,pickup.Position,pickup.Direction) end
        if ok then
            for j,dropoff in ipairs(Service.Stops(target,250)) do
                if j>16 then break end
                local connected,path=pcall(Lanes.Between,pickup.Position,pickup.Direction,dropoff.Position,dropoff.Direction)
                if connected and #path>=2 then
                    ride.Pickup,ride.Dropoff,ride.Path=pickup,dropoff,path
                    ride.PickupPlayerPosition=root.Position;ride.Created=os.clock()
                    ride.Player:SetAttribute("TaxiPickupPosition",pickup.Curb)
                    ride.Player:SetAttribute("TaxiPickupRevision",(ride.Player:GetAttribute("TaxiPickupRevision") or 0)+1)
                    if current then
                        state(ride,"Coming");Fleet.SetJourney(ride.Vehicle,approach,ride.Kind=="E-Bike" and 38 or 42)
                    end
                    message(ride.Player,"Your driver is rerouting to your new pickup stop. Follow the blue marker.")
                    return true
                end
            end
        end
    end
end
local function dispatch(ride)
    if rides[ride.Player]~=ride then return false end
    ride.LastDispatch=os.clock()
    local approach=approachRoute(ride)
    if not approach then return false end
    local vehicle=templates[ride.Kind]:Clone()
    vehicle.Name="Taxi_"..ride.Id;vehicle:SetAttribute("OwnerUserId",ride.Player.UserId)
    vehicle:SetAttribute("Route","Roaming");vehicle:SetAttribute("CruiseSpeed",ride.Kind=="E-Bike" and 38 or 42)
    vehicle.Parent=workspace.BrighthavenTransit
    local seat=vehicle:FindFirstChild("PassengerSeat",true)
    assert(seat and seat:IsA("Seat"),"Missing taxi seat");seat.CanTouch=false
    local prompt=Instance.new("ProximityPrompt")
    prompt.Name="BoardTaxi";prompt.ActionText="Get On - 10 Coins";prompt.ObjectText=ride.Kind.." to "..ride.Destination.Name
    prompt.RequiresLineOfSight=false;prompt.MaxActivationDistance=34;prompt.HoldDuration=0;prompt.Enabled=false;prompt.ClickablePrompt=true;prompt.Parent=seat
    ride.Vehicle,ride.Seat,ride.Prompt=vehicle,seat,prompt
    local ok,err=pcall(Fleet.SetJourney,vehicle,approach,ride.Kind=="E-Bike" and 38 or 42)
    if not ok then vehicle:Destroy();ride.Vehicle,ride.Seat,ride.Prompt=nil,nil,nil;return false end
    ride.ApproachLength=pathLength(approach);ride.Player:SetAttribute("TaxiApproachLength",ride.ApproachLength)
    ride.Player:SetAttribute("TaxiVehicle",vehicle.Name);state(ride,"Coming")
    message(ride.Player,"Your "..ride.Kind:lower().." is driving to you. Follow the blue pickup marker. Fare: 10 coins when you board.")
    table.insert(ride.Connections,prompt.Triggered:Connect(function(who)
        if who==ride.Player and not busy[who] then
            busy[who]=true;local boarded,text=Service.Board(who);busy[who]=nil
            if not boarded then message(who,text) end
        end
    end))
    return true
end
function Service.Call(player,kind,id)
    if player:GetAttribute("HomeInteriorActive") or player:GetAttribute("Sleeping") or player:GetAttribute("ClinicRecovering") then return false,"Go outside before calling a ride." end
    if player:GetAttribute("BrighthavenFlashbackPending") then return false,"Finish Captain Kappa's story first." end
    if rides[player] then return false,"You already have a ride. Cancel it before calling another." end
    if not Practice.CanUseWorld(player) then return false,"Rides are available in the main world." end
    if kind~="E-Bike" and kind~="Tricycle" then return false,"Choose an e-bike or a tricycle." end
    local destination=Locations.ById[id]
    local target=destination and Locations.Position(destination)
    if not target then return false,"Choose a place to visit." end
    if destination.Id=="school" and player:GetAttribute("CaptainMetThisVisit")~=true then return false,"Talk to Captain Kappa at Barangay Hall first." end
    local balance=Money.Balance(player)
    if not balance then return false,"Your coins are still loading." end
    if balance<FARE then return false,"You need 10 coins for a ride. Earn coins by helping with quests." end
    local character=player.Character
    local h=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not h or not root or h.Health<=0 or h.SeatPart then return false,"Step off your current ride first." end
    if (flat(root.Position)-flat(target)).Magnitude<35 then return false,"You are already near that place. Choose another destination." end
    local count=0
    for _ in pairs(rides) do count+=1 end
    if count>=3 then return false,"All drivers are busy. Please try again soon." end
    local pickups=Service.Stops(root.Position,220)
    local schoolAnchor=workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation.SchoolVolunteerPrompt
    local schoolPickup=id=="dumpsite" and kind=="Tricycle" and (root.Position-schoolAnchor.Position).Magnitude<180
    if #pickups==0 and schoolPickup then pickups=Service.Stops(root.Position,220) end
    if #pickups==0 then return false,"Walk to a sidewalk beside a road to call your ride." end
    local pickup,dropoff,path
    local stops=Service.Stops(target,250)
    for j,from in ipairs(pickups) do
        if j>8 then break end
        for i,candidate in ipairs(stops) do
            if i>24 then break end
            local ok,result=pcall(Lanes.Between,from.Position,from.Direction,candidate.Position,candidate.Direction)
            if ok and #result>=2 then pickup,dropoff,path=from,candidate,result;break end
        end
        if path then break end
    end
    if not path then return false,"That stop is not connected to this road. Try a nearby sidewalk." end
    local uid=HttpService:GenerateGUID(false)
    local ride={Player=player,Id=uid,Kind=kind,Destination=destination,Pickup=pickup,Dropoff=dropoff,Path=path,
        Connections={},Created=os.clock(),PickupPlayerPosition=root.Position,LastDispatch=0,LastReroute=0}
    rides[player]=ride;player:SetAttribute("TaxiPickupRevision",0);state(ride,"Dispatching")
    player:SetAttribute("TaxiDestination",destination.Name);player:SetAttribute("TaxiDestinationId",id);player:SetAttribute("TaxiKind",kind)
    player:SetAttribute("TaxiPickupPosition",pickup.Curb)
    message(player,"Finding your "..kind:lower().." a clear road. Follow the blue pickup marker. No fare until you board.")
    table.insert(ride.Connections,player.CharacterRemoving:Connect(function() finish(ride,false,ride.State=="Boarding",nil) end))
    dispatch(ride)

    return true,player:GetAttribute("TaxiMessage")
end
function Service.Board(player)
    local ride=rides[player]
    if not ride or ride.State~="Waiting" then return false,"Wait for your driver to arrive." end
    local character=player.Character
    local h=character and character:FindFirstChildOfClass("Humanoid")
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local atCurb=root and (flat(root.Position)-flat(ride.Pickup.Curb)).Magnitude<=10 and math.abs(root.Position.Y-ride.Pickup.Curb.Y)<12
    if not h or not root or h.Health<=0 or h.SeatPart or (not atCurb and (root.Position-ride.Seat.Position).Magnitude>22) then
        return false,"Walk closer to your ride to get on."
    end
    local ok,text=Money.Change(player,-FARE,"ride:fare:"..ride.Id)
    if not ok then return false,text end
    if rides[player]~=ride or player.Character~=character or not h.Parent or h.Health<=0 or not ride.Seat.Parent or h.SeatPart then
        Money.Change(player,FARE,"ride:refund:"..ride.Id)
        return false,"The ride could not start. Please call again."
    end
    ride.Paid=true;ride.Character=character;ride.Humanoid=h
    ride.WalkSpeed=h.WalkSpeed;ride.AutoRotate=h.AutoRotate;ride.Jumping=h:GetStateEnabled(Enum.HumanoidStateType.Jumping)
    h.WalkSpeed=0;h.AutoRotate=false;h:SetStateEnabled(Enum.HumanoidStateType.Jumping,false)
    ride.Seat:Sit(h)
    player:SetAttribute("BrighthavenRiding",true);player:SetAttribute("BrighthavenRideVehicle",ride.Vehicle.Name)
    state(ride,"Boarding");message(player,"Fare paid: 10 coins. Next stop: "..ride.Destination.Name..".")
    table.insert(ride.Connections,h.Died:Connect(function() finish(ride,false,ride.State=="Boarding",nil) end))
    task.delay(.4,function()
        if rides[player]~=ride then return end
        if ride.Seat.Occupant~=h then finish(ride,false,true,ride.Pickup.Curb);return end
        state(ride,"Driving")
        Fleet.SetJourney(ride.Vehicle,ride.Path,ride.Kind=="E-Bike" and 40 or 44)
    end)
    return true,"All aboard!"
end
function Service.Cancel(player)
    local ride=rides[player]
    if not ride then return false,"No ride is waiting." end
    if ride.Paid then function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service.Exit(player) end
    finish(ride,false,false,nil)
    return true,"Pickup canceled. No coins spent."
end
function Service.Exit(player)
    local ride=rides[player]
    if not ride or not ride.Paid then return false,"You are not riding yet." end
    ride.PendingExit=true;player:SetAttribute("BrighthavenRideWaiting",true)
    return true,"Finding a safe stop..."
end
function Service.Status(player)
    local ride=rides[player]
    return ride and {State=ride.State,Kind=ride.Kind,Destination=ride.Destination.Name,Vehicle=ride.Vehicle and ride.Vehicle.Name,Paid=ride.Paid,Pickup=ride.Pickup.Curb,ApproachLength=ride.ApproachLength} or {}
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0
    for player,ride in pairs(rides) do
        if not player.Parent then finish(ride,false,ride.Paid,nil)
        elseif ride.State=="Dispatching" then
            reroutePickup(ride)
            if os.clock()-ride.LastDispatch>=1 then dispatch(ride) end
            if os.clock()-ride.Created>120 then finish(ride,false,false,nil) end
        elseif not ride.Vehicle or not ride.Vehicle.Parent then finish(ride,false,ride.Paid,nil)
        elseif (ride.State=="Coming" or ride.State=="Waiting") and reroutePickup(ride) then
            -- The active lane journey now approaches the updated pickup.
        elseif ride.State=="Coming" and ride.Vehicle:GetAttribute("JourneyComplete") then
            state(ride,"Waiting");ride.Arrived=os.clock()
            message(player,"Your "..ride.Kind:lower().." is here! Walk over and get on. Fare: 10 coins.")
        elseif ride.State=="Waiting" and os.clock()-ride.Arrived>90 then finish(ride,false,false,nil)
        elseif ride.State=="Driving" then
            if ride.PendingExit then
                local f=ride.Vehicle:GetPivot()
                local point=curb(flat(f.Position),f.LookVector)
                if point then Fleet.Pause(ride.Vehicle,1);finish(ride,false,false,point) end
            elseif ride.Vehicle:GetAttribute("JourneyComplete") then finish(ride,true,false,ride.Dropoff.Curb)
            elseif not ride.Humanoid.Parent or ride.Seat.Occupant~=ride.Humanoid then
                local f=ride.Vehicle:GetPivot();finish(ride,false,false,curb(flat(f.Position),f.LookVector))
            end
        end
        if rides[player]==ride and ride.Vehicle and os.clock()-ride.Created>600 then
            local f=ride.Vehicle:GetPivot();finish(ride,false,ride.Paid,curb(flat(f.Position),f.LookVector))
        end
    end
end)
local request=ReplicatedStorage.Brighthaven.Transit:WaitForChild("TaxiRequest")
request.OnServerInvoke=function(player,action,payload)
    if type(action)~="string" or type(payload)~="table" then return {Ok=false,Message="Please try again."} end
    if busy[player] or os.clock()-(limits[player] or 0)<.4 then return {Ok=false,Message="One moment! Please try again."} end
    limits[player]=os.clock();busy[player]=true
    local ok,result,text=pcall(function()
        if action=="Call" then function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service.Call(player,payload.Kind,payload.Destination)
        elseif action=="Board" then function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service.Board(player)
        elseif action=="Cancel" then function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service.Cancel(player)
        elseif action=="Exit" then function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service.Exit(player) end
        return false,"Unknown ride action."
    end)
    busy[player]=nil
    if not ok then warn("[BrightHaven Taxi]",result);return {Ok=false,Message="The driver could not start. Please try again."} end
    message(player,text)
    return {Ok=result,Message=text,Status=Service.Status(player),Coins=Money.Balance(player)}
end
Players.PlayerRemoving:Connect(function(player)
    if rides[player] then finish(rides[player],false,false,nil) end
    busy[player],limits[player]=nil,nil
end)
function Service.ForceRest(player)
 if rides[player] then finish(rides[player],false,rides[player].Paid==true,nil) end
end
return Service


