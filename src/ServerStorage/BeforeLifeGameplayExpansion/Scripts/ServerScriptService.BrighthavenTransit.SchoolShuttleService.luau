local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Practice=require(ReplicatedStorage.Brighthaven.TutorialPractice)
local TrafficRules=require(script.Parent:WaitForChild("TrafficRules"))
local Service={}
local root,vehicle,prompt,remote,path,length,door,closedDoor,returnPath,outLength,returnLength
local passengers={}
local state,distance,reverse,departure,arrival="Waiting",0,false,0,0
local eligibility,initialized,frame,turnFrom,turnTo
local replicationElapsed=0
local appearanceElapsed=0
local priorityElapsed=0
local speed=72
local velocity=0
local halfLength,turnProgress=12,0
function Service.SetEligibility(callback) eligibility=callback end
local function setState(value)
    state=value;root:SetAttribute("ShuttleState",value)
    TrafficRules.HoldSchoolMerge(vehicle,value=="Boarding" or (value=="Driving" and distance<130))
    prompt.Enabled=value=="Waiting" or value=="Boarding"
end
local function setDoor(open)
    root:SetAttribute("DoorOpen",open)
    door.CFrame=vehicle:GetPivot()*closedDoor*CFrame.new(0,0,open and 2.8 or 0)
end
local function count()
    local n=0;for _ in pairs(passengers) do n+=1 end;return n
end
local function roadFrame(d)
    local active=reverse and returnPath or path
    local remaining=math.clamp(d,0,length)
    for i=2,#active do
        local a,b=active[i-1],active[i]
        local segment=(b-a).Magnitude
        if remaining<=segment or i==#active then
            local position=a:Lerp(b,math.clamp(remaining/segment,0,1))+Vector3.new(0,-142.974,0)
            return CFrame.lookAt(position,position+b-a)
        end
        remaining-=segment
    end
end
local function exitFrame(player,atSchool,index)
    local anchor=root.Stops[atSchool and "SchoolDropoff" or "HallBoarding"]
    local position=anchor.Position+Vector3.new(0,0,((index or 1)-1)*2.5)
    local ignore={vehicle}
    for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore,p.Character) end end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances=ignore;params.RespectCanCollide=true
    local floor=workspace:Raycast(position+Vector3.new(0,20,0),Vector3.new(0,-50,0),params)
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    local part=character and character:FindFirstChild("HumanoidRootPart")
    local leg=humanoid and humanoid.RigType==Enum.HumanoidRigType.R6 and character:FindFirstChild("Left Leg")
    local height=humanoid and part and humanoid.HipHeight+part.Size.Y/2+(leg and leg.Size.Y or 0) or 3
    if floor then position=Vector3.new(position.X,floor.Position.Y+.2+height,position.Z) end
    return CFrame.lookAt(position,position+vehicle:GetPivot().RightVector)
end
local function fitAccessories(ride)
    if ride.Humanoid.SeatPart~=ride.Seat then return end
    local roof=vehicle.BusShell.Roof
    local ceiling=roof.Position.Y-roof.Size.Y/2-.1
    for _,accessory in ipairs(ride.Character:GetChildren()) do
        if accessory:IsA("Accessory") then
            local clips=false
            for _,part in ipairs(accessory:GetDescendants()) do
                if part:IsA("BasePart") then
                    local extent=math.abs(part.CFrame.RightVector.Y)*part.Size.X/2
                        +math.abs(part.CFrame.UpVector.Y)*part.Size.Y/2+math.abs(part.CFrame.LookVector.Y)*part.Size.Z/2
                    if part.Position.Y+extent>ceiling then clips=true;break end
                end
            end
            if clips then
                for _,part in ipairs(accessory:GetDescendants()) do
                    if part:IsA("BasePart") and ride.HiddenAccessories[part]==nil then
                        ride.HiddenAccessories[part]=part.Transparency
                        part.Transparency=1
                    end
                end
            end
        end
    end
