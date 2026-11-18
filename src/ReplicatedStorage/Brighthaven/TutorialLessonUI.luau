local TextService = game:GetService("TextService")
local TweenService = game:GetService("TweenService")
local KidUI = require(script.Parent.Campaign.KidUI)
local UI = {}
local colours = {
    ink = Color3.fromRGB(48, 52, 55),
    blue = Color3.fromRGB(255, 211, 78),
    pink = Color3.fromRGB(255, 211, 78),
    paper = Color3.new(1, 1, 1),
    sky = Color3.fromRGB(255, 246, 202),
    yellow = Color3.fromRGB(255, 246, 202),
    green = Color3.fromRGB(48, 52, 55),
}
local groupColours = {
    {Color3.fromRGB(255, 246, 202), Color3.fromRGB(255, 211, 78)},
    {Color3.new(1, 1, 1), Color3.fromRGB(255, 211, 78)},
    {Color3.fromRGB(255, 246, 202), Color3.fromRGB(255, 211, 78)},
}
local function make(class, name, parent)
    local item = parent:FindFirstChild(name)
    if item and item.ClassName ~= class then item:Destroy(); item = nil end
    item = item or Instance.new(class)
    item.Name, item.Parent = name, parent
    return item
end
local function corner(item, radius)
    make("UICorner", "LessonCorner", item).CornerRadius = UDim.new(0, radius)
end
local function textStyle(item, size, bold)
    item.BackgroundTransparency, item.TextScaled, item.TextWrapped, item.AutomaticSize = 1, false, true, Enum.AutomaticSize.None
    item.Font, item.TextSize, item.TextColor3 = bold and Enum.Font.GothamBold or Enum.Font.Gotham, size, colours.ink
    item.TextXAlignment, item.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
end
local function buttonStyle(item, colour)
    item.BackgroundColor3, item.TextColor3, item.BorderSizePixel = colour, colours.ink, 0
    item.Font, item.TextSize, item.TextScaled, item.TextWrapped = Enum.Font.FredokaOne, 20, false, true
    corner(item, 8)
    item.AutoButtonColor = false
    item.MouseEnter:Connect(function() TweenService:Create(item, TweenInfo.new(.12), {BackgroundColor3=colour:Lerp(Color3.new(1,1,1), .08)}):Play() end)
    item.MouseLeave:Connect(function() TweenService:Create(item, TweenInfo.new(.12), {BackgroundColor3=colour}):Play() end)
end
function UI.Math(message)
    return (message or ""):gsub(" / ", " " .. utf8.char(247) .. " "):gsub(" x ", " " .. utf8.char(215) .. " "):gsub(" > ", " " .. utf8.char(8594) .. " ")
end

