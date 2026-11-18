local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local TextService = game:GetService("TextService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local campaign = ReplicatedStorage.Brighthaven:WaitForChild("Campaign")
local Data = require(campaign.CampaignData)
local ActivitySites=require(campaign:WaitForChild("ActivitySites"))
local ChunkingMath=require(campaign.ChunkingMath)
local Quests = require(campaign.QuestData)
local KidUI = require(campaign.KidUI)
local remote = campaign:WaitForChild("Request")
local world = workspace:WaitForChild("BrighthavenStoryExtension")
local state, currentNode, busy, lastClick = nil, nil, false, -math.huge
local currentStaffAnchor
local briefingPage = 1
local renderBoard, renderMission, renderJourney, celebrate
local activityView
local colours = {paper = Color3.fromRGB(255, 248, 214), sky = Color3.fromRGB(226, 244, 255),
    outline = Color3.fromRGB(255, 180, 76), yellow = Color3.fromRGB(255, 199, 76),
    blue = Color3.fromRGB(52, 142, 202), ink = Color3.fromRGB(45, 70, 82), title = Color3.fromRGB(24, 47, 62),
    green = Color3.fromRGB(39, 132, 74), red = Color3.fromRGB(174, 51, 61)}
local function make(class, props, parent)
    local item = Instance.new(class)
    for key, value in pairs(props) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item, radius) make("UICorner", {CornerRadius = UDim.new(0, radius or 12)}, item) end
