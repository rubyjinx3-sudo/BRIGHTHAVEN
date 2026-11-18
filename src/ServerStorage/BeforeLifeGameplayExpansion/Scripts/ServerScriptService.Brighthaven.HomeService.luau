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
            elseif p:IsA("PointLight") then p.Enabled=upgrades[model.Name]==true end
        end
    end
    player:SetAttribute("HomePosition",homes.StarterHome.Entry.Position)
end
function Service.Ensure(player)
    if owned[player] then return owned[player] end
    nextSlot+=1
    local house=SS.BrighthavenHomeTemplate:Clone();house.Name="Home_"..player.UserId
    house:PivotTo(CFrame.new(6000+nextSlot*70,0,6000));house:SetAttribute("OwnerUserId",player.UserId)
    local door=Instance.new("Part");door.Name="PrivateDoor";door.Anchored=true;door.Size=Vector3.new(7,10,.6)
    door.Color=Color3.fromRGB(255,211,78);door.CFrame=house.Floor.CFrame*CFrame.new(0,5.3,13.7);door.Parent=house
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
function Service.Enter(player)
    if not ready(player) or not near(player,homes.StarterHome.Entry) then return false,"Walk to your front door." end
    local h=player.Character:FindFirstChildOfClass("Humanoid")
    if h.SeatPart or player:GetAttribute("SchoolShuttleRiding") or player:GetAttribute("BrighthavenRiding") then return false,"Get off your ride first." end
    local house=Service.Ensure(player)
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
    task.delay(2,function()
        if Clock.CanSleep() and allAsleep() then Clock.Morning() end
        skipPending=false
    end)
end
function Service.Sleep(player)
    local house=owned[player]
    if not ready(player) or not house or not player:GetAttribute("HomeInteriorActive") or not near(player,house.Bed) then return false,"Rest at your own bed." end
    if not Clock.CanSleep() then return false,"It is daytime. You can sleep when evening rain starts at 18:00." end
    local wakeDay=Clock.Minutes<420 and Clock.Day or Clock.Day+1
    if (rested[player] or 0)>=wakeDay then return false,"You have already rested for this morning." end
    local root=player.Character.HumanoidRootPart
    local h=player.Character:FindFirstChildOfClass("Humanoid")
    if h.SeatPart then return false,"Stand beside your bed to rest." end
    sleepers[player]={Character=player.Character,Anchored=root.Anchored}
    root.Anchored=true;h.WalkSpeed=0;player:SetAttribute("Sleeping",true)
    notify(player,"sleep","Sleep well! You wake at 07:00. If other players are still outside, you can get up while you wait.")
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
    if not ready(player) or not owned[player] or not player:GetAttribute("HomeInteriorActive") or not near(player,owned[player].Exit) then return false,"Walk to your door to go outside." end
    player:SetAttribute("HomeInteriorActive",false)
    move(player,CFrame.new(homes.StarterHome.Entry.Position+Vector3.new(0,1.5,7)))
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
        if action=="Get" then
            accepted=true
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
    player.CharacterRemoving:Connect(function() release(player);player:SetAttribute("HomeInteriorActive",false) end)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
Players.PlayerRemoving:Connect(function(player)
    release(player)
    if owned[player] then owned[player]:Destroy() end
    owned[player],rested[player],busy[player],limits[player]=nil,nil,nil,nil
    task.delay(.2,tryMorning)
end)
Clock.Changed:Connect(function(minutes)
    if minutes>=420 and minutes<1080 then for player in sleepers do Service.Wake(player,true) end end
end)
return Service
