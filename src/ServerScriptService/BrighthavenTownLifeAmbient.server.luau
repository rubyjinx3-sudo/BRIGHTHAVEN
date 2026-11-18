local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local town = workspace:WaitForChild("BrighthavenTownLife")
local function lights()
    local night = ReplicatedStorage:GetAttribute("BrightHavenIsNight") == true
    for _,v in ipairs(town:GetDescendants()) do
        if v:IsA("SpotLight") and v.Name == "NightLight" then
            v.Enabled = night
            v.Parent.Material = night and Enum.Material.Neon or Enum.Material.Glass
        end
    end
end
ReplicatedStorage:GetAttributeChangedSignal("BrightHavenIsNight"):Connect(lights)
lights()

for _,v in ipairs(town:GetDescendants()) do
    if v:IsA("Model") and v:GetAttribute("TownRole") == "Moving swing" then
        local base = v:GetPivot()
        local angle = Instance.new("NumberValue")
        angle.Name, angle.Value, angle.Parent = "SwingAngle", -.22, v
        angle.Changed:Connect(function(value) if v.Parent then v:PivotTo(base * CFrame.Angles(value, 0, 0)) end end)
        TweenService:Create(angle, TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Value = .22}):Play()
    elseif v:IsA("Model") and v:GetAttribute("TownRole") == "Resident" then
        local shoulder
        for _,joint in ipairs(v:GetDescendants()) do
            if joint:IsA("Motor6D") and (joint.Name == "Right Shoulder" or joint.Name == "RightShoulder") then shoulder = joint; break end
        end
        if shoulder then
            task.spawn(function()
                local base = shoulder.C0
                task.wait(2 + tonumber(v.Name:match("%d+")) * .7)
                while v.Parent do
                    TweenService:Create(shoulder, TweenInfo.new(.7, Enum.EasingStyle.Sine), {C0 = base * CFrame.Angles(-.2, 0, 2.05)}):Play()
                    v:SetAttribute("WavesGiven", (v:GetAttribute("WavesGiven") or 0) + 1)
                    task.wait(1.1)
                    TweenService:Create(shoulder, TweenInfo.new(.7, Enum.EasingStyle.Sine), {C0 = base}):Play()
                    task.wait(12 + math.random() * 5)
                end
            end)
        end
    end
end
