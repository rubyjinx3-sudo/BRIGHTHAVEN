local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Brighthaven.Settings)
local MissionData = require(ReplicatedStorage.Brighthaven.MissionData)
local FeedbackEngine = require(script.Parent.FeedbackEngine)
local AnalyticsTracker = require(script.Parent.AnalyticsTracker)

local MissionManager = {}
local missionRandom = Random.new()

local function cloneMission(mission)
    local copy = table.clone(mission)
    return copy
end

local function getMissionForActive(activeMission)
    if not activeMission then return nil end
    return MissionData.GetMissionForActive(activeMission)
end

function MissionManager.CompleteTutorial(profile)
    if profile.TutorialComplete then
        return true, "You are ready to help the school!"
    end
    profile.TutorialComplete = true
    profile.Level = math.max(profile.Level, 1)
    profile.XP += 25
    profile.Trust += 2
    return true, "Let's go! Meet the School Helper at the school."
end

function MissionManager.StartMission(profile, missionId)
    local mission = MissionData.GetMission(missionId)
    if not mission then
        return false, "Mission not found."
    end

    if not profile.TutorialComplete then
        return false, "Meet Captain Kappa at Barangay Hall before helping the school."
    end

    if mission.RequiresMission and not profile.CompletedMissionIds[mission.RequiresMission] then
        return false, "Share the food packs first. Then you can share more supplies!"
    end

    if mission.Level > profile.Level then
        return false, "This district is locked. Complete an earlier mission first."
    end

    if mission.RandomFoodPacks then
        local range = mission.RandomFoodPacks
        local perClassroom = missionRandom:NextInteger(range.MinPerClassroom, range.MaxPerClassroom)
        -- Avoid an immediate repeat without changing a round already in progress.
        if perClassroom * mission.Divisor == profile.LastFoodPackTotal and range.MaxPerClassroom > range.MinPerClassroom then
            local previous = perClassroom
            perClassroom = missionRandom:NextInteger(range.MinPerClassroom, range.MaxPerClassroom - 1)
            if perClassroom >= previous then perClassroom += 1 end
        end
        mission = MissionData.GetMissionForActive({
            Id = mission.Id, Dividend = perClassroom * mission.Divisor, Divisor = mission.Divisor,
        })
        profile.LastFoodPackTotal = mission.Dividend
    end

    profile.ActiveMission = {
        Id = mission.Id,
        Title = mission.Title,
        Dividend = mission.Dividend,
        Divisor = mission.Divisor,
        Phase = "briefing",
        Remaining = mission.Dividend,
        RunningQuotient = 0,
        Remainder = nil,
        Chunks = {},
        ClassroomAmounts = table.create(mission.Divisor, 0),
        SchoolSolution = mission.ChunkingFirst == true,
        SolutionVersion = 0,
        HintsUsed = 0,
        EqualShareChecked = false,
        RemainderConfirmed = false,
        VerificationPassed = false,
        Rewarded = false,
        Attempts = {
            EqualShare = 0,
            Remainder = 0,
            Verify = 0,
        },
    }
    profile.SchoolSerial = (profile.SchoolSerial or 0) + 1

    profile.Stats.MissionsStarted += 1

    return true, "Let's help! " .. mission.Title .. ".", cloneMission(mission), profile.ActiveMission
end

function MissionManager.BeginMission(profile)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end
    if active.Phase ~= "briefing" then
        return true, "You can keep sharing!", active
    end

    local mission = getMissionForActive(active)
    active.Phase = mission and mission.ChunkingFirst and "chunking" or "equalShare"
    active.EqualShareChecked = active.Phase == "chunking"
    return true, "Give the same amount to each classroom.", active
end

function MissionManager.GetFactorAssist(profile)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end

    return true, "Factor assist ready.", {
        Divisor = active.Divisor,
        Remaining = active.Remaining,
        Suggestions = FeedbackEngine.FriendlyMultiples(active.Divisor, active.Remaining),
    }
end

function MissionManager.SubmitEqualShare(profile, quotient, remainder)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end
    if active.Phase ~= "equalShare" then
        return false, "The equal share station is already complete."
    end

    active.Attempts.EqualShare += 1
    local ok, message = FeedbackEngine.CheckEqualShare(active.Dividend, active.Divisor, quotient, remainder)
    if not ok then
        profile.Stats.Retries += 1
        profile.Stats.EqualShareErrors += 1
        return false, message, active
    end

    active.EqualShareChecked = true
    active.Phase = "chunking"
    return true, message .. " Share in easy steps to show your work.", active
end

function MissionManager.UseHint(profile)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end

    if active.HintsUsed >= Settings.Progression.MaxHintsPerMission then
        return false, "You used all your hints. Count what is left. You can do it!"
    end

    active.HintsUsed += 1
    profile.Stats.HintsUsed += 1
    return true, FeedbackEngine.HintFor(active), active
