local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local CAS=game:GetService("ContextActionService")
local StarterGui=game:GetService("StarterGui")
local PromptService=game:GetService("ProximityPromptService")
local Rules=require(script.Parent.ActivityRules)
local Sites=require(script.Parent.ActivitySites)
local Data=require(script.Parent.CampaignData)
local Client={}
local WasteIcons=require(game.ReplicatedStorage.Brighthaven.WasteIcons)
local yellow,white,ink=Color3.fromRGB(255,211,78),Color3.new(1,1,1),Color3.fromRGB(48,52,55)
local function make(class,props,parent) local v=Instance.new(class);for k,x in props do v[k]=x end;v.Parent=parent;return v end
local function round(v) make("UICorner",{CornerRadius=UDim.new(0,8)},v) end
local function item(parent,kind)
    local p=make("Part",{Name=kind,Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Size=Vector3.new(1.2,.4,1.2),Color=white},parent)
    if kind=="Wood" then p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(1.8,.7,.7);p.Color=Color3.fromRGB(174,126,79)
    elseif kind=="Plastic" then p.Size=Vector3.new(.65,1.4,.65);p.Color=Color3.fromRGB(102,188,228);p.Transparency=.15
    elseif kind=="Metal" then p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(1.3,.8,.8);p.Color=Color3.fromRGB(174,187,194);p.Material=Enum.Material.Metal end
    return p
