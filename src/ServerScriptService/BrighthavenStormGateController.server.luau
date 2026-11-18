local TweenService = game:GetService("TweenService")

local gate = workspace:WaitForChild("Fence gate")
local panel = gate:WaitForChild("SlidingPanel")
local anchor = gate:WaitForChild("GatePromptAnchor")
local prompt = anchor:WaitForChild("OpenGatePrompt")
local closedPivot = gate:GetAttribute("ClosedPanelPivot") or panel:GetPivot()
local openOffset = gate:GetAttribute("OpenOffset") or Vector3.new(0, 0, 26)
local opening = false

panel:PivotTo(closedPivot)
gate:SetAttribute("GateState", "Closed")
prompt.Enabled = true
prompt.ActionText = "Open Gate"

prompt.Triggered:Connect(function(player)
    if opening or gate:GetAttribute("GateState") ~= "Closed" then return end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid or humanoid.Health <= 0 then return end
    if (root.Position - anchor.Position).Magnitude > prompt.MaxActivationDistance + 3 then return end

    opening = true
    gate:SetAttribute("GateState", "Opening")
    prompt.Enabled = false
    -- Keep the moving panel from pushing or trapping anyone in the entrance.
    for _,part in panel:GetDescendants() do
        if part:IsA("BasePart") then part.CanCollide = false end
    end

    local pivot = Instance.new("CFrameValue")
    pivot.Value = closedPivot
    pivot.Parent = script
    local connection = pivot:GetPropertyChangedSignal("Value"):Connect(function()
        panel:PivotTo(pivot.Value)
    end)
    local tween = TweenService:Create(pivot, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
        Value = closedPivot + openOffset,
    })
    tween:Play()
    tween.Completed:Wait()
    connection:Disconnect()
    panel:PivotTo(closedPivot + openOffset)
    pivot:Destroy()
    tween:Destroy()
    gate:SetAttribute("GateState", "Open")
end)
