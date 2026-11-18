local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local TextService=game:GetService("TextService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local RS=game:GetService("ReplicatedStorage")
local Practice=require(RS.Brighthaven.TutorialPractice)
local remotes=RS.Brighthaven:WaitForChild("Tutorial3Remotes")
local tutorial=workspace["Possible Map Replacement"].Tutorial.Tutorial_3
local area=tutorial:WaitForChild("ForkliftPractice")
local car=tutorial:WaitForChild("TutorialForklift")
local state,owner,busy,note,noteUntil
local ink=Color3.fromRGB(48,52,55)
local blue=Color3.fromRGB(255,211,78)
local function make(class,props,parent)
    local o=Instance.new(class); for k,v in pairs(props) do o[k]=v end; o.Parent=parent; return o
end
local function round(o) make("UICorner",{CornerRadius=UDim.new(0,8)},o) end
local gui=make("ScreenGui",{Name="Tutorial3Deliveries",ResetOnSpawn=false,DisplayOrder=43},pg)
local bounds=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
local dock=make("ScrollingFrame",{Name="SideGuide",Position=UDim2.fromOffset(12,76),Size=UDim2.new(0,324,1,-88),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,
    CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false},gui)
make("UIPadding",{PaddingTop=UDim.new(0,3),PaddingBottom=UDim.new(0,3),PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,7)},dock)
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,12)},dock)
local header=make("Frame",{Name="DeliveryRecord",LayoutOrder=1,
    Size=UDim2.new(1,0,0,100),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Visible=false},dock)
round(header); make("UIStroke",{Color=blue,Thickness=2},header)
make("TextLabel",{Name="Title",Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-70,0,24),Text="Kargada Quest",
    BackgroundTransparency=1,TextColor3=ink,Font=Enum.Font.GothamBlack,TextSize=20,TextXAlignment=Enum.TextXAlignment.Left},header)
local tips=make("TextButton",{Name="Tips",Position=UDim2.new(1,-54,0,6),Size=UDim2.fromOffset(44,36),
    Text="?",Font=Enum.Font.GothamBlack,TextSize=22,TextColor3=ink,BackgroundColor3=Color3.fromRGB(255,211,78),BorderSizePixel=0},header)
round(tips)
local goal=make("TextLabel",{Name="Goal",Position=UDim2.fromOffset(12,38),Size=UDim2.new(1,-24,0,48),
    BackgroundTransparency=1,TextWrapped=true,TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=18,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},header)
local totals=make("TextLabel",{Name="Totals",Position=UDim2.fromOffset(12,38),Size=UDim2.new(1,-24,0,23),
    BackgroundTransparency=1,TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left},header)
local counts=make("TextLabel",{Name="CrateChunks",Position=UDim2.fromOffset(12,67),Size=UDim2.new(1,-24,0,22),
    BackgroundTransparency=1,TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left},header)
local roundSummary=make("TextLabel",{Name="RoundSummary",Position=UDim2.fromOffset(12,96),Size=UDim2.new(1,-24,0,22),
    BackgroundTransparency=1,TextColor3=Color3.fromRGB(48,52,55),Font=Enum.Font.GothamBold,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left},header)
local panel=make("Frame",{Name="DeliveryControls",LayoutOrder=2,
    Size=UDim2.new(1,0,0,212),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Visible=false},dock)
round(panel); make("UIStroke",{Color=Color3.fromRGB(255,211,78),Thickness=2},panel)
local instruction=make("TextLabel",{Name="Instruction",Position=UDim2.fromOffset(14,10),Size=UDim2.new(1,-28,0,50),
    BackgroundTransparency=1,TextWrapped=true,TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=18,
    TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},panel)
local actions=make("Frame",{Name="Actions",Position=UDim2.fromOffset(14,70),Size=UDim2.new(1,-28,0,48),BackgroundTransparency=1},panel)
local feedback=make("TextLabel",{Name="Feedback",Position=UDim2.fromOffset(14,126),Size=UDim2.new(1,-86,0,50),
    BackgroundTransparency=1,TextWrapped=true,TextColor3=Color3.fromRGB(48,52,55),Font=Enum.Font.GothamBold,
    TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},panel)
local recover=make("TextButton",{Name="Recover",Position=UDim2.new(1,-58,1,-54),Size=UDim2.fromOffset(44,40),
    Text="R",Font=Enum.Font.GothamBlack,TextSize=20,TextColor3=ink,BackgroundColor3=Color3.fromRGB(255,211,78),BorderSizePixel=0},panel)
