local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

local Settings = require(ReplicatedStorage:WaitForChild("Brighthaven"):WaitForChild("Settings"))
local town = workspace:WaitForChild("BrighthavenPrototype")

local DAY_DURATION = Settings.DayDurationSeconds
local START_CLOCK = 6
local END_CLOCK = 18

local function ensureEffect(className, name)
    local effect = Lighting:FindFirstChild(name)
    if not effect then
        effect = Instance.new(className)
        effect.Name = name
        effect.Parent = Lighting
    end
    return effect
end

local atmosphere = ensureEffect("Atmosphere", "BrighthavenGloom")
atmosphere.Density = 0.30
atmosphere.Offset = 0.10
atmosphere.Color = Color3.fromRGB(154, 166, 165)
atmosphere.Decay = Color3.fromRGB(96, 106, 110)
atmosphere.Glare = 0.05
atmosphere.Haze = 1.45

local color = ensureEffect("ColorCorrectionEffect", "BrighthavenColdGrade")
color.Brightness = -0.03
color.Contrast = 0.10
color.Saturation = -0.16
color.TintColor = Color3.fromRGB(214, 224, 224)

local bloom = ensureEffect("BloomEffect", "BrighthavenLampBloom")
bloom.Intensity = 0.22
bloom.Size = 18
bloom.Threshold = 1.2

local clouds
if Terrain then
    clouds = Terrain:FindFirstChild("BrighthavenLowClouds")
    if not clouds then
        clouds = Instance.new("Clouds")
        clouds.Name = "BrighthavenLowClouds"
        clouds.Parent = Terrain
    end
    clouds.Cover = 0.72
    clouds.Density = 0.42
    clouds.Color = Color3.fromRGB(130, 140, 142)
end

local weather = town:FindFirstChild("WeatherSystem")
if not weather then
    weather = Instance.new("Folder")
    weather.Name = "WeatherSystem"
    weather.Parent = town
end

local rainPart = weather:FindFirstChild("RainEmitter")
if not rainPart or not rainPart:IsA("BasePart") then
    if rainPart then rainPart:Destroy() end
    rainPart = Instance.new("Part")
    rainPart.Name = "RainEmitter"
    rainPart.Parent = weather
end
rainPart.Anchored = true
rainPart.CanCollide = false
rainPart.CanQuery = false
rainPart.Transparency = 1
rainPart.Size = Vector3.new(520, 1, 410)
rainPart.CFrame = CFrame.new(0, 90, 0)

local rain = rainPart:FindFirstChild("LightRain")
if not rain then
    rain = Instance.new("ParticleEmitter")
    rain.Name = "LightRain"
    rain.Parent = rainPart
end
rain.Enabled = true
rain.Rate = 185
rain.Lifetime = NumberRange.new(1.5, 2.0)
rain.Speed = NumberRange.new(44, 58)
rain.Acceleration = Vector3.new(3, -78, 0)
rain.SpreadAngle = Vector2.new(8, 8)
rain.EmissionDirection = Enum.NormalId.Bottom
rain.LightEmission = 0.08
rain.LightInfluence = 0.75
rain.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.18),
    NumberSequenceKeypoint.new(0.85, 0.46),
    NumberSequenceKeypoint.new(1, 1),
})
rain.Size = NumberSequence.new(0.09)
rain.Color = ColorSequence.new(Color3.fromRGB(185, 205, 212))

local mist = rainPart:FindFirstChild("GroundMist")
if not mist then
    mist = Instance.new("ParticleEmitter")
    mist.Name = "GroundMist"
    mist.Parent = rainPart
end
mist.Enabled = true
mist.Rate = 12
mist.Lifetime = NumberRange.new(4, 7)
mist.Speed = NumberRange.new(1, 3)
mist.Acceleration = Vector3.new(0, -6, 0)
mist.SpreadAngle = Vector2.new(45, 45)
mist.EmissionDirection = Enum.NormalId.Bottom
mist.LightEmission = 0
mist.LightInfluence = 1
mist.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.88),
    NumberSequenceKeypoint.new(0.55, 0.76),
    NumberSequenceKeypoint.new(1, 1),
})
mist.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 5),
    NumberSequenceKeypoint.new(1, 11),
})
mist.Color = ColorSequence.new(Color3.fromRGB(103, 118, 123))

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function lerpColor(a, b, t)
    return Color3.new(lerp(a.R, b.R, t), lerp(a.G, b.G, t), lerp(a.B, b.B, t))
end

local presets = {
    dawn = {
        ambient = Color3.fromRGB(72, 82, 86),
        outdoor = Color3.fromRGB(86, 96, 100),
        brightness = 0.85,
        fogEnd = 360,
        fogColor = Color3.fromRGB(116, 128, 130),
    },
    day = {
        ambient = Color3.fromRGB(86, 96, 99),
        outdoor = Color3.fromRGB(104, 114, 116),
        brightness = 1.05,
        fogEnd = 520,
        fogColor = Color3.fromRGB(140, 151, 151),
    },
    dusk = {
        ambient = Color3.fromRGB(52, 60, 68),
        outdoor = Color3.fromRGB(62, 72, 82),
        brightness = 0.55,
        fogEnd = 290,
        fogColor = Color3.fromRGB(82, 92, 104),
    },
    night = {
        ambient = Color3.fromRGB(24, 29, 36),
        outdoor = Color3.fromRGB(30, 36, 45),
        brightness = 0.25,
        fogEnd = 165,
        fogColor = Color3.fromRGB(35, 42, 50),
    },
}

local function blendedPreset(progress)
    if progress < 0.12 then
        return presets.dawn, presets.day, progress / 0.12
    elseif progress < 0.70 then
        return presets.day, presets.day, 0
    elseif progress < 0.88 then
        return presets.day, presets.dusk, (progress - 0.70) / 0.18
    else
        return presets.dusk, presets.night, (progress - 0.88) / 0.12
    end
end

while true do
    local elapsed = os.clock() % DAY_DURATION
    local progress = elapsed / DAY_DURATION
    local fromPreset, toPreset, t = blendedPreset(progress)

    Lighting.ClockTime = START_CLOCK + progress * (END_CLOCK - START_CLOCK)
    Lighting.Ambient = lerpColor(fromPreset.ambient, toPreset.ambient, t)
    Lighting.OutdoorAmbient = lerpColor(fromPreset.outdoor, toPreset.outdoor, t)
    Lighting.Brightness = lerp(fromPreset.brightness, toPreset.brightness, t)
    Lighting.FogEnd = lerp(fromPreset.fogEnd, toPreset.fogEnd, t)
    Lighting.FogColor = lerpColor(fromPreset.fogColor, toPreset.fogColor, t)

    rain.Rate = 185
    mist.Rate = 12

    task.wait(1)
end
