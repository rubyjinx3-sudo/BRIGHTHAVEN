local HudLayout={}
local HudIcon=require(script.Parent:WaitForChild("HudIcon"))

function HudLayout.StatusMetrics(topbarWidth,screenWidth)
    local embedded=topbarWidth>=770
    local width=embedded and 450 or math.min(450,math.max(264,screenWidth-24))
    local cell=math.floor((width-16)/3)
    return {Embedded=embedded,Width=cell*3+16,Cell=cell,Track=cell-32,Height=32}
end

function HudLayout.Topbar()
    local pg=game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
    local gui=pg:FindFirstChild("BrightHavenHud")
    if not gui then
        gui=Instance.new("ScreenGui")
        gui.Name="BrightHavenHud"
        gui.ResetOnSpawn=false
        gui.DisplayOrder=80
        gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
        gui.ScreenInsets=Enum.ScreenInsets.TopbarSafeInsets
        gui.Parent=pg
        local bounds=Instance.new("Frame")
        bounds.Name="Bounds"
        bounds.Size=UDim2.fromScale(1,1)
        bounds.BackgroundTransparency=1
        bounds.Parent=gui
    end
    return gui
end

function HudLayout.Action(button,slot)
    button.Parent=HudLayout.Topbar()
    button.AnchorPoint=Vector2.new(1,0)
    button.Position=UDim2.new(1,-16-(5-slot)*48,0,8)
    button.Size=UDim2.fromOffset(40,40)
    button.BackgroundTransparency=1
    button.AutoButtonColor=false
    if button:FindFirstChild("Symbol") then
        button.Symbol.Size=UDim2.fromOffset(30,30)
        button.Symbol.ImageColor3=Color3.new(1,1,1)
        button.Symbol:SetAttribute("SemanticColor",Color3.new(1,1,1))
        button:SetAttribute("HudIconColor",Color3.new(1,1,1))
        HudIcon.Emphasize(button.Symbol)
    end
    local hint=button:FindFirstChild("Tooltip")
    if hint then
        hint.AnchorPoint=Vector2.new(1,0)
        hint.Position=UDim2.new(1,0,1,8)
        hint.Size=UDim2.fromOffset(slot==5 and 204 or 148,30)
        hint.TextSize=14
    end
end

function HudLayout.Hint(target,value)
    local hint=Instance.new("TextLabel")
    hint.Name="Tooltip"
    hint.Text=value
    hint.Size=UDim2.fromOffset(220,42)
    hint.Position=UDim2.new(0,0,1,8)
    hint.BackgroundColor3=Color3.fromRGB(28,31,34)
    hint:SetAttribute("SemanticColor",hint.BackgroundColor3)
    hint.BackgroundTransparency=.18
    hint.BorderSizePixel=0
    hint.TextColor3=Color3.new(1,1,1)
    hint:SetAttribute("SemanticTextColor",hint.TextColor3)
    hint.TextSize=13
    hint.Font=Enum.Font.GothamBold
    hint.TextWrapped=true
    hint.Visible=false
    hint.ZIndex=30
    hint.Parent=target
    local corner=Instance.new("UICorner");corner.CornerRadius=UDim.new(0,8);corner.Parent=hint
    target.MouseEnter:Connect(function() hint.Visible=target.Visible end)
    target.MouseLeave:Connect(function() hint.Visible=false end)
    target:GetPropertyChangedSignal("Visible"):Connect(function() hint.Visible=false end)
    return hint
end

return HudLayout