round(recover)
local tooltip=make("TextLabel",{Name="RecoverHint",Size=UDim2.new(1,-86,0,40),Position=UDim2.new(0,14,1,-54),
    Text="Rescue forklift",TextSize=16,Font=Enum.Font.GothamBold,TextColor3=ink,BackgroundTransparency=1,Visible=false},panel)
round(tooltip)
recover.MouseEnter:Connect(function() tooltip.Visible=true end)
recover.MouseLeave:Connect(function() tooltip.Visible=false end)
local function request(action,payload)
    if busy then return end; busy=true
    local ok,r=pcall(function() return remotes.Request:InvokeServer(action,payload or {}) end)
    busy=false
    if ok and r then
        if r.State then state=r.State end
        owner=r.Owner
        if r.Message and r.Message~="" then note=r.Message; noteUntil=os.clock()+7 end
    else note="Please try again."; noteUntil=os.clock()+5 end
end
remotes.StateChanged.OnClientEvent:Connect(function(r)
    if r.State then state=r.State end
    owner=r.Owner
    if r.Message and r.Message~="" then note=r.Message; noteUntil=os.clock()+7 end
end)
tips.Activated:Connect(function()
    pg:SetAttribute("PracticeHelpStage",nil); pg:SetAttribute("PracticeHelpStage",3)
end)
recover.Activated:Connect(function() request("Recover") end)
local key
local function button(name,text,x,width,callback)
    local b=make("TextButton",{Name=name,Position=UDim2.new(x,0,0,0),Size=UDim2.new(width,-6,1,0),
        BackgroundColor3=blue,TextColor3=ink,Text=text,TextWrapped=true,TextSize=18,
        Font=Enum.Font.GothamBold,BorderSizePixel=0},actions)
    round(b); b.Activated:Connect(callback)
end
local function answerBox(name,placeholder,submit)
    local input=make("TextBox",{Name=name,Size=UDim2.new(.58,-8,1,0),Text="",PlaceholderText=placeholder,
        ClearTextOnFocus=false,Font=Enum.Font.GothamBold,TextSize=20,TextColor3=ink,
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},actions)
    round(input)
    local border=make("UIStroke",{ApplyStrokeMode=Enum.ApplyStrokeMode.Border,Color=Color3.fromRGB(163,167,171),Thickness=1},input)
    border:SetAttribute("SemanticColor",Color3.fromRGB(163,167,171))
    local function check() submit(input.Text) end
    input.FocusLost:Connect(function(enterPressed) if enterPressed then check() end end)
    button("Check","Check",.58,.42,check)
end
local beam,from,to,beamRoot,beamTarget
local function guide(target)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if root==beamRoot and target==beamTarget then return end
    if beam then beam:Destroy() end
    if from then from:Destroy() end
    if to then to:Destroy() end
    beamRoot,beamTarget=root,target
    if not root or not target then return end
    from=make("Attachment",{Position=Vector3.new(0,1,0)},root)
    to=make("Attachment",{},target)
    beam=make("Beam",{Attachment0=from,Attachment1=to,Width0=.35,Width1=.35,FaceCamera=true,
        LightEmission=1,Color=ColorSequence.new(Color3.fromRGB(255,208,63)),Transparency=NumberSequence.new(.15)},root)
end
local function hideGuide()
    dock.Visible=false; header.Visible=false; panel.Visible=false; tooltip.Visible=false
    guide(nil)
end
for _,attribute in {"PracticeHintOpen","WorldMapOpen","BagOpen","TaxiUIOpen"} do
    pg:GetAttributeChangedSignal(attribute):Connect(function()
        if pg:GetAttribute(attribute) then hideGuide() end
    end)
end
local watchedOverlays={}
local function watchOverlay(overlay)
    if not overlay or watchedOverlays[overlay] then return end
    watchedOverlays[overlay]=true
    overlay:GetPropertyChangedSignal("Visible"):Connect(function()
        if overlay.Visible then hideGuide() end
    end)
end
local elapsed=0
local measured={}
local function textHeight(label,width)
    local entry=measured[label]
    if not entry or entry.Text~=label.Text or entry.Width~=width or entry.Font~=label.Font then
        entry={Text=label.Text,Width=width,Font=label.Font,
            Height=TextService:GetTextSize(label.Text,label.TextSize,label.Font,Vector2.new(width,1000)).Y+4}
        measured[label]=entry
    end
    return math.max(label.TextSize+4,entry.Height)
