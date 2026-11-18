local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shared = ReplicatedStorage:WaitForChild("Brighthaven")
local data = require(shared:WaitForChild("MissionData"))
local requestRemote = shared:WaitForChild("Remotes"):WaitForChild("ClientRequest")
local campaignRemote = shared:WaitForChild("Campaign"):WaitForChild("Request")
local questData = require(shared.Campaign.QuestData)
local campaignData = require(shared.Campaign.CampaignData)
local captainLines, captainEnding, captainFollowup = data.CaptainDialogue, false, false
local function campaignRequest(action, payload)
    local ok, result = pcall(function() return campaignRemote:InvokeServer(action, payload or {}) end)
    return ok and result or nil
end
local locations = workspace:WaitForChild("BrighthavenPrototype"):WaitForChild("Locations_1_2")
local hall = locations:WaitForChild("Location1_BarangayHall")
local school = locations:WaitForChild("Location2_SchoolEvacuation")
local mainWorldEntrance = workspace:WaitForChild("Portal6"):WaitForChild("Teleport")
local profile, busy, view, dialogueIndex = nil, false, nil, 1
local lastActionAt = -math.huge
local colors = {
    ink = Color3.fromRGB(45, 70, 82), paper = Color3.fromRGB(255, 248, 214),
    green = Color3.fromRGB(39, 132, 74), blue = Color3.fromRGB(52, 142, 202),
    yellow = Color3.fromRGB(255, 199, 76), muted = Color3.fromRGB(76, 104, 119),
    outline = Color3.fromRGB(255, 180, 76), sky = Color3.fromRGB(226, 244, 255),
    title = Color3.fromRGB(24, 47, 62),
}
local dialogueFont = Enum.Font.GothamBold
local headingFont = Enum.Font.GothamBlack
local function make(class, props, parent)
    local item = Instance.new(class)
    for key, value in pairs(props) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, item)
end
local function dialogueSurface(item)
    item.BackgroundColor3 = colors.paper
    item.BackgroundTransparency = 0.02
    round(item, 16)
    make("UIStroke", {Color = colors.outline, Thickness = 3}, item)
    make("UIGradient", {
        Color = ColorSequence.new(colors.paper, colors.sky), Rotation = 10,
    }, item)
end
local gui = make("ScreenGui", {
    Name = "BrighthavenLocation12", ResetOnSpawn = false,
    DisplayOrder = 45, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Enabled = false,
}, playerGui)
local screenBounds = make("Frame", {
    Name = "ScreenBounds", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
}, gui)
local function dialogueBounds()
    local size = screenBounds.AbsoluteSize
    local wide = size.X >= 700
    local width = math.min(720, math.max(240, wide and size.X * 0.46 or size.X - 32))
    local bottom = playerGui:GetAttribute("BrightHavenGuideVisible") == true and 0.76 or 0.95
    return width, UDim2.fromScale(wide and 0.56 or 0.5, bottom), math.max(164, size.Y * bottom - 16)
