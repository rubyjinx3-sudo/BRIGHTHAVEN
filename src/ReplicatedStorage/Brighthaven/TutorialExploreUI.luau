local TextService = game:GetService("TextService")
local Practice = require(script.Parent.TutorialPractice)
local KidUI = require(script.Parent.Campaign.KidUI)
local UI = {}
local ink, yellow = Color3.fromRGB(48,52,55), Color3.fromRGB(255,211,78)
local function make(class, name, parent, properties)
    local item = Instance.new(class)
    item.Name = name
    for key, value in pairs(properties or {}) do item[key] = value end
    item.Parent = parent
    return item
end
local function round(item) make("UICorner", "Corner", item, {CornerRadius=UDim.new(0,8)}) end
local function label(name, parent, size, bold)
    return make("TextLabel", name, parent, {BackgroundTransparency=1, Font=bold and Enum.Font.FredokaOne or Enum.Font.Gotham,
        TextSize=size, TextColor3=ink, TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top})
end
local function button(name, parent, text, colour)
    local b = make("TextButton", name, parent, {Text=text, Font=Enum.Font.GothamBold, TextSize=18,
        BackgroundColor3=colour, TextColor3=ink, BorderSizePixel=0})
    round(b)
    return b
end
function UI.Preview(viewport, asset)
    viewport:ClearAllChildren()
    local source = Practice.Asset(asset)
    if not source then return end
    local clone = source:Clone()
    -- Keep the real geometry and textures, not scripts, prompts, or answer labels.
    for _, child in ipairs(clone:GetDescendants()) do
        if child:IsA("LuaSourceContainer") or child:IsA("LayerCollector") or child:IsA("ProximityPrompt")
            or child:IsA("ClickDetector") or child:IsA("JointInstance") or child:IsA("WeldConstraint") then child:Destroy() end
    end
    local model = Instance.new("Model")
    clone.Parent = model
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false end
    end
    local cf, size = model:GetBoundingBox()
    model:PivotTo(CFrame.new(-cf.Position) * model:GetPivot())
    local scene = make("WorldModel", "PreviewWorld", viewport)
    model.Name, model.Parent = "ActualProp", scene
    local camera = make("Camera", "PreviewCamera", viewport, {FieldOfView=38})
    local direction = Vector3.new(1.2,.8,1.5).Unit
    local rotation = CFrame.lookAt(direction,Vector3.zero)
    local aspect = viewport.AbsoluteSize.Y>0 and viewport.AbsoluteSize.X/viewport.AbsoluteSize.Y or 3.9
    local tangent = math.tan(math.rad(camera.FieldOfView/2))
    local distance = 0
    for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
        local corner = (cf-cf.Position):VectorToWorldSpace(Vector3.new(x*size.X/2,y*size.Y/2,z*size.Z/2))
        local projected = rotation:VectorToObjectSpace(corner)
        distance = math.max(distance,projected.Z+math.abs(projected.Y)/tangent,projected.Z+math.abs(projected.X)/(tangent*aspect))
    end end end
    camera.CFrame = CFrame.lookAt(direction*distance*1.18,Vector3.zero)
    viewport.CurrentCamera = camera
    viewport.Ambient, viewport.LightColor, viewport.LightDirection = Color3.fromRGB(190,190,190), Color3.new(1,1,1), Vector3.new(-1,-1,-1)
