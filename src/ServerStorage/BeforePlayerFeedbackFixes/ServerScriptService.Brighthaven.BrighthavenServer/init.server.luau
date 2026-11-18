local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Brighthaven = ReplicatedStorage:WaitForChild("Brighthaven")
local Practice = require(Brighthaven:WaitForChild("TutorialPractice"))
local Remotes = Brighthaven:WaitForChild("Remotes")
local ClientRequest = Remotes:WaitForChild("ClientRequest")
local ServerNotice = Remotes:WaitForChild("ServerNotice")

local Settings = require(Brighthaven:WaitForChild("Settings"))
local MissionData = require(Brighthaven:WaitForChild("MissionData"))
local AnalyticsTracker = require(script.Parent.AnalyticsTracker)
local MissionManager = require(script.Parent.MissionManager)
local BoostTerminalController = require(script.Parent.BoostTerminalController)
local SchoolShuttle = require(game.ServerScriptService.BrighthavenTransit:WaitForChild("SchoolShuttleService"))
local Flashback = require(script.Parent:WaitForChild("FlashbackService"))

local profiles = {}
local Money=require(script.Parent:WaitForChild("MoneyService"))
local Care=require(script.Parent:WaitForChild("SurvivalService"))
local moneyBusy={}
local function copy(value)
    if type(value)~="table" then return value end
    local result={}
    for key,item in pairs(value) do result[key]=copy(item) end
    return result
end
SchoolShuttle.SetEligibility(function(player)
    local profile = profiles[player.UserId]
    return profile ~= nil and profile.TutorialComplete and player:GetAttribute("CaptainMetThisVisit") == true
end)
local currentDay = 1
local profileStore = nil

if not RunService:IsStudio() then
    pcall(function()
        profileStore = DataStoreService:GetDataStore(Settings.ProfileStoreName)
    end)
end

local function secondsRemaining()
    return (1440-(ReplicatedStorage:GetAttribute("TownMinutes") or 420))*Settings.DayDurationSeconds/1440
end

local function newOrLoadedProfile(player)
    local profile = AnalyticsTracker.NewProfile(player)
    if profileStore then
        local ok, saved = pcall(function()
            return profileStore:GetAsync("player_" .. player.UserId)
        end)
        if ok and type(saved) == "table" then
            for key, value in pairs(saved) do
                profile[key] = value
            end
        end
    end
    profile=AnalyticsTracker.NormalizeProfile(profile, player)
    Money.ImportSchool(player,profile)
    return profile
end

local function saveProfile(player)
    local profile = profiles[player.UserId]
    if not profile or not profileStore then return false end

    local saveData = AnalyticsTracker.PrepareForSave(profile)
    local lastError = nil
    for attempt = 1, Settings.Persistence.SaveRetries do
        local ok, err = pcall(function()
            profileStore:SetAsync("player_" .. player.UserId, saveData)
        end)
        if ok then
            return true
        end
        lastError = err
        task.wait(0.4 * attempt)
    end
    warn("[Brighthaven] Save failed for", player.UserId, lastError)
    return false
end

local function snapshot(profile)
    local result = AnalyticsTracker.Snapshot(profile, currentDay, secondsRemaining())
    result.CompletedMissionIds = table.clone(profile.CompletedMissionIds)
    return result
end

local function okResponse(profile, message, extra)
    local response = {
        Ok = true,
        Message = message,
        Profile = snapshot(profile),
    }
    if extra then
        for key, value in pairs(extra) do
            response[key] = value
        end
    end
    return response
end

local function failResponse(profile, message, extra)
    local response = {
        Ok = false,
        Message = message,
        Profile = profile and snapshot(profile) or nil,
    }
    if extra then
        for key, value in pairs(extra) do
            response[key] = value
        end
    end
    return response
end