end
local captainDialogue = make("Frame", {
    Name = "CaptainDialogue", AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.fromScale(0.56, 0.95), Size = UDim2.fromOffset(540, 164),
    BackgroundColor3 = colors.paper, BorderSizePixel = 0, Visible = false,
}, gui)
dialogueSurface(captainDialogue)
local captainBadge = make("TextLabel", {
    Name = "SpeakerBadge", Position = UDim2.fromOffset(18, 20), Size = UDim2.fromOffset(74, 74),
    BackgroundColor3 = colors.yellow, BorderSizePixel = 0,
    Text = "KP", Font = headingFont, TextColor3 = colors.title, TextScaled = true,
}, captainDialogue)
round(captainBadge, 14)
make("TextLabel", {
    Name = "Speaker", Position = UDim2.fromOffset(112, 18), Size = UDim2.new(1, -174, 0, 28),
    BackgroundTransparency = 1, Text = "Captain Kappa", Font = headingFont,
    TextSize = 22, TextColor3 = colors.title, TextXAlignment = Enum.TextXAlignment.Left,
    TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Center,
}, captainDialogue)
local captainClose = make("TextButton", {
    Name = "Close", Position = UDim2.new(1, -54, 0, 12), Size = UDim2.fromOffset(44, 44),
    BackgroundTransparency = 1, BorderSizePixel = 0, Text = "X", Font = headingFont,
    TextSize = 18, TextColor3 = colors.title,
}, captainDialogue)
local captainBody = make("ScrollingFrame", {
    Name = "Body", Position = UDim2.fromOffset(112, 52), Size = UDim2.new(1, -132, 1, -114),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, captainDialogue)
local captainMessage = make("TextLabel", {
    Name = "Message", Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1, Text = "", Font = dialogueFont, TextSize = 18,
    LineHeight = 1.15, TextColor3 = colors.ink, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, captainBody)
local captainBack = make("TextButton", {
    Name = "PreviousDialogue", Position = UDim2.new(0, 18, 1, -54), Size = UDim2.fromOffset(44, 44),
    BackgroundColor3 = colors.blue, BorderSizePixel = 0,
    Text = "<", Font = headingFont, TextSize = 20, TextColor3 = Color3.new(1, 1, 1),
}, captainDialogue)
round(captainBack)
local captainPage = make("TextLabel", {
    Name = "Page", Position = UDim2.new(0, 72, 1, -54), Size = UDim2.fromOffset(58, 44),
    BackgroundTransparency = 1, Text = "1 of 3", Font = dialogueFont,
    TextSize = 14, TextColor3 = colors.ink,
}, captainDialogue)
local captainContinue = make("TextButton", {
    Name = "ContinueDialogue", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -28, 1, -54),
    Size = UDim2.fromOffset(126, 44), BackgroundColor3 = colors.blue, BorderSizePixel = 0,
    Text = "Next", Font = headingFont, TextSize = 18, TextColor3 = Color3.new(1, 1, 1),
}, captainDialogue)
round(captainContinue)
local previousTooltip = make("TextLabel", {
    Name = "Tooltip", Position = UDim2.new(0, 16, 1, -82), Size = UDim2.fromOffset(90, 24),
    BackgroundColor3 = colors.title, TextColor3 = colors.paper, Text = "Go back",
    Font = dialogueFont, TextSize = 13, BorderSizePixel = 0, Visible = false, ZIndex = 3,
}, captainDialogue)
captainBack.MouseEnter:Connect(function() previousTooltip.Visible = true end)
captainBack.MouseLeave:Connect(function() previousTooltip.Visible = false end)
captainContinue.MouseEnter:Connect(function() captainContinue.BackgroundColor3 = Color3.fromRGB(40, 122, 179) end)
captainContinue.MouseLeave:Connect(function() captainContinue.BackgroundColor3 = colors.blue end)
local function layoutCaptain()
    local width, position, available = dialogueBounds()
    local speaker = captainDialogue.Speaker
    local titleHeight = math.max(48, TextService:GetTextSize(speaker.Text, 22, headingFont, Vector2.new(width - 150, 1000)).Y)
    captainBadge.Position, captainBadge.Size = UDim2.fromOffset(18, 14), UDim2.fromOffset(56, 56)
    speaker.Position, speaker.Size = UDim2.fromOffset(90, 16), UDim2.new(1, -150, 0, titleHeight)
    local top = math.max(84, titleHeight + 34)
    captainBody.Position, captainBody.Size = UDim2.fromOffset(18, top), UDim2.new(1, -36, 1, -top - 76)
    local measured = TextService:GetTextSize(captainMessage.Text, 18, dialogueFont, Vector2.new(width - 44, 2000))
    captainDialogue.Size = UDim2.fromOffset(width, math.min(math.max(210, top + 82 + measured.Y * 1.15), available))
    captainContinue.Size = UDim2.fromOffset(math.min(190, width - 166), 48)
    captainContinue.Position = UDim2.new(1, -18, 1, -58)
    captainContinue.TextWrapped = true
    captainBack.Size, captainBack.Position = UDim2.fromOffset(48, 48), UDim2.new(0, 18, 1, -58)
    captainDialogue.Position = position
end
screenBounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutCaptain)
playerGui:GetAttributeChangedSignal("BrightHavenGuideVisible"):Connect(layoutCaptain)
local panel = make("Frame", {
    Name = "MissionPanel", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(0.56, 0.95),
    Size = UDim2.fromOffset(540, 220), BackgroundColor3 = colors.paper, BorderSizePixel = 0,
    Visible = false,
}, gui)
dialogueSurface(panel)
local schoolBadge = make("TextLabel", {
    Name = "SpeakerBadge", Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(56, 56),
    BackgroundColor3 = colors.yellow, BorderSizePixel = 0, Text = "SH",
    Font = headingFont, TextColor3 = colors.title, TextScaled = true,
}, panel)
round(schoolBadge, 14)
local heading = make("TextLabel", {
    Name = "Heading", BackgroundTransparency = 1, Position = UDim2.fromOffset(90, 16),
    Size = UDim2.new(1, -150, 0, 40), Font = headingFont, TextSize = 22,
    TextColor3 = colors.title, TextXAlignment = Enum.TextXAlignment.Left, TextWrapped = true,
    Text = "School Evacuation",
}, panel)
local close = make("TextButton", {
    Name = "Close", BackgroundTransparency = 1, Position = UDim2.new(1, -54, 0, 10),
    Size = UDim2.fromOffset(44, 44), Font = Enum.Font.GothamBold, Text = "X",
    TextSize = 18, TextColor3 = colors.title,
}, panel)
local content = make("ScrollingFrame", {
    Name = "Content", Position = UDim2.fromOffset(18, 82), Size = UDim2.new(1, -36, 1, -96),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4,
    AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
}, panel)
local feedback = make("TextLabel", {
    Name = "Feedback", BackgroundTransparency = 1, Position = UDim2.new(0, 18, 1, -70),
    Size = UDim2.new(1, -36, 0, 56), Font = dialogueFont, TextSize = 18,
    TextColor3 = colors.green, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, Text = "",
}, panel)
local function layoutMissionPanel()
    local width, position, available = dialogueBounds()
    local layout = content:FindFirstChildWhichIsA("UIListLayout")
    local titleHeight = math.max(48, TextService:GetTextSize(heading.Text, 22, headingFont, Vector2.new(width - 150, 1000)).Y)
    heading.Size = UDim2.new(1, -150, 0, titleHeight)
    local top = math.max(82, titleHeight + 34)
    local footer = feedback.Text ~= "" and math.max(50, TextService:GetTextSize(feedback.Text, 18, dialogueFont, Vector2.new(width - 36, 1000)).Y) + 20 or 14
    local desired = top + footer + (layout and layout.AbsoluteContentSize.Y or 100)
    panel.Position = position
    panel.Size = UDim2.fromOffset(width, math.min(math.max(190, desired), 520, available))
    content.Position, content.Size = UDim2.fromOffset(18, top), UDim2.new(1, -36, 1, -top - footer)
    feedback.Position, feedback.Size = UDim2.new(0, 18, 1, -footer + 6), UDim2.new(1, -36, 0, footer - 14)
    feedback.Visible = feedback.Text ~= ""
