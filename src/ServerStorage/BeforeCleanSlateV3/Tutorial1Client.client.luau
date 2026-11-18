tutorial1server:
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
local startTutorial1 = ReplicatedStorage:WaitForChild("StartTutorial1")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")
local tutorialFolder = workspace
		:WaitForChild("Possible Map Replacement")
	:WaitForChild("Tutorial")
	:WaitForChild("Tutorial_1")
local totalSupplies = tutorialFolder:WaitForChild("TotalSupplies")
local remainingSupplies = tutorialFolder:WaitForChild("RemainingSupplies")
local supplyBox = tutorialFolder:WaitForChild("SupplyBox")
local supplyPrompt = supplyBox:WaitForChild("ProximityPrompt")
local tutorialNPC = tutorialFolder:WaitForChild("TutorialNPC1")
local npcPrompt = tutorialNPC
	:WaitForChild("HumanoidRootPart")
	:WaitForChild("ProximityPrompt")
local currentPlayer = nil
local tutorialStarted = false
supplyPrompt.Enabled = true
npcPrompt.Enabled = true
local counterPart = supplyBox:WaitForChild("CounterPart")
local surfaceGui = counterPart:WaitForChild("SurfaceGui")
local counterLabel = surfaceGui:WaitForChild("TextLabel")
-- SupplyStation billboard showing total supplies to deliver
local supplyStation = workspace:FindFirstChild("SupplyStation")
local stationBillboardLabel = nil
if supplyStation then
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         	local billboard = supplyStation:FindFirstChild("BoxSupplyBillboard")
	if billboard then
		stationBillboardLabel = billboard:FindFirstChild("TextLabel")
	end
end
surfaceGui.Enabled = false
local tent1 = tutorialFolder:WaitForChild("Tent1")
local tent2 = tutorialFolder:WaitForChild("Tent2")
local tent3 = tutorialFolder:WaitForChild("Tent3")
local tent1Supplies = tent1:WaitForChild("CurrentSupplies")
local tent2Supplies = tent2:WaitForChild("CurrentSupplies")
local tent3Supplies = tent3:WaitForChild("CurrentSupplies")
local possibleTotals = {
	12,
	18, 
	24,
	30
}
local function updateCounterDisplay()
	counterLabel.Text = string.format("%d / %d", remainingSupplies.Value, totalSupplies.Value)
	if stationBillboardLabel then
		stationBillboardLabel.Text = string.format("Supplies to Deliver: %d", totalSupplies.Value)
	end
end
local function checkTutorialComplete()
	if remainingSupplies.Value > 0 then
		return
	end
	if tent1Supplies.Value == tent2Supplies.Value
		and tent2Supplies.Value == tent3Supplies.Value then

		print("================================")
		print("TUTORIAL 1 COMPLETE!")
		print("================================")

		supplyPrompt.Enabled = true
		npcPrompt.Enabled = false

		showDialogue:FireClient(
			currentPlayer,
			"dialogue",
			"Excellent work! You shared all the supplies equally! The main security gate keycard has been updated.",
			"Supply Captain Rita",
			"SCR"
		)
	end
end
-- Triggers right when the player spawns into Tutorial 1
startTutorial1.OnServerEvent:Connect(function(player)
	if tutorialStarted then
		print("Tutorial 1 is already active or completed.")
		return
	end
	tutorialStarted = true
	currentPlayer = player

	-- Select total supply count from random options
	local total = possibleTotals[math.random(1, #possibleTotals)]

	totalSupplies.Value = total
	remainingSupplies.Value = total

	updateCounterDisplay()
	surfaceGui.Enabled = true

	tent1Supplies.Value = 0
	tent2Supplies.Value = 0
	tent3Supplies.Value = 0

	supplyPrompt.Enabled = true
	npcPrompt.Enabled = true

	-- Immediate Welcome/Spawn Frame Dialogue
	showDialogue:FireClient(
		currentPlayer,
		--"welcome",--
		"Welcome to Relief Base! Typhoon Astra is approaching, and the main gate is locked down. To unlock the gate, you must complete your emergency protocol training. Approach Supply Captain Rita and talk to her to receive your tutorial instructions!",
		"Base Command",
		"BC"
	)
end)
-- Triggers when player talks to the NPC
npcPrompt.Triggered:Connect(function(player)
	if player ~= currentPlayer and currentPlayer ~= nil then
		return
	end
	local total = totalSupplies.Value
	local perTent = total / 3

	-- Enable supply box interaction after NPC dialogue
	supplyPrompt.Enabled = true

	local npcMessage = string.format(
		"Recruit! Evacuees need emergency provisions immediately. Drag all %d supply boxes and distribute them equally among the 3 tents so every tent receives exactly %d boxes. Once all boxes are loaded, hit 'Verify Distribution' to seal the crates!",
		total,
		perTent
	)

	showDialogue:FireClient(
		player,
		"dialogue",
		npcMessage,
		"Supply Captain Rita",
		"SCR"
	)
end)
remainingSupplies.Changed:Connect(function() updateCounterDisplay() checkTutorialComplete() end) tent1Supplies.Changed:Connect(checkTutorialComplete) tent2Supplies.Changed:Connect(checkTutorialComplete) tent3Supplies.Changed:Connect(checkTutorialComplete)