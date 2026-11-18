local Data = require(game.ReplicatedStorage.Brighthaven.Campaign.CampaignData)
local Quests = require(game.ReplicatedStorage.Brighthaven.Campaign.QuestData)
local Feedback = require(game.ServerScriptService.Brighthaven.FeedbackEngine)
local Engine = {}
local Progress = require(script.Parent.QuestProgress)
local ActivityRules=require(game.ReplicatedStorage.Brighthaven.Campaign.ActivityRules)
local ChunkingMath=require(game.ReplicatedStorage.Brighthaven.Campaign.ChunkingMath)
local Mastery=require(game.ReplicatedStorage.Brighthaven.Campaign.MasteryProgression)

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy(item) end
    return result
end

function Engine.Integer(value, minimum, maximum)
    local number = tonumber(value)
    if not number or number ~= number or number % 1 ~= 0 or number < minimum or number > maximum then return nil end
    return number
end

function Engine.NewProfile()
    return {Version = 1, SchoolComplete = false, Completed = {}, Nodes = {}, Parts = {}, InstalledParts = {},
        LabRounds = {}, Stars = 0, Victory = false, Active = nil,
        CaptainBriefed = false, Accepted = {}, StoryFinished = false, BaseXP = 0, SideQuests = {}, SideDiscovered = {}}
end

function Engine.Rebuild(profile)
    profile.Nodes, profile.Parts, profile.LabRounds = {}, {}, {}
    for id, done in pairs(profile.Completed) do
        local m = Data.ById[id]
        if done == true and m then
            profile.Nodes[m.Node] = true
            if m.Node == "dumpsite" then profile.Parts["1"] = true end
            if m.Node == "shop" then profile.Parts["2"], profile.Parts["3"] = true, true end
            if m.Round then profile.LabRounds[tostring(m.Round)] = true end
        end
    end
    profile.Nodes.lab = profile.LabRounds["1"] and profile.LabRounds["2"] and profile.LabRounds["3"] or false
    profile.Victory = profile.Nodes.lab == true
    profile.Stars = 0
    for _,done in pairs(profile.Completed) do if done == true then profile.Stars += 1 end end
end

function Engine.Normalize(saved)
    local profile = Engine.NewProfile()
    if type(saved) ~= "table" then return profile end
    Progress.Normalize(profile, saved)
    profile.SchoolComplete = saved.SchoolComplete == true
    profile.CaptainBriefed = saved.CaptainBriefed == true or profile.SchoolComplete
    for id, accepted in pairs(type(saved.Accepted) == "table" and saved.Accepted or {}) do
        if Quests.ById[id] and accepted == true then profile.Accepted[id] = true end
    end
    for id, done in pairs(type(saved.Completed) == "table" and saved.Completed or {}) do
        if Data.ById[id] and done == true then profile.Completed[id] = true end
    end
    for key, done in pairs(type(saved.InstalledParts) == "table" and saved.InstalledParts or {}) do
        if Engine.Integer(key, 1, 3) and done == true then profile.InstalledParts[tostring(key)] = true end
    end
    Engine.Rebuild(profile)
    profile.StoryFinished = saved.StoryFinished == true and profile.Victory
    -- Rebuild saved arithmetic from valid chunks rather than trusting cached totals.
    local old = saved.Active
    local m = type(old) == "table" and Data.ById[old.Id]
    if m and type(old.Steps) == "table" then
        -- Keep an already-started legacy lesson playable when adding new gates.
        profile.MasteryResumeNode=(old.MinimumChunks==nil or saved.MasteryResumeNode==m.Node and old.MinimumChunks==1) and m.Node or nil
        local active = {Id = m.Id, Node = m.Node, Phase = "briefing", Remaining = m.Dividend,
            Quotient = 0, Steps = {}, Remainder = m.Dividend % m.Divisor, Hints = 0}
        active.MinimumChunks=old.MinimumChunks==2 and 2 or 1
        for _,step in ipairs(old.Steps) do
            local q = type(step) == "table" and Engine.Integer(step.Quotient, 1, 1000)
            if not q or q * m.Divisor > active.Remaining then break end
            active.Quotient += q
            active.Remaining -= q * m.Divisor
            table.insert(active.Steps, {Quotient = q, Amount = q * m.Divisor, Remaining = active.Remaining})
        end
        active.Hints = Engine.Integer(old.Hints, 0, 100) or 0
        active.NextToken=Engine.Integer(old.NextToken,0,1000000) or #active.Steps
        if #active.Steps > 0 or old.Phase ~= "briefing" then active.Phase = "chunking" end
        if m.Activity and old.Physical then active.Physical=ActivityRules.Normalize(old.Physical,m.Activity) end
        if m.Activity and old.Phase=="activity" then
            active.Physical=active.Physical or ActivityRules.New(m.Activity)
            active.Phase=active.Physical.Count>=ActivityRules.Required and "chunking" or "activity"
        end
        if active.Remaining < m.Divisor then
            active.Phase = active.Remaining == 0 and "verify" or "remainder"
            if old.Phase == "verify" and old.Routed == active.Remaining then active.Phase = "verify"; active.Routed = active.Remaining end
        end
        if active.Phase=="chunking" and type(old.PendingChunk)=="table" then
            local normalized=ChunkingMath.Normalize(old,m.Dividend,m.Divisor)
            active.PendingChunk=normalized.PendingChunk;active.NextToken=normalized.NextToken
        end
        if profile.Completed[m.Id] and old.Phase == "complete" then
            active.Phase = "complete"
            active.Routed = active.Remainder > 0 and active.Remainder or nil
        end
        if Engine.Unlocked(profile, m.Node) and (Quests.Current(profile).Id == m.Node or profile.Nodes[m.Node]) then
            profile.Active = active
            profile.Accepted[m.Node] = true
        else profile.MasteryResumeNode=nil end
    end
    return profile
