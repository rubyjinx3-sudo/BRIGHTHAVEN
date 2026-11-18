local Data = {}

Data.Version = 1
Data.Order = {"dumpsite", "wood", "train", "clinic", "shop", "power", "lab"}
Data.PartNames = {"Ion Stabilizer", "Atmospheric Core", "Wind Turbine"}
Data.MachineName = "Storm Stopper"
Data.EndGoal = "Help Dr. Liza build the Storm Stopper: find all 3 parts, restore power, and stop the super typhoon before it reaches BrightHaven."
Data.Nodes = {
    school = {Title = "School Shuttle", Speaker = "Shuttle Helper", Badge = "SH", Position = Vector3.new(-265.6, -142.814, 63.2), Next = "dumpsite"},
    dumpsite = {Title = "Linis Barangay Yard", Speaker = "Kuya Nestor", Badge = "KN", Position = Vector3.new(672, -142.814, -72), Next = "wood",
        Intro = "The Storm Stopper's first part may be in this pile! Sort paper, plastic, and metal. Shoot each item into the right bin, then share our recycling loads equally.",
        Thanks = "The path is clear! You found the first machine part. The woodworker needs help next."},
    wood = {Title = "Wood Area", Speaker = "Woodworker", Badge = "WW", Position = Vector3.new(-320, -142.814, -480), Next = "train",
        Intro = "This fallen log blocks our delivery route! Use the game axe in this practice area. Chop at the marked stump, then count equal 4-meter pieces. Keep real axes with grown-ups.",
        Thanks = "The path is open! We have equal firewood pieces for the families. Supplies can reach the clinic while we find the Storm Stopper's other parts."},
    train = {Title = "Train Station", Speaker = "Station Helper", Badge = "ST", Position = Vector3.new(28, -142.814, -416), Next = "clinic",
        Intro = "You cleared the way! The train brought medicine for Dr. Maya. Give each truck the same number of boxes. Any extra boxes go straight to the clinic.",
        Thanks = "Medicine is on its way! Keeping families healthy gives Dr. Liza time to build the Storm Stopper. Dr. Maya is waiting."},
    clinic = {Title = "Barangay Clinic", Speaker = "Dr. Maya", Badge = "DR", Position = Vector3.new(-108.8, -142.814, 62.4), Next = "shop",
        Intro = "Thank you for helping our medicine arrive! Now let's give each room the same number of pesos to buy supplies.",
        Thanks = "Each room can buy supplies! The shop helper has the last two parts for the Storm Stopper."},
    shop = {Title = "General Shop", Speaker = "Shop Helper", Badge = "GS", Position = Vector3.new(-404.356005859, -142.814, 322.979589844), Next = "power",
        Intro = "I have the Storm Stopper's Atmospheric Core and Wind Turbine. Help me price lanterns for families. Earn both parts by finishing this helping job!",
        Thanks = "You found the prices! Here are the other two machine parts. The lights went out. Let's help at the power station."},
    power = {Title = "Power Station", Speaker = "Power Helper", Badge = "PH", Position = Vector3.new(320.8, -142.814, -432), Next = "lab",
        Intro = "You have all the parts, but the lab needs power! Use this pretend meter to give each tower the same number of power units. The grown-ups will do the repairs.",
        Thanks = "The lights are back on! Take your three machine parts to the scientist at the weather lab."},
    lab = {Title = "Weather Lab", Speaker = "Scientist", Badge = "SC", Position = Vector3.new(216, -142.814, 663.2),
        Intro = "I could not build this alone. Thank you for helping! Install all 3 parts in the Storm Stopper. Share energy and signals carefully so its beam can break apart the storm.",
        Thanks = "The Storm Stopper broke apart the super typhoon! You saved our barangay. Tell Captain Kappa how everyone helped."},
}

Data.ClinicStaff = {
    nurse = {Name = "Nurse Ana", Badge = "NA", Message = "Hi! I am Nurse Ana. I help patients rest and feel better. Dr. Maya is near the front door. She needs your help sharing money for our rooms."},
    reception = {Name = "Clinic Helper Ben", Badge = "BH", Message = "Welcome to our clinic! I help families find the right room. Walk to the front door and talk to Dr. Maya. Thank you for helping our town!"},
}

Data.Missions = {}
Data.ById = {}
local function add(id, node, title, total, groups, chunks, resource, group, mode, extra)
    local item = {Id = id, Node = node, Title = title, Dividend = total, Divisor = groups,
        Chunks = chunks, Resource = resource, Group = group, Mode = mode or "share"}
    for key, value in pairs(extra or {}) do item[key] = value end
    table.insert(Data.Missions, item)
    Data.ById[id] = item
end

add("yard_metal", "dumpsite", "Load Metal Blocks", 180, 5, {30, 6}, "metal blocks", "truck")
add("yard_plastic", "dumpsite", "Load Recycling Boxes", 192, 6, {30, 2}, "recycling boxes", "truck")
add("yard_planks", "dumpsite", "Load Wooden Planks", 224, 4, {50, 6}, "wooden planks", "truck")
add("wood_log", "wood", "Count Wood Pieces", 120, 4, {20, 10}, "meters", "piece", "measure")
for _,mission in ipairs(Data.Missions) do
    if mission.Node=="dumpsite" or mission.Node=="wood" then mission.Activity=mission.Node=="wood" and "chop" or "sort" end
