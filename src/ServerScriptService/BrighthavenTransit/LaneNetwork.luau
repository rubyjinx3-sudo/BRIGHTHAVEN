local RoadNetwork=require(script.Parent.RoadNetwork)
local function build(vehicleSize,finite)
local Network={Edges={},Transitions={},Nodes={}}
local roads=RoadNetwork.Roads
local function flat(v) return Vector3.new(v.X,0,v.Z) end
local function cross(a,b) return a.X*b.Z-a.Z*b.X end
local function frame(point,direction) return CFrame.lookAt(point,point+direction) end
local function right(direction) return Vector3.new(-direction.Z,0,direction.X) end
local function contains(point,direction)
    return RoadNetwork.Contains(frame(point,direction),vehicleSize)
end
local segments={}
for _,road in ipairs(roads) do
    local length,width=math.max(road.Size.X,road.Size.Z),math.min(road.Size.X,road.Size.Z)
    if length>=width*1.3 and length>(finite and 20 or 45) then
        local direction=flat(road.Size.X>road.Size.Z and road.CFrame.RightVector or road.CFrame.LookVector).Unit
        local a=flat(road.Position)-direction*length/2
        table.insert(segments,{A=a,Direction=direction,Length=length,Width=width,Cuts={math.min(20,length/3),length-math.min(20,length/3)}})
    end
end
local function cut(segment,point)
    local t=(point-segment.A):Dot(segment.Direction)
    for _,old in ipairs(segment.Cuts) do if math.abs(old-t)<2 then return end end
    table.insert(segment.Cuts,t)
end
for i,a in ipairs(segments) do
    for j=i+1,#segments do
        local b=segments[j]
        local denominator=cross(a.Direction,b.Direction)
        if math.abs(denominator)>.05 then
            local t=cross(b.A-a.A,b.Direction)/denominator
            local u=cross(b.A-a.A,a.Direction)/denominator
            local margin=22
            if t>=-margin and t<=a.Length+margin and u>=-margin and u<=b.Length+margin then
                local p=a.A+a.Direction*t
                if contains(p,a.Direction) and contains(p,b.Direction) then cut(a,p);cut(b,p) end
            end
        elseif math.abs(cross(b.A-a.A,a.Direction))<5 then
            for _,endA in ipairs({a.A,a.A+a.Direction*a.Length}) do
                for _,endB in ipairs({b.A,b.A+b.Direction*b.Length}) do
                    if (endA-endB).Magnitude<46 then
                        local p=(endA+endB)/2
                        if contains(p,a.Direction) then cut(a,p);cut(b,p) end
                    end
                end
            end
        end
    end
end
local function vertex(point)
    for _,v in ipairs(Network.Nodes) do if (v.Position-point).Magnitude<4 then return v end end
    local v={Position=point,Edges={}}
    table.insert(Network.Nodes,v);return v
end
local function append(points,point,direction)
    if #points==0 or (points[#points].Position-point).Magnitude>.001 then
        table.insert(points,{Position=point,Direction=direction})
    end
end
local function edge(a,b,width)
    local delta=b.Position-a.Position
    if delta.Magnitude<5 then return end
    local d=delta.Unit
    local trim=math.min(18,delta.Magnitude*.35)
    local offset=math.min(8,width/4)
    local start=a.Position+d*trim+right(d)*offset
    local finish=b.Position-d*trim+right(d)*offset
    local points={}
    local length=(finish-start).Magnitude
    for i=0,math.ceil(length/3) do
        local p=start:Lerp(finish,i/math.max(1,math.ceil(length/3)))
        if not contains(p,d) then return end
        append(points,p,d)
    end
    local result={From=a,To=b,Direction=d,Offset=offset,Trim=trim,Start=start,Finish=finish,Points=points,Choices={}}
    table.insert(Network.Edges,result);table.insert(a.Edges,result)
end
for _,s in ipairs(segments) do
    table.sort(s.Cuts)
    for i=2,#s.Cuts do
        local a,b=vertex(s.A+s.Direction*s.Cuts[i-1]),vertex(s.A+s.Direction*s.Cuts[i])
        edge(a,b,s.Width);edge(b,a,s.Width)
    end
end
local function transition(incoming,outgoing)
    local points={}
    local d,e=incoming.Direction,outgoing.Direction
    if d:Dot(e)<-.98 then
        local centre=incoming.Finish-right(d)*incoming.Offset
        if math.abs(incoming.Offset-outgoing.Offset)>.1 or math.abs(incoming.Trim-outgoing.Trim)>.1 then return end
        for i=0,18 do
            local theta=math.pi*i/18
            local p=centre+right(d)*incoming.Offset*math.cos(theta)+d*incoming.Offset*math.sin(theta)
            local heading=(-right(d)*math.sin(theta)+d*math.cos(theta)).Unit
            if not contains(p,heading) then return end
            append(points,p,heading)
        end
    else
        local a,b=incoming.Finish,outgoing.Start
        local denominator=cross(d,e)
        local control=(a+b)/2
        if math.abs(denominator)>.05 then control=a+d*(cross(b-a,e)/denominator) end
        -- Short connector trims can put the tangent intersection behind the vehicle.
        -- Reject that turn instead of generating a backwards curve into following traffic.
        if (control-a):Dot(d)<-.01 or (b-control):Dot(e)<-.01 then return end
        local steps=math.max(4,math.ceil(((a-control).Magnitude+(control-b).Magnitude)/2))
        for i=0,steps do
            local t=i/steps
            local p=a*(1-t)^2+control*(2*t*(1-t))+b*t*t
            local heading=((control-a)*(1-t)+(b-control)*t)
            if heading.Magnitude<.01 then heading=d:Lerp(e,t) end
            heading=heading.Unit
            if not contains(p,heading) then return end
            append(points,p,heading)
        end
    end
    return {Edge=outgoing,Points=points,UTurn=d:Dot(e)<-.98}
