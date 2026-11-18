local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MissionData = require(ReplicatedStorage.Brighthaven.MissionData)
local Settings = require(ReplicatedStorage.Brighthaven.Settings)
local AnalyticsTracker = require(script.Parent.AnalyticsTracker)

local BoostTerminalController = {}
local Review=require(script.Parent.AnswerReview)

local function findChallenge(id)
    for _, challenge in ipairs(MissionData.BoostChallenges) do
        if challenge.Id == id then
            return challenge
        end
    end
    return nil
end

function BoostTerminalController.Start(profile, currentDay)
    if profile.Boost.UsedDay == currentDay then
        return false, {
            Message = "Boost already used today. Wait for the next in-game day.",
            Cooldown = true,
        }
    end

    local challenge = MissionData.BoostChallenges[math.random(1, #MissionData.BoostChallenges)]
    profile.Boost.ActiveChallengeId = challenge.Id
    profile.Boost.UsedDay = currentDay
    local stats=profile.Stats
    stats.BoostStarted=math.max(stats.BoostStarted or 0,stats.BoostWins+stats.BoostLosses)+1

    return true, {
        Message = "Boost challenge ready. One try only.",
        Challenge = table.clone(challenge),
        Cooldown = false,
        Reward = Settings.Rewards.BoostCorrectCoins,
    }
end

function BoostTerminalController.Submit(profile, answer, currentDay)
    local challenge = findChallenge(profile.Boost.ActiveChallengeId)
    if not challenge or profile.Boost.UsedDay ~= currentDay then
        return false, {
            Message = "No active boost challenge is ready.",
        }
    end

    local expected = math.floor(challenge.Dividend / challenge.Divisor)
    local received = tonumber(answer)
    local won = received == expected
    if not won then Review.Add(profile,"Boost","Boost Challenge",received,expected) end
    AnalyticsTracker.ApplyBoost(profile, won)

    local message
    if won then
        message = "Boost correct. The town earned " .. Settings.Rewards.BoostCorrectCoins .. " bonus coins."
    else
        message = "Boost missed. The answer was " .. expected .. ". Try again tomorrow."
    end

    profile.Boost.ActiveChallengeId = nil

    return won, {
        Message = message,
        Correct = won,
        Expected = expected,
        Reward = won and Settings.Rewards.BoostCorrectCoins or 0,
    }
end

return BoostTerminalController
