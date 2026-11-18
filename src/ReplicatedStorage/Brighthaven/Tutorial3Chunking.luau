local QuickPlay=require(game.ReplicatedStorage.Brighthaven.QuickPlaySettings)
local Math = require(script.Parent.Campaign.ChunkingMath)
local Chunking = {}
function Chunking.New(rng,previousTotal)
    rng=rng or Random.new()
    local choices={}
    -- Each total needs a separate smaller round whether the first load is two or three boxes.
    for _,total in ipairs(QuickPlay.ForkliftTotals) do if total~=previousTotal then table.insert(choices,total) end end
    local total=choices[rng:NextInteger(1,#choices)]
    return {Total=total, Remaining=total, Cargo=0, Counts={0,0,0}, Chunks={{},{},{}},
        Round=1, Delivered={}, History={}, Complete=false, Travel=0, NextPlanToken=0}
end
function Chunking.Plan(s, amount)
    if s.Complete then return false, "Your crates are ready!" end
    if s.Cargo > 0 then return false, "Deliver your load first. Only one chunk fits on the forklift." end
    if s.RoundChunk then return false, "Finish this fair round. Give each crate the same load." end
    if type(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 or amount < 1 or amount > 3 then
        return false, "Choose a whole number from 1 to 3."
    end
    if not s.MainChunk and (amount ~= QuickPlay.ForkliftMainChunk or amount * 3 >= s.Total) then
        return false, "Start with 3 boxes for each crate. Finish with one smaller round."
    end
    local smaller = s.MainChunk and s.Remaining < s.MainChunk * 3
    if smaller and (amount >= s.MainChunk or amount * 3 ~= s.Remaining) then
        return false, "Count the boxes left. Choose a smaller chunk that can fill all three crates equally."
    elseif s.MainChunk and not smaller and amount ~= s.MainChunk then
        return false, "Use the same chunk for the larger rounds."
    end
    if not s.RoundMath then
        s.RoundMath = Math.New(s.Remaining)
        s.RoundMath.NextToken = s.NextPlanToken
    end
    local ok, message = Math.Choose(s.RoundMath, 3, amount)
    s.NextPlanToken = s.RoundMath.NextToken
    return ok, ok and Math.FactorHint(3, amount) or message
end
function Chunking.PlanStep(s, step, answer, token)
    if s.Complete or s.RoundChunk or not s.RoundMath then return false, "Choose an equal load at the loading bay first." end
    local pending = s.RoundMath.PendingChunk
    local ok, message, ready = Math.Step(s.RoundMath, 3, step, answer, token)
    if ready then
        -- Calculate the round here; only physical deliveries remove boxes from the bay.
        s.RoundPlan = {Before=pending.Before, Product=pending.Product, Left=s.RoundMath.Remaining}
        s.RoundChunk = pending.Quotient
        s.SmallRound = s.MainChunk ~= nil and pending.Before < s.MainChunk * 3
        s.MainChunk = s.MainChunk or s.RoundChunk
        return true, "Plan ready! Load one chunk, then drive it to a crate."
    elseif ok and step == "multiply" then
        return true, "You counted all three loads! How many will be left after this round?"
    end
    return ok, message
end
function Chunking.Load(s, amount)
    if s.Complete then return false, "Your crates are ready!" end
    if s.Cargo > 0 then return false, "Deliver your load first. Only one chunk fits on the forklift." end
    if not s.RoundPlan or not s.RoundChunk then return false, "Plan your equal loads first. Multiply, then subtract." end
    if amount ~= s.RoundChunk then return false, "Keep this round fair. Use the same chunk at all three crates." end
    if s.Remaining + (s.RoundUsed or 0) ~= s.RoundPlan.Before then return false, "Check your current delivery round." end
    s.Cargo, s.Travel = amount, 0
    return true, s.SmallRound and "The smaller chunk is on board. Drive it to a crate!" or "Chunk loaded. Drive to a crate!"
end
function Chunking.Deliver(s, id)
    if s.Complete or s.Cargo == 0 then return false, "Load a chunk at the loading bay first." end
    if id ~= 1 and id ~= 2 and id ~= 3 then return false, "Choose one of the three crates." end
    if s.Delivered[id] then return false, "This crate has its chunk for this round. Visit another crate." end
    if s.Travel < QuickPlay.ForkliftMinimumTravel then return false, "Drive your load from the loading bay to the crate." end
    local amount = s.Cargo
    s.Counts[id] += amount
    table.insert(s.Chunks[id], amount)
    s.Delivered[id] = true
    s.Remaining -= amount
    s.RoundUsed = (s.RoundUsed or 0) + amount
    s.Cargo = 0
    if s.Delivered[1] and s.Delivered[2] and s.Delivered[3] then
        table.insert(s.History, {Amount=s.RoundChunk, Used=s.RoundUsed, Remaining=s.Remaining, Smaller=s.SmallRound})
        s.Round += 1
        s.Delivered, s.RoundChunk, s.RoundUsed = {}, nil, 0
        s.RoundPlan, s.RoundMath = nil, nil
        if s.Remaining == 0 then s.Complete = true; return true, "All three crates match! Add the chunks in one crate to check your division answer." end
        if s.Remaining < s.MainChunk * 3 then
            return true, "A few boxes are left. Return to the loading bay for a separate, smaller chunk."
        end
        return true, "Fair round! Return to the loading bay for another chunk."
    end
    return true, "Chunk delivered! Go back for a load for the next crate."
end
return Chunking
