local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local UIS=game:GetService("UserInputService")
local player=Players.LocalPlayer
local pg=player:WaitForChild("PlayerGui")
local folder=game.ReplicatedStorage:WaitForChild("Brighthaven")
local Locations=require(folder:WaitForChild("MapLocations"))
local Practice=require(folder.TutorialPractice)
local HudLayout=require(folder:WaitForChild("HudLayout"))
local request=folder.Transit:WaitForChild("TaxiRequest")
local FARE=folder.Transit:GetAttribute("Fare") or 10
local ink,green,yellow=Color3.fromRGB(48,52,55),Color3.fromRGB(23,128,108),Color3.fromRGB(255,211,78)
local iconAssets={
    X="rbxassetid://138390730174790",
    Landmark="rbxassetid://123824235933259",
    Axe="rbxassetid://73640950365224",
    Recycle="rbxassetid://128434729283561",
    FlaskConical="rbxassetid://98505449659972",
    Volleyball="rbxassetid://131168379687530",
    CarTaxiFront="rbxassetid://130541622809371",
    TrainFront="rbxassetid://133607552471876",
    Bike="rbxassetid://93244319037822",
    Zap="rbxassetid://126218319106766",
    CircleCheck="rbxassetid://106827529603950",
    Hospital="rbxassetid://118271627387330",
    School="rbxassetid://78967195537805",
    Store="rbxassetid://106942681580636",
    Coins="rbxassetid://98693973113274",
}
local locationIcons={hall="Landmark",school="School",clinic="Hospital",train="TrainFront",dumpsite="Recycle",
    wood="Axe",shop="Store",power="Zap",lab="FlaskConical",basketball="Volleyball",
    store1="Store",store2="Store",store3="Store",store4="Store"}
task.spawn(function()
    local assets={}
    for _,asset in pairs(iconAssets) do table.insert(assets,asset) end
    pcall(function() game:GetService("ContentProvider"):PreloadAsync(assets) end)
end)
local function make(class,properties,parent)
    local object=Instance.new(class);for key,value in pairs(properties) do object[key]=value end;object.Parent=parent;return object
end
local function round(object) make("UICorner",{CornerRadius=UDim.new(0,8)},object) end
local function picture(parent,name,asset,position,size)
    local image=make("ImageLabel",{Name=name,Image=iconAssets[asset],Position=position,Size=size,
        BackgroundTransparency=1,ImageColor3=ink,ScaleType=Enum.ScaleType.Fit},parent)
    image:SetAttribute("SemanticColor",ink)
    return image
end
local function selectTile(button,selected)
    button:SetAttribute("ThemeSelected",selected)
    button.Checked.Visible=selected
    button.Selection.Thickness=selected and 2 or 1
    button.Selection.Transparency=selected and 0 or .5
end
local gui=make("ScreenGui",{Name="BrightHavenTaxi",ResetOnSpawn=false,DisplayOrder=60,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},pg)
local bounds=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1},gui)
local call=make("TextButton",{Name="CallRide",AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-16,1,-152),
    Size=UDim2.fromOffset(56,56),Text="",BackgroundColor3=yellow,BorderSizePixel=0,Visible=false},gui)
round(call);require(folder.HudIcon).Attach(call,"rbxassetid://108617819328776","Call E-Bike or Tricycle",ink)
HudLayout.Action(call,5)
local panel=make("Frame",{Name="DestinationPicker",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    Size=UDim2.fromOffset(620,566),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Visible=false},gui)
round(panel);make("UIStroke",{Color=yellow,Thickness=3},panel)
local title=make("TextLabel",{Position=UDim2.fromOffset(20,12),Size=UDim2.new(1,-80,0,32),Text="Where Are We Going?",
    Font=Enum.Font.FredokaOne,TextSize=23,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},panel)
