local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local PromptService = game:GetService("ProximityPromptService")
local CAS = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local shared = game.ReplicatedStorage:WaitForChild("Brighthaven")
local Scene = require(shared:WaitForChild("FlashbackScene"))
local request = shared.Remotes:WaitForChild("FlashbackRequest")
local Playback = {}
local playing = false
local yellow, white, ink = Color3.fromRGB(255, 211, 78), Color3.new(1, 1, 1), Color3.fromRGB(48, 52, 55)

local function make(class, properties, parent)
    local object = Instance.new(class)
    for key, value in pairs(properties) do object[key] = value end
    object.Parent = parent
    return object
end
local function invoke(action, token, outcome)
    local ok, result = pcall(function() return request:InvokeServer(action, {Token = token, Outcome = outcome}) end)
    return ok and type(result) == "table" and result.Ok == true
end

function Playback.Play(token)
    if playing or type(token) ~= "string" then return "unavailable" end
    if not invoke("Start", token) then invoke("Finish", token, "abort");return "unavailable" end
    playing = true
    local player = Players.LocalPlayer
    local pg = player:WaitForChild("PlayerGui")
    local camera = workspace.CurrentCamera
    if not camera then invoke("Finish", token, "abort");playing = false;return "abort" end
    local character = player.Character
    local saved = {Frame = camera.CFrame, Type = camera.CameraType, Subject = camera.CameraSubject,
        FOV = camera.FieldOfView, Prompts = PromptService.Enabled, TaxiOpen = pg:GetAttribute("TaxiUIOpen")}
    local connections, hidden, ambient, core, sounds = {}, {}, {}, {}, {}
    local lightState, effects, atmosphereState = {}, {}, {}
    local atmosphere
    local scene, gui, audio, grade, controls, controlsEnabled
    local stopped, outcome, failure = false, "complete", nil
    local function cleanup()
        RunService:UnbindFromRenderStep("BrightHavenFlashbackCamera")
        CAS:UnbindAction("BrightHavenFlashbackInput")
        for _,connection in ipairs(connections) do connection:Disconnect() end
        invoke("Finish", token, outcome)
        if audio then audio:Destroy() end
        if grade then grade:Destroy() end
        for effect, enabled in pairs(effects) do if effect.Parent then effect.Enabled = enabled end end
        for property, value in pairs(lightState) do Lighting[property] = value end
        if atmosphere and atmosphere.Parent then
            for property, value in pairs(atmosphereState) do atmosphere[property] = value end
        end
        if scene then scene:Destroy() end
        if gui then gui:Destroy() end
        for sound, volume in pairs(ambient) do if sound.Parent then sound.Volume = volume end end
        for screen, enabled in pairs(hidden) do if screen.Parent then screen.Enabled = enabled end end
        for enum, enabled in pairs(core) do pcall(function() StarterGui:SetCoreGuiEnabled(enum, enabled) end) end
        PromptService.Enabled = saved.Prompts
        pg:SetAttribute("FlashbackPlaying", nil)
        pg:SetAttribute("TaxiUIOpen", saved.TaxiOpen)
        if camera.Parent then
            camera.FieldOfView = saved.FOV
            local currentHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            camera.CameraSubject = saved.Subject and saved.Subject.Parent and saved.Subject or currentHumanoid
            camera.CameraType = player.Character == character and saved.Type or Enum.CameraType.Custom
            camera.CFrame = saved.Frame
        end
        if controls and controlsEnabled then controls:Enable() end
        playing = false
    end
    local ok, err = xpcall(function()
        pg:SetAttribute("FlashbackPlaying", true)
        pg:SetAttribute("TaxiUIOpen", true)
        PromptService.Enabled = false
        local playerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
        if playerModule then
            controls = require(playerModule):GetControls()
            controlsEnabled = controls.controlsEnabled ~= false
            controls:Disable()
        end
        CAS:BindActionAtPriority("BrightHavenFlashbackInput", function() return Enum.ContextActionResult.Sink end, false, 3000,
            Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space, Enum.KeyCode.LeftShift,
            Enum.KeyCode.E, Enum.KeyCode.M, Enum.KeyCode.B, Enum.KeyCode.Q)
        gui = make("ScreenGui", {Name = "BrightHavenFlashback", IgnoreGuiInset = true, ResetOnSpawn = false,
            DisplayOrder = 200, ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, pg)
        local function suppress(screen)
            if not screen:IsA("ScreenGui") or screen == gui or hidden[screen] ~= nil then return end
            hidden[screen] = screen.Enabled
            screen.Enabled = false
            table.insert(connections, screen:GetPropertyChangedSignal("Enabled"):Connect(function()
                if not stopped and screen.Enabled then screen.Enabled = false end
            end))
        end
        for _,screen in ipairs(pg:GetChildren()) do suppress(screen) end
        table.insert(connections, pg.ChildAdded:Connect(suppress))
        for _,enum in ipairs(Enum.CoreGuiType:GetEnumItems()) do
            if enum ~= Enum.CoreGuiType.All then
                local read, enabled = pcall(function() return StarterGui:GetCoreGuiEnabled(enum) end)
                if read then core[enum] = enabled;pcall(function() StarterGui:SetCoreGuiEnabled(enum, false) end) end
            end
        end
        for _,object in ipairs(game:GetDescendants()) do
            if object:IsA("Sound") and object.IsPlaying then ambient[object] = object.Volume;object.Volume = 0 end
        end
        local band = make("Frame", {Name = "CaptionBand", AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1),
            Size = UDim2.new(1, 0, 0, 126), BackgroundColor3 = white, BorderSizePixel = 0}, gui)
        make("Frame", {Name = "ChapterRibbon", Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = yellow, BorderSizePixel = 0}, band)
        local chapter = make("TextLabel", {Name = "Chapter", Position = UDim2.fromOffset(28, 12), Size = UDim2.new(1, -56, 0, 26),
            BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextSize = 20, TextColor3 = ink, TextXAlignment = Enum.TextXAlignment.Left}, band)
        local caption = make("TextLabel", {Name = "Caption", Position = UDim2.fromOffset(28, 46), Size = UDim2.new(1, -56, 1, -56),
            BackgroundTransparency = 1, TextWrapped = true, Font = Enum.Font.GothamMedium, TextSize = 20, TextColor3 = ink,
            TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, band)
        local skip = make("TextButton", {Name = "Skip", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -24, 0, 60),
            Size = UDim2.fromOffset(108, 42), BackgroundColor3 = yellow, BorderSizePixel = 0, Text = "Skip", Modal = true,
            Font = Enum.Font.FredokaOne, TextSize = 20, TextColor3 = ink}, gui)
        make("UICorner", {CornerRadius = UDim.new(0, 8)}, skip)
        local fade = make("Frame", {Name = "SceneFade", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(),
            BorderSizePixel = 0, ZIndex = 20}, gui)
        fade:SetAttribute("SemanticColor", Color3.new())
        skip.ZIndex = 25
        table.insert(connections, skip.Activated:Connect(function() outcome = "skip";stopped = true end))
        table.insert(connections, player.CharacterRemoving:Connect(function() outcome = "abort";stopped = true end))
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if humanoid then table.insert(connections, humanoid.Died:Connect(function() outcome = "abort";stopped = true end)) end
        local assets = shared:WaitForChild("FlashbackAssets")
        scene = Scene.Create(assets)
        -- Only this player's cinematic changes lighting; the live weather and town stay intact.
        for _,property in ipairs({"ClockTime", "Brightness", "ExposureCompensation", "Ambient", "OutdoorAmbient", "FogColor", "FogStart", "FogEnd"}) do
            lightState[property] = Lighting[property]
        end
        for _,effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effects[effect] = effect.Enabled
                effect.Enabled = false
            end
        end
        atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
        if atmosphere then
            for _,property in ipairs({"Density", "Haze", "Glare", "Color", "Decay", "Offset"}) do atmosphereState[property] = atmosphere[property] end
        end
        grade = make("ColorCorrectionEffect", {Name = "FlashbackGrade", Saturation = -.12, TintColor = Color3.fromRGB(243, 242, 229)}, camera)
        audio = make("SoundGroup", {Name = "BrightHavenFlashbackAudio", Volume = .8}, SoundService)
        local volumes = {Rain = .44, Wind = .30, WoodBreak = .3, Splash = .24, Hammer = .18, Thunder = .17, Footsteps = .22}
        for _,template in ipairs(assets.Sounds:GetChildren()) do
            if template:IsA("Sound") then
                local sound = template:Clone()
                sound.SoundGroup, sound.Volume, sound.Parent = audio, 0, audio
                sound.Looped = sound.Name == "Rain" or sound.Name == "Wind" or sound.Name == "Hammer" or sound.Name == "Thunder" or sound.Name == "Footsteps"
                if sound.Name == "Footsteps" then sound.PlaybackSpeed = 1.35 end
                sounds[sound.Name] = sound
            end
        end
        -- Loading is bounded: unavailable audio cannot strand the player in the cutscene.
        local loaded = false
        task.spawn(function()
            local list = {};for _,sound in pairs(sounds) do table.insert(list, sound) end
            pcall(function() ContentProvider:PreloadAsync(list) end)
            loaded = true
        end)
        local preloadAt = os.clock()
        while not loaded and not stopped and os.clock() - preloadAt < 4 do RunService.Heartbeat:Wait() end
        local function soundCue(name)
            local sound = sounds[name]
            if sound then sound.Volume = volumes[name];sound.TimePosition = 0;sound:Play() end
        end
        sounds.Rain:Play();sounds.Wind:Play()
        if sounds.Thunder then sounds.Thunder:Play() end
        local started, lastTime, lastShot = os.clock(), -1, nil
        local cueTimes = {{11.2, "WoodBreak"}, {12.8, "WoodBreak"}, {14.4, "WoodBreak"}, {25, "Splash"}, {29, "Splash"}, {34, "Splash"}, {51, "Splash"}}
        local function update()
            if stopped then return end
            local time = math.min(os.clock() - started, Scene.Duration)
            local frame, shot, index, fov = scene:Update(time)
            camera.CameraType, camera.FieldOfView, camera.CFrame = Enum.CameraType.Scriptable, fov, frame
            local storm = time >= Scene.StormStart and time < Scene.StormStop
            local warning = time >= Scene.WarningStart and time < Scene.ProposalStart
            Lighting.ClockTime = storm and 17 or warning and 16 or 14
            Lighting.Brightness = storm and 1 or warning and 1.6 or 2
            Lighting.ExposureCompensation = -.15
            Lighting.Ambient = Color3.fromRGB(105, 114, 125)
            Lighting.OutdoorAmbient = storm and Color3.fromRGB(105, 114, 125) or Color3.fromRGB(135, 140, 145)
            Lighting.FogColor = storm and Color3.fromRGB(124, 139, 152) or Color3.fromRGB(190, 212, 224)
            Lighting.FogStart, Lighting.FogEnd = storm and 80 or 200, storm and 260 or 600
            if atmosphere and atmosphere.Parent then
                atmosphere.Density, atmosphere.Haze, atmosphere.Glare = storm and .48 or .25, storm and 2 or .3, 0
                atmosphere.Color = storm and Color3.fromRGB(150, 161, 172) or Color3.fromRGB(205, 220, 235)
                atmosphere.Decay = storm and Color3.fromRGB(124, 135, 146) or Color3.fromRGB(150, 175, 195)
                atmosphere.Offset = 0
            end
            grade.Saturation = storm and -.34 or -.08
            grade.TintColor = storm and Color3.fromRGB(208, 222, 234) or Color3.fromRGB(246, 245, 233)
            grade.Brightness = storm and -.025 or .04
            sounds.Rain.Volume = storm and volumes.Rain or 0
            sounds.Wind.Volume = storm and volumes.Wind or warning and .09 or time < Scene.StormStart and .06 or 0
            if sounds.Thunder then sounds.Thunder.Volume = storm and volumes.Thunder or warning and .055 or 0 end
            if sounds.Footsteps then
                if time >= 15 and time < 26.5 then
                    if not sounds.Footsteps.IsPlaying then soundCue("Footsteps") end
                else sounds.Footsteps:Stop() end
            end
            if time >= Scene.RebuildStart and time < Scene.RebuildStop and not sounds.Hammer.IsPlaying then soundCue("Hammer") end
            if time >= Scene.RebuildStop then sounds.Hammer:Stop() end
            for _,cue in ipairs(cueTimes) do if lastTime < cue[1] and time >= cue[1] then soundCue(cue[2]) end end
            if index ~= lastShot then
                lastShot = index
                chapter.Text, caption.Text = shot.Title, shot.Caption
                gui:SetAttribute("Shot", index)
            end
            local edge = math.min(time - shot.Start, shot.Stop - time)
            fade.BackgroundTransparency = math.clamp(edge / .55, 0, 1)
            local width = camera.ViewportSize.X
            caption.TextSize = width < 700 and 18 or 20
            chapter.TextSize = width < 700 and 18 or 20
            chapter.TextWrapped = true
            gui:SetAttribute("Elapsed", math.floor(time * 10) / 10)
            lastTime = time
            if time >= Scene.Duration then stopped = true end
        end
        update()
        RunService:BindToRenderStep("BrightHavenFlashbackCamera", Enum.RenderPriority.Camera.Value + 10, function()
            local rendered, renderError = pcall(update)
            if not rendered then failure = renderError;outcome = "abort";stopped = true end
        end)
        while not stopped do RunService.Heartbeat:Wait() end
    end, debug.traceback)
    stopped = true
    if not ok or failure then outcome = "abort" end
    cleanup()
    if not ok or failure then warn("[BrightHaven Flashback]", err or failure) end
    return outcome
end

return Playback
