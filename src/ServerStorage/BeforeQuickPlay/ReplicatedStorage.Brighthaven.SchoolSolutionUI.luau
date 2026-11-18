local UI = {}
local MissionData = require(game.ReplicatedStorage.Brighthaven.MissionData)
local ChunkingMath=require(game.ReplicatedStorage.Brighthaven.Campaign.ChunkingMath)
local yellow, white = Color3.fromRGB(255, 216, 77), Color3.new(1, 1, 1)
local ink, muted = Color3.fromRGB(51, 55, 57), Color3.fromRGB(86, 91, 93)
local function make(class, name, parent, props)
    local item = Instance.new(class)
    item.Name = name
    for key, value in pairs(props) do item[key] = value end
    item.Parent = parent
    return item
end
local function text(name, parent, value, size, pos, bounds)
    return make("TextLabel", name, parent, {BackgroundTransparency = 1, Text = value,
        TextColor3 = ink, Font = Enum.Font.GothamBold, TextSize = size,
        TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center, Position = pos, Size = bounds})
end
local function button(name, parent, value, pos, bounds)
    local b = make("TextButton", name, parent, {Text = value, Font = Enum.Font.GothamBold,
        TextSize = 18, TextColor3 = ink, BackgroundColor3 = yellow, BorderSizePixel = 0,
        TextWrapped = true, Position = pos, Size = bounds})
    make("UICorner", "Corner", b, {CornerRadius = UDim.new(0, 8)})
    return b
