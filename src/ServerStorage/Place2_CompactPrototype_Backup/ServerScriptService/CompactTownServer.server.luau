local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local PPS=game:GetService('ProximityPromptService')
local root=workspace:WaitForChild('BrightHavenCompact')
local shared=RS:WaitForChild('BrightHavenCompact')
local notice=shared:WaitForChild('Notice')
local states={}
local function say(p,title,text) notice:FireClient(p,title,text) end
local function coins(p,n)
 p:SetAttribute('BHCoins',math.max(0,(p:GetAttribute('BHCoins') or 0)+n))
 local stats=p:FindFirstChild('leaderstats');if stats then stats.Coins.Value=p:GetAttribute('BHCoins') end
end
local function needs(p,food,water)
 p:SetAttribute('BHFood',math.clamp((p:GetAttribute('BHFood') or 0)+food,0,100))
 p:SetAttribute('BHWater',math.clamp((p:GetAttribute('BHWater') or 0)+water,0,100))
end
local function clearCargo(p)
 for _,container in ipairs({p.Backpack,p.Character}) do if container then local t=container:FindFirstChild('School supplies');if t then t:Destroy() end end end
 p:SetAttribute('BHCarrying',false)
end
local function giveCargo(p)
 local t=Instance.new('Tool');t.Name='School supplies';t.CanBeDropped=false;t.ToolTip='One set for a learning table'
 local h=Instance.new('Part');h.Name='Handle';h.Size=Vector3.new(1.7,1.4,1.3);h.Color=Color3.fromRGB(246,190,65);h.Material=Enum.Material.WoodPlanks;h.CanCollide=false;h.Massless=true;h.Parent=t
 t.Grip=CFrame.new(0,-.2,0);t.Parent=p.Backpack
 local humanoid=p.Character and p.Character:FindFirstChildOfClass('Humanoid');if humanoid then humanoid:EquipTool(t) end
 p:SetAttribute('BHCarrying',true)
end
local function init(p)
 if states[p] then return end
 states[p]={Litter={},Tables={},LastAction=0}
 p:SetAttribute('BHCoins',20);p:SetAttribute('BHFood',78);p:SetAttribute('BHWater',72);p:SetAttribute('BHLitter',0);p:SetAttribute('BHTables',0);p:SetAttribute('BHCarrying',false)
 local stats=Instance.new('Folder');stats.Name='leaderstats';stats.Parent=p
 local c=Instance.new('IntValue');c.Name='Coins';c.Value=20;c.Parent=stats
 p.CharacterAdded:Connect(function(character)
  clearCargo(p)
  local h=character:WaitForChild('Humanoid');h.WalkSpeed=16
 end)
