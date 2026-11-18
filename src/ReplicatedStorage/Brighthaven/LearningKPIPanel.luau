local Panel={}
local ink=Color3.fromRGB(22,38,49)
local paper=Color3.fromRGB(255,252,239)
local function make(class,parent,properties)
    local item=Instance.new(class)
    for key,value in pairs(properties) do item[key]=value end
    item.Parent=parent
    return item
end
local function paint(item,color)
    item.BackgroundColor3=color
    item:SetAttribute("SemanticColor",color)
end
local function corner(item,radius)
    make("UICorner",item,{CornerRadius=UDim.new(0,radius)})
end
local function text(class,parent,name,value,size,position,textSize,bold)
    local item=make(class,parent,{Name=name,Text=value,Size=size,Position=position,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=textSize,TextColor3=ink,
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,BackgroundTransparency=1,ZIndex=12})
    item:SetAttribute("SemanticTextColor",ink)
    return item
end
local function ratio(correct,attempts)
    if attempts==0 then return "No data yet",0 end
    return string.format("%d%% · %d/%d",math.round(100*correct/attempts),correct,attempts),correct/attempts
end
function Panel.Create(gui)
    local frame=make("Frame",gui,{Name="LearningKPIPanel",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
        Visible=false,BorderSizePixel=0,ZIndex=10})
    paint(frame,paper)
    corner(frame,14)
    local limits=make("UISizeConstraint",frame,{MaxSize=Vector2.new(508,620)})
    local title=text("TextLabel",frame,"Title","My Learning",UDim2.new(1,-208,0,38),UDim2.fromOffset(59,8),18,true)
    title.TextScaled=true
    make("UITextSizeConstraint",title,{MinTextSize=13,MaxTextSize=21})
    local toggle=text("TextButton",frame,"ExpandCollapse","Collapse",UDim2.fromOffset(88,36),UDim2.new(1,-139,0,9),14,true)
    local close=text("TextButton",frame,"Close","×",UDim2.fromOffset(38,36),UDim2.new(1,-44,0,9),22,true)
    local back=text("TextButton",frame,"Back","←",UDim2.fromOffset(42,36),UDim2.fromOffset(10,9),23,true)
    for _,button in ipairs({back,toggle,close}) do
        button.BackgroundTransparency=0
        button.TextXAlignment=Enum.TextXAlignment.Center
        paint(button,Color3.fromRGB(255,229,154))
        corner(button,8)
    end
    -- Build the arrow from shapes so it stays visible in every UI font.
    back.Text=""
    for _,line in ipairs({{13,17,17,3,0},{12,13,10,3,-45},{12,21,10,3,45}}) do
        local stroke=make("Frame",back,{Position=UDim2.fromOffset(line[1],line[2]),
            Size=UDim2.fromOffset(line[3],line[4]),Rotation=line[5],BorderSizePixel=0,ZIndex=13})
        paint(stroke,ink)
        corner(stroke,2)
    end
    close.Activated:Connect(function() frame.Visible=false end)
    local body=make("ScrollingFrame",frame,{Name="Metrics",Position=UDim2.fromOffset(12,98),Size=UDim2.new(1,-24,1,-108),
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=11})
    make("UIListLayout",body,{Padding=UDim.new(0,7),SortOrder=Enum.SortOrder.LayoutOrder})
    local tracks={}
    local metrics={
        {"DivisionAccuracy","Division","÷",Color3.fromRGB(108,192,247)},
        {"TrialAttempts","Tries","2x",Color3.fromRGB(255,183,116)},
        {"CompletionTime","Task time","",Color3.fromRGB(176,154,239)},
        {"ChunkingQuality","Chunking","▦",Color3.fromRGB(112,214,194)},
        {"RemainderHandling","Remainders","+1",Color3.fromRGB(249,150,183)},
        {"BudgetingPerformance","Budgeting","₱",Color3.fromRGB(144,203,113)},
        {"BoostUsage","Boost challenges","★",Color3.fromRGB(249,195,74)},
    }
    for index,metric in ipairs(metrics) do
        local row=make("Frame",body,{Name=metric[1],Size=UDim2.new(1,-7,0,78),LayoutOrder=index,
            BorderSizePixel=0,ZIndex=11})
        paint(row,metric[4]:Lerp(Color3.new(1,1,1),.84))
        corner(row,9)
        local icon=text("TextLabel",row,"Icon",metric[3],UDim2.fromOffset(37,37),UDim2.fromOffset(8,10),23,true)
        icon.BackgroundTransparency=0
        icon.TextXAlignment=Enum.TextXAlignment.Center
        paint(icon,metric[4])
        corner(icon,11)
        if metric[1]=="CompletionTime" then
            local clock=make("Frame",icon,{Size=UDim2.fromOffset(20,20),Position=UDim2.fromOffset(8,8),
                BackgroundTransparency=1,ZIndex=13})
            corner(clock,10)
            make("UIStroke",clock,{Color=ink,Thickness=2})
            for _,hand in ipairs({{Size=UDim2.fromOffset(2,7),Position=UDim2.fromOffset(9,4)},
                {Size=UDim2.fromOffset(6,2),Position=UDim2.fromOffset(9,10)}}) do
                hand.BackgroundColor3=ink
                hand.BorderSizePixel=0
                hand.ZIndex=13
                make("Frame",clock,hand)
            end
        end
        text("TextLabel",row,"Metric",metric[2],UDim2.new(1,-63,0,20),UDim2.fromOffset(54,5),17,true)
        local value=text("TextLabel",row,"Value","No data yet",UDim2.new(1,-63,0,34),UDim2.fromOffset(54,23),16,true)
        local track=make("Frame",row,{Name="Track",Position=UDim2.fromOffset(54,63),Size=UDim2.new(1,-66,0,8),
            BorderSizePixel=0,ClipsDescendants=true,ZIndex=12})
        paint(track,Color3.fromRGB(223,230,235))
        corner(track,4)
        local fill=make("Frame",track,{Name="Fill",Size=UDim2.fromScale(0,1),BorderSizePixel=0,ZIndex=13})
        paint(fill,metric[4])
        corner(fill,4)
        tracks[index]={Value=value,Fill=fill}
    end
    local tabs=make("Frame",frame,{Name="Tabs",Position=UDim2.fromOffset(12,54),Size=UDim2.new(1,-24,0,36),
        BackgroundTransparency=1,ZIndex=11})
    local numbers=text("TextButton",tabs,"Numbers","My numbers",UDim2.new(.5,-4,1,0),UDim2.fromOffset(0,0),14,true)
    local again=text("TextButton",tabs,"TryAgain","Try again",UDim2.new(.5,-4,1,0),UDim2.fromScale(.5,0),14,true)
    for _,button in ipairs({numbers,again}) do
        button.TextXAlignment=Enum.TextXAlignment.Center
        button.BackgroundTransparency=0
        corner(button,7)
    end
    local review=make("ScrollingFrame",frame,{Name="AnswerReview",Position=body.Position,Size=body.Size,
        BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,CanvasSize=UDim2.new(),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=false,ZIndex=11})
    make("UIListLayout",review,{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder})
    local function reviewRow(name,message,order,color)
        local row=text("TextLabel",review,name,message,UDim2.new(1,-8,0,0),UDim2.new(),15,order<=2)
        row.LayoutOrder=order
        row.AutomaticSize=Enum.AutomaticSize.Y
        row.BackgroundTransparency=0
        paint(row,color)
        corner(row,7)
        make("UIPadding",row,{PaddingTop=UDim.new(0,7),PaddingBottom=UDim.new(0,7),
            PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9)})
        return row
    end
    local soft=Color3.fromRGB(244,240,218)
    local summary=reviewRow("Summary","0 answers to try again",1,Color3.fromRGB(255,229,154))
    local breakdown=reviewRow("BySkill","",2,soft)
    local recentRows={}
    for index=1,12 do
        recentRows[index]=reviewRow("Answer"..index,"",index+3,soft)
    end
    local expanded,showReview=false,false
    local function refreshTabs()
        tabs.Visible=expanded
        body.Visible=expanded and not showReview
        review.Visible=expanded and showReview
        local on,off=Color3.fromRGB(255,229,154),Color3.fromRGB(231,240,231)
        paint(numbers,showReview and off or on)
        paint(again,showReview and on or off)
    end
    numbers.Activated:Connect(function() showReview=false;refreshTabs() end)
    again.Activated:Connect(function() showReview=true;refreshTabs() end)
    local api={Frame=frame,Back=back}
    function api:SetExpanded(value)
        expanded=value
        refreshTabs()
        limits.MaxSize=Vector2.new(508,value and 620 or 54)
        frame.Size=value and UDim2.new(1,-28,1,-100) or UDim2.new(1,-28,0,54)
        toggle.Text=value and "Collapse" or "Expand"
    end
    toggle.Activated:Connect(function() api:SetExpanded(not expanded) end)
    function api:Show()
        showReview=false
        self:SetExpanded(true)
        review.CanvasPosition=Vector2.zero
        body.CanvasPosition=Vector2.zero
        frame.Visible=true
    end
    function api:Update(state,legacy,schoolReview)
        local journey=state and state.LearningKPIs or {}
        local mission=legacy or {}
        local verified=(journey.VerifyAttempts or 0)+(mission.VerifyAttempts or 0)
        local correct=(journey.VerifyCorrect or 0)+(mission.CorrectMissions or 0)
        local chunks=(journey.ChunkAttempts or 0)+(mission.SchoolMathAttempts or 0)
        local goodChunks=(journey.ChunkCorrect or 0)+(mission.SchoolMathCorrect or 0)
        local routed=(journey.RemainderCorrect or 0)+(mission.RemainderPlans or 0)
        local remainders=(journey.RemainderAttempts or 0)+(mission.RemainderErrors or 0)+(mission.RemainderPlans or 0)
        local timed=(journey.TimedTasks or 0)+(mission.TimedTasks or 0)
        local savedCampaignCompletions=0
        for _,done in pairs(state and state.Completed or {}) do
            if done==true then savedCampaignCompletions+=1 end
        end
        local campaignCompletions=math.max(savedCampaignCompletions,journey.VerifyCorrect or 0)
        local completed=math.max(timed,correct,(mission.MissionsCompleted or 0)+campaignCompletions)
        local rounds=mission.ChunkSteps or 0
        local seconds=(journey.TaskSeconds or 0)+(mission.TaskSeconds or 0)
        local answered=(mission.BoostWins or 0)+(mission.BoostLosses or 0)
        local started=math.max(mission.BoostStarted or 0,answered)
        local attempts=verified+chunks+remainders
        local successes=correct+goodChunks+routed
        local budget=journey.BudgetAttempts or 0
        local values={
            {ratio(correct,verified)},
            {string.format("%d tries · %d right",attempts,successes),attempts>0 and successes/attempts or 0},
            {timed>0 and string.format("%.1f s avg · %d/%d timed",seconds/timed,timed,completed)
                or completed>0 and (completed.." done · no time") or "No timed tasks",
                completed>0 and timed/completed or 0},
            {ratio(goodChunks,chunks)},
            {ratio(routed,remainders)},
            {ratio(journey.BudgetCorrect or 0,budget)},
            {string.format("%d started · %d tried · %d right",started,answered,mission.BoostWins or 0),
                started>0 and answered/started or 0},
        }
        if rounds>0 then
            values[4][1]=chunks>0 and (values[4][1].." · "..rounds.." rounds shared") or (rounds.." rounds shared · no scored checks")
        elseif chunks==0 then values[4][1]="No chunk checks" end
        if remainders==0 then values[5][1]="No remainder checks" end
        if verified==0 then values[1][1]="No division checks" end
        if budget==0 then values[6][1]="No budget checks" end
        if budget==0 and (mission.BudgetMissionsCompleted or 0)>0 then
            values[6][1]=mission.BudgetMissionsCompleted.." completed · no scored attempts"
        end
        if showReview then
            local counts,entries={},{}
            for _,data in ipairs({state and state.AnswerReview or {},schoolReview or {}}) do
                for skill,count in pairs(data.Counts or {}) do counts[skill]=(counts[skill] or 0)+count end
                for _,entry in ipairs(data.Recent or {}) do table.insert(entries,entry) end
            end
            table.sort(entries,function(a,b)
                return a.At>b.At or a.At==b.At and a.Id<b.Id
            end)
            local total=0
            local lines={}
            local names={"Division","Multiplication","Subtraction","Skip counting","Remainders","Budgeting","Boost"}
            local most,mostCount=nil,0
            for _,skill in ipairs(names) do
                local count=counts[skill] or 0
                if count>0 then
                    total+=count
                    table.insert(lines,skill.."  "..count)
                    if count>mostCount then most,mostCount=skill,count end
                end
            end
            summary.Text=total==0 and "Nothing to retry yet"
                or string.format("%d missed %s · Try %s",total,total==1 and "answer" or "answers",most)
            breakdown.Visible=total>0
            breakdown.Text=table.concat(lines,"    •    ")
            for index,row in ipairs(recentRows) do
                local answer=entries[index]
                row.Visible=answer~=nil
                if answer then
                    local your=tostring(answer.Answer)
                    local correct=tostring(answer.Expected)
                    if answer.Extra~=nil then your..=" r "..answer.Extra end
                    if answer.ExpectedExtra~=nil then correct..=" r "..answer.ExpectedExtra end
                    row.Text=answer.Skill.." · "..answer.Label.."\nYours: "..your.." · Right: "..correct
                end
            end
        end
        for index,track in ipairs(tracks) do
            track.Value.Text=values[index][1]
            track.Fill.Size=UDim2.fromScale(math.clamp(values[index][2],0,1),1)
        end
    end
    api:SetExpanded(false)
    return api
end
return Panel
