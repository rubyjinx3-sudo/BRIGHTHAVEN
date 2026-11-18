local Players = game:GetService("Players")
local Practice = require(game.ReplicatedStorage.Brighthaven.TutorialPractice)

local logsFolder = script.Parent

local MAX_DEATHS = 3
local deathCounts = {}

local originalPositions = {}


-- Save the original position of every log
for _, object in ipairs(logsFolder:GetDescendants()) do

	if object:IsA("BasePart") then

		originalPositions[object] = object.CFrame

		print("Saved original position of:", object.Name)

	end

end


print("Tutorial 2 Manager started")
print("Total logs saved:", #logsFolder:GetDescendants())


local function resetLogs(player)

	print("================================")
	print("3 DEATHS REACHED")
	print("RESETTING LOGS")
	print("================================")

	-- Signal all log scripts to cancel tweens and reset positions
	local resetCount = logsFolder:GetAttribute("ResetCount") or 0
	logsFolder:SetAttribute("ResetCount", resetCount + 1)

	deathCounts[player] = 0

	print("================================")
	print("RESET COMPLETE")
	print("Deaths:", "0/" .. MAX_DEATHS)
	print("================================")

end


local function playerDied(player)
	if player:GetAttribute("Tutorial2Practice")~="active" or Practice.PlayerStage(player)~=2 then return end

	deathCounts[player]=(deathCounts[player] or 0)+1
	local deaths=deathCounts[player]

	print("Player died!")
	print("Deaths:", deaths .. "/" .. MAX_DEATHS)

	if deaths >= MAX_DEATHS then

		resetLogs(player)

	end

end


local function setupCharacter(player,character)

	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()

		playerDied(player)

	end)

end


local function setupPlayer(player)

	player.CharacterAdded:Connect(function(character)

		setupCharacter(player,character)

	end)

	if player.Character then

		setupCharacter(player,player.Character)

	end

end


Players.PlayerAdded:Connect(function(player)

	setupPlayer(player)

end)

Players.PlayerRemoving:Connect(function(player) deathCounts[player]=nil end)


for _, player in ipairs(Players:GetPlayers()) do

	setupPlayer(player)

end
