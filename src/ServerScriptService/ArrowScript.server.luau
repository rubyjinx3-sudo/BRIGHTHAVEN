local Players = game:GetService("Players")


--------------------------------------------------
-- CREATE FOLLOW ARROW
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

	beam.Color = ColorSequence.new(
		Color3.fromRGB(255, 255, 255)
	)

	beam.Parent = parent

	return beam
end


--------------------------------------------------
-- PLAYER JOINED
--------------------------------------------------

Players.PlayerAdded:Connect(function(player)

	player.CharacterAdded:Connect(function(character)

		local hrp =
			character:WaitForChild("HumanoidRootPart")


		--------------------------------------------------
		-- TUTORIAL FOLDER
		--------------------------------------------------

		local tutorialFolder =
			workspace
			:WaitForChild("Possible Map Replacement")
			:WaitForChild("Tutorial")
			:WaitForChild("Tutorial_1")


		--------------------------------------------------
		-- NPC SETUP
		--------------------------------------------------

		local npc =
			tutorialFolder:WaitForChild("TutorialNPC1")

		local npcHrp =
			npc:WaitForChild("HumanoidRootPart")

		local npcPrompt =
			npcHrp:WaitForChild("ProximityPrompt")


		--------------------------------------------------
		-- SUPPLY BOX SETUP
		--------------------------------------------------

		local supplyBox =
			tutorialFolder:WaitForChild("SupplyBox")

		local supplyPrompt =
			supplyBox:WaitForChild("ProximityPrompt")


		--------------------------------------------------
		-- ARROW VARIABLES
		--------------------------------------------------

		local beam1 = nil
		local beam2 = nil

		local playerAttachment1 = nil
		local playerAttachment2 = nil


		--------------------------------------------------
		-- NPC ATTACHMENT
		--------------------------------------------------

		local npcAttachment =
			npcHrp:FindFirstChild("BeamAttachment")

		if not npcAttachment then

			npcAttachment =
				Instance.new("Attachment")

			npcAttachment.Name =
				"BeamAttachment"

			npcAttachment.Parent =
				npcHrp

		end


		--------------------------------------------------
		-- ARROW 1
		-- PLAYER → NPC
		--------------------------------------------------

		playerAttachment1 =
			Instance.new("Attachment")

		playerAttachment1.Name =
			"PlayerAttachment1"

		playerAttachment1.Position =
			Vector3.new(0, 2, 0)

		playerAttachment1.Parent =
			hrp


		beam1 =
			createBeam(
				npcAttachment,
				playerAttachment1,
				character
			)


		--------------------------------------------------
		-- NPC INTERACTION
		--------------------------------------------------

		npcPrompt.Triggered:Connect(function(triggeringPlayer)

			if triggeringPlayer ~= player then
				return
			end


			--------------------------------------------------
			-- REMOVE PLAYER → NPC ARROW
			--------------------------------------------------

			if beam1 then

				beam1:Destroy()
				beam1 = nil

			end


			if playerAttachment1 then

				playerAttachment1:Destroy()
				playerAttachment1 = nil

			end


			--------------------------------------------------
			-- SUPPLY BOX ATTACHMENT
			--------------------------------------------------

			local boxAttachment =
				supplyBox:FindFirstChild("BeamAttachment")

			if not boxAttachment then

				boxAttachment =
					Instance.new("Attachment")

				boxAttachment.Name =
					"BeamAttachment"

				boxAttachment.Parent =
					supplyBox

			end


			--------------------------------------------------
			-- PLAYER ATTACHMENT 2
			--------------------------------------------------

			playerAttachment2 =
				Instance.new("Attachment")

			playerAttachment2.Name =
				"PlayerAttachment2"

			playerAttachment2.Position =
				Vector3.new(0, 2, 0)

			playerAttachment2.Parent =
				hrp


			--------------------------------------------------
			-- ARROW 2
			-- PLAYER → SUPPLY BOX
			--------------------------------------------------

			beam2 =
				createBeam(
					boxAttachment,
					playerAttachment2,
					character
				)

		end)


		--------------------------------------------------
		-- SUPPLY BOX INTERACTION
		--------------------------------------------------

		supplyPrompt.Triggered:Connect(function(triggeringPlayer)

			if triggeringPlayer ~= player then
				return
			end


			--------------------------------------------------
			-- REMOVE PLAYER → SUPPLY BOX ARROW
			--------------------------------------------------

			if beam2 then

				beam2:Destroy()
				beam2 = nil

			end


			if playerAttachment2 then

				playerAttachment2:Destroy()
				playerAttachment2 = nil

			end

			--------------------------------------------------
			-- STOP HERE
			--
			-- DO NOT CREATE TORCH ARROW HERE.
			--
			-- Tutorial1ServerController will create
			-- the torch guide ONLY after Tutorial 1
			-- is actually completed.
			--------------------------------------------------

		end)

	end)

end)