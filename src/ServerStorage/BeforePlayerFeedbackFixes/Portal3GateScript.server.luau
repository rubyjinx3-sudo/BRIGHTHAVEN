local portal_name = "Portal4"
local portal = script.Parent.Parent.Parent:FindFirstChild(portal_name)

-- Clean up Tutorial 2 arrows from the character
local function cleanupTutorial2Arrows(character)
	for _, descendant in ipairs(character:GetDescendants()) do
		if descendant:IsA("Beam") or descendant:IsA("Attachment") then
			if descendant.Name == "FollowArrow"
				or descendant.Name == "PlayerAttachment"
				or descendant.Name == "PlayerAttachment1"
				or descendant.Name == "PlayerAttachment2"
				or descendant.Name == "BeamAttachment" then
				descendant:Destroy()
			end
		end
	end
end

script.Parent.Touched:Connect(function(hit)
	local character = hit.Parent
	local player = game.Players:GetPlayerFromCharacter(character)

	if player then
		cleanupTutorial2Arrows(character)

		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		humanoidRootPart.CFrame = CFrame.new(
			portal.Teleport.Position.X - 5,
			portal.Teleport.Position.Y,
			portal.Teleport.Position.Z
		)

		-- Trigger Tutorial 3 arrows
		game.ServerStorage.StartTutorial3Arrow:Fire(player)
	end
end)