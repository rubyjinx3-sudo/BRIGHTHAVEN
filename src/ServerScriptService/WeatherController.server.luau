
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local town = workspace:FindFirstChild("DivisionTown")
if not town then return end

local weather = town:FindFirstChild("WeatherSystem")
local rainParticles = weather and weather:FindFirstChild("RainEmitter") and weather.RainEmitter:FindFirstChild("LightRain")
local rainSound = weather and weather:FindFirstChild("RainAmbient")
local thunderSound = weather and weather:FindFirstChild("DistantThunder")


local DAY_DURATION = 720
local DAWN_START = 6
local DUSK_END = 18


local PRESETS = {
	dawn  = { ambient = Color3.fromRGB(55, 55, 65), outdoor = Color3.fromRGB(60, 62, 72), brightness = 0.7, fogEnd = 280 },
	day   = { ambient = Color3.fromRGB(50, 52, 60), outdoor = Color3.fromRGB(55, 58, 68), brightness = 0.6, fogEnd = 250 },
	dusk  = { ambient = Color3.fromRGB(40, 42, 52), outdoor = Color3.fromRGB(45, 47, 58), brightness = 0.4, fogEnd = 200 },
	night = { ambient = Color3.fromRGB(30, 32, 42), outdoor = Color3.fromRGB(35, 37, 48), brightness = 0.25, fogEnd = 180 },
}

local function lerpColor(a, b, t)
	return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
end

local function lerpNum(a, b, t)
	return a + (b - a) * t
end


local currentDay = 0
local dayStartTime = tick()


local remotes = ReplicatedStorage:FindFirstChild("DivisionGame") and ReplicatedStorage.DivisionGame:FindFirstChild("Remotes")
local dayRemote = remotes and remotes:FindFirstChild("GetDayInfo")
if not dayRemote then
	dayRemote = Instance.new("RemoteFunction")
	dayRemote.Name = "GetDayInfo"
	dayRemote.Parent = remotes or Instance.new("Folder")
end

dayRemote.OnServerInvoke = function(player)
	local elapsed = tick() - dayStartTime
	local dayProgress = (elapsed % DAY_DURATION) / DAY_DURATION
	return {
		currentDay = currentDay,
		dayProgress = dayProgress,
		timeOfDay = DAWN_START + dayProgress * (DUSK_END - DAWN_START),
		secondsRemaining = DAY_DURATION - (elapsed % DAY_DURATION),
	}
end


if rainSound then
	rainSound:Play()
end


while true do
	local cycleStart = tick()
	local lastTick = cycleStart
	currentDay = currentDay + 1
	dayStartTime = cycleStart


	for _, player in Players:GetPlayers() do
		local feedbackRemote = remotes and remotes:FindFirstChild("FeedbackToClient")
		if feedbackRemote then
			feedbackRemote:FireClient(player, {
				type = "info",
				message = "Day " .. currentDay .. " has begun.",
			})
		end
	end


	while true do
		local now = tick()
		local elapsed = now - cycleStart
		if elapsed >= DAY_DURATION then break end

		local progress = elapsed / DAY_DURATION
		local clockTime = DAWN_START + progress * (DUSK_END - DAWN_START)
		Lighting.ClockTime = clockTime


		local phase, nextPhase, phaseProgress
		if progress < 0.08 then
			phase = PRESETS.dawn
			nextPhase = PRESETS.day
			phaseProgress = progress / 0.08
		elseif progress < 0.75 then
			phase = PRESETS.day
			nextPhase = PRESETS.day
			phaseProgress = 0
		elseif progress < 0.88 then
			phase = PRESETS.day
			nextPhase = PRESETS.dusk
			phaseProgress = (progress - 0.75) / 0.13
		else
			phase = PRESETS.dusk
			nextPhase = PRESETS.night
			phaseProgress = (progress - 0.88) / 0.12
		end

		Lighting.Ambient = lerpColor(phase.ambient, nextPhase.ambient, phaseProgress)
		Lighting.OutdoorAmbient = lerpColor(phase.outdoor, nextPhase.outdoor, phaseProgress)
		Lighting.Brightness = lerpNum(phase.brightness, nextPhase.brightness, phaseProgress)
		Lighting.FogEnd = lerpNum(phase.fogEnd, nextPhase.fogEnd, phaseProgress)


		if rainParticles then
			local baseRate = 100
			local variation = math.sin(elapsed * 0.1) * 20
			rainParticles.Rate = baseRate + variation
		end


		if thunderSound and math.random() < 0.0003 then
			thunderSound.Volume = 0.08 + math.random() * 0.12
			thunderSound:Play()
		end

		task.wait(1)
	end
end


local Lighting = game:GetService("Lighting")
local town = workspace:FindFirstChild("DivisionTown")
if not town then return end

local weather = town:FindFirstChild("WeatherSystem")
if not weather then return end

local rainEmitter = weather:FindFirstChild("RainEmitter")
local rainParticles = rainEmitter and rainEmitter:FindFirstChild("Rain")
local thunderFlash = weather:FindFirstChild("ThunderFlash")
local lightningLight = thunderFlash and thunderFlash:FindFirstChild("LightningLight")
local stormClouds = weather:FindFirstChild("StormClouds")
local rainSound = weather:FindFirstChild("RainSound")
local thunderSound = weather:FindFirstChild("ThunderSound")


local STATE = {
	CLEAR = "clear",
	CLOUDY = "cloudy",
	STORM = "storm",
	FADING = "fading",
}


