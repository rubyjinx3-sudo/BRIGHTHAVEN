local Players=game:GetService("Players")
local Rules={Signals={},Vehicles={}}
local root=workspace:WaitForChild("BrighthavenStreetSafety")
local phases={{"XGreen",16},{"XAmber",3},{"AllRed",2},{"ZGreen",16},{"ZAmber",3},{"AllRed",2}}
local pedestrianPhases={{"XGreen",40},{"XAmber",3},{"AllRed",2}}
for _,model in ipairs(root.Signals:GetChildren()) do
    local center=model:GetAttribute("Center")
    local zones={center}
    -- The nearby T-bend and market crossing form one short junction; do not admit opposing turns between them.
    if model.Name=="MarketJunction" then table.insert(zones,Vector3.new(159.472,center.Y,296.04)) end
    table.insert(Rules.Signals,{Model=model,Center=center,Zones=zones,Phases=model:GetAttribute("PedestrianOnly") and pedestrianPhases or phases,
        Offset=model:GetAttribute("PhaseOffset") or 0,Commitments={}})
end
local dark=Color3.fromRGB(46,51,54)
local colors={Red=Color3.fromRGB(255,72,61),Amber=Color3.fromRGB(255,202,46),Green=Color3.fromRGB(69,233,129)}
local widths={Bus=4.9,Jeepney=4.3,Car=4.5,Tricycle=2.6,["E-Bike"]=2.6,Motorcycle=1.3,Bicycle=1.3}
local dimensions={}
function Rules.Dimensions(vehicle)
    if dimensions[vehicle] then return dimensions[vehicle].Length,dimensions[vehicle].Width end
    local length=vehicle:GetAttribute("HalfLength") or (vehicle:GetAttribute("VehicleKind")=="Bus" and 12 or 10)
    local width=vehicle:GetAttribute("HalfWidth") or widths[vehicle:GetAttribute("VehicleKind")] or 4.5
    local parts=vehicle:IsA("BasePart") and {vehicle} or vehicle:GetDescendants()
    local origin=vehicle:GetPivot()
    for _,part in ipairs(parts) do
        if part:IsA("BasePart") and part.Transparency<.95 then
            local f=origin:ToObjectSpace(part.CFrame);local h=part.Size/2
            local x=math.abs(f.RightVector.X)*h.X+math.abs(f.UpVector.X)*h.Y+math.abs(f.LookVector.X)*h.Z
            local z=math.abs(f.RightVector.Z)*h.X+math.abs(f.UpVector.Z)*h.Y+math.abs(f.LookVector.Z)*h.Z
            width=math.max(width,math.abs(f.X)+x);length=math.max(length,math.abs(f.Z)+z)
        end
    end
    dimensions[vehicle]={Length=length,Width=width}
    return length,width
end
local function halfWidth(vehicle) local _,width=Rules.Dimensions(vehicle);return width end
local lanesConfigured=false
function Rules.ConfigureLanes(network)
    if lanesConfigured then return end
    lanesConfigured=true
    local junctions={}
    local arms={}
    for _,node in ipairs(network.Nodes) do
        local directions={}
        for _,edge in ipairs(node.Edges) do
            if #edge.Choices>0 then
                local duplicate=false
                for _,direction in ipairs(directions) do if direction:Dot(edge.Direction)>.98 then duplicate=true;break end end
                if not duplicate then table.insert(directions,edge.Direction) end
            end
        end
        arms[node]=#directions
    end
    for _,incoming in ipairs(network.Edges) do
        if #incoming.Choices>0 and arms[incoming.To]~=2 then
            for _,turn in ipairs(incoming.Choices) do
                if incoming.Direction:Dot(turn.Edge.Direction)<.98 then junctions[incoming.To]=true end
            end
        end
    end
    local points={}
    for node in pairs(junctions) do table.insert(points,node.Position) end
    table.sort(points,function(a,b) return a.X==b.X and a.Z<b.Z or a.X<b.X end)
    for index,point in ipairs(points) do
        local nearest,gap
        for _,s in ipairs(Rules.Signals) do
            if not s.Model:GetAttribute("PedestrianOnly") then
                for _,center in ipairs(s.Zones) do
                    local distance=((point-center)*Vector3.new(1,0,1)).Magnitude
                    if distance<80 and (not gap or distance<gap) then nearest,gap=s,distance end
                end
            end
        end
        if nearest then
            if gap>6.4 then table.insert(nearest.Zones,Vector3.new(point.X,nearest.Center.Y,point.Z)) end
        else
            local model=Instance.new("Folder")
            model.Name="RoadYield_"..index
            local center=Vector3.new(point.X,-142.6,point.Z)
            model:SetAttribute("Center",center);model:SetAttribute("YieldOnly",true)
            model:SetAttribute("JunctionRadius",27.2)
            model:SetAttribute("Exclusive",true);model:SetAttribute("Virtual",true)
            model.Parent=root.Signals
            table.insert(Rules.Signals,{Model=model,Center=center,Zones={center},Phases=phases,Offset=0,Commitments={}})
        end
    end
