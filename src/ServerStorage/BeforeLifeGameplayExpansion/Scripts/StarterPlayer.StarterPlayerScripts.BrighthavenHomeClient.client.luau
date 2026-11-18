local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local Prompts=game:GetService("ProximityPromptService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local shared=RS:WaitForChild("Brighthaven")
local Rules=require(shared:WaitForChild("HomeRules"))
local Practice=require(shared.TutorialPractice)
local Icons=require(shared.HudIcon)
local remote=shared:WaitForChild("WorldCare"):WaitForChild("Request")
local ink=Color3.fromRGB(48,52,55)
local yellow=Color3.fromRGB(255,211,78)
local function make(class,props,parent)
    local o=Instance.new(class);for k,v in props do o[k]=v end;o.Parent=parent;return o
end
local function round(o) make("UICorner",{CornerRadius=UDim.new(0,8)},o) end
local function label(parent,name,pos,size,value,fontSize)
    return make("TextLabel",{Name=name,Position=pos,Size=size,Text=value,TextSize=fontSize or 17,
        Font=Enum.Font.GothamBold,TextColor3=ink,BackgroundTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},parent)
end
local gui=make("ScreenGui",{Name="BrightHavenHome",ResetOnSpawn=false,DisplayOrder=75},pg)
local bounds=make("Frame",{Name="Bounds",Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
local clock=make("Frame",{Name="Clock",Position=UDim2.fromOffset(16,48),Size=UDim2.fromOffset(158,26),
    BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.08,BorderSizePixel=0,Visible=false},gui)
clock.Parent=require(shared.HudLayout).Topbar()
round(clock);make("UIStroke",{Color=yellow,Thickness=1.5},clock)
local time=label(clock,"Time",UDim2.fromOffset(9,0),UDim2.new(1,-18,1,0),"Day 1   07:00",15)
local toast=make("Frame",{Name="Notice",AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,62),Size=UDim2.fromOffset(380,100),
    BackgroundColor3=Color3.new(1,1,1),BackgroundTransparency=.03,BorderSizePixel=0,Visible=false},gui)
round(toast);make("UIStroke",{Color=yellow,Thickness=2},toast)
local noticeTitle=label(toast,"Title",UDim2.fromOffset(14,8),UDim2.new(1,-28,0,22),"",18)
noticeTitle.Font=Enum.Font.FredokaOne
local noticeBody=label(toast,"Body",UDim2.fromOffset(14,32),UDim2.new(1,-28,1,-40),"",15)
local panel=make("Frame",{Name="Home",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(530,460),
    BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Visible=false},gui)
round(panel);make("UIStroke",{Color=yellow,Thickness=3},panel)
local title=label(panel,"Title",UDim2.fromOffset(20,14),UDim2.new(1,-80,0,34),"My Home",26);title.Font=Enum.Font.FredokaOne
local close=make("TextButton",{Name="Close",Position=UDim2.new(1,-48,0,16),Size=UDim2.fromOffset(30,30),Text="X",
    TextSize=19,Font=Enum.Font.GothamBold,TextColor3=ink,BackgroundColor3=yellow,BorderSizePixel=0},panel);round(close)
local info=label(panel,"Info",UDim2.fromOffset(20,56),UDim2.new(1,-40,0,42),"",17)
local list=make("ScrollingFrame",{Name="Upgrades",Position=UDim2.fromOffset(20,110),Size=UDim2.new(1,-40,1,-230),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
make("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},list)
local rows={}
for i,item in Rules.Upgrades do
    local row=make("Frame",{Name=item.Id,Size=UDim2.new(1,-6,0,70),LayoutOrder=i,BackgroundColor3=Color3.fromRGB(255,249,225),BorderSizePixel=0},list);round(row)
    local icon=make("ImageLabel",{Name="Icon",Position=UDim2.fromOffset(12,22),Size=UDim2.fromOffset(30,30),BackgroundTransparency=1,
        Image=Icons.Asset(({WaterTank="Thirst",SnackShelf="Hunger",CozyBed="Health"})[item.Id]),ImageColor3=Color3.fromRGB(188,143,15)},row)
    label(row,"Name",UDim2.fromOffset(52,8),UDim2.new(1,-168,0,22),item.Name,17)
    label(row,"Description",UDim2.fromOffset(52,32),UDim2.new(1,-168,0,38),item.Description,14)
    local buy=make("TextButton",{Name="Buy",Position=UDim2.new(1,-104,0,18),Size=UDim2.fromOffset(92,42),Text=item.Cost.." coins",
        TextSize=16,Font=Enum.Font.GothamBold,TextColor3=ink,BackgroundColor3=yellow,BorderSizePixel=0},row);round(buy)
    rows[item.Id]=buy
end
local feedback=label(panel,"Feedback",UDim2.fromOffset(20,0),UDim2.new(1,-40,0,40),"",15)
feedback.Position=UDim2.new(0,20,1,-114)
local sleepButton=make("TextButton",{Name="Sleep",Position=UDim2.new(0,20,1,-62),Size=UDim2.new(1,-40,0,42),Text="Sleep Until 07:00",
    TextSize=18,Font=Enum.Font.GothamBold,TextColor3=ink,BackgroundColor3=yellow,BorderSizePixel=0},panel);round(sleepButton)
local state,busy=nil,false
local function otherModal()
    for _,key in ipairs({"WorldMapOpen","BagOpen","TaxiUIOpen","SchoolShuttleUIOpen","WorldActivityOpen"}) do if pg:GetAttribute(key) then return true end end
    for name,children in pairs({BrightHavenQuests={"QuestBook"},BrighthavenLocation12={"CaptainDialogue","MissionPanel","SchoolSolution"},
        BrightHavenSideDialogue={"Dialogue"},BrightHavenStoryExtension={"Dialogue"}}) do
        local screen=pg:FindFirstChild(name)
        if screen then for _,childName in children do local child=screen:FindFirstChild(childName);if child and child.Visible then return true end end end
    end
    return player:GetAttribute("BrighthavenFlashbackPlaying")==true
end
local function closePanel()
    panel.Visible=false;pg:SetAttribute("HomeUIOpen",false)
    local house=workspace.BrighthavenHomes:FindFirstChild("Home_"..player.UserId)
    if house then for _,name in ipairs({"Exit","Bed","Upgrades"}) do
        local prompt=house[name]:FindFirstChildOfClass("ProximityPrompt");if prompt then prompt.Enabled=true end
    end end
end
local function invoke(action,payload)
    if busy then return end;busy=true
    local ok,result=pcall(function() return remote:InvokeServer(action,payload or {}) end)
    busy=false
    if ok and type(result)=="table" then
        state=result;feedback.Text=result.Message or ""
    else feedback.Text="Please try again in a moment." end
    return ok and result
end
local function openPanel()
    if otherModal() then return end
    pg:SetAttribute("HomeUIOpen",true);panel.Visible=true
    invoke("Get")
end
for id,button in rows do button.Activated:Connect(function() invoke("Upgrade",{Id=id}) end) end
sleepButton.Activated:Connect(function() invoke(player:GetAttribute("Sleeping") and "Wake" or "Sleep") end)
close.Activated:Connect(function()
    if player:GetAttribute("Sleeping") then invoke("Wake") end
    closePanel()
end)
Prompts.PromptTriggered:Connect(function(prompt,p)
    if p and p~=player then return end
    if prompt:GetAttribute("HomeOwner")~=player.UserId then return end
    if prompt.Name=="HomeBed" or prompt.Name=="HomeUpgrades" then openPanel()
    elseif prompt.Name=="HomeExit" then closePanel();invoke("Exit") end
end)
UIS.InputBegan:Connect(function(input,used)
    if not used and input.KeyCode==Enum.KeyCode.Escape and panel.Visible then
        if player:GetAttribute("Sleeping") then invoke("Wake") end
        closePanel()
    end
end)
local titles={rain="Rain Is Starting",curfew="Time to Go Home",final="Final Curfew Reminder",reward="Quest Supplies",clinic="A Visit to Nurse Ana",morning="A New Day",sleep="Rest Time",needs="Time for Food and Water"}
local queue={}
local current,shownAt=nil,0
local function enqueue(kind,message)
    if kind=="clinic" or kind=="morning" then
        current=nil
        for i=#queue,1,-1 do if queue[i].Kind~="reward" then table.remove(queue,i) end end
    end
    for _,item in queue do if item.Kind==kind and item.Message==message then return end end
    table.insert(queue,{Kind=kind,Message=message})
    if #queue>6 then table.remove(queue,1) end
end
shared.WorldCare.Notice.OnClientEvent:Connect(enqueue)
player.CharacterAdded:Connect(closePanel)
player:GetAttributeChangedSignal("Sleeping"):Connect(function()
    if panel.Visible and not player:GetAttribute("Sleeping") then
        local minutes=RS:GetAttribute("TownMinutes") or 420
        feedback.Text=minutes>=420 and minutes<1080 and "Good morning! You are ready for a new day." or "You got up."
    end
end)
local phaseSeen,emptySeen={},nil
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.2 then return end;local step=elapsed;elapsed=0
    local usable=player:GetAttribute("HasStartedGame")==true and player:GetAttribute("EnteredMainWorld")==true and Practice.CanUseWorld(player)
    local modal=otherModal()
    if not usable or modal or not player:GetAttribute("HomeInteriorActive") then closePanel() end
    local minutes=RS:GetAttribute("TownMinutes") or 420
    local day=RS:GetAttribute("TownDay") or 1
    time.Text="Day "..day.."   "..Rules.FormatTime(minutes)
    clock.Visible=usable and not modal and not panel.Visible
    time.TextColor3=(minutes>=1320 or minutes<420) and Color3.fromRGB(159,92,14) or ink
    if usable and not modal then
        local phase=minutes>=1350 and "final" or minutes>=1320 or minutes<420
        phase=phase==true and "curfew" or phase
        if not phase and RS:GetAttribute("BrightHavenRaining") then phase="rain" end
        local key=tostring(day)..":"..tostring(phase)
        if phase and not phaseSeen[key] then
            phaseSeen[key]=true
            local home=player:GetAttribute("HomeInteriorActive")
            local message=phase=="final" and "It is 22:30, the final warning. Go home now and sleep until 07:00."
                or phase=="curfew" and "It is curfew. Rain is falling. Head home and sleep until 07:00."
                or "Rain is starting. Head home to stay dry. Rest in your bed to wake up at 07:00."
            if home then message="You are safe at home. Rest in your bed until 07:00." end
            enqueue(phase,message)
        end
        local empty=(player:GetAttribute("Hunger") or 100)<=0 or (player:GetAttribute("Thirst") or 100)<=0
        if empty and not emptySeen then enqueue("needs","You are tired and losing health. Eat a Food Pack and drink water from your bag. Quests give free supplies!") end
        emptySeen=empty
    end
    local canShow=usable and not modal and not panel.Visible and not player:GetAttribute("Sleeping")
    if canShow and not current and #queue>0 then current=table.remove(queue,1);shownAt=0 end
    toast.Visible=canShow and current~=nil
    if toast.Visible then
        noticeTitle.Text=titles[current.Kind] or "BrightHaven";noticeBody.Text=current.Message
        shownAt+=step;if shownAt>=8 then current=nil;toast.Visible=false end
    end
    local screen=bounds.AbsoluteSize
    toast.Size=UDim2.fromOffset(math.min(380,screen.X-32),110)
    panel.Size=UDim2.fromOffset(math.min(530,screen.X-32),math.min(460,screen.Y-32))
    if panel.Visible then
        local house=workspace.BrighthavenHomes:FindFirstChild("Home_"..player.UserId)
        if house then for _,name in ipairs({"Exit","Bed","Upgrades"}) do
            local prompt=house[name]:FindFirstChildOfClass("ProximityPrompt");if prompt then prompt.Enabled=false end
        end end
        info.Text=player:GetAttribute("Sleeping") and "Resting until 07:00. You can get up while you wait."
            or "Your coins: "..tostring(player:GetAttribute("Coins") or 0).."   |   Wake up at 07:00"
        sleepButton.Text=busy and "One moment..." or player:GetAttribute("Sleeping") and "Get Up" or "Sleep Until 07:00"
        sleepButton.Active=not busy
        for id,button in rows do
            local item=Rules.ById[id];local owned=state and state.Upgrades and state.Upgrades[id]
            local affordable=(player:GetAttribute("Coins") or 0)>=item.Cost
            button.Text=owned and "Owned" or (item.Cost.." coins")
            button.Active=not busy and not owned and affordable and not player:GetAttribute("Sleeping")
            button.BackgroundColor3=button.Active and yellow or Color3.fromRGB(229,233,233)
        end
    end
end)
