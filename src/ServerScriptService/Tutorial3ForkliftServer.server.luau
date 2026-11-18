local Players=game:GetService("Players")
local Review=require(game.ServerScriptService.Brighthaven.AnswerReview)
local RunService=game:GetService("RunService")
local RS=game:GetService("ReplicatedStorage")
local Practice=require(RS.Brighthaven.TutorialPractice)
local Chunking=require(RS.Brighthaven.Tutorial3Chunking)
local remotes=RS.Brighthaven.Tutorial3Remotes
local tutorial=workspace["Possible Map Replacement"].Tutorial.Tutorial_3
local area=tutorial.ForkliftPractice
local car=tutorial.TutorialForklift
local seat=car.DriveSeat
car.PrimaryPart=seat
local home=car:GetPivot()
local states, owner, last, idle, limits={}, nil, nil, 0, {}
local problemRandom,lastTotal=Random.new(),nil
local stockTemplates=area.Stock:GetChildren()
local function ensureStock(total)
    for i=#area.Stock:GetChildren()+1,total do
        local template=stockTemplates[(i-1)%#stockTemplates+1]
        local extra=template:Clone()
        extra.Name="StockBox"..i
        local lift=Vector3.new(0,math.floor((i-1)/#stockTemplates)*1.8,0)
        extra.CFrame+=lift
        for _,part in ipairs(extra:GetDescendants()) do if part:IsA("BasePart") then part.CFrame+=lift end end
        extra.Parent=area.Stock
    end
end
local function copy(v)
    if type(v)~="table" then return v end
    local t={}; for k,x in pairs(v) do t[k]=copy(x) end; return t
end
local function response(player, ok, message)
    return {Ok=ok, Message=message or "", State=copy(states[player.UserId]), Owner=owner and owner.UserId}
end
local function publish(player, message)
    remotes.StateChanged:FireClient(player,response(player,true,message))
end
local function cargoClear()
    area.Cargo:ClearAllChildren()
end
local function box(parent, cf, moving)
    local p=Instance.new("Part")
    p.Name="SupplyBox"; p.Size=Vector3.new(1.8,1.6,1.8); p.CFrame=cf
    p.Color=Color3.fromRGB(202,159,99); p.Material=Enum.Material.SmoothPlastic
    p.Anchored=not moving; p.CanCollide=false; p.CanTouch=false; p.CanQuery=false; p.Massless=true; p.Parent=parent
    local tape=Instance.new("Part")
    tape.Name="Tape"; tape.Size=Vector3.new(.28,1.65,1.85); tape.CFrame=cf
    tape.Color=Color3.fromRGB(246,228,167)
    tape.Anchored=not moving; tape.CanCollide=false; tape.CanTouch=false; tape.CanQuery=false; tape.Massless=true; tape.Parent=p
    if moving then
        for _,part in ipairs({p,tape}) do
            local weld=Instance.new("WeldConstraint"); weld.Part0=seat; weld.Part1=part; weld.Parent=part
        end
    end
end
local function render(s)
    cargoClear()
    ensureStock(s.Total)
    for id=1,3 do
        local crate=area.Crates["Crate"..id]
        crate.Boxes:ClearAllChildren()
        for i=1,s.Counts[id] do
            local x=((i-1)%3-1)*2.25
            local z=(math.floor((i-1)/3)%2-.5)*2.25
            local y=1.15+math.floor((i-1)/6)*1.8
            box(crate.Boxes,crate.Base.CFrame*CFrame.new(x,y,z),false)
        end
    end
    if s.Cargo>0 then
        -- Weld the visible load to the forks without adding weight to the vehicle.
        local pallet=Instance.new("Part")
        pallet.Name="CargoPallet"; pallet.Size=Vector3.new(4.2,.25,2.2)
        pallet.CFrame=seat.CFrame*CFrame.new(0,-1.42,-6.5)
        pallet.Material=Enum.Material.WoodPlanks; pallet.Color=Color3.fromRGB(166,120,72)
        pallet.CanCollide=false; pallet.CanTouch=false; pallet.CanQuery=false; pallet.Massless=true; pallet.Parent=area.Cargo
        local weld=Instance.new("WeldConstraint"); weld.Part0=seat; weld.Part1=pallet; weld.Parent=pallet
        for i=1,s.Cargo do
            local x=s.Cargo==1 and 0 or (i==1 and -.95 or i==2 and .95 or 0)
            local y=i==3 and 1.155 or -.495
            box(area.Cargo,seat.CFrame*CFrame.new(x,y,-6.5),true)
        end
    end
    for i,p in ipairs(area.Stock:GetChildren()) do
        local shown=i<=s.Remaining-s.Cargo
        p.Transparency=shown and 0 or 1
        for _,d in ipairs(p:GetDescendants()) do if d:IsA("BasePart") then d.Transparency=p.Transparency end end
    end
end
local function releaseWheels()
    for _,wheel in car.Wheels:GetChildren() do
        local motor=wheel:FindFirstChild("#AV")
        if motor then motor.AngularVelocity=Vector3.zero; motor.MaxTorque=Vector3.zero end
    end
end
seat.ChildAdded:Connect(function(child)
    if child.Name=="SeatWeld" then releaseWheels() end
end)
local function updateDrivePrompt()
    seat.DrivePrompt.Enabled=seat.Occupant==nil
end
seat:GetPropertyChangedSignal("Occupant"):Connect(updateDrivePrompt)
updateDrivePrompt()
local function resetCar()
    if seat.Occupant then seat.Occupant.Sit=false end
    local weld=seat:FindFirstChild("SeatWeld")
    if weld then weld:Destroy() end
    releaseWheels()
    cargoClear()
    car:PivotTo(home)
    for _,p in ipairs(car:GetDescendants()) do
        if p:IsA("BasePart") then p.AssemblyLinearVelocity=Vector3.zero; p.AssemblyAngularVelocity=Vector3.zero end
    end
    last=nil
end
local function driving(player)
    return owner==player and player.Character and seat.Occupant==player.Character:FindFirstChildOfClass("Humanoid")
end
local function slow() return seat.AssemblyLinearVelocity.Magnitude<5 end
local function flatDistance(a,b) return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude end
local function begin(player)
    if Practice.PlayerStage(player)~=3 then return false,"Meet the Warehouse Worker first." end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position-Practice.Anchors[3].Position).Magnitude>20 then return false,"Walk closer to the Warehouse Worker." end
    if owner and owner~=player then return false,"Another helper is driving. Come back when the forklift is free." end
    local s=states[player.UserId]
    if player:GetAttribute("Tutorial3Practice")=="complete" then return true,"Your crates are ready. Follow the yellow guide!" end
    if owner~=player then resetCar() end
    owner, idle=player, 0
    if not s then s=Chunking.New(problemRandom,lastTotal);lastTotal=s.Total end
    states[player.UserId]=s
    player:SetAttribute("Tutorial3Total",s.Total)
    if s.Cargo>0 then s.Cargo=0 end
    seat.Disabled=false
    player:SetAttribute("Tutorial3Practice","active")
    render(s); publish(player,"Sit in the forklift, then drive to the loading bay.")
    return true,"Sit in the forklift, then drive to the loading bay."
end
RS.StartTutorialQuest.OnServerEvent:Connect(function(player)
    local ok,msg=begin(player); remotes.StateChanged:FireClient(player,response(player,ok,msg))
end)
seat.DrivePrompt.Triggered:Connect(function(player)
    if owner~=player then
        remotes.StateChanged:FireClient(player,response(player,false,"Talk to the Warehouse Worker before driving."))
        return
    end
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if h and root and h.Health>0 and (root.Position-seat.Position).Magnitude<=12 then seat:Sit(h) end
end)
remotes.Request.OnServerInvoke=function(player,action,payload)
    if action=="GetState" then return response(player,true) end
    local now=os.clock()
    if now-(limits[player.UserId] or 0)<.15 then return response(player,false,"One moment!") end
    limits[player.UserId]=now
    if type(payload)~="table" then return response(player,false,"Choose a button.") end
    local s=states[player.UserId]
    if not s or owner~=player or Practice.PlayerStage(player)~=3 then return response(player,false,"Meet the Warehouse Worker first.") end
    local ok,msg
    if action=="Recover" then
        resetCar(); s.Cargo=0; render(s)
        ok,msg=true,"Your forklift is back in its parking spot. Your deliveries are safe."
    elseif action=="Check" then
        if not s.Complete then return response(player,false,"Deliver all the chunks first.") end
        if tonumber(payload.Answer)~=s.Counts[1] then
            Review.ForPlayer(player,"Division","Kargada Quest",payload.Answer,s.Counts[1])
            return response(player,false,"Add the chunks in one crate. Then try again.")
        end
        s.Checked=true
        player:SetAttribute("Tutorial3Practice","complete")
        RS.ShowDialogue:FireClient(player,"Equal groups! Follow the yellow arrows to the exit gate, then press E to enter BrightHaven.","tutorial3_complete","Warehouse Worker")
        ok,msg=true,"You shared in chunks! Follow the yellow arrows to the exit gate, then press E to enter BrightHaven."
    elseif not driving(player) then
        return response(player,false,"Sit in your forklift to carry and deliver a chunk.")
    elseif not slow() then return response(player,false,"Stop the forklift before loading or delivering.")
    elseif action=="PlanChunk" or action=="PlanStep" or action=="Load" then
        if flatDistance(seat.Position,area.LoadingBay.Position)>13 then return response(player,false,"Drive to the green loading bay first.") end
        if action=="PlanChunk" then ok,msg=Chunking.Plan(s,payload.Amount)
        elseif action=="PlanStep" then
            local pending=s.RoundMath and s.RoundMath.PendingChunk
            ok,msg=Chunking.PlanStep(s,payload.Step,payload.Answer,payload.Token)
            if not ok and pending and pending.Token==payload.Token and pending.Step==payload.Step then
                local product=pending.Quotient*3
                Review.ForPlayer(player,payload.Step=="multiply" and "Multiplication" or "Subtraction","Kargada Quest",
                    payload.Answer,payload.Step=="multiply" and product or pending.Before-product)
            end
        else ok,msg=Chunking.Load(s,payload.Amount) end
    elseif action=="Deliver" then
        local id=payload.Crate
        if id~=1 and id~=2 and id~=3 then return response(player,false,"Choose a crate.") end
        if flatDistance(seat.Position,area.Crates["Crate"..id].DeliveryBay.Position)>9 then return response(player,false,"Drive closer to this crate's colored bay.") end
        ok,msg=Chunking.Deliver(s,id)
    else return response(player,false,"Choose a delivery action.") end
    if ok then render(s); publish(player,msg) end
    return response(player,ok,msg)
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt
    if elapsed<.1 then return end
    local step=elapsed; elapsed=0
    if not owner then return end
    local s=states[owner.UserId]
    if not owner.Parent or Practice.PlayerStage(owner)~=3 then
        if s then s.Cargo=0 end
        resetCar(); seat.Disabled=true; owner=nil; return
    end
    if driving(owner) then
        idle=0
        local pos=seat.Position
        if last and s.Cargo>0 then
            local distance=flatDistance(last,pos)
            if distance<=math.max(8,step*55) then s.Travel+=distance end
        end
        last=pos
        if pos.Y < -150 or pos.X<2453 or pos.X>2559 or pos.Z< -1945 or pos.Z> -1876 then
            resetCar(); s.Cargo=0; render(s); publish(owner,"Forklift rescued! Your delivered chunks are still safe.")
        end
    else
        last=nil; idle+=step
        if seat.Occupant then seat.Occupant.Sit=false end
        if idle>90 then
            local previous=owner
            s.Cargo=0; resetCar(); seat.Disabled=true; owner=nil
            publish(previous,"The forklift is free for another helper. Talk to the worker to continue.")
        end
    end
end)
Players.PlayerRemoving:Connect(function(player)
    if owner==player then resetCar(); owner=nil; seat.Disabled=true end
    states[player.UserId],limits[player.UserId]=nil,nil
end)

game.ServerScriptService:WaitForChild('BarangayPracticeReset').Event:Connect(function(player,index)
 if index~=3 or owner and owner~=player then return end
 resetCar();states[player.UserId]=nil;owner=nil;player:SetAttribute('Tutorial3Practice',nil);player:SetAttribute('Tutorial3Total',nil)
end)