end

local function recordChunk(profile, q, subtractAmount, alreadyShared)
    local active = profile.ActiveMission
    local message = "You shared the same chunk with every classroom."
    active.RunningQuotient += q
    if not alreadyShared then active.Remaining -= subtractAmount end
    profile.Stats.ChunkSteps += 1
    table.insert(active.Chunks, {Quotient=q, Amount=subtractAmount, Remaining=active.Remaining})
    if active.Remaining < active.Divisor then
        active.Phase, active.Remainder = "remainder", active.Remaining
        local mission = getMissionForActive(active)
        if mission and mission.ChunkingFirst and active.Remaining == 0 then
            active.RemainderConfirmed, active.Phase = true, "verify"
            message = "Each classroom has the same amount! Let's check your work."
        end
    end
    return true, message, active
end

function MissionManager.SchoolStep(profile, action, value, token)
    local active = profile.ActiveMission
    if not active or not active.SchoolSolution or active.Phase ~= "chunking" then return false, "Start the school sharing activity first.", active end
    local number = tonumber(value)
    if not number or number ~= number or number % 1 ~= 0 or number < 0 or number > 1000000 then return false, "Enter a whole number and try again.", active end
    local pending = active.PendingChunk
    if action == "choose" then
        if pending and pending.Step == "deliver" then return false, "Finish this delivery round before choosing another chunk.", active end
        if number < 1 or number * active.Divisor > active.Remaining then return false, "Try a smaller chunk that fits the supplies left.", active end
        active.SolutionVersion += 1
        active.PendingChunk = {Multiplier=number, Before=active.Remaining, Step="multiply", Delivered={},
            Token=tostring(profile.SchoolSerial)..":"..active.SolutionVersion}
        return true, "Multiply the number of classrooms by your chunk.", active
    end
    if not pending or pending.Token ~= token then return false, "Use the current step in your solution book.", active end
    if action == "multiply" and pending.Step == "multiply" then
        if number ~= active.Divisor * pending.Multiplier then return false, "Count equal groups to check your multiplication. Try again.", active end
        pending.Product, pending.Step = number, "subtract"
        return true, "Now subtract the amount you will share from the supplies left.", active
    elseif action == "subtract" and pending.Step == "subtract" then
        if number ~= pending.Before - pending.Product then return false, "Check your subtraction. How many will be left?", active end
        pending.Leftover, pending.Step = number, "deliver"
        return true, "Your group is ready! Carry the supplies to each classroom.", active
    elseif action == "deliver" and pending.Step == "deliver" then
        if number < 1 or number > active.Divisor or pending.Delivered[tostring(number)] then return false, "Choose a classroom that still needs this chunk.", active end
        active.ClassroomAmounts = active.ClassroomAmounts or table.create(active.Divisor, active.RunningQuotient)
        pending.Delivered[tostring(number)] = true
        active.ClassroomAmounts[number] += pending.Multiplier
        active.Remaining -= pending.Multiplier
        local count = 0
        for _ in pairs(pending.Delivered) do count += 1 end
        if count == active.Divisor then
            assert(active.Remaining == pending.Leftover, "School sharing total changed")
            active.PendingChunk = nil
            return recordChunk(profile, pending.Multiplier, pending.Product, true)
        end
        return true, "Classroom " .. number .. " received its chunk. Keep the other groups fair!", active
    end
    return false, "Finish the step shown in your solution book.", active
end

function MissionManager.SubmitChunk(profile, chunkQuotient)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end
    if active.Phase ~= "chunking" then
        return false, "Let's finish the step on your screen first."
    end
    if active.SchoolSolution then return false, "Work out your chunk in the solution book, then deliver it to the classrooms.", active end

    local number = tonumber(chunkQuotient)
    if not number or number ~= number or number == math.huge or number == -math.huge or number % 1 ~= 0 then
        return false, "Choose a whole number for each classroom.", active
    end
    local ok, message, q, subtractAmount = FeedbackEngine.ValidateChunk(active.Divisor, active.Remaining, number)
    if not ok then
        profile.Stats.Retries += 1
        profile.Stats.ChunkErrors += 1
        return false, message, active
    end

    return recordChunk(profile, q, subtractAmount, false)
end