local close=make("TextButton",{Name="Close",Position=UDim2.new(1,-48,0,12),Size=UDim2.fromOffset(32,32),
    Text="",BackgroundColor3=Color3.fromRGB(237,243,244),BorderSizePixel=0,Modal=true},panel)
round(close);require(folder.HudIcon).Attach(close,iconAssets.X,"Close",ink)
close.Size=UDim2.fromOffset(32,32);close.Symbol.Size=UDim2.fromOffset(22,22)
local kind
local kindButtons={}
for i,name in ipairs({"E-Bike","Tricycle"}) do
    local button=make("TextButton",{Name=name,Position=UDim2.new((i-1)*.5,20-(i-1)*10,0,58),Size=UDim2.new(.5,-30,0,56),
        Text="",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,AutoButtonColor=false},panel)
    round(button);kindButtons[name]=button
    make("UIStroke",{Name="Selection",Color=yellow,Thickness=1,Transparency=.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},button):SetAttribute("SemanticColor",yellow)
    button:SetAttribute("ThemeSelected",false)
    picture(button,"RideIcon",name=="E-Bike" and "Bike" or "CarTaxiFront",UDim2.fromOffset(14,12),UDim2.fromOffset(32,32))
    make("TextLabel",{Name="Label",Position=UDim2.fromOffset(54,0),Size=UDim2.new(1,-86,1,0),Text=name,
        Font=Enum.Font.GothamBold,TextSize=18,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},button)
    local check=picture(button,"Checked","CircleCheck",UDim2.new(1,-28,.5,-9),UDim2.fromOffset(18,18));check.Visible=false
    button.Activated:Connect(function()
        kind=name
        for option,item in pairs(kindButtons) do
            selectTile(item,option==kind)
        end
    end)
end
make("TextLabel",{Name="PlacesHeading",Position=UDim2.fromOffset(20,124),Size=UDim2.new(1,-40,0,24),Text="Places",
    Font=Enum.Font.FredokaOne,TextSize=19,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},panel)
local list=make("ScrollingFrame",{Name="Destinations",Position=UDim2.fromOffset(20,154),Size=UDim2.new(1,-40,1,-288),
    BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=5,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y},panel)
list.ScrollBarImageColor3=yellow
make("UIPadding",{PaddingLeft=UDim.new(0,3),PaddingTop=UDim.new(0,3),PaddingRight=UDim.new(0,10),PaddingBottom=UDim.new(0,3)},list)
local grid=make("UIGridLayout",{CellSize=UDim2.new(1/3,-11,0,86),CellPadding=UDim2.fromOffset(10,10),SortOrder=Enum.SortOrder.LayoutOrder},list)
local destination,buttons=nil,{}
for index,location in ipairs(Locations.List) do
    if Locations.Position(location) then
        local button=make("TextButton",{Name=location.Id,LayoutOrder=index,Text="",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,AutoButtonColor=false},list)
        round(button);buttons[location.Id]=button
        make("UIStroke",{Name="Selection",Color=yellow,Thickness=1,Transparency=.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},button):SetAttribute("SemanticColor",yellow)
        button:SetAttribute("ThemeSelected",false)
        picture(button,"LocationIcon",locationIcons[location.Id] or "Landmark",UDim2.new(.5,-18,0,9),UDim2.fromOffset(36,36))
        make("TextLabel",{Name="Label",Position=UDim2.new(0,8,0,48),Size=UDim2.new(1,-16,0,32),Text=location.Name,
            Font=Enum.Font.GothamBold,TextSize=16,TextColor3=ink,TextWrapped=true,BackgroundTransparency=1},button)
        local check=picture(button,"Checked","CircleCheck",UDim2.new(1,-24,0,6),UDim2.fromOffset(18,18));check.Visible=false
        button.Activated:Connect(function()
            destination=location.Id
            for id,item in pairs(buttons) do selectTile(item,id==destination) end
        end)
    end