end
screenBounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutMissionPanel)
playerGui:GetAttributeChangedSignal("BrightHavenGuideVisible"):Connect(layoutMissionPanel)
feedback:GetPropertyChangedSignal("Text"):Connect(layoutMissionPanel)
local function clear(title)
    captainDialogue.Visible = false
    previousTooltip.Visible = false
    heading.Text = title
    schoolBadge.Text = view == "travel" and "KP" or view == "radio" and "KN" or "SH"
    local speaker=view=="radio" and workspace.BrighthavenStoryExtension.dumpsite.StoryHelper
        or view=="travel" and hall.CaptainKappa or school.EvacuationVolunteer
    require(ReplicatedStorage.Brighthaven.Campaign.KidUI).Portrait(schoolBadge,speaker)
    feedback.Text = ""
    for _, item in ipairs(content:GetChildren()) do item:Destroy() end
    local layout = make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layoutMissionPanel)
    content.CanvasPosition = Vector2.zero
    panel.Visible = true
end
local function label(text, height, bold)
    return make("TextLabel", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, height or 56),
        Text = text, TextColor3 = colors.ink, Font = bold and headingFont or dialogueFont,
        TextSize = bold and 20 or 18, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
    }, content)
end
local function paragraph(text)
    local item = label(text, 0)
    item.AutomaticSize = Enum.AutomaticSize.Y
    item.TextYAlignment = Enum.TextYAlignment.Top
    return item
end
local function equation(text)
    local item = paragraph(text)
    item.Font = headingFont
    item.TextSize = 18
    return item
end
local function button(name, text, callback, color)
    local item = make("TextButton", {
        Name = name, Size = UDim2.new(1, -6, 0, 52), Text = text, TextSize = 18,
        Font = headingFont, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true,
        BackgroundColor3 = color or colors.blue, BorderSizePixel = 0,
    }, content)
    round(item)
    local function fit()
        local h = TextService:GetTextSize(text, 18, headingFont, Vector2.new(math.max(100, item.AbsoluteSize.X - 18), 1000)).Y
        item.Size = UDim2.new(1, -6, 0, math.max(52, h + 22))
    end
    item:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    task.defer(fit)
    item.Activated:Connect(function()
        if busy or os.clock() - lastActionAt < 0.35 then return end
        lastActionAt = os.clock()
        callback()
    end)
    return item
end
local function request(action, payload)
    if busy then return nil end
    busy = true
    local ok, result = pcall(function() return requestRemote:InvokeServer(action, payload or {}) end)
    busy = false
    if not ok or type(result) ~= "table" then
        feedback.Text = "Oops! We could not reach the helper. Please try again."
        feedback.TextColor3 = Color3.fromRGB(174, 51, 61)
        return nil
    end
    if result.Profile then profile = result.Profile end
    if action ~= "GetProfile" then
        feedback.Text = result.Message or ""
        feedback.TextColor3 = result.Ok and colors.green or Color3.fromRGB(174, 51, 61)
    end
    return result
end
local function activeMission()
    return profile and profile.ActiveMission
end
local function chunksText(active)
    local parts = {}
    for _, chunk in ipairs(active.Chunks or {}) do table.insert(parts, tostring(chunk.Quotient)) end
    return table.concat(parts, " + ")
