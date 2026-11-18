local Practice=require(game.ReplicatedStorage.Brighthaven.TutorialPractice)
local Quests=require(game.ReplicatedStorage.Brighthaven.Campaign.QuestData)
local Side=require(game.ReplicatedStorage.Brighthaven.Campaign.SideQuestData)
local Data=require(game.ReplicatedStorage.Brighthaven.Campaign.CampaignData)
local Guidebook={}
local colours={Color3.fromRGB(255,211,78),Color3.fromRGB(255,211,78),Color3.fromRGB(255,211,78),
    Color3.fromRGB(255,211,78),Color3.fromRGB(255,211,78)}
local ink=Color3.fromRGB(48,52,55)
local function make(class,props,parent)
    local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent;return o
end
local function label(parent,name,text,y,height,size,bold)
    return make("TextLabel",{Name=name,Position=UDim2.fromOffset(18,y),Size=UDim2.new(1,-36,0,height),
        Text=text,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        BackgroundTransparency=1,TextColor3=ink,Font=bold and Enum.Font.GothamBlack or Enum.Font.GothamBold,
        TextSize=size or 18},parent)
end
function Guidebook.Create(parent, options)
    options = options or {}
    local self={Page=1,State=nil,Practicing=nil}
    local view=make("Frame",{Name="GuidebookPages",Position=UDim2.fromOffset(12,58),Size=UDim2.new(1,-24,1,-70),
        BackgroundTransparency=1,Visible=false},parent)
    self.View=view
    local left=make("Frame",{Name="ContentsPage",Size=UDim2.new(.32,-8,1,-54),
        BackgroundColor3=Color3.fromRGB(255,246,202),BorderSizePixel=0},view)
    local right=make("ScrollingFrame",{Name="ReadingPage",Position=UDim2.new(.32,8,0,0),Size=UDim2.new(.68,-8,1,-54),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ScrollBarThickness=3,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},view)
    local binding=make("Frame",{Name="Binding",Position=UDim2.new(.32,-3,0,0),Size=UDim2.new(0,6,1,-54),
        BackgroundColor3=Color3.fromRGB(224,173,39),BorderSizePixel=0},view)
    for i=1,6 do make("Frame",{Name="BookRing",Position=UDim2.new(0,-5,(i-.5)/6,-3),
        Size=UDim2.fromOffset(16,6),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},binding) end
    label(left,"ContentsTitle","My Chapters",8,28,18,true)
    local tabs=make("Frame",{Name="ChapterTabs",Position=UDim2.fromOffset(10,44),Size=UDim2.new(1,-20,0,190),
        BackgroundTransparency=1},left)
    local preview=make("ViewportFrame",{Name="MemoryPicture",Position=UDim2.fromOffset(10,246),Size=UDim2.new(1,-20,1,-258),
        BackgroundTransparency=1,Ambient=Color3.fromRGB(205,205,205),LightColor=Color3.new(1,1,1),
        LightDirection=Vector3.new(-1,-1,-1)},left)
    local camera=make("Camera",{FieldOfView=35},preview);preview.CurrentCamera=camera
    local modelWorld=make("WorldModel",{},preview)
    local pageCount=make("TextLabel",{Name="PageCount",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-6),
        Size=UDim2.fromOffset(110,40),Text="",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundTransparency=1},view)
    local back=make("TextButton",{Name="PreviousPage",Position=UDim2.new(0,0,1,-46),Size=UDim2.fromOffset(100,40),
        Text="< Back",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundColor3=colours[1],BorderSizePixel=0},view)
    local nextPage=make("TextButton",{Name="NextPage",AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,0,1,-46),Size=UDim2.fromOffset(100,40),
        Text="Next >",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundColor3=colours[1],BorderSizePixel=0},view)
    for _,b in ipairs({back,nextPage}) do make("UICorner",{CornerRadius=UDim.new(0,8)},b) end
    local titles={"Practice","My Progress","Our Story","Helping Jobs","Machine Parts"}
    local function picture()
        modelWorld:ClearAllChildren()
        local asset=self.Page==1 and Practice.Asset("supply") or self.Page==3 and Practice.Asset("forklift") or Practice.Asset("receiving")
        if not asset then return end
        local clone=asset:Clone()
        if not clone then return end
        local model=Instance.new("Model");model.Parent=modelWorld;clone.Parent=model
        for _,o in ipairs(model:GetDescendants()) do
            if o:IsA("LuaSourceContainer") or o:IsA("ProximityPrompt") or o:IsA("ClickDetector") or o:IsA("LayerCollector") or o:IsA("Humanoid") then o:Destroy()
            elseif o:IsA("BasePart") then o.Anchored=true;o.CanCollide=false end
        end
        local c,size=model:GetBoundingBox()
        local radius=math.max(size.X,size.Y,size.Z)*1.65
        camera.CFrame=CFrame.lookAt(c.Position+Vector3.new(radius*.65,radius*.45,radius),c.Position)
    end
    local function metric(name, title, value, y, fraction)
        local card=make("Frame",{Name=name,Position=UDim2.fromOffset(12,y),Size=UDim2.new(1,-24,0,84),
            BackgroundColor3=Color3.fromRGB(255,246,202),BorderSizePixel=0},right)
        make("UICorner",{CornerRadius=UDim.new(0,8)},card)
        label(card,"Metric",title,5,25,15,true)
        label(card,"Value",value,30,30,19,true)
        if fraction then
            local bar=make("Frame",{Name="Track",Position=UDim2.fromOffset(18,68),Size=UDim2.new(1,-36,0,7),
                BackgroundColor3=Color3.fromRGB(231,217,174),BorderSizePixel=0},card)
            make("Frame",{Name="Fill",Size=UDim2.fromScale(math.clamp(fraction,0,1),1),
                BackgroundColor3=Color3.fromRGB(40,144,97),BorderSizePixel=0},bar)
        end
    end
    local function row(text,status,y,done)
        local r=make("Frame",{Name="ProgressRow",Position=UDim2.fromOffset(18,y),Size=UDim2.new(1,-36,0,54),BackgroundTransparency=1},right)
        make("TextLabel",{Name="Item",Size=UDim2.new(1,-102,1,0),Text=text,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,
            TextColor3=ink,Font=Enum.Font.GothamBold,TextSize=18,BackgroundTransparency=1},r)
        make("TextLabel",{Name="Status",Position=UDim2.new(1,-98,0,0),Size=UDim2.fromOffset(98,54),Text=status,TextWrapped=true,
            TextColor3=ink,Font=Enum.Font.GothamBlack,TextSize=16,BackgroundTransparency=1},r)
        make("Frame",{Name="Rule",Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1),
            BackgroundColor3=Color3.fromRGB(255,235,166),BorderSizePixel=0},r)
    end
    function self:Render()
        right:ClearAllChildren();tabs:ClearAllChildren();right.CanvasPosition=Vector2.zero
        local total=self.Practicing and 2 or 5
        self.Page=math.clamp(self.Page,1,total)
        for i=1,total do
            local tab=make("TextButton",{Name="Chapter"..i,Position=UDim2.fromOffset(0,(i-1)*38),Size=UDim2.new(1,0,0,34),
                Text=(self.Page==i and "> " or "")..titles[i],TextWrapped=true,Font=Enum.Font.GothamBold,TextSize=16,
                TextColor3=ink,
                BackgroundColor3=colours[i],BackgroundTransparency=self.Page==i and 0 or 1,BorderSizePixel=0},tabs)
            tab.Activated:Connect(function() self.Page=i;self:Render() end)
        end
        local heading=make("Frame",{Name="ChapterRibbon",Size=UDim2.new(1,0,0,48),BackgroundColor3=colours[self.Page],BorderSizePixel=0},right)
        local h=label(heading,"ChapterTitle",titles[self.Page],0,48,22,true);h.TextColor3=ink
        local s=self.State
        if self.Page==1 then
            label(right,"Subtitle","My practice journey",58,30,20,true)
            for i,name in ipairs({"Equal Sharing","Skip Counting","Forklift Chunks"}) do
                local status=self.Player:GetAttribute("Tutorial"..i.."Practice")
                row(i..". "..name,status=="complete" and "Done!" or status=="active" and "Trying" or "Not yet",100+(i-1)*60,status=="complete")
            end
            local complete=0
            for i=1,3 do
                if self.Player:GetAttribute("Tutorial"..i.."Practice")=="complete" then complete+=1 end
            end
            metric("TutorialProgress","Tutorials completed",complete.." / 3",288,complete/3)
        elseif self.Page==2 and self.Practicing then
            label(right,"BigTitle","Helping earns XP!",66,54,26,true)
            label(right,"Note","A quest is a helping job. Finish a job in BrightHaven to earn experience points, called XP.",138,90,20)
            label(right,"Reminder","Practice is for learning. XP starts in the town.",254,60,18,true)
        elseif not s then label(right,"Waiting","Your guidebook is getting ready.",78,80,20)
        elseif self.Page==2 then
            local stats=s.Progress
            local done=0
            for _,quest in ipairs(Quests.Chapters) do
                if Quests.Done(s,quest.Id) then done+=1 end
            end
            local levelXP=stats.NextLevelXP or 100
            local jobs=stats.DivisionTasks or 0
            local current=Quests.Current(s)
            local gate=s.GameLocks and s.GameLocks[current.Id]
            local needsJobs=gate and not gate.Unlocked and gate.JobsNeeded>0
            metric("Mastery","Mastery level","Level "..stats.Level,60)
            metric("LevelXP","XP toward next level",stats.LevelXP.." / "..levelXP.." XP",154,stats.LevelXP/levelXP)
            metric("StoryProgress","Story quests completed",done.." / "..#Quests.Chapters,248,done/#Quests.Chapters)
            metric("DivisionJobs","Division jobs checked",needsJobs and (jobs.." / "..gate.RequiredPractice) or tostring(jobs),342,
                needsJobs and jobs/gate.RequiredPractice or nil)
            local nextStep=s.StoryFinished and "Story complete" or current.Title
            if needsJobs then
                nextStep..="\nCheck "..gate.JobsNeeded.." more division "..(gate.JobsNeeded==1 and "job" or "jobs").." to unlock."
            elseif gate and not gate.Unlocked and gate.Reason~="" then
                nextStep..="\n"..gate.Reason
            end
            label(right,"NextStep",nextStep,440,100,17,true)
        elseif self.Page==3 then
            local done=0;for _,q in ipairs(Quests.Chapters) do if Quests.Done(s,q.Id) then done+=1 end end
            local current=Quests.Current(s)
            label(right,"Act",Quests.Act(s).Title,62,64,22,true)
            label(right,"StoryCount",done.." / "..#Quests.Chapters.." quests finished",134,36,18)
            label(right,"Now",s.StoryFinished and "We helped BrightHaven!" or current.Title,182,64,24,true)
            local objective=s.StoryFinished and "Explore the town and help your neighbors." or Quests.Objective(s,Data)
            local width=math.max(80,right.AbsoluteSize.X-36)
            local objectiveHeight=math.max(88,game:GetService("TextService"):GetTextSize(objective,20,Enum.Font.GothamBold,Vector2.new(width,10000)).Y+20)
            label(right,"NextStep",objective,262,objectiveHeight,20)
            local gate=s.GameLocks and s.GameLocks[current.Id]
            local requirement=s.StoryFinished and "Everyone helped save BrightHaven!" or gate and "Needed: Level "..gate.RequiredLevel.." and "..gate.RequiredPractice.." checked division jobs." or "Follow your helper's next step."
            local requirementY=274+objectiveHeight
            local requirementHeight=math.max(64,game:GetService("TextService"):GetTextSize(requirement,18,Enum.Font.GothamBlack,Vector2.new(width,10000)).Y+20)
            label(right,"UnlockRequirement",requirement,requirementY,requirementHeight,18,true)
            local trackY=requirementY+requirementHeight+14
            local track=make("TextButton",{Name="TrackStory",Position=UDim2.fromOffset(18,trackY),Size=UDim2.new(1,-36,0,44),
                Text="Pin My Story Quest",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundColor3=colours[3],BorderSizePixel=0},right)
            track.Activated:Connect(function() if options.OnStoryTrack then options.OnStoryTrack() end end)
            local y=trackY+60
            for _,q in ipairs(Quests.Chapters) do
                local finished=Quests.Done(s,q.Id)
                local available=finished or q.Id==current.Id
                local rule=s.GameLocks and s.GameLocks[q.Id]
                local status=finished and "Done!" or rule and not rule.Unlocked and "Lv. "..rule.RequiredLevel or available and "Now" or "Locked"
                row(available and q.Title or "Story chapter "..q.Index,status,y,finished)
                y+=60
            end
        elseif self.Page==4 then
            local found,done=0,0
            for _,q in ipairs(Side.Quests) do
                if s.SideDiscovered and s.SideDiscovered[q.Id] then found+=1 end
                local p=s.SideQuests[q.Id];if p and p.Complete then done+=1 end
            end
            label(right,"Met",found.." helping jobs discovered",66,52,24,true)
            label(right,"Done",done.." helping jobs finished",132,52,24,true)
            label(right,"Hint","Talk to a neighbor to open their helping job.",192,60,20)
            local y=266
            for index,q in ipairs(Side.Quests) do
                local met=s.SideDiscovered and s.SideDiscovered[q.Id]==true
                local p=s.SideQuests[q.Id]
                row(met and q.Title or "Helping job "..index,not met and "Locked" or p and p.Complete and "Done!" or "Open",y,p and p.Complete)
                y+=60
                if met then
                    label(right,"Helper_"..q.Id,q.Speaker.."  |  "..q.XP.." XP",y,30,18,true);y+=36
                    label(right,"Task_"..q.Id,Side.Objective(q,p),y,64,18);y+=70
                    if not p or not p.Complete then
                        local track=make("TextButton",{Name="TrackSide_"..q.Id,Position=UDim2.fromOffset(18,y),Size=UDim2.new(1,-36,0,44),
                            Text="Pin "..q.Speaker.."'s Quest",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundColor3=colours[4],BorderSizePixel=0},right)
                        track.Activated:Connect(function() if options.OnSideTrack then options.OnSideTrack(q.Id) end end)
                        y+=52
                    end
                end
            end
        elseif self.Page==5 then
            local found,installed=0,0
            for i=1,#Data.PartNames do
                local key=tostring(i)
                if s.Parts[key] or s.InstalledParts[key] then found+=1 end
                if s.InstalledParts[key] then installed+=1 end
                local revealed=s.Parts[key] or s.InstalledParts[key]
                row(revealed and Data.PartNames[i] or "Machine part "..i,s.InstalledParts[key] and "Installed" or s.Parts[key] and "Found" or "Locked",98+(i-1)*60,s.InstalledParts[key])
            end
            label(right,"Summary",found.." found  |  "..installed.." installed",62,32,20,true)
            label(right,"Note","Follow the story to help repair the machine.",292,50,18)
        end
        pageCount.Text=self.Page.." / "..total
        back.Visible=self.Page>1;nextPage.Visible=self.Page<total
        picture()
    end
    function self:Show(state,practicing,player)
        self.State,self.Practicing,self.Player=state,practicing,player
        view.Visible=true;self:Render()
    end
    function self:Hide() view.Visible=false end
    back.Activated:Connect(function() self.Page-=1;self:Render() end)
    nextPage.Activated:Connect(function() self.Page+=1;self:Render() end)
    return self
end
return Guidebook
