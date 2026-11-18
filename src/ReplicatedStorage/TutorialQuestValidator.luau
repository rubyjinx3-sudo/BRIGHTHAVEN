-- ReplicatedStorage.TutorialQuestValidator
-- Shared module for checking the tutorial quest state after each crate deposit.
-- If all crates are placed on the 3 QuestSpots and equally distributed -> congrats.
-- If all placed but not equal (e.g. 6/6/3) -> throw crates back to spawn area.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local module = {}

local SPOT_RADIUS = 2 -- flat-distance threshold for a crate to count as "on a spot"

-- Walk the hierarchy to find the QuestSpotsTutorial model.
local function findQuestSpots()
	local mapReplacement = workspace:FindFirstChild("Possible Map Replacement")
	if not mapReplacement then return nil end
	local tutorial = mapReplacement:FindFirstChild("Tutorial")
	if not tutorial then return nil end
	local tutorial3 = tutorial:FindFirstChild("Tutorial_3")
	if not tutorial3 then return nil end
	local questSpotsModel = tutorial3:FindFirstChild("QuestSpotsTutorial")
	if not questSpotsModel then return nil end
	return questSpotsModel:GetChildren()
end

local function findSpawnMarker()
	return workspace:FindFirstChild("SpawnMarkerTutorial")
end

-- Count crates sitting on a given spot (flat distance < SPOT_RADIUS).
local function countCratesOnSpot(spot)
	local count = 0
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("TutorialCrate") then
			local flatDist = (Vector3.new(obj.Position.X, 0, obj.Position.Z)
				- Vector3.new(spot.Position.X, 0, spot.Position.Z)).Magnitude
			if flatDist < SPOT_RADIUS then
				count += 1
			end
		end
	end
	return count
end

-- Is this crate sitting on any of the given spots?
local function isCrateOnAnySpot(crate, spots)
	for _, spot in ipairs(spots) do
		local flatDist = (Vector3.new(crate.Position.X, 0, crate.Position.Z)
			- Vector3.new(spot.Position.X, 0, spot.Position.Z)).Magnitude
		if flatDist < SPOT_RADIUS then
			return true
		end
	end
	return false
end

-- Check if any player is currently holding a crate (CrateWeld on a character).
local function isAnyPlayerHoldingCrate()
	for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
		local character = player.Character
		if character then
			for _, obj in pairs(character:GetDescendants()) do
				if obj:IsA("WeldConstraint") and obj.Name == "CrateWeld" and obj.Part0 and obj.Part0:GetAttribute("TutorialCrate") then
					return true
				end
			end
		end
	end
	return false
end

-- Count crates that are NOT on any spot (i.e. still in spawn area or elsewhere).
local function countCratesNotOnSpots(spots)
	local count = 0
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj:GetAttribute("TutorialCrate") then
			if not isCrateOnAnySpot(obj, spots) then
				count += 1
			end
		end
	end
	return count
end

function module.checkQuest(player)
	if not player or player:GetAttribute("Tutorial3Practice")~="active" then return end
	local spots = findQuestSpots()
	if not spots or #spots == 0 then return end

	local spawnMarker = findSpawnMarker()
	if not spawnMarker then return end

	-- Count crates on each spot and total.
	local spotCounts = {}
	local totalOnSpots = 0
	for i, spot in ipairs(spots) do
		spotCounts[i] = countCratesOnSpot(spot)
		totalOnSpots += spotCounts[i]
	end

	-- Only proceed when ALL conditions are met:
	-- 1. At least one crate is on a spot (don't trigger on empty state).
	-- 2. No player is holding a crate (all crates have been deposited).
	-- 3. No crates remain off-spot (all spawned crates are on platforms).
	if totalOnSpots == 0 then
		return
	end

	if isAnyPlayerHoldingCrate() then
		return
	end

	local cratesNotOnSpots = countCratesNotOnSpots(spots)
	if cratesNotOnSpots > 0 then
		return
	end

	-- Check whether all spots have an equal count.
	local firstCount = spotCounts[1]
	local allEqual = true
	for i = 2, #spotCounts do
		if spotCounts[i] ~= firstCount then
			allEqual = false
			break
		end
	end

	local showDialogue = ReplicatedStorage:FindFirstChild("ShowDialogue")

	if allEqual then
		player:SetAttribute("Tutorial3Practice","complete")
		-- Quest complete!
		print("Tutorial Quest Complete! Equal distribution: " .. firstCount .. "/" .. firstCount .. "/" .. firstCount)
		if showDialogue and player then
			showDialogue:FireClient(player,
				"Equal groups! Follow the yellow arrows to the exit gate, then press E to enter BrightHaven.",
				"tutorial3_complete",
				"Warehouse Worker",
				"WH"
			)
		end
	else
		-- Unequal distribution – build the ratio string for logging.
		local countStr = ""
		for i, c in ipairs(spotCounts) do
			countStr = countStr .. (i > 1 and "/" or "") .. tostring(c)
		end
		print("Unequal distribution: " .. countStr .. " – Resetting crates to spawn area!")

		-- Throw every crate that's on a spot back to the spawn area.
		for _, obj in ipairs(workspace:GetChildren()) do
			if obj:IsA("BasePart") and obj:GetAttribute("TutorialCrate") and isCrateOnAnySpot(obj, spots) then
				local randomX = math.random(-spawnMarker.Size.X / 2, spawnMarker.Size.X / 2)
				local randomZ = math.random(-spawnMarker.Size.Z / 2, spawnMarker.Size.Z / 2)
				obj.Anchored = true
				obj.Position = Vector3.new(
					spawnMarker.Position.X + randomX,
					spawnMarker.Position.Y + (obj.Size.Y / 2),
					spawnMarker.Position.Z + randomZ
				)
			end
		end

		-- Tell the player to try again.
		if showDialogue and player then
			showDialogue:FireClient(player,
				"The stacks were different. Try placing the same chunk on every floor spot.",
				"tutorial3_failed",
				"Warehouse Worker",
				"WH"
			)
		end
	end
end

return module
