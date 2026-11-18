local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local startGarbageQuest = ReplicatedStorage:WaitForChild("StartGarbageQuest")
local garbageSpawner = require(ServerScriptService:WaitForChild("GarbageSpawner"))

local questStarted = false

startGarbageQuest.OnServerEvent:Connect(function(player)
	if questStarted then
		return
	end

	questStarted = true
	print(player.Name .. " started the garbage quest!")

	garbageSpawner()
end)