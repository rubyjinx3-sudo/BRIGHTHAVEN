local QuickPlay=require(game.ReplicatedStorage.Brighthaven.QuickPlaySettings)
local Rules = {}
Rules.SharingTotals = QuickPlay.SharingTotals

function Rules.ChooseTotal(previous, randomInteger)
    randomInteger = randomInteger or math.random
    local choices = {}
    for _, total in ipairs(Rules.SharingTotals) do
        if total ~= previous then table.insert(choices, total) end
    end
    return choices[randomInteger(1, #choices)]
end

function Rules.LogChoices(correct, previousSlot, randomInteger)
    randomInteger = randomInteger or math.random
    local below = correct - randomInteger(1, 3)
    local above = correct + randomInteger(1, 3)
    -- Shuffle the values between physical slots, not the order of log instances.
    local permutations = {
        {below, above, correct}, {correct, below, above},
        {correct, above, below}, {above, below, correct}, {above, correct, below},
    }
    local choices = {}
    for _, values in ipairs(permutations) do
        local slot = table.find(values, correct)
        if slot ~= previousSlot then table.insert(choices, values) end
    end
    return choices[randomInteger(1, #choices)]
end

function Rules.CountedSteps(startingNumber, row)
    local steps = {}
    if startingNumber < 4 or startingNumber > 9 then return steps end
    local jumps = math.clamp(math.floor((tonumber(row) or 1) - 1), 0, 3)
    for i = 1, jumps + 1 do table.insert(steps, tostring(startingNumber * i)) end
    return steps
end

return Rules
