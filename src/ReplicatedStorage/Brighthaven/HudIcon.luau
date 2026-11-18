local HudIcon = {}
local assets={
    ["World Map"]="rbxassetid://126604506628629",
    ["Guidebook"]="rbxassetid://109063258338654",
    ["Quests"]="rbxassetid://136416861435677",
    ["My Bag"]="rbxassetid://124924202169496",
    ["Call E-Bike or Tricycle"]="rbxassetid://101707423055439",
    ["Call a Ride"]="rbxassetid://101707423055439",
    ["Health"]="rbxassetid://123964259409669",
    ["Hunger"]="rbxassetid://126210402040345",
    ["Thirst"]="rbxassetid://75960504910086",
}

function HudIcon.Asset(label,fallback)
    return assets[label] or fallback
end

function HudIcon.Emphasize(icon,padding)
    local existing=icon.Parent:FindFirstChild(icon.Name.."Backing")
    if existing then return existing end
    padding=padding or 8
    local backing=Instance.new("Frame")
    backing.Name=icon.Name.."Backing"
    backing.BackgroundColor3=Color3.fromRGB(29,34,39)
    backing:SetAttribute("SemanticColor",backing.BackgroundColor3)
    backing.BackgroundTransparency=.35
    backing.BorderSizePixel=0
    icon.ZIndex=math.max(2,icon.ZIndex)
    backing.ZIndex=icon.ZIndex-1
    backing.Parent=icon.Parent
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(.5,0)
    corner.Parent=backing
    local stroke=Instance.new("UIStroke")
    stroke.Color=Color3.new(1,1,1)
    stroke:SetAttribute("SemanticColor",stroke.Color)
    stroke.Thickness=1
    stroke.Transparency=.78
    stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
    stroke.Parent=backing
    local function align()
        backing.AnchorPoint=icon.AnchorPoint
        backing.Position=icon.Position-UDim2.fromOffset(padding*(.5-icon.AnchorPoint.X),padding*(.5-icon.AnchorPoint.Y))
        backing.Size=icon.Size+UDim2.fromOffset(padding,padding)
    end
    align()
    icon:GetPropertyChangedSignal("Size"):Connect(align)
    icon:GetPropertyChangedSignal("Position"):Connect(align)
    icon:GetPropertyChangedSignal("AnchorPoint"):Connect(align)
    return backing
end

function HudIcon.Attach(button,asset,label,color)
    button.Text=""
    button.Size=UDim2.fromOffset(44,44)
    button.BackgroundTransparency=1
    button.BorderSizePixel=0
    button.AutoButtonColor=false
    button:SetAttribute("HudIconColor",color or Color3.fromRGB(48,52,55))
    local icon=Instance.new("ImageLabel")
    icon.Name="Symbol"
    icon.Image=HudIcon.Asset(label,asset)
    icon.ImageColor3=button:GetAttribute("HudIconColor")
    icon:SetAttribute("SemanticColor",icon.ImageColor3)
    icon.AnchorPoint=Vector2.new(.5,.5)
    icon.Position=UDim2.fromScale(.5,.5)
    icon.Size=UDim2.fromOffset(28,28)
    icon.BackgroundTransparency=1
    icon.ScaleType=Enum.ScaleType.Fit
    icon.ZIndex=button.ZIndex+1
    icon.Parent=button
    local tooltip=Instance.new("TextLabel")
    tooltip.Name="Tooltip"
    tooltip.Text=label
    tooltip.Font=Enum.Font.GothamBold
    tooltip.TextSize=14
    tooltip.TextWrapped=true
    tooltip.TextColor3=Color3.new(1,1,1)
    tooltip:SetAttribute("SemanticTextColor",tooltip.TextColor3)
    tooltip.BackgroundColor3=Color3.fromRGB(28,31,34)
    tooltip:SetAttribute("SemanticColor",tooltip.BackgroundColor3)
    tooltip.BackgroundTransparency=.18
    tooltip.BorderSizePixel=0
    tooltip.AnchorPoint=Vector2.new(1,.5)
    tooltip.Position=UDim2.new(0,-8,.5,0)
    tooltip.Size=UDim2.fromOffset(148,36)
    tooltip.ZIndex=20
    tooltip.Visible=false
    tooltip.Parent=button
    local corner=Instance.new("UICorner")
    corner.CornerRadius=UDim.new(0,4)
    corner.Parent=tooltip
    local function show()
        tooltip.Visible=button.Visible
        icon.ImageColor3=Color3.fromRGB(255,222,118)
        icon:SetAttribute("SemanticColor",icon.ImageColor3)
    end
    local function hide()
        tooltip.Visible=false
        icon.ImageColor3=button:GetAttribute("HudIconColor")
        icon:SetAttribute("SemanticColor",icon.ImageColor3)
    end
    button.MouseEnter:Connect(show)
    button.MouseLeave:Connect(hide)
    button.SelectionGained:Connect(show)
    button.SelectionLost:Connect(hide)
    button.Activated:Connect(hide)
    button:GetPropertyChangedSignal("Visible"):Connect(hide)
    return icon
end

return HudIcon