end

function Engine.Unlocked(profile, node)
    local quest = Quests.ById[node]
    if not quest then return false end
    for index = 1, quest.Index - 1 do
        if not Quests.Done(profile, Quests.Chapters[index].Id) then return false end
    end
    if node=="lab" and not (profile.Parts["1"] and profile.Parts["2"] and profile.Parts["3"]) then return false end
    return Mastery.Gate(profile,node,Progress.Summary(profile)).Ready
end

function Engine.LockMessage(profile,node)
    local quest=Quests.ById[node]
    if quest then
        for index=1,quest.Index-1 do
            if not Quests.Done(profile,Quests.Chapters[index].Id) then return "Finish your current story job first. Your guidebook shows the next helper." end
        end
    end
    local gate=Mastery.Gate(profile,node,Progress.Summary(profile))
    if not gate.Ready then return gate.Reason end
    return "Find all three machine parts and restore power first."
end

function Engine.LabRound(profile)
    for index = 1, 3 do if not profile.LabRounds[tostring(index)] then return index end end
    return 3
end

function Engine.Snapshot(profile)
    local result = copy(profile)
    result.Unlocked = {}
    for _,node in ipairs(Data.Order) do result.Unlocked[node] = Engine.Unlocked(profile, node) end
    result.LabRound = Engine.LabRound(profile)
    result.Blackout = profile.Nodes.shop == true and profile.Nodes.power ~= true
    result.QuestId = Quests.Current(profile).Id
    result.Progress = Progress.Summary(profile)
    result.Progress.DivisionTasks=Mastery.Tasks(profile)
    result.GameLocks={}
    for node in pairs(Mastery.Games) do
        local gate=Mastery.Gate(profile,node,result.Progress)
        gate.Unlocked=Engine.Unlocked(profile,node)
        result.Unlocked[node]=gate.Unlocked
        if not gate.Unlocked then gate.Reason=Engine.LockMessage(profile,node) end
        result.GameLocks[node]=gate
    end
    return result
end

function Engine.InstallPart(profile, index)
    local key = tostring(Engine.Integer(index, 1, 3) or "")
    if not Engine.Unlocked(profile, "lab") or not profile.Parts[key] then return false, "Find all three parts and turn the power back on first." end
    profile.InstalledParts[key] = true
    return true, "Part " .. key .. " is in the machine!"
end

function Engine.AcceptQuest(profile, node)
    local quest = Quests.ById[node]
    if not quest or not Engine.Unlocked(profile, node) then return false, Engine.LockMessage(profile,node) end
    if Quests.Current(profile).Id ~= node and not profile.Nodes[node] then return false, "Let's finish the job in your quest book first." end
    profile.Accepted[node] = true
    return true, "New quest: " .. quest.Title .. ". Let's help together!"
end

function Engine.Start(profile, id)
    local m = Data.ById[id]
    if not m then return false, "Choose an activity from the helper." end
    if not Engine.Unlocked(profile, m.Node) then return false, Engine.LockMessage(profile,m.Node) end
    if Quests.Current(profile).Id ~= m.Node and not profile.Nodes[m.Node] then return false, "Finish your current story job first." end
    if not profile.Nodes[m.Node] then
        if not profile.Accepted[m.Node] then return false, "Talk to the helper and choose I'll Help first." end
        local quest = Quests.ById[m.Node]
        local required = m.Node == "lab" and ({"lab_energy_450", "lab_pulses", "lab_reserve"})[Engine.LabRound(profile)] or quest.Mission
        if m.Id ~= required then return false, "Finish the story job first. More helping jobs will be ready after that." end
    end
    if profile.Active and profile.Active.Phase ~= "complete" then return false, "Finish your current activity first. Choose Keep Helping to continue." end
    if m.Node == "lab" then
        if not (profile.InstalledParts["1"] and profile.InstalledParts["2"] and profile.InstalledParts["3"]) then return false, "Put all three parts into the machine first." end
        if not profile.Victory and m.Round ~= Engine.LabRound(profile) then return false, "Let's finish the current lab activity first." end
    end
    profile.Active = {Id = id, Node = m.Node, Phase = "briefing", Remaining = m.Dividend,
        Quotient = 0, Steps = {}, Remainder = m.Dividend % m.Divisor, Hints = 0, MinimumChunks=2}
    return true, "Let's help!"
