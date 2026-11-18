local RS=game.ReplicatedStorage
local Shelter=require(game.ServerScriptService.BrighthavenRainShelter)
local source=workspace.BrighthavenCommunity.Residents:GetChildren()[1]
local style=require(RS.Brighthaven.ResidentStyle)
local group=Instance.new('Folder');group.Name='BrightHavenWalkingResidents';group.Parent=workspace
local paths={}
for _,p in ipairs(workspace.BrighthavenSidewalks:GetChildren()) do
 if p:IsA('BasePart') and math.max(p.Size.X,p.Size.Z)>=65 and math.min(p.Size.X,p.Size.Z)>=4 then table.insert(paths,p) end
end
table.sort(paths,function(a,b) return a.Name<b.Name end)
local walkers={}
for i=1,22 do
 local model=source:Clone();model.Name='WalkingNeighbor_'..i
 for _,x in ipairs(model:GetDescendants()) do
  if x:IsA('BaseScript') or x:IsA('ProximityPrompt') or x:IsA('BillboardGui') then x:Destroy()
  elseif x:IsA('BasePart') then x.Anchored=x.Name=='HumanoidRootPart';x.CanCollide=false;x.CanTouch=false;x.CanQuery=false end
 end
 local h=model:FindFirstChildOfClass('Humanoid');h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.EvaluateStateMachine=false
 model:SetAttribute('WalkingResident',true);model:SetAttribute('Gender',i%2==0 and 'Female' or 'Male');model:SetAttribute('AgeGroup',i%6==0 and 'Elder' or 'Adult')
 style.Apply(model,40+i,false)
 local motors={};for _,m in ipairs(model:GetDescendants()) do if m:IsA('Motor6D') then motors[m]=m.C0 end end
 local path=paths[(i-1)%#paths+1];local axis=path.Size.X>path.Size.Z and Vector3.xAxis or Vector3.zAxis
 local half=math.max(path.Size.X,path.Size.Z)/2-5
 local start=path.Position-axis*half;local finish=path.Position+axis*half
 start=Vector3.new(start.X,-140.55,start.Z);finish=Vector3.new(finish.X,-140.55,finish.Z)
 model:PivotTo(CFrame.new(start:Lerp(finish,i/22)));model.Parent=group
 Shelter.Register(model)
 walkers[i]={Model=model,Start=start,Finish=finish,Length=(finish-start).Magnitude,T=i/22,Direction=i%2==0 and 1 or -1,Speed=3.6+i%4*.4,Motors=motors}
 task.wait()
end
-- Customers are real neighbors who walk to the queue and wait beside the tills.
local stations=workspace.BrightHavenSupermarket.SupermarketStations
for i=1,3 do
 local customer=source:Clone();customer.Name='Customer_'..i
 for _,x in ipairs(customer:GetDescendants()) do if x:IsA('BaseScript') or x:IsA('ProximityPrompt') or x:IsA('BillboardGui') then x:Destroy() elseif x:IsA('BasePart') then x.Anchored=true;x.CanCollide=false;x.CanTouch=false end end
 style.Apply(customer,70+i,true)
 local bounds,extent=customer:GetBoundingBox();local foot=customer.HumanoidRootPart.Position.Y-(bounds.Position.Y-extent.Y/2)
 local pos=stations['Customer'..i].Position+Vector3.new(0,foot-.01,0)
 customer:PivotTo(CFrame.lookAt(pos,Vector3.new(stations.Checkout.Position.X,pos.Y,stations.Checkout.Position.Z)));customer.Parent=group
end
for _,model in ipairs(workspace.BrighthavenCommunity.Residents:GetChildren()) do Shelter.Register(model) end
local elapsed=0
while true do
 local dt=task.wait(.08);elapsed+=dt
 local minute=RS:GetAttribute('TownMinutes') or 420;local asleep=minute>=1260 or minute<420
 for _,w in ipairs(walkers) do
  if not w.Model:GetAttribute('RainShelterManaged') then
   if w.Model:GetAttribute('ResumePatrol') then w.T=math.clamp((w.Model.HumanoidRootPart.Position-w.Start):Dot((w.Finish-w.Start).Unit)/w.Length,0,1);w.Model:SetAttribute('ResumePatrol',nil) end
   w.T+=dt*w.Speed/w.Length*w.Direction
   if w.T>=1 then w.T=1;w.Direction=-1 elseif w.T<=0 then w.T=0;w.Direction=1 end
   local p=w.Start:Lerp(w.Finish,w.T)
   if not Shelter.CanPatrol(w.Model,p) then w.T=math.clamp(w.T-dt*w.Speed/w.Length*w.Direction,0,1);w.Direction=-w.Direction;p=w.Start:Lerp(w.Finish,w.T) end
   local direction=(w.Finish-w.Start).Unit*w.Direction
   w.Model:PivotTo(CFrame.lookAt(p,p+direction))
   for m,c in pairs(w.Motors) do
    local name=m.Name
    local side=name:find('Left') and 1 or -1
    if name:find('Hip') or name:find('Shoulder') then m.C0=c*CFrame.Angles(math.sin(elapsed*6+w.T*8)*.35*side,0,0) end
   end
  end
 end
end