end
local function release(player,atSchool,cancelled)
    local ride=passengers[player]
    if not ride then return end
    passengers[player]=nil
    for _,c in ipairs(ride.Connections) do c:Disconnect() end
    for part,transparency in pairs(ride.HiddenAccessories) do
        if part.Parent then part.Transparency=transparency end
    end
    ride.Seat:SetAttribute("Reserved",nil)
    local h=ride.Humanoid
    if h.Parent then
        local weld=ride.Seat:FindFirstChild("SeatWeld")
        if weld and weld:IsA("Weld") and weld.Part1 and weld.Part1:IsDescendantOf(ride.Character) then weld:Destroy() end
        h.Sit=false;h.WalkSpeed=ride.WalkSpeed;h.AutoRotate=ride.AutoRotate
        h:SetStateEnabled(Enum.HumanoidStateType.Jumping,ride.Jumping)
        local part=ride.Character:FindFirstChild("HumanoidRootPart")
        if not cancelled and part and h.Health>0 and player.Character==ride.Character then
            local destination=exitFrame(player,atSchool,ride.Index)
            local anchored=part.Anchored;part.Anchored=true;part.CFrame=destination
            part.AssemblyLinearVelocity,part.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
            remote:FireClient(player,"Exit",destination,ride.Character)
            task.delay(.3,function()
                if part.Parent then
                    if player.Character==ride.Character then part.CFrame=destination end
                    part.Anchored=anchored
                    if not anchored and part:CanSetNetworkOwnership() then part:SetNetworkOwnershipAuto() end
                end
            end)
        end
    end
    player:SetAttribute("SchoolShuttleRiding",nil)
    root:SetAttribute("PassengerCount",count())
    if atSchool and not cancelled then player:SetAttribute("SchoolShuttleArrived",true) end
    if state=="Boarding" and count()==0 then setState("Waiting");setDoor(true) end
end
function Service.Board(player)
    if player:GetAttribute("BrighthavenFlashbackPending") then
        return false,"Finish Captain Kappa's story first."
    end
    if not initialized or not Practice.CanUseWorld(player) or not eligibility or not eligibility(player) then
        return false,"Talk to Captain Kappa first. He will tell you about the school trip."
    end
    if passengers[player] then return false,"You already have a seat. Driver Lito will take you to school." end
    if state~="Waiting" and state~="Boarding" then return false,"Driver Lito is bringing the shuttle back. Wait at the blue stop." end
    local character=player.Character
    local h=character and character:FindFirstChildOfClass("Humanoid")
    local part=character and character:FindFirstChild("HumanoidRootPart")
    if not h or not part or h.Health<=0 or h.SeatPart or (part.Position-prompt.Parent.Position).Magnitude>12 then
        return false,"Walk to the shuttle's side door to get on."
    end
    local seat,index
    local seats=vehicle.PassengerSeats:GetChildren();table.sort(seats,function(a,b) return a.Name<b.Name end)
    for i,s in ipairs(seats) do if not s.Occupant and not s:GetAttribute("Reserved") then seat,index=s,i;break end end
    if not seat then return false,"All seats are full. Wait for the next school trip." end
    local ride={Character=character,Humanoid=h,Seat=seat,Index=index,Connections={},WalkSpeed=h.WalkSpeed,
        AutoRotate=h.AutoRotate,Jumping=h:GetStateEnabled(Enum.HumanoidStateType.Jumping),HiddenAccessories={}}
    passengers[player]=ride;seat:SetAttribute("Reserved",true)
    h:SetStateEnabled(Enum.HumanoidStateType.Jumping,false);h.WalkSpeed=0;h.AutoRotate=false
    seat:Sit(h)
    player:SetAttribute("SchoolShuttleRiding",true);player:SetAttribute("SchoolShuttleArrived",false)
    table.insert(ride.Connections,h.Died:Connect(function() release(player,false,true) end))
    table.insert(ride.Connections,player.CharacterRemoving:Connect(function() release(player,false,true) end))
    table.insert(ride.Connections,seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if seat.Occupant~=h then release(player,false,true) end
    end))
    task.delay(.5,function() if passengers[player]==ride and seat.Occupant~=h then release(player,false,true) end end)
    if state=="Waiting" then
        departure=workspace:GetServerTimeNow();root:SetAttribute("DepartureAt",nil);setState("Boarding")
    end
    root:SetAttribute("PassengerCount",count())
    remote:FireClient(player,"Boarded")
    return true,"All aboard! Driver Lito will take us to school."
