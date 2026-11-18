local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PromptService = game:GetService("ProximityPromptService")
local TextService = game:GetService("TextService")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local campaign = game.ReplicatedStorage.Brighthaven:WaitForChild("Campaign")
local Data = require(campaign.SideQuestData)
local ChunkingMath=require(campaign.ChunkingMath)
local KidUI = require(campaign.KidUI)
local Practice = require(game.ReplicatedStorage.Brighthaven.TutorialPractice)
local remote = campaign:WaitForChild("Request")
local world = workspace:WaitForChild("BrighthavenSideQuests")
local state, current, anchor, busy
local briefingPage=1
local render
local function make(class, props, parent)
    local item = Instance.new(class)
    for key, value in pairs(props) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item) make("UICorner", {CornerRadius = UDim.new(0, 8)}, item) end
local ink = Color3.fromRGB(31, 67, 78)
local teal = Color3.fromRGB(24, 133, 148)
local gui = make("ScreenGui", {Name = "BrightHavenSideDialogue", ResetOnSpawn = false, DisplayOrder = 47}, playerGui)
local bounds = make("Frame", {Name = "Bounds", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1}, gui)
local panel = make("Frame", {Name = "Dialogue", AnchorPoint = Vector2.new(.5, 1), Position = UDim2.fromScale(.5, .95),
    Size = UDim2.fromOffset(560, 380), BackgroundColor3 = Color3.fromRGB(241, 252, 249), BorderSizePixel = 0, Visible = false}, gui)
round(panel)
make("UIStroke", {Color = Color3.fromRGB(255, 180, 76), Thickness = 3}, panel)
local badge = make("TextLabel", {Name = "PortraitBadge", Position = UDim2.fromOffset(16, 14), Size = UDim2.fromOffset(64, 64),
    Text = "", TextSize = 24, Font = Enum.Font.GothamBlack, BackgroundColor3 = Color3.fromRGB(255, 211, 103)}, panel)
round(badge)
local title = make("TextLabel", {Name = "Speaker", Position = UDim2.fromOffset(94, 16), Size = UDim2.new(1, -156, 0, 40),
    BackgroundTransparency = 1, Font = Enum.Font.GothamBlack, TextSize = 22, TextWrapped = true, TextColor3 = ink,
    TextXAlignment = Enum.TextXAlignment.Left}, panel)
local close = make("TextButton", {Name = "Close", Position = UDim2.new(1, -58, 0, 10), Size = UDim2.fromOffset(48, 48),
    BackgroundTransparency = 1, Text = "X", Font = Enum.Font.GothamBlack, TextSize = 22, TextColor3 = ink}, panel)
local content = make("ScrollingFrame", {Name = "Content", Position = UDim2.fromOffset(18, 92), Size = UDim2.new(1, -36, 1, -110),
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new()}, panel)
local feedback = make("TextLabel", {Name = "Feedback", BackgroundTransparency = 1, Text = "", Font = Enum.Font.GothamBold,
    TextSize = 18, TextWrapped = true, TextColor3 = teal, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top}, panel)
local function layout()
    local size = bounds.AbsoluteSize
    local width = math.min(620, math.max(240, size.X - 32))
    local titleH = math.max(48, TextService:GetTextSize(title.Text, 22, Enum.Font.GothamBlack, Vector2.new(width - 156, 1000)).Y)
    title.Size = UDim2.new(1, -156, 0, titleH)
    local top = math.max(92, titleH + 32)
    local footer = feedback.Text == "" and 18 or math.max(50, TextService:GetTextSize(feedback.Text, 18, Enum.Font.GothamBold, Vector2.new(width - 36, 2000)).Y) + 24
    local list = content:FindFirstChildOfClass("UIListLayout")
    local height = math.min(top + footer + (list and list.AbsoluteContentSize.Y or 160), 570, size.Y * .95 - 16)
    panel.Size = UDim2.fromOffset(width, math.max(top + footer + 50, height))
    content.Position, content.Size = UDim2.fromOffset(18, top), UDim2.new(1, -36, 1, -top - footer)
    feedback.Position, feedback.Size = UDim2.new(0, 18, 1, -footer + 6), UDim2.new(1, -36, 0, footer - 14)