end
for _,incoming in ipairs(Network.Edges) do
    for _,outgoing in ipairs(incoming.To.Edges) do
        local turn=transition(incoming,outgoing)
        if turn then table.insert(incoming.Choices,turn);table.insert(Network.Transitions,turn) end
    end
end
-- Remove lanes that cannot continue; random traffic never escapes a street by reversing through a red light.
local changed=true
while changed and not finite do
    changed=false
    for _,e in ipairs(Network.Edges) do
        for i=#e.Choices,1,-1 do if #e.Choices[i].Edge.Choices==0 then table.remove(e.Choices,i);changed=true end end
    end
end
local usable={}
for _,e in ipairs(Network.Edges) do if finite or #e.Choices>0 then table.insert(usable,e) end end
Network.SpawnEdges=usable
assert(#usable>=8,"Not enough connected, footprint-safe traffic lanes")
function Network.Journey(start,rng)
    rng=rng or Random.new()
    local points={}
    local current=start and start.Edge or usable[rng:NextInteger(1,#usable)]
    local spawnLength=start and 0 or (current.Finish-current.Start).Magnitude
    local function add(list) for _,p in ipairs(list) do append(points,p.Position,p.Direction) end end
    if not start then add(current.Points) end
    for _=1,rng:NextInteger(6,10) do
        local choices={}
        for _,turn in ipairs(current.Choices) do if not turn.UTurn then table.insert(choices,turn) end end
        if #choices==0 then choices=current.Choices end
        local turn=choices[rng:NextInteger(1,#choices)]
        add(turn.Points);current=turn.Edge;add(current.Points)
    end
    local length,cumulative=0,{0}
    for i=2,#points do length+=(points[i].Position-points[i-1].Position).Magnitude;cumulative[i]=length end
    return {Path=points,Length=length,Cumulative=cumulative,Finish={Edge=current},LaneJourney=true,SpawnLength=spawnLength}
end
function Network.Frame(journey,distance,height)
    local d=math.clamp(distance,0,journey.Length)
    local lo,hi=2,#journey.Path
    while lo<hi do local mid=math.floor((lo+hi)/2);if journey.Cumulative[mid]<d then lo=mid+1 else hi=mid end end
    local a,b=journey.Path[lo-1],journey.Path[lo]
    local segment=journey.Cumulative[lo]-journey.Cumulative[lo-1]
    local t=segment>0 and math.clamp((d-journey.Cumulative[lo-1])/segment,0,1) or 0
    local p=a.Position:Lerp(b.Position,t)+Vector3.new(0,height or -142.974,0)
    local direction=a.Direction:Lerp(b.Direction,t).Unit
    return CFrame.lookAt(p,p+direction)
end
function Network.Between(startPosition,startDirection,endPosition,endDirection)
    local function nearest(position,direction)
        local best,score,point
        for _,e in ipairs(usable) do
            if e.Direction:Dot(direction)>.8 then
                local delta=e.Finish-e.Start
                local t=math.clamp((flat(position)-e.Start):Dot(delta)/delta:Dot(delta),0,1)
                local p=e.Start+delta*t
                local distance=(p-flat(position)).Magnitude
                if not score or distance<score then best,score,point=e,distance,p end
            end
        end
        assert(best,"Missing directed shuttle lane");return best,point
    end
    local first,start=nearest(startPosition,startDirection)
    local goal,finish=nearest(endPosition,endDirection)
    if first==goal and (finish-start):Dot(first.Direction)>0 then
        return {{Position=start,Direction=first.Direction},{Position=finish,Direction=goal.Direction}}
    end
    local costs,previous,done={[first]=0},{},{}
    local loop=first==goal
    if loop then
        costs={}
        for _,turn in ipairs(first.Choices) do
            costs[turn.Edge]=(first.Finish-turn.Edge.Finish).Magnitude+(turn.UTurn and 100 or 0)
            previous[turn.Edge]={Edge=first,Turn=turn,FromStart=true}
        end
    end
    while not done[goal] do
        local current,cost
        for e,c in pairs(costs) do if not done[e] and (not cost or c<cost) then current,cost=e,c end end
        assert(current,"No lane-connected shuttle route")
        done[current]=true
        for _,turn in ipairs(current.Choices) do
            local e=turn.Edge
            local nextCost=cost+(current.Finish-e.Finish).Magnitude+(turn.UTurn and 100 or 0)
            if not costs[e] or nextCost<costs[e] then costs[e]=nextCost;previous[e]={Edge=current,Turn=turn} end
        end
    end
    local turns,current={},goal
    while loop or current~=first do
        local step=previous[current];assert(step);table.insert(turns,1,step.Turn);current=step.Edge
        if step.FromStart then break end
    end
    local points={}
    append(points,start,first.Direction)
    append(points,first.Finish,first.Direction)
    for _,turn in ipairs(turns) do
        for _,p in ipairs(turn.Points) do append(points,p.Position,p.Direction) end
        if turn.Edge~=goal then for _,p in ipairs(turn.Edge.Points) do append(points,p.Position,p.Direction) end end
    end
    append(points,finish,goal.Direction)
    return points
end
return Network
end
local network=build(Vector3.new(9,6,15),false)
local taxiNetwork
function network.ForTaxi()
    if not taxiNetwork then taxiNetwork=build(Vector3.new(5,6,9),true) end
    return taxiNetwork
end
return network


