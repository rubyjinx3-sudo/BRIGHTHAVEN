-- ServerScriptService/SpawnOnPlay
-- Players are only spawned after their local loading screen requests it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Care=require(game.ServerScriptService.Brighthaven.SurvivalService)

Players.CharacterAutoLoads = false

local playRequested = Instance.new("RemoteEvent")
playRequested.Name = "PlayRequested"
playRequested.Parent = ReplicatedStorage

local function setupRespawn(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	task.spawn(Care.RecoverAtClinic,player,character)

	humanoid.Died:Connect(function()
		Care.RecordCollapse(player,character)
		task.wait(Players.RespawnTime)
		if player and player.Parent and player.Character==character then
			player:LoadCharacter()
		end
	end)
end

playRequested.OnServerEvent:Connect(function(player)
	if player:GetAttribute("HasStartedGame") then
		return
	end

	player:SetAttribute("HasStartedGame", true)
	player:LoadCharacter()
end)

-- Auto-respawn when a character dies (handles reset and natural death)
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		setupRespawn(player, character)
	end)
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		setupRespawn(player, character)
	end)
end