end
function Client.Create(options)
    local player=Players.LocalPlayer;local pg=player.PlayerGui
    local jobs=require(script.Parent.WorldJobClient).Create(options)
    local active,busy,selected,chargeAt,tool,toolConnection=nil,false,"Paper",nil,nil,nil
    local savedBackpack,savedPrompts
    local activeScene,woodHighlight,woodBeam,woodFrom,woodTo
    local function clearWoodGuide()
        for _,v in ipairs({woodHighlight,woodBeam,woodFrom,woodTo}) do v:Destroy() end
        woodHighlight,woodBeam,woodFrom,woodTo=nil,nil,nil,nil
    end
    local function focus(enabled)
        if enabled and savedBackpack==nil then
            savedBackpack=StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.Backpack)
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false)
            savedPrompts=PromptService.Enabled;PromptService.Enabled=false
        elseif not enabled and savedBackpack~=nil then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,savedBackpack)
            PromptService.Enabled=savedPrompts;savedBackpack,savedPrompts=nil,nil
        end
    end
    local gui=make("ScreenGui",{Name="BrightHavenWorldActivity",ResetOnSpawn=false,DisplayOrder=85},pg)
    local panel=make("ScrollingFrame",{Name="Activity",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-20),Size=UDim2.fromOffset(450,192),CanvasSize=UDim2.new(),ScrollBarThickness=3,ScrollingDirection=Enum.ScrollingDirection.Y,BackgroundColor3=white,BackgroundTransparency=.04,BorderSizePixel=0,Visible=false},gui)
    round(panel);make("UIStroke",{Color=yellow,Thickness=3},panel)
    local function label(name,pos,size,value,font)
        return make("TextLabel",{Name=name,Position=pos,Size=size,Text=value,TextSize=font or 17,Font=Enum.Font.FredokaOne,TextColor3=ink,BackgroundTransparency=1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left},panel)
    end
    local title=label("Title",UDim2.fromOffset(14,8),UDim2.new(1,-72,0,30),"Sorting Shots",22)
    local guide=label("Guide",UDim2.fromOffset(14,42),UDim2.new(1,-28,0,40),"",17)
    local feedback=label("Feedback",UDim2.fromOffset(14,158),UDim2.new(1,-28,0,26),"",15)
    local woodGoal=label("Goal",UDim2.fromOffset(14,48),UDim2.new(1,-28,0,55),"",18)
    local woodSteps=label("Steps",UDim2.fromOffset(14,110),UDim2.new(1,-28,0,104),"",17)
    woodGoal.TextYAlignment=Enum.TextYAlignment.Top;woodSteps.TextYAlignment=Enum.TextYAlignment.Top
    woodGoal.Visible=false;woodSteps.Visible=false
    local close=make("TextButton",{Name="Close",Position=UDim2.new(1,-44,0,8),Size=UDim2.fromOffset(30,30),Text="X",TextSize=20,Font=Enum.Font.FredokaOne,TextColor3=ink,BackgroundColor3=yellow,BorderSizePixel=0},panel);round(close)
    local preview=make("ViewportFrame",{Name="CurrentItem",Position=UDim2.fromOffset(14,82),Size=UDim2.fromOffset(64,64),BackgroundColor3=Color3.fromRGB(255,240,190),BackgroundTransparency=.3,Ambient=Color3.new(1,1,1),LightColor=white},panel);round(preview)
    local previewWorld=make("WorldModel",{},preview)
    local camera=make("Camera",{CFrame=CFrame.lookAt(Vector3.new(2,1.6,3),Vector3.zero),FieldOfView=40},preview);preview.CurrentCamera=camera
    local itemLabel=label("ItemLabel",UDim2.fromOffset(84,84),UDim2.new(1,-100,0,20),"",16)
    local binButtons={}
    for i,name in Rules.Bins do
        local b=make("TextButton",{Name="Aim"..name,Position=UDim2.new(0,84+(i-1)*88,0,108),Size=UDim2.fromOffset(82,30),Text=name,Font=Enum.Font.FredokaOne,TextSize=16,TextColor3=ink,BackgroundColor3=white,BorderSizePixel=0},panel)
        round(b);make("UIStroke",{Color=yellow,Thickness=1},b);binButtons[name]=b
        b.Activated:Connect(function()
            selected=name
            for k,v in binButtons do
                v:SetAttribute("SemanticColor",k==selected and yellow or white)
                v.UIStroke.Thickness=k==selected and 3 or 1
            end
        end)
    end
    local fire=make("TextButton",{Name="Fire",Position=UDim2.new(1,-100,0,82),Size=UDim2.fromOffset(86,64),Text="Shoot",Font=Enum.Font.FredokaOne,TextSize=20,TextColor3=ink,BackgroundColor3=yellow,BorderSizePixel=0},panel);round(fire)
    local track=make("Frame",{Name="Power",Position=UDim2.fromOffset(84,143),Size=UDim2.new(1,-200,0,9),BackgroundColor3=Color3.fromRGB(214,218,224),BorderSizePixel=0},panel);round(track)
    local fill=make("Frame",{Name="Charge",Size=UDim2.fromScale(0,1),BackgroundColor3=yellow,BorderSizePixel=0},track);round(fill)
    track:SetAttribute("SemanticColor",Color3.fromRGB(214,218,224));fill:SetAttribute("SemanticColor",yellow)
    local star=make("TextLabel",{Name="ReleaseMark",Position=UDim2.fromScale(.75,-1),AnchorPoint=Vector2.new(.5,0),Size=UDim2.fromOffset(18,22),Text="\u{2605}",TextColor3=ink,TextSize=20,Font=Enum.Font.FredokaOne,BackgroundTransparency=1},track)
    local chopped=make("Folder",{Name="MyFirewoodPieces"},workspace)
    local function animateShot(shot)
        local object=item(workspace,shot.Item);local began=os.clock()
        local connection
        connection=RunService.RenderStepped:Connect(function()
            local t=math.min(os.clock()-began,shot.Duration)
            object.CFrame=CFrame.new(Rules.Position(shot,t))*CFrame.Angles(t*5,t*3,0)
            if t>=shot.Duration then connection:Disconnect();task.delay(.2,function() object:Destroy() end) end
        end)
    end
    local function refresh()
        if not active then return end
        local physical=active.Physical;local wood=physical.Kind=="chop"
        title.Text=wood and "Kahoy Kabayan" or "Sorting Shots  "..physical.Count.." / "..Rules.Required
        guide.Text="Choose the bin for this item. Hold Shoot, then release at the star."
        guide.Visible=not wood;woodGoal.Visible=wood;woodSteps.Visible=wood
        fire.Text=wood and (tool and "Chop" or "Get Axe") or "Shoot"
        for _,v in binButtons do v.Visible=not wood end
        track.Visible=true;star.Visible=not wood
        if wood then fill.Size=UDim2.fromScale(physical.Count/Rules.Required,1) end
        previewWorld:ClearAllChildren();item(previewWorld,wood and "Wood" or physical.Sequence[physical.Count+1] or "Paper")
        if not wood then WasteIcons.Draw(preview,physical.Sequence[physical.Count+1] or "Paper") else local old=preview:FindFirstChild("ClearWasteIcon");if old then old:Destroy() end end
        for name,b in binButtons do b:SetAttribute("SemanticColor",name==selected and yellow or white);b.UIStroke.Thickness=name==selected and 3 or 1 end
        itemLabel.Text=wood and "Cuts: "..physical.Count.." / "..Rules.Required or "Item: "..(physical.Sequence[physical.Count+1] or "Done")
        if wood then
            local mission=Data.ById[active.Id]
            woodGoal.Text="Goal: count equal "..mission.Divisor.."-meter pieces from "..mission.Dividend.." meters of wood."
            woodSteps.Text="1. Get the game axe.\n2. Walk to the yellow log marker.\n3. Chop "..Rules.Required.." times to clear the path.\nThen: count the wood in chunks."
            chopped:ClearAllChildren()
            local stump=activeScene.ChoppingLog
            for i=1,physical.Count do
                local p=item(chopped,"Firewood");p.Color=Color3.fromRGB(174,126,79);p.Shape=Enum.PartType.Cylinder;p.Size=Vector3.new(2.6,.8,.8)
                p.Position=stump.Position+Vector3.new(5+(i%3),-2.6,math.floor((i-1)/3)*1.2)
            end
            if not woodHighlight then
                local visual=activeScene:FindFirstChild("LogVisual")
                woodHighlight=make("Highlight",{Name="WoodActivityTarget",Adornee=visual and visual.Value or stump,FillTransparency=1,OutlineColor=yellow,OutlineTransparency=.1,DepthMode=Enum.HighlightDepthMode.Occluded},workspace)
                local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    woodFrom=make("Attachment",{Position=Vector3.new(0,1,0)},root)
                    woodTo=make("Attachment",{Position=Vector3.new(0,3,0)},stump)
                    woodBeam=make("Beam",{Attachment0=woodTo,Attachment1=woodFrom,Width0=1.1,Width1=1.1,FaceCamera=true,Texture="rbxassetid://10249261576",TextureLength=5,TextureSpeed=1,LightEmission=1,Color=ColorSequence.new(yellow),Transparency=NumberSequence.new(.2)},root)
                end
            end
        else
            clearWoodGuide();chopped:ClearAllChildren()
        end
    end
    local function finishResult(result)
        if not result then return end
        feedback.Text=result.Message or ""
        if result.State and result.State.Active then active=result.State.Active end
        if active and active.Phase~="activity" then
            refresh()
            panel.Visible=false;pg:SetAttribute("WorldActivityOpen",false);chargeAt=nil;focus(false)
            clearWoodGuide()
            CAS:UnbindAction("BrightHavenSortingShot");options.OnFinished()
        else refresh() end
    end
    local function chop()
        if busy or not active or active.Physical.Kind~="chop" then return end
        busy=true
        if tool then
            local swinging=tool;local original=swinging.Grip
            local tween=TweenService:Create(swinging,TweenInfo.new(.12),{Grip=original*CFrame.Angles(-.9,0,0)});tween:Play()
            task.delay(.18,function() if swinging.Parent then swinging.Grip=original end end)
        end
        local result=options.Request("ActivityChop")
        if result and result.Ok then
            local sound=make("Sound",{Name="WoodChop",SoundId="rbxasset://sounds/action_jump_land.mp3",Volume=.12,PlaybackSpeed=1.3},activeScene.ChoppingLog)
            sound:Play();game.Debris:AddItem(sound,4)
        end
        finishResult(result);busy=false
    end
    local function press()
        if not active or busy or not panel.Visible then return end
        if active.Physical.Kind=="chop" then
            if tool then chop()
            else local result=options.Request("ActivityEquip");feedback.Text=result and result.Message or "Try again." end
        else chargeAt=os.clock() end
    end
    local function release()
        if not chargeAt or busy or not active then return end
        local power=math.clamp((os.clock()-chargeAt)/1.2,0,1);chargeAt=nil;busy=true
        local result=options.Request("ActivityShoot",{Bin=selected,Power=power})
        if result and result.Shot then
            animateShot(result.Shot)
            task.wait(result.Shot.Duration)
        end
        fill.Size=UDim2.fromScale(0,1);finishResult(result);busy=false
    end
    fire.MouseButton1Down:Connect(press);fire.MouseButton1Up:Connect(release)
    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 and chargeAt then release() end
    end)
    local view={}
    function view:Hide()
        jobs:Hide()
        panel.Visible=false;chargeAt=nil;active=nil;focus(false)
        clearWoodGuide();chopped:ClearAllChildren();activeScene=nil
        pg:SetAttribute("WorldActivityOpen",false);CAS:UnbindAction("BrightHavenSortingShot")
    end
    function view:Show(a)
        if a.Physical.Kind~="sort" and a.Physical.Kind~="chop" then
            panel.Visible=false;focus(false);jobs:Show(a);return
        end
        jobs:Hide()
        active=a;activeScene=Sites.Resolve(player,a.Node);panel.Visible=true;focus(true);pg:SetAttribute("WorldActivityOpen",true)
        feedback.Text=a.Physical.Kind=="chop" and "This game axe stays in the wood area." or ""
        refresh()
        if a.Physical.Kind=="sort" then CAS:BindAction("BrightHavenSortingShot",function(_,state)
            if state==Enum.UserInputState.Begin then press() elseif state==Enum.UserInputState.End then release() end
            return Enum.ContextActionResult.Sink
        end,false,Enum.KeyCode.Space) end
    end
    close.Activated:Connect(function() view:Hide();options.OnClose() end)
    player.CharacterRemoving:Connect(function() view:Hide() end)
    for _,attribute in ipairs({"WorldMapOpen","BagOpen","TaxiUIOpen"}) do
        pg:GetAttributeChangedSignal(attribute):Connect(function()
            if panel.Visible and pg:GetAttribute(attribute) then view:Hide();options.OnClose() end
        end)
    end
    game.ProximityPromptService.PromptTriggered:Connect(function(prompt,p)
        if prompt.Name=="ActivityAxe" and (not p or p==player) and active then press() end
    end)
    local elapsed=0
    RunService.Heartbeat:Connect(function(dt)
        elapsed+=dt;if elapsed<.05 then return end;elapsed=0
        local width=math.min(450,math.max(260,workspace.CurrentCamera.ViewportSize.X-24))
        local narrow=width<440
        local wood=active and active.Physical.Kind=="chop"
        panel.AnchorPoint=wood and Vector2.new(1,0) or Vector2.new(.5,1)
        panel.Position=wood and UDim2.new(1,-14,0,78) or UDim2.new(.5,0,1,-20)
        panel.Size=UDim2.fromOffset(wood and math.min(324,width) or width,wood and math.min(424,math.max(180,workspace.CurrentCamera.ViewportSize.Y-100)) or (narrow and 250 or 192))
        panel.CanvasSize=UDim2.fromOffset(0,wood and 424 or (narrow and 250 or 192))
        preview.Position=UDim2.fromOffset(14,wood and 226 or 82)
        itemLabel.Position=UDim2.fromOffset(wood and 88 or 84,wood and 226 or 84)
        itemLabel.Size=UDim2.new(1,wood and -102 or -100,0,wood and 28 or 20)
        fire.Position=wood and UDim2.fromOffset(14,302) or UDim2.new(1,-100,0,narrow and 174 or 82)
        fire.Size=wood and UDim2.new(1,-28,0,42) or UDim2.fromOffset(86,64)
        feedback.Position=UDim2.fromOffset(14,wood and 352 or (narrow and 216 or 158))
        feedback.Size=UDim2.new(1,-28,0,wood and 60 or 26)
        track.Position=UDim2.fromOffset(wood and 88 or 84,wood and 270 or 143)
        track.Size=UDim2.new(1,wood and -102 or (narrow and -112 or -200),0,9)
        local available=width-(narrow and 112 or 194)
        for i,name in Rules.Bins do
            local b=binButtons[name];b.Position=UDim2.fromOffset(84+(i-1)*available/3,108)
            b.Size=UDim2.fromOffset(available/3-6,30)
        end
        if chargeAt then fill.Size=UDim2.fromScale(math.clamp((os.clock()-chargeAt)/1.2,0,1),1) end
        local c=player.Character;local axe=c and c:FindFirstChild("Wood Area Axe")
        if axe~=tool then
            if toolConnection then toolConnection:Disconnect();toolConnection=nil end
            tool=axe;if tool then toolConnection=tool.Activated:Connect(chop) end
            if active and active.Physical.Kind=="chop" then fire.Text=tool and "Chop" or "Get Axe" end
        end
        if panel.Visible and active then
            local r=c and c:FindFirstChild("HumanoidRootPart");local scene=activeScene
            if not r or (r.Position-scene.ActivityFloor.Position).Magnitude>Rules.ZoneRadius then view:Hide();options.OnClose() end
            local quests=pg:FindFirstChild("BrightHavenQuests")
            local book=quests and quests:FindFirstChild("QuestBook")
            if book and book.Visible then view:Hide();options.OnClose() end
        end
    end)
    return view
end
return Client
