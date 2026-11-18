-- Street residents follow walkable routes to assigned houses, then resume their patrol.
local RS=game.ReplicatedStorage
local PFS=game:GetService('PathfindingService')
local Physics=game:GetService('PhysicsService')
local Service={Actors={}}
local homes=workspace.BarangayCommunityBlocks
local homeOccupancy={}
pcall(function() Physics:RegisterCollisionGroup('BrightHavenResidents') end)
for _,g in Physics:GetRegisteredCollisionGroups() do Physics:CollisionGroupSetCollidable('BrightHavenResidents',g.name,false) end
local function wet()
 local minute=RS:GetAttribute('TownMinutes') or 420
 return RS:GetAttribute('BrightHavenRaining')==true or (RS:GetAttribute('WeatherIntensity') or 0)>.04 or minute>=1260 or minute<420
end
local function grounded(a,point)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={a.Model};params.RespectCanCollide=true
 local hit=workspace:Raycast(Vector3.new(point.X,-136,point.Z),Vector3.new(0,-15,0),params)
 return Vector3.new(point.X,(hit and hit.Position.Y or -143.47)+a.Foot,point.Z)
end
local function animate(a,dt,running)
 a.Time+=dt
 for joint,cf in pairs(a.Motors) do
  if joint.Parent then
   if running and (joint.Name:find('Hip') or joint.Name:find('Shoulder')) then
    joint.C0=cf*CFrame.Angles(math.sin(a.Time*12)*.65*(joint.Name:find('Left') and 1 or -1),0,0)
   else joint.C0=cf end
  end
 end
end
local function walk(a,point,speed)
 local last=os.clock();local limit=last+math.max(10,(a.Model:GetPivot().Position-point).Magnitude/speed*3)
 while a.Model.Parent do
  local now=os.clock();local dt=math.min(.12,now-last);last=now
  local current=a.Model.HumanoidRootPart.Position;local target=grounded(a,point)
  local delta=Vector3.new(target.X-current.X,0,target.Z-current.Z)
  if delta.Magnitude<.2 then animate(a,0,false);return true end
  if now>limit then return false end
  local step=math.min(delta.Magnitude,speed*dt)
  local p=grounded(a,current+delta.Unit*step)
  a.Model:PivotTo(CFrame.lookAt(p,p+delta.Unit));animate(a,dt,true)
  task.wait(.06)
 end
 return false
end
function Service.CanPatrol(model,point)
 local params=OverlapParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={model};params.RespectCanCollide=true
 for _,part in workspace:GetPartBoundsInBox(CFrame.new(point+Vector3.new(0,.25,0)),Vector3.new(2.5,4.8,2.5),params) do if part.CanCollide then return false end end
 return true
end
local function pathTo(a,target)
 local path=PFS:CreatePath({AgentRadius=1.4,AgentHeight=5,AgentCanJump=false,AgentCanClimb=false,WaypointSpacing=7,Costs={Water=math.huge}})
 local ok=pcall(function() path:ComputeAsync(a.Model.HumanoidRootPart.Position,target) end)
 if not ok or path.Status~=Enum.PathStatus.Success then
  -- Step back from a counter edge before requesting a new walkable route.
  for _,offset in ipairs({Vector3.new(0,0,2.5),Vector3.new(0,0,-2.5),Vector3.new(2.5,0,0),Vector3.new(-2.5,0,0),Vector3.new(0,0,5),Vector3.new(5,0,0)}) do
   local start=grounded(a,a.Model.HumanoidRootPart.Position+offset)
   if Service.CanPatrol(a.Model,start) then
    local retry=pcall(function() path:ComputeAsync(start,target) end)
    if retry and path.Status==Enum.PathStatus.Success and walk(a,start,8) then
     if a.Model:GetAttribute('ShelterState')=='RunningHome' then a.Return=a.Return+(start-a.Return.Position) end
     ok=true;break
    end
   end
  end
  if not ok or path.Status~=Enum.PathStatus.Success then a.Model:SetAttribute('RainRouteStatus','Retrying path');return false end
 end
 a.Model:SetAttribute('RainRouteStatus','Following walkable route')
 for _,p in path:GetWaypoints() do if not walk(a,p.Position,14) then return false end end
 return true
