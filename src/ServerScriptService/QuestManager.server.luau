local ReplicatedStorage = game:GetService("ReplicatedStorage")

local crateTemplate = ReplicatedStorage:WaitForChild("Crate")

game.ReplicatedStorage:WaitForChild("StartQuest").OnServerEvent:Connect(function(player)
	local spawnMarker=workspace:FindFirstChild("SpawnMarker")
	if not spawnMarker or not spawnMarker:IsA("BasePart") then return end
	print("Quest Started!")

	-- Remove old crates (optional)
	for _, obj in ipairs(workspace:GetChildren()) do
		if obj.Name == crateTemplate.Name then
			obj:Destroy()
		end
	end

	for i = 1, 15 do
		local newCrate = crateTemplate:Clone()

		-- Random position inside the SpawnMarker
		local randomX = math.random(-spawnMarker.Size.X / 2, spawnMarker.Size.X / 2)
		local randomZ = math.random(-spawnMarker.Size.Z / 2, spawnMarker.Size.Z / 2)

		local worldX = spawnMarker.Position.X + randomX
		local worldZ = spawnMarker.Position.Z + randomZ

		newCrate.Parent = workspace
		newCrate.Anchored = true

		-- Spawn directly on the SpawnMarker's height
		newCrate.Position = Vector3.new(
			worldX,
			spawnMarker.Position.Y + (newCrate.Size.Y / 2),
			worldZ
		)
	end
end)
