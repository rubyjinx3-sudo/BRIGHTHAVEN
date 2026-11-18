local ReplicatedStorage = game:GetService("ReplicatedStorage")
local weatherEvent = ReplicatedStorage:WaitForChild("WeatherEvent")

-- Keep your existing module requirement
local Rain = require(script.Rain)

-- APPLY CONFIGURATION (Do this once at start)
Rain:SetColor(Color3.fromRGB(script.Color.Value.x, script.Color.Value.y, script.Color.Value.z))
Rain:SetDirection(script.Direction.Value)
Rain:SetTransparency(script.Transparency.Value)
Rain:SetSpeedRatio(script.SpeedRatio.Value)
Rain:SetIntensityRatio(script.IntensityRatio.Value)
Rain:SetLightInfluence(script.LightInfluence.Value)
Rain:SetLightEmission(script.LightEmission.Value)
Rain:SetVolume(script.Volume.Value)
Rain:SetSoundId(script.SoundId.Value)
Rain:SetStraightTexture(script.StraightTexture.Value)
Rain:SetTopDownTexture(script.TopDownTexture.Value)
Rain:SetSplashTexture(script.SplashTexture.Value)

-- Collision Logic from your original script
local threshold = script.TransparencyThreshold.Value
if script.TransparencyConstraint.Value and script.CanCollideConstraint.Value then
	Rain:SetCollisionMode(
		Rain.CollisionMode.Function,
		function(p)
			return p.Transparency <= threshold and p.CanCollide
		end
	)
elseif script.TransparencyConstraint.Value then
	Rain:SetCollisionMode(
		Rain.CollisionMode.Function,
		function(p)
			return p.Transparency <= threshold
		end
	)
elseif script.CanCollideConstraint.Value then
	Rain:SetCollisionMode(
		Rain.CollisionMode.Function,
		function(p)
			return p.CanCollide
		end
	)
end

-- LISTEN FOR SERVER COMMANDS
local function setRain(isNight)
	if isNight then
		print("Client: Enabling Rain")
		Rain:Enable()
	else
		print("Client: Disabling Rain")
		Rain:Disable()
	end
end

weatherEvent.OnClientEvent:Connect(setRain)
-- New players see the current weather without waiting for the next long phase.
local isNight = ReplicatedStorage:GetAttribute("BrightHavenIsNight")
if isNight == nil then
    local clockTime = game:GetService("Lighting").ClockTime
    isNight = clockTime >= 18 or clockTime < 6
end
setRain(isNight)
