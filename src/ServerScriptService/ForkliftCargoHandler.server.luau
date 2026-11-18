local ReplicatedStorage = game:GetService("ReplicatedStorage")

local checkForkliftCargo = ReplicatedStorage:WaitForChild("CheckForkliftCargo")
local cargoBox = ReplicatedStorage:WaitForChild("CargoBox")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")

local DIVISOR = 6
local MAX_CHUNK = 60

checkForkliftCargo.OnServerEvent:Connect(function(player, multiplier)

	if player:GetAttribute("ForkliftQuestActive") ~= true then
		return
	end

	local cargoAmount = player:GetAttribute("ForkliftCargo")

	if not cargoAmount or cargoAmount <= 0 then
		return
	end

	if typeof(multiplier) ~= "number" then
		return
	end

	if multiplier <= 0 then
		return
	end

	local chunkAmount = DIVISOR * multiplier

	print(player.Name .. " requested chunk:", chunkAmount)
	print("Divisor:", DIVISOR)
	print("Multiplier:", multiplier)

	if chunkAmount > MAX_CHUNK then
		print("Chunk is too large for the forklift!")
		return
	end

	if chunkAmount > cargoAmount then
		print("Chunk is larger than remaining cargo!")
		return
	end

	local forklift = workspace:FindFirstChild("Forklift")

	if not forklift then
		print("Forklift not found!")
		return
	end

	local body = forklift:FindFirstChild("Body")

	if not body then
		print("Forklift Body not found!")
		return
	end

	local model = body:FindFirstChild("Model")

	if not model then
		print("Forklift Body Model not found!")
		return
	end

	local collision = model:FindFirstChild("Collision")

	if not collision then
		print("Forklift Collision not found!")
		return
	end

	-- Create cargo box
	local box = cargoBox:Clone()
	box.Parent = forklift

	-- Put cargo box on the front lift
	box.CFrame = collision.CFrame * CFrame.new(0, 2.5, 0)

	-- Attach cargo box to the forklift
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = collision
	weld.Part1 = box
	weld.Parent = box

	-- Remove the loaded chunk from remaining cargo
	local remainingCargo = cargoAmount - chunkAmount

	player:SetAttribute("ForkliftCargo", remainingCargo)

	print("Chunk loaded:", chunkAmount)
	print("Remaining cargo:", remainingCargo)

	-- Remaining cargo is too small to make another complete group
	if remainingCargo > 0 and remainingCargo < DIVISOR then

		print("Remaining cargo is less than the divisor.")
		print("Forklift Captain is taking over.")

		showDialogue:FireClient(
			player,
			"Looks like they overloaded or given us extra, lad. I'll call the head and ask 'em what to do about it. Good work, lad. I'll take it from here.",
			"forklift_overload",
			"Forklift Captain",
			"FC"
		)

		player:SetAttribute("ForkliftQuestActive", false)
	
	elseif remainingCargo == 0 then 
		
		showDialogue:FireClient(
			player,
			"Good job, lad! You're a natural on that machine.",
			"forklift_complete",
			"Forklift Captain",
			"FC"
		)
		
	end

end)