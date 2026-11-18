local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage.Brighthaven.Settings)

local FeedbackEngine = {}

function FeedbackEngine.Expected(dividend, divisor)
    return math.floor(dividend / divisor), dividend % divisor
end

function FeedbackEngine.CheckQRR(dividend, divisor, quotient, remainder)
    quotient = tonumber(quotient)
    remainder = tonumber(remainder)
    if not quotient or not remainder then
        return false, "Write how many each group gets and how many are left over."
    end

    quotient = math.floor(quotient)
    remainder = math.floor(remainder)

    if quotient < 0 or remainder < 0 then
        return false, "Use 0 or a bigger number. We cannot share less than 0."
    end

    if remainder >= divisor then
        return false, "There is enough left to give one more to each group. Keep sharing!"
    end

    local expectedQ, expectedR = FeedbackEngine.Expected(dividend, divisor)
    if quotient ~= expectedQ then
        return false, "Let's count again. How many does each group get?"
    end

    if remainder ~= expectedR then
        return false, "Give each group the same number. Then count what is left."
    end

    return true, "Each group gets " .. quotient .. ". There are " .. remainder .. " left over.", quotient, remainder
end

function FeedbackEngine.CheckEqualShare(dividend, divisor, quotient, remainder)
    local ok, message, q, r = FeedbackEngine.CheckQRR(dividend, divisor, quotient, remainder)
    if ok then
        return true, "Great sharing! Each group gets " .. q .. ", with " .. r .. " left over.", q, r
    end
    return false, message
end

function FeedbackEngine.ValidateChunk(divisor, remaining, chunkQuotient)
    chunkQuotient = tonumber(chunkQuotient)
    if not chunkQuotient then
        return false, "Choose how many to give to each classroom."
    end

    chunkQuotient = math.floor(chunkQuotient)
    if chunkQuotient <= 0 then
        return false, "Give at least 1 to each classroom."
    end

    local subtractAmount = chunkQuotient * divisor
    if subtractAmount > remaining then
        return false, "We need " .. subtractAmount .. ", but only " .. remaining .. " are left. Try a smaller number."
    end

    return true, "You shared " .. subtractAmount .. "! " .. divisor .. " x " .. chunkQuotient .. " = " .. subtractAmount .. ".", chunkQuotient, subtractAmount
end

function FeedbackEngine.FriendlyMultiples(divisor, remaining)
    local suggestions = {}
    for _, q in ipairs({20, 10, 5, 4, 2, 1}) do
        local amount = q * divisor
        if amount <= remaining then
            table.insert(suggestions, {
                Quotient = q,
                Amount = amount,
                Label = "Give " .. q .. " to each classroom: " .. amount .. " shared",
            })
        end
    end
    return suggestions
end

function FeedbackEngine.CheckRemainderDecision(mission, decision)
    if not decision or not Settings.ValidRemainderDecisions[decision] then
        return false, "Pick a safe plan for the leftover supplies."
    end

    if mission.PreferredDecision and decision == mission.PreferredDecision then
        return true, "Great choice. That leftover plan fits this storm mission."
    end

    return true, "That is a valid leftover plan. Captain Kapa marked it for review."
end

function FeedbackEngine.VerifyEquation(quotient, divisor, remainder, dividend)
    quotient = tonumber(quotient)
    divisor = tonumber(divisor)
    remainder = tonumber(remainder)
    dividend = tonumber(dividend)

    if not quotient or not divisor or not remainder or not dividend then
        return false, "Fill in all the numbers so we can check your sharing."
    end

    local computed = math.floor(quotient) * math.floor(divisor) + math.floor(remainder)
    if computed ~= math.floor(dividend) then
        return false, "Let's try again. We counted " .. computed .. ", but started with " .. math.floor(dividend) .. "."
    end

    return true, "It matches! " .. math.floor(quotient) .. " x " .. math.floor(divisor) .. " + " .. math.floor(remainder) .. " = " .. math.floor(dividend) .. "."
end

function FeedbackEngine.HintFor(activeMission)
    if not activeMission then
        return "Talk to the School Helper and choose some supplies to share."
    end

    local divisor = activeMission.Divisor
    local remaining = activeMission.Remaining or activeMission.Dividend
    local hintsUsed = activeMission.HintsUsed or 0

    if activeMission.Phase == "equalShare" then
        return "Share " .. activeMission.Dividend .. " among " .. divisor .. " groups. How many can each group get?"
    end

    if activeMission.Phase == "chunking" then
        if hintsUsed <= 1 then
            for _, jump in ipairs({20, 10, 5, 4, 2, 1}) do
                local amount = divisor * jump
                if amount <= remaining then
                    return "Try " .. jump .. " in each classroom.\n" .. divisor .. " x " .. jump .. " = " .. amount .. " shared."
                end
            end
        elseif hintsUsed == 2 then
            return "Count what is left. Give each classroom the same number again."
        end
        return "Keep sharing until there is not enough to give 1 more to all " .. divisor .. " classrooms."
    end

    if activeMission.Phase == "remainder" then
        return "Count the supplies left over. Choose how to save them or use them."
    end

    if activeMission.Phase == "verify" then
        return "Multiply the number in each classroom by " .. divisor .. ". Does your answer match " .. activeMission.Dividend .. "?"
    end

    return "Finish the step on your screen. You can do it!"
end

return FeedbackEngine