local MIN_CLEAR_TIME = 60
local MAX_CLEAR_TIME = 120
local MIN_STORM_TIME = 30
local MAX_STORM_TIME = 60
local CLOUDY_TRANSITION = 10
local STORM_BUILDUP = 8
local FADE_DURATION = 12


local CLEAR_LIGHTING = {
	Ambient = Color3.fromRGB(80, 85, 100),
	OutdoorAmbient = Color3.fromRGB(100, 105, 120),
	Brightness = 1.5,
	FogEnd = 600,
	ClockTime = 14.5,
}

local STORM_LIGHTING = {
	Ambient = Color3.fromRGB(40, 42, 55),
	OutdoorAmbient = Color3.fromRGB(50, 52, 65),
	Brightness = 0.5,
	FogEnd = 200,
	ClockTime = 18,
}

local currentState = STATE.CLEAR

local function lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

local function lerpNumber(a, b, t)
	return a + (b - a) * t
end

local function setCloudTransparency(transparency)
	if not stormClouds then return end
	for _, cloud in stormClouds:GetChildren() do
		if cloud:IsA("BasePart") then
			cloud.Transparency = transparency
		end
	end
end

local function setRainRate(rate)
	if rainParticles then
		rainParticles.Rate = rate
	end
end

local function setRainVolume(vol)
	if rainSound then
		rainSound.Volume = vol
	end
end

local function transitionLighting(fromPreset, toPreset, duration)
	local steps = 20
	local interval = duration / steps
	for i = 1, steps do
		local t = i / steps
		Lighting.Ambient = lerpColor(fromPreset.Ambient, toPreset.Ambient, t)
		Lighting.OutdoorAmbient = lerpColor(fromPreset.OutdoorAmbient, toPreset.OutdoorAmbient, t)
		Lighting.Brightness = lerpNumber(fromPreset.Brightness, toPreset.Brightness, t)
		Lighting.FogEnd = lerpNumber(fromPreset.FogEnd, toPreset.FogEnd, t)
		Lighting.ClockTime = lerpNumber(fromPreset.ClockTime, toPreset.ClockTime, t)
		task.wait(interval)
	end
end

local function doLightningStrike()
	if not lightningLight then return end


	local flashes = math.random(1, 3)
	for i = 1, flashes do
		lightningLight.Brightness = math.random(5, 10)
		task.wait(0.05 + math.random() * 0.1)
		lightningLight.Brightness = 0
		task.wait(0.1 + math.random() * 0.15)
		lightningLight.Brightness = math.random(3, 7)
		task.wait(0.05)
		lightningLight.Brightness = 0
		if i < flashes then
			task.wait(0.2 + math.random() * 0.3)
		end
	end


	task.spawn(function()
		task.wait(0.5 + math.random() * 1.5)
		if thunderSound then
			thunderSound.Volume = 0.3 + math.random() * 0.4
			thunderSound:Play()
		end
	end)
end

local function runStorm()
	currentState = STATE.CLOUDY


	setCloudTransparency(0.3)
	task.spawn(transitionLighting, CLEAR_LIGHTING, {
		Ambient = Color3.fromRGB(65, 68, 82),
		OutdoorAmbient = Color3.fromRGB(75, 78, 92),
		Brightness = 1.0,
		FogEnd = 400,
		ClockTime = 16,
	}, CLOUDY_TRANSITION)
	task.wait(CLOUDY_TRANSITION)


	currentState = STATE.STORM
	setCloudTransparency(0.15)
	task.spawn(transitionLighting, {
		Ambient = Color3.fromRGB(65, 68, 82),
		OutdoorAmbient = Color3.fromRGB(75, 78, 92),
		Brightness = 1.0,
		FogEnd = 400,
		ClockTime = 16,
	}, STORM_LIGHTING, STORM_BUILDUP)


	for rate = 0, 400, 20 do
		setRainRate(rate)
		setRainVolume(rate / 400 * 0.6)
		task.wait(0.2)
	end

	if rainSound then rainSound:Play() end


	local stormDuration = MIN_STORM_TIME + math.random() * (MAX_STORM_TIME - MIN_STORM_TIME)
	local stormEnd = tick() + stormDuration
	local nextLightning = tick() + math.random(3, 8)

	while tick() < stormEnd do
		if tick() >= nextLightning then
			task.spawn(doLightningStrike)
			nextLightning = tick() + math.random(5, 15)
		end
		task.wait(0.5)
	end


	currentState = STATE.FADING


	for rate = 400, 0, -20 do
		setRainRate(rate)
		setRainVolume(rate / 400 * 0.6)
		task.wait(0.3)
	end

	if rainSound then
		rainSound.Volume = 0
		rainSound:Stop()
	end


	task.spawn(transitionLighting, STORM_LIGHTING, CLEAR_LIGHTING, FADE_DURATION)

	for t = 0.15, 1, 0.05 do
		setCloudTransparency(t)
		task.wait(FADE_DURATION / 17)
	end
	setCloudTransparency(1)

	currentState = STATE.CLEAR
end


task.spawn(function()
	while true do

		local clearTime = MIN_CLEAR_TIME + math.random() * (MAX_CLEAR_TIME - MIN_CLEAR_TIME)
		task.wait(clearTime)


		task.spawn(runStorm)


		while currentState ~= STATE.CLEAR do
			task.wait(1)
		end
	end
end)