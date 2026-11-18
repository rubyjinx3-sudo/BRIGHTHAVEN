local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local SS=game:GetService("ServerStorage")
local Clock=require(script.Parent.TownClock)
local Care=require(script.Parent.SurvivalService)
local Money=require(script.Parent.MoneyService)
local Rules=require(RS.Brighthaven.HomeRules)
local homes=workspace:WaitForChild("BrighthavenHomes")
local request=RS.Brighthaven.WorldCare.Request
local notice=RS.Brighthaven.WorldCare.Notice
local owned,sleepers,rested,busy,limits={},{},{},{},{}
local nextSlot=0
local Service={}
local function notify(player,kind,message) if player.Parent then notice:FireClient(player,kind,message) end end
function Service.Upgrades(player)
    local result={}
    for _,item in Rules.Upgrades do result[item.Id]=Money.HasReceipt(player,"home:"..item.Id) end
    return result
end
local function refresh(player)
    local house=owned[player];if not house then return end
    local upgrades=Service.Upgrades(player)
    for _,model in house.UpgradeProps:GetChildren() do
        for _,p in model:GetDescendants() do
            if p:IsA("BasePart") then
                if p:GetAttribute("HomeTransparency")==nil then p:SetAttribute("HomeTransparency",p.Transparency) end
                p.Transparency=upgrades[model.Name] and p:GetAttribute("HomeTransparency") or 1
                p.CanCollide=upgrades[model.Name]==true
            elseif p:IsA("PointLight") or p:IsA("SurfaceGui") or p:IsA("BillboardGui") then p.Enabled=upgrades[model.Name]==true end
        end
    end
    player:SetAttribute("HomePosition",homes.StarterHome.Entry.Position)
    player:SetAttribute("OwnHomeAssigned",true)
    player:SetAttribute("HomeStormRoof",Service.Upgrades(player).StormRoof==true)
    player:SetAttribute("HomeStormShutters",Service.Upgrades(player).StormShutters==true)
end
function Service.Ensure(player)
    if owned[player] then return owned[player] end
    nextSlot+=1
    local house=SS.BrighthavenHomeTemplate:Clone();house.Name="Home_"..player.UserId
    house:PivotTo(CFrame.new(6000+nextSlot*70,0,6000));house:SetAttribute("OwnerUserId",player.UserId);house:SetAttribute("OwnerName",player.DisplayName)
    if not house:FindFirstChild("InteriorDoor") then
        local door=Instance.new("Part");door.Name="PrivateDoor";door.Anchored=true;door.Size=Vector3.new(7,10,.6)
        door.Color=Color3.fromRGB(111,83,54);door.Material=Enum.Material.WoodPlanks;door.CFrame=house.Floor.CFrame*CFrame.new(0,5.3,13.7);door.Parent=house
    end
    house.Entry:Destroy();house.Parent=homes;owned[player]=house
    for _,v in house:GetDescendants() do if v:IsA("ProximityPrompt") then v:SetAttribute("HomeOwner",player.UserId) end end
    refresh(player)
    return house
end
local function ready(player)
    return Clock.Eligible(player) and not player:GetAttribute("ClinicRecovering") and not player:GetAttribute("Sleeping")
end
local function near(player,point)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and (root.Position-point.Position).Magnitude<=18
end
local function move(player,cf)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero;character:PivotTo(cf) end
end
local doorStates=setmetatable({},{__mode="k"})
local function swingDoor(model,open)
    if not model or not model.Parent then return end
    local state=doorStates[model]
    if not state then state={Closed=model:GetPivot()};doorStates[model]=state end
    if state.Tween then state.Tween:Cancel() end
    for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide=false end end
    local value=Instance.new("CFrameValue");value.Value=model:GetPivot()
    local connection=value.Changed:Connect(function(cf) if model.Parent then model:PivotTo(cf) end end)
    local angle=model.Name=="FrontDoor" and -85 or 85
    local tween=game.TweenService:Create(value,TweenInfo.new(.4,Enum.EasingStyle.Sine),{Value=state.Closed*CFrame.Angles(0,open and math.rad(angle) or 0,0)})
    state.Tween=tween
    tween.Completed:Once(function()
        connection:Disconnect();value:Destroy()
        if state.Tween==tween then
            state.Tween=nil
            if not open and model.Parent and model:FindFirstChild("DoorLeaf") then model.DoorLeaf.CanCollide=true end
        end
    end)
    tween:Play()
    if open then
        state.Serial=(state.Serial or 0)+1;local serial=state.Serial
        task.delay(1.5,function() if model.Parent and state.Serial==serial then swingDoor(model,false) end end)
    end
