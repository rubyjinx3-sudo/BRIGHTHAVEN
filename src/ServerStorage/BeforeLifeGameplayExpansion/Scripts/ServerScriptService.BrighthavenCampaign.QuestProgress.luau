local QuickPlay=require(game.ReplicatedStorage.Brighthaven.QuickPlaySettings)
local Side = require(game.ReplicatedStorage.Brighthaven.Campaign.SideQuestData)
local Settings = require(game.ReplicatedStorage.Brighthaven.Settings)
local ChunkingMath=require(game.ReplicatedStorage.Brighthaven.Campaign.ChunkingMath)
local Progress = {}
local rewards = {dumpsite = 40, wood = 40, train = 50, clinic = 40, shop = 40, power = 50}

local function integer(value, maximum)
    return type(value) == "number" and value == value and value % 1 == 0 and value >= 0 and value <= maximum
end

function Progress.Normalize(profile, saved)
    saved = type(saved) == "table" and saved or {}
    profile.BaseXP = integer(saved.BaseXP, 100000000) and saved.BaseXP or 0
    profile.SideQuests = {}
    profile.SideDiscovered = {}
    for _, quest in ipairs(Side.Quests) do
        if type(saved.SideDiscovered) == "table" and saved.SideDiscovered[quest.Id] == true then profile.SideDiscovered[quest.Id] = true end
        local old = type(saved.SideQuests) == "table" and saved.SideQuests[quest.Id]
        if type(old) == "table" then
            local p = {Items = {}, Step = integer(old.Step, 3) and old.Step or 0, Complete = old.Complete == true}
            for _, item in ipairs(quest.Items or {}) do
                if type(old.Items) == "table" and old.Items[item.Id] == true then p.Items[item.Id] = true end
            end
            if quest.Sharing and type(old.Sharing)=="table" then
                p.Sharing=ChunkingMath.Normalize(old.Sharing,quest.Sharing.Total,quest.Sharing.Groups)
            end
            profile.SideQuests[quest.Id] = p
            profile.SideDiscovered[quest.Id] = true
        end
    end
    local active = Side.ById[saved.SideActiveId]
    if active and profile.SideQuests[active.Id] and not profile.SideQuests[active.Id].Complete then profile.SideActiveId = active.Id end
end

function Progress.Merge(profile, snapshot)
    profile.BaseXP = math.max(profile.BaseXP, snapshot.BaseXP or 0)
    profile.SideDiscovered = profile.SideDiscovered or {}
    for id, met in pairs(snapshot.SideDiscovered or {}) do
        if met == true and Side.ById[id] then profile.SideDiscovered[id] = true end
    end
    for id, p in pairs(snapshot.SideQuests or {}) do
        local own = profile.SideQuests[id] or {Items = {}, Step = 0, Complete = false}
        for key, done in pairs(p.Items) do if done then own.Items[key] = true end end
        own.Step = math.max(own.Step, p.Step)
        own.Complete = own.Complete or p.Complete
        local problem=Side.ById[id] and Side.ById[id].Sharing
        if problem and type(p.Sharing)=="table" then
            local shared=ChunkingMath.Normalize(p.Sharing,problem.Total,problem.Groups)
            if not own.Sharing or shared.Quotient>own.Sharing.Quotient or shared.Checked then own.Sharing=shared end
        end
        profile.SideQuests[id] = own
    end
    local active=snapshot.SideActiveId and profile.SideQuests[snapshot.SideActiveId]
    profile.SideActiveId=active and not active.Complete and snapshot.SideActiveId or nil
end

function Progress.Meet(profile, id)
    local quest = Side.ById[id]
    if not quest then return false, "Talk to a nearby neighbor." end
    profile.SideDiscovered = profile.SideDiscovered or {}
    profile.SideDiscovered[id] = true
    return true, "You met " .. quest.Speaker .. "!"
end

