local Checker={}
local ink=Color3.fromRGB(36,51,57)
local paper=Color3.fromRGB(250,252,248)
local function make(class,parent,properties)
    local object=Instance.new(class)
    for key,value in pairs(properties) do object[key]=value end
    object.Parent=parent
    return object
end
local function label(parent,name,size,bold)
    return make("TextLabel",parent,{Name=name,BackgroundTransparency=1,Text="",TextWrapped=true,Size=size,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=bold and 18 or 15,
        TextXAlignment=Enum.TextXAlignment.Left,TextColor3=ink})
end
function Checker.Create(gui,player)
    local frame=make("Frame",gui,{Name="ProgressChecker",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
        Size=UDim2.new(1,-28,1,-100),Visible=false,BackgroundColor3=paper,BorderSizePixel=0,ZIndex=10})
    make("UISizeConstraint",frame,{MaxSize=Vector2.new(508,560)})
    make("UICorner",frame,{CornerRadius=UDim.new(0,14)})
    local title=label(frame,"Title",UDim2.new(1,-76,0,44),true)
    title.Position=UDim2.fromOffset(18,9)
    title.Text="My Progress"
    title.ZIndex=11
    local close=make("TextButton",frame,{Name="Close",Text="×",Font=Enum.Font.GothamBold,TextSize=26,
        TextColor3=ink,BackgroundColor3=Color3.fromRGB(237,242,235),Position=UDim2.new(1,-56,0,9),
        Size=UDim2.fromOffset(42,42),ZIndex=11})
    make("UICorner",close,{CornerRadius=UDim.new(0,8)})
    close.Activated:Connect(function() frame.Visible=false end)
    local openKPIs=make("TextButton",frame,{Name="OpenKPIs",Text="My Learning  ›",
        Position=UDim2.fromOffset(18,58),Size=UDim2.new(1,-36,0,42),Font=Enum.Font.GothamBold,
        TextSize=17,TextColor3=ink,BackgroundColor3=Color3.fromRGB(255,229,154),BorderSizePixel=0,ZIndex=11})
    make("UICorner",openKPIs,{CornerRadius=UDim.new(0,9)})
    local body=make("ScrollingFrame",frame,{Name="Skills",Position=UDim2.fromOffset(18,110),Size=UDim2.new(1,-36,1,-70),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=11})
    make("UIListLayout",body,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
    local level=label(body,"MasteryLevel",UDim2.new(1,-10,0,32),true)
    level.ZIndex=11
    local tracks={}
    local definitions={
        {"XP to next level",Color3.fromRGB(43,108,156)},
        {"Multiplication",Color3.fromRGB(111,75,159)},
        {"Chunking",Color3.fromRGB(37,120,103)},
        {"Division",Color3.fromRGB(37,107,167)},
        {"Subtraction",Color3.fromRGB(166,92,35)},
        {"Skip counting",Color3.fromRGB(98,113,47)},
    }
    for index,definition in ipairs(definitions) do
        local row=make("Frame",body,{Name=definition[1],Size=UDim2.new(1,-10,0,50),
            BackgroundTransparency=1,ZIndex=11,LayoutOrder=index})
        local text=label(row,"Value",UDim2.new(1,0,0,28),false)
        text.ZIndex=12
        local bar=make("Frame",row,{Name="Track",Position=UDim2.fromOffset(0,33),Size=UDim2.new(1,0,0,9),
            BackgroundColor3=Color3.fromRGB(220,230,224),BorderSizePixel=0,ZIndex=12})
        make("UICorner",bar,{CornerRadius=UDim.new(1,0)})
        local fill=make("Frame",bar,{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=definition[2],
            BorderSizePixel=0,ZIndex=13})
        make("UICorner",fill,{CornerRadius=UDim.new(1,0)})
        tracks[index]={Text=text,Fill=fill}
    end
    local summary=label(body,"Checklist",UDim2.new(1,-10,0,46),false)
    summary.ZIndex=11
    summary.LayoutOrder=#definitions+1
    local activity=label(body,"ActivityTotals",UDim2.new(1,-10,0,52),false)
    activity.ZIndex=11
    activity.LayoutOrder=#definitions+2
    local api={Frame=frame}
    function api:Update(state,storyDone,storyTotal,mission)
        local stats=state and state.Progress
        level.Text=stats and ("Mastery level "..stats.Level.."  ·  "..stats.Rank) or "Loading mastery…"
        local tutorials=0
        for i=1,3 do
            if player:GetAttribute("Tutorial"..i.."Practice")=="complete" then tutorials+=1 end
        end
        local forklift=player:GetAttribute("Tutorial3Practice")=="complete" and 1 or 0
        local sharing=player:GetAttribute("Tutorial1Practice")=="complete" and 1 or 0
        local counting=player:GetAttribute("Tutorial2Practice")=="complete" and 1 or 0
        local chunks=(stats and stats.CheckedChunkingJobs or 0)+forklift
        local school=state and state.SchoolComplete and 1 or 0
        local division=chunks+sharing+school
        local values={stats and stats.LevelXP or 0,chunks,chunks,division,chunks,counting}
        local goals={stats and stats.NextLevelXP or 100,5,5,5,5,1}
        for index,item in ipairs(tracks) do
            local value,goal=values[index],goals[index]
            local unit=index==1 and " XP" or index==6 and " tutorial" or " checked activities"
            local progress=index~=1 and value>goal and (value..unit.."  ·  goal met") or (value.." / "..goal..unit)
            item.Text.Text=definitions[index][1].."   "..progress
            item.Fill.Size=UDim2.fromScale(math.clamp(value/goal,0,1),1)
        end
        local verified=state and state.LearningKPIs and state.LearningKPIs.VerifyCorrect or 0
        local saved=0
        for _,done in pairs(state and state.Completed or {}) do
            if done==true then saved+=1 end
        end
        verified=math.max(verified,saved)
        local schoolCompleted=mission and mission.MissionsCompleted or 0
        activity.Text=stats and mission and string.format("%d XP · %d division jobs\n%d missions done",
            stats.XP or 0,stats.DivisionTasks or 0,schoolCompleted+verified)
            or "Loading totals…"
        summary.Text="Tutorials  "..tutorials.." / 3   ·   Story quests  "..storyDone.." / "..storyTotal
    end
    return api
end
return Checker
