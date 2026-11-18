local ReplicatedStorage = game:GetService("ReplicatedStorage")

local supplyBox = script.Parent
local prompt = supplyBox:WaitForChild("ProximityPrompt")

local counterPart = supplyBox:WaitForChild("CounterPart")
local counterLabel = counterPart
	:WaitForChild("SurfaceGui")
	:WaitForChild("TextLabel")

local openSupplyGui = ReplicatedStorage:WaitForChild("OpenSupplyGui")
local takeSupplies = ReplicatedStorage:WaitForChild("TakeSupplies")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")

local supplyTools = ReplicatedStorage:WaitForChild("SupplyTools")
local carriedSupplyBox = supplyTools:WaitForChild("SupplyBox")

local tutorialFolder = workspace
	:WaitForChild("Possible Map Replacement")
	:WaitForChild("Tutorial")
	:WaitForChild("Tutorial_1")

local remainingSupplies = tutorialFolder:WaitForChild("RemainingSupplies")
local totalSupplies = tutorialFolder:WaitForChild("TotalSupplies")


local function canUseBox(player)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return tutorialFolder:GetAttribute("PracticeActive")==true and tutorialFolder:GetAttribute("PracticeOwner")==player.UserId
        and root and (root.Position-supplyBox.Position).Magnitude<=35
end
prompt.Triggered:Connect(function(player)
	if not canUseBox(player) then return end
	print(player.Name .. " opened the Supply Box")
	openSupplyGui:FireClient(player)
end)


takeSupplies.OnServerEvent:Connect(function(player, amount)
	if not canUseBox(player) then return end
	print(player.Name .. " requested " .. tostring(amount) .. " supplies")

	-- Validate amount type and value
	amount = tonumber(amount)
	if not amount or amount < 1 or amount > 10 or amount%1~=0 then
		warn("Invalid amount requested:", amount)
		return
	end

	-- Check remaining supplies
	if amount > remainingSupplies.Value then
		showDialogue:FireClient(player, "The box has fewer supplies than that. Count what is left, then choose again.", "tutorial1_hint", "Supply Helper", "SC")
		return
	end

	-- Check if player is already holding a supply box
	local hasInBackpack = player.Backpack:FindFirstChild("SupplyBox")
	local hasInChar = player.Character and player.Character:FindFirstChild("SupplyBox")

	if hasInBackpack or hasInChar then
		showDialogue:FireClient(player, "You already have a box. Take it to a shelter before picking up another.", "tutorial1_hint", "Supply Helper", "SC")
		return
	end

	-- Deduct supplies from storage
	remainingSupplies.Value -= amount
	counterLabel.Text = string.format("%d / %d", remainingSupplies.Value, totalSupplies.Value)

	-- Clone and configure the supply tool
	local box = carriedSupplyBox:Clone()
	box:SetAttribute("Amount", amount)

	-- Ensure tool is usable without a Handle part if needed
	if box:IsA("Tool") then
		box.RequiresHandle = false
		box.CanBeDropped = false
	end

	-- Give tool to player
	box.Parent = player.Backpack

	print("Successfully gave " .. amount .. " supplies to " .. player.Name)
end)

