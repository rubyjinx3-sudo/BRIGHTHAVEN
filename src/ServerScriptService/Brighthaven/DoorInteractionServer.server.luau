local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local TWEEN_INFO = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local doors = {}

local function getDoorFromPrompt(prompt)
    local parent = prompt.Parent
    if parent and parent:IsA("Attachment") then
        parent = parent.Parent
    end
    if parent and parent:IsA("BasePart") and parent:GetAttribute("BrighthavenDoor") then
        return parent
    end
    return nil
end

local function getBuildingModel(door)
    local current = door.Parent
    while current and current ~= workspace do
        if current:IsA("Model") and current.Name ~= "CleanHouseFacade" and current.Name ~= "CleanBuildingFacade" then
            return current
        end
        current = current.Parent
    end
    return door.Parent
end

local function getNormalAxis(door)
    local axis = door:GetAttribute("DoorNormalAxis")
    if axis == "X" or axis == "Z" then
        return axis
    end
    return door.Size.X <= door.Size.Z and "X" or "Z"
end

local function getOutsideSign(door, normalAxis)
    local existing = door:GetAttribute("DoorOutsideSign")
    if existing == 1 or existing == -1 then
        return existing
    end
    local model = getBuildingModel(door)
    if model and model:IsA("Model") then
        local cf = model:GetBoundingBox()
        if normalAxis == "X" then
            return door.Position.X >= cf.Position.X and 1 or -1
        end
        return door.Position.Z >= cf.Position.Z and 1 or -1
    end
    return 1
end

local function configurePrompt(prompt, door, normalAxis, outsideSign, closedPosition)
    prompt.RequiresLineOfSight = true
    prompt.MaxActivationDistance = 7
    prompt:SetAttribute("BrighthavenDoorPrompt", true)
    prompt:SetAttribute("DoorNormalAxis", normalAxis)
    prompt:SetAttribute("DoorOutsideSign", outsideSign)
    prompt:SetAttribute("DoorClosedX", closedPosition.X)
    prompt:SetAttribute("DoorClosedZ", closedPosition.Z)
    prompt:SetAttribute("DoorBusy", false)
end

local function configurePrompts(door, normalAxis, outsideSign, closedPosition)
    for _, child in ipairs(door:GetDescendants()) do
        if child:IsA("ProximityPrompt") and child:GetAttribute("BrighthavenDoorPrompt") then
            configurePrompt(child, door, normalAxis, outsideSign, closedPosition)
        end
    end
end

local function initDoor(door)
    if doors[door] then
        return doors[door]
    end

    local axis = door:GetAttribute("DoorSlideAxis") or "X"
    local distance = door:GetAttribute("DoorSlideDistance") or (math.max(door.Size.X, door.Size.Z) + 1.5)
    local sign = door:GetAttribute("DoorSlideSign") or 1
    local offset = axis == "Z" and CFrame.new(0, 0, distance * sign) or CFrame.new(distance * sign, 0, 0)
    local normalAxis = getNormalAxis(door)
    local outsideSign = getOutsideSign(door, normalAxis)

    local data = {
        Closed = door.CFrame,
        Open = door.CFrame * offset,
        IsOpen = false,
        NormalAxis = normalAxis,
        OutsideSign = outsideSign,
    }
    doors[door] = data
    door.Anchored = true
    door.CanCollide = true
    door:SetAttribute("DoorNormalAxis", normalAxis)
    door:SetAttribute("DoorOutsideSign", outsideSign)
    door:SetAttribute("DoorClosedX", data.Closed.Position.X)
    door:SetAttribute("DoorClosedZ", data.Closed.Position.Z)
    configurePrompts(door, normalAxis, outsideSign, data.Closed.Position)
    return data
end

local function isPlayerOutsideDoor(player, data)
    if not player then
        return false
    end
    local character = player.Character
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        return false
    end
    local closedPosition = data.Closed.Position
    local delta = data.NormalAxis == "X"
        and (rootPart.Position.X - closedPosition.X) * data.OutsideSign
        or (rootPart.Position.Z - closedPosition.Z) * data.OutsideSign
    return delta > 0.25
end

for _, descendant in ipairs(workspace:GetDescendants()) do
    if descendant:IsA("BasePart") and descendant:GetAttribute("BrighthavenDoor") then
        initDoor(descendant)
    end
end

workspace.DescendantAdded:Connect(function(descendant)
    if descendant:IsA("BasePart") and descendant:GetAttribute("BrighthavenDoor") then
        initDoor(descendant)
    elseif descendant:IsA("ProximityPrompt") and descendant:GetAttribute("BrighthavenDoorPrompt") then
        local door = getDoorFromPrompt(descendant)
        if door then
            local data = initDoor(door)
            configurePrompt(descendant, door, data.NormalAxis, data.OutsideSign, data.Closed.Position)
        end
    end
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    if not prompt:GetAttribute("BrighthavenDoorPrompt") then
        return
    end

    local door = getDoorFromPrompt(prompt)
    if not door then
        return
    end

    local data = initDoor(door)
    if prompt:GetAttribute("DoorBusy") or not isPlayerOutsideDoor(player, data) then
        return
    end

    local shouldOpen = not data.IsOpen
    data.IsOpen = shouldOpen

    prompt:SetAttribute("DoorBusy", true)
    prompt.Enabled = false
    door.CanCollide = false

    local target = shouldOpen and data.Open or data.Closed
    local tween = TweenService:Create(door, TWEEN_INFO, { CFrame = target })
    tween:Play()
    tween.Completed:Once(function()
        if not shouldOpen then
            door.CanCollide = true
        end
        prompt.ActionText = shouldOpen and "Close" or "Open"
        prompt:SetAttribute("DoorBusy", false)
        prompt.Enabled = true
    end)
end)