function MissionManager.ConfirmRemainder(profile, quotient, remainder, decision)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end
    if active.Phase ~= "remainder" then
        return false, "Keep sharing until there is not enough to give one more to each classroom."
    end

    active.Attempts.Remainder += 1
    local ok, message, q, r = FeedbackEngine.CheckQRR(active.Dividend, active.Divisor, quotient, remainder)
    if not ok then
        profile.Stats.Retries += 1
        profile.Stats.RemainderErrors += 1
        return false, message, active
    end

    local mission = getMissionForActive(active)
    local decisionOk, decisionMessage = FeedbackEngine.CheckRemainderDecision(mission, decision)
    if r == 0 then
        decisionOk = true
        decisionMessage = "Nothing is left over. Let's check your sharing!"
    end

    if not decisionOk then
        profile.Stats.Retries += 1
        profile.Stats.RemainderErrors += 1
        return false, decisionMessage, active
    end

    active.RunningQuotient = q
    active.Remainder = r
    active.RemainderDecision = decision
    active.RemainderConfirmed = true
    profile.Stats.RemainderPlans += 1
    if mission and mission.PreferredDecision and decision == mission.PreferredDecision then
        profile.Stats.PreferredRemainderPlans += 1
    end
    active.Phase = "verify"

    return true, message .. " " .. decisionMessage, active
end