end
local function door(a,hold)
 local d=a.House.FrontDoor
 local count=math.max(0,(d:GetAttribute('ShelterDoorUsers') or 0)+(hold and 1 or -1));d:SetAttribute('ShelterDoorUsers',count)
 while d:GetAttribute('RainDoorTween') or d:GetAttribute('DoorTweenActive') do task.wait(.03) end
 local opening=(d:GetAttribute('ShelterDoorUsers') or 0)>0
 if opening==d:GetAttribute('Open') then return end
 d:SetAttribute('RainDoorTween',true)
 local closed,hinge=d:GetAttribute('ClosedPivot'),d:GetAttribute('HingeFrame')
 local target=opening and hinge*CFrame.Angles(0,math.rad(100),0)*hinge:Inverse()*closed or closed
 local from=d:GetPivot()
 for i=1,10 do d:PivotTo(from:Lerp(target,i/10));task.wait(.025) end
 d:SetAttribute('Open',opening);d:SetAttribute('RainDoorTween',nil)
end
local function travel(a,home)
 a.Busy=true;a.Model:SetAttribute('RainShelterManaged',true)
 a.Model:SetAttribute('ShelterState',home and 'RunningHome' or 'ReturningOutside')
 local base=a.House.Floor.CFrame
 local porch=base:PointToWorldSpace(Vector3.new(0,.125+a.Foot,-18))
 local inside=base:PointToWorldSpace(Vector3.new(a.Slot,.125+a.Foot,a.Depth))
 local ok
 if home then
  a.Return=a.Model:GetPivot()
  ok=pathTo(a,porch)
  if ok then door(a,true);ok=walk(a,inside,9);door(a,false) end
 else
  door(a,true);ok=walk(a,porch,9);door(a,false)
  if ok then ok=pathTo(a,a.Return.Position) end
 end
 a.Busy=false
 if ok then
  a.Inside=home;a.Model:SetAttribute('ShelterState',home and 'ShelteredAtHome' or 'Outdoors')
  a.Model:SetAttribute('RainRouteStatus',home and 'Arrived home' or 'Patrol resumed')
  if not home then a.Model:SetAttribute('ResumePatrol',true);a.Model:SetAttribute('RainShelterManaged',false) end
 else
  a.Retry=os.clock()+4
  a.Model:SetAttribute('ShelterState','WaitingForSafeRoute')
 end
end
function Service.Register(model)
 if not model:FindFirstChild('HumanoidRootPart') or model:GetAttribute('RainShelterRegistered') then return end
 model:SetAttribute('RainShelterRegistered',true)
 -- Read the rest-pose joint chain: cloned limb transforms may not have settled yet.
 local torso=model:FindFirstChild('Torso');local rootJoint=model.HumanoidRootPart:FindFirstChild('RootJoint');local hip=torso and torso:FindFirstChild('Right Hip');local leg=model:FindFirstChild('Right Leg')
 local foot=2.88
 if rootJoint and hip and leg then local rest=rootJoint.C0*rootJoint.C1:Inverse()*hip.C0*hip.C1:Inverse();foot=-rest.Y+leg.Size.Y/2 end
 local house,best
 for i=1,12 do local h=homes['Bahay_'..i];local pos=(h.Floor.CFrame*CFrame.new(0,0,-18)).Position;local dist=(pos-model.HumanoidRootPart.Position).Magnitude
  if not best or dist<best then best=dist;house=h end
 end
 local motors={};for _,d in model:GetDescendants() do
  if d:IsA('Motor6D') then motors[d]=d.C0 elseif d:IsA('BasePart') then d.CollisionGroup='BrightHavenResidents';d.CanCollide=false end
 end
 local number=homeOccupancy[house] or 0;homeOccupancy[house]=number+1
 local a={Model=model,House=house,Foot=foot,Motors=motors,Time=0,Slot=(number%3-1)*3,Depth=-7+math.floor(number/3)*3,Inside=false,Busy=false,Retry=0}
 model:SetAttribute('AssignedHouse',house.Name);model:SetAttribute('ShelterState','Outdoors')
 table.insert(Service.Actors,a)
end
task.spawn(function()
 while true do
  task.wait(.3);local rain=wet()
  for _,a in Service.Actors do
   if a.Model.Parent and not a.Busy and os.clock()>a.Retry and rain~=a.Inside then
    task.spawn(travel,a,rain);task.wait(.08)
   end
  end
 end
end)
return Service