end

function Engine.Begin(profile)
    local a = profile.Active
    if not a then return false, "Choose an activity first." end
    if a.Phase == "briefing" then
        local m=Data.ById[a.Id]
        a.Phase=m.Activity and "activity" or "chunking"
        if m.Activity then a.Physical=ActivityRules.New(m.Activity) end
    end
    return true, "Take one step at a time. You can do it!"
end

function Engine.ActivityStep(profile,kind,category,inHoop)
    local a=profile.Active
    if not a or a.Phase~="activity" or not a.Physical or a.Physical.Kind~=kind then return false,"Start the helping job with this area's helper first." end
    local physical=a.Physical
    if kind=="sort" then
        if category~=physical.Sequence[physical.Count+1] then return false,"That bin holds a different material. Look at the item and try again." end
        if not inHoop then return false,"Almost! Release closer to the star on the power meter." end
    end
    physical.Count+=1
    if physical.Count>=ActivityRules.Required then a.Phase="chunking" end
    return true,a.Phase=="chunking" and "The hands-on job is done! Now count and share in equal chunks." or kind=="chop" and "Good cut! Keep going at the stump." or "Nice shot! That belongs in this bin."
end

function Engine.Chunk(profile, number)
    local a = profile.Active
    if not a or a.Phase ~= "chunking" then return false, "Finish the step on your screen first." end
    local m = Data.ById[a.Id]
    return ChunkingMath.Choose(a,m.Divisor,number)
end

function Engine.ChunkStep(profile, action, number, token)
    local a=profile.Active
    if not a or a.Phase~="chunking" then return false,"Finish the step on your screen first." end
    local ok,message,committed=ChunkingMath.Step(a,Data.ById[a.Id].Divisor,action,number,token)
    if committed and a.Remaining<Data.ById[a.Id].Divisor then a.Phase=a.Remaining==0 and "verify" or "remainder" end
    return ok,message
end

function Engine.Hint(profile)
    local a = profile.Active
    if not a then return false, "Choose an activity first." end
    local m = Data.ById[a.Id]
    a.Hints += 1
    if a.Phase == "chunking" then
        if a.PendingChunk then
            if a.PendingChunk.Step=="multiply" then return true,ChunkingMath.FactorHint(m.Divisor,a.PendingChunk.Quotient) end
            return true,"Subtract the whole chunk from the amount left. Count back or use a number line."
        end
        return true,"Choose an easy amount for each group. Multiply by all the groups, subtract the chunk, and repeat. Keep every share equal."
    end
    return true, "Multiply " .. a.Quotient .. " by " .. m.Divisor .. ". Then add anything left over."
end

function Engine.Remainder(profile, number, plan)
    local a = profile.Active
    if not a or a.Phase ~= "remainder" then return false, "Finish sharing first." end
    local m = Data.ById[a.Id]
    local r = Engine.Integer(number, 0, m.Divisor - 1)
    if not r then return false, "Count the extra boxes. Write a whole number smaller than " .. m.Divisor .. "." end
    local ok, message = Feedback.CheckQRR(m.Dividend, m.Divisor, a.Quotient, r)
    if not ok then return false, "Count the boxes that are left. Use + or - to change your answer, then try again." end
    if plan ~= "clinic" or m.RemainderPlan ~= "clinic" then return false, "Send the extra medicine boxes to the clinic." end
    a.Routed = r
    a.Phase = "verify"
    return true, r .. " extra boxes are going straight to the clinic!"
end

function Engine.Verify(profile, quotient, remainder)
    local a = profile.Active
    if not a then return false, "Choose an activity first." end
    if a.Phase == "complete" then return true, "You already finished this activity!" end
    if a.Phase ~= "verify" then return false, "Finish all the sharing steps first." end
    if #a.Steps<(a.MinimumChunks or 1) then return false,"Use two or more equal chunks, then check your division." end
    local m = Data.ById[a.Id]
    local q, r = Engine.Integer(quotient, 0, 1000), Engine.Integer(remainder, 0, 1000)
    if not q or not r then return false, "Use whole numbers to check your answer." end
    local ok, message = Feedback.CheckQRR(m.Dividend, m.Divisor, q, r)
    if not ok then return false, message end
    ok, message = Feedback.VerifyEquation(q, m.Divisor, r, m.Dividend)
    if not ok then return false, message end
    if r > 0 and a.Routed ~= r then return false, "Send the extra boxes to the clinic first." end
    local first = profile.Completed[m.Id] ~= true
    profile.Completed[m.Id] = true
    a.Phase = "complete"
    a.NewStar = first
    Engine.Rebuild(profile)
    profile.MasteryResumeNode=nil
    return true, "Great job! Your answer matches the number we started with."
end

return Engine
