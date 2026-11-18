local Players,RS=game.Players,game.ReplicatedStorage
local Physics=game:GetService('PhysicsService')
pcall(function() Physics:RegisterCollisionGroup('BrightHavenResidents') end)
for _,g in ipairs(Physics:GetRegisteredCollisionGroups()) do Physics:CollisionGroupSetCollidable('BrightHavenResidents',g.name,false) end
local walkers={}
for i=1,12 do
 local house=workspace.BarangayCommunityBlocks['Bahay_'..i]
 for _,m in ipairs(house:WaitForChild('HouseholdResidents'):GetChildren()) do
  for _,part in ipairs(m:GetDescendants()) do if part:IsA('BasePart') then part.CollisionGroup='BrightHavenResidents' end end
  local foot=m:GetAttribute('FootOffset');local y=.125+foot
  local host=m:GetAttribute('HouseholdRole')=='Host'
  local route=host and {Vector3.new(-13.2,y,-3.5),Vector3.new(-13.2,y,.6),Vector3.new(-4.8,y,.6)} or {Vector3.new(13.2,y,7.5),Vector3.new(13.2,y,2),Vector3.new(13.2,y,-1)}
  local motors={};for _,motor in ipairs(m:GetDescendants()) do if motor:IsA('Motor6D') then motors[motor]=motor.C0 end end
  table.insert(walkers,{Model=m,Base=house.Floor.CFrame,Route=route,At=route[1],Next=2,Pause=(i%4)*2+3,Host=host,Motors=motors,Seed=i*2+(host and 0 or 1)})
 end
end
local elapsed=0
while true do
 local dt=task.wait(.15);elapsed+=dt
 local minute=RS:GetAttribute('TownMinutes') or 420;local night=minute>=1260 or minute<420
 for _,w in ipairs(walkers) do
  local moving=false
  local look
  if not night then
   if w.Pause>0 then w.Pause-=dt
   else
    local target=w.Route[w.Next];local delta=target-w.At;local step=2.1*dt
    if delta.Magnitude<=step then w.At=target;w.Next=w.Next%#w.Route+1;w.Pause=5+w.Seed%5
    else moving=true;look=w.At+delta;w.At+=delta.Unit*step end
   end
  else w.Pause=math.max(w.Pause,3) end
  if not look then
   look=w.Host and Vector3.new(-7,w.At.Y,-1) or Vector3.new(8,w.At.Y,10.8)
   local world=w.Base:PointToWorldSpace(w.At)
   for _,p in ipairs(Players:GetPlayers()) do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
    if r and (r.Position-world).Magnitude<8 then local v=w.Base:PointToObjectSpace(r.Position);look=Vector3.new(v.X,w.At.Y,v.Z);break end
   end
  end
  if (look-w.At).Magnitude>.1 then w.Model:PivotTo(w.Base*CFrame.lookAt(w.At,look)) end
  for motor,cf in pairs(w.Motors) do
   local side=motor.Name:find('Left') and 1 or -1
   if moving and (motor.Name:find('Hip') or motor.Name:find('Shoulder')) then motor.C0=cf*CFrame.Angles(math.sin(elapsed*5+w.Seed)*.25*side,0,0)
   elseif motor.Name:find('Shoulder') then motor.C0=cf*CFrame.Angles(math.sin(elapsed*1.8+w.Seed)*.05,0,w.Host and .02 or .12*side)
   else motor.C0=cf end
  end
 end
end
