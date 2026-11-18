local Settings = {}

Settings.Version = "Prototype 0.4 - Cozy Division Town"
Settings.DayDurationSeconds = 360
Settings.ProfileStoreName = "BrighthavenPrototypeProfiles_v1"

Settings.Progression = {
    TutorialGatePercent = 80,
    MissionGatePercent = 75,
    MaxHintsPerMission = 3,
    BaseCommunityMeter = 55,
    BaseStormRisk = 40,
    MasteryProblemsPerGate = 3,
    RemedialMissionsRequired = 1,
}

Settings.Persistence = {
    AutosaveSeconds = 60,
    SaveRetries = 3,
}

Settings.Rewards = {
    BaseMissionCoins = 45,
    PerfectMissionBonus = 25,
    BaseMissionXP = 35,
    VerificationFirstTryBonus = 10,
    BoostCorrectCoins = 80,
    BoostCorrectXP = 30,
}

Settings.Ranks = {
    { Name = "Rescue Helper", XP = 0 },
    { Name = "Fair Share Star", XP = 90 },
    { Name = "Chunking Hero", XP = 190 },
    { Name = "Storm Solver", XP = 340 },
    { Name = "Brighthaven Champion", XP = 520 },
}

Settings.Upgrades = {
    storage = {
        Name = "Dry Storage Box",
        Description = "Keeps leftover supplies safe and dry.",
        Cost = 60,
        CommunityDelta = 8,
        StormRiskDelta = -4,
    },
    transport = {
        Name = "Helper Bus",
        Description = "Carries fair shares to homes faster.",
        Cost = 75,
        CommunityDelta = 10,
        StormRiskDelta = -5,
    },
    reserve = {
        Name = "Emergency Kit",
        Description = "Helps the town during rainy day rescues.",
        Cost = 90,
        CommunityDelta = 12,
        StormRiskDelta = -7,
    },
}

Settings.ValidRemainderDecisions = {
    store = true,
    carryover = true,
    emergency = true,
    redistribute = true,
}

return Settings