end
function UI.Create(frame, bounds, options)
    options = options or {}
    for _, child in ipairs(frame:GetChildren()) do child:Destroy() end
    frame.Visible, frame.BorderSizePixel, frame.BackgroundTransparency = false, 0, .03
    frame.BackgroundColor3 = Color3.new(1,1,1)
    frame.AnchorPoint = Vector2.new(0,1)
    round(frame)
    require(script.Parent.KidTheme).DialoguePaper(frame,Color3.fromRGB(255,244,209))
    make("UIStroke", "Outline", frame, {Color=yellow, Thickness=2})
    local header = make("Frame", "Header", frame, {BackgroundColor3=yellow, BorderSizePixel=0, Size=UDim2.new(1,0,0,56)})
    round(header)
    local badge = label("Badge", header, 20, true)
    badge.Position, badge.Size = UDim2.fromOffset(8,6), UDim2.fromOffset(44,44)
    badge.TextColor3 = ink
    local speaker = label("Speaker", header, 20, true)
    speaker.Position, speaker.Size, speaker.TextColor3 = UDim2.fromOffset(62,16), UDim2.new(1,-110,0,28), ink
    local close = button("Close", header, "X", yellow)
    close.Position, close.Size = UDim2.new(1,-42,0,8), UDim2.fromOffset(34,40)
    local title = label("Title", frame, 22, true)
    local body = label("Body", frame, 19, false)
    body.Font = Enum.Font.GothamBold
    body.LineHeight = 1.1
    local preview = make("ViewportFrame", "PropPreview", frame, {BackgroundColor3=Color3.fromRGB(255,246,202), BorderSizePixel=0})
    round(preview)
    local caption = label("Caption", frame, 14, false)
    local equation = label("Equation", frame, 18, true)
    equation.TextColor3 = ink
    local back = button("PreviousPage", frame, utf8.char(8592), yellow)
    local nextButton = button("AcceptButton", frame, "Next", yellow)
    local count = label("PageCount", frame, 14, false)
    count.TextYAlignment = Enum.TextYAlignment.Center
    local controller = {Frame=frame, Pages={}, Index=1}
    local function height(text, size, font, width)
        return math.ceil(TextService:GetTextSize(text,size,font,Vector2.new(width,1000)).Y)
    end
    local function layout()
        local width = math.min(420,math.max(280,bounds.AbsoluteSize.X-24))
        local inside = width-28
        local titleHeight = height(title.Text,22,Enum.Font.FredokaOne,inside)
        body.TextSize = bounds.AbsoluteSize.Y < 470 and 18 or 19
        local bodyHeight = height(body.Text,body.TextSize,body.Font,inside)*1.1
        local y = 68
        title.Position, title.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(inside,titleHeight)
        y += titleHeight+8
        body.Position, body.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(inside,bodyHeight)
        y += bodyHeight+10
        local available = bounds.AbsoluteSize.Y-24
        local extra = equation.Visible and height(equation.Text,18,Enum.Font.FredokaOne,inside)+10 or 0
        local previewHeight = math.clamp(available-y-extra-86,50,100)
        preview.Position, preview.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(inside,previewHeight)
        y += previewHeight+4
        caption.Position, caption.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(inside,18)
        y += 24
        equation.Position, equation.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(inside,extra)
        y += extra
        back.Position, back.Size = UDim2.fromOffset(14,y),UDim2.fromOffset(44,42)
        count.Position, count.Size = UDim2.fromOffset(68,y),UDim2.fromOffset(100,42)
        nextButton.Position, nextButton.Size = UDim2.fromOffset(width-168,y),UDim2.fromOffset(154,42)
        frame.Position, frame.Size = UDim2.new(0,12,1,-12),UDim2.fromOffset(width,y+54)
    end
    function controller:Hide()
        frame.Visible = false
        if options.OnClose then options.OnClose() end
    end
    function controller:Render()
        local page = self.Pages[self.Index]
        if not page then return end
        title.Text, body.Text, caption.Text = page.Title or "",page.Body or "",page.Caption or ""
        equation.Text, equation.Visible = (page.Equation or ""):gsub(" / "," "..utf8.char(247).." "):gsub(" x "," "..utf8.char(215).." "),page.Equation ~= nil
        UI.Preview(preview,page.Asset)
        back.Visible, count.Visible = self.Index>1,#self.Pages>1
        count.Text = self.Index.." / "..#self.Pages
        nextButton.Text = self.Index<#self.Pages and "Next "..utf8.char(8594) or self.FinalLabel
        layout()
    end
    function controller:Show(pages, settings)
        settings = settings or {}
        self.Pages,self.Index,self.FinalLabel = pages,1,settings.FinalLabel or "Done"
        speaker.Text = settings.Speaker or "A little hint"
        KidUI.Portrait(badge,settings.Model)
        self:Render()
        frame.Visible = true
    end
    back.Activated:Connect(function() controller.Index=math.max(1,controller.Index-1);controller:Render() end)
    nextButton.Activated:Connect(function()
        if controller.Index<#controller.Pages then controller.Index+=1;controller:Render();return end
        frame.Visible = false
        if options.OnFinish then options.OnFinish() end
    end)
    close.Activated:Connect(function() controller:Hide() end)
    bounds:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
    return controller
end
function UI.Notifier(gui, bounds)
    local notice = label("PracticeNotice",gui,19,true)
    notice.AnchorPoint,notice.Position = Vector2.new(.5,1),UDim2.new(.5,0,1,-18)
    notice.BackgroundTransparency,notice.BackgroundColor3,notice.TextWrapped = .05,Color3.new(1,1,1),true
    notice.Visible,notice.Text = false,""
    round(notice)
    require(script.Parent.KidTheme).DialoguePaper(notice,Color3.fromRGB(255,244,209))
    make("UIStroke","Outline",notice,{Color=yellow,Thickness=2,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    make("UIPadding","Padding",notice,{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,12),PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10)})
    local token = 0
    local playerGui = gui.Parent
    playerGui:GetAttributeChangedSignal("PracticeHintOpen"):Connect(function()
        if playerGui:GetAttribute("PracticeHintOpen") then token += 1; notice.Visible=false end
    end)
    return function(message)
        if playerGui:GetAttribute("PracticeHintOpen") then return end
        token += 1
        local current = token
        local width = math.min(520,bounds.AbsoluteSize.X-24)
        local lines = TextService:GetTextSize(message,notice.TextSize,notice.Font,Vector2.new(width-24,1000)).Y
        notice.Text,notice.Size,notice.Visible = message,UDim2.fromOffset(width,lines+22),true
        task.delay(5,function() if current==token then notice.Visible=false end end)
    end
end
return UI