function Progress.Summary(profile)
    local xp = profile.BaseXP or 0
    for node, reward in pairs(rewards) do if profile.Nodes[node] then xp += reward end end
    for _, done in pairs(profile.LabRounds) do if done then xp += 50 end end
    if profile.StoryFinished then xp += 75 end
    for _, quest in ipairs(Side.Quests) do
        if profile.SideQuests[quest.Id] and profile.SideQuests[quest.Id].Complete then xp += quest.XP end
    end
    local rank = Settings.Ranks[1].Name
    for _, item in ipairs(Settings.Ranks) do if xp >= item.XP then rank = item.Name end end
    return {XP = xp, Level = math.floor(xp / 100) + 1, LevelXP = xp % 100, NextLevelXP = 100, Rank = rank}
end

function Progress.Accept(profile, id)
    local quest = Side.ById[id]
    if not quest then return false, "Choose a quest from a neighbor." end
    if not (profile.SideDiscovered and profile.SideDiscovered[id]) then return false, "Meet this neighbor first to unlock their helping job." end
    local p = profile.SideQuests[id]
    if p and p.Complete then return false, "You already helped here. Great work!" end
    if profile.SideActiveId and profile.SideActiveId ~= id then
        return false, "Finish helping " .. Side.ById[profile.SideActiveId].Speaker .. " first."
    end
    profile.SideQuests[id] = p or {Items = {}, Step = 0, Complete = false}
    profile.SideActiveId = id
    return true, "Let's help " .. quest.Speaker .. "!"
end

function Progress.Collect(profile, id, itemId)
    local quest, p = Side.ById[id], profile.SideQuests[id]
    if not quest or quest.Kind ~= "collect" or profile.SideActiveId ~= id or not p or p.Complete then return false, "Talk to the neighbor and choose I'll Help first." end
    for _, item in ipairs(quest.Items) do
        if item.Id == itemId then
            if p.Items[itemId] then return false, "You already have this one!" end
            p.Items[itemId] = true
            return true, "Found: " .. item.Name .. "!"
        end
    end
    return false, "Choose an item from your quest."
end

function Progress.Answer(profile, id, choice, step)
    local quest, p = Side.ById[id], profile.SideQuests[id]
    if not quest or quest.Kind ~= "quiz" or profile.SideActiveId ~= id or not p or p.Complete then return false, "Start this quest with the neighbor first." end
    local question = quest.Questions[p.Step + 1]
    if not question or step ~= p.Step + 1 then return false, "Read the question on your screen first." end
    if not integer(choice, #question.Choices) or choice < 1 then return false, "Choose one of the answers." end
    if choice ~= question.Answer then return false, "Let's try again. " .. question.Tip end
    p.Step += 1
    return true, "Good choice! " .. question.Tip
end

function Progress.Finish(profile, id)
    local quest, p = Side.ById[id], profile.SideQuests[id]
    if not quest or not p then return false, "Start this quest first." end
    if p.Complete then return false, "Already finished! Your XP is safe in your progress bar." end
    if profile.SideActiveId ~= id or not Side.Ready(quest, p) then return false, "Finish your helping steps, then check your equal shares." end
    p.Complete = true
    profile.SideActiveId = nil
    return true, "Quest complete! You earned " .. quest.XP .. " XP."
end

function Progress.Share(profile,id,action,number,token)
    local quest,p=Side.ById[id],profile.SideQuests[id]
    if not quest or not quest.Sharing or not p or p.Complete or profile.SideActiveId~=id or not Side.TaskReady(quest,p) then
        return false,"Finish the neighbor's helping steps first."
    end
    local problem=quest.Sharing
    p.Sharing=p.Sharing or ChunkingMath.New(problem.Total,QuickPlay.MinimumChunks)
    if action=="choose" then return ChunkingMath.Choose(p.Sharing,problem.Groups,number)
    elseif action=="check" then return ChunkingMath.Check(p.Sharing,problem.Total,problem.Groups,number) end
    return ChunkingMath.Step(p.Sharing,problem.Groups,action,number,token)
end
return Progress
