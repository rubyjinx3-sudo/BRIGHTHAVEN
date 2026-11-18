local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Clone the loading screen to PlayerGui so it's visible on screen
local loadingTemplate = ReplicatedFirst:WaitForChild("LoadingScreen")
local loadingScreen = loadingTemplate:Clone()
loadingScreen.Parent = playerGui

-- Wait for the rest of the game to load
if not game:IsLoaded() then
	game.Loaded:Wait()
end

-- Small delay so the image is visible even on fast loads
task.wait(2)

-- Fade out the loading screen
local coverImage = loadingScreen:FindFirstChild("CoverImage")
if coverImage then
	for i = 1, 10 do
		coverImage.ImageTransparency = i / 10
		task.wait(0.05)
	end
end

-- Remove the loading screen
loadingScreen:Destroy()