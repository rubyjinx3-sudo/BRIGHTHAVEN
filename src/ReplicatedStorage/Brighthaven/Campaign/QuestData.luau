local Quests = {}

Quests.Title = "Help BrightHaven"
Quests.Chapters = {
    {Id = "captain", Title = "A Town That Needs You", Helper = "Captain Kappa", Goal = "Talk to Captain Kappa at Barangay Hall.",
        Why = "Another super typhoon is coming! Dr. Liza needs everyone's help to build the Storm Stopper. Our neighbors need fair supplies while we work."},
    {Id = "school", Title = "Food for Families", Helper = "School Helper", Goal = "Help the School Helper share food packs.",
        Why = "Feed families at the school while the Scientist builds the Storm Stopper. Every classroom needs a fair share."},
    {Id = "dumpsite", Title = "Linis Barangay", Helper = "Kuya Nestor", Mission = "yard_metal", Goal = "Talk to Kuya Nestor at the Recycling Yard.",
        Why = "The Storm Stopper's first part is hidden in recycling. Clear the yard so Kuya Nestor can find it.",
        Steps = {"Shoot 3 items into the correct sorting bins.", "Share recycling equally among the trucks.", "Check your work and collect the Ion Stabilizer."}},
    {Id = "wood", Title = "Clear the Way", Helper = "Woodworker", Mission = "wood_log", Goal = "Ask the Woodworker how to clear the path.",
        Why = "Clear fallen wood for our relief route. Families need firewood and medicine while we gather the Storm Stopper's parts.",
        Steps = {"Use the provided game axe at the marked stump.", "Count equal 4-meter pieces and check your total.", "Leave the axe here and help at the train station."}},
    {Id = "train", Title = "Medicine on the Move", Helper = "Station Helper", Mission = "train_215", Goal = "Meet the Station Helper at the Train Station.",
        Why = "The medicine train has arrived. Your careful sharing will help the clinic get its supplies.",
        Steps = {"Give each truck the same number of boxes.", "Send the extra boxes to the clinic.", "Check that every box is counted."}},
    {Id = "clinic", Title = "Care for Our Neighbors", Helper = "Dr. Maya", Mission = "clinic_960", Goal = "Talk to Dr. Maya at the Barangay Clinic.",
        Why = "The medicine is here! Dr. Maya needs to share money so each room can buy supplies.",
        Steps = {"Give every room the same number of pesos.", "Check the total.", "Ask the Shop Helper about the parts."}},
    {Id = "shop", Title = "Two More Parts", Helper = "Shop Helper", Mission = "shop_lanterns", Goal = "Meet the Shop Helper at the General Shop.",
        Why = "The shop has the two missing parts. Help count the price of one lantern for the families.",
        Steps = {"Find the price of one lantern.", "Check the total price.", "Collect the last two machine parts."}},
    {Id = "power", Title = "Light Up the Town", Helper = "Power Helper", Mission = "power_400", Goal = "Talk to the Power Helper at the Power Station.",
        Why = "The lights went out! The weather lab needs power. Use the pretend meter while the grown-ups do the repairs.",
        Steps = {"Share the power units equally.", "Check your answer to turn the lights on.", "Take all three parts to the Scientist."}},
    {Id = "lab", Title = "Bring Back the Sunshine", Helper = "Scientist", Mission = "lab_energy_450", Goal = "Bring your three parts to the Scientist.",
        Why = "The Storm Stopper can break apart the approaching super typhoon. Help Dr. Liza finish it: install its parts and complete 3 jobs to power its beam.",
        Steps = {"Put all three parts in the machine.", "Share energy for the beams.", "Share signals for the dishes.", "Share the lab money and check your work."}},
    {Id = "home", Title = "Our Town, Together", Helper = "Captain Kappa", Goal = "Return to Captain Kappa and tell him the good news.",
        Why = "The Storm Stopper stopped the super typhoon! Tell Captain Kappa how your journey saved the barangay."},
}
Quests.ById = {}
Quests.Acts = {
    {Title="Chapter 1: Helping Hands", Summary="Meet Captain Kappa and help families at the school."},
    {Title="Chapter 2: The Relief Route", Summary="Clear the way and help medicine reach the clinic."},
    {Title="Chapter 3: Stop the Super Typhoon", Summary="Help Dr. Liza build the Storm Stopper. Earn the missing parts, restore power, and break apart the storm."},
}
local acts = {1,1,2,2,2,2,3,3,3,3}
Quests.Chapters[2].Steps = {"Ride Driver Lito's shuttle to the school.", "Share food equally with each classroom.", "Check your work with the School Helper."}
for index, quest in ipairs(Quests.Chapters) do
    quest.Index = index
    quest.Act = acts[index]
    Quests.ById[quest.Id] = quest
end

function Quests.Act(state)
    return Quests.Acts[Quests.Current(state).Act]
end

function Quests.Done(state, id)
    if id == "captain" then return state.CaptainBriefed == true end
    if id == "school" then return state.SchoolComplete == true end
    if id == "home" then return state.StoryFinished == true end
    return state.Nodes and state.Nodes[id] == true
end

function Quests.Current(state)
    for _,quest in ipairs(Quests.Chapters) do
        if not Quests.Done(state, quest.Id) then return quest end
    end
    return Quests.ById.home
end

function Quests.Objective(state, campaignData)
    local quest = Quests.Current(state)
    if state.StoryFinished and not (state.Active and state.Active.Phase ~= "complete") then return "BrightHaven is safe! Explore or help with extra supplies." end
    local gate=state.GameLocks and state.GameLocks[quest.Id]
    if gate and not gate.Unlocked then return gate.Reason end
    if quest.Id == "school" and state.SchoolActive then
        local a = state.SchoolActive
        if a.Phase == "briefing" then return "Read the School Helper's plan, then start sharing." end
        if a.Phase == "chunking" then return "Share the food packs. " .. a.Remaining .. " are left." end
        if a.Phase == "verify" then return "Check that every classroom has the same number." end
    end
    local a = state.Active
    if a and a.Phase ~= "complete" and a.Node == quest.Id then
        local mission = campaignData.ById[a.Id]
        if a.Phase=="activity" then return a.Physical.Kind=="chop" and "Chop at the wood-area stump: "..a.Physical.Count.." / 3 cuts." or "Shoot items into the right bins: "..a.Physical.Count.." / 3 sorted." end
        if a.Phase == "briefing" then return "Read " .. quest.Helper .. "'s plan, then start." end
        if a.Phase == "remainder" then return "Count the extra medicine boxes. Send them to the clinic." end
        if a.Phase == "verify" then return "Check your answer with " .. quest.Helper .. "." end
        return "Keep helping " .. quest.Helper .. ". " .. a.Remaining .. " " .. mission.Resource .. " left."
    end
    if quest.Id == "lab" and state.Accepted and state.Accepted.lab then
        local installed = 0
        for _,done in pairs(state.InstalledParts or {}) do if done then installed += 1 end end
        if installed < 3 then return "Put the parts in the machine: " .. installed .. " of 3 ready." end
        return "Help the Scientist with lab job " .. (state.LabRound or 1) .. " of 3."
    end
    if state.Accepted and state.Accepted[quest.Id] then return "Start your helping job with " .. quest.Helper .. "." end
    return quest.Goal
end

local Titles=require(game.ReplicatedStorage.Brighthaven.GameTitles)
for _,q in ipairs(Quests.Chapters) do q.Title=Titles.Nodes[q.Id] or q.Title end

return Quests