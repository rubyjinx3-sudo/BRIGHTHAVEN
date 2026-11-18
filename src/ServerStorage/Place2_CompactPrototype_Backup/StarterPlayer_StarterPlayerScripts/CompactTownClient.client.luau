local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local p=Players.LocalPlayer
local shared=RS:WaitForChild('BrightHavenCompact')
local world=workspace:WaitForChild('BrightHavenCompact')
local teal=Color3.fromRGB(35,91,92)
local cream=Color3.fromRGB(255,249,233)
local gold=Color3.fromRGB(248,200,73)
local gui=Instance.new('ScreenGui');gui.Name='BrightHavenCompactHUD';gui.ResetOnSpawn=false;gui.DisplayOrder=10;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=p.PlayerGui
local function corner(o,r) local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,r or 12);c.Parent=o end
local function label(parent,name,pos,size,text,color,font)
 local l=Instance.new('TextLabel');l.Name=name;l.Position=pos;l.Size=size;l.BackgroundTransparency=1;l.Text=text;l.TextColor3=color or teal;l.Font=font or Enum.Font.GothamBold;l.TextSize=16;l.TextWrapped=true;l.Parent=parent;return l
end
local function frame(name,pos,size,color)
 local f=Instance.new('Frame');f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=color or cream;f.BorderSizePixel=0;f.Parent=gui;corner(f);return f
end
local status=frame('TownStatus',UDim2.new(1,-270,0,12),UDim2.fromOffset(254,108))
label(status,'Title',UDim2.fromOffset(12,9),UDim2.fromOffset(230,22),'BRIGHTHAVEN',teal,Enum.Font.GothamBlack)
local clock=label(status,'Clock',UDim2.fromOffset(12,34),UDim2.fromOffset(110,22),'07:30')
local money=label(status,'Coins',UDim2.fromOffset(124,34),UDim2.fromOffset(118,22),'20 coins')
local function meter(y,title,color)
 label(status,title,UDim2.fromOffset(12,y),UDim2.fromOffset(50,18),title).TextSize=12
 local back=Instance.new('Frame');back.Position=UDim2.fromOffset(67,y+3);back.Size=UDim2.fromOffset(172,12);back.BackgroundColor3=Color3.fromRGB(224,226,214);back.BorderSizePixel=0;back.Parent=status;corner(back,6)
 local fill=back:Clone();fill.Name='Fill';fill.Position=UDim2.fromScale(0,0);fill.Size=UDim2.fromScale(.7,1);fill.BackgroundColor3=color;fill.Parent=back;return fill
end
local food=meter(61,'Food',gold);local water=meter(82,'Water',Color3.fromRGB(91,174,194))
local goal=frame('CommunityGoal',UDim2.new(.5,-265,1,-90),UDim2.fromOffset(530,66))
local goalTitle=label(goal,'Heading',UDim2.fromOffset(14,7),UDim2.fromOffset(502,23),'LINIS BARANGAY · 0 / 6')
local goalText=label(goal,'Directions',UDim2.fromOffset(14,33),UDim2.fromOffset(502,23),'Collect litter around the plaza. Walk close and press E.');goalText.TextSize=13;goalText.Font=Enum.Font.Gotham
local dialog=frame('NeighborMessage',UDim2.new(.5,-285,1,-202),UDim2.fromOffset(570,100));dialog.Visible=false
local speaker=label(dialog,'Speaker',UDim2.fromOffset(18,8),UDim2.fromOffset(500,24),'Mabuhay!')
local words=label(dialog,'Words',UDim2.fromOffset(18,36),UDim2.fromOffset(534,54),'');words.TextSize=15;words.Font=Enum.Font.Gotham
local close=Instance.new('TextButton');close.Size=UDim2.fromOffset(28,28);close.Position=UDim2.new(1,-34,0,5);close.Text='×';close.TextSize=24;close.TextColor3=teal;close.BackgroundTransparency=1;close.Parent=dialog;close.Activated:Connect(function() dialog.Visible=false end)
local messageId=0
local function say(title,text)
 messageId+=1;local id=messageId;speaker.Text=title;words.Text=text;dialog.Visible=true
 task.delay(9,function() if id==messageId then dialog.Visible=false end end)