end
function Service.Enter(player)
    if not ready(player) or not near(player,homes.StarterHome.Entry) then return false,"Walk to your front door." end
    local h=player.Character:FindFirstChildOfClass("Humanoid")
    if h.SeatPart or player:GetAttribute("SchoolShuttleRiding") or player:GetAttribute("BrighthavenRiding") then return false,"Get off your ride first." end
    local house=Service.Ensure(player);refresh(player)
    swingDoor(homes.StarterHome:FindFirstChild("FrontDoor"),true);task.wait(.3)
    player:SetAttribute("HomeInteriorActive",true)
    move(player,CFrame.new(house.Floor.Position+Vector3.new(0,3.5,6)))
    return true,"Welcome home! Your bed and upgrades are inside."
end
local function release(player)
    local sleep=sleepers[player];sleepers[player]=nil;player:SetAttribute("Sleeping",false)
    if not sleep then return end
    local root=sleep.Character and sleep.Character:FindFirstChild("HumanoidRootPart")
    local h=sleep.Character and sleep.Character:FindFirstChildOfClass("Humanoid")
    if root then root.Anchored=sleep.Anchored end
    if h and h.Health>0 then h.WalkSpeed=16 end
end
function Service.Wake(player,rest)
    if not sleepers[player] then return end
    if not rest and player:GetAttribute("CurfewDay")==Clock.Day and Clock.IsCurfew(Clock.Minutes) then return end
    release(player)
    if rest then
        Care.Rest(player,Rules.Rest(Service.Upgrades(player)))
        rested[player]=Clock.Day
        notify(player,"morning","Good morning! It is 07:00. You rested, had a snack, and drank clean water. Ready to help your neighbors?")
    end
end
local skipPending=false
local function allAsleep()
    local count=0
    for _,p in Players:GetPlayers() do
        if Clock.Eligible(p) and not p:GetAttribute("ClinicRecovering") then
            count+=1;if not sleepers[p] then return false end
        end
    end
    return count>0
end
local function tryMorning()
    if skipPending or not Clock.CanSleep() or not allAsleep() then return end
    skipPending=true
    task.delay(6,function()
        if Clock.CanSleep() and allAsleep() then Clock.Morning() end
        skipPending=false
    end)
end
function Service.Sleep(player)
    local house=owned[player]
    if not ready(player) or not house or not player:GetAttribute("HomeInteriorActive") or not near(player,house.Bed) then return false,"Rest at your own bed." end
    if not Clock.CanSleep() then return false,"It is daytime. Rest in the evening; curfew sends everyone home at 21:00." end
    local wakeDay=Clock.Minutes<420 and Clock.Day or Clock.Day+1
    if (rested[player] or 0)>=wakeDay then return false,"You have already rested for this morning." end
    local root=player.Character.HumanoidRootPart
    local h=player.Character:FindFirstChildOfClass("Humanoid")
    if h.SeatPart then return false,"Stand beside your bed to rest." end
    sleepers[player]={Character=player.Character,Anchored=root.Anchored}
    root.Anchored=true;h.WalkSpeed=0;player:SetAttribute("Sleeping",true)
    notify(player,"sleep","Sleep well! You wake at 07:00. Your house keeps you safe through the night.")
    tryMorning();return true,"Resting until 07:00."
end
function Service.Upgrade(player,id)
    local house=owned[player];local item=Rules.ById[id]
    if not item or not ready(player) or not house or not player:GetAttribute("HomeInteriorActive") or not near(player,house.Upgrades) then return false,"Visit your home upgrade board." end
    local ok,message,applied=Money.Change(player,-item.Cost,"home:"..id)
    if ok then refresh(player);message=applied and (item.Name.." is ready!") or "You already own this upgrade." end
    return ok,message
end
function Service.Exit(player)
    if Clock.IsCurfew(Clock.Minutes) then return false,"It is curfew. Rest until 07:00." end
    if not ready(player) or not owned[player] or not player:GetAttribute("HomeInteriorActive") or not near(player,owned[player].Exit) then return false,"Walk to your door to go outside." end
    swingDoor(owned[player]:FindFirstChild("InteriorDoor"),true);task.wait(.3)
    player:SetAttribute("HomeInteriorActive",false)
    local entry=homes.StarterHome.Entry
    local out=entry.Position+Vector3.new(0,1.2,0)+entry.CFrame.LookVector*3
    move(player,CFrame.lookAt(out,out+entry.CFrame.LookVector))
    return true,"See you soon!"
end
local function snapshot(player,ok,message)
    return {Ok=ok,Message=message,Upgrades=Service.Upgrades(player),Coins=Money.Balance(player),Sleeping=player:GetAttribute("Sleeping")==true}
