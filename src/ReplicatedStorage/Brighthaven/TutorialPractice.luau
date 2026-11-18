local Practice = {}
local tutorials = workspace:WaitForChild("Possible Map Replacement"):WaitForChild("Tutorial")
Practice.Anchors = {
    tutorials.Tutorial_1.TutorialNPC1.HumanoidRootPart,
    tutorials.Tutorial_2.TutorialNPC2.HumanoidRootPart,
    tutorials.Tutorial_3.WarehouseTutorial.WarehouseNPCTutorial.HumanoidRootPart,
}
-- These folders include distant planning parts, so use the actual helpers.
function Practice.Stage(position)
    for i, anchor in ipairs(Practice.Anchors) do
        if (position - anchor.Position).Magnitude < 350 then return i end
    end
end
function Practice.PlayerStage(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and Practice.Stage(root.Position)
end
function Practice.CanUseWorld(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root ~= nil and Practice.Stage(root.Position) == nil
end
function Practice.Asset(name)
    if name == "supply" then return tutorials.Tutorial_1.SupplyBox.OpenBoxModel
    elseif name == "shelter" then return tutorials.Tutorial_1.Tent1.TentModel
    elseif name == "log" then return tutorials.Tutorial_2.Logs.Log_column1.Log1
    elseif name == "crate" then return game.ReplicatedStorage.Crate
    elseif name == "forklift" then return tutorials.Tutorial_3:FindFirstChild("TutorialForklift")
    elseif name == "receiving" then return tutorials.Tutorial_3.ForkliftPractice.Crates:FindFirstChild("Crate1")
    elseif name == "spot" then return tutorials.Tutorial_3.QuestSpotsTutorial:FindFirstChildWhichIsA("BasePart") end
end
Practice.Names = {"Supply Helper", "Counting Helper", "Warehouse Worker"}
Practice.Tasks = {"Share the supplies equally.", "Skip count to find your log path.", "Drive one chunk to each crate."}
Practice.Lessons = {
    {
        {Title="Share the supplies equally", Body="Equal sharing means every shelter gets the same amount. Share all the supplies among the three shelters. Nobody should get more or less.", Asset="supply", Caption="A fair share for every shelter"},
        {Title="Give everyone the same amount", Body="Give supplies to each of the three shelters. You can share one at a time or choose an equal amount for every shelter. Keep going until the supply box is empty.",Asset="supply",Caption="The same amount for every shelter"},
    },
    {{Title="Count in equal jumps", Body="Skip counting means adding the same number each time. Your number guide will show where to start. Add that number, then find your next log.", Asset="log", Caption="Equal number jumps along the logs"}},
    {
        {Title="Start with equal sharing", Body="Share the boxes at the loading bay among 3 crates. Your starting pile changes each time. A chunk is a small load. Give each crate the same load in every round.", Asset="receiving", Caption="Three crates, equal shares", Equation="Boxes at the bay / 3 crates = ?"},
        {Title="Find the factors", Body="Factors are numbers we multiply. Your factors are 3 crates and the boxes in each load. Use equal jumps to count all three loads. Type your answer at the loading bay.", Asset="receiving", Caption="Equal sharing helps us multiply", Equation="3 x boxes in each load = boxes this round"},
        {Title="Plan what will be left", Body="Subtract the boxes for this round from the pile. Type how many will be left. These two steps help you share a big pile in smaller chunks.", Asset="crate", Caption="Multiply, then subtract", Equation="Pile - boxes this round = boxes left"},
        {Title="Drive your equal loads", Body="Drive one chunk to a crate. Return for the same load for each other crate. Then plan your next round. If fewer boxes are left, make a smaller chunk and drive it on its own trips.", Asset="forklift", Caption="One chunk, one crate, one trip"},
    },
}
local hints = {
    {
        {Title="What is equal sharing?", Body="Equal sharing means every group gets the same amount. Look at the three shelters and the supplies left in the box.", Asset="shelter", Caption="Three shelters, the same amount"},
        {Title="Give each shelter a fair share", Body="Choose a small number of supplies. Visit each shelter and give it the same amount. Nobody should get more or less.", Asset="supply", Caption="Give the same amount to each shelter"},
        {Title="Count and check", Body="Read each shelter's number. Are they equal? If not, use Take Some Back and try again. Keep sharing until the box is empty.", Asset="shelter", Caption="Compare all three shelters"},
        {Title="Why fair sharing matters", Body="Equal sharing makes equal groups. Division asks how many are in each group. Count one shelter's supplies to find your answer.", Asset="shelter", Caption="Equal groups help us divide"},
        {Title="Check every fair share",Body="Compare the supplies in all three shelters. Everyone should have the same number, and the supply box should be empty. Move supplies back and try again if the shares do not match.",Asset="shelter",Caption="Equal amounts, nothing left in the box"},
    },
    {
        {Title="Try skip counting", Body="Add the same number each time. For example, count by 2: 2, 4, 6, 8. Each jump adds 2. Your log path uses a different starting number.", Asset="log", Caption="Example only: your number may be different", Equation="2, 4, 6, 8 ..."},
        {Title="Read your number guide", Body="The guide shows your starting number and the steps you finish. Add the starting number each time. Work out the next number yourself.", Asset="log", Caption="Your guide records the jumps you finish"},
        {Title="Work out your next jump", Body="Start with the number you last reached. Add the starting number. Find that answer on a log in the next row.", Asset="log", Caption="Choose your own path", Equation="Last number + starting number = ?"},
        {Title="How skip counting helps", Body="Skip counting means adding the same number each time. Check the pattern after every jump: the difference between two neighboring numbers should always match your starting number.", Asset="log", Caption="Keep adding the same number"},
        {Title="Check your counting pattern",Body="For example, counting by 2 gives 2, 4, 6, 8. Each number is 2 more than the last. Use your own starting number to check all three jumps.",Asset="log",Caption="Same-sized number jumps",Equation="2, 4, 6, 8"},
    },
    {
        {Title="Equal sharing comes first", Body="Every crate needs the same number of boxes. Choose a small load. Give that same load to all three crates before starting another round. This keeps sharing fair.", Asset="receiving", Caption="Equal sharing makes equal groups"},
        {Title="What are factors?", Body="Factors are numbers we multiply. Here, one factor is 3 crates. The other is the boxes in each load. Multiply them to count the boxes needed for a fair round.", Asset="receiving", Caption="Crates and boxes per crate are your factors", Equation="3 x boxes per load = boxes this round"},
        {Title="Use equal jumps", Body="Add your load size three times: once for each crate. That is the same as multiplying by 3. Try it yourself, then type your total at the loading bay.", Asset="crate", Caption="Skip counting helps with your factors", Equation="Load + load + load = 3 x load"},
        {Title="Subtract, then deliver", Body="Take your round's total away from the pile. Type how many boxes will be left. Then drive one chunk to each crate. Boxes move only when you deliver them.", Asset="forklift", Caption="Plan first. Drive one chunk per trip.", Equation="Pile - boxes this round = boxes left"},
        {Title="Plan a smaller chunk", Body="If your usual load is too big for all three crates, choose a smaller equal load. Multiply and subtract again. Drive those smaller chunks on their own trips.", Asset="receiving", Caption="Finish the leftover boxes with equal loads"},
        {Title="Check your groups", Body="Add the chunks inside one crate. That is your division answer. Compare the three crates. They should match, and the loading bay should be empty.", Asset="receiving", Caption="Use your delivery record to check"},
        {Title="Helping earns XP later", Body="In BrightHaven, a quest is a helping job from a neighbor. Finish quests to earn experience points, called XP. Practice does not give XP.", Asset="crate", Caption="Practice here, help the town later"},
    },
}
local kinds = {tutorial1=true, tutorial1_failed=true, tutorial1_complete=true, tutorial1_hint=true,
    tutorial2=true, tutorial2_running=true, tutorial2_complete=true,
    WH_tutorial=true, tutorial3_failed=true, tutorial3_complete=true}
function Practice.IsPracticeKind(kind) return kinds[kind] == true end
function Practice.Index(kind)
    if kind == "WH_tutorial" then return 3 end
    return tonumber((kind or ""):match("^tutorial(%d)"))
end
function Practice.IsBriefing(kind)
    return kind == "tutorial1" or kind == "tutorial2" or kind == "WH_tutorial"
end
local notices = {
    tutorial1_failed="Check all three shelters. Each should have the same number of supplies.",
    tutorial1_complete="Fair sharing! Follow the green arrows to the next helper.",
    tutorial2_running="Your guide shows where to start. Add the same number each jump.",
    tutorial2_complete="Great skip counting! Follow the yellow arrows to the warehouse.",
    tutorial3_failed="Keep each round fair. Drive the same chunk to every crate.",
    tutorial3_complete="Equal groups! Follow the yellow arrows to the exit gate, then press E to enter BrightHaven.",
}
function Practice.Notice(kind) return notices[kind] end
function Practice.Pages(kind, message)
    local index = Practice.Index(kind)
    if Practice.IsBriefing(kind) then
        local pages = {}
        for _, page in ipairs(Practice.Lessons[index]) do table.insert(pages, table.clone(page)) end
        if index == 1 then
            local total = tutorials.Tutorial_1.TotalSupplies.Value
            pages[1].Body = "Equal sharing means every shelter gets the same amount. Share all " .. total .. " supplies among the three shelters. Nobody should get more or less."
            pages[1].Equation = total .. " supplies / 3 shelters = ?"
        end
        return pages
    end
    return {{Body=Practice.Notice(kind) or message or "Take your time and try your idea."}}
end
function Practice.GuidePages(index, startingNumber)
    local pages = {}
    for _, page in ipairs(hints[index]) do table.insert(pages, table.clone(page)) end
    if index == 2 and startingNumber and startingNumber >= 4 and startingNumber <= 9 then
        pages[2].Body = "Start at " .. startingNumber .. ". Add " .. startingNumber .. " each jump. The guide shows only the steps you finish. Work out the next number before choosing a log."
    end
    return pages
end
-- Legacy NPCs keep their quest actions and readable pages.
function Practice.MessagePages(message, title)
    local result, words, length = {}, {}, 0
    local function flush()
        if #words > 0 then table.insert(result, {Title=title, Body=table.concat(words, " ")}); words, length = {}, 0 end
    end
    for word in (message or "Let's help together!"):gmatch("%S+") do
        if length + #word + 1 > 170 then flush() end
        table.insert(words, word)
        length += #word + 1
        if length >= 90 and word:match("[.!?]$") then flush() end
    end
    flush()
    if #result == 0 then table.insert(result, {Title=title, Body="Let's help together!"}) end
    return result
end
Practice.Lessons={
 {{Title='Hati-Hati Heroes',Body='Share all the supplies fairly among the three shelters. Give every shelter the same amount, empty the supply box, then compare the three totals to check your equal shares.',Asset='supply',Caption='Three shelters, equal shares'}},
 {{Title='Lundag Bilang',Body='Add the starting number once per row. Choose the matching wooden plank. The planks turn slowly: line up near the middle, then jump to the next safe landing.',Asset='log',Caption='Three skip-counting stages'}},
 {{Title='Kargada Quest',Body='Plan 3 boxes per crate: multiply and subtract, then make three deliveries. Plan one smaller round to finish. Add the chunks in one crate to check.',Asset='forklift',Caption='Two rounds, six short deliveries'}},
}
local Titles=require(game.ReplicatedStorage.Brighthaven.GameTitles)
Practice.GameNames=Titles.Practice
for i,pages in ipairs(Practice.Lessons) do if pages[1] then pages[1].Title=Titles.Practice[i] end end

return Practice