local gui = make("ScreenGui", {Name = "BrightHavenStoryExtension", ResetOnSpawn = false, DisplayOrder = 46,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling}, playerGui)
local bounds = make("Frame", {Name = "Bounds", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)
local panel = make("Frame", {Name = "Dialogue", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.fromScale(.56, .95),
    Size = UDim2.fromOffset(540, 300), BackgroundColor3 = colours.paper, BackgroundTransparency = .02,
    BorderSizePixel = 0, Visible = false}, gui)
round(panel, 16)
make("UIStroke", {Color = colours.outline, Thickness = 3}, panel)
make("UIGradient", {Color = ColorSequence.new(colours.paper, colours.sky), Rotation = 10}, panel)
local badge = make("TextLabel", {Name = "Badge", Position = UDim2.fromOffset(18, 14), Size = UDim2.fromOffset(56, 56),
    BackgroundColor3 = colours.yellow, BorderSizePixel = 0, Font = Enum.Font.GothamBlack,
    Text = "TD", TextScaled = true, TextColor3 = colours.title}, panel)
round(badge, 14)
local heading = make("TextLabel", {Name = "Heading", Position = UDim2.fromOffset(90, 16), Size = UDim2.new(1, -150, 0, 40),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = colours.title,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Text = "Truck Driver"}, panel)
local close = make("TextButton", {Name = "Close", Position = UDim2.new(1, -54, 0, 10), Size = UDim2.fromOffset(44, 44),
    BackgroundTransparency = 1, Text = "X", Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = colours.title}, panel)
local content = make("ScrollingFrame", {Name = "Content", Position = UDim2.fromOffset(18, 82), Size = UDim2.new(1, -36, 1, -96),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 4, AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new()}, panel)
local feedback = make("TextLabel", {Name = "Feedback", Position = UDim2.new(0, 18, 1, -64), Size = UDim2.new(1, -36, 0, 50),
    BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold, TextSize = 18, TextWrapped = true,
    TextColor3 = colours.green, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, panel)
local function layout()
    local size = bounds.AbsoluteSize
    local wide = size.X >= 700
    local width = math.min(720, math.max(240, wide and size.X * .46 or size.X - 32))
    local bottom = playerGui:GetAttribute("BrightHavenGuideVisible") == true and .76 or .95
    local headingHeight = math.max(48, TextService:GetTextSize(heading.Text, 22, Enum.Font.GothamBlack, Vector2.new(width - 150, 1000)).Y)
    heading.Size = UDim2.new(1, -150, 0, headingHeight)
    local top = math.max(82, headingHeight + 34)
    local footer = feedback.Text ~= "" and math.max(50, TextService:GetTextSize(feedback.Text, 18, Enum.Font.GothamBold, Vector2.new(width - 36, 1000)).Y) + 20 or 14
    local list = content:FindFirstChildWhichIsA("UIListLayout")
    local desired = top + footer + (list and list.AbsoluteContentSize.Y or 100)
    local height = math.min(math.max(190, desired), 560, math.max(180, size.Y * bottom - 16))
    panel.Position, panel.Size = UDim2.fromScale(wide and .56 or .5, bottom), UDim2.fromOffset(width, height)
    content.Position, content.Size = UDim2.fromOffset(18, top), UDim2.new(1, -36, 1, -top - footer)
    feedback.Position, feedback.Size = UDim2.new(0, 18, 1, -footer + 6), UDim2.new(1, -36, 0, footer - 14)
    feedback.Visible = feedback.Text ~= ""
end
bounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
feedback:GetPropertyChangedSignal("Text"):Connect(layout)
playerGui:GetAttributeChangedSignal("BrightHavenGuideVisible"):Connect(layout)
local function clear(title, initials)
    heading.Text, badge.Text, feedback.Text = title, initials or Data.Nodes[currentNode].Badge, ""
    local model = currentStaffAnchor and currentStaffAnchor:FindFirstAncestorOfClass("Model") or world[currentNode]:FindFirstChild("StoryHelper")
    KidUI.Portrait(badge, model)
    for _,item in ipairs(content:GetChildren()) do item:Destroy() end
    local list = make("UIListLayout", {Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layout)
    content.CanvasPosition = Vector2.zero
    panel.Visible = true
    layout()
end
local function text(message, bold)
    return make("TextLabel", {Name = "Message", BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y, Text = message, Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold,
        TextSize = bold and 20 or 18, TextColor3 = colours.ink, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, content)
end
local function button(name, label, callback, enabled)
    local item = make("TextButton", {Name = name, Size = UDim2.new(1, -6, 0, 48), Text = label,
        Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), TextWrapped = true,
        BackgroundColor3 = enabled == false and Color3.fromRGB(111, 129, 139) or colours.blue, BorderSizePixel = 0,
        Active = enabled ~= false, AutoButtonColor = enabled ~= false}, content)
    round(item)
    local function fit()
        local h = TextService:GetTextSize(label, 18, Enum.Font.GothamBlack, Vector2.new(math.max(100, item.AbsoluteSize.X - 18), 1000)).Y
        item.Size = UDim2.new(1, -6, 0, math.max(52, h + 22))
    end
    item:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    task.defer(fit)
    item.Activated:Connect(function()
        if enabled == false or busy or os.clock() - lastClick < .3 then return end
        lastClick = os.clock()
        callback()
    end)
    return item
end
local function numberInput(name, initial, maximum)
    local row = make("Frame", {Name = name .. "Row", BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 48)}, content)
    local input = make("TextBox", {Name = name, Position = UDim2.new(.25, 0, 0, 0), Size = UDim2.new(.5, 0, 1, 0),
        Text = tostring(initial), ClearTextOnFocus = false, Font = Enum.Font.GothamBold, TextSize = 18,
        TextColor3 = colours.ink, BackgroundColor3 = colours.sky, BorderSizePixel = 0}, row)
    round(input, 8)
    for index, delta in ipairs({-1, 1}) do
        local step = make("TextButton", {Name = delta < 0 and "Less" or "More", Position = UDim2.new(index == 1 and 0 or .8, 0, 0, 0),
            Size = UDim2.new(.2, 0, 1, 0), Text = delta < 0 and "-" or "+", Font = Enum.Font.GothamBlack, TextSize = 20,
            TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = colours.blue, BorderSizePixel = 0}, row)
        round(step, 8)
        step.Activated:Connect(function() input.Text = tostring(math.clamp((tonumber(input.Text) or 0) + delta, 0, maximum)) end)
    end
    return input
end

local originals = {}
for _,v in ipairs(world:GetDescendants()) do
    if v:IsA("BasePart") then originals[v] = {Transparency = v.Transparency, Size = v.Size, CFrame = v.CFrame} end
end
local function visible(object, show)
    if not object then return end
    local all = object:GetDescendants()
    if object:IsA("BasePart") then table.insert(all, object) end
    for _,v in ipairs(all) do
        if v:IsA("BasePart") then v.LocalTransparencyModifier = show and 0 or 1
        elseif v:IsA("SurfaceGui") then v.Enabled = show
        elseif v:IsA("PointLight") then v.Enabled = show end
    end
end
local colourEffect = make("ColorCorrectionEffect", {Name = "BrightHavenStoryLighting", Brightness = 0, Saturation = 0, Enabled = false}, Lighting)
local celebrationId, celebrating = 0, false
local function updateWorld()
    if not state then return end
    colourEffect.Enabled, colourEffect.Brightness = state.Blackout == true, -.13
    for _,node in ipairs(Data.Order) do
        local scene = world[node]
        local active = state.Active and state.Active.Node == node and state.Active
        local completedMission
        for _,candidate in ipairs(Data.GetChoices(node, 1)) do
            if state.Completed[candidate.Id] then completedMission = candidate; break end
        end
        local m = active and Data.ById[active.Id] or completedMission or Data.GetChoices(node, 1)[1]
        local completed = completedMission ~= nil
        local quotient = active and active.Quotient or completed and math.floor(m.Dividend / m.Divisor) or 0
        local groups = scene:FindFirstChild("Groups")
        for _,group in ipairs(groups and groups:GetChildren() or {}) do
            local index = group:GetAttribute("Index")
            visible(group, index <= m.Divisor)
            local label = group.Counter.Label.Text
            label.Text = m.Group:gsub("^%l", string.upper) .. " " .. index .. "\n" .. quotient .. " " .. m.Resource
            if node == "shop" then
                for key, item in pairs({Lantern = "lantern", Radio = "radio", PowerBank = "power bank"}) do visible(group:FindFirstChild(key), index <= m.Divisor and m.Group == item) end
            elseif node == "lab" then
                local chosen = m.Round == 2 and "DishUnit" or m.Round == 3 and "CellUnit" or "BeamUnit"
                for _,key in ipairs({"BeamUnit", "DishUnit", "CellUnit"}) do visible(group:FindFirstChild(key), index <= m.Divisor and key == chosen) end
            end
        end
        local pile = scene:FindFirstChild("SourcePile")
        if pile then
            local left = active and active.Remaining or completed and 0 or m.Dividend
            if active and active.Routed then left = 0 end
            for _,box in ipairs(pile:GetChildren()) do visible(box, box:GetAttribute("Index") <= math.ceil(left / m.Dividend * 24)) end
        end
        local extras = scene:FindFirstChild("ClinicExtras")
        if extras then visible(extras, active and (active.Routed or 0) > 0 or completed and m.Dividend % m.Divisor > 0 or false) end
        if node == "wood" then
            local left = active and active.Remaining or completed and 0 or 120
            local log = scene.RemainingLog
            log.LocalTransparencyModifier = left == 0 and 1 or 0
            log.Size = Vector3.new(math.max(.05, 38 * left / 120), 4.4, 4.4)
            log.CFrame = originals[log].CFrame * CFrame.new((log.Size.X - 38) / 2, 0, 0)
            for _,piece in ipairs(scene.CutPieces:GetChildren()) do visible(piece, piece:GetAttribute("Index") <= quotient) end
        elseif node == "lab" then
            for index = 1, 3 do scene.WeatherMachine["Socket" .. index].Color = state.InstalledParts[tostring(index)] and colours.green or colours.yellow end
            if not celebrating then visible(scene.StoryStormClouds, not state.Victory) end
        end
    end
end
local function animateChunk(m)
    local scene = ActivitySites.Resolve(player,m.Node)
    local groups = scene:FindFirstChild("Groups")
    if not groups or m.Mode == "measure" then return end
    for index = 1, m.Divisor do
        local group = groups:FindFirstChild("Group" .. index)
        if group then
            local start = Data.Nodes[m.Node].Position + Vector3.new(30, 6, 0)
            local cube = make("Part", {Name = "StoryDelivery", Size = m.Resource == "pesos" and Vector3.new(2, .25, 1.3) or Vector3.new(1.7, 1.7, 1.7),
                Position = start, Color = m.Resource == "pesos" and colours.yellow or colours.blue,
                Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false}, world)
            local goal = group.Counter.Position + Vector3.new(0, 3, 6)
            local tween = TweenService:Create(cube, TweenInfo.new(.7, Enum.EasingStyle.Quad), {Position = goal})
            tween:Play()
            tween.Completed:Once(function() cube:Destroy() end)
        end
    end
end
local function request(action, payload)
    if busy then return nil end
    busy = true
    local ok, result = pcall(function() return remote:InvokeServer(action, payload or {}) end)
    busy = false
    if not ok or type(result) ~= "table" then feedback.Text = "The helper could not hear us. Please try again."; feedback.TextColor3 = colours.red; return nil end
    if result.State then state = result.State end
    feedback.Text, feedback.TextColor3 = result.Message or "", result.Ok and colours.green or colours.red
    if result.Celebrate then
        celebrating = true
        task.defer(celebrate)
    end
    updateWorld()
    return result
end
local function travel(destination)
    if not state then return end
    if not state.Unlocked[destination] then
        local gate=state.GameLocks and state.GameLocks[destination]
        feedback.Text=gate and gate.Reason or "Finish your current story job first. Check your guidebook for the next helper."
        return
    end
    playerGui:SetAttribute("MapPingPosition",nil)
    playerGui:SetAttribute("MapPingTitle",nil)
    playerGui:SetAttribute("QuestPingKind","story")
    playerGui:SetAttribute("QuestPingId",destination)
    playerGui:SetAttribute("SideQuestFocus",false)
    panel.Visible=false;currentNode=nil;currentStaffAnchor=nil
end
local function returnToCaptain()
    playerGui:SetAttribute("QuestPingKind","story")
    playerGui:SetAttribute("QuestPingId","home")
    playerGui:SetAttribute("SideQuestFocus",false)
    panel.Visible=false;currentNode=nil;currentStaffAnchor=nil
end
local function inventory()
    text("Weather Machine Parts", true)
    for index, name in ipairs(Data.PartNames) do
        text((state.Parts[tostring(index)] and "Found: " or "Still to find: ") .. name)
    end
end
renderJourney = function()
    panel.Visible=false;currentNode=nil;currentStaffAnchor=nil
    playerGui:SetAttribute("OpenStoryGuidebook",true)
end
renderBoard = function()
    if not currentNode or not state then return end
    local node = Data.Nodes[currentNode]
    clear(node.Speaker)
    if currentNode == "school" then
        text(state.SchoolComplete and "The families have their food! The truck driver needs help at the recycling yard." or
            "Help the School Helper share food packs first. Then we can help the truck driver at the recycling yard.")
        if state.SchoolComplete and not state.Unlocked.dumpsite then
            local gate=state.GameLocks and state.GameLocks.dumpsite
            text(gate and gate.Reason or "Meet a neighbor and finish a division job to keep practicing.")
        end
        button("NextStop", "Pin the Recycling Yard", function() travel("dumpsite") end, state.SchoolComplete and state.Unlocked.dumpsite)
    elseif not state.Unlocked[currentNode] then
        local gate=state.GameLocks and state.GameLocks[currentNode]
        text("Keep Practicing!",true)
        text(gate and gate.Reason or Quests.Objective(state,Data))
        if gate then text("Helper Level "..gate.RequiredLevel.."  |  "..gate.RequiredPractice.." division jobs",true) end
        text("Neighbors have division jobs that help our town prepare. Meet them to earn XP and practice equal chunks.")
    elseif state.Active and state.Active.Phase ~= "complete" then
        if state.Active.Node == currentNode then
            text("Let's finish our activity. Take one step at a time!")
            button("Resume", "Keep Helping", renderMission)
        else text("We have an activity to finish at " .. Data.Nodes[state.Active.Node].Title .. ". It will be ready when you return.") end
    else
        local quest = Quests.ById[currentNode]
        if not state.Nodes[currentNode] and not state.Accepted[currentNode] then
            text(Quests.Acts[quest.Act].Title, true)
            text(quest.Title, true)
            local pages={quest.Why,node.Intro,quest.Steps[1].." Finish this helping job to earn XP and coins."}
            text(pages[briefingPage])
            text(briefingPage.." / "..#pages)
            if briefingPage<#pages then
                button("NextDialogue","Next",function() briefingPage+=1;renderBoard() end)
            else
                button("AcceptQuest", "I'll Help!", function()
                    local result = request("AcceptQuest", {Node = currentNode})
                    if result and result.Ok then
                        if currentNode=="lab" then renderBoard()
                        else
                            result=request("Start",{Id=quest.Mission})
                            if result and result.Ok then renderMission() end
                        end
                    end
                end)
            end
            if briefingPage>1 then button("PreviousDialogue","Back",function() briefingPage-=1;renderBoard() end) end
            return
        end
        text(state.Nodes[currentNode] and node.Thanks or node.Intro)
        if node.Next and state.Unlocked[node.Next] then
            button("NextStop", "Pin " .. Data.Nodes[node.Next].Speaker, function() travel(node.Next) end)
            text("More Helping Jobs", true)
        elseif node.Next and state.Nodes[currentNode] then
            local gate=state.GameLocks and state.GameLocks[node.Next]
            if gate then text("Next: "..Data.Nodes[node.Next].Title,true);text(gate.Reason) end
        elseif currentNode == "lab" and state.Victory then
            button("ReturnCaptain", "Tell Captain Kappa the Good News", function()
                returnToCaptain()
            end)
            text("More Helping Jobs", true)
        end
        if currentNode == "lab" and not (state.InstalledParts["1"] and state.InstalledParts["2"] and state.InstalledParts["3"]) then
            for index, name in ipairs(Data.PartNames) do
                if not state.InstalledParts[tostring(index)] then
                    button("Install" .. index, "Put in the " .. name, function()
                        local result = request("InstallPart", {Index = index})
                        if result and result.Ok then renderBoard() end
                    end)
                end
            end
        else
            if currentNode == "lab" then text(state.Victory and "BrightHaven is safe! Help stock more supplies." or "Lab job " .. state.LabRound .. " of 3", true) end
            local choices=Data.GetChoices(currentNode, state.LabRound)
            if currentNode=="lab" and state.Victory then choices=Data.GetChoices(currentNode,nil) end
            for _,mission in ipairs(choices) do
                local required = currentNode == "lab" and ({"lab_energy_450", "lab_pulses", "lab_reserve"})[state.LabRound] or quest.Mission
                if state.Nodes[currentNode] or mission.Id == required then
                button("Start_" .. mission.Id, mission.Title, function()
                    local result = request("Start", {Id = mission.Id})
                    if result and result.Ok then renderMission() end
                end)
                end
            end
        end
    end
    button("Journey", "My Quest Book", renderJourney)
    if currentNode ~= "school" then button("ReturnSchool", "Pin the School", function() travel("school") end) end
end

local function groupCounters(m, active)
    if m.Mode == "measure" then
        text("Pieces made: " .. active.Quotient .. "\nLog left: " .. active.Remaining .. " meters", true)
        local bar = make("Frame", {Name = "LogMeter", Size = UDim2.new(1, -6, 0, 24), BackgroundColor3 = colours.sky, BorderSizePixel = 0}, content)
        round(bar, 6)
        local fill = make("Frame", {Name = "RemainingLength", Size = UDim2.fromScale(active.Remaining / m.Dividend, 1), BackgroundColor3 = colours.blue, BorderSizePixel = 0}, bar)
        round(fill, 6)
        return
    end
    local grid = make("Frame", {Name = "GroupCounters", BackgroundTransparency = 1,
        Size = UDim2.new(1, -6, 0, math.ceil(m.Divisor / 3) * 68 - 6)}, content)
    make("UIGridLayout", {CellSize = UDim2.new(1 / 3, -6, 0, 62), CellPadding = UDim2.fromOffset(6, 6)}, grid)
    for index = 1, m.Divisor do
        local cell = make("TextLabel", {Name = "Group" .. index, BackgroundColor3 = colours.sky, BorderSizePixel = 0,
            Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = colours.ink, TextWrapped = true,
            Text = m.Group:gsub("^%l", string.upper) .. " " .. index .. "\n" .. active.Quotient .. " " .. m.Resource}, grid)
        round(cell, 8)
    end
end
renderMission = function()
    local a = state and state.Active
    if not a or a.Node ~= currentNode then renderBoard(); return end
    local m = Data.ById[a.Id]
    if a.Phase=="activity" then
        panel.Visible=false
        activityView:Show(a)
        return
    end
    activityView:Hide()
    clear(m.Title)
    if a.Phase == "briefing" then
        if m.Activity=="chop" then
            text("Our Goal",true)
            text("Clear the fallen wood so supplies can reach families.")
            text("How many equal "..m.Divisor.."-meter pieces can we make from "..m.Dividend.." meters of wood?",true)
            text("First: get the game axe and make 3 cuts at the marked log.")
            text("Next: count pieces in chunks. Multiply, subtract, and repeat.")
        else
            text(Quests.ById[m.Node].Why)
            text(Data.Story(m))
            text("Share in equal chunks. Choose an amount for each group, multiply to count the whole chunk, then subtract and repeat.")
        end
        button("Begin", "Let's Start", function() local result = request("Begin"); if result and result.Ok then renderMission() end end)
    elseif a.Phase == "chunking" then
        local pending=a.PendingChunk
        text(pending and (pending.Step=="multiply" and "2. Count the Whole Chunk" or "3. Find What Is Left") or "1. Choose an Equal Chunk", true)
        if m.Mode ~= "measure" then text("Left to count: " .. a.Remaining .. " " .. m.Resource) end
        groupCounters(m, a)
        local last = a.Steps[#a.Steps]
        if last then text("Our last step: " .. last.Quotient .. " x " .. m.Divisor .. " = " .. last.Amount .. ".\n" .. (last.Remaining + last.Amount) .. " - " .. last.Amount .. " = " .. a.Remaining .. " left.") end
        if pending then
            if pending.Step=="multiply" then
                text(m.Divisor.." x "..pending.Quotient.." = ?",true)
                text(ChunkingMath.FactorHint(m.Divisor,pending.Quotient))
            else
                text(pending.Before.." - "..pending.Product.." = ?",true)
                text(m.Mode=="measure" and "Take away the wood used in this chunk. How much wood is left?" or "Take away the whole chunk. You will still give every group the same amount.")
            end
            local answer=numberInput("ChunkAnswer","",m.Dividend)
            answer.PlaceholderText="My number"
            button("CheckChunk","Check",function()
                local result=request("ChunkStep",{Step=pending.Step,Number=answer.Text,Token=pending.Token})
                if result and result.Ok then
                    if pending.Step=="subtract" then animateChunk(m) end
                    renderMission()
                end
            end)
            button("CancelChunk","Start Over",function()
                local result=request("ChunkStep",{Step="cancel",Token=pending.Token})
                if result and result.Ok then renderMission() end
            end)
        else
            text(m.Mode=="measure" and "Count a few "..m.Divisor.."-meter pieces at a time. Keep going until no wood is left." or "Choose how much EACH "..m.Group.." gets this round.")
            local custom=numberInput("CustomChunk","",1000);custom.PlaceholderText="My chunk"
            button("ChooseChunk","Use My Chunk",function()
                local result=request("Chunk",{Number=custom.Text})
                if result and result.Ok then renderMission() end
            end)
            local shown={}
            local choices=table.clone(m.Chunks)
            for _,q in ipairs({10,5,2,1}) do table.insert(choices,q) end
            for _,q in ipairs(choices) do
                if not shown[q] then
                    shown[q]=true
                    button("Chunk"..q,Data.ChunkText(m,q),function()
                        local result=request("Chunk",{Number=q})
                        if result and result.Ok then renderMission() end
                    end)
                end
            end
        end
        button("Hint", "Show Me a Hint", function() request("Hint") end)
    elseif a.Phase == "remainder" then
        text("3. Count the Extra Boxes", true)
        groupCounters(m, a)
        text("There are " .. a.Remaining .. " extra boxes. There are not enough to give every truck one more. How many extra boxes should we send to the clinic?")
        local input = numberInput("ExtraBoxes", 0, m.Divisor - 1)
        button("SendExtras", "Send the Extra Boxes to the Clinic", function()
            local result = request("Remainder", {Number = input.Text, Plan = "clinic"})
            if result and result.Ok then renderMission() end
        end)
    elseif a.Phase == "verify" then
        text("Check Our Work", true)
        local numbers = {}
        for _,step in ipairs(a.Steps) do table.insert(numbers, tostring(step.Quotient)) end
        text("Add the numbers from our steps:")
        text(table.concat(numbers, " + ") .. " = " .. a.Quotient, true)
        if m.Mode == "measure" then text(a.Quotient .. " pieces x 4 meters = " .. m.Dividend .. " meters", true)
        else
            text(a.Quotient .. " in each " .. m.Group .. " x " .. m.Divisor .. " " .. Data.GroupPlural(m) .. " = " .. a.Quotient * m.Divisor, true)
            if a.Remainder > 0 then text(a.Quotient * m.Divisor .. " + " .. a.Remainder .. " extra boxes = " .. m.Dividend, true) end
        end
        text("That matches the number we started with!")
        button("Verify", "Check My Answer", function()
            local result = request("Verify", {Quotient = a.Quotient, Remainder = a.Remainder})
            if result and result.Ok and not result.Celebrate then
                renderMission()
            end
        end)
    elseif a.Phase == "complete" then
        text("You Did It!", true)
        if m.Mode == "measure" then text("You helped cut and count 30 equal pieces. Every piece is 4 meters long.")
        elseif m.Mode == "price" then text("Each " .. m.Group .. " costs " .. a.Quotient .. " pesos.")
        else text("Each " .. m.Group .. " has " .. a.Quotient .. " " .. m.Resource .. ".") end
        if a.Remainder > 0 then text(a.Remainder .. " extra medicine boxes went straight to the clinic.") end
        text(a.NewStar and "You earned a helping star!" or "Thanks for helping again!")
        text(currentNode == "lab" and not state.Victory and "Lab job " .. m.Round .. " complete!" or "Quest complete: " .. Quests.ById[currentNode].Title, true)
        if currentNode == "lab" and not state.Victory then
            text("Great work! The next lab activity is ready.")
            button("NextRound", "Next Lab Activity", renderBoard)
        else
            text(Data.Nodes[currentNode].Thanks)
            local nextNode = Data.Nodes[currentNode].Next
            if nextNode then
                if state.Unlocked[nextNode] then
                    button("NextStop", "Pin " .. Data.Nodes[nextNode].Speaker, function() travel(nextNode) end)
                else
                    local gate=state.GameLocks and state.GameLocks[nextNode]
                    text("Next: "..Data.Nodes[nextNode].Title,true)
                    text(gate and gate.Reason or "Finish a neighbor's division job to keep practicing.")
                end
            elseif state.Victory then
                button("ReturnCaptain", "Tell Captain Kappa the Good News", function()
                    returnToCaptain()
                end)
            end
        end
        button("MoreActivities", "Help Here Again", renderBoard)
        button("Journey", "My Story Guidebook", renderJourney)
    end
end

celebrate = function()
    celebrationId += 1
    local token = celebrationId
    local camera = workspace.CurrentCamera
    local old = {Type = camera.CameraType, CFrame = camera.CFrame, Subject = camera.CameraSubject, FOV = camera.FieldOfView}
    local lab = world.lab
    local origin = Data.Nodes.lab.Position
    local beam = lab.WeatherMachine.BeamNozzle.VictoryBeam
    visible(lab.StoryStormClouds, true)
    camera.CameraType = Enum.CameraType.Scriptable
    camera.CFrame = CFrame.lookAt(origin + Vector3.new(40, 30, -50), origin + Vector3.new(0, 20, 0))
    currentNode = "lab"
    clear("Scientist", "SC")
    text("The machine is ready! Let's count down together.")
    local count = text("3", true)
    for value = 3, 1, -1 do
        if token ~= celebrationId then break end
        count.Text = tostring(value)
        task.wait(1)
    end
    if token == celebrationId then
        beam.Enabled = true
        count.Text = "BrightHaven is Safe!"
        for _,cloud in ipairs(lab.StoryStormClouds:GetDescendants()) do
            if cloud:IsA("BasePart") then TweenService:Create(cloud, TweenInfo.new(2), {Transparency = 1}):Play() end
        end
        local sunshine = make("ColorCorrectionEffect", {Name = "StoryVictorySunshine", Brightness = .08, Saturation = .15}, Lighting)
        task.wait(3)
        sunshine:Destroy()
    end
    beam.Enabled = false
    camera.CameraType, camera.CameraSubject, camera.FieldOfView = old.Type, old.Subject, old.FOV
    camera.CFrame = old.CFrame
    celebrating = false
    updateWorld()
    if token == celebrationId then
        clear("Scientist", "SC")
        text("The Storm Stopper's beam broke apart the super typhoon! Our homes are safe. Let's tell Captain Kappa the good news.")
        text("You collected all 3 parts and finished all 3 lab activities.")
        button("ReturnCaptain", "Return to Captain Kappa", function()
            returnToCaptain()
        end)
        button("Journey", "My Quest Book", renderJourney)
        button("ReturnSchool", "Pin the School", function() travel("school") end)
    end
end
local function closeDialogue()
    celebrationId += 1
    panel.Visible, currentNode, currentStaffAnchor = false, nil, nil
end
activityView=require(campaign:WaitForChild("WorldActivityClient")).Create({
    Request=request,
    OnFinished=function() renderMission() end,
    OnClose=closeDialogue,
})
close.Activated:Connect(closeDialogue)
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer and triggeringPlayer ~= player then return end
    if prompt:GetAttribute("SideQuestId") then closeDialogue(); return end
    local node = prompt:GetAttribute("CampaignNode")
    local legacyWood=ActivitySites.IsLegacyWoodPrompt(prompt)
    if not node or not Data.Nodes[node] or (not prompt:IsDescendantOf(world) and not legacyWood) or celebrating then return end
    -- Reading the existing profile lets the server observe genuine school completion.
    pcall(function() ReplicatedStorage.Brighthaven.Remotes.ClientRequest:InvokeServer("GetProfile", {}) end)
    currentNode = node
    briefingPage = 1
    currentStaffAnchor = legacyWood and workspace.WoodCuttingNPC.HumanoidRootPart or nil
    local result = request("GetState")
    if result and result.Ok then
        local key = prompt:GetAttribute("ClinicStaff")
        local staff = node == "clinic" and key and Data.ClinicStaff[key]
        if staff then
            currentStaffAnchor = prompt.Parent
            clear(staff.Name, staff.Badge)
            text(staff.Message)
            button("ThanksStaff", "Thank you!", closeDialogue)
        else renderBoard() end
    end
end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < .2 then return end
    elapsed = 0
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if panel.Visible and currentNode and not celebrating then
        local anchor = currentStaffAnchor or world[currentNode].HelperAnchor
        local scene=currentNode=="wood" and ActivitySites.Resolve(player,"wood")
        local atLog=root and scene and (root.Position-scene.ChoppingLog.Position).Magnitude<=12
        if not root or not anchor.Parent or ((root.Position-anchor.Position).Magnitude>18 and not atLog) then closeDialogue() end
        local oldGui = playerGui:FindFirstChild("BrighthavenLocation12")
        if oldGui and ((oldGui.MissionPanel.Visible) or oldGui.CaptainDialogue.Visible) then panel.Visible = false; currentNode = nil end
        local native = playerGui:FindFirstChild("DialogueSystem")
        local frame = native and native:FindFirstChild("Frame")
        if frame and frame.Visible then panel.Visible = false; currentNode = nil end
    end
end)
task.defer(function() request("GetState"); feedback.Text = "" end)