end
picture(panel,"FareIcon","Coins",UDim2.new(0,20,1,-124),UDim2.fromOffset(22,22))
local fare=make("TextLabel",{Name="Fare",Position=UDim2.new(0,50,1,-124),Size=UDim2.new(.5,-50,0,24),Text="Fare: 10 coins",
    Font=Enum.Font.GothamBold,TextSize=17,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},panel)
local wallet=make("TextLabel",{Name="Wallet",Position=UDim2.new(.5,0,1,-124),Size=UDim2.new(.5,-20,0,24),Text="",
    Font=Enum.Font.GothamBold,TextSize=17,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right},panel)
local feedback=make("TextLabel",{Name="Feedback",Position=UDim2.new(0,20,1,-95),Size=UDim2.new(1,-40,0,30),Text="",
    TextWrapped=true,Font=Enum.Font.GothamMedium,TextSize=15,TextColor3=ink,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left},panel)
local confirm=make("TextButton",{Name="Confirm",Position=UDim2.new(0,20,1,-57),Size=UDim2.new(1,-40,0,42),Text="Call My Ride",
    Font=Enum.Font.GothamBlack,TextSize=19,TextColor3=Color3.new(1,1,1),BackgroundColor3=green,BorderSizePixel=0},panel)
round(confirm)
local status=make("Frame",{Name="PickupStatus",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,-18),
    Size=UDim2.new(1,-180,0,102),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Visible=false},gui)
make("UISizeConstraint",{MaxSize=Vector2.new(480,102)},status);round(status)
make("UIStroke",{Color=green,Thickness=2},status)
local note=make("TextLabel",{Position=UDim2.fromOffset(12,8),Size=UDim2.new(1,-24,0,48),Text="",TextWrapped=true,
    Font=Enum.Font.GothamBold,TextSize=16,TextColor3=ink,BackgroundTransparency=1},status)
local cancel=make("TextButton",{Name="CancelPickup",Position=UDim2.new(0,12,1,-38),Size=UDim2.new(.5,-18,0,30),Text="Cancel Pickup",
    Font=Enum.Font.GothamBold,TextSize=15,TextColor3=ink,BackgroundColor3=Color3.fromRGB(237,243,244),BorderSizePixel=0},status)
round(cancel)
local board=make("TextButton",{Name="Board",Position=UDim2.new(.5,6,1,-38),Size=UDim2.new(.5,-18,0,30),Text="Get On - 10 Coins",
    Font=Enum.Font.GothamBold,TextSize=15,TextColor3=Color3.new(1,1,1),BackgroundColor3=green,BorderSizePixel=0},status)
round(board)
local busy,toastUntil=false,0
player:GetAttributeChangedSignal("TaxiMessage"):Connect(function()
    if not player:GetAttribute("TaxiState") then toastUntil=os.clock()+4 end
end)
local function shut()
    panel.Visible=false;pg:SetAttribute("TaxiUIOpen",false)
end
local function invoke(action,payload)
    if busy then return end
    busy=true
    task.spawn(function()
        local ok,result=pcall(function() return request:InvokeServer(action,payload or {}) end)
        busy=false
        feedback.Text=ok and result and result.Message or "The driver could not answer. Please try again."
        if ok and result and result.Ok and action=="Call" then
            local location=Locations.ById[destination]
            local position=Locations.Position(location)
            if position then
                pg:SetAttribute("MapPingPosition",Vector3.new(position.X,-140,position.Z));pg:SetAttribute("MapPingTitle",location.Name)
                pg:SetAttribute("QuestPingKind","location");pg:SetAttribute("QuestPingId",location.Id)
                pg:SetAttribute("SideQuestFocus",false)
            end
            shut()
        end
    end)
