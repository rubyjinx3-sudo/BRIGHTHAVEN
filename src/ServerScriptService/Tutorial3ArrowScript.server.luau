--------------------------------------------------
-- TUTORIAL 3 FOLLOW ARROW
--------------------------------------------------

local function createBeam(attachment0, attachment1, parent)
	local beam = Instance.new("Beam")
	beam.Name = "FollowArrow"
	beam.Attachment0 = attachment0
	beam.Attachment1 = attachment1
	beam.Width0 = 1
	beam.Width1 = 1
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Texture = "rbxassetid://10249261576"
	beam.TextureLength = 5
	beam.TextureSpeed = 1
	beam.Transparency = NumberSequence.new(0)
	beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
	beam.Parent = parent
	return beam
end

local function cleanupArrow(beam, attachment)
	if beam then beam:Destroy() end
	if attachment then attachment:Destroy() end
end

--------------------------------------------------
-- LISTEN FOR PORTAL3 TELEPORT SIGNAL
--------------------------------------------------

local startEvent = game.ServerStorage:WaitForChild("StartTutorial3Arrow")

startEvent.Event:Connect(function(player)
	local character = player.Character
	if not character then return end

	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end

	-- Tutorial 3 objects
	local tutorial3 = workspace
		:WaitForChild("Possible Map Replacement")
		:WaitForChild("Tutorial")
		:WaitForChild("Tutorial_3")

	local warehouse = tutorial3:WaitForChild("WarehouseTutorial")
	local npc = warehouse:WaitForChild("WarehouseNPCTutorial")
	local npcHrp = npc:WaitForChild("HumanoidRootPart")
	local npcPrompt = npcHrp:WaitForChild("ProximityPrompt")

	local crateSpawnMarker = workspace:WaitForChild("SpawnMarkerTutorial")

	-- Arrow variables
	local beam1 = nil
	local playerAttachment1 = nil

	-- NPC attachment
	local npcAttachment = npcHrp:FindFirstChild("BeamAttachment")
	if not npcAttachment then
		npcAttachment = Instance.new("Attachment")
		npcAttachment.Name = "BeamAttachment"
		npcAttachment.Parent = npcHrp
	end

	-- ARROW 1: Player -> WarehouseNPCTutorial
	playerAttachment1 = Instance.new("Attachment")
	playerAttachment1.Name = "PlayerAttachment1"
	playerAttachment1.Position = Vector3.new(0, 2, 0)
	playerAttachment1.Parent = hrp

	beam1 = createBeam(npcAttachment, playerAttachment1, character)
	
	-- After crate pickup -> switch arrow to QuestSpotsTutorial
	local questSpots = tutorial3:WaitForChild("QuestSpotsTutorial")
	local questSpot1 = questSpots:FindFirstChild("QuestSpot")
	if questSpot1 then
		local questAttachment = questSpot1:FindFirstChild("BeamAttachment")
		if not questAttachment then
			questAttachment = Instance.new("Attachment")
			questAttachment.Name = "BeamAttachment"
			questAttachment.Parent = questSpot1
		end

		character.ChildAdded:Connect(function(child)
			if child:IsA("BasePart") and child.Name == "Crate" then
				-- Remove arrow to crate spawn area
				cleanupArrow(beam1, playerAttachment1)
				beam1 = nil
				playerAttachment1 = nil

				-- ARROW 3: Player -> QuestSpotsTutorial
				playerAttachment1 = Instance.new("Attachment")
				playerAttachment1.Name = "PlayerAttachment3"
				playerAttachment1.Position = Vector3.new(0, 2, 0)
				playerAttachment1.Parent = hrp

				beam1 = createBeam(questAttachment, playerAttachment1, character)
				
				-- When crate is deposited -> remove arrow
				character.ChildRemoved:Connect(function(child)
					if child:IsA("BasePart") and child.Name == "Crate" then
						cleanupArrow(beam1, playerAttachment1)
						beam1 = nil
						playerAttachment1 = nil
					end
				end)
				
			end
		end)
	end

	-- NPC INTERACTION -> switch arrow to crate spawn area
	npcPrompt.Triggered:Connect(function(triggeringPlayer)
		if triggeringPlayer ~= player then return end

		-- Remove Player -> NPC arrow
		cleanupArrow(beam1, playerAttachment1)
		beam1 = nil
		playerAttachment1 = nil

		-- Crate spawn marker attachment
		local crateAttachment = crateSpawnMarker:FindFirstChild("BeamAttachment")
		if not crateAttachment then
			crateAttachment = Instance.new("Attachment")
			crateAttachment.Name = "BeamAttachment"
			crateAttachment.Parent = crateSpawnMarker
		end

		-- ARROW 2: Player -> Crate spawn area
		playerAttachment1 = Instance.new("Attachment")
		playerAttachment1.Name = "PlayerAttachment2"
		playerAttachment1.Position = Vector3.new(0, 2, 0)
		playerAttachment1.Parent = hrp

		beam1 = createBeam(crateAttachment, playerAttachment1, character)
	end)
end)