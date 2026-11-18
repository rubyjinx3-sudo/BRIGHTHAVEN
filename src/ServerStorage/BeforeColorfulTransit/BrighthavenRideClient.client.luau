local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local folder = ReplicatedStorage:WaitForChild("Brighthaven")
local Practice = require(folder.TutorialPractice)
local request = ReplicatedStorage:WaitForChild("Brighthaven"):WaitForChild("Transit"):WaitForChild("RideRequest")
local function make(class, properties, parent)
    local item = Instance.new(class)
    for key, value in pairs(properties) do item[key] = value end
    item.Parent = parent
    return item
end
local gui = make("ScreenGui", {Name = "BrighthavenRideGui", ResetOnSpawn = false, DisplayOrder = 45,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local panel = make("Frame", {Name = "RidePanel", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.new(.5, 0, 1, -24),
    Size = UDim2.new(1, -32, 0, 78), BackgroundColor3 = Color3.fromRGB(255, 248, 214), BorderSizePixel = 0, Visible = false}, gui)
make("UISizeConstraint", {MaxSize = Vector2.new(370, 78), MinSize = Vector2.new(0, 78)}, panel)
make("UICorner", {CornerRadius = UDim.new(0, 12)}, panel)
make("UIStroke", {Color = Color3.fromRGB(255, 180, 76), Thickness = 2}, panel)
local title = make("TextLabel", {Name = "RideTitle", Position = UDim2.fromOffset(16, 13), Size = UDim2.new(1, -164, 0, 25),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 18, TextScaled = true, Text = "Jeepney Ride",
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(24, 47, 62)}, panel)
local status = make("TextLabel", {Name = "RideStatus", Position = UDim2.fromOffset(16, 41), Size = UDim2.new(1, -164, 0, 24),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBold, TextSize = 12, Text = "Enjoy the ride!", TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(45, 70, 82)}, panel)
make("UITextSizeConstraint", {MinTextSize = 12, MaxTextSize = 18}, title)
status.Size = UDim2.new(1, -164, 0, 28)
status.TextSize=14
local exit = make("TextButton", {Name = "GetOff", AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -14, .5, 0),
    Size = UDim2.fromOffset(120, 46), Text = "Get Off", Font = Enum.Font.GothamBlack, TextSize = 17,
    TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = Color3.fromRGB(52, 142, 202), BorderSizePixel = 0}, panel)
make("UICorner", {CornerRadius = UDim.new(0, 8)}, exit)
local lastRequest = 0
local function getOff()
    if not player:GetAttribute("BrighthavenRiding") or os.clock() - lastRequest < .5 then return end
    lastRequest = os.clock()
    if player:GetAttribute("TaxiState") then
        task.spawn(function() folder.Transit.TaxiRequest:InvokeServer("Exit",{}) end)
    else request:FireServer("Exit") end
end
exit.Activated:Connect(getOff)
local activeHumanoid, jumpEnabled, fadedRoof, oldTransparency
local function restore()
    ContextActionService:UnbindAction("BrighthavenGetOff")
    if activeHumanoid and activeHumanoid.Parent then activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, jumpEnabled) end
    if fadedRoof and fadedRoof.Parent then fadedRoof.LocalTransparencyModifier = oldTransparency end
    activeHumanoid, fadedRoof = nil, nil
end
request.OnClientEvent:Connect(function(action, destination, character)
    if action ~= "Exit" or typeof(destination) ~= "CFrame" or player.Character ~= character then return end
    local humanoid, root = character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 then return end
    local seat = humanoid.SeatPart
    local weld = seat and seat:FindFirstChild("SeatWeld")
    if weld and weld:IsA("Weld") and weld.Part1 and weld.Part1:IsDescendantOf(character) then weld:Destroy() end
    humanoid.Sit, humanoid.Jump = false, false
    humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
    root.CFrame = destination
    root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    task.delay(.35, function()
        if player.Character == character and root.Parent and humanoid.Health > 0 and not humanoid.SeatPart then
            root.CFrame = destination
            root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        end
    end)
end)
folder.Transit:WaitForChild("TaxiNotice").OnClientEvent:Connect(function(action,destination,character)
    if action~="Exit" or typeof(destination)~="CFrame" or player.Character~=character then return end
    local h=character:FindFirstChildOfClass("Humanoid")
    local root=character:FindFirstChild("HumanoidRootPart")
    if not h or not root or h.Health<=0 then return end
    local weld=h.SeatPart and h.SeatPart:FindFirstChild("SeatWeld")
    if weld then weld:Destroy() end
    h.Sit=false;h.Jump=false;h:ChangeState(Enum.HumanoidStateType.GettingUp)
    root.CFrame=destination;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
    task.delay(.35,function()
        if player.Character==character and root.Parent and h.Health>0 and not h.SeatPart then
            root.CFrame=destination;root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        end
    end)
end)
local function update()
    local riding = player:GetAttribute("BrighthavenRiding") == true
    panel.Visible = riding
    title.Text=player:GetAttribute("TaxiKind") and player:GetAttribute("TaxiKind").." Ride" or "Jeepney Ride"
    status.Text = player:GetAttribute("BrighthavenRideWaiting") and "Finding a safe stop..."
        or player:GetAttribute("TaxiDestination") and "Next stop: "..player:GetAttribute("TaxiDestination") or "Enjoy the ride!"
    if not riding then restore(); return end
    if not activeHumanoid then
        activeHumanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if activeHumanoid then
            jumpEnabled = activeHumanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)
            activeHumanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end
        ContextActionService:BindActionAtPriority("BrighthavenGetOff", function(_, state)
            if state == Enum.UserInputState.Begin then getOff() end
            return Enum.ContextActionResult.Sink
        end, false, Enum.ContextActionPriority.High.Value + 1, Enum.PlayerActions.CharacterJump, Enum.KeyCode.Space, Enum.KeyCode.ButtonA)
        local vehicles = workspace:FindFirstChild("BrighthavenTransit")
        local vehicle = vehicles and vehicles:FindFirstChild(player:GetAttribute("BrighthavenRideVehicle") or "")
        fadedRoof = vehicle and vehicle:FindFirstChild("Roof")
        if fadedRoof then oldTransparency = fadedRoof.LocalTransparencyModifier; fadedRoof.LocalTransparencyModifier = .8 end
    end
end
player:GetAttributeChangedSignal("BrighthavenRiding"):Connect(update)
player:GetAttributeChangedSignal("BrighthavenRideWaiting"):Connect(update)
player:GetAttributeChangedSignal("TaxiDestination"):Connect(update)
player:GetAttributeChangedSignal("TaxiKind"):Connect(update)
player.CharacterRemoving:Connect(function() panel.Visible = false; restore() end)
update()