local function ensureStormEvent(profile)
    if profile.Level < 3 then
        return nil
    end

    if profile.EventStorm.LastTriggeredDay ~= currentDay or not profile.EventStorm.Active then
        local event = MissionData.GetStormEvent(currentDay)
        if event then
            event.Day = currentDay
            event.Completed = false
            profile.EventStorm.Active = event
            profile.EventStorm.LastTriggeredDay = currentDay
        end
    end

    return profile.EventStorm.Active
end

local function masteryStatus(profile)
    local _, _, mastery = MissionManager.GetMasteryStatus(profile)
    return mastery
end

local handlers = {}

function handlers.GetProfile(player, payload, profile)
    return okResponse(profile, "Profile loaded.", {
        Missions = MissionData.GetUnlockedMissions(profile.Level),
        Mastery = masteryStatus(profile),
        EventStorm = profile.EventStorm.Active,
        Settings = {
            Upgrades = Settings.Upgrades,
            Version = Settings.Version,
            DayDurationSeconds = Settings.DayDurationSeconds,
        },
    })
end

function handlers.GetMissions(player, payload, profile)
    return okResponse(profile, "Mission board ready.", {
        Missions = MissionData.GetUnlockedMissions(profile.Level),
    })
end

function handlers.CompleteTutorial(player, payload, profile)
    local locations = workspace.BrighthavenPrototype.Locations_1_2
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - locations.Location1_BarangayHall.CaptainKapaPrompt.Position).Magnitude > 22 then
        return failResponse(profile, "Meet Captain Kappa at Barangay Hall first.")
    end
    local ok, message = MissionManager.CompleteTutorial(profile)
    if not ok then return failResponse(profile, message) end
    player:SetAttribute("CaptainMetThisVisit", true)
    saveProfile(player)
    local flashbackToken = Flashback.Begin(player)
    return okResponse(profile, message, {
        TutorialSteps = MissionData.TutorialSteps,
        FlashbackToken = flashbackToken,
    })
end

function handlers.StartMission(player, payload, profile)
    if player:GetAttribute("CaptainMetThisVisit") ~= true then
        return failResponse(profile, "Talk to Captain Kappa at Barangay Hall first.")
    end
    local volunteer = workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation.SchoolVolunteerPrompt
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - volunteer.Position).Magnitude > 45 then
        return failResponse(profile, "Talk to the School Helper at the school first.")
    end
    local ok, message, mission, active = MissionManager.StartMission(profile, payload and payload.MissionId)
    if not ok then
        return failResponse(profile, message)
    end
    return okResponse(profile, message, {
        Mission = mission,
        ActiveMission = active,
        FactorAssist = {
            Suggestions = {},
        },
    })
end

function handlers.TravelToSchool(player, payload, profile)
    local ok, message = SchoolShuttle.Board(player)
    return ok and okResponse(profile, message) or failResponse(profile, message)
end

function handlers.BeginMission(player, payload, profile)
    local ok, message, active = MissionManager.BeginMission(profile)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    return okResponse(profile, message, { ActiveMission = active })
end

function handlers.SubmitEqualShare(player, payload, profile)
    local ok, message, active = MissionManager.SubmitEqualShare(profile, payload and payload.Quotient, payload and payload.Remainder)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    return okResponse(profile, message, { ActiveMission = active })
end

function handlers.GetFactorAssist(player, payload, profile)
    local ok, message, data = MissionManager.GetFactorAssist(profile)
    if not ok then
        return failResponse(profile, message)
    end
    return okResponse(profile, message, { FactorAssist = data })
end

function handlers.UseHint(player, payload, profile)
    local ok, message, active = MissionManager.UseHint(profile)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    return okResponse(profile, message, { ActiveMission = active, Hint = message })
end

function handlers.SubmitChunk(player, payload, profile)
    local ok, message, active = MissionManager.SubmitChunk(profile, payload and payload.ChunkQuotient)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    return okResponse(profile, message, { ActiveMission = active })
end

