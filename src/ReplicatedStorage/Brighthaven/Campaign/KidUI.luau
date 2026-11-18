local UI = {}

function UI.Portrait(badge, model)
    local old = badge:FindFirstChild("Portrait")
    if old then old:Destroy() end
    if not model or not model:IsA("Model") or not model:FindFirstChild("Head") then return end
    local archivable = model.Archivable
    model.Archivable = true
    local clone = model:Clone()
    model.Archivable = archivable
    if not clone then return end
    local viewport = Instance.new("ViewportFrame")
    viewport.Name = "Portrait"
    viewport.Size = UDim2.fromScale(1, 1)
    viewport.ZIndex = badge.ZIndex + 1
    viewport.BackgroundTransparency = 1
    viewport.Ambient = Color3.fromRGB(220, 220, 220)
    viewport.LightColor = Color3.new(1, 1, 1)
    viewport.Parent = badge
    local world = Instance.new("WorldModel")
    world.Parent = viewport
    for _, object in ipairs(clone:GetDescendants()) do
        if object:IsA("LuaSourceContainer") or object:IsA("ProximityPrompt") or object:IsA("BillboardGui") then object:Destroy()
        elseif object:IsA("BasePart") then object.Anchored = true; object.CanCollide = false end
    end
    clone.Parent = world
    local head = clone.Head
    local camera = Instance.new("Camera")
    camera.FieldOfView = 38
    camera.CFrame = CFrame.lookAt(head.Position + head.CFrame.LookVector * 4.5 + Vector3.new(0, .5, 0), head.Position - Vector3.new(0, .4, 0))
    camera.Parent = viewport
    viewport.CurrentCamera = camera
    badge.Text = ""
end
return UI