end
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt; if elapsed<.15 then return end; elapsed=0
    local inStage=Practice.PlayerStage(player)==3
    local other=pg:FindFirstChild("DialogueSystem")
    local brief=other and other:FindFirstChild("PracticeBriefing")
    local dialogue=other and other:FindFirstChild("Frame")
    local blocked=pg:GetAttribute("PracticeHintOpen") or pg:GetAttribute("WorldMapOpen") or (brief and brief.Visible)
        or (dialogue and dialogue.Visible) or pg:GetAttribute("BagOpen") or pg:GetAttribute("TaxiUIOpen")
    local questGui=pg:FindFirstChild("BrightHavenQuests")
    local journal=questGui and questGui:FindFirstChild("QuestBook")
    watchOverlay(brief); watchOverlay(dialogue); watchOverlay(journal)
    blocked=blocked or (journal and journal.Visible)
    local active=inStage and state and player:GetAttribute("Tutorial3Practice")~=nil
    local notice=other and other:FindFirstChild("PracticeNotice")
    if active and notice and notice.Visible then
        note=notice.Text; noteUntil=os.clock()+7; notice.Visible=false
    end
    dock.Visible=active and not blocked
    header.Visible=active and not blocked
    panel.Visible=active and not blocked
    if not dock.Visible then tooltip.Visible=false end
    if not active then guide(inStage and not blocked and Practice.Anchors[3] or nil); return end
    local available=state.Remaining-state.Cargo
    goal.Text="Goal: share "..state.Total.." boxes equally among 3 crates."
    totals.Text=available.." at bay   |   "..state.Cargo.." on board"
    local lines={}
    for id=1,3 do
        local chunks=state.Chunks[id]
        table.insert(lines,id..": "..(#chunks==0 and "empty" or table.concat(chunks," + ")))
    end
    counts.Text="Crates   "..table.concat(lines,"     ")
    local width=math.min(324,bounds.AbsoluteSize.X-24)
    dock.Size=UDim2.fromOffset(width,math.max(100,bounds.AbsoluteSize.Y-88))
    local textWidth=width-34
    local history=state.History[#state.History]
    local goalHeight=textHeight(goal,textWidth)
    goal.Size=UDim2.new(1,-24,0,goalHeight)
    local totalsY=38+goalHeight+6
    totals.TextWrapped=true
    local totalsHeight=textHeight(totals,textWidth)
    totals.Position=UDim2.fromOffset(12,totalsY)
    totals.Size=UDim2.new(1,-24,0,totalsHeight)
    counts.TextWrapped=true
    counts.Position=UDim2.fromOffset(12,totalsY+totalsHeight+6)
    local countsHeight=textHeight(counts,textWidth)
    counts.Size=UDim2.new(1,-24,0,countsHeight)
    roundSummary.TextWrapped=true
    roundSummary.Visible=history~=nil
    if history then roundSummary.Text="Equal round: 3 x "..history.Amount.." = "..history.Used.." moved; "..history.Remaining.." left" end
    local summaryY=totalsY+totalsHeight+6+countsHeight+6
    local summaryHeight=history and textHeight(roundSummary,textWidth) or 0
    roundSummary.Position=UDim2.fromOffset(12,summaryY)
    roundSummary.Size=UDim2.new(1,-24,0,summaryHeight)
    header.Size=UDim2.new(1,0,0,summaryY+summaryHeight+8)
    local help="Keep each round fair."
    local pending=state.RoundMath and state.RoundMath.PendingChunk
    local mode,target="drive",area.LoadingBay
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    local driving=car.DriveSeat.Occupant==h and owner==player.UserId
    if state.Checked then
        mode="done"; instruction.Text="Practice finished! Follow the yellow guide to the exit gate. Press E to enter BrightHaven."
        target=workspace.Portal5.Teleport
    elseif state.Complete then
        mode="check"; instruction.Text="How many boxes are in one crate? Add its chunks, then check your answer."
        target=area.Crates.Crate1.Base
    elseif owner~=player.UserId then
        mode="waiting"; instruction.Text="Talk to the Warehouse Worker to continue when the forklift is free."
        target=Practice.Anchors[3]
    elseif not driving then
        mode="sit"; instruction.Text="Sit in the yellow forklift. Move with W, A, S, D or the arrow keys."
        target=car.DriveSeat
    elseif state.Cargo>0 then
        instruction.Text="Drive this chunk to a crate's colored bay. Stop, then unload."
        target=nil
        for id=1,3 do
            if not state.Delivered[id] then
                local p=area.Crates["Crate"..id].DeliveryBay
                if not target then target=p end
                if (Vector3.new(car.DriveSeat.Position.X,0,car.DriveSeat.Position.Z)-Vector3.new(p.Position.X,0,p.Position.Z)).Magnitude<=9 then
                    mode="deliver"..id; target=p; break
                end
            end
        end
    else
        local distance=(Vector3.new(car.DriveSeat.Position.X,0,car.DriveSeat.Position.Z)-Vector3.new(area.LoadingBay.Position.X,0,area.LoadingBay.Position.Z)).Magnitude
        if distance<=13 then
            if state.RoundPlan then
                mode="load"
                instruction.Text="Plan ready! Load "..state.RoundChunk.." box"..(state.RoundChunk==1 and "" or "es").." for one crate. Every crate gets the same load."
                help="One chunk per trip. Finish all three crates before planning again."
            elseif pending then
                mode=pending.Step
                if mode=="multiply" then
                    instruction.Text="Count this fair round: 3 x "..pending.Quotient.." = ? boxes. Each crate gets the same load."
                    help="Factors: 3 crates and "..pending.Quotient.." boxes per load. Add your load size three times."
                else
                    instruction.Text="After all three loads: "..pending.Before.." - "..pending.Product.." = ? boxes left."
                    help="Take away the boxes you counted for this round. Work out what will be left."
                end
            else
                mode="choose"
                local smaller=state.MainChunk and state.Remaining<state.MainChunk*3
                instruction.Text=smaller and "Plan the leftover boxes. Choose a smaller equal load for each of the three crates." or "Start with equal sharing. How many boxes will you put in each crate on this round?"
                help="Choose boxes per crate. Next, use your factors to count the whole round."
            end
        else instruction.Text="Drive to the loading bay. One chunk per trip. Count a full round with 3 x your chunk." end
    end
    feedback.Text=note and os.clock()<(noteUntil or 0) and note or help
    local hasActions=mode=="choose" or mode=="multiply" or mode=="subtract" or mode=="load" or mode=="check" or mode:sub(1,7)=="deliver"
    local instructionHeight=textHeight(instruction,width-38)
    instruction.Size=UDim2.new(1,-28,0,instructionHeight)
    actions.Position=UDim2.fromOffset(14,instructionHeight+20)
    actions.Visible=hasActions
    local feedbackY=instructionHeight+(hasActions and 80 or 22)
    local feedbackHeight=textHeight(feedback,width-38)
    feedback.Position=UDim2.fromOffset(14,feedbackY)
    feedback.Size=UDim2.new(1,-28,0,feedbackHeight)
    panel.Size=UDim2.new(1,0,0,feedbackY+feedbackHeight+(state.Checked and 14 or 66))
    recover.Visible=not state.Checked
    guide(blocked and nil or target)
    local nextKey=mode..":"..tostring(state.RoundChunk)..":"..tostring(pending and pending.Token)
    if key~=nextKey then
        key=nextKey; actions:ClearAllChildren()
        if mode=="choose" then
            for amount=1,3 do
                local n=amount
                button("Choose"..n,n.." box"..(n==1 and "" or "es").." each",(n-1)/3,1/3,function() request("PlanChunk",{Amount=n}) end)
            end
        elseif mode=="multiply" or mode=="subtract" then
            local step,token=mode,pending.Token
            answerBox(mode=="multiply" and "MultiplyAnswer" or "SubtractAnswer","My answer",function(answer)
                request("PlanStep",{Step=step,Answer=answer,Token=token})
            end)
        elseif mode=="load" then
            local amount=state.RoundChunk
            button("Load","Load "..amount.." box"..(amount==1 and "" or "es"),0,1,function() request("Load",{Amount=amount}) end)
        elseif mode:sub(1,7)=="deliver" then
            local id=tonumber(mode:sub(8))
            button("Unload","Unload into Crate "..id,0,1,function() request("Deliver",{Crate=id}) end)
        elseif mode=="check" then
            answerBox("Answer","My answer",function(answer) request("Check",{Answer=answer}) end)
        end
    end
end)
player.CharacterRemoving:Connect(function() guide(nil) end)
task.spawn(function()
    request("GetState")
    while gui.Parent do
        task.wait(3)
        if Practice.PlayerStage(player)==3 then request("GetState") end
    end
end)