end
local function setBillboard(part, title, body)
    local billboard = part and part:FindFirstChild("LocationBillboard")
    if not billboard then return end
    local labels = {}
    for _, item in ipairs(billboard:GetDescendants()) do
        if item:IsA("TextLabel") then table.insert(labels, item) end
    end
    table.sort(labels, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
    if labels[1] then labels[1].Text = title end
    if labels[2] then labels[2].Text = body end
end
local function setPropVisible(prop, visible)
    if prop:IsA("BasePart") then prop.LocalTransparencyModifier = visible and 0 or 1 end
    for _, item in ipairs(prop:GetDescendants()) do
        if item:IsA("BasePart") then item.LocalTransparencyModifier = visible and 0 or 1
        elseif item:IsA("SurfaceGui") then item.Enabled = visible end
    end
end
local function supplyTemplate(mission)
    local name = mission.Resource == "water bottles" and "ReliefWaterBottle"
        or mission.Resource == "care kits" and "ReliefCareKit" or "ReliefFoodPack"
    return shared:WaitForChild(name)
end
local function resourceName(mission, count)
    return count == 1 and mission.ResourceSingular or mission.Resource
end
local function updateWorld(active)
    local roundStarted = active ~= nil
    active = active or {Id = "school_evacuation_144_6", Divisor = 6, RunningQuotient = 0,
        Remaining = 144, Dividend = 144}
    local mission = data.GetMissionForActive(active)
    setBillboard(school.SchoolMissionBoard, roundStarted and mission.Title or "Food for the School",
        roundStarted and (active.Dividend .. " " .. mission.Resource .. " for " .. active.Divisor .. " classrooms")
            or "Share food packs among 6 classrooms.")
    for index = 1, 7 do
        local tent = school:FindFirstChild("ClassroomTent_" .. index)
        if tent then
            local visible = index <= active.Divisor
            setPropVisible(tent, visible)
            local amount = active.ClassroomAmounts and active.ClassroomAmounts[index] or active.RunningQuotient
            local pending=active.PendingChunk
            local delivering=pending and pending.Step=="deliver"
            local needs=delivering and not pending.Delivered[tostring(index)] and pending.Multiplier or 0
            local status="Plan your next equal chunk"
            if not roundStarted then status="Talk to the School Helper"
            elseif active.Phase=="complete" or active.Phase=="verify" then status="0 needed - all supplied!"
            elseif delivering then status=needs>0 and (needs.." needed this trip") or "0 needed - delivered!" end
            setBillboard(tent:FindFirstChild("TentLabelPost"), "Classroom " .. index,
                status.."\n"..tostring(amount).." received")
            local sign=tent.TentLabelPost:FindFirstChild("LocationBillboard")
            if sign then
                sign.Size=UDim2.fromOffset(200,82);sign.MaxDistance=48
                local frame=sign:FindFirstChildWhichIsA("Frame")
                if frame then
                    frame.Title.Size=UDim2.new(1,-20,0,22)
                    frame.Body.Position=UDim2.fromOffset(10,30);frame.Body.Size=UDim2.new(1,-20,0,44)
                    frame.Body.TextSize=14;frame.Body.TextWrapped=true
                end
            end
        end
    end
    local stacks = school:FindFirstChild("FoodTrayStacks_144")
    if stacks then
        setBillboard(stacks:FindFirstChild("FoodTrayCounter"),
            roundStarted and (active.Remaining .. " " .. resourceName(mission, active.Remaining) .. " left") or "Food Packs",
            roundStarted and "Give each classroom the same number." or "Talk to the School Helper to start.")
        local count = math.ceil(active.Remaining / active.Dividend * 12)
        for index = 1, 12 do
            local stack = stacks:FindFirstChild("FoodTrayStack_" .. index)
            if stack then
                if stack:GetAttribute("Resource") ~= mission.Resource then
                    local base = stack:GetAttribute("SupplyBasePosition")
                    stack:Destroy()
                    stack = supplyTemplate(mission):Clone()
                    stack.Name = "FoodTrayStack_" .. index
                    stack:SetAttribute("SupplyBasePosition", base)
                    stack:PivotTo(CFrame.new(base + Vector3.new(0, stack:GetAttribute("CenterHeight"), 0)))
                    stack.Parent = stacks
                end
                setPropVisible(stack, index <= count)
            end
        end
    end
end
local function animateDelivery(active, classroomIndex)
    local source = school.FoodTrayStacks_144.FoodTrayCounter.Position + Vector3.new(0, 2, 0)
    for index = 1, active.Divisor do
        local tent = school:FindFirstChild("ClassroomTent_" .. index)
        if tent and (not classroomIndex or index == classroomIndex) then
            local mission = data.GetMissionForActive(active)
            local pack = supplyTemplate(mission):Clone()
            pack.Name = "ReliefDelivery"
            pack:PivotTo(CFrame.new(source))
            pack.Parent = workspace
            local position = make("CFrameValue", {Value = pack:GetPivot()}, pack)
            local connection = position.Changed:Connect(function(value) pack:PivotTo(value) end)
            local tween = TweenService:Create(position, TweenInfo.new(0.65, Enum.EasingStyle.Quad), {
                Value = CFrame.new(tent.TentBase.Position + Vector3.new(0, 3.2, 0)),
            })
            tween.Completed:Once(function() connection:Disconnect(); pack:Destroy() end)
            tween:Play()
        end
    end
end
local renderMission, renderBoard, renderCaptain
local function meetTruckDriver()
    captainDialogue.Visible=false
    view="radio"
    clear("Walkie-Talkie")
    paragraph("Calling the Recycling Yard...")
    local result=campaignRequest("CallTruckDriver")
    if not result or not result.Ok then
        clear("Walkie-Talkie")
        paragraph(result and result.Message or "The radio did not connect. Please try again.")
        button("RetryRadio","Call Again",meetTruckDriver)
        return
    end
    local page=1
    local lines={
        "Kuya Nestor here! I drive the recycling truck. Thank you for sharing food fairly with the families!",
        "Our yard is full of things we can use again. Help me sort them into equal groups. We may find a part for Dr. Liza's Storm Stopper!",
        "Come meet me at the Recycling Yard. Would you like a tricycle ride? It costs 10 coins. Walk to the school gate for pickup.",
    }
    local function show()
        clear("Kuya Nestor | Radio Call")
        paragraph(lines[page])
        if page<#lines then
            button("NextRadioPage","Next",function() page+=1;show() end)
        else
            if not result.ActivityUnlocked then paragraph(result.ActivityGuidance) end
            button("CallNestorTricycle","Call a Tricycle - 10 Coins",function()
                if busy then return end
                busy=true
                local ok,ride=pcall(function()
                    return shared.Transit.TaxiRequest:InvokeServer("Call",{Kind="Tricycle",Destination="dumpsite"})
                end)
                busy=false
                if ok and ride and ride.Ok then panel.Visible=false;view=nil
                else
                    show()
                    paragraph(ok and ride and ride.Message or "The driver could not answer. Please try again.")
                end
            end)
            button("WalkToNestor","I'll Walk",function()
                playerGui:SetAttribute("QuestPingKind","location")
                playerGui:SetAttribute("QuestPingId","dumpsite")
                panel.Visible=false;view=nil
            end)
        end
    end
    show()
end
local solution = require(shared:WaitForChild("SchoolSolutionUI")).Create(gui, screenBounds, {
    Request = request,
    OnChanged = function(result) if result.Ok then updateWorld(activeMission()) end end,
    OnComplete = function() renderMission() end,
})
renderCaptain = function()
    view = "captain"
    panel.Visible = false
    captainMessage.Text = captainLines[dialogueIndex]
    captainPage.Text = tostring(dialogueIndex) .. " of " .. #captainLines
    captainBack.Visible = dialogueIndex > 1
    previousTooltip.Visible = false
    captainContinue.Text = dialogueIndex < #captainLines and "Next" or captainEnding and "We Did It!"
        or player:GetAttribute("BarangayFlashbackSeen") ~= true and "Let's Help!" or captainFollowup and "Keep Helping" or "Let's Help"
    require(ReplicatedStorage.Brighthaven.Campaign.KidUI).Portrait(captainBadge, hall.CaptainKappa)
    captainBody.CanvasPosition = Vector2.zero
    layoutCaptain()
    captainDialogue.Visible = true
end
captainBack.Activated:Connect(function()
    if busy or dialogueIndex <= 1 or os.clock() - lastActionAt < 0.35 then return end
    lastActionAt = os.clock()
    dialogueIndex -= 1
    renderCaptain()
end)
local function showShuttleDirections(flashbackToken)
    captainDialogue.Visible = false
    panel.Visible = false
    view = nil
    if flashbackToken then
        busy = true
        local ok, outcome = pcall(function()
            return require(shared:WaitForChild("BarangayFlashback")).Play(flashbackToken)
        end)
        busy = false
        if not ok then
            warn("[BrightHaven Flashback]", outcome)
            pcall(function() shared.Remotes.FlashbackRequest:InvokeServer("Finish", {Token = flashbackToken, Outcome = "abort"}) end)
        end
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 or ok and outcome == "abort" then return end
    end
    view = "travel"
    clear("Your School Ride")
    paragraph("Driver Lito is waiting at the blue school shuttle. Walk to its side door and get on.")
    button("FindShuttle", "Let's Go!", function()
        panel.Visible = false; view = nil
        playerGui:SetAttribute("SideQuestFocus", false)
    end, colors.blue)
end
captainContinue.Activated:Connect(function()
    if busy or os.clock() - lastActionAt < 0.35 then return end
    lastActionAt = os.clock()
    if dialogueIndex < #captainLines then
        dialogueIndex += 1
        renderCaptain()
        return
    end
    if captainFollowup then
        local briefing = request("CompleteTutorial")
        if not briefing or not briefing.Ok then
            captainMessage.Text = briefing and briefing.Message or "Please talk to me at Barangay Hall."
            return
        end
        local current = campaignRequest("GetState")
        if current and current.State and questData.Current(current.State).Id == "school" then
            showShuttleDirections(briefing.FlashbackToken)
            return
        end
        local ride = campaignRequest("CaptainRide")
        if ride and ride.Ok then captainDialogue.Visible = false; view = nil
        else captainMessage.Text = ride and ride.Message or "Please try again." end
        return
    end
    if captainEnding then
        local ending = campaignRequest("FinishStory")
        if ending and ending.Ok then
            captainDialogue.Visible = false
            view = "ending"
            clear("Thank You, Helper!")
            paragraph(ending.Message)
            paragraph("Your quest book has all 10 chapters. You can explore or share more supplies at the school.")
            button("ExploreTown", "Explore BrightHaven", function() panel.Visible = false; view = nil end, colors.blue)
        else captainMessage.Text = ending and ending.Message or "Please try that again." end
        return
    end
    local result = request("CompleteTutorial")
    if result and result.Ok then
        showShuttleDirections(result.FlashbackToken)
    elseif result then
        captainMessage.Text = result.Message or "Please talk to me at Barangay Hall."
        layoutCaptain()
    end
end)
renderBoard = function()
    view = "board"
    request("GetProfile")
    clear("School Helper")
    local active = activeMission()
    updateWorld(active)
    if active and active.Phase ~= "complete" then
        local mission = data.GetMissionForActive(active)
        paragraph("Let's finish sharing the " .. mission.Resource .. ". Each classroom needs the same number.")
        button("ResumeMission", "Keep Sharing", renderMission)
        return
    end
    paragraph(data.VolunteerDialogue)
    if profile and profile.CompletedMissionIds.school_evacuation_144_6 then
        paragraph("The families have their food. Your next story job is at the Recycling Yard. You can also share extra supplies here.")
        button("NextStoryQuest", "Call Kuya Nestor", meetTruckDriver, colors.blue)
    end
    for _, mission in ipairs(data.Missions) do
        local unlocked = not mission.RequiresMission or (profile and profile.CompletedMissionIds[mission.RequiresMission])
        if unlocked then
            local title = "Share " .. mission.Resource
            button("Start_" .. mission.Id, title, function()
                local result = request("StartMission", {MissionId = mission.Id})
                if result and result.Ok then renderMission() end
            end, colors.blue)
        end
    end
end
renderMission = function()
    view = "mission"
    local active = activeMission()
    if not active then renderBoard(); return end
    if active.SchoolSolution and (active.Phase == "chunking" or active.Phase == "verify") then
        panel.Visible, captainDialogue.Visible = false, false
        updateWorld(active)
        solution:Show(active)
        return
    end
    solution:Hide()
    local mission = data.GetMissionForActive(active)
    clear(mission.Title or mission.District)
    updateWorld(active)
    if active.Phase == "briefing" then
        paragraph(mission.Story)
        paragraph("Choose a group for each classroom. Multiply to count the whole group. Subtract to find what is left. Then carry the " .. mission.Resource .. " to the classroom supply boxes!")
        button("BeginMission", "Start Sharing", function()
            local result = request("BeginMission")
            if result and result.Ok then renderMission() end
        end)
    elseif active.Phase == "chunking" then
        equation(#active.Chunks == 0 and "1. Give the Same Number" or "2. Share What Is Left")
        paragraph("Left to share: " .. active.Remaining .. " " .. resourceName(mission, active.Remaining))
        local grid = make("Frame", {Name = "ClassroomCounters", BackgroundTransparency = 1,
            Size = UDim2.new(1, -6, 0, math.ceil(active.Divisor / 3) * 62 - 6)}, content)
        make("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 0, 56), CellPadding = UDim2.fromOffset(6, 6)}, grid)
        for index = 1, active.Divisor do
            local counter = make("TextLabel", {Name = "Classroom" .. index,
                BackgroundColor3 = colors.sky, BorderSizePixel = 0,
                Font = dialogueFont, TextSize = 16, TextColor3 = colors.ink, TextWrapped = true,
                Text = "Classroom " .. index .. "\n" .. active.RunningQuotient .. " " .. resourceName(mission, active.RunningQuotient)}, grid)
            round(counter, 8)
        end
        if #active.Chunks > 0 then
            local last = active.Chunks[#active.Chunks]
            paragraph("You gave " .. last.Quotient .. " to each classroom.\n" .. active.Divisor .. " x " .. last.Quotient .. " = " .. last.Amount .. " shared.")
        end
        local offered = {}
        local choices = {mission.ChunkPlan[1], 20, 10, mission.ChunkPlan[2], 5, 2, 1}
        for _, q in ipairs(choices) do
            if q > 0 and not offered[q] and q * active.Divisor <= active.Remaining then
                offered[q] = true
                button("Chunk" .. q, "Give " .. q .. " " .. resourceName(mission, q) .. " to each classroom", function()
                    local result = request("SubmitChunk", {ChunkQuotient = q})
                    if result and result.Ok then animateDelivery(result.ActiveMission); renderMission() end
                end, colors.blue)
            end
        end
        button("Hint", "Show Me a Hint", function() request("UseHint") end, colors.muted)
    elseif active.Phase == "verify" then
        equation("3. Check Your Sharing")
        paragraph("Add the numbers you gave to each classroom:")
        equation(chunksText(active) .. " = " .. active.RunningQuotient)
        paragraph("Each classroom has " .. active.RunningQuotient .. " " .. mission.Resource .. ".\nCheck all " .. active.Divisor .. " classrooms:")
        equation(active.RunningQuotient .. " x " .. active.Divisor .. " = " .. active.Dividend)
        paragraph("That matches the number we started with. Nothing is left!")
        button("VerifyMission", "Check My Sharing", function()
            local result = request("VerifyMission", {Quotient = active.RunningQuotient, Divisor = active.Divisor,
                Remainder = 0, Dividend = active.Dividend})
            if result and result.Ok then panel.Visible=false;view=nil end
        end)
    elseif active.Phase == "complete" then
        equation("You Did It!")
        paragraph(mission.PostDialogue)
        paragraph("All " .. active.Divisor .. " classrooms have the same number. There are 0 left.")
        paragraph("You earned " .. tostring(active.CoinsEarned or 0) .. " coins and " .. tostring(active.XPEarned or 0) .. " XP!")
        if active.Id == "school_evacuation_144_6" then
            button("NextStoryQuest", "Call Kuya Nestor", meetTruckDriver, colors.blue)
        end
        button("MoreSchoolSupplies", "Share More Supplies", renderBoard, colors.blue)
        button("ReturnToSchool", "Back to the School", function() panel.Visible = false; view = nil end)
    end
end
close.Activated:Connect(function() panel.Visible = false; view = nil end)
captainClose.Activated:Connect(function()
    captainDialogue.Visible = false
    previousTooltip.Visible = false
    view = nil
end)
local nearbyClassroom
local deliveryButton = make("TextButton", {
    Name="SchoolDeliveryAction", AnchorPoint=Vector2.new(.5,1), Position=UDim2.new(.5,0,1,-82),
    Size=UDim2.fromOffset(330,52), BackgroundColor3=colors.green, BorderSizePixel=0,
    TextColor3=Color3.new(1,1,1), Font=headingFont, TextSize=18, TextWrapped=true, Visible=false,
},gui)
round(deliveryButton)
local function deliverClassroom(index)
    local active=activeMission()
    local pending=active and active.PendingChunk
    if not pending or pending.Step~="deliver" or pending.Delivered[tostring(index)] then return end
    local result=request("SchoolStep",{Action="deliver",Number=index,Token=pending.Token})
    if result and result.Ok then
        solution:Hide()
        animateDelivery(result.ActiveMission,index)
        updateWorld(activeMission())
    end
    solution:SetState(activeMission())
    if result and result.Ok and not activeMission().PendingChunk then solution:Show(activeMission()) end
end
deliveryButton.Activated:Connect(function() if nearbyClassroom then deliverClassroom(nearbyClassroom) end end)
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer and triggeringPlayer ~= player then return end
    local classroomIndex = prompt:GetAttribute("SchoolDeliveryIndex")
    if classroomIndex then deliverClassroom(classroomIndex); return end
    local action = prompt.Parent:GetAttribute("BrightHavenAction")
    if action == "tutorial" and prompt:IsDescendantOf(hall) then
        local result = campaignRequest("GetState")
        captainEnding = result and result.State and result.State.Victory == true or false
        captainFollowup = not captainEnding and result and result.State and result.State.CaptainBriefed == true or false
        captainLines = captainEnding and data.CaptainEnding or data.CaptainDialogue
        if captainFollowup then
            local quest = questData.Current(result.State)
            captainLines = {"Welcome back, helper! Our town is making progress, one kind job at a time.",
                quest.Why, questData.Objective(result.State, campaignData)}
            if quest.Id == "school" then
                table.insert(captainLines, "Driver Lito can take you to school. Walk to the blue shuttle and get on at its side door.")
            end
        end
        if not captainEnding and player:GetAttribute("BarangayFlashbackSeen") ~= true then
            captainLines = table.clone(captainLines)
            table.insert(captainLines, "Every family needs food and clean water for the next typhoon. Equal sharing means no one is left out. This is why our town needs your help.")
        end
        dialogueIndex = 1; renderCaptain()
    elseif action == "missionBoard" and prompt:IsDescendantOf(school) then
        if profile and profile.TutorialComplete and player:GetAttribute("CaptainMetThisVisit") == true then renderBoard()
        else clear("School Helper"); paragraph("Talk to Captain Kappa at Barangay Hall first. Then come back to help us.") end
    end
end)

updateWorld(activeMission())
local schoolLabels = {}
for _, item in ipairs(school:GetDescendants()) do
    if item:IsA("BillboardGui") and item.Parent:IsA("BasePart") then
        table.insert(schoolLabels, {
            gui = item, part = item.Parent,
            tentIndex = tonumber(string.match(item.Parent.Parent.Name, "^ClassroomTent_(%d+)$")),
            radius = item:GetAttribute("VisibilityRadius") or 14,
        })
        item.Enabled = false
    end
end
local function updateNearbySchoolLabels(root)
    local candidates = {}
    local camera = workspace.CurrentCamera
    local active = activeMission()
    local tentCount = active and active.Divisor or 6
    for _, entry in ipairs(schoolLabels) do
        entry.gui.Enabled = false
        entry.gui.AlwaysOnTop = true
        if root and camera and not panel.Visible and not captainDialogue.Visible
            and (not entry.tentIndex or entry.tentIndex <= tentCount) then
            local distance = (root.Position - entry.part.Position).Magnitude
            local point, onScreen = camera:WorldToViewportPoint(entry.part.Position + entry.gui.StudsOffsetWorldSpace)
            if distance <= entry.radius and onScreen and point.Z > 0 then
                local size = Vector2.new(entry.gui.Size.X.Offset, entry.gui.Size.Y.Offset)
                local min = Vector2.new(point.X, point.Y) - size / 2
                local max = Vector2.new(point.X, point.Y) + size / 2
                if min.X >= 8 and min.Y >= 64 and max.X <= camera.ViewportSize.X - 8
                    and max.Y <= camera.ViewportSize.Y - 8 then
                    table.insert(candidates, {entry = entry, distance = distance, min = min, max = max})
                end
            end
        end
    end
    table.sort(candidates, function(a, b) return a.distance < b.distance end)
    local shown, tentShown, landmarkShown = {}, false, false
    for _, candidate in ipairs(candidates) do
        local blocked = candidate.entry.tentIndex and tentShown or not candidate.entry.tentIndex and landmarkShown
        for _, other in ipairs(shown) do
            if candidate.min.X < other.max.X + 16 and candidate.max.X > other.min.X - 16
                and candidate.min.Y < other.max.Y + 12 and candidate.max.Y > other.min.Y - 12 then
                blocked = true
            end
        end
        if not blocked and #shown < 2 then
            candidate.entry.gui.Enabled = true
            table.insert(shown, candidate)
            if candidate.entry.tentIndex then tentShown = true else landmarkShown = true end
        end
    end
end

-- Show a destination beacon without drawing a route through buildings.
local attachment = make("Attachment", {Name = "ReliefDestination"}, hall.CaptainKapaPrompt)
local beam = make("Beam", {
    Name = "ReliefRoute", Attachment1 = attachment, Width0 = 0.12, Width1 = 0.28,
    FaceCamera = true, Color = ColorSequence.new(colors.yellow),
    Transparency = NumberSequence.new(0.25), Segments = 8, Enabled = false,
}, attachment)
local timer = 0
local hiddenTutorialArrow, tutorialArrowWasEnabled
local trackedCharacter, mainWorldArrived = nil, false
RunService.Heartbeat:Connect(function(dt)
    timer += dt
    if timer < 0.2 then return end
    timer = 0
    local character = player.Character
    if character ~= trackedCharacter then
        trackedCharacter = character
        mainWorldArrived = false
        panel.Visible = false
        captainDialogue.Visible = false
        previousTooltip.Visible = false
        view = nil
    end
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local inLocations = root and (
        (root.Position - hall.CaptainKapaPrompt.Position).Magnitude < 160
        or (root.Position - school.SchoolVolunteerPrompt.Position).Magnitude < 160
    )
    -- Portal6 is the arrival point after the last tutorial portal.
    if root and ((root.Position - mainWorldEntrance.Position).Magnitude < 100 or inLocations) then
        mainWorldArrived = true
    end
    if captainDialogue.Visible and (not root or (root.Position - hall.CaptainKapaPrompt.Position).Magnitude > 16) then
        captainDialogue.Visible = false
        previousTooltip.Visible = false
        view = nil
    end
    local questGui = playerGui:FindFirstChild("BrightHavenQuests")
    local sideGui = playerGui:FindFirstChild("BrightHavenSideDialogue")
    local journal = questGui and questGui:FindFirstChild("QuestBook")
    local sidePanel = sideGui and sideGui:FindFirstChild("Dialogue")
    local blocked = panel.Visible or captainDialogue.Visible or playerGui:GetAttribute("WorldMapOpen")
        or playerGui:GetAttribute("SchoolShuttleUIOpen")
        or journal and journal.Visible or sidePanel and sidePanel.Visible
    solution:SetAvailable(root ~= nil and player:GetAttribute("CaptainMetThisVisit") == true
        and not blocked and (root.Position - school.SchoolVolunteerPrompt.Position).Magnitude < 100)
    gui.Enabled = root ~= nil and (panel.Visible or captainDialogue.Visible or solution.Frame.Visible or solution.Resume.Visible)
    local active = activeMission()
    local pending = active and active.PendingChunk
    for _, prompt in ipairs(school:GetDescendants()) do
        if prompt:IsA("ProximityPrompt") and prompt.Parent:GetAttribute("BrightHavenAction") == "missionBoard" then
            prompt.Enabled = not pending or pending.Step ~= "deliver"
        end
    end
    for index = 1, 7 do
        local tent = school:FindFirstChild("ClassroomTent_" .. index)
        local target = tent and (tent:FindFirstChild("SchoolDeliveryTarget") or tent.TentLabelPost)
        local prompt = target and target:FindFirstChild("SchoolDeliveryPrompt")
        if prompt then
            prompt.Enabled = pending ~= nil and pending.Step == "deliver" and index <= active.Divisor and not pending.Delivered[tostring(index)]
            prompt.ObjectText = "Classroom " .. index
            local resource = active and data.GetMissionForActive(active).Resource or "food packs"
            prompt.ActionText = "Give " .. (pending and pending.Multiplier or 0) .. " " .. resource
        end
    end
    nearbyClassroom=nil
    local nearestDistance,nearestTarget=math.huge,nil
    if root and pending and pending.Step=="deliver" then
        for index=1,active.Divisor do
            if not pending.Delivered[tostring(index)] then
                local tent=school:FindFirstChild("ClassroomTent_"..index)
                local target=tent and (tent:FindFirstChild("SchoolDeliveryTarget") or tent.TentLabelPost)
                if target then
                    local distance=(root.Position-target.Position).Magnitude
                    if distance<nearestDistance then nearestDistance,nearestTarget,nearbyClassroom=distance,target,index end
                end
            end
        end
    end
    deliveryButton.Visible=nearestTarget~=nil and nearestDistance<=11 and not blocked and not solution.Frame.Visible
    if deliveryButton.Visible then deliveryButton.Text="Deliver to Classroom "..nearbyClassroom end
    gui.Enabled=gui.Enabled or deliveryButton.Visible
    updateNearbySchoolLabels(root)
    local schoolComplete = profile and profile.CompletedMissionIds["school_evacuation_144_6"]
    local metCaptain = player:GetAttribute("CaptainMetThisVisit") == true
    local destination = metCaptain and school.SchoolVolunteerPrompt or hall.CaptainKapaPrompt
    if metCaptain and not schoolComplete and player:GetAttribute("SchoolShuttleArrived") ~= true then
        destination = workspace.BrighthavenSchoolShuttle.Stops.HallBoarding
    end
    if nearestTarget then destination=nearestTarget end
    attachment.Parent = destination
    if root then
        local oldArrow = player.Character:FindFirstChild("FollowArrow", true)
        if require(shared.TutorialPractice).CanUseWorld(player) and oldArrow and oldArrow:IsA("Beam") then
            if hiddenTutorialArrow ~= oldArrow then
                hiddenTutorialArrow = oldArrow
                tutorialArrowWasEnabled = oldArrow.Enabled
            end
            oldArrow.Enabled = false
        elseif hiddenTutorialArrow then
            if hiddenTutorialArrow.Parent then hiddenTutorialArrow.Enabled = tutorialArrowWasEnabled end
            hiddenTutorialArrow = nil
        end
        local from = root:FindFirstChild("ReliefRouteStart") or make("Attachment", {Name = "ReliefRouteStart"}, root)
        beam.Attachment0 = from
        local distance = (root.Position - destination.Position).Magnitude
        beam.Enabled = inLocations and distance > 12 and distance < 180 and not schoolComplete
            and not playerGui:GetAttribute("SchoolShuttleUIOpen")
    else beam.Enabled = false end
end)
task.spawn(function()
    request("GetProfile")
    solution:SetState(activeMission())
    while gui.Parent do
        task.wait(12)
        if not busy and not panel.Visible and not captainDialogue.Visible then request("GetProfile"); solution:SetState(activeMission()) end
    end
end)
print("[Brighthaven] Locations 1-2 client ready")