end
Players.PlayerAdded:Connect(init)
Players.PlayerRemoving:Connect(function(p) states[p]=nil end)
for _,p in ipairs(Players:GetPlayers()) do init(p) end
PPS.PromptTriggered:Connect(function(prompt,p)
 if not prompt:IsDescendantOf(root) then return end
 local action=prompt:GetAttribute('CompactAction');local s=states[p];local ch=p.Character;local hrp=ch and ch:FindFirstChild('HumanoidRootPart');local humanoid=ch and ch:FindFirstChildOfClass('Humanoid')
 if not action or not s or not hrp or not humanoid or humanoid.Health<=0 or not prompt.Parent:IsA('BasePart') then return end
 if (hrp.Position-prompt.Parent.Position).Magnitude>prompt.MaxActivationDistance+4 or os.clock()-s.LastAction<.45 then return end
 s.LastAction=os.clock()
 if action=='litter' then
  local id=prompt.Parent:GetAttribute('LitterId');if s.Litter[id] then return end
  s.Litter[id]=true;p:SetAttribute('BHClean'..id,true)
  local count=(p:GetAttribute('BHLitter') or 0)+1;p:SetAttribute('BHLitter',count);coins(p,2)
  if count==6 then say(p,'Salamat, bayani!','The plaza is clean! You earned 12 coins. Visit Teacher Lira at the school to share supplies with three learning tables.')
  else say(p,'Linis Barangay',count..' / 6 pieces collected · +2 coins') end
 elseif action=='supplies' then
  if p:GetAttribute('BHTables')==3 then say(p,'All supplied!','Every learning table has a set. Thank you for helping our school.')
  elseif p:GetAttribute('BHCarrying') then say(p,'Ready to share','Carry this set inside and deliver it to a table that still needs supplies.')
  else giveCargo(p);say(p,'One set picked up','Bring this box to a learning table inside the school. Come back for the next set.') end
 elseif action=='deliver' then
  local id=prompt.Parent:GetAttribute('TableIndex')
  if s.Tables[id] then say(p,'Already supplied','This table already has its set. Look for another table.')
  elseif not p:GetAttribute('BHCarrying') then say(p,'Pick up a set first','The yellow community supply box is outside the school entrance.')
  else
   s.Tables[id]=true;clearCargo(p);p:SetAttribute('BHTable'..id,true)
   local count=(p:GetAttribute('BHTables') or 0)+1;p:SetAttribute('BHTables',count);coins(p,3)
   say(p,count==3 and 'Bayanihan at school!' or 'Set delivered',count==3 and 'Three equal sets, three happy tables! You earned 9 coins. Take a break at home or explore the rest of town.' or count..' / 3 tables supplied · +3 coins. Pick up the next set outside.')
  end
 elseif action=='water' or action=='food' then
  local cost=action=='water' and 1 or 2;local attr=action=='water' and 'BHWater' or 'BHFood'
  if (p:GetAttribute(attr) or 0)>=100 then say(p,'Feeling good!',action=='water' and 'Your water bar is full.' or 'Your food bar is full.')
  elseif (p:GetAttribute('BHCoins') or 0)<cost then say(p,'More coins needed','Help collect litter or deliver school supplies to earn coins.')
  else coins(p,-cost);needs(p,action=='food' and 35 or 0,action=='water' and 40 or 0);say(p,'Salamat po!',action=='water' and 'Cold water restored 40 water · −1 coin.' or 'Fresh pandesal restored 35 food · −2 coins.') end
 elseif action=='clinic' then
  if humanoid.Health>=humanoid.MaxHealth then say(p,'Nurse Ana','You are healthy! Remember to eat, drink water, and rest.')
  else local fee=math.min(5,p:GetAttribute('BHCoins') or 0);coins(p,-fee);humanoid.Health=humanoid.MaxHealth;needs(p,15,15);say(p,'Nurse Ana','You are feeling better. Treatment: '..fee..' coins. We cover any shortfall.') end
 elseif action=='sleep' then
  humanoid.Health=humanoid.MaxHealth;needs(p,25,25)
  if #Players:GetPlayers()==1 then game.Lighting.ClockTime=7;shared:SetAttribute('Clock',7) end
  say(p,'Magandang umaga!','You rested at home. Health restored, food +25, water +25. A new day begins!')
 else
  local npc=prompt:FindFirstAncestorOfClass('Model')
  say(p,prompt.ObjectText,npc and npc:GetAttribute('Greeting') or 'Welcome to our little BrightHaven. Explore the town and lend a helping hand!')
 end
end)
game.Lighting.ClockTime=7.5
shared:SetAttribute('Clock',7.5)
task.spawn(function()
 local tickCount=0
 while true do
  task.wait(2);tickCount+=1
  local before=game.Lighting.ClockTime;local after=(before+24/1080*2)%24;game.Lighting.ClockTime=after;shared:SetAttribute('Clock',after)
  if before<22 and after>=22 then for p in pairs(states) do say(p,'Time to head home','It is 22:00. Your bed is in the coral house east of the plaza. Rest for the next day.') end end
  if tickCount%5==0 then
   for p in pairs(states) do
    needs(p,-.6,-.8)
    local h=p.Character and p.Character:FindFirstChildOfClass('Humanoid')
    if h then h.WalkSpeed=((p:GetAttribute('BHFood') or 0)<=0 or (p:GetAttribute('BHWater') or 0)<=0) and 11 or 16 end
   end
  end
 end
end)
