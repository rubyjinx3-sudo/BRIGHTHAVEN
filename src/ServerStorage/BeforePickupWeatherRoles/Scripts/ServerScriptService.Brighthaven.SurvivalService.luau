local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Brighthaven.ItemCatalog)
local Rules=require(RS.Brighthaven.SurvivalRules)
local Practice=require(RS.Brighthaven.TutorialPractice)
local Bag=require(script.Parent.InventoryService)
local Money=require(script.Parent.MoneyService)
local Service={}
local states={}
local clinic,grace,rewardBusy={},{},{}
local function notice(player,kind,message)
    if player.Parent then RS.Brighthaven.WorldCare.Notice:FireClient(player,kind,message) end
end
function Service.State(player) states[player]=states[player] or Rules.New();return states[player] end
function Service.InMainWorld(player)
    if not Practice.CanUseWorld(player) then return false end
    local ch=player.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local h=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root then return false end
    if not player:GetAttribute("HomeInteriorActive") and (math.abs(root.Position.X)>=1200 or math.abs(root.Position.Z)>=1100) then return false end
    if player:GetAttribute("EnteredMainWorld") then return true end
    if root and h and h.Health>0 and h.FloorMaterial~=Enum.Material.Air and math.abs(root.Position.X)<1200
        and math.abs(root.Position.Z)<1100 and root.Position.Y>-160 and root.Position.Y<-110 then
        player:SetAttribute("EnteredMainWorld",true);return true
    end
    return false
end
local function publish(player,s)
    player:SetAttribute("Hunger",math.floor(s.Hunger+.5));player:SetAttribute("Thirst",math.floor(s.Thirst+.5))
    player:SetAttribute("RainExposure",math.floor(s.Exposure));player:SetAttribute("FeelingSick",s.Sick)
    player:SetAttribute("NeedsRest",Rules.IsTired(s) and Service.InMainWorld(player))
end
function Service.Rest(player,amounts)
    local s=Service.State(player)
    s.Hunger=math.min(100,s.Hunger+amounts.Hunger);s.Thirst=math.min(100,s.Thirst+amounts.Thirst)
    s.Exposure=0;s.Sick=false;s.DamageTime=0
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if h and h.Health>0 then h.Health=math.min(h.MaxHealth,h.Health+amounts.Health) end
    publish(player,s)
end
function Service.RewardSupplies(player,id)
    local receipt="meal:"..id
    if rewardBusy[player] then return false end
    rewardBusy[player]=true
    local bag=Bag.Snapshot(player)
    local fresh=bag and not bag.Receipts[receipt]
    local ok=not fresh or Bag.GrantOnce(player,receipt,{FoodPack=1,WaterBottle=1})
    rewardBusy[player]=nil
    if fresh and ok then notice(player,"reward","Thank you for helping! Your bag has a free Food Pack (+40 food) and Water Bottle (+45 water).") end
    return ok
end
function Service.RecordCollapse(player,character)
    if clinic[player] or player.Character~=character or not Service.InMainWorld(player)
        or player:GetAttribute("HasStartedGame")~=true then return false end
    clinic[player]={Receipt="clinic:"..game:GetService("HttpService"):GenerateGUID(false)}
    player:SetAttribute("ClinicRecovering",true)
    player:SetAttribute("Sleeping",false)
    player:SetAttribute("HomeInteriorActive",false)
    return true
end
function Service.RecoverAtClinic(player,character)
    local recovery=clinic[player]
    if not recovery or recovery.Busy then return end;recovery.Busy=true
    local root=character:WaitForChild("HumanoidRootPart",10)
    local h=character:FindFirstChildOfClass("Humanoid")
    if not root or not h then recovery.Busy=false;return end
    task.wait(.5)
    if player.Character~=character then recovery.Busy=false;return end
    local point=workspace.BrighthavenStoryExtension.clinic:WaitForChild("ClinicRecoveryPoint")
    root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    character:PivotTo(point.CFrame)
    h.Health=h.MaxHealth;h.WalkSpeed=16
    local s=Rules.New();s.Hunger=60;s.Thirst=65;states[player]=s
    grace[player]=os.clock()+5;publish(player,s)
    local paid,_,_,charged=Money.ClinicFee(player,recovery.Receipt)
    clinic[player]=nil;player:SetAttribute("ClinicRecovering",false)
    local message="Nurse Ana helped you recover. Treatment cost "..tostring(charged or 0).." coins."
    if paid and (charged or 0)<5 then message..=" The clinic covered the rest." end
    if not paid then message="Nurse Ana helped you recover. Your treatment is free this time because your wallet is unavailable." end
    notice(player,"clinic",message.." Eat, drink, and rest to stay healthy.")
