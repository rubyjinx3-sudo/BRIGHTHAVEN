local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Brighthaven.Settings)

local AnalyticsTracker = {}
local Review=require(script.Parent.AnswerReview)

local function clamp(value, minValue, maxValue)
    return math.max(minValue, math.min(maxValue, value))
end

local function mergeMissing(target, defaults)
    for key, value in pairs(defaults) do
        if target[key] == nil then
            if type(value) == "table" then
                target[key] = table.clone(value)
                mergeMissing(target[key], value)
            else
                target[key] = value
            end
        elseif type(target[key]) == "table" and type(value) == "table" then
            mergeMissing(target[key], value)
        end
    end
end

function AnalyticsTracker.GetRank(xp)
    local current = Settings.Ranks[1]
    local nextRank = nil
    for index, rank in ipairs(Settings.Ranks) do
        if xp >= rank.XP then
            current = rank
            nextRank = Settings.Ranks[index + 1]
        end
    end
    return current, nextRank
end

function AnalyticsTracker.NewProfile(player)
    return {
        UserId = player.UserId,
        DisplayName = player.DisplayName,
        TutorialComplete = false,
        Level = 1,
        Coins = 0,
        Trust = 0,
        XP = 0,
        CommunityMeter = Settings.Progression.BaseCommunityMeter,
        StormRisk = Settings.Progression.BaseStormRisk,
        Upgrades = {
            storage = 0,
            transport = 0,
            reserve = 0,
        },
        Stats = {
            MissionsStarted = 0,
            MissionsCompleted = 0,
            CorrectMissions = 0,
            HintsUsed = 0,
            VerifyAttempts = 0,
            VerifyFirstTry = 0,
            Retries = 0,
            BoostStarted = 0,
            TimedTasks = 0,
            SchoolMathAttempts = 0,
            SchoolMathCorrect = 0,
            TaskSeconds = 0,
            BoostWins = 0,
            BoostLosses = 0,
            StormsSurvived = 0,
            EventStormsCompleted = 0,
            MasteryPasses = 0,
            MasteryRetries = 0,
            CoinsEarned = 0,
            ChunkSteps = 0,
            EqualShareErrors = 0,
            ChunkErrors = 0,
            RemainderErrors = 0,
            VerificationErrors = 0,
            RemainderPlans = 0,
            PreferredRemainderPlans = 0,
            BudgetMissionsCompleted = 0,
            BudgetAmountHandled = 0,
            TimePlayedSeconds = 0,
        },
        Boost = {
            UsedDay = 0,
            ActiveChallengeId = nil,
        },
        Mastery = {
            Active = nil,
            Ready = false,
            LastScore = 0,
            RemediationRequired = false,
            Attempts = 0,
        },
        EventStorm = {
            Active = nil,
            LastTriggeredDay = 0,
        },
        CompletedMissionIds = {},
        CompletedLevelCounts = {},
        ActiveMission = nil,
    }
end

function AnalyticsTracker.NormalizeProfile(profile, player)
    mergeMissing(profile, AnalyticsTracker.NewProfile(player))
    profile.AnswerReview=Review.Merge(profile.AnswerReview)
    profile.UserId = player.UserId
    profile.DisplayName = player.DisplayName
    profile.ActiveMission = nil
    return profile
end

function AnalyticsTracker.PrepareForSave(profile)
    local copy = table.clone(profile)
    copy.ActiveMission = nil
    return copy
end

function AnalyticsTracker.ApplyMissionReward(profile, mission, score, verifyFirstTry)
    local coinReward = math.max(15, math.floor(Settings.Rewards.BaseMissionCoins * score / 100))
    local xpReward = math.max(15, math.floor(Settings.Rewards.BaseMissionXP * score / 100))

    if score >= 95 then
        coinReward += Settings.Rewards.PerfectMissionBonus
    end
    if verifyFirstTry then
        xpReward += Settings.Rewards.VerificationFirstTryBonus
    end

    profile.Coins += coinReward
    profile.Trust += math.max(2, math.floor(score / 20))
    profile.XP += xpReward
    profile.CommunityMeter = clamp(profile.CommunityMeter + math.floor(score / 12), 0, 100)
    profile.StormRisk = clamp(profile.StormRisk - math.floor(score / 25), 0, 100)

    profile.CompletedMissionIds[mission.Id] = true
    local levelKey = tostring(mission.Level or profile.Level)
    profile.CompletedLevelCounts[levelKey] = (profile.CompletedLevelCounts[levelKey] or 0) + 1
    if mission.Level == profile.Level and profile.Level < 3 then
        profile.Mastery.Ready = true
    end

    profile.Stats.MissionsCompleted += 1
    profile.Stats.CorrectMissions += 1
    profile.Stats.CoinsEarned += coinReward
    if mission.Type == "money_budgeting" then
        profile.Stats.BudgetMissionsCompleted += 1
        profile.Stats.BudgetAmountHandled += mission.Dividend or 0
    end
    if verifyFirstTry then
        profile.Stats.VerifyFirstTry += 1
    end

    return coinReward, xpReward