end
local function text(message, bold)
    return make("TextLabel", {Name = "Message", Size = UDim2.new(1, -8, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1, Text = message, TextWrapped = true, Font = bold and Enum.Font.GothamBlack or Enum.Font.GothamBold,
        TextSize = bold and 20 or 18, TextColor3 = ink, TextXAlignment = Enum.TextXAlignment.Left}, content)
end
local function request(action, payload)
    if busy then return nil end
    busy = true
    local ok, result = pcall(function() return remote:InvokeServer(action, payload or {}) end)
    busy = false
    if ok and type(result) == "table" then
        if result.State then state = result.State end
        return result
    end
    return {Ok = false, Message = "The helper is getting ready. Please try again."}
end
local function hide() panel.Visible = false; current = nil; anchor = nil end
local function nearNpc()
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    return root and anchor and anchor.Parent and Practice.CanUseWorld(player) and (root.Position - anchor.Position).Magnitude <= 14
end
local function button(name, message, callback)
    local item = make("TextButton", {Name = name, Size = UDim2.new(1, -8, 0, 56), Text = message, TextWrapped = true,
        Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), BackgroundColor3 = teal, BorderSizePixel = 0}, content)
    round(item)
    item.Activated:Connect(function() if not busy then callback() end end)
    local function fit()
        local h = TextService:GetTextSize(message, 18, Enum.Font.GothamBold, Vector2.new(math.max(100, item.AbsoluteSize.X - 20), 1000)).Y
        item.Size = UDim2.new(1, -8, 0, math.max(56, h + 24))
    end
    item:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
    task.defer(fit)
end
local function shares(quest,p)
    local problem=quest.Sharing
    local s=p.Sharing or ChunkingMath.New(problem.Total,2)
    local pending=s.PendingChunk
    text("Share Supplies Fairly",true)
    text(problem.Total.." "..problem.Resource.." / "..problem.Groups.." "..(problem.Group=="family" and "families" or problem.Group.."s"))
    text("Left: "..s.Remaining.."   |   Each group: "..s.Quotient)
    local action=pending and pending.Step or s.Remaining==0 and "check" or "choose"
    if pending then
        if action=="multiply" then
            text(problem.Groups.." x "..pending.Quotient.." = ?",true)
            text(ChunkingMath.FactorHint(problem.Groups,pending.Quotient))
        else text(pending.Before.." - "..pending.Product.." = ?",true);text("Take away the whole chunk. Keep each group's share equal.") end
    elseif action=="check" then
        text("Multiply one group's share by all "..problem.Groups.." groups. Does it match our starting pile?")
    else text("Choose a small amount for EACH group. Use at least two chunks. Multiply to count a chunk, subtract it, then share again.") end
    local input=make("TextBox",{Name="SharingNumber",Text="",PlaceholderText=action=="choose" and "My chunk" or "My number",
        Size=UDim2.new(1,-8,0,48),ClearTextOnFocus=false,Font=Enum.Font.GothamBold,TextSize=20,TextColor3=ink,
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},content)
    round(input);make("UIStroke",{Color=Color3.fromRGB(255,211,78),Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},input)
    local function send(step,number)
        local result=request("SideShare",{Id=current,Step=step,Number=number,Token=pending and pending.Token})
        render(result and result.Message)
    end
    button("CheckSharing",action=="choose" and "Use My Chunk" or "Check",function() send(action,input.Text) end)
    if pending then button("RestartSharing","Start Over",function() send("cancel") end) end