end
local function axisOf(frame)
    return math.abs(frame.LookVector.X)>=math.abs(frame.LookVector.Z) and "X" or "Z"
end
function Rules.Phase(signal,time)
    local continuous=signal.Model:GetAttribute("ContinuousAxis")
    if continuous then return continuous.."Green",30 end
    local length=0;for _,p in ipairs(signal.Phases) do length+=p[2] end
    local t=((time or workspace:GetServerTimeNow())+signal.Offset)%length
    for _,p in ipairs(signal.Phases) do if t<p[2] then return p[1],p[2]-t end;t-=p[2] end
end
-- An occupied school shuttle requests a green in advance, never skips amber or an occupied crossing.
function Rules.RequestShuttlePriority(vehicle,frame)
    local now=workspace:GetServerTimeNow()
    for _,s in ipairs(Rules.Signals) do
      for _,center in ipairs(s.Zones or {s.Center}) do
        local relative=center-frame.Position
        local along=relative:Dot(frame.LookVector)
        if not s.Model:GetAttribute("YieldOnly") and along>20 and along<220 and math.abs(relative:Dot(frame.RightVector))<22
            and not s.Commitments[vehicle] and not s.Requested
            and not (s.RequestClearUntil and now<s.RequestClearUntil) then
            local axis=axisOf(frame)
            if s.Priority and s.Priority.Vehicle==vehicle and s.Priority.Axis==axis then
                s.Priority.Expires=now+1.5
            elseif not s.Priority then
                local phase,remaining=Rules.Phase(s,now)
                local activeAxis=phase:match("^([XZ])")
                local stage,untilTime="Clear",now+math.min(2,remaining)
                if phase==axis.."Green" then stage,untilTime="Green",now+6
                elseif phase:match("Green$") then stage,untilTime="Amber",now+3
                elseif phase:match("Amber$") then stage,untilTime="Amber",now+remaining end
                s.Priority={Vehicle=vehicle,Axis=axis,PreviousAxis=activeAxis,Stage=stage,Until=untilTime,Expires=now+1.5}
            end
        end
      end
    end
end
local function priorityPhase(s,now,phase,remaining)
    local p=s.Priority
    if not p then return phase,remaining end
    if p.Stage=="Amber" and now>=p.Until then p.Stage="Clear";p.Until=now+2 end
    if p.Stage=="Clear" and now>=p.Until then p.Stage="Green";p.Until=now+6 end
    if p.Stage=="Green" and now>=p.Until and (now>=p.Expires or not p.Vehicle.Parent or s.Requested) then
        p.Stage="ReleaseAmber";p.Until=now+3
    end
    if p.Stage=="ReleaseAmber" and now>=p.Until then p.Stage="ReleaseClear";p.Until=now+2 end
    if p.Stage=="ReleaseClear" and now>=p.Until then
        local start=s.Model:GetAttribute("PedestrianOnly") and 0 or (p.Axis=="X" and 21 or 0)
        local cycle=0;for _,entry in ipairs(s.Phases) do cycle+=entry[2] end
        s.Offset=(start-now)%cycle;s.Priority=nil
        return Rules.Phase(s,now)
    end
    if p.Stage=="Green" then return p.Axis.."Green",math.max(.3,p.Until-now) end
    if p.Stage=="Amber" then return (p.PreviousAxis or p.Axis).."Amber",p.Until-now end
    if p.Stage=="ReleaseAmber" then return p.Axis.."Amber",p.Until-now end
    return "AllRed",p.Until-now