end
add("train_215", "train", "215 Medicine Boxes", 215, 7, {20, 10}, "medicine boxes", "truck", "share", {RemainderPlan = "clinic"})
add("train_210", "train", "210 Medicine Boxes", 210, 7, {20, 10}, "medicine boxes", "truck", "share", {RemainderPlan = "clinic"})
add("train_250", "train", "250 Medicine Boxes", 250, 8, {20, 10, 1}, "medicine boxes", "truck", "share", {RemainderPlan = "clinic"})
add("clinic_960", "clinic", "Share 960 Pesos", 960, 8, {100, 20}, "pesos", "room", "money")
add("clinic_840", "clinic", "Share 840 Pesos", 840, 7, {100, 20}, "pesos", "room", "money")
add("clinic_720", "clinic", "Share 720 Pesos", 720, 6, {100, 20}, "pesos", "room", "money")
add("shop_lanterns", "shop", "Price of One Lantern", 720, 9, {50, 30}, "pesos", "lantern", "price")
add("shop_radios", "shop", "Price of One Radio", 640, 8, {50, 30}, "pesos", "radio", "price")
add("shop_banks", "shop", "Price of One Power Bank", 560, 7, {50, 30}, "pesos", "power bank", "price")
add("power_400", "power", "400 Power Units", 400, 5, {50, 30}, "power units", "tower", "power")
add("power_320", "power", "320 Power Units", 320, 4, {50, 30}, "power units", "tower", "power")
add("power_450", "power", "450 Power Units", 450, 5, {50, 40}, "power units", "tower", "power")
add("power_480", "power", "480 Power Units", 480, 6, {50, 30}, "power units", "tower", "power")
add("lab_energy_450", "lab", "1. Share Energy", 450, 5, {50, 40}, "energy units", "beam", "power", {Round = 1})
add("lab_energy_400", "lab", "1. Share 400 Energy Units", 400, 5, {50, 30}, "energy units", "beam", "power", {Round = 1})
add("lab_energy_540", "lab", "1. Share 540 Energy Units", 540, 6, {50, 40}, "energy units", "beam", "power", {Round = 1})
add("lab_energy_630", "lab", "1. Share 630 Energy Units", 630, 7, {50, 40}, "energy units", "beam", "power", {Round = 1})
add("lab_pulses", "lab", "2. Share Signals", 360, 6, {50, 10}, "signals", "dish", "power", {Round = 2})
add("lab_reserve", "lab", "3. Share the Lab Money", 1000, 8, {100, 25}, "pesos", "power cell", "money", {Round = 3})

for _,mission in ipairs(Data.Missions) do
 local kinds={train="freight",clinic="care",shop="stock",power="power",lab="science"}
 if kinds[mission.Node] then mission.Activity=kinds[mission.Node] end
 local full=math.floor(mission.Dividend/mission.Divisor)
 for i=#mission.Chunks,1,-1 do if mission.Chunks[i]>=full then table.remove(mission.Chunks,i) end end
 local half=math.max(1,math.floor(full/2));if not table.find(mission.Chunks,half) then table.insert(mission.Chunks,1,half) end
end
function Data.Story(mission)
    if mission.Mode == "measure" then
        return "The fallen log is 120 meters long. Chop in our game area, then count equal 4-meter pieces. How many pieces can we make?"
    elseif mission.Mode == "price" then
        return mission.Divisor .. " " .. Data.GroupPlural(mission) .. " cost " .. mission.Dividend .. " pesos altogether. Find the price of one " .. mission.Group .. "."
    end
    return "There are " .. mission.Dividend .. " " .. mission.Resource .. ". Share them among " .. mission.Divisor .. " " .. Data.GroupPlural(mission) .. "."
end

function Data.GroupPlural(mission)
    return mission.Group == "dish" and "dishes" or mission.Group .. "s"
end

function Data.ChunkText(mission, number)
    if mission.Mode == "measure" then
        return number == 1 and "Count 1 piece that is 4 meters long" or "Count " .. number .. " pieces, each 4 meters long"
    end
    if mission.Mode == "price" then return "Count " .. number .. (number == 1 and " peso" or " pesos") .. " for each " .. mission.Group end
    if number == 1 then
        local single = { ["metal blocks"] = "metal block", ["recycling boxes"] = "recycling box",
            ["wooden planks"] = "wooden plank", ["medicine boxes"] = "medicine box", ["pesos"] = "peso",
            ["power units"] = "power unit", ["energy units"] = "energy unit", ["signals"] = "signal" }
        return "Give 1 " .. (single[mission.Resource] or mission.Resource) .. " to each " .. mission.Group
    end
    return "Give " .. number .. " " .. mission.Resource .. " to each " .. mission.Group
end

function Data.GetChoices(node, labRound)
    local result = {}
    for _,mission in ipairs(Data.Missions) do
        if mission.Node == node and (node ~= "lab" or labRound == nil or mission.Round == labRound) then table.insert(result, mission) end
    end
    return result
end

for id,node in pairs(Data.Nodes) do local m=workspace.BrighthavenStoryExtension:FindFirstChild(id);if m and m:FindFirstChild("HelperAnchor") then node.Position=m.HelperAnchor.Position end end
local Titles=require(game.ReplicatedStorage.Brighthaven.GameTitles)
for _,mission in ipairs(Data.Missions) do mission.Title=Titles.Missions[mission.Id] or mission.Title end
for id,node in pairs(Data.Nodes) do node.Title=Titles.Nodes[id] or node.Title end

return Data