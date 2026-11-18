local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local campaign = ReplicatedStorage.Brighthaven:WaitForChild("Campaign")
local Practice = require(ReplicatedStorage.Brighthaven:WaitForChild("TutorialPractice"))
local Data = require(campaign.CampaignData)
local ActivitySites=require(campaign:WaitForChild("ActivitySites"))
local Engine = require(script.Parent.CampaignEngine)
local Quests = require(campaign.QuestData)
local Side = require(campaign.SideQuestData)
local Progress = require(script.Parent.QuestProgress)
local Targets = require(ReplicatedStorage.Brighthaven:WaitForChild("QuestTargets"))
local NavigationRoutes = require(script.Parent:WaitForChild("NavigationRoutes"))
local Locations=require(ReplicatedStorage.Brighthaven:WaitForChild("MapLocations"))
local Money=require(game.ServerScriptService.Brighthaven:WaitForChild("MoneyService"))
local Care=require(game.ServerScriptService.Brighthaven:WaitForChild("SurvivalService"))
local Bag=require(game.ServerScriptService.Brighthaven:WaitForChild("InventoryService"))
local Activities=require(script.Parent:WaitForChild("WorldActivities"))
local routeLimits, routeBusy = {}, {}
local Analytics = require(game.ServerScriptService.Brighthaven.AnalyticsTracker)
local remote = campaign:WaitForChild("Request")
local changed = campaign:WaitForChild("QuestChanged")
local profiles, pendingSchool, loading, dirty, busy, limits, loadFailed = {}, {}, {}, {}, {}, {}, {}
local store
if not RunService:IsStudio() then
    local ok, result = pcall(function() return DataStoreService:GetDataStore("BrightHaven_StoryExtension_v3") end)
    if ok then store = result end
end

-- Observe trusted school progress without replacing any existing script or response.
local pendingBriefing, pendingSchoolActive, pendingXP = {}, {}, {}
local originalSnapshot = Analytics.Snapshot
Analytics.Snapshot = function(profile, ...)
    pendingXP[profile.UserId] = math.max(pendingXP[profile.UserId] or 0, profile.XP or 0)
    if profile.TutorialComplete then pendingBriefing[profile.UserId] = true end
    local active = profile.ActiveMission
    pendingSchoolActive[profile.UserId] = active and active.Id == "school_evacuation_144_6" and active.Phase ~= "complete"
        and {Phase = active.Phase, Remaining = active.Remaining, Dividend = active.Dividend, Divisor = active.Divisor} or nil
    if profile.CompletedMissionIds and profile.CompletedMissionIds.school_evacuation_144_6 then
        pendingSchool[profile.UserId] = true
        local own = profiles[profile.UserId]
        if own and not own.SchoolComplete then own.SchoolComplete = true; dirty[profile.UserId] = true end
    end
    local own = profiles[profile.UserId]
    if own then
        if pendingXP[profile.UserId] > own.BaseXP then own.BaseXP = pendingXP[profile.UserId]; dirty[profile.UserId] = true end
        if pendingBriefing[profile.UserId] and not own.CaptainBriefed then own.CaptainBriefed = true; dirty[profile.UserId] = true end
        own.SchoolActive = pendingSchoolActive[profile.UserId]
        local player = Players:GetPlayerByUserId(profile.UserId)
        if player then changed:FireClient(player, Engine.Snapshot(own)) end
    end
    return originalSnapshot(profile, ...)
end