end
function Rules.Update(time)
    time=time or workspace:GetServerTimeNow()
    for vehicle in pairs(Rules.Vehicles) do
        if not vehicle.Parent then Rules.Vehicles[vehicle]=nil;dimensions[vehicle]=nil end
    end
    for _,s in ipairs(Rules.Signals) do
        local phase,remaining=Rules.Phase(s,time)
        if s.RequestClearUntil and time<s.RequestClearUntil then
            s.Priority=nil
            if time<s.RequestWalkAt then phase="AllRed";remaining=s.RequestWalkAt-time
            elseif time<s.RequestUntil then phase="Walk";remaining=s.RequestUntil-time
            else phase="AllRed";remaining=s.RequestClearUntil-time end
        else phase,remaining=priorityPhase(s,time,phase,remaining) end
        s.Model:SetAttribute("SchoolShuttlePriority",s.Priority~=nil)
        if s.Requested and remaining<.3 and phase:match("Amber") then s.RequestWalkAt=time+2;s.RequestUntil=time+12;s.RequestClearUntil=time+14;s.Requested=false;s.Model:SetAttribute("CrossingRequested",false) end
        s.State=phase;s.Model:SetAttribute("TrafficPhase",phase);s.Model:SetAttribute("WalkAllowed",phase=="Walk")
        s.Model:SetAttribute("SecondsToChange",math.ceil(remaining))
        if s.LastPhase~=phase then
            s.LastPhase=phase
            for _,head in ipairs(s.Model:GetChildren()) do
                if head:GetAttribute("Axis") then
                    local axis=head:GetAttribute("Axis")
                    local on=phase==axis.."Green" and "Green" or phase==axis.."Amber" and "Amber" or "Red"
                    for _,name in ipairs({"Red","Amber","Green"}) do
                        head[name].Color=name==on and colors[name] or dark
                        head[name].Material=name==on and Enum.Material.Neon or Enum.Material.Glass
                    end
                elseif head.Name=="PedestrianPanel" then
                    local label=head.SurfaceGui.WalkState;label.Text=phase=="Walk" and "WALK" or "WAIT"
                    label.TextColor3=phase=="Walk" and colors.Green or colors.Red
                end
            end
        end
        for vehicle,commitment in pairs(s.Commitments) do
            local observed=Rules.Vehicles[vehicle]
            local clearance=observed and observed.HalfLength+(s.Model:GetAttribute("JunctionRadius") or (s.Model:GetAttribute("PedestrianOnly") and 14 or 35))+4 or 0
            if not vehicle.Parent or not observed then s.Commitments[vehicle]=nil
            elseif typeof(commitment)=="table" then
                local relative=observed.Frame.Position-(commitment.Center or s.Center)
                local inside=false
                for _,center in ipairs(s.Zones or {s.Center}) do
                    if (observed.Frame.Position-center).Magnitude<=clearance then inside=true;break end
                end
                if inside then commitment.Entered=true
                elseif commitment.Entered or relative:Dot(commitment.Direction)<-commitment.Approach-8 then s.Commitments[vehicle]=nil end
            elseif (observed.Frame.Position-s.Center).Magnitude>clearance then s.Commitments[vehicle]=nil end
        end
    end
end
function Rules.Observe(vehicle,frame,halfLength)
    local previous=Rules.Vehicles[vehicle]
    Rules.Vehicles[vehicle]={Frame=frame,HalfLength=halfLength,HalfWidth=halfWidth(vehicle),
        Moving=previous and (previous.Frame.Position-frame.Position).Magnitude>.002 or false}