end
shared.Notice.OnClientEvent:Connect(say)
local map=frame('TownGuide',UDim2.new(0,16,0,66),UDim2.fromOffset(285,330));map.Visible=false
label(map,'GuideTitle',UDim2.fromOffset(12,8),UDim2.fromOffset(261,25),'YOUR LITTLE BRIGHTHAVEN')
label(map,'GuideList',UDim2.fromOffset(17,41),UDim2.fromOffset(251,250),'NORTH\nRailway · recycling · wood yard\n\nWEST          PLAZA          EAST\nClinic          Hall          School\nSari-sari       Fountain       Home\n\nSOUTH\nJeepney bay · homes · canal\n\nE / tap: interact   •   M: town guide',teal,Enum.Font.Gotham).TextSize=14
local mapButton=Instance.new('TextButton');mapButton.Name='TownGuideButton';mapButton.Position=UDim2.fromOffset(16,12);mapButton.Size=UDim2.fromOffset(155,42);mapButton.Text='Town guide  [M]';mapButton.Font=Enum.Font.GothamBold;mapButton.TextSize=14;mapButton.TextColor3=teal;mapButton.BackgroundColor3=gold;mapButton.BorderSizePixel=0;mapButton.Parent=gui;corner(mapButton)
mapButton.Activated:Connect(function() map.Visible=not map.Visible end)
UIS.InputBegan:Connect(function(i,processed) if not processed and i.KeyCode==Enum.KeyCode.M then map.Visible=not map.Visible end end)
local function update()
 money.Text=tostring(p:GetAttribute('BHCoins') or 20)..' coins'
 food.Size=UDim2.fromScale(math.clamp((p:GetAttribute('BHFood') or 78)/100,0,1),1)
 water.Size=UDim2.fromScale(math.clamp((p:GetAttribute('BHWater') or 72)/100,0,1),1)
 local n=p:GetAttribute('BHLitter') or 0;local t=p:GetAttribute('BHTables') or 0
 if n<6 then goalTitle.Text='LINIS BARANGAY · '..n..' / 6';goalText.Text='Collect litter around the plaza. Walk close and press E.'
 elseif t<3 then goalTitle.Text='BAHAGI SA PAARALAN · '..t..' / 3';goalText.Text=p:GetAttribute('BHCarrying') and 'Carry your set to an unsupplied learning table inside the school.' or 'Pick up a supply set from the yellow box at the school.'
 else goalTitle.Text='SALAMAT, BAYANI!';goalText.Text='Our town is cleaner and our school is supplied. Enjoy BrightHaven.' end
 for i=1,6 do
  local item=world.CleanupTrail:FindFirstChild('Litter'..i)
  if item then local done=p:GetAttribute('BHClean'..i)==true;item.LocalTransparencyModifier=done and 1 or 0;local prompt=item:FindFirstChildOfClass('ProximityPrompt');if prompt then prompt.Enabled=not done end end
 end
 for i=1,3 do
  local done=p:GetAttribute('BHTable'..i)==true;local tablePart=world.BrightHavenSchool:FindFirstChild('Delivery'..i)
  if tablePart then tablePart.Color=done and Color3.fromRGB(87,163,97) or gold;tablePart:FindFirstChildOfClass('ProximityPrompt').Enabled=not done end
  for _,d in ipairs(world.BrightHavenSchool:GetChildren()) do
   if d:IsA('BasePart') and d.Name:find('Sign_LEARNING TABLE '..i,1,true) then
    local g=d:FindFirstChildOfClass('SurfaceGui');if g then g:FindFirstChildOfClass('TextLabel').Text='LEARNING TABLE '..i..(done and '\nSUPPLIED ✓' or '\n1 SET NEEDED') end
   end
  end
 end
end
local function updateClock()
 local hours=shared:GetAttribute('Clock') or 7.5;clock.Text=string.format('%02d:%02d',math.floor(hours),math.floor(hours%1*60))
end
p.AttributeChanged:Connect(update);shared:GetAttributeChangedSignal('Clock'):Connect(updateClock)
update();updateClock()
local function resize()
 local cam=workspace.CurrentCamera;if not cam then return end
 local width=cam.ViewportSize.X
 local scale=math.min(1,(width-24)/570)
 for _,f in ipairs({dialog,goal}) do
  local u=f:FindFirstChildOfClass('UIScale') or Instance.new('UIScale');u.Scale=scale;u.Parent=f
  f.AnchorPoint=Vector2.new(.5,0);f.Position=UDim2.new(.5,0,1,f==dialog and -202*scale or -90*scale)
 end
end
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(resize) end
resize();task.delay(2,function() say('Mabuhay, neighbor!','Welcome to our little BrightHaven. Meet Ate Maya in the plaza, or start by collecting six pieces of litter. Press M for the town guide.') end)
