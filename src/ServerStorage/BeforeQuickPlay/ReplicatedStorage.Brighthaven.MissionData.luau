local MissionData = {}

MissionData.Scope = { Locations = {1, 2}, Sectors = {0, 1} }
MissionData.MainWorldWelcomeDialogue = {
    "Welcome to Brighthaven! I'm Captain Kappa. You are ready to help our town.",
    "A storm is coming. Families are staying safely at the school.",
    "Meet me at Barangay Hall. Then we can help the school share food.",
}
MissionData.CaptainDialogue = {
    "Hi! I'm Captain Kappa. A storm is coming. Families are safe at the school.",
    "Another super typhoon is coming. Dr. Liza, our mad scientist, has a plan: build the Storm Stopper! But she cannot build it without everyone's help.",
    "Food and clean water help families stay healthy during a typhoon. Share supplies equally, so every classroom gets its share and no one is left out.",
    "Help at each stop to earn coins and find the parts. First, share food at the school. Then find all 3 parts, power the Storm Stopper, and save our barangay!",
}
MissionData.CaptainEnding = {
    "You did it! The families have food, the clinic has supplies, and our lights are back on.",
    "You found all 3 parts and powered the Storm Stopper. Its beam broke apart the super typhoon before it could reach our homes!",
    "Thank you for being a kind helper. BrightHaven is safe! You can explore or help with extra supplies now.",
}
MissionData.VolunteerDialogue = "Welcome, helper! Another typhoon is coming. These families need food and clean water. Give each classroom the same number of food packs so no one is left out."
MissionData.SchoolPostDialogue = "Families have food while we help Dr. Liza build the Storm Stopper! Call Kuya Nestor on the walkie-talkie. He may find our first machine part at the Recycling Yard."

MissionData.TutorialSteps = {
    {
        Title = "1. Barangay Hall",
        Body = "Talk to Captain Kappa at Barangay Hall. He will tell you how to help.",
    },
    {
        Title = "2. Head to School",
        Body = "Take the shuttle to the school. The School Helper is waiting for you.",
    },
    {
        Title = "3. Food for the School",
        Body = "Count the food packs. Share them with 6 classrooms. Each classroom needs the same number.",
    },
    {
        Title = "4. Share in Easy Steps",
        Body = "Give 10 or 20 packs to each classroom first. Each classroom gets the same number.",
    },
    {
        Title = "5. Finish the Share",
        Body = "Count the packs left. Give the same number to each classroom again. Keep going until no packs are left.",
    },
    {
        Title = "6. Check It",
        Body = "Add the numbers you gave to each classroom. Multiply your answer by 6. Does it match the number of packs you started with?",
    },
    {
        Title = "7. Thank You, Helper!",
        Body = "The families have food! Call Kuya Nestor at the Recycling Yard. You can share water and care kits as extra help later.",
    },
}

MissionData.Missions = {
    {
        Id = "school_evacuation_144_6",
        Level = 1,
        Title = "Food for the School",
        District = "School Evacuation Building",
        Type = "partial_quotients",
        Dividend = 144,
        Divisor = 6,
        RandomFoodPacks = {MinPerClassroom = 12, MaxPerClassroom = 29},
        Resource = "food packs",
        ResourceSingular = "food pack",
        Recipients = "classrooms",
        Story = "Share the food packs with 6 classrooms. Each classroom needs the same number.",
        Urgency = "Emergency relief",
        PreferredDecision = "store",
        ChunkPlan = {20, 4},
        ChunkingFirst = true,
        PostDialogue = MissionData.SchoolPostDialogue,
    },
    {
        Id = "school_water_135_5", Level = 1,
        Title = "Water for the School", District = "School Evacuation Center",
        Type = "partial_quotients", Dividend = 135, Divisor = 5,
        Resource = "water bottles", Recipients = "classrooms",
        ResourceSingular = "water bottle",
        Story = "There are 135 water bottles. Share them with 5 classrooms.",
        Urgency = "School relief", PreferredDecision = "store",
        ChunkPlan = {20, 7}, ChunkingFirst = true,
        RequiresMission = "school_evacuation_144_6",
        PostDialogue = "Thank you! Each classroom has 27 water bottles. You helped the families get clean water.",
    },
    {
        Id = "school_hygiene_168_7", Level = 1,
        Title = "Care Kits for the School", District = "School Evacuation Center",
        Type = "partial_quotients", Dividend = 168, Divisor = 7,
        Resource = "care kits", Recipients = "classrooms",
        ResourceSingular = "care kit",
        Story = "There are 168 care kits. Each kit has soap and things to keep us clean. Share the kits with 7 classrooms.",
        Urgency = "School relief", PreferredDecision = "store",
        ChunkPlan = {20, 4}, ChunkingFirst = true,
        RequiresMission = "school_evacuation_144_6",
        PostDialogue = "Thank you! Each classroom has 24 care kits. You helped the families stay clean.",
    },
}