end
request.OnServerInvoke=function(player,action,payload)
    if busy[player] or os.clock()-(limits[player] or 0)<.25 then return {Ok=false,Message="One moment!"} end
    limits[player]=os.clock();busy[player]=true
    local ok,result=pcall(function()
        payload=type(payload)=="table" and payload or {}
        local accepted,message=false,"Visit your home to rest or buy upgrades."
        if action=="BeginIntroduction" then
            if player:GetAttribute("HomeIntroductionSeen") then return snapshot(player,false,"Your house is already marked on the map.") end
            if not ready(player) or not player:GetAttribute("EnteredMainWorld") or player:GetAttribute("HomeInteriorActive") then return snapshot(player,false,"Enter BrightHaven first.") end
            Service.Ensure(player);refresh(player)
            player:SetAttribute("HomeIntroductionActive",true)
            accepted=true;message="Welcome to your own house in BrightHaven."
        elseif action=="EndIntroduction" then
            if player:GetAttribute("HomeIntroductionActive") then
                player:SetAttribute("HomeIntroductionActive",false)
                if payload.Completed==true then player:SetAttribute("HomeIntroductionSeen",true) end
            end
            accepted=true;message="Your front door is marked on the map."
        elseif action=="Get" then
            Service.Ensure(player);refresh(player);accepted=true
            local rest=Rules.Rest(Service.Upgrades(player))
            message="Rest restores "..rest.Hunger.." food, "..rest.Thirst.." water, and "..rest.Health.." health points."
        elseif action=="Sleep" then accepted,message=Service.Sleep(player)
        elseif action=="Wake" then Service.Wake(player,false);accepted=true;message="You got up."
        elseif action=="Upgrade" and type(payload.Id)=="string" then accepted,message=Service.Upgrade(player,payload.Id)
        elseif action=="Enter" then accepted,message=Service.Enter(player)
        elseif action=="Exit" then accepted,message=Service.Exit(player) end
        return snapshot(player,accepted,message)
    end)
    busy[player]=nil
    if not ok then warn("[BrightHaven Home]",result);return {Ok=false,Message="Please try again in a moment."} end
    return result
end
homes.StarterHome.Entry.HomeEntry.Triggered:Connect(Service.Enter)
local function bind(player)
    player:SetAttribute("HomePosition",homes.StarterHome.Entry.Position)
    player:SetAttribute("OwnHomeAssigned",true)
    player:SetAttribute("HomeStormRoof",Service.Upgrades(player).StormRoof==true)
    player:SetAttribute("HomeStormShutters",Service.Upgrades(player).StormShutters==true)
    player.CharacterRemoving:Connect(function() release(player);player:SetAttribute("HomeInteriorActive",false);player:SetAttribute("HomeIntroductionActive",false) end)
    player.CharacterAdded:Connect(function(character)
        task.delay(1,function()
            if player.Character==character and Clock.IsCurfew(Clock.Minutes) then
                player:SetAttribute("CurfewDay",nil);Service.ForceCurfew(player)
            end
        end)
    end)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
Players.PlayerRemoving:Connect(function(player)
    release(player)
    if owned[player] then owned[player]:Destroy() end
    owned[player],rested[player],busy[player],limits[player]=nil,nil,nil,nil
    task.delay(.2,tryMorning)
end)
function Service.ForceCurfew(player)
    if not Clock.Eligible(player) or player:GetAttribute("ClinicRecovering") or player:GetAttribute("Sleeping") or player:GetAttribute("CurfewDay")==Clock.Day then return false end
    player:SetAttribute("CurfewDay",Clock.Day);player:SetAttribute("CurfewResting",true)
    local taxi=require(game.ServerScriptService.BrighthavenTransit.TaxiService)
    if taxi.ForceRest then taxi.ForceRest(player) end
    local shuttle=require(game.ServerScriptService.BrighthavenTransit.SchoolShuttleService)
    if shuttle.ForceRest then shuttle.ForceRest(player) end
    local character=player.Character;local h=character and character:FindFirstChildOfClass("Humanoid")
    if h then
        local seat=h.SeatPart;if seat then local weld=seat:FindFirstChild("SeatWeld");if weld then weld:Destroy() end end
        h.Sit=false
    end
    local house=Service.Ensure(player)
    player:SetAttribute("HomeInteriorActive",true)
    notify(player,"curfew","21:00 curfew! Returning to your own house for a safe night's rest.")
    task.delay(.8,function()
        if player.Character~=character or not h or h.Health<=0 then player:SetAttribute("CurfewResting",nil);return end
        local root=character:FindFirstChild("HumanoidRootPart");root.Anchored=false
        move(player,CFrame.new(house.Bed.Position+Vector3.new(0,1.5,2)))
        player:SetAttribute("CurfewResting",nil)
        Service.Sleep(player)
    end)
    return true
end
Clock.Changed:Connect(function(minutes)
    if minutes>=Rules.CurfewMinutes then
        for _,player in ipairs(Players:GetPlayers()) do Service.ForceCurfew(player) end
    end
    if minutes>=420 and minutes<1080 then for player in sleepers do Service.Wake(player,true) end end
end)
return Service
