local Data = {}
Data.Quests = {
    {Id = "go_bag", Title = "A Bag for Ready Days", Speaker = "Aling Rosa", Badge = "AR", Kind = "collect", XP = 100,
        Intro = "Let's practice packing a go-bag! Find the water, flashlight, and whistle on my blue table.",
        Safety = "At home, pack your real go-bag with a grown-up. These are just three practice items.",
        Thanks = "Water helps us stay well. A flashlight gives light. A whistle helps us call for help. Great packing!",
        Items = {{Id = "water", Name = "Water bottle"}, {Id = "flashlight", Name = "Flashlight"}, {Id = "whistle", Name = "Whistle"}},
        AnchorPath = "BrighthavenFilipinoNeighborhood.SariSariStore_1.AlingRosa.Torso", TableOffset = Vector3.new(9, 0, 0)},
    {Id = "weather", Title = "Weather Watch Buddies", Speaker = "Mang Ben", Badge = "MB", Kind = "quiz", XP = 100,
        Intro = "A storm may be coming. Let's choose three ways to stay safe together!",
        Safety = "Listen to official weather updates with a grown-up. Follow your family's safety plan.",
        Thanks = "You know who to listen to! A grown-up and official warnings can help your family get ready.",
        AnchorPath = "BrighthavenFilipinoNeighborhood.SariSariStore_2.MangBen.Torso",
        Questions = {
            {Ask = "Who can help you check a storm warning?", Choices = {"A grown-up checking PAGASA", "A stranger's rumor", "An old video"}, Answer = 1, Tip = "Check new PAGASA warnings with a grown-up."},
            {Ask = "A grown-up says to move to a safe shelter. What do you do?", Choices = {"Hide by myself", "Go with my grown-up", "Keep playing outside"}, Answer = 2, Tip = "Stay with your grown-up and follow the safety plan."},
            {Ask = "The rain has stopped. Is it time to play outside?", Choices = {"Yes, right away!", "I will check alone", "Wait until a grown-up says it is safe"}, Answer = 3, Tip = "There may still be danger. Wait for a grown-up to check."},
        }},
    {Id = "family", Title = "Our Family Plan", Speaker = "Lola Nena", Badge = "LN", Kind = "quiz", XP = 100,
        Intro = "A family plan helps us stay together. Will you practice three good choices with me?",
        Safety = "Make a meeting plan with your family. Keep phone numbers private; do not type them into the game.",
        Thanks = "A family plan is a team plan! Ask your grown-up about a safe meeting place and who can help.",
        AnchorPath = "BrighthavenFilipinoNeighborhood.SariSariStore_3.LolaNena.Torso",
        Questions = {
            {Ask = "Who should choose your family's safe meeting place?", Choices = {"A stranger online", "My family and a trusted grown-up", "Only me"}, Answer = 2, Tip = "Choose a safe meeting place together with your family."},
            {Ask = "You cannot find your family at a shelter. Who can help?", Choices = {"A shelter worker or trusted grown-up", "Any stranger online", "No one; I should leave alone"}, Answer = 1, Tip = "Stay at the shelter and ask a worker or trusted grown-up for help."},
            {Ask = "Where should you share your family's phone number?", Choices = {"In public game chat", "On a public sign", "Only with trusted helpers when needed"}, Answer = 3, Tip = "Keep family details private. A trusted grown-up can help you."},
        }},
    {Id = "flood", Title = "Safe Steps After Rain", Speaker = "Aling Lina", Badge = "AL", Kind = "quiz", XP = 100,
        Intro = "Let's practice safe choices after heavy rain. You can help by knowing when to ask a grown-up!",
        Safety = "Stay out of floodwater. Never touch fallen wires. Tell a trusted grown-up.",
        Thanks = "Great safe choices! Stay away from floodwater and fallen wires, and ask a grown-up for help.",
        AnchorPath = "BrighthavenFilipinoNeighborhood.SariSariStore_4.AlingLina.Torso",
        Questions = {
            {Ask = "There is floodwater across the path. What do you do?", Choices = {"Splash through it", "Stay back and tell a grown-up", "Try to swim"}, Answer = 2, Tip = "Stay out of floodwater. It can be deep, dirty, or moving fast."},
            {Ask = "You see a fallen wire. What is the safe choice?", Choices = {"Pick it up", "Poke it with a stick", "Stay far away and tell a grown-up"}, Answer = 3, Tip = "Never touch a fallen wire or anything touching it."},
            {Ask = "Who checks if it is safe to go home after a flood?", Choices = {"Grown-ups following official advice", "Me, on my own", "Anyone guessing"}, Answer = 1, Tip = "Stay with your grown-up and follow official safety advice."},
        }},
    {Id = "comfort", Title = "A Little Comfort", Speaker = "Nurse Ana", Badge = "NA", Kind = "collect", XP = 100,
        Intro = "Let's make a pretend comfort kit. Pick up water, soap, and a blanket from the clinic's blue table.",
        Safety = "Ask a grown-up before giving someone supplies. Nurses and grown-ups handle all medicines.",
        Thanks = "This kit can help a family feel cared for. Thank you for being a thoughtful neighbor!",
        AnchorPath = "BrighthavenStoryExtension.clinic.NurseAna.HumanoidRootPart", TableOffset = Vector3.new(0, 0, 5),
        Items = {{Id = "water", Name = "Water bottle"}, {Id = "soap", Name = "Soap"}, {Id = "blanket", Name = "Blanket"}}},
    {Id = "clean", Title = "A Ready Little Park", Speaker = "Kuya Lito", Badge = "KL", Kind = "collect", XP = 100,
        Intro = "Our practice path is safe and dry. Pick up the three clean paper wrappers on the blue table, then bring them to me.",
        Safety = "This is pretend practice. In real life, ask a grown-up before cleaning. Leave sharp things and floodwater alone.",
        Thanks = "A clear path helps our neighbors move safely. Small acts of care make our town stronger!",
        AnchorPath = "BrighthavenTownLife.Resident_1.HumanoidRootPart", TableOffset = Vector3.new(-8, 0, 4),
        Items = {{Id = "paper1", Name = "Blue paper wrapper"}, {Id = "paper2", Name = "Pink paper wrapper"}, {Id = "paper3", Name = "Yellow paper wrapper"}}},
}
Data.ById = {}
for _, quest in ipairs(Data.Quests) do Data.ById[quest.Id] = quest end
local sharing={
    go_bag={Total=24,Groups=4,Resource="water bottles",Group="go-bag"},
    weather={Total=30,Groups=5,Resource="storm-update cards",Group="family"},
    family={Total=18,Groups=3,Resource="meeting-plan cards",Group="family"},
    flood={Total=28,Groups=4,Resource="safety cards",Group="family"},
    comfort={Total=24,Groups=3,Resource="comfort packs",Group="room"},
    clean={Total=18,Groups=3,Resource="paper wrappers",Group="recycling bag"},
}
for id,problem in pairs(sharing) do
    local quest=Data.ById[id]
    quest.Sharing=problem
    local plural=problem.Group=="family" and "families" or problem.Group.."s"
    quest.Intro..=" Then share "..problem.Total.." "..problem.Resource.." equally among "..problem.Groups.." "..plural..". Use small chunks, multiply, subtract, and check."