MissionData.BoostChallenges = {
    {
        Id = "boost_school_72_6",
        Dividend = 72,
        Divisor = 6,
        Resource = "blankets",
        Story = "Share 72 blankets with 6 classrooms. Give each classroom the same number.",
    },
    {
        Id = "boost_school_96_6",
        Dividend = 96,
        Divisor = 6,
        Resource = "water bottles",
        Story = "Share 96 water bottles with 6 classrooms. Give each classroom the same number.",
    },
    {
        Id = "boost_school_120_6",
        Dividend = 120,
        Divisor = 6,
        Resource = "care kits",
        Story = "Share 120 care kits with 6 classrooms. Give each classroom the same number.",
    },
}

MissionData.MasteryChecks = {}
MissionData.StormEvents = {}
MissionData.MaxLevel = 1

local missionById = {}
for _, mission in ipairs(MissionData.Missions) do
    missionById[mission.Id] = mission
end

function MissionData.GetMission(id)
    return missionById[id]
end

function MissionData.GetMissionForActive(active)
    local definition = active and MissionData.GetMission(active.Id)
    if not definition then return nil end
    local mission = table.clone(definition)
    mission.Dividend = active.Dividend or mission.Dividend
    mission.Divisor = active.Divisor or mission.Divisor
    if mission.RandomFoodPacks then
        local perClassroom = math.floor(mission.Dividend / mission.Divisor)
        local firstShare = math.floor(perClassroom / 10) * 10
        mission.ChunkPlan = {firstShare, perClassroom - firstShare}
        mission.Story = "There are " .. mission.Dividend .. " food packs. Share them equally with " .. mission.Divisor .. " classrooms so all the families have food for the coming typhoon."
        mission.PostDialogue = "Thank you! Each classroom has " .. perClassroom
            .. " food packs. The families can eat! Next, call Kuya Nestor on the walkie-talkie."
    end
    return mission
end

function MissionData.GetUnlockedMissions(level)
    local unlocked = {}
    for _, mission in ipairs(MissionData.Missions) do
        local copy = table.clone(mission)
        copy.Locked = mission.Level > level
        table.insert(unlocked, copy)
    end
    return unlocked
end

function MissionData.GetMasteryCheck(level)
    local check = MissionData.MasteryChecks[level]
    if not check then return nil end
    local copy = table.clone(check)
    copy.Problems = {}
    for _, problem in ipairs(check.Problems) do
        table.insert(copy.Problems, table.clone(problem))
    end
    return copy
end

function MissionData.GetStormEvent(day)
    if #MissionData.StormEvents == 0 then return nil end
    local index = ((day - 1) % #MissionData.StormEvents) + 1
    return table.clone(MissionData.StormEvents[index])
end

local Titles=require(game.ReplicatedStorage.Brighthaven.GameTitles)
for _,q in ipairs(MissionData.Missions) do q.Title=Titles.School[q.Id] or q.Title end

return MissionData