end
function Service.Sheltered(player)
    if player:GetAttribute("SchoolShuttleRiding") or player:GetAttribute("TaxiState")=="Driving" and player:GetAttribute("TaxiKind")=="Tricycle" then return true end
    local ch=player.Character;local head=ch and ch:FindFirstChild("Head")
    if not head then return true end
    local ignore={ch}
    for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore,p.Character) end end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances=ignore;params.RespectCanCollide=true
    local hit=workspace:Raycast(head.Position,Vector3.new(0,120,0),params)
    return hit~=nil
end
local function umbrella(player,open)
    local ch=player.Character;local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local old=ch:FindFirstChild("RainUmbrella");if old then old:Destroy() end
    if open then
        local model=RS.Brighthaven.BagUmbrella:Clone();model.Name="RainUmbrella"
        model:PivotTo(root.CFrame*CFrame.new(0,5.3,0))
        for _,part in ipairs(model:GetDescendants()) do if part:IsA("BasePart") then
            part.Anchored=false;part.Massless=true;part.CanCollide=false;part.CanTouch=false;part.CanQuery=false
            local weld=Instance.new("WeldConstraint");weld.Part0=root;weld.Part1=part;weld.Parent=part
        end end
        model.Parent=ch
    end
    player:SetAttribute("UmbrellaOpen",open);return true
end
function Service.Use(player,index,id)
    local item=Catalog.ById[id]
    local ch=player.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local bag=Bag.Snapshot(player);local slot=bag and bag.Slots[tostring(index)]
    if not Practice.CanUseWorld(player) or not h or h.Health<=0 or not slot or slot.Id~=id or not item then return false,"Choose a supply from your bag in the main world." end
    if not item.Action then return false,"Keep this reward in your bag." end
    if id=="Umbrella" then
        local open=not player:GetAttribute("UmbrellaOpen")
        return umbrella(player,open),open and "Umbrella open. Stay dry!" or "Umbrella closed."
    end
    local s=Service.State(player)
    if item.Hunger and s.Hunger>=99 or item.Thirst and s.Thirst>=99 or item.Health and h.Health>=h.MaxHealth and not s.Sick and s.Exposure==0 then return false,"You don't need that supply yet. Save it for later." end
    local ok,message=Bag.Take(player,index,id)
    if not ok then return false,message end
    if item.Hunger then s.Hunger=math.min(100,s.Hunger+item.Hunger) end
    if item.Thirst then s.Thirst=math.min(100,s.Thirst+item.Thirst) end
    if item.Health then h.Health=math.min(h.MaxHealth,h.Health+item.Health);s.Exposure=0;s.Sick=false;s.DamageTime=0 end
    publish(player,s);return true,item.Name.." used. You're feeling better!"
end
function Service.Step(player,dt)
    local s=Service.State(player);local ch=player.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid")
    local active=player:GetAttribute("HasStartedGame")==true and not player:GetAttribute("BrighthavenFlashbackPlaying")
        and not player:GetAttribute("Sleeping") and not player:GetAttribute("ClinicRecovering")
        and os.clock()>=(grace[player] or 0) and Service.InMainWorld(player) and h and h.Health>0
    local sheltered=true
    if active then sheltered=Service.Sheltered(player) end
    local damage=Rules.Step(s,dt,{Active=active,Raining=RS:GetAttribute("BrightHavenIsNight")==true,Sheltered=sheltered,
        Protected=player:GetAttribute("UmbrellaOpen")==true,Sprinting=player:GetAttribute("Sprinting")==true})
    if damage>0 and h then h:TakeDamage(damage) end
    player:SetAttribute("Sheltered",sheltered);publish(player,s)
end
function Service.Bind(player)
    Service.State(player);publish(player,states[player]);task.spawn(Bag.Bind,player)
    player.CharacterAdded:Connect(function() states[player]=Rules.New();player:SetAttribute("UmbrellaOpen",false);publish(player,states[player]) end)
end
Players.PlayerAdded:Connect(Service.Bind)
for _,p in ipairs(Players:GetPlayers()) do Service.Bind(p) end
Players.PlayerRemoving:Connect(function(player) states[player],clinic[player],grace[player],rewardBusy[player]=nil,nil,nil,nil end)
task.spawn(function() while true do task.wait(1);for _,p in ipairs(Players:GetPlayers()) do Service.Step(p,1) end end end)
return Service