end
function UI.Create(gui, screenBounds, options)
    local self = {Open = false, Available = false}
    local frame = make("Frame", "SchoolSolution", gui, {AnchorPoint = Vector2.new(.5, 1),
        Position = UDim2.new(.5, 0, 1, -16), Size = UDim2.fromOffset(900, 314),
        BackgroundColor3 = white, BorderSizePixel = 0, Visible = false})
    make("UICorner", "Corner", frame, {CornerRadius = UDim.new(0, 8)})
    make("UIStroke", "Outline", frame, {Color = yellow, Thickness = 3})
    local ribbon = make("Frame", "Ribbon", frame, {BackgroundColor3 = yellow, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 44)})
    local title = text("Title", ribbon, "My Solution", 21, UDim2.fromOffset(14, 0), UDim2.new(1, -74, 1, 0))
    title.Font = Enum.Font.FredokaOne
    local close = button("Close", ribbon, "X", UDim2.new(1, -48, 0, 2), UDim2.fromOffset(44, 40))
    local work = make("Frame", "Work", frame, {BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 54)})
    local remaining = text("Remaining", work, "", 18, UDim2.new(), UDim2.new(.5, -4, 0, 28))
    local each = text("Quotient", work, "", 18, UDim2.new(.5, 4, 0, 0), UDim2.new(.5, -4, 0, 28))
    local sheet = make("ScrollingFrame", "Worksheet", work, {BackgroundColor3 = Color3.fromRGB(255, 251, 224),
        BorderSizePixel = 0, Position = UDim2.fromOffset(0, 34), Size = UDim2.new(1, 0, 0, 80),
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
    local sums = text("Sums", sheet, "", 19, UDim2.fromOffset(8, 4), UDim2.new(1, -18, 0, 0))
    sums.Font, sums.TextYAlignment = Enum.Font.Code, Enum.TextYAlignment.Top
    local step = text("Step", work, "", 18, UDim2.fromOffset(0, 120), UDim2.new(1, 0, 0, 48))
    local presets = make("Frame", "Multipliers", work, {BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 174), Size = UDim2.new(.48, -6, 0, 44)})
    local input = make("TextBox", "Answer", work, {BackgroundColor3 = white, BorderSizePixel = 0,
        Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = ink, PlaceholderText = "Your number",
        ClearTextOnFocus = false, Text = "", Position = UDim2.new(.48, 0, 0, 174), Size = UDim2.new(.27, -8, 0, 44)})
    make("UICorner", "Corner", input, {CornerRadius = UDim.new(0, 8)})
    make("UIStroke", "Outline", input, {Color = yellow, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local submit = button("Submit", work, "Set", UDim2.new(.75, 0, 0, 174), UDim2.new(.25, 0, 0, 44))
    local guide = make("ScrollingFrame", "TeacherGuide", frame, {BackgroundTransparency = 1,BorderSizePixel=0,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=4})
    text("Heading", guide, "Helper Guide", 20, UDim2.new(), UDim2.new(1, 0, 0, 28)).Font = Enum.Font.FredokaOne
    local guideBody = text("Message", guide, "", 18, UDim2.fromOffset(0, 36), UDim2.new(1, 0, 1, -36))
    guideBody.TextColor3, guideBody.TextYAlignment = muted, Enum.TextYAlignment.Top
    local feedback = text("Feedback", frame, "", 17, UDim2.new(0, 14, 1, -44), UDim2.new(1, -28, 0, 38))
    local resume = button("SchoolSolutionResume", gui, "My Solution", UDim2.new(.5, 0, 1, -16), UDim2.fromOffset(290, 48))
    resume.AnchorPoint, resume.Visible = Vector2.new(.5, 1), false
    self.Frame, self.Resume = frame, resume
    local sending, key = false, nil
    local function mode()
        local active = self.Active
        return active and (active.Phase == "verify" and "verify" or active.PendingChunk and active.PendingChunk.Step or "choose")
    end
    function self:Layout()
        local width = math.min(900, math.max(280, screenBounds.AbsoluteSize.X - 32))
        local stacked = width < 760
        local guideHeight=stacked and math.min(152,math.max(70,screenBounds.AbsoluteSize.Y-370)) or 220
        frame.Size = UDim2.fromOffset(width, stacked and 338+guideHeight or 314)
        work.Size = UDim2.fromOffset(stacked and width - 28 or width - 292, 220)
        local textWidth = work.Size.X.Offset - 18
        local textHeight = game:GetService("TextService"):GetTextSize(sums.Text, 19, Enum.Font.Code, Vector2.new(textWidth, 10000)).Y
        sums.Size = UDim2.new(1, -18, 0, textHeight + 6)
        guide.Position = stacked and UDim2.fromOffset(14, 282) or UDim2.new(1, -264, 0, 54)
        guide.Size = stacked and UDim2.fromOffset(width - 28, guideHeight) or UDim2.fromOffset(250, 220)
        local guideWidth=stacked and width-36 or 242
        local guideTextHeight=game:GetService("TextService"):GetTextSize(guideBody.Text,18,Enum.Font.GothamBold,Vector2.new(guideWidth,10000)).Y
        guideBody.Size=UDim2.new(1,-8,0,guideTextHeight+6)
        local valid = self.Active and self.Active.SchoolSolution and (self.Active.Phase == "chunking" or self.Active.Phase == "verify")
        frame.Visible = self.Available and valid and self.Open or false
        resume.Visible = self.Available and valid and not self.Open or false
    end
    function self:SetState(active)
        self.Active = active
        if not active then self:Layout(); return end
        local pending, current = active.PendingChunk, mode()
        local mission = MissionData.GetMissionForActive(active)
        local resource = mission and mission.Resource or "food packs"
        title.Text = "My Solution | " .. active.Dividend .. " / " .. active.Divisor
        remaining.Text = "Left to share: " .. active.Remaining
        each.Text = "Each classroom: " .. active.RunningQuotient
        local lines = {active.Divisor .. " | " .. active.Dividend}
        for _, chunk in ipairs(active.Chunks or {}) do
            table.insert(lines, "- " .. chunk.Amount .. "  (" .. active.Divisor .. " x " .. chunk.Quotient .. ")   left: " .. chunk.Remaining)
        end
        if pending then
            table.insert(lines, active.Divisor .. " x " .. pending.Multiplier .. " = " .. (pending.Product or "?"))
            if pending.Product then table.insert(lines, pending.Before .. " - " .. pending.Product .. " = " .. (pending.Leftover or "?")) end
        end
        sums.Text = table.concat(lines, "\n")
        presets.Visible, input.Visible, submit.Visible = current == "choose", current ~= "deliver", true
        input.Position = current == "choose" and UDim2.new(.48, 0, 0, 174) or UDim2.fromOffset(0, 174)
        input.Size = current == "choose" and UDim2.new(.27, -8, 0, 44) or UDim2.new(.75, -8, 0, 44)
        if current == "choose" then
            step.Text, submit.Text = "1. How many will you give EACH classroom?", "Set"
            guideBody.Text = "Choose a group you can count. Multiply it by the number of classrooms. Your group must fit the " .. resource .. " left. You can type your own number!"
        elseif current == "multiply" then
            step.Text, submit.Text = "2. " .. active.Divisor .. " x " .. pending.Multiplier .. " = ?", "Check"
            guideBody.Text = "Count equal shares for ALL classrooms. "..ChunkingMath.FactorHint(active.Divisor,pending.Multiplier)
        elseif current == "subtract" then
            step.Text, submit.Text = "3. " .. pending.Before .. " - " .. pending.Product .. " = ?", "Check"
            guideBody.Text = "Take away the supplies you will share. Subtract your group total from the supplies you started this trip with. How many will be left?"
        elseif current == "deliver" then
            local count = 0
            for _ in pairs(pending.Delivered) do count += 1 end
            step.Text, submit.Text = "4. Give " .. pending.Multiplier .. " " .. resource .. " to each classroom. " .. count .. " / " .. active.Divisor .. " visited", "Deliver!"
            resume.Text = "Delivery " .. count .. "/" .. active.Divisor .. " | My Solution"
            guideBody.Text = "Your " .. resource .. " are ready! Close this page and walk to each classroom supply box. Give every classroom the SAME group. Then choose your next group."
        else
            step.Text, submit.Text = "5. Check: " .. active.RunningQuotient .. " x " .. active.Divisor .. " = ?", "Finish"
            guideBody.Text = "Everyone has an equal share! Multiply the supplies in ONE classroom by ALL classrooms. Does your answer match the number you started with?"
        end
        if current ~= "deliver" then resume.Text = "My Solution" end
        local nextKey = active.Id .. ":" .. current .. ":" .. tostring(pending and pending.Token)
        if key ~= nextKey then input.Text, feedback.Text, key = "", "", nextKey; sheet.CanvasPosition = Vector2.new(0, math.huge) end
        self:Layout()
    end
    function self:Show(active) self.Open = true; self:SetState(active) end
    function self:Hide() self.Open = false; self:Layout() end
    function self:SetAvailable(value) self.Available = value; self:Layout() end
    local function send(action, number)
        if sending or not self.Active then return end
        if action == "deliver" then self:Hide(); return end
        if not tonumber(number) then feedback.Text = "Type a whole number, then press Check."; return end
        sending = true
        local active = self.Active
        local payload = action == "verify" and {Quotient = active.RunningQuotient, Divisor = active.Divisor,
            Remainder = active.Remaining, Dividend = tonumber(number)} or {Action = action, Number = tonumber(number), Token = active.PendingChunk and active.PendingChunk.Token}
        local result = options.Request(action == "verify" and "VerifyMission" or "SchoolStep", payload)
        sending = false
        if not result then feedback.Text = "Please try again. Your work is still here."; return end
        self:SetState(result.Profile and result.Profile.ActiveMission or result.ActiveMission or active)
        feedback.Text = result.Message or ""
        feedback.TextColor3 = result.Ok and Color3.fromRGB(29, 116, 57) or Color3.fromRGB(176, 53, 55)
        if options.OnChanged then options.OnChanged(result) end
        if result.Ok and self.Active and self.Active.Phase == "complete" then
            self:Hide()
            if options.OnComplete then options.OnComplete() end
        end
    end
    for index, number in ipairs({1, 2, 5, 10}) do
        local b = button("Times" .. number, presets, "x" .. number, UDim2.new((index - 1) / 4, 0, 0, 0), UDim2.new(.25, -4, 1, 0))
        b.Activated:Connect(function() send("choose", number) end)
    end
    submit.Activated:Connect(function() send(mode(), input.Text) end)
    input.FocusLost:Connect(function(enter) if enter and self.Active then send(mode(), input.Text) end end)
    close.Activated:Connect(function() self:Hide() end)
    resume.Activated:Connect(function() self:Show(self.Active) end)
    screenBounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() self:Layout() end)
    return self
end
return UI