end
function Service.Exit(player)
    if not passengers[player] then return false,"You are not on the shuttle." end
    if state=="Driving" or state=="Returning" or state:match("Turning") then return false,"Stay seated while the shuttle is moving. We will stop at school." end
    release(player,state=="AtSchool",false)
    return true,"You are safely off the shuttle."
end
function Service.Status() return {State=state,Distance=distance,Length=length,Passengers=count(),Reverse=reverse} end
function Service.Init()
    if initialized then return end
    root=workspace:WaitForChild("BrighthavenSchoolShuttle")
    vehicle=root.Vehicle;prompt=vehicle.DoorStep.BoardShuttle;door=vehicle.SlidingDoor.DoorGlass
    halfLength=TrafficRules.Dimensions(vehicle)
    local transit=ReplicatedStorage.Brighthaven:WaitForChild("Transit")
    remote=transit:WaitForChild("SchoolShuttleRequest")
    path={};length=0
    local values=root.Route:GetChildren();table.sort(values,function(a,b) return a.Name<b.Name end)
    for _,v in ipairs(values) do table.insert(path,v.Value) if #path>1 then length+=(path[#path]-path[#path-1]).Magnitude end end
    assert(#path>1 and length>100,"Missing school shuttle route")
    outLength=length;returnPath={};returnLength=0
    local returning=root.ReturnRoute:GetChildren();table.sort(returning,function(a,b) return a.Name<b.Name end)
    for _,v in ipairs(returning) do table.insert(returnPath,v.Value);if #returnPath>1 then returnLength+=(returnPath[#returnPath]-returnPath[#returnPath-1]).Magnitude end end
    assert(#returnPath>1 and returnLength>100,"Missing shuttle return lanes")
    frame=roadFrame(0);vehicle:PivotTo(frame)
    closedDoor=frame:ToObjectSpace(door.CFrame)
    initialized=true;setState("Waiting");setDoor(true)
    prompt.Triggered:Connect(function(player)
        local ok,message=Service.Board(player)
        if not ok then remote:FireClient(player,"Notice",message) end
    end)
    remote.OnServerEvent:Connect(function(player,action)
        if action=="Exit" then
            local ok,message=Service.Exit(player)
            if not ok then remote:FireClient(player,"Notice",message) end
        end
    end)
    Players.PlayerRemoving:Connect(function(player) release(player,false,true) end)
    RunService.Heartbeat:Connect(function(dt)
        local step=math.clamp(dt,.001,.05)
        appearanceElapsed+=step
        if appearanceElapsed>=.2 then
            appearanceElapsed=0
            for _,ride in pairs(passengers) do fitAccessories(ride) end
        end
        local now=workspace:GetServerTimeNow()
        if state=="Boarding" and now>=departure then
            if count()==0 then setState("Waiting") else distance=0;velocity=0;reverse=false;length=outLength;setDoor(false);setState("Driving") end
        elseif state=="Driving" or state=="Returning" then
            speed=math.clamp(root:GetAttribute("CruiseSpeed") or 72,10,80)
            priorityElapsed+=step
            if state=="Driving" and count()>0 and priorityElapsed>=.15 then
                priorityElapsed=0
                TrafficRules.RequestShuttlePriority(vehicle,frame)
                -- Clear queues around the next turn before they block the shuttle's approach.
                for _,ahead in ipairs({40,80,120}) do
                    TrafficRules.RequestShuttlePriority(vehicle,roadFrame(math.min(length,distance+ahead)))
                end
            end
            TrafficRules.HoldSchoolMerge(vehicle,state=="Driving" and distance<130)
            local desired=TrafficRules.SpeedLimit(frame,speed)
            if state=="Driving" and distance<25 and not TrafficRules.SchoolMergeClear(vehicle) then
                desired=0;vehicle:SetAttribute("TrafficStopReason","Waiting for merging lane")
            end
            local look=roadFrame(math.min(length,distance+22))
            if frame.LookVector:Dot(look.LookVector)<math.cos(math.rad(15)) then desired=math.min(desired,28) end
            local braking,acceleration=50,28
            local clearance,anticipation=TrafficRules.Constrain(vehicle,frame,math.max(12,velocity^2/(2*braking)+3),halfLength,true)
            local curve=TrafficRules.CurveSamples(frame,function(ahead) return roadFrame(math.min(length,distance+ahead)) end)
            local curvedClearance,curveReason=TrafficRules.FollowCurve(vehicle,frame,clearance,halfLength,curve)
            if curvedClearance<clearance then clearance,anticipation=curvedClearance,curveReason end
            desired=math.min(desired,math.sqrt(2*braking*math.max(0,clearance-1)),math.sqrt(2*braking*math.max(0,length-distance)))
            velocity+=math.clamp(desired-velocity,-braking*step,acceleration*step)
            local travel,_,reservations=TrafficRules.Constrain(vehicle,frame,velocity*step,halfLength)
            local curveTravel=TrafficRules.FollowCurve(vehicle,frame,travel,halfLength,curve)
            travel=math.min(curveTravel,math.max(0,length-distance))
            if travel<.01 and anticipation~="" then vehicle:SetAttribute("TrafficStopReason",anticipation) end
            local nextDistance=math.min(length,distance+travel)
            local target=roadFrame(nextDistance)
            local rotation=(frame-frame.Position):Lerp(target-target.Position,1-math.exp(-10*step))
            local candidate=CFrame.new(target.Position)*rotation
            if not TrafficRules.CanMoveTo(vehicle,frame,candidate,halfLength) then
                nextDistance=distance
                candidate=frame;travel=0
                vehicle:SetAttribute("TrafficStopReason","Yielding to Cross Traffic")
            end
            TrafficRules.CommitMove(vehicle,frame,travel,reservations)
            distance=nextDistance
            velocity=travel/step
            vehicle:SetAttribute("CurrentSpeed",travel/step)
            frame=candidate;vehicle:PivotTo(frame)
            replicationElapsed+=step
            if replicationElapsed>=.2 or distance>=length then
                replicationElapsed=0
                root:SetAttribute("TripProgress",distance/length)
                root:SetAttribute("SecondsRemaining",math.ceil((length-distance)/speed))
            end
            if distance>=length then
                setDoor(true)
                if reverse then
                    reverse=false;distance=0;length=outLength
                    turnFrom,turnTo,turnProgress=frame,roadFrame(0),0
                    setDoor(false);setState("TurningAtHall")
                else
                    arrival=now+3;root:SetAttribute("GetOffBy",arrival);setState("AtSchool")
                    for p in pairs(passengers) do p:SetAttribute("SchoolShuttleArrived",true) end
                end
            end
        elseif state=="AtSchool" and (now>=arrival or count()==0) then
            local riders={};for p in pairs(passengers) do table.insert(riders,p) end
            for _,p in ipairs(riders) do release(p,true,false) end
            reverse=true;distance=0;length=returnLength;setDoor(false);setState("Returning")
            turnFrom,turnTo,turnProgress=frame,roadFrame(0),0
            setState("TurningForReturn")
        elseif state=="TurningAtHall" or state=="TurningForReturn" then
            local nextProgress=math.min(1,turnProgress+step/2.5)
            local eased=nextProgress*nextProgress*(3-2*nextProgress)
            local candidate=turnFrom:Lerp(turnTo,eased)
            local moved=0
            if TrafficRules.CanMoveTo(vehicle,frame,candidate,halfLength) then
                moved=(candidate.Position-frame.Position).Magnitude
                frame=candidate;turnProgress=nextProgress;vehicle:PivotTo(frame)
                vehicle:SetAttribute("TrafficStopReason","")
            else vehicle:SetAttribute("TrafficStopReason","Yielding to Cross Traffic") end
            vehicle:SetAttribute("CurrentSpeed",moved/step)
            if turnProgress>=1 then
                if state=="TurningAtHall" then
                    root:SetAttribute("TripProgress",0);setDoor(true);setState("Waiting")
                else setState("Returning") end
            end
        end
        TrafficRules.Observe(vehicle,frame,halfLength)
    end)
end
return Service



