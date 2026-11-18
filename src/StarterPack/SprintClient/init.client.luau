local userInputService = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local playersService = game:GetService("Players")
local SprintSettings = require(script.SprintSettings)

local sprintEvent = replicatedStorage:WaitForChild("SprintEvent")
local player = playersService.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera
local sprintAnim = script:WaitForChild("SprintAnim")
local sprintTrack = humanoid:LoadAnimation(sprintAnim)

local sprinting = false

script.SprintSettings:Destroy() -- Destroying SprintSettings to make it exploiter proof

function tweenFov(duration, fov)
	if not SprintSettings.EnableFOVChanging then return end
	local tween = tweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Quad), { FieldOfView = fov })
	tween:Play()
	tween.Completed:Wait()
	tween:Destroy()
end

function toggleSprint(enable)
	sprinting = enable

	if enable then
		if humanoid.MoveDirection.Magnitude > 0 and not sprintTrack.IsPlaying then
			sprintTrack:Play(0.25)
		end
		sprintEvent:FireServer(SprintSettings.SprintSpeed)
		tweenFov(0.35, SprintSettings.SprintFov)
	else
		if sprintTrack.IsPlaying then
			sprintTrack:Stop()
		end
		sprintEvent:FireServer(SprintSettings.DefaultSpeed)
		tweenFov(0.35, SprintSettings.NormalFov)
	end
end

userInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.KeyCode == SprintSettings.SprintKey or input.KeyCode == SprintSettings.SprintButton) then
		toggleSprint(not sprinting)
	end
end)

userInputService.InputEnded:Connect(function(input)
	if input.KeyCode == SprintSettings.SprintKey then
		toggleSprint(false)
	end
end)

humanoid:GetPropertyChangedSignal("FloorMaterial"):Connect(function()
	if not SprintSettings.FallStopsSprinting then return end
	
	if humanoid.FloorMaterial == Enum.Material.Air and sprinting then
		toggleSprint(false)
	elseif humanoid.FloorMaterial ~= Enum.Material.Air and sprinting and humanoid.MoveDirection.Magnitude > 0 and not sprintTrack.IsPlaying then
		sprintTrack:Play(0.25)
	end
end)

humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
	if humanoid.MoveDirection.Magnitude > 0 and sprinting and not sprintTrack.IsPlaying then
		sprintTrack:Play(0.25)
	elseif humanoid.MoveDirection.Magnitude == 0 and sprintTrack.IsPlaying then
		sprintTrack:Stop()
	end
end)
