local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local Rules = require(script.Parent.TutorialNumberRules)
local UI = {}
local ink = Color3.fromRGB(48, 52, 55)
local yellow = Color3.fromRGB(255, 211, 78)
local function make(class, name, parent, props)
    local item = Instance.new(class)
    item.Name = name
    for key, value in pairs(props) do item[key] = value end
    item.Parent = parent
    return item
end
function UI.Create(gui, bounds, onTips)
    local panel = make("Frame", "CountingGuide", gui, {
        AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, 12),
        Size = UDim2.fromOffset(420, 152), Visible = false,
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    })
    make("UICorner", "Corner", panel, {CornerRadius = UDim.new(0, 8)})
    require(script.Parent.KidTheme).DialoguePaper(panel,Color3.fromRGB(229,247,255))
    local outline = make("UIStroke", "Outline", panel, {Color = yellow, Thickness = 2})
    local header = make("Frame", "Header", panel, {
        Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = yellow, BorderSizePixel = 0,
    })
    make("UICorner", "Corner", header, {CornerRadius = UDim.new(0, 8)})
    local function label(name, size, font, parent)
        return make("TextLabel", name, parent or panel, {
            BackgroundTransparency = 1, TextColor3 = ink, TextSize = size,
            Font = font, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        })
    end
    local title = label("Title", 20, Enum.Font.FredokaOne, header)
    title.Text, title.Position, title.Size = "Let's skip count!", UDim2.fromOffset(14, 6), UDim2.new(1, -94, 0, 32)
    local tips = make("TextButton", "Tips", header, {
        Position = UDim2.new(1, -76, 0, 4), Size = UDim2.fromOffset(68, 36),
        Text = "?", TextSize = 24, Font = Enum.Font.GothamBold, TextColor3 = ink,
        BackgroundTransparency = 1,
    })
    tips.Activated:Connect(onTips)
    local instruction = label("Instruction", 19, Enum.Font.GothamBold)
    instruction.Position = UDim2.fromOffset(14, 52)
    local sequence = label("EarnedSteps", 26, Enum.Font.GothamBold)
    local progress = label("Progress", 16, Enum.Font.Gotham)
    local lastKey, flash
    local api = {Frame = panel}
    function api:Update(start, row, visible, atBottom, feedback)
        panel.Visible = visible
        if not visible then return end
        local steps = Rules.CountedSteps(start, row)
        local key = start .. ":" .. tostring(row)
        local jumps = #steps - 1
        title.Text = jumps >= 3 and "Great skip counting!" or jumps > 0 and "Keep adding " .. start or "Let's skip count!"
        instruction.Text = jumps >= 3 and "You made three equal jumps. Great counting!"
            or feedback or ("Start at " .. start .. ". Add " .. start .. " each jump.")
        sequence.Text = table.concat(steps, " > ")
        progress.Text = #steps.." equal groups: "..start.." x "..#steps.." = "..steps[#steps]
        local width = math.min(420, bounds.AbsoluteSize.X - 32)
        instruction.Visible = true
        local textHeight = instruction.Visible and TextService:GetTextSize(instruction.Text, instruction.TextSize, instruction.Font, Vector2.new(width - 28, 1000)).Y or 0
        instruction.Size = UDim2.new(1, -28, 0, textHeight + 4)
        sequence.Position, sequence.Size = UDim2.fromOffset(14, 60 + textHeight), UDim2.new(1, -28, 0, 34)
        progress.Position, progress.Size = UDim2.fromOffset(14, 99 + textHeight), UDim2.new(1, -28, 0, 24)
        panel.Size = UDim2.fromOffset(width, 133 + textHeight)
        panel.AnchorPoint = Vector2.new(.5, atBottom and 1 or 0)
        panel.Position = UDim2.new(.5, 0, atBottom and 1 or 0, atBottom and -16 or 12)
        if lastKey ~= key then
            lastKey = key
            if flash then flash:Cancel() end
            outline.Thickness = 4
            flash = TweenService:Create(outline, TweenInfo.new(.8), {Thickness = 2})
            flash:Play()
        end
    end
    return api
end
return UI