end
function Rules.ClearRailSpawn(position,halfLength) return true end
function Rules.ClearSpawn(frame,halfLength)
    local station=workspace:FindFirstChild("BrighthavenSchoolShuttle")
    local parked=station and station:FindFirstChild("Vehicle")
    if parked then local length=Rules.Dimensions(parked);if ((frame.Position-parked:GetPivot().Position)*Vector3.new(1,0,1)).Magnitude<halfLength+length+12 then return false end end
    if not Rules.ClearRailSpawn(frame.Position,halfLength) then return false end
    for _,s in ipairs(Rules.Signals) do
        for _,center in ipairs(s.Zones or {s.Center}) do
            if ((frame.Position-center)*Vector3.new(1,0,1)).Magnitude<halfLength+45 then return false end
        end
    end
    return true
end
local function overlaps(a,al,aw,b,bl,bw,margin)
    local delta=b.Position-a.Position
    if math.abs(delta.Y)>12 or delta.Magnitude>al+bl+aw+bw+2 then return false end
    for _,axis in ipairs({a.RightVector,a.LookVector,b.RightVector,b.LookVector}) do
        local ra=math.abs(axis:Dot(a.LookVector))*al+math.abs(axis:Dot(a.RightVector))*aw
        local rb=math.abs(axis:Dot(b.LookVector))*bl+math.abs(axis:Dot(b.RightVector))*bw
        if math.abs(delta:Dot(axis))>=ra+rb+(margin or 0) then return false end
    end
    return true
end
-- Check actual oriented bodies, including cross traffic and the separate school shuttle.
function Rules.CanMoveTo(vehicle,from,target,halfLength)
    local width=halfWidth(vehicle)
    local angle=math.acos(math.clamp(from.LookVector:Dot(target.LookVector),-1,1))
    local samples=math.clamp(math.ceil(((target.Position-from.Position).Magnitude+angle*halfLength)/2),1,12)
    for other,observed in pairs(Rules.Vehicles) do
        if other~=vehicle and other.Parent then
            for step=1,samples do
                local candidate=from:Lerp(target,step/samples)
                if overlaps(candidate,halfLength,width,observed.Frame,observed.HalfLength,observed.HalfWidth,.6) then
                    -- A vehicle already inside the comfort margin can leave it without touching another body.
                    if overlaps(candidate,halfLength,width,observed.Frame,observed.HalfLength,observed.HalfWidth,0)
                        or not overlaps(from,halfLength,width,observed.Frame,observed.HalfLength,observed.HalfWidth,.6) then return false end
                end
            end
        end
    end
    return true
end
function Rules.SpeedLimit(frame,desired)
    local cap=desired
    if frame.X>-400 and frame.X<-260 and math.abs(frame.Z+35)<55 then cap=math.min(cap,24) end
    for _,s in ipairs(Rules.Signals) do if (frame.Position-s.Center).Magnitude<65 then cap=math.min(cap,30) end end
    return cap
end
function Rules.CurveSamples(frame,atDistance)
    local middle,finish=atDistance(32),atDistance(64)
    if frame.LookVector:Dot(middle.LookVector)>.98 and frame.LookVector:Dot(finish.LookVector)>.98 then return nil end
    local samples={}
    for distance=4,72,4 do table.insert(samples,{Distance=distance,Frame=atDistance(distance)}) end
    return samples
end
-- Follow the lane around a bend, not just the current heading. Leave room for a turning vehicle's rear.
function Rules.FollowCurve(vehicle,frame,travel,halfLength,samples)
    if not samples then return travel end
    local reason
    for other,observed in pairs(Rules.Vehicles) do
        if other~=vehicle and other.Parent and (observed.Frame.Position-frame.Position).Magnitude<100 then
            for _,sample in ipairs(samples) do
                local relative=sample.Frame:PointToObjectSpace(observed.Frame.Position)
                if math.abs(relative.Y)<12 and math.abs(relative.X)<6 and math.abs(relative.Z)<4
                    and sample.Frame.LookVector:Dot(observed.Frame.LookVector)>.7 then
                    local room=math.max(0,sample.Distance-halfLength-observed.HalfLength-14)
                    if room<travel then travel=room;reason="Following Traffic" end
                    break
                end
            end
        end
    end
    return travel,reason