end
Data.StoryLinks = {
    go_bag="The town is getting ready for the storm. Help Aling Rosa pack a practice go-bag.",
    weather="While you help the town, Mang Ben can practice checking storm warnings with you.",
    family="Families need a plan for staying together. Lola Nena has a helping job for you.",
    flood="Rain can leave unsafe paths. Practice safe choices with Aling Lina.",
    comfort="Your medicine delivery helps the clinic. Nurse Ana also needs a little comfort kit.",
    clean="A clear, dry path helps families reach shelter. Ask Kuya Lito about the practice cleanup.",
}

function Data.Anchor(quest)
    local object = workspace
    for name in string.gmatch(quest.AnchorPath, "[^.]+") do
        object = object and object:FindFirstChild(name)
    end
    return object
end

function Data.TaskReady(quest, progress)
    if not progress then return false end
    if quest.Kind == "quiz" then return (progress.Step or 0) >= #quest.Questions end
    for _, item in ipairs(quest.Items) do if not progress.Items[item.Id] then return false end end
    return true
end

function Data.Ready(quest,progress)
    if progress and progress.Complete then return true end
    return Data.TaskReady(quest,progress) and (not quest.Sharing or progress.Sharing and progress.Sharing.Checked==true) or false
end

function Data.Objective(quest, progress)
    if progress and progress.Complete then return "Done! You helped " .. quest.Speaker .. "." end
    if not progress then return "Talk to " .. quest.Speaker .. "." end
    if Data.Ready(quest, progress) then return "Return to " .. quest.Speaker .. " to finish." end
    if Data.TaskReady(quest,progress) then return "Share the "..quest.Sharing.Resource.." in equal chunks with "..quest.Speaker.."." end
    if quest.Kind == "quiz" then return "Choose a safe answer with " .. quest.Speaker .. ": " .. ((progress.Step or 0) + 1) .. " of 3." end
    for _, item in ipairs(quest.Items) do
        if not progress.Items[item.Id] then return "Find the " .. string.lower(item.Name) .. " on the blue table." end
    end
end
local Titles=require(game.ReplicatedStorage.Brighthaven.GameTitles)
for _,q in ipairs(Data.Quests) do q.Title=Titles.Side[q.Id] or q.Title end

return Data