local function schoolCarry(player, active)
    local backpack=player:FindFirstChildOfClass("Backpack")
    if not backpack then return end
    local previous=backpack:FindFirstChild("SchoolFoodBundle") or player.Character and player.Character:FindFirstChild("SchoolFoodBundle")
    local pending=active and active.PendingChunk
    if not pending or pending.Step~="deliver" then if previous then previous:Destroy() end;return end
    if previous then return end
    local tool=Instance.new("Tool");tool.Name="SchoolFoodBundle";tool.CanBeDropped=false
    local mission=MissionData.GetMissionForActive(active)
    tool.ToolTip=mission.Resource.." for our classrooms"
    local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(1.6,.8,1.2)
    handle.Transparency=1;handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
    local template=mission.Resource=="water bottles" and "ReliefWaterBottle" or mission.Resource=="care kits" and "ReliefCareKit" or "ReliefFoodPack"
    local pack=ReplicatedStorage.Brighthaven[template]:Clone()
    pack.Name="FoodPacks";pack:PivotTo(handle.CFrame);pack.Parent=tool
    for _,part in ipairs(pack:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored=false;part.CanCollide=false;part.CanTouch=false;part.Massless=true
            local weld=Instance.new("WeldConstraint");weld.Part0=handle;weld.Part1=part;weld.Parent=handle
        elseif part:IsA("LuaSourceContainer") or part:IsA("ProximityPrompt") then part:Destroy() end
    end
    tool.Parent=backpack
    local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then humanoid:EquipTool(tool) end
end

function handlers.SchoolStep(player, payload, profile)
    payload = type(payload) == "table" and payload or {}
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local school=workspace.BrighthavenPrototype.Locations_1_2.Location2_SchoolEvacuation
    local anchor=school.SchoolVolunteerPrompt
    if payload.Action=="deliver" then
        local index=tonumber(payload.Number)
        local classroom=index and index%1==0 and index>=1 and index<=7 and school:FindFirstChild("ClassroomTent_"..index)
        anchor=classroom and classroom:FindFirstChild("TentLabelPost")
    end
    local range=payload.Action=="deliver" and 10 or 100
    if not root or not anchor or (root.Position-anchor.Position).Magnitude>range then return failResponse(profile,"Walk to the school helper or the classroom supply box.") end
    local ok,message,active=MissionManager.SchoolStep(profile,payload.Action,payload.Number,payload.Token)
    schoolCarry(player,active)
    if not ok then return failResponse(profile,message,{ActiveMission=active}) end
    return okResponse(profile,message,{ActiveMission=active})
end

function handlers.ConfirmRemainder(player, payload, profile)
    local ok, message, active = MissionManager.ConfirmRemainder(profile, payload and payload.Quotient, payload and payload.Remainder, payload and payload.Decision)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    return okResponse(profile, message, { ActiveMission = active })
end

function handlers.VerifyMission(player, payload, profile)
    local ok, message, active = MissionManager.VerifyMission(profile, payload and payload.Quotient, payload and payload.Divisor, payload and payload.Remainder, payload and payload.Dividend)
    if not ok then
        return failResponse(profile, message, { ActiveMission = active })
    end
    saveProfile(player)
    return okResponse(profile, message, { ActiveMission = active })
end

function handlers.BuyUpgrade(player, payload, profile)
    local ok, message, data = MissionManager.BuyUpgrade(profile, payload and payload.UpgradeId)
    if not ok then
        return failResponse(profile, message)
    end
    saveProfile(player)
    return okResponse(profile, message, { Upgrade = data })
end

function handlers.StartBoost(player, payload, profile)
    local ok, data = BoostTerminalController.Start(profile, currentDay)
    if not ok then
        return failResponse(profile, data.Message, { Boost = data })
    end
    return okResponse(profile, data.Message, { Boost = data })
end

function handlers.SubmitBoost(player, payload, profile)
    local won, data = BoostTerminalController.Submit(profile, payload and payload.Answer, currentDay)
    saveProfile(player)
    return okResponse(profile, data.Message, { Boost = data })
end

function handlers.ResetPrototype(player, payload, profile)
    profiles[player.UserId] = AnalyticsTracker.NewProfile(player)
    return okResponse(profiles[player.UserId], "Prototype profile reset.", {
        Missions = MissionData.GetUnlockedMissions(1),
    })
end

function handlers.PrepareDemoProfile(player, payload, profile)
    profile.TutorialComplete = true
    profile.Level = MissionData.MaxLevel
    profile.Coins = math.max(profile.Coins, 250)
    profile.XP = math.max(profile.XP, 360)
    profile.Trust = math.max(profile.Trust, 12)
    profile.CompletedLevelCounts["1"] = math.max(profile.CompletedLevelCounts["1"] or 0, 1)
    profile.CompletedLevelCounts["2"] = math.max(profile.CompletedLevelCounts["2"] or 0, 1)
    profile.Mastery.Ready = false
    profile.Mastery.RemediationRequired = false
    profile.Mastery.Active = nil
    ensureStormEvent(profile)
    saveProfile(player)
    return okResponse(profile, "Demo profile ready: storm missions, budgeting, upgrades, analytics, and all rescue levels are available.", {
        Missions = MissionData.GetUnlockedMissions(profile.Level),
        Mastery = masteryStatus(profile),
        EventStorm = profile.EventStorm.Active,
    })
end

function handlers.GetDayInfo(player, payload, profile)
    return okResponse(profile, "Day info ready.", {
        Day = currentDay,
        SecondsRemaining = secondsRemaining(),
    })
end

function handlers.GetMasteryStatus(player, payload, profile)
    local ok, message, mastery = MissionManager.GetMasteryStatus(profile)
    return okResponse(profile, message, { Mastery = mastery })
end

function handlers.StartMasteryCheck(player, payload, profile)
    local ok, message, mastery = MissionManager.StartMasteryCheck(profile)
    if not ok then
        return failResponse(profile, message, { Mastery = mastery })
    end
    return okResponse(profile, message, { Mastery = mastery })
end

function handlers.SubmitMasteryAnswer(player, payload, profile)
    local ok, message, mastery = MissionManager.SubmitMasteryAnswer(
        profile,
        payload and payload.Quotient,
        payload and payload.Remainder,
        payload and payload.VerifyQuotient,
        payload and payload.VerifyDivisor,
        payload and payload.VerifyRemainder,
        payload and payload.VerifyDividend
    )
    if ok then
        saveProfile(player)
        return okResponse(profile, message, { Mastery = mastery })
    end
    return failResponse(profile, message, { Mastery = mastery })
end

function handlers.GetStormEvent(player, payload, profile)
    local event = ensureStormEvent(profile)
    if not event then
        return okResponse(profile, "Storm events unlock at Level 3.", { EventStorm = { Available = false } })
    end
    return okResponse(profile, event.Title .. " briefing ready.", { EventStorm = event })
end

function handlers.StartStormMission(player, payload, profile)
    local event = ensureStormEvent(profile)
    if not event then
        return failResponse(profile, "Storm events unlock at Level 3.")
    end

    local ok, message, mission, active = MissionManager.StartMission(profile, event.MissionId)
    if not ok then
        return failResponse(profile, message, { EventStorm = event })
    end
    MissionManager.AttachStormEvent(profile, event)
    return okResponse(profile, "Storm mission launched: " .. event.Title .. ".", {
        Mission = mission,
        ActiveMission = profile.ActiveMission,
        EventStorm = event,
    })
end

ClientRequest.OnServerInvoke = function(player, action, payload)
    local profile = profiles[player.UserId]
    if not profile then
        profile = newOrLoadedProfile(player)
        profiles[player.UserId] = profile
    end

    if action ~= "GetProfile" and action ~= "GetMissions" and not Practice.CanUseWorld(player) then
        return failResponse(profile, "This is practice. Quests and XP start in the main world.")
    end
    local handler = handlers[action]
    if not handler then
        return failResponse(profile, "Unknown Brighthaven action: " .. tostring(action))
    end

    if moneyBusy[player] then return failResponse(profile,"One moment! Please try again.") end
    if (action=="PrepareDemoProfile" or action=="ResetPrototype") and not RunService:IsStudio() then
        return failResponse(profile,"That action is only available in Studio.")
    end
    if not Money.ImportSchool(player,profile) then return failResponse(profile,"Your coins are still loading. Please try again.") end
    moneyBusy[player]=true
    local previous=copy(profile)
    local before=profile.Coins
    local ok, result = pcall(handler, player, payload or {}, profile)
    if ok and result and result.Ok and profiles[player.UserId]==profile and profile.Coins~=before then
        local delta=profile.Coins-before
        local paid,message=Money.Change(player,delta,"school:"..game:GetService("HttpService"):GenerateGUID(false))
        if not paid then
            profiles[player.UserId]=previous;profile=previous
            saveProfile(player)
            result=failResponse(profile,message)
        else
            profile.Coins=Money.Balance(player);saveProfile(player)
            if result.Profile then result.Profile.Coins=profile.Coins end
        end
    end
    moneyBusy[player]=nil
    if not ok then
        warn("[Brighthaven] Request failed", action, result)
        return failResponse(profile, "The prototype hit a server error. Check Output for details.")
    end

    if result and result.Ok and profile.ActiveMission and profile.ActiveMission.Rewarded then
        Care.RewardSupplies(player,"school:"..tostring(profile.SchoolSerial or 0))
    end
    return result
end

Players.PlayerAdded:Connect(function(player)
    local profile = newOrLoadedProfile(player)
    profiles[player.UserId] = profile

    local welcomed = false
    player.CharacterAdded:Connect(function()
        if not player:GetAttribute("ClinicRecovering") then player:SetAttribute("CaptainMetThisVisit", false) end
        player:SetAttribute("SchoolShuttleArrived", false)
        task.delay(1, function()
            if player.Parent and Practice.CanUseWorld(player) then schoolCarry(player, profile.ActiveMission) end
        end)
        if welcomed then return end
        welcomed = true
        task.delay(2, function()
            if not player.Parent or not Practice.CanUseWorld(player) then return end
            if profile.TutorialComplete then
                ServerNotice:FireClient(player, {
                    Type = "info",
                    Speaker = "Captain Kappa",
                    Action = "CaptainReturn",
                    Message = "Welcome back! Talk to Captain Kappa at Barangay Hall first.",
                })
            else
                ServerNotice:FireClient(player, {
                    Type = "info",
                    Speaker = "Captain Kappa",
                    Action = "CaptainWelcome",
                    Message = "Welcome to Brighthaven! Meet Captain Kappa at Barangay Hall. Then help the school share food packs.",
                })
            end
        end)
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    saveProfile(player)
    profiles[player.UserId] = nil
    moneyBusy[player]=nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    profiles[player.UserId] = newOrLoadedProfile(player)
end

task.spawn(function()
    while true do
        task.wait(1)
        for _, profile in pairs(profiles) do
            profile.Stats.TimePlayedSeconds = (profile.Stats.TimePlayedSeconds or 0) + 1
        end

        local townDay=ReplicatedStorage:GetAttribute("TownDay") or 1
        if townDay~=currentDay then
            currentDay=townDay
            for _, profile in pairs(profiles) do
                profile.Stats.StormsSurvived += 1
                profile.EventStorm.Active = nil
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(Settings.Persistence.AutosaveSeconds)
        for _, player in ipairs(Players:GetPlayers()) do
            saveProfile(player)
        end
    end
end)

print("[Brighthaven] Prototype server online")