end
call.Activated:Connect(function()
    if panel.Visible then shut();return end
    kind=nil;destination=nil
    for _,item in pairs(kindButtons) do selectTile(item,false) end
    for _,item in pairs(buttons) do selectTile(item,false) end
    pg:SetAttribute("TaxiUIOpen",true);panel.Visible=true;feedback.Text="Choose an e-bike or a tricycle, then a place to visit."
end)
close.Activated:Connect(shut)
confirm.Activated:Connect(function()
    if not kind then feedback.Text="Choose an e-bike or a tricycle.";return end
    if not destination then feedback.Text="Choose a place to visit.";return end
    if not player:GetAttribute("WalletReady") then feedback.Text="Your coins are still loading.";return end
    if (player:GetAttribute("Coins") or 0)<FARE then feedback.Text="You need 10 coins. Help with quests to earn more.";return end
    invoke("Call",{Kind=kind,Destination=destination})
end)
cancel.Activated:Connect(function() invoke("Cancel") end)
board.Activated:Connect(function() invoke("Board") end)
UIS.InputBegan:Connect(function(input,used) if not used and input.KeyCode==Enum.KeyCode.Escape and panel.Visible then shut() end end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0
    local taxiState=player:GetAttribute("TaxiState")
    local riding=player:GetAttribute("BrighthavenRiding") or player:GetAttribute("SchoolShuttleRiding")
    local quests=pg:FindFirstChild("BrightHavenQuests")
    local school=pg:FindFirstChild("BrighthavenLocation12")
    local side=pg:FindFirstChild("BrightHavenSideDialogue")
    local modal=pg:GetAttribute("BagOpen") or pg:GetAttribute("WorldMapOpen") or pg:GetAttribute("SchoolShuttleUIOpen")
        or (quests and quests.QuestBook.Visible)
        or (school and (school.CaptainDialogue.Visible or school.SchoolSolution.Visible or school.MissionPanel.Visible))
        or (side and side.Dialogue.Visible)
    local usable=Practice.CanUseWorld(player)
    if not usable or modal or riding then shut() end
    call.Visible=usable and not modal and not riding and not taxiState and not panel.Visible
    confirm.Text=busy and "Calling..." or not kind and "Choose Your Ride" or not destination and "Choose a Destination" or "Call My "..kind
    confirm.Active=kind~=nil and destination~=nil and not busy and player:GetAttribute("WalletReady")==true and (player:GetAttribute("Coins") or 0)>=FARE
    confirm.AutoButtonColor=confirm.Active
    confirm.BackgroundColor3=confirm.Active and yellow or Color3.new(1,1,1)
    fare.Text="Fare: "..FARE.." coins"
    wallet.Text="Your coins: "..tostring(player:GetAttribute("Coins") or "...")
    status.Visible=usable and not modal and not panel.Visible and (taxiState=="Coming" or taxiState=="Waiting" or (not taxiState and os.clock()<toastUntil))
    note.Text=player:GetAttribute("TaxiMessage") or ""
    board.Visible=taxiState=="Waiting";board.Active=not busy and (player:GetAttribute("Coins") or 0)>=FARE
    board.BackgroundColor3=board.Active and green or Color3.fromRGB(123,141,146)
    cancel.Visible=taxiState=="Coming" or taxiState=="Waiting";cancel.Active=not busy
    status.Size=UDim2.new(1,-180,0,taxiState and 102 or 64)
    local size=bounds.AbsoluteSize
    panel.Size=UDim2.fromOffset(math.min(620,size.X-32),math.min(566,size.Y-28))
    local columns=panel.Size.X.Offset>=520 and 3 or 2
    grid.CellSize=UDim2.new(1/columns,-(10*(columns-1)+13)/columns,0,86)
    for _,item in pairs(kindButtons) do item.Label.TextSize=panel.Size.X.Offset<390 and 14 or 18 end
    title.TextSize=panel.Size.X.Offset<390 and 18 or 23
    fare.TextSize=panel.Size.X.Offset<390 and 14 or 17
    wallet.TextSize=fare.TextSize
end)
player.CharacterRemoving:Connect(shut)