function MissionManager.VerifyMission(profile, quotient, divisor, remainder, dividend)
    local active = profile.ActiveMission
    if not active then
        return false, "Start a mission first."
    end
    if active.Phase ~= "verify" then
        return false, "Finish sharing first. Then we can check your answer."
    end
    if active.Rewarded then
        return true, "Mission already submitted.", active
    end

    active.Attempts.Verify += 1
    profile.Stats.VerifyAttempts += 1

    local ok, message = FeedbackEngine.VerifyEquation(quotient, divisor, remainder, dividend)
    if not ok then
        profile.Stats.Retries += 1
        profile.Stats.VerificationErrors += 1
        return false, message, active
    end

    local expectedQ, expectedR = FeedbackEngine.Expected(active.Dividend, active.Divisor)
    if math.floor(tonumber(quotient)) ~= expectedQ or math.floor(tonumber(remainder)) ~= expectedR or math.floor(tonumber(divisor)) ~= active.Divisor or math.floor(tonumber(dividend)) ~= active.Dividend then
        profile.Stats.Retries += 1
        profile.Stats.VerificationErrors += 1
        return false, "Use the numbers for this activity. Let's try again.", active
    end

    active.VerificationPassed = true
    active.Phase = "complete"
    active.Rewarded = true

    local verifyFirstTry = active.Attempts.Verify == 1
    local retryPenalty = (math.max(0, active.Attempts.EqualShare - 1) + math.max(0, active.Attempts.Remainder - 1) + math.max(0, active.Attempts.Verify - 1)) * 6
    local hintPenalty = active.HintsUsed * 5
    local chunkPenalty = math.max(0, #active.Chunks - 2) * 4
    local score = math.max(60, 100 - retryPenalty - hintPenalty - chunkPenalty)

    local mission = getMissionForActive(active)
    local coins, xp = AnalyticsTracker.ApplyMissionReward(profile, mission, score, verifyFirstTry)

    if active.StormEvent then
        profile.Stats.EventStormsCompleted += 1
        if profile.EventStorm and profile.EventStorm.Active and profile.EventStorm.Active.Id == active.StormEvent.Id then
            profile.EventStorm.Active.Completed = true
        end
    end

    active.Score = score
    active.CoinsEarned = coins
    active.XPEarned = xp

    local tutorialMessage = ""
    if not profile.TutorialComplete and active.Id == "school_evacuation_144_6" then
        local _, completeMessage = MissionManager.CompleteTutorial(profile)
        tutorialMessage = " " .. completeMessage
    end

    return true, "Great job! You earned " .. coins .. " coins and " .. xp .. " XP." .. tutorialMessage, active
end

local function masterySnapshot(profile)
    local check = MissionData.GetMasteryCheck(profile.Level)
    local active = profile.Mastery and profile.Mastery.Active or nil
    local snapshot = {
        Available = check ~= nil,
        Ready = profile.Mastery and profile.Mastery.Ready or false,
        Level = profile.Level,
        LastScore = profile.Mastery and profile.Mastery.LastScore or 0,
        RemediationRequired = profile.Mastery and profile.Mastery.RemediationRequired or false,
        Attempts = profile.Mastery and profile.Mastery.Attempts or 0,
        Threshold = check and check.Threshold or Settings.Progression.MissionGatePercent,
        Title = check and check.Title or "All Districts Unlocked",
        UnlocksLevel = check and check.UnlocksLevel or profile.Level,
    }

    if active then
        snapshot.Active = true
        snapshot.Index = active.Index
        snapshot.Total = #active.Problems
        snapshot.Correct = active.Correct
        snapshot.Score = active.Score or 0
        snapshot.Completed = active.Completed or false
        snapshot.Passed = active.Passed or false
        local problem = active.Problems[active.Index]
        if problem then
            snapshot.CurrentProblem = table.clone(problem)
        end
    end

    return snapshot
end

function MissionManager.GetMasteryStatus(profile)
    return true, "Mastery status ready.", masterySnapshot(profile)
end

function MissionManager.StartMasteryCheck(profile)
    local check = MissionData.GetMasteryCheck(profile.Level)
    if not check then
        return false, "All mastery gates are complete for this prototype.", masterySnapshot(profile)
    end
    if not profile.TutorialComplete then
        return false, "Finish Captain Kapa's tutorial before taking a Mastery Check.", masterySnapshot(profile)
    end

    local completedAtLevel = profile.CompletedLevelCounts[tostring(profile.Level)] or 0
    if completedAtLevel < Settings.Progression.RemedialMissionsRequired then
        return false, "Complete one rescue at this level before the Mastery Check.", masterySnapshot(profile)
    end

    profile.Mastery.Attempts += 1
    profile.Mastery.Active = {
        Level = profile.Level,
        Title = check.Title,
        Threshold = check.Threshold,
        UnlocksLevel = check.UnlocksLevel,
        Index = 1,
        Correct = 0,
        Retries = 0,
        Problems = check.Problems,
        Completed = false,
        Passed = false,
        Score = 0,
    }

    return true, check.Title .. " started.", masterySnapshot(profile)
end

function MissionManager.SubmitMasteryAnswer(profile, quotient, remainder, verifyQuotient, verifyDivisor, verifyRemainder, verifyDividend)
    local active = profile.Mastery and profile.Mastery.Active or nil
    if not active or active.Completed then
        return false, "Start a Mastery Check first.", masterySnapshot(profile)
    end

    local problem = active.Problems[active.Index]
    if not problem then
        return false, "Mastery problem missing.", masterySnapshot(profile)
    end

    local ok, message = FeedbackEngine.CheckQRR(problem.Dividend, problem.Divisor, quotient, remainder)
    if not ok then
        active.Retries += 1
        profile.Stats.Retries += 1
        return false, message, masterySnapshot(profile)
    end

    ok, message = FeedbackEngine.VerifyEquation(verifyQuotient, verifyDivisor, verifyRemainder, verifyDividend)
    if not ok then
        active.Retries += 1
        profile.Stats.Retries += 1
        return false, message, masterySnapshot(profile)
    end

    if math.floor(tonumber(verifyQuotient)) ~= math.floor(tonumber(quotient)) or math.floor(tonumber(verifyDivisor)) ~= problem.Divisor or math.floor(tonumber(verifyRemainder)) ~= math.floor(tonumber(remainder)) or math.floor(tonumber(verifyDividend)) ~= problem.Dividend then
        active.Retries += 1
        profile.Stats.Retries += 1
        return false, "Use this problem's numbers in the multiplication check.", masterySnapshot(profile)
    end

    active.Correct += 1
    if active.Index < #active.Problems then
        active.Index += 1
        return true, "Correct. Next Mastery Check rescue is ready.", masterySnapshot(profile)
    end

    active.Score = math.max(0, math.floor((active.Correct / #active.Problems) * 100) - active.Retries * 5)
    active.Completed = true
    active.Passed = active.Score >= active.Threshold
    profile.Mastery.LastScore = active.Score

    if active.Passed then
        profile.Level = math.max(profile.Level, math.min(MissionData.MaxLevel, active.UnlocksLevel))
        profile.Mastery.Ready = false
        profile.Mastery.RemediationRequired = false
        profile.Stats.MasteryPasses += 1
        profile.Trust += 4
        profile.XP += 30
        local passedSnapshot = masterySnapshot(profile)
        profile.Mastery.Active = nil
        return true, "Mastery passed. Level " .. profile.Level .. " districts are unlocked.", passedSnapshot
    end

    profile.Mastery.RemediationRequired = true
    profile.Stats.MasteryRetries += 1
    return false, "Mastery score was " .. active.Score .. "%. Try one more rescue mission, then retake the check.", masterySnapshot(profile)
end

function MissionManager.AttachStormEvent(profile, event)
    local active = profile.ActiveMission
    if active and event then
        active.StormEvent = table.clone(event)
        active.TimeLimitSeconds = event.TimeLimitSeconds
    end
    return active
end

function MissionManager.BuyUpgrade(profile, upgradeId)
    local upgrade = Settings.Upgrades[upgradeId]
    if not upgrade then
        return false, "That upgrade does not exist."
    end

    local owned = profile.Upgrades[upgradeId] or 0
    local cost = upgrade.Cost + owned * 35
    if profile.Coins < cost then
        return false, "Need " .. cost .. " coins for " .. upgrade.Name .. "."
    end

    profile.Coins -= cost
    profile.Upgrades[upgradeId] = owned + 1
    AnalyticsTracker.ApplyUpgrade(profile, upgrade)

    return true, upgrade.Name .. " upgraded. Community Meter improved.", {
        UpgradeId = upgradeId,
        Owned = profile.Upgrades[upgradeId],
        Cost = cost,
    }
end

return MissionManager
