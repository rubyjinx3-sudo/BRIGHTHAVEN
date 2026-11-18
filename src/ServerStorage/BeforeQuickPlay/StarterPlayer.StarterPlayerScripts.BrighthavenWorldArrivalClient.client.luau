local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local motion = require(ReplicatedStorage.Brighthaven:WaitForChild("WorldArrivalMotion"))
local entrance = workspace:WaitForChild("Portal6"):WaitForChild("Teleport")
local captain = workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
local binding = "BrightHavenWorldArrival"
local playing, consumed = false, nil
local arrivalConnection

local function playArrival()
    local serial = player:GetAttribute("WorldArrivalSerial")
    if not serial or serial == consumed or playing then return end
    consumed = serial
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not humanoid or humanoid.SeatPart or player:GetAttribute("SchoolShuttleRiding") then return end
    -- The server signals after teleporting; wait for the character position to replicate.
    local deadline = os.clock() + 5
    while root.Parent and (root.Position - entrance.Position).Magnitude > 40 and os.clock() < deadline do
        RunService.Heartbeat:Wait()
    end
    if player.Character ~= character or humanoid.Health <= 0 or (root.Position - entrance.Position).Magnitude > 40 then return end
    if player:GetAttribute("BrighthavenFlashbackPlaying") then return end
    playing = true
    RunService.RenderStepped:Wait()
    RunService.RenderStepped:Wait()
    local camera = workspace.CurrentCamera
    local saved = {FOV = camera.FieldOfView, Subject = camera.CameraSubject,
        Prompts = ProximityPromptService.Enabled, AutoRotate = humanoid.AutoRotate}
    local controls, gui, stopped, failure, cleaned
    local connections = {}
    local function cleanup()
        if cleaned then return end
        cleaned, stopped = true, true
        RunService:UnbindFromRenderStep(binding)
        for _,connection in ipairs(connections) do connection:Disconnect() end
        if gui then gui:Destroy() end
        pg:SetAttribute("WorldArrivalPlaying", nil)
        ProximityPromptService.Enabled = saved.Prompts
        if humanoid.Parent then humanoid.AutoRotate = saved.AutoRotate end
        if camera == workspace.CurrentCamera and not player:GetAttribute("SchoolShuttleRiding") then
            camera.FieldOfView = saved.FOV
            camera.CameraSubject = player.Character == character and humanoid
                or player.Character and player.Character:FindFirstChildOfClass("Humanoid") or saved.Subject
            camera.CameraType = Enum.CameraType.Custom
        end
        if controls then controls:Enable() end
        playing = false
    end
    local ok, err = xpcall(function()
        controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()
        controls:Disable()
        humanoid.AutoRotate = false
        pg:SetAttribute("WorldArrivalPlaying", true)
        ProximityPromptService.Enabled = false
        gui = Instance.new("ScreenGui")
        gui.Name, gui.IgnoreGuiInset, gui.ResetOnSpawn, gui.DisplayOrder = "BrightHavenWorldArrival", true, false, 90
        local fade = Instance.new("Frame")
        fade.Name, fade.Size = "Fade", UDim2.fromScale(1, 1)
        fade.BackgroundColor3, fade.BackgroundTransparency, fade.BorderSizePixel = Color3.new(), 1, 0
        fade.Active = true
        fade.Parent, gui.Parent = gui, pg
        for _,bottom in ipairs({false,true}) do
            local bar=Instance.new("Frame")
            bar.Name=bottom and "BottomLetterbox" or "TopLetterbox"
            bar.Size=UDim2.new(1,0,.075,0);bar.Position=UDim2.fromScale(0,bottom and .925 or 0)
            bar.BackgroundColor3=Color3.new();bar.BorderSizePixel=0;bar.ZIndex=2;bar.Parent=gui
        end
        local title=Instance.new("TextLabel")
        title.Name="TownTitle";title.Position=UDim2.fromScale(.06,.8);title.Size=UDim2.fromScale(.7,.1)
        title.BackgroundTransparency=1;title.Text="BrightHaven";title.TextColor3=Color3.new(1,1,1)
        title.TextStrokeTransparency=.5;title.Font=Enum.Font.FredokaOne;title.TextSize=34
        title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=gui
        local skip=Instance.new("TextButton")
        skip.Name="SkipTour";skip.AnchorPoint=Vector2.new(1,0);skip.Position=UDim2.new(1,-24,.09,0)
        skip.Size=UDim2.fromOffset(92,40);skip.Text="Skip";skip.Font=Enum.Font.GothamBold;skip.TextSize=18
        skip.BackgroundColor3=Color3.fromRGB(255,215,75);skip.BorderSizePixel=0;skip.Parent=gui
        Instance.new("UICorner",skip).CornerRadius=UDim.new(0,8)
        fade.ZIndex=5
        table.insert(connections, humanoid.Died:Connect(cleanup))
        table.insert(connections, player.CharacterRemoving:Connect(cleanup))
        table.insert(connections, script.Destroying:Connect(cleanup))
        local elapsed, switched, handoff = 0, false, nil
        table.insert(connections,skip.Activated:Connect(function()
            if switched then elapsed=motion.FadeDuration+motion.TourDuration;skip.Visible=false end
        end))
        local function update(dt)
            if stopped then return end
            if camera ~= workspace.CurrentCamera or player.Character ~= character or humanoid.Health <= 0
                or player:GetAttribute("SchoolShuttleRiding") then
                stopped = true
                return
            end
            elapsed += math.min(dt, 0.05)
            if elapsed < motion.FadeDuration then
                fade.BackgroundTransparency = 1 - motion.Ease(elapsed / motion.FadeDuration)
            elseif elapsed < motion.FadeDuration + motion.TourDuration then
                if not switched then
                    switched = true
                    camera.CameraType = Enum.CameraType.Scriptable
                end
                local time = elapsed - motion.FadeDuration
                title.Text=time<27 and "BrightHaven" or "Barangay Hall"
                title.TextTransparency=1-math.min(1,time/2)*math.min(1,(motion.TourDuration-time)/2)
                local frame, focus = motion.Sample(captain.Position, time / motion.TourDuration)
                camera.CFrame, camera.Focus, camera.FieldOfView = frame, CFrame.new(focus), 65
                fade.BackgroundTransparency = motion.Ease(math.min(time / 0.5, 1))
            else
                if not handoff then
                    title.Visible=false;skip.Visible=false
                    gui.TopLetterbox.Visible=false;gui.BottomLetterbox.Visible=false
                    handoff = {Frame = camera.CFrame, FOV = camera.FieldOfView}
                    camera.CameraSubject, camera.CameraType = humanoid, Enum.CameraType.Custom
                end
                -- The default camera computes its live target first, then we blend toward it.
                local alpha = motion.Ease((elapsed - motion.FadeDuration - motion.TourDuration) / motion.ReturnDuration)
                camera.CFrame = handoff.Frame:Lerp(camera.CFrame, alpha)
                camera.FieldOfView = handoff.FOV + (saved.FOV - handoff.FOV) * alpha
                fade.BackgroundTransparency = 1
                if alpha >= 1 then stopped = true end
            end
        end
        RunService:BindToRenderStep(binding, Enum.RenderPriority.Camera.Value + 10, function(dt)
            local rendered, renderError = pcall(update, dt)
            if not rendered then failure = renderError; stopped = true end
        end)
        while not stopped do RunService.Heartbeat:Wait() end
    end, debug.traceback)
    cleanup()
    if not ok or failure then warn("[BrightHaven World Arrival]", err or failure) end
end

arrivalConnection = player:GetAttributeChangedSignal("WorldArrivalSerial"):Connect(function()
    task.spawn(playArrival)
end)
script.Destroying:Connect(function() arrivalConnection:Disconnect() end)
if player:GetAttribute("WorldArrivalSerial") then task.spawn(playArrival) end

