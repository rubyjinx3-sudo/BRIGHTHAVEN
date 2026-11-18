local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NumberRules = require(ReplicatedStorage.Brighthaven:WaitForChild("TutorialNumberRules"))
local Practice = require(ReplicatedStorage.Brighthaven.TutorialPractice)
local startTutorial2 = ReplicatedStorage:WaitForChild("StartTutorial2")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")
local tutorialFolder = workspace:WaitForChild("Possible Map Replacement")
    :WaitForChild("Tutorial"):WaitForChild("Tutorial_2")
local logsFolder = tutorialFolder:WaitForChild("Logs")
local originalNumber = tutorialFolder:WaitForChild("OriginalNumber")
local currentPlayer, tutorialStarted, lastStartingNumber
local previousCorrectSlots = {}

local function chooseStartingNumber()
    local choices = {}
    for number = 4, 9 do
        if number ~= lastStartingNumber then table.insert(choices, number) end
    end
    lastStartingNumber = choices[math.random(1, #choices)]
    return lastStartingNumber
end

local function physicalSlots(column)
    local parts = {column:WaitForChild("Log1"), column:WaitForChild("Log2"), column:WaitForChild("Log3")}
    local xMin, xMax, zMin, zMax = math.huge, -math.huge, math.huge, -math.huge
    for _, part in ipairs(parts) do
        xMin, xMax = math.min(xMin, part.Position.X), math.max(xMax, part.Position.X)
        zMin, zMax = math.min(zMin, part.Position.Z), math.max(zMax, part.Position.Z)
    end
    local axis = xMax - xMin > zMax - zMin and "X" or "Z"
    table.sort(parts, function(a, b) return a.Position[axis] < b.Position[axis] end)
    return parts
end

local function generateColumn(column, correctNumber)
    local values = NumberRules.LogChoices(correctNumber, previousCorrectSlots[column])
    for slot, log in ipairs(physicalSlots(column)) do
        log:WaitForChild("LogLabel"):WaitForChild("TextLabel").Text = tostring(values[slot])
        local top=log:FindFirstChild("TopNumber");if top then top.TextLabel.Text=tostring(values[slot]) end
        local correct = values[slot] == correctNumber
        log:SetAttribute("IsCorrect", correct)
        if correct then previousCorrectSlots[column] = slot end
    end
end

local function generateProblem()
    originalNumber.Value = chooseStartingNumber()
    for row = 1, 3 do
        generateColumn(logsFolder:WaitForChild("Log_column" .. row), originalNumber.Value * (row + 1))
    end
end

local function showCountingSteps(player)
    showDialogue:FireClient(player,
        "Start at " .. originalNumber.Value .. ". Add the same number each jump. Your guide records the steps you finish.",
        "tutorial2_running", "Counting Helper", "CH", {StartingNumber = originalNumber.Value})
end

startTutorial2.OnServerEvent:Connect(function(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position - tutorialFolder.TutorialNPC2.HumanoidRootPart.Position).Magnitude > 18 then return end
    if player:GetAttribute("Tutorial2Practice")=="complete" then
        showDialogue:FireClient(player,"Great skip counting! Follow the guide to the warehouse.","tutorial2_complete","Counting Helper")
        return
    end
    if tutorialStarted then return end
    logsFolder:SetAttribute("ResetCount",(logsFolder:GetAttribute("ResetCount") or 0)+1)
    tutorialStarted, currentPlayer = true, player
    generateProblem()
    player:SetAttribute("Tutorial2Row", 1)
    player:SetAttribute("Tutorial2Practice", "active")
    tutorialFolder.TutorialNPC2.HumanoidRootPart.ProximityPrompt.Enabled = false
    showCountingSteps(player)
end)

logsFolder:GetAttributeChangedSignal("ResetCount"):Connect(function()
    local player = currentPlayer
    if not tutorialStarted or not player or player:GetAttribute("Tutorial2Practice") ~= "active" then return end
    generateProblem()
    if player.Parent then
        player:SetAttribute("Tutorial2Row", 1)
        showCountingSteps(player)
    end
end)

Players.PlayerRemoving:Connect(function(player)
    if player ~= currentPlayer then return end
    currentPlayer, tutorialStarted = nil, false
    tutorialFolder.TutorialNPC2.HumanoidRootPart.ProximityPrompt.Enabled = true
end)

task.spawn(function()
    while true do
        task.wait(1)
        local player=currentPlayer
        local character=player and player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if player and (player:GetAttribute("Tutorial2Practice")=="complete"
            or humanoid and humanoid.Health>0 and not player:GetAttribute("Tutorial2LavaFall") and character:FindFirstChild("HumanoidRootPart") and Practice.PlayerStage(player)~=2) then
            currentPlayer,tutorialStarted=nil,false
            tutorialFolder.TutorialNPC2.HumanoidRootPart.ProximityPrompt.Enabled=true
        end
    end
end)


game.ServerScriptService:WaitForChild('BarangayPracticeReset').Event:Connect(function(player,index)
 if index~=2 or currentPlayer and currentPlayer~=player and tutorialStarted then return end
 currentPlayer=nil;tutorialStarted=false;player:SetAttribute('Tutorial2Practice',nil);player:SetAttribute('Tutorial2Row',nil)
 tutorialFolder.TutorialNPC2.HumanoidRootPart.ProximityPrompt.Enabled=true
end)