end
local function pedestrianAt(signal,frame)
    for _,p in ipairs(Players:GetPlayers()) do
        local ch=p.Character;local h=ch and ch:FindFirstChildOfClass("Humanoid");local r=ch and ch:FindFirstChild("HumanoidRootPart")
        if r and h and h.Health>0 and not h.SeatPart and math.abs(r.Position.Y+140)<12 then
            local v=r.Position-signal.Center
            local crossing=signal.Model:GetAttribute("PedestrianOnly") and math.abs(v.X)<5 and math.abs(v.Z)<20 or not signal.Model:GetAttribute("PedestrianOnly") and ((math.abs(math.abs(v.X)-27)<5 and math.abs(v.Z)<20) or (math.abs(math.abs(v.Z)-27)<5 and math.abs(v.X)<20))
            if crossing then local ahead=frame:PointToObjectSpace(r.Position);if ahead.Z<0 and math.abs(ahead.X)<20 then return -ahead.Z end end
        end
    end
end
function Rules.Constrain(vehicle,frame,travel,halfLength,probe)
    local reason=""
    local reservations={}
    for _,s in ipairs(Rules.Signals) do
      for _,center in ipairs(s.Zones or {s.Center}) do
        local relative=center-frame.Position
        local along=relative:Dot(frame.LookVector)
        local lateral=math.abs(relative:Dot(frame.RightVector))
        if relative.Magnitude<120 then
            local pedestrian=pedestrianAt(s,frame)
            if pedestrian then local room=math.max(0,pedestrian-halfLength-5);if room<travel then travel=room;reason="Pedestrian" end end
        end
        if lateral<22 and along>0 and along<140 then
            local radius=s.Model:GetAttribute("JunctionRadius") or (s.Model:GetAttribute("PedestrianOnly") and 11.2 or 27.2)
            local stop=along-radius-halfLength-1
            local axis=axisOf(frame)
            local permitted=s.Model:GetAttribute("YieldOnly") or (s.State or Rules.Phase(s))==axis.."Green"
            if stop>=-.5 and not s.Commitments[vehicle] then
                local busy=false
                for other,commitment in pairs(s.Commitments) do
                    if other~=vehicle then
                        local sameApproach=typeof(commitment)=="table" and commitment.Direction:Dot(frame.LookVector)>.98
                            and math.abs((commitment.Position-frame.Position):Dot(frame.RightVector))<5
                            and not s.Model:GetAttribute("Exclusive")
                        if not sameApproach and not s.Model:GetAttribute("PedestrianOnly") then busy=true;break end
                    end
                end
                -- Leave room beyond the crossing instead of joining a stopped queue inside it.
                if permitted and not busy then
                    for other,ahead in pairs(Rules.Vehicles) do
                        if other~=vehicle and other.Parent and not ahead.Moving and frame.LookVector:Dot(ahead.Frame.LookVector)>.95 then
                            local beyond=ahead.Frame.Position-center
                            local forward=beyond:Dot(frame.LookVector)
                            if forward>0 and forward<radius+1+halfLength+ahead.HalfLength+6
                                and math.abs((ahead.Frame.Position-frame.Position):Dot(frame.RightVector))<7 then
                                busy=true;break
                            end
                        end
                    end
                end
                if not permitted or busy then
                    local room=math.max(0,stop)
                    if room<travel then travel=room;reason=permitted and "Junction Queue" or "Red Light" end
                else table.insert(reservations,{Signal=s,Stop=stop,Along=along,Center=center}) end
            end
        end
      end
    end
    -- Queue behind traffic on the same lane, including the separate school shuttle.
    for other,ahead in pairs(Rules.Vehicles) do
        if other~=vehicle and other.Parent and frame.LookVector:Dot(ahead.Frame.LookVector)>.4 then
            local p=frame:PointToObjectSpace(ahead.Frame.Position)
            if math.abs(p.X)<7 and p.Z<0 and p.Z>-90 then
                local room=math.max(0,-p.Z-halfLength-ahead.HalfLength-6)
                if room<travel then travel=room;reason="Following Traffic" end
            end
        end
    end
    local train=workspace:FindFirstChild("Train")
    if false and train and train:IsA("BasePart") and math.abs(frame.LookVector.X)>.7 then
        for _,z in ipairs({-251.56,-29.16,250.04}) do
            local crossing=Vector3.new(109.768,frame.Y,z)
            local relative=crossing-frame.Position
            local along=relative:Dot(frame.LookVector)
            if math.abs(relative:Dot(frame.RightVector))<24 and along>=18+halfLength-.5 and along<140 then
                local clearTime=(36+2*halfLength+6)/math.max(12,math.min(vehicle:GetAttribute("CruiseSpeed") or 30,30))+2
                local trainBuffer=(train:GetAttribute("CruiseSpeed") or 120)*clearTime
                local blocked=train:GetAttribute("TransitActive")~=false and math.abs(train.Position.Z-z)<train.Size.Z/2+trainBuffer
                -- A red light or stopped queue just beyond the rails must not trap a vehicle on the tracks.
                for _,signal in ipairs(Rules.Signals) do
                    for _,center in ipairs(signal.Zones or {signal.Center}) do
                        local beyond=center-crossing
                        local offset=beyond:Dot(frame.LookVector)
                        local radius=signal.Model:GetAttribute("JunctionRadius") or (signal.Model:GetAttribute("PedestrianOnly") and 11.2 or 27.2)
                        if offset>0 and offset-radius-halfLength-1<18+halfLength+3
                            and math.abs(beyond:Dot(frame.RightVector))<22 and not signal.Commitments[vehicle] then
                            local green=signal.Model:GetAttribute("YieldOnly") or (signal.State or Rules.Phase(signal))==axisOf(frame).."Green"
                            local priority=signal.Priority and signal.Priority.Stage=="Green" and workspace:GetServerTimeNow()<signal.Priority.Expires
                            local ending=not signal.Model:GetAttribute("YieldOnly") and not priority
                                and (signal.Model:GetAttribute("SecondsToChange") or 30)<math.ceil(clearTime)
                            if not green or ending then blocked=true end
                            for other,commitment in pairs(signal.Commitments) do
                                if other~=vehicle and (typeof(commitment)~="table" or commitment.Direction:Dot(frame.LookVector)<.98) then blocked=true end
                            end
                        end
                    end
                end
                for other,ahead in pairs(Rules.Vehicles) do
                    if other~=vehicle and other.Parent and not ahead.Moving and frame.LookVector:Dot(ahead.Frame.LookVector)>.7 then
                        local beyond=ahead.Frame.Position-crossing
                        local offset=beyond:Dot(frame.LookVector)
                        if offset>0 and offset<18+halfLength+ahead.HalfLength+6 and math.abs(beyond:Dot(frame.RightVector))<7 then blocked=true end
                    end
                end
                if blocked then
                    local room=math.max(0,along-18-halfLength)
                    if room<travel then travel=room;reason="Train Crossing" end
                end
            end
        end
    end
    if not probe then
        vehicle:SetAttribute("TrafficStopReason",reason)
    end
    return travel,reason,reservations
end
-- Called only after collision checks accept the actual move. A blocked proposal cannot own a junction.
function Rules.CommitMove(vehicle,frame,travel,reservations)
    if travel<=0 then return end
    for _,reservation in ipairs(reservations or {}) do
        if reservation.Stop<travel then
            reservation.Signal.Commitments[vehicle]={Direction=frame.LookVector,Position=frame.Position,
                Approach=reservation.Along,Center=reservation.Center,Entered=false}
        end
    end
end
return Rules



