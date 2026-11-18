local Run=game:GetService('RunService')
local t=workspace['Possible Map Replacement'].Tutorial.Tutorial_2
local logs=t.Logs
local states={}
local started=workspace:GetServerTimeNow()
for row=1,3 do for _,p in ipairs(logs['Log_column'..row]:GetChildren()) do if p:IsA('BasePart') then
 local state={Part=p,Base=p:GetAttribute('RotationBase') or p.CFrame,Amplitude=math.rad(p:GetAttribute('RotationAmplitude') or 10),Period=p:GetAttribute('RotationPeriod') or 14,Phase=(row-1)*.6,CanCollide=p.CanCollide}
 states[p]=state
 p.LogLabel.Enabled=false

end end end
logs:GetAttributeChangedSignal('ResetCount'):Connect(function()
 for p,s in pairs(states) do s.SinkStart=nil;p.CanCollide=s.CanCollide;p:SetAttribute('Sinking',false);p.TopNumber.Enabled=true;p.LogLabel.Enabled=false end
end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.04 then return end;elapsed=0
 local now=workspace:GetServerTimeNow()
 for p,s in pairs(states) do
  if p:GetAttribute("Sinking") and not s.SinkStart then
   s.SinkStart=now;p.CanCollide=false;p.TopNumber.Enabled=false
  end
  local angle=math.sin((now-started)*2*math.pi/s.Period+s.Phase)*s.Amplitude
  local sink=s.SinkStart and math.clamp((now-s.SinkStart)/.25,0,1)*8 or 0
  p.CFrame=s.Base*CFrame.new(0,-sink,0)*CFrame.Angles(0,angle,0)
 end
end)