local function load(player)
    local id = player.UserId
    if profiles[id] then return profiles[id] end
    if loadFailed[id] then return nil end
    if loading[id] then
        while loading[id] and player.Parent do task.wait(.1) end
        return profiles[id]
    end
    loading[id] = true
    local saved
    if store then
        local ok, value = pcall(function() return store:GetAsync("player_" .. id) end)
        if ok then saved = value
        else
            warn("[BrightHaven Campaign] Load failed for", id)
            loadFailed[id], loading[id] = true, nil
            return nil
        end
    end
    if not player.Parent then loading[id] = nil; return nil end
    local profile = Engine.Normalize(saved)
    if pendingSchool[id] then profile.SchoolComplete = true end
    if pendingBriefing[id] then profile.CaptainBriefed = true end
    profile.SchoolActive = pendingSchoolActive[id]
    profile.BaseXP = math.max(profile.BaseXP, pendingXP[id] or 0)
    profiles[id], loading[id] = profile, nil
    return profile
end

local function save(id)
    local profile = profiles[id]
    if not profile or not store or not dirty[id] then return end
    local snapshot = Engine.Snapshot(profile)
    dirty[id] = nil
    for attempt = 1, 3 do
        local ok = pcall(function()
            store:UpdateAsync("player_" .. id, function(old)
                local merged = Engine.Normalize(old)
                merged.SchoolComplete = merged.SchoolComplete or snapshot.SchoolComplete
                merged.CaptainBriefed = merged.CaptainBriefed or snapshot.CaptainBriefed
                merged.StoryFinished = merged.StoryFinished or snapshot.StoryFinished
                for key, accepted in pairs(snapshot.Accepted) do if accepted then merged.Accepted[key] = true end end
                for key, done in pairs(snapshot.Completed) do if done then merged.Completed[key] = true end end
                for key, done in pairs(snapshot.InstalledParts) do if done then merged.InstalledParts[key] = true end end
                merged.Active = snapshot.Active
                merged.MasteryResumeNode=snapshot.MasteryResumeNode
                Progress.Merge(merged, snapshot)
                Engine.MergeKPIs(merged,snapshot.LearningKPIs)
                merged.AnswerReview=require(game.ServerScriptService.Brighthaven.AnswerReview).Merge(merged.AnswerReview,snapshot.AnswerReview)
                Engine.Rebuild(merged)
                return merged
            end)
        end)
        if ok then return end
        task.wait(attempt * .5)
    end
    dirty[id] = true
    warn("[BrightHaven Campaign] Save failed for", id)
end

local function near(player, node, range)
    local location = ActivitySites.Resolve(player,node)
    local anchor = location and location:FindFirstChild("HelperAnchor")
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if anchor and root and (root.Position-anchor.Position).Magnitude<=(range or 20) then return true end
    local log=node=="wood" and location and location:FindFirstChild("ChoppingLog")
    return log and root and (root.Position-log.Position).Magnitude<=(range or 20) or false
end

local function response(profile, ok, message, extra)
    local result = {Ok = ok, Message = message, State = Engine.Snapshot(profile)}
    for key, value in pairs(extra or {}) do result[key] = value end
    return result
end

