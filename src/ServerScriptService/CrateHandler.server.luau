local SnapEvent = game.ReplicatedStorage:WaitForChild("SnapCrate")

SnapEvent.OnServerEvent:Connect(function(player, action, data)
	local character = player.Character
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if action == "PickUp" then
		local crate = data
		-- Move it to the hand/front of player
		crate.CFrame = rootPart.CFrame * CFrame.new(0, 0, -2)
		crate.Anchored = false

		local weld = Instance.new("WeldConstraint")
		weld.Name = "CrateWeld"
		weld.Part0 = crate
		weld.Part1 = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
		weld.Parent = crate

	elseif action == "Snap" then
		local spot = data
		-- Find the crate attached to the player
		for _, obj in pairs(character:GetDescendants()) do
			if obj:IsA("WeldConstraint") and obj.Name == "CrateWeld" then
				local crate = obj.Part0
				obj:Destroy() -- Detach
				crate.CFrame = spot.CFrame + Vector3.new(0, 3, 0)
				crate.Anchored = true
				print("Snapped!")
				break
			end
		end
	end
end)
