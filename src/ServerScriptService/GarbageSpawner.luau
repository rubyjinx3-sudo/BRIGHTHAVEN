local garbageTemplate = game.ReplicatedStorage:WaitForChild("Garbage")
local area = workspace:WaitForChild("GarbageArea")
local remaining = workspace:WaitForChild("GarbageRemaining")

local TOTAL_GARBAGE = 20

return function()

	remaining.Value = TOTAL_GARBAGE

	-- clear old garbage
	for _, obj in pairs(workspace:GetChildren()) do
		if obj.Name == "Garbage" then
			obj:Destroy()
		end
	end

	-- spawn new garbage
	for i = 1, TOTAL_GARBAGE do
		local garbage = garbageTemplate:Clone()

		local randomX = math.random(-area.Size.X / 2, area.Size.X / 2)
		local randomZ = math.random(-area.Size.Z / 2, area.Size.Z / 2)

		garbage.Position = area.Position + Vector3.new(randomX, 2, randomZ)
		garbage.Parent = workspace
	end
end

