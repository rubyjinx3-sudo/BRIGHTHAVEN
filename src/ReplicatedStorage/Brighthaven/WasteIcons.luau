local Icons={}
local ink=Color3.fromRGB(26,45,65)
function Icons.Draw(parent,kind)
 local old=parent:FindFirstChild('ClearWasteIcon');if old then old:Destroy() end
 local f=Instance.new('Frame');f.Name='ClearWasteIcon';f.Size=UDim2.fromScale(1,1);f.BackgroundColor3=ink;f.BorderSizePixel=0;f.Parent=parent
 local function box(name,x,y,w,h,color,round)
  local p=Instance.new('Frame');p.Name=name;p.Position=UDim2.fromScale(x,y);p.Size=UDim2.fromScale(w,h);p.BackgroundColor3=color;p.BorderSizePixel=0;p.Parent=f
  if round then local c=Instance.new('UICorner');c.CornerRadius=UDim.new(round,0);c.Parent=p end;return p
 end
 if kind=='Paper' then
  box('Newspaper',.23,.12,.54,.76,Color3.fromRGB(251,246,228))
  box('Headline',.3,.23,.4,.07,ink);box('Picture',.3,.37,.18,.19,Color3.fromRGB(78,142,173))
  for i=0,3 do box('PrintedLine',.52,.38+i*.075,.18,.025,ink) end
  for i=0,2 do box('PrintedLine',.3,.66+i*.06,.4,.022,ink) end
 elseif kind=='Plastic' then
  box('BottleCap',.4,.08,.2,.1,Color3.fromRGB(242,213,65),.1)
  box('BottleNeck',.43,.18,.14,.12,Color3.fromRGB(126,217,247),.2)
  box('Bottle',.32,.27,.36,.62,Color3.fromRGB(57,172,225),.18)
  box('BottleHighlight',.37,.33,.045,.43,Color3.fromRGB(172,234,255),.3)
  box('BottleLabel',.32,.48,.36,.2,Color3.new(1,1,1))
  local label=Instance.new('TextLabel');label.Size=UDim2.fromScale(.36,.2);label.Position=UDim2.fromScale(.32,.48);label.Text='PET';label.TextScaled=true;label.Font=Enum.Font.GothamBlack;label.TextColor3=ink;label.BackgroundTransparency=1;label.Parent=f
 elseif kind=='Metal' then
  box('CanBody',.27,.2,.46,.64,Color3.fromRGB(185,203,213),.15)
  box('CanTop',.27,.14,.46,.15,Color3.fromRGB(237,244,247),.45)
  box('CanBottom',.27,.76,.46,.12,Color3.fromRGB(123,149,169),.4)
  box('PullTab',.43,.17,.14,.065,ink,.5)
  for i=1,3 do box('CanRib',.29,.32+i*.1,.42,.035,Color3.fromRGB(105,134,154)) end
 else f:Destroy();return end
 return f
end
return Icons