function UI.Create(frame, bounds, options)
    options = options or {}
    local controller = {Frame=frame, Pages={}, Index=1}
    frame.Visible, frame.BorderSizePixel, frame.BackgroundTransparency = false, 0, 0
    frame.BackgroundColor3, frame.AnchorPoint = colours.paper, Vector2.new(.5, 1)
    corner(frame, 16)
    require(script.Parent.KidTheme).DialoguePaper(frame,Color3.fromRGB(231,246,255))
    local stroke = make("UIStroke", "LessonOutline", frame)
    stroke.Color, stroke.Thickness = colours.blue, 3
    local header = make("Frame", "Header", frame)
    header.Size, header.BackgroundColor3, header.BorderSizePixel = UDim2.new(1, 0, 0, 88), colours.blue, 0
    corner(header, 16)
    local base = make("Frame", "HeaderBase", header)
    base.Position, base.Size, base.BackgroundColor3, base.BorderSizePixel = UDim2.fromOffset(0, 44), UDim2.new(1, 0, 0, 44), colours.blue, 0
    local badge = make("TextLabel", "SpeakerBadge", header)
    badge.Position, badge.Size = UDim2.fromOffset(16, 10), UDim2.fromOffset(68, 68)
    badge.BackgroundColor3, badge.TextColor3, badge.Font, badge.TextSize = colours.yellow, colours.ink, Enum.Font.GothamBold, 22
    corner(badge, 12)
    local speaker = make("TextLabel", "SpeakerTitle", header)
    textStyle(speaker, 22, true)
    speaker.Font, speaker.TextSize = Enum.Font.FredokaOne, 24
    speaker.Position, speaker.Size = UDim2.fromOffset(100, 14), UDim2.new(1, -158, 0, 30)
    speaker.TextColor3 = colours.ink
    local subtitle = make("TextLabel", "PracticeName", header)
    textStyle(subtitle, 16, true)
    subtitle.Position, subtitle.Size, subtitle.TextColor3 = UDim2.fromOffset(100, 50), UDim2.new(1, -122, 0, 24), colours.ink
    local close = make("TextButton", "Close", header)
    close.Position, close.Size = UDim2.new(1, -46, 0, 12), UDim2.fromOffset(36, 36)
    close.BackgroundTransparency, close.Text, close.Font, close.TextSize, close.TextColor3 = 1, "X", Enum.Font.GothamBold, 20, colours.ink
    close.Visible = options.Closeable == true
    local body = make("ScrollingFrame", "Body", frame)
    body.BackgroundTransparency, body.ClipsDescendants = 1, true
    body.BorderSizePixel, body.ScrollBarThickness, body.AutomaticCanvasSize = 0, 4, Enum.AutomaticSize.None
    local title = make("TextLabel", "LessonTitle", body)
    textStyle(title, 22, true)
    title.Font, title.TextSize = Enum.Font.FredokaOne, 24
    local dialogue = frame:FindFirstChild("DialogueText") or make("TextLabel", "DialogueText", body)
    dialogue.Parent = body
    textStyle(dialogue, 21, true)
    dialogue.LineHeight = 1.12
    local equation = make("TextLabel", "Equation", body)
    textStyle(equation, 22, true)
    equation.BackgroundTransparency, equation.BackgroundColor3, equation.TextColor3 = 0, colours.yellow, colours.ink
    equation.TextXAlignment, equation.TextYAlignment = Enum.TextXAlignment.Center, Enum.TextYAlignment.Center
    corner(equation, 8)
    local groups = make("Frame", "EqualGroups", body)
    groups.BackgroundTransparency = 1
    local labels = {}
    for i = 1, 3 do
        local group = make("Frame", "Group" .. i, groups)
        group.Position, group.Size = UDim2.new((i-1)/3, 3, 0, 0), UDim2.new(1/3, -6, 1, 0)
        group.BackgroundColor3, group.BorderSizePixel = groupColours[i][1], 0
        corner(group, 8)
        local name = make("TextLabel", "GroupName", group)
        textStyle(name, 18, true)
        name.Position, name.Size, name.TextXAlignment = UDim2.fromOffset(4, 6), UDim2.new(1, -8, 0, 24), Enum.TextXAlignment.Center
        local count = make("TextLabel", "Count", group)
        textStyle(count, 20, true)
        count.Position, count.Size, count.TextXAlignment = UDim2.fromOffset(4, 62), UDim2.new(1, -8, 0, 26), Enum.TextXAlignment.Center
        local chunk = make("TextLabel", "Chunk", group)
        textStyle(chunk, 20, true)
        chunk.Position, chunk.Size, chunk.TextXAlignment, chunk.TextColor3 = UDim2.fromOffset(4, 34), UDim2.new(1, -8, 0, 24), Enum.TextXAlignment.Center, colours.ink
        local packs = make("Frame", "Packs", group)
        packs.Position, packs.Size, packs.BackgroundTransparency = UDim2.fromOffset(4, 34), UDim2.new(1, -8, 0, 22), 1
        local layout = make("UIListLayout", "PackLayout", packs)
        layout.FillDirection, layout.HorizontalAlignment, layout.Padding = Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Center, UDim.new(0, 5)
        for p=1,5 do
            local pack = make("Frame", "Pack"..p, packs)
            pack.Size, pack.BackgroundColor3, pack.BorderSizePixel = UDim2.fromOffset(18, 22), groupColours[i][2], 0
            corner(pack, 3)
            local band = make("Frame", "Band", pack)
            band.Position, band.Size, band.BackgroundColor3, band.BorderSizePixel = UDim2.fromOffset(0, 8), UDim2.new(1, 0, 0, 4), Color3.new(1,1,1), 0
        end
        labels[i] = group
    end
    local remaining = make("TextLabel", "LeftToShare", body)
    textStyle(remaining, 18, true)
    remaining.TextXAlignment, remaining.TextColor3 = Enum.TextXAlignment.Center, colours.green
    local back = make("TextButton", "PreviousPage", frame)
    buttonStyle(back, colours.blue)
    back.Text = utf8.char(8592)
    local nextButton = frame:FindFirstChild("AcceptButton") or make("TextButton", "AcceptButton", frame)
    buttonStyle(nextButton, colours.pink)
    local count = make("TextLabel", "PageCount", frame)
    textStyle(count, 16, true)
    count.TextXAlignment, count.TextYAlignment = Enum.TextXAlignment.Center, Enum.TextYAlignment.Center
    local track = make("Frame", "StepTrack", frame)
    track.BackgroundColor3, track.BorderSizePixel = colours.sky, 0
    local fill = make("Frame", "Completed", track)
    fill.BackgroundColor3, fill.BorderSizePixel = colours.blue, 0
    local function layout()
        local screen = bounds.AbsoluteSize
        local width = math.min(640, math.max(300, screen.X - 40))
        local bottom = options.Centered and .5 or (options.Lifted and options.Lifted() and .76 or .95)
        local height = math.min(480, options.Centered and screen.Y - 32 or screen.Y * bottom - 16)
        frame.AnchorPoint = options.Centered and Vector2.new(.5,.5) or Vector2.new(.5,1)
        frame.Position, frame.Size = UDim2.fromScale(.5, bottom), UDim2.fromOffset(width, height)
        body.Position, body.Size = UDim2.fromOffset(20, 104), UDim2.new(1,-40,1,-180)
        local textWidth = width - 48
        local nameHeight = math.max(28, TextService:GetTextSize(speaker.Text,24,Enum.Font.FredokaOne,Vector2.new(width-158,1000)).Y)
        speaker.Size = UDim2.new(1,-158,0,nameHeight)
        subtitle.Position = UDim2.fromOffset(100, math.max(50, nameHeight+18))
        local titleHeight = title.Visible and math.max(28,TextService:GetTextSize(title.Text,24,Enum.Font.FredokaOne,Vector2.new(textWidth,1000)).Y) or 0
        local textTop = titleHeight > 0 and titleHeight+8 or 0
        local textHeight = math.max(48,TextService:GetTextSize(dialogue.Text,dialogue.TextSize,dialogue.Font,Vector2.new(textWidth,2000)).Y*1.12)
        title.Position, title.Size = UDim2.new(), UDim2.new(1,-8,0,titleHeight)
        dialogue.Position, dialogue.Size = UDim2.fromOffset(0,textTop), UDim2.new(1,-8,0,textHeight)
        local y = textTop+textHeight+12
        local equationHeight = math.max(44,TextService:GetTextSize(equation.Text,22,Enum.Font.GothamBold,Vector2.new(textWidth,1000)).Y+12)
        equation.Position, equation.Size = UDim2.fromOffset(0,y), UDim2.new(1,-8,0,equationHeight)
        if equation.Visible then y += equationHeight+12 end
        groups.Position, groups.Size = UDim2.fromOffset(0,y), UDim2.new(1,-8,0,90)
        if groups.Visible then y += 96 end
        remaining.Position, remaining.Size = UDim2.fromOffset(0,y), UDim2.new(1,-8,0,24)
        if remaining.Visible then y += 24 end
        body.CanvasSize = UDim2.fromOffset(0,y)
        back.Position, back.Size = UDim2.new(0,20,1,-64), UDim2.fromOffset(52,48)
        local buttonWidth = math.min(188, math.max(140,width*.4))
        nextButton.Position, nextButton.Size = UDim2.new(1,-buttonWidth-20,1,-64), UDim2.fromOffset(buttonWidth,48)
        count.Position, count.Size = UDim2.new(0,80,1,-64), UDim2.new(1,-buttonWidth-108,0,48)
        track.Position, track.Size = UDim2.new(0,20,1,-8), UDim2.new(1,-40,0,4)
    end
    function controller:Render()
        local page = self.Pages[self.Index]
        if not page then return end
        title.Text, title.Visible = page.Title or "", page.Title ~= nil
        dialogue.Text = page.Body or ""
        equation.Text, equation.Visible = UI.Math(page.Equation), page.Equation ~= nil
        groups.Visible, remaining.Visible = page.Each ~= nil, page.Left ~= nil
        for i, group in ipairs(labels) do
            group.GroupName.Text = (page.Group or "Group").." "..i
            group.Count.Text = tostring(page.Each or 0).." each"
            group.Chunk.Text, group.Chunk.Visible = page.Chunk or "", page.Chunk ~= nil
            for p=1,5 do group.Packs["Pack"..p].Visible = page.Each ~= nil and page.Each <= 5 and p <= page.Each end
        end
        remaining.Text = tostring(page.Left or 0).." left to share"
        count.Text = "Step "..self.Index.." of "..#self.Pages
        back.Visible = self.Index > 1
        nextButton.Text = self.Index < #self.Pages and "Next  "..utf8.char(8594) or self.FinalLabel
        fill.Size = UDim2.fromScale(self.Index/#self.Pages,1)
        body.CanvasPosition = Vector2.zero
        layout()
    end
    function controller:Show(pages, settings)
        settings = settings or {}
        self.Pages, self.Index, self.FinalLabel = pages, 1, settings.FinalLabel or "Done"
        speaker.Text, subtitle.Text, badge.Text = settings.Speaker or "Practice Guide", settings.Subtitle or "Learn one step at a time", settings.Badge or "?"
        KidUI.Portrait(badge, settings.Model)
        self:Render()
        frame.Visible = true
    end
    function controller:Hide() frame.Visible = false end
    back.Activated:Connect(function() controller.Index = math.max(1,controller.Index-1);controller:Render() end)
    nextButton.Activated:Connect(function()
        if controller.Index < #controller.Pages then controller.Index += 1;controller:Render();return end
        controller:Hide()
        if options.OnFinish then options.OnFinish() end
    end)
    close.Activated:Connect(function() controller:Hide() end)
    bounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
    if options.PositionChanged then options.PositionChanged:Connect(layout) end
    layout()
    return controller
end
return UI