end

function AnalyticsTracker.ApplyUpgrade(profile, upgrade)
    profile.CommunityMeter = clamp(profile.CommunityMeter + upgrade.CommunityDelta, 0, 100)
    profile.StormRisk = clamp(profile.StormRisk + upgrade.StormRiskDelta, 0, 100)
end

function AnalyticsTracker.ApplyBoost(profile, won)
    if won then
        profile.Stats.BoostWins += 1
        profile.Coins += Settings.Rewards.BoostCorrectCoins
        profile.XP += Settings.Rewards.BoostCorrectXP
        profile.Trust += 3
        profile.CommunityMeter = clamp(profile.CommunityMeter + 4, 0, 100)
    else
        profile.Stats.BoostLosses += 1
        profile.StormRisk = clamp(profile.StormRisk + 3, 0, 100)
    end
end

function AnalyticsTracker.Snapshot(profile, currentDay, secondsRemaining)
    local accuracy = 0
    if profile.Stats.MissionsStarted > 0 then
        accuracy = math.floor((profile.Stats.CorrectMissions / profile.Stats.MissionsStarted) * 100)
    end

    local verifyRate = 0
    if profile.Stats.VerifyAttempts > 0 then
        verifyRate = math.floor((profile.Stats.VerifyFirstTry / profile.Stats.VerifyAttempts) * 100)
    end

    local currentRank, nextRank = AnalyticsTracker.GetRank(profile.XP)
    local rankProgress = 1
    local xpToNext = 0
    if nextRank then
        local span = math.max(1, nextRank.XP - currentRank.XP)
        rankProgress = clamp((profile.XP - currentRank.XP) / span, 0, 1)
        xpToNext = math.max(0, nextRank.XP - profile.XP)
    end

    local averageRetries = 0
    if profile.Stats.MissionsStarted > 0 then
        averageRetries = math.floor((profile.Stats.Retries / profile.Stats.MissionsStarted) * 10) / 10
    end

    local scaffold = "Full"
    if profile.Stats.MissionsCompleted >= 4 and accuracy >= 80 and profile.Stats.HintsUsed <= profile.Stats.MissionsCompleted then
        scaffold = "Light"
    elseif profile.Stats.MissionsCompleted >= 2 and accuracy >= 65 then
        scaffold = "Medium"
    end

    return {
        UserId = profile.UserId,
        DisplayName = profile.DisplayName,
        TutorialComplete = profile.TutorialComplete,
        Level = profile.Level,
        Coins = profile.Coins,
        Trust = profile.Trust,
        XP = profile.XP,
        Rank = currentRank.Name,
        NextRank = nextRank and nextRank.Name or "Max Rank",
        RankProgress = rankProgress,
        XPToNext = xpToNext,
        CommunityMeter = profile.CommunityMeter,
        StormRisk = profile.StormRisk,
        Upgrades = table.clone(profile.Upgrades),
        Stats = table.clone(profile.Stats),
        AnswerReview=Review.Merge(profile.AnswerReview),
        Accuracy = accuracy,
        VerifyFirstTryRate = verifyRate,
        AverageRetries = averageRetries,
        HintScaffold = scaffold,
        ActiveMission = profile.ActiveMission,
        Mastery = profile.Mastery,
        EventStorm = profile.EventStorm,
        CurrentDay = currentDay,
        SecondsRemaining = secondsRemaining,
        TimePlayedMinutes = math.floor((profile.Stats.TimePlayedSeconds or 0) / 60),
    }
end

return AnalyticsTracker