local function handle(player, action, payload, profile)
    if action == "GetState" then return response(profile, true, "Your journey is ready.") end
    if action == "CallTruckDriver" then
        if not profile.SchoolComplete then
            return response(profile,false,"Finish sharing food at the school before calling Kuya Nestor.")
        end
        return response(profile,true,"Kuya Nestor is on the radio!",{
            Driver="Kuya Nestor",Destination="dumpsite",Fare=Money.Fare,
            ActivityUnlocked=Engine.Unlocked(profile,"dumpsite"),
            ActivityGuidance=Engine.LockMessage(profile,"dumpsite"),
        })
    end
    if action=="ActivityEquip" or action=="ActivityChop" or action=="ActivityShoot" or action=="ActivityUse" then
        local ok,message,shot=Activities.Handle(player,action,payload,profile,Engine)
        if ok then dirty[player.UserId]=true end
        return response(profile,ok,message,{Shot=shot})
    end
    if action == "SideMeet" or action == "SideAccept" or action == "SideAnswer" or action == "SideCollect" or action == "SideFinish" or action == "SideShare" then
        local quest = Side.ById[payload.Id]
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local anchor = quest and Side.Anchor(quest)
        if action == "SideCollect" then
            local area = workspace:FindFirstChild("BrighthavenSideQuests")
            local group = quest and area and area:FindFirstChild(quest.Id)
            local item = type(payload.Item) == "string" and group and group:FindFirstChild(payload.Item)
            anchor = item and item.PrimaryPart
        end
        if not root or not anchor or (root.Position - anchor.Position).Magnitude > 14 then
            return response(profile, false, "Walk closer to your neighbor or the quest item.")
        end
        local ok, message
        if action == "SideMeet" then ok, message = Progress.Meet(profile, payload.Id)
        elseif action == "SideAccept" then ok, message = Progress.Accept(profile, payload.Id)
        elseif action == "SideAnswer" then ok, message = Progress.Answer(profile, payload.Id, payload.Choice, payload.Step)
        elseif action == "SideCollect" then ok, message = Progress.Collect(profile, payload.Id, payload.Item)
        elseif action == "SideShare" then ok, message = Progress.Share(profile, payload.Id, payload.Step, payload.Number, payload.Token)
        else ok, message = Progress.Finish(profile, payload.Id) end
        if ok or action=="SideShare" then dirty[player.UserId] = true end
        return response(profile, ok, message)
    end
    if action=="BeginEnding" then
        if not profile.Victory then return response(profile,false,"Finish the lab first.") end
        player:SetAttribute("StoryEndingPlaying",true)
        task.delay(60,function() if player.Parent then player:SetAttribute("StoryEndingPlaying",nil) end end)
        return response(profile,true,"The final storm is approaching.")
    elseif action=="FinishEnding" then require(game.ServerScriptService.Brighthaven.RandomWeatherService).SetWeather("Clear",90,2);player:SetAttribute("StoryEndingPlaying",nil);return response(profile,true,"BrightHaven celebrates!") end
    if action == "FinishStory" then
        local anchor = workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not profile.Victory or not root or (root.Position - anchor.Position).Magnitude > 22 then
            return response(profile, false, "Finish the lab jobs, then talk to Captain Kappa at Barangay Hall.")
        end
        profile.StoryFinished = true
        player:SetAttribute("CaptainMetThisVisit", true)
        dirty[player.UserId] = true
        return response(profile, true, "Stormbreaker stopped the super typhoon! You and our neighbors saved BrightHaven.")
    end
    if action == "TravelToCaptain" or action == "WelcomeRide" or action == "CaptainRide" then
        if action == "WelcomeRide" then
            return response(profile, false, "Talk to Captain Kappa at Barangay Hall first. He is beside the entrance.")
        end
        local entrance = workspace.Portal6.Teleport
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local captainAnchor = workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
        local allowed = action == "TravelToCaptain" and profile.Victory and near(player, "lab", 24)
            or action == "WelcomeRide" and root and (root.Position - entrance.Position).Magnitude <= 25
            or action == "CaptainRide" and profile.CaptainBriefed and root and (root.Position - captainAnchor.Position).Magnitude <= 22
        if not allowed or not root then return response(profile, false, "Use the nearby shuttle helper to take a ride.") end
        local quest = Quests.Current(profile)
        local target = quest.Id
        if action == "CaptainRide" then
            if player:GetAttribute("CaptainMetThisVisit") ~= true then
                return response(profile, false, "Finish talking to Captain Kappa first.")
            end
            if target == "school" then
                return response(profile, true, "Walk to Driver Lito's school shuttle. Get on at the side door.")
            end
        end
        local anchor = workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
        local offset = Vector3.new(-7, 1, 0)
        if action ~= "TravelToCaptain" and target ~= "captain" and target ~= "home" then
            if target == "school" then anchor = workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation.SchoolVolunteerPrompt
            else anchor = workspace.BrighthavenStoryExtension[target].HelperAnchor end
            offset = Vector3.new(0, 1, -6)
        end
        player.Character:PivotTo(CFrame.lookAt(anchor.Position + offset, anchor.Position))
        return response(profile, true, "Your next helper is right here!")
    end
    if action == "Travel" then
        local source, destination = payload.Source, payload.Destination
        local schoolAnchor = workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation.SchoolVolunteerPrompt
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local atSchool = source == "school" and root and (root.Position - schoolAnchor.Position).Magnitude <= 20
        if not Data.Nodes[source] or not Data.Nodes[destination] or not (near(player, source, 24) or atSchool) then
            return response(profile, false, "Talk to a nearby helper before taking a ride.")
        end
        if not Engine.Unlocked(profile, destination) then return response(profile, false, Engine.LockMessage(profile,destination)) end
        if source ~= destination and destination ~= Data.Nodes[source].Next and destination ~= "school" then
            return response(profile, false, "Take the next ride on your journey.")
        end
        if profile.Active and profile.Active.Phase ~= "complete" and destination ~= profile.Active.Node then
            return response(profile, false, "Finish the activity here before taking the next ride.")
        end
        local anchor=destination=="school" and schoolAnchor or workspace.BrighthavenStoryExtension[destination].HelperAnchor
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return response(profile, false, "Your character is not ready yet.") end
        player.Character:PivotTo(CFrame.lookAt(anchor.Position + Vector3.new(0, 1, -6), anchor.Position))
        return response(profile, true, "You arrived at " .. Data.Nodes[destination].Title .. "!", {Arrived = destination})
    end
    local node = profile.Active and profile.Active.Node
    if action == "AcceptQuest" then
        node = payload.Node
    elseif action == "Start" then
        local mission = Data.ById[payload.Id]
        node = mission and mission.Node
    elseif action == "InstallPart" then node = "lab" end
    if not Data.Nodes[node] or not near(player, node) then return response(profile, false, "Stay close to the helper for this activity.") end
    local wasVictory = profile.Victory
    local ok, message
    if action == "AcceptQuest" then ok, message = Engine.AcceptQuest(profile, node)
    elseif action == "Start" then ok, message = Engine.Start(profile, payload.Id)
    elseif action == "Begin" then ok, message = Engine.Begin(profile)
    elseif action == "Chunk" then ok, message = Engine.Chunk(profile, payload.Number)
    elseif action == "ChunkStep" then ok, message = Engine.ChunkStep(profile, payload.Step, payload.Number, payload.Token)
    elseif action == "Hint" then ok, message = Engine.Hint(profile)
    elseif action == "Remainder" then ok, message = Engine.Remainder(profile, payload.Number, payload.Plan)
    elseif action == "Verify" then
        local a=profile.Active;local m=a and Data.ById[a.Id]
        if m and m.Node=="lab" and m.Round==3 and (not Money.HasReceipt(player,"home:StormRoof") or not Money.HasReceipt(player,"home:StormShutters")) then
            return response(profile,false,"Strengthen your own home first: buy Storm Roof and Storm Shutters at your home upgrade board. Then return to finish the beam.")
        end
        ok, message = Engine.Verify(profile, payload.Quotient, payload.Remainder)
    elseif action == "InstallPart" then ok, message = Engine.InstallPart(profile, payload.Index)
    else return response(profile, false, "Choose an action on your screen.") end
    if ok or action=="Verify" or action=="ChunkStep" or action=="Remainder" then dirty[player.UserId] = true end
    return response(profile, ok, message, {Celebrate = profile.Victory and not wasVictory})
