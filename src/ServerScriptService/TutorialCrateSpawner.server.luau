-- ServerScriptService/TutorialCrateSpawner
-- Spawns crates at the WarehouseTutorial, separate from the regular warehouse quest.
-- Logic adapted from ServerScriptService.QuestManager but targets the tutorial warehouse.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local crateTemplate = ReplicatedStorage:WaitForChild("Crate")
local tutorialSpawnMarker = workspace:FindFirstChild("SpawnMarkerTutorial")

local StartTutorialQuest = ReplicatedStorage:WaitForChild("StartTutorialQuest")

local TOTAL_CRATES = 15
local cratesSpawned = false

-- Find the NPC ProximityPrompt
local function getNPCPrompt()
	local mapReplacement = workspace:FindFirstChild("Possible Map Replacement")
	if not mapReplacement then return nil end
	local tutorial = mapReplacement:FindFirstChild("Tutorial")
	if not tutorial then return nil end
	local tutorial3 = tutorial:FindFirstChild("Tutorial_3")
	if not tutorial3 then return nil end
	local warehouse = tutorial3:FindFirstChild("WarehouseTutorial")
	if not warehouse then return nil end
	local npc = warehouse:FindFirstChild("WarehouseNPCTutorial")
	if not npc then return nil end
	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root then return nil end
	return root:FindFirstChildOfClass("ProximityPrompt")
end

StartTutorialQuest.OnServerEvent:Connect(function(player)
	local prompt = getNPCPrompt()
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or not prompt or (root.Position-prompt.Parent.Position).Magnitude>18 then return end
	print("Tutorial Quest Started!")

	-- Prevent double-spawning if crates already exist
	if cratesSpawned then
		print("Tutorial crates already spawned – ignoring duplicate request.")
		return
	end

	if not tutorialSpawnMarker then
		warn("TutorialCrateSpawnMarker not found in WarehouseTutorial!")
		return
	end

	-- Remove old crates that are within the tutorial spawn area (only tutorial crates)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj:IsA("BasePart") and obj.Name == crateTemplate.Name then
			local flatDist = (Vector3.new(obj.Position.X, 0, obj.Position.Z)
				- Vector3.new(tutorialSpawnMarker.Position.X, 0, tutorialSpawnMarker.Position.Z)).Magnitude
			-- Only remove crates that are within the tutorial warehouse area
			if flatDist < (tutorialSpawnMarker.Size.X / 2) then
				obj:Destroy()
			end
		end
	end

	-- Spawn new crates inside the TutorialCrateSpawnMarker
	for i = 1, TOTAL_CRATES do
		local newCrate = crateTemplate:Clone()
		newCrate:SetAttribute("TutorialCrate",true)

		local randomX = math.random(-tutorialSpawnMarker.Size.X / 2, tutorialSpawnMarker.Size.X / 2)
		local randomZ = math.random(-tutorialSpawnMarker.Size.Z / 2, tutorialSpawnMarker.Size.Z / 2)

		local worldX = tutorialSpawnMarker.Position.X + randomX
		local worldZ = tutorialSpawnMarker.Position.Z + randomZ

		newCrate.Parent = workspace
		newCrate.Anchored = true

		-- Spawn directly on the spawn marker's height
		newCrate.Position = Vector3.new(
			worldX,
			tutorialSpawnMarker.Position.Y + (newCrate.Size.Y / 2),
			worldZ
		)
	end

	-- Mark as spawned and disable the NPC prompt so it can't be triggered again
	cratesSpawned = true
	player:SetAttribute("Tutorial3Practice","active")
	local prompt = getNPCPrompt()
	if prompt then
		prompt.Enabled = false
		print("NPC prompt disabled after crate spawn.")
	else
		warn("Could not find NPC ProximityPrompt to disable!")
	end
end)
