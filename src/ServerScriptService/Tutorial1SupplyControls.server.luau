local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local tutorialFolder = workspace
	:WaitForChild("Possible Map Replacement")
	:WaitForChild("Tutorial")
	:WaitForChild("Tutorial_1")

local openTentSupplyGui = ReplicatedStorage:WaitForChild("OpenTentSupplyGui")
local deliverTentSupplies = ReplicatedStorage:WaitForChild("DeliverTentSupplies")
local deductTentSupplies = ReplicatedStorage:WaitForChild("DeductTentSupplies")
local supplyBoxTemplate = ReplicatedStorage
	:WaitForChild("SupplyTools")
	:WaitForChild("SupplyBox")
local resetTentSupplies = ReplicatedStorage:WaitForChild("ResetTentSupplies")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")
local supplyBox = tutorialFolder:WaitForChild("SupplyBox")
local supplyPrompt = supplyBox:WaitForChild("ProximityPrompt")
local function syncPrompts()
    local active = tutorialFolder:GetAttribute("PracticeActive")==true
    supplyPrompt.Enabled = active
    for _, name in ipairs({"Tent1","Tent2","Tent3"}) do
        tutorialFolder[name].ProximityPrompt.Enabled = active
    end
end
syncPrompts()
tutorialFolder:GetAttributeChangedSignal("PracticeActive"):Connect(syncPrompts)
local function ensureSupplyGui(player)
	local supplyGuis = {}
	for _, child in ipairs(player.PlayerGui:GetChildren()) do
		if child:IsA("ScreenGui") and child.Name == "SupplyGui" then
			table.insert(supplyGuis, child)
		end
	end

	for index = 2, #supplyGuis do
		supplyGuis[index]:Destroy()                                                   
	end
end

Players.PlayerAdded:Connect(ensureSupplyGui)
for _, player in ipairs(Players:GetPlayers()) do
	ensureSupplyGui(player)
end
local tents = {}
for _, name in ipairs({"Tent1", "Tent2", "Tent3"}) do
	local tent = tutorialFolder:WaitForChild(name)
	tents[name] = {
		instance = tent,
		supplies = tent:WaitForChild("CurrentSupplies")
	}
end

local function getTutorialTent(name)
	if typeof(name) ~= "string" then
		return nil
	end

	return tents[name]
end

local function isNearTutorial(player, maxDistance, anchor)
	if not tutorialFolder:GetAttribute("PracticeActive") or tutorialFolder:GetAttribute("PracticeOwner")~=player.UserId then return false end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then
		return false
	end

	return (root.Position - (anchor or supplyBox).Position).Magnitude <= maxDistance
end

local function getHeldSupplyBox(player)
	local tool = player.Backpack and player.Backpack:FindFirstChild("SupplyBox")
	if not tool and player.Character then
		tool = player.Character:FindFirstChild("SupplyBox")
	end
	if tool and tool:IsA("Tool") then
		return tool
	end
	return nil
end

-- Fixed delivery: the tent receives the entire amount the player
-- is carrying in their supply box (no client-chosen amount).
deliverTentSupplies.OnServerEvent:Connect(function(player, tentName)
	local tentData = getTutorialTent(tentName)
	if not tentData or not isNearTutorial(player, 35, tentData.instance) then
		return
	end

	local tool = getHeldSupplyBox(player)
	if not tool then
		return
	end

	local toolAmount = tonumber(tool:GetAttribute("Amount")) or 0
	if toolAmount <= 0 then
		tool:Destroy()
		return
	end

	tentData.supplies.Value += toolAmount
	tool:Destroy()
end)

-- Deduct: take supplies back out of a tent. The deducted supplies
-- go back into the player's carried box (a new one is given if they
-- are not currently carrying one).
deductTentSupplies.OnServerEvent:Connect(function(player, tentName, amount)
	local tentData = getTutorialTent(tentName)
	if not tentData or not isNearTutorial(player, 35, tentData.instance) then
		return
	end

	amount = tonumber(amount)
	if not amount or amount < 1 or amount > 10 or amount % 1 ~= 0 then
		return
	end

	if amount > tentData.supplies.Value then
		showDialogue:FireClient(player, "This shelter has fewer supplies than that. Count its supplies and choose again.", "tutorial1_hint", "Supply Helper", "SC")
		return
	end
	local deducted = amount

	tentData.supplies.Value -= deducted

	local tool = getHeldSupplyBox(player)
	if tool then
		local currentAmount = tonumber(tool:GetAttribute("Amount")) or 0
		tool:SetAttribute("Amount", currentAmount + deducted)
	else
		local box = supplyBoxTemplate:Clone()
		box:SetAttribute("Amount", deducted)
		if box:IsA("Tool") then
			box.RequiresHandle = false
			box.CanBeDropped = false
		end
		box.Parent = player.Backpack
	end
end)

resetTentSupplies.OnServerEvent:Connect(function(player)
	if not isNearTutorial(player, 35) then
		return
	end

	local returned=0
	for _,tentData in pairs(tents) do returned+=tentData.supplies.Value end
	tutorialFolder.RemainingSupplies.Value+=returned
	for _, tentData in pairs(tents) do
		tentData.supplies.Value = 0
	end
end)