end

remote.OnServerInvoke = function(player, action, payload)
    local profile = load(player)
    if not profile then return {Ok = false, Message = "Your saved journey could not load. Please rejoin. Your saved progress has not been changed."} end
    if pendingSchool[player.UserId] and not profile.SchoolComplete then profile.SchoolComplete = true; dirty[player.UserId] = true end
    if pendingBriefing[player.UserId] and not profile.CaptainBriefed then profile.CaptainBriefed = true; dirty[player.UserId] = true end
    if type(action) ~= "string" or type(payload) ~= "table" then return response(profile, false, "Please try that again.") end
    if action ~= "GetState" and not Practice.CanUseWorld(player) then
        return response(profile, false, "This is practice. Quests and XP start in the main world.")
    end
    local now = os.clock()
    if action == "QuestRoute" or action=="MapRoute" then
        if routeBusy[player] or now - (routeLimits[player] or 0) < 1 then return {Ok=false} end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local anchor, helper, title = Targets.Resolve(player, profile, payload.Kind, payload.Id)
        if action=="MapRoute" and Locations.ValidPoint(payload.Position) then
            anchor={Position=payload.Position};helper="Destination";title="My Pin"
        end
        if not root or not anchor then return {Ok=false} end
        routeLimits[player], routeBusy[player] = now, true
        local ok, points, routeType = pcall(NavigationRoutes.Between, root.Position, anchor.Position)
        routeBusy[player] = nil
        return {Ok=ok and points~=nil, Points=ok and points or nil, RouteType=routeType, Helper=helper, Title=title, Target=anchor.Position}
    end
    local window = limits[player.UserId]
    if not window or now - window.Start > 5 then window = {Start = now, Count = 0}; limits[player.UserId] = window end
    window.Count += 1
    if window.Count > 20 or busy[player.UserId] then return response(profile, false, "One moment! The helper is getting ready.") end
    busy[player.UserId] = true
    local before = Progress.Summary(profile)
    local ok, result = pcall(handle, player, action, payload, profile)
    if not ok then busy[player.UserId]=nil;warn("[BrightHaven Campaign] Request failed:", result); return response(profile, false, "Oops! Please try that again.") end
    if result.Ok and Practice.CanUseWorld(player) then
        for id,completed in pairs(profile.Completed) do
            if completed then
                Money.Change(player,10,"quest:"..id)
                Care.RewardSupplies(player,"quest:"..id)
            end
        end
        for id,progress in pairs(profile.SideQuests or {}) do
            if progress.Complete then
                Money.Change(player,5,"side:"..id)
                Care.RewardSupplies(player,"side:"..id)
                Bag.GrantOnce(player,"side:"..id,{HelperBadge=1})
            end
        end
        for index,id in ipairs({"IonStabilizer","AtmosphericCore","WindTurbine"}) do
            if profile.Parts[tostring(index)] then
                Bag.GrantOnce(player,"part:"..id,{[id]=1})
                if profile.InstalledParts[tostring(index)] then Bag.Install(player,id) end
            end
        end
    end
    busy[player.UserId] = nil
    local after = Progress.Summary(profile)
    if result.Ok and after.XP > before.XP then result.Reward = {XP = after.XP - before.XP, LevelUp = after.Level > before.Level} end
    if result.Ok and action ~= "GetState" then changed:FireClient(player, result.State) end
    return result
end

Players.PlayerAdded:Connect(function(player) task.spawn(load, player) end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(load, player) end
Players.PlayerRemoving:Connect(function(player)
    routeLimits[player], routeBusy[player] = nil, nil
    save(player.UserId)
    profiles[player.UserId], pendingSchool[player.UserId], limits[player.UserId] = nil, nil, nil
    pendingBriefing[player.UserId], pendingSchoolActive[player.UserId] = nil, nil
    pendingXP[player.UserId], loadFailed[player.UserId], busy[player.UserId], loading[player.UserId], dirty[player.UserId] = nil, nil, nil, nil, nil
end)
task.spawn(function()
    while true do
        task.wait(45)
        for id in pairs(profiles) do task.spawn(save, id) end
    end
end)
game:BindToClose(function()
    local remaining = 0
    for id in pairs(profiles) do
        remaining += 1
        task.spawn(function() save(id); remaining -= 1 end)
    end
    local start = os.clock()
    while remaining > 0 and os.clock() - start < 25 do task.wait(.1) end
end)

