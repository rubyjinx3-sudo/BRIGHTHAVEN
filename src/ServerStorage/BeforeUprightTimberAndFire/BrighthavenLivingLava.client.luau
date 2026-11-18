local Players=game:GetService('Players')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local arena=workspace:WaitForChild('Possible Map Replacement'):WaitForChild('Tutorial'):WaitForChild('Tutorial_2'):WaitForChild('LundagLavaCrater')
local effects=arena:WaitForChild('LivingLavaEffects')
local lava=arena:WaitForChild('Lava')
local flows,bubbles,ripples,smoke={},{},{},{}
for _,p in ipairs(effects:GetChildren()) do
 if p:IsA('BasePart') then
  if p:GetAttribute('FlowOrigin') then table.insert(flows,{Part=p,Origin=p:GetAttribute('FlowOrigin'),Size=p:GetAttribute('FlowSize'),Phase=p:GetAttribute('FlowPhase')})
  elseif p:GetAttribute('BubbleOrigin') then table.insert(bubbles,{Part=p,Origin=p:GetAttribute('BubbleOrigin'),Phase=p:GetAttribute('BubblePhase'),Period=p:GetAttribute('BubblePeriod')})
  elseif p:GetAttribute('RippleOrigin') then table.insert(ripples,{Part=p,Origin=p:GetAttribute('RippleOrigin'),Phase=p:GetAttribute('BubblePhase'),Period=p:GetAttribute('BubblePeriod'),Stroke=p:FindFirstChild('RippleStroke',true)}) end
 end
end
for _,p in ipairs(effects:GetDescendants()) do if p:IsA('ParticleEmitter') then p.Enabled=false;table.insert(smoke,p) end end
local elapsed,wasNear=0,nil
local connection
connection=Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.05 then return end;elapsed=0
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local near=root and (root.Position-lava.Position).Magnitude<260 or false
 if near~=wasNear then
  wasNear=near
  for _,emitter in ipairs(smoke) do emitter.Enabled=near end
  arena:SetAttribute('LavaAnimationActive',near)
  if not near then
   for _,b in ipairs(bubbles) do b.Part.Transparency=1 end
   for _,r in ipairs(ripples) do r.Stroke.Transparency=1 end
  end
 end
 if not near then return end
 local now=workspace:GetServerTimeNow()
 for _,f in ipairs(flows) do
  local phase=now*.42+f.Phase
  f.Part.CFrame=f.Origin*CFrame.new(math.sin(phase)*1.15,math.sin(phase*1.3)*.055,math.cos(phase*.7)*1.8)*CFrame.Angles(0,math.sin(phase*.4)*.12,0)
  local pulse=.5+.5*math.sin(phase)
  f.Part.Size=Vector3.new(f.Size.X*(.85+.25*pulse),f.Size.Y,f.Size.Z*(.9+.15*(1-pulse)))
  f.Part.Color=Color3.fromRGB(139,44,23):Lerp(Color3.fromRGB(193,78,31),pulse)
 end
 for _,b in ipairs(bubbles) do
  local cycle=(now/b.Period+b.Phase)%1
  local swell=math.sin(math.pi*math.clamp(cycle/.72,0,1))
  if cycle<.72 then
   b.Part.Transparency=.18+.15*(1-swell)
   b.Part.Size=Vector3.new(.6+swell*1.6,.16+swell*.65,.6+swell*1.6)
   b.Part.CFrame=CFrame.new(b.Origin+Vector3.new(0,-.3+swell*.25,0))
   b.Part.Color=Color3.fromRGB(147,44,21):Lerp(Color3.fromRGB(211,91,32),swell)
  else b.Part.Transparency=1 end
 end
 for _,r in ipairs(ripples) do
  local cycle=(now/r.Period+r.Phase)%1
  local burst=math.clamp((cycle-.62)/.38,0,1)
  r.Part.Size=Vector3.new(1.2+burst*4.2,.035,1.2+burst*4.2)
  r.Stroke.Transparency=cycle<.62 and 1 or .35+burst*.65
 end
 arena:SetAttribute('LavaAnimationTime',now)
end)
script.Destroying:Connect(function()
 if connection then connection:Disconnect() end
 for _,emitter in ipairs(smoke) do if emitter.Parent then emitter.Enabled=false end end
end)