end
render = function(note)
    if not current or not state then return end
    if not nearNpc() then hide(); return end
    local quest = Data.ById[current]
    local p = state.SideQuests[current]
    title.Text, badge.Text = quest.Speaker, quest.Badge
    KidUI.Portrait(badge, anchor:FindFirstAncestorOfClass("Model"))
    feedback.Text = note or ""
    for _, child in ipairs(content:GetChildren()) do child:Destroy() end
    local list = make("UIListLayout", {Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder}, content)
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(layout)
    text(quest.Title, true)
    if p and p.Complete then
        text("Quest complete! +" .. quest.XP .. " XP", true)
        text(quest.Thanks)
        button("Done", "We helped together!", hide)
    elseif state.SideActiveId == current then
        if Data.Ready(quest, p) then
            text("All three steps are done!", true)
            text("Tell " .. quest.Speaker .. " you are ready.")
            button("Finish", "Finish Quest - Earn " .. quest.XP .. " XP", function()
                local result = request("SideFinish", {Id = current})
                if result and result.Ok then playerGui:SetAttribute("SideQuestFocus", false) end
                render(result and result.Message)
            end)
        elseif Data.TaskReady(quest,p) then
            shares(quest,p)
        elseif quest.Kind == "quiz" then
            local question = quest.Questions[p.Step + 1]
            text("Safe choice " .. (p.Step + 1) .. " of 3", true)
            text(question.Ask)
            for index, answer in ipairs(question.Choices) do
                local step = p.Step + 1
                button("Answer" .. index, answer, function()
                    local result = request("SideAnswer", {Id = current, Step = step, Choice = index})
                    render(result and result.Message)
                end)
            end
        else
            text(Data.Objective(quest, p), true)
            for _, item in ipairs(quest.Items) do text((p.Items[item.Id] and "Got it: " or "Find: ") .. item.Name) end
            text(quest.Safety)
            button("FindItems", "Let's Find Them!", hide)
        end
    else
        local pages={Data.StoryLinks[current],quest.Intro,quest.Safety}
        text(pages[briefingPage])
        text(briefingPage.." / "..#pages)
        if briefingPage<#pages then
            button("NextDialogue","Next",function() briefingPage+=1;render() end)
        else
            text("Reward: " .. quest.XP .. " XP", true)
            button("Accept", "I'll Help!", function()
                local result = request("SideAccept", {Id = current})
                if result and result.Ok then playerGui:SetAttribute("SideQuestTarget", quest.Id); playerGui:SetAttribute("SideQuestFocus", true) end
                render(result and result.Message)
            end)
        end
        if briefingPage>1 then button("PreviousDialogue","Back",function() briefingPage-=1;render() end) end
        button("Later", "Maybe Later", hide)
    end
    content.CanvasPosition = Vector2.zero
    layout()
    panel.Visible = true
end
local function updateProps()
    for _, group in ipairs(world:GetChildren()) do
        local p = state and state.SideQuests[group.Name]
        for _, model in ipairs(group:GetChildren()) do
            local id = model:GetAttribute("ItemId")
            if id then
                local met=state and state.SideDiscovered and state.SideDiscovered[group.Name]
                local collected = not met or not p or p.Complete or p.Items[id]
                for _, object in ipairs(model:GetDescendants()) do
                    if object:IsA("BasePart") then object.LocalTransparencyModifier = collected and 1 or 0
                    elseif object:IsA("ProximityPrompt") then object.Enabled = state ~= nil and state.SideActiveId == group.Name and not collected end
                end
            end
        end
    end
end
campaign.QuestChanged.OnClientEvent:Connect(function(nextState) state = nextState; updateProps() end)
PromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
    if triggeringPlayer and triggeringPlayer ~= player then return end
    local id = prompt:GetAttribute("SideQuestId")
    if not Data.ById[id] then hide(); return end
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not Practice.CanUseWorld(player) or not prompt.Parent:IsA("BasePart") or (root.Position - prompt.Parent.Position).Magnitude > 12 then return end
    local item = prompt:GetAttribute("SideQuestItem")
    if item then
        local result = request("SideCollect", {Id = id, Item = item})
        updateProps()
        if result and result.Ok then playerGui:SetAttribute("SideQuestTarget", id); playerGui:SetAttribute("SideQuestFocus", true) end
        return
    end
    local result = request("SideMeet", {Id = id})
    if result and result.Ok and result.State then
        for _, name in ipairs({"BrighthavenLocation12", "BrightHavenStoryExtension", "DialogueSystem", "BrighthavenNeighborhoodDialogue"}) do
            local other = playerGui:FindFirstChild(name)
            if other then
                for _, child in ipairs(other:GetChildren()) do
                    if child:IsA("GuiObject") and (child.Name == "CaptainDialogue" or child.Name == "MissionPanel" or child.Name == "Dialogue" or child.Name == "Frame") then child.Visible = false end
                end
            end
        end
        current, anchor = id, prompt.Parent
        briefingPage = 1
        render()
    end
end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < .2 then return end
    elapsed = 0
    if not panel.Visible then return end
    if not nearNpc() then hide() end
end)
close.Activated:Connect(hide)
player.CharacterRemoving:Connect(hide)
bounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
task.spawn(function() request("GetState"); updateProps() end)
updateProps()
