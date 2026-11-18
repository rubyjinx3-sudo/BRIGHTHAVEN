local RunService = game:GetService("RunService")
local Routes = require(script.Parent.TransitRoutes)
local RoadNetwork = require(script.Parent:WaitForChild("LaneNetwork"))
local TrafficRules = require(script.Parent:WaitForChild("TrafficRules"))
local Fleet = {Ready = false}
local vehicles = {}
if RunService:IsRunning() then TrafficRules.ConfigureLanes(RoadNetwork) end

function Fleet.GetState(vehicle)
    return vehicles[vehicle]
end

function Fleet.CanSpawnAt(position,radius)
    if not TrafficRules.ClearRailSpawn(position,radius) then return false end
    for vehicle,state in pairs(TrafficRules.Vehicles) do
        if vehicle.Parent and ((state.Frame.Position-position)*Vector3.new(1,0,1)).Magnitude<radius then return false end
    end
    return true
end

function Fleet.StopAt(vehicle, distance)
    local state = vehicles[vehicle]
    if not state or state.Journey then return false end
    state.RequestedStop = {Remaining=(distance-state.Distance)%Routes.Length(state.Route)}
    return true
end

function Fleet.ClearStop(vehicle)
    local state = vehicles[vehicle]
    if state then state.RequestedStop = nil end
end

function Fleet.Pause(vehicle, seconds)
    local state = vehicles[vehicle]
    if state then
        state.StoppedUntil = math.max(state.StoppedUntil, os.clock() + seconds)
        state.Velocity = 0
    end
end

function Fleet.FindSpawnDistance(route)
    local positions = {}
    for vehicle, state in pairs(vehicles) do
        if vehicle.Parent and state.Route == route then table.insert(positions, state.Distance) end
    end
    table.sort(positions)
    local length = Routes.Length(route)
    if #positions == 0 then return 0 end
    local bestGap, distance = 0, 0
    for i, start in ipairs(positions) do
        local finish = positions[i + 1] or positions[1] + length
        if finish - start > bestGap then
            bestGap, distance = finish - start, (start + finish) / 2
        end
    end
    return distance % length
end

function Fleet.Register(vehicle)
    if vehicles[vehicle] then return vehicles[vehicle] end
    assert(vehicle:IsA("Model") or vehicle:IsA("BasePart"), "Expected a transit vehicle")
    local route = vehicle:GetAttribute("Route") or "Clockwise"
    assert(route == "Clockwise" or route == "Counterclockwise" or route == "Roaming", "Unknown transit route")
    local height, halfLength = -142.974, 10
    if vehicle:IsA("BasePart") then
        height += vehicle.Size.Y / 2
        halfLength = vehicle.Size.Z / 2
        vehicle.Anchored, vehicle.CanCollide, vehicle.CanTouch = true, false, false
    else
        halfLength = vehicle:GetAttribute("HalfLength") or (vehicle:GetAttribute("VehicleKind") == "Bus" and 12 or 10)
    end
    halfLength = TrafficRules.Dimensions(vehicle)
    local state = {
        Vehicle = vehicle,
        Route = route,
        Distance = route == "Roaming" and 0 or (vehicle:GetAttribute("StartDistance") or Fleet.FindSpawnDistance(route)) % Routes.Length(route),
        Speed = vehicle:GetAttribute("CruiseSpeed") or 40,
        Velocity = 0,
        Height = height,
        HalfLength = halfLength,
        StoppedUntil = 0,
    }
    if route == "Roaming" then
        state.Random = Random.new()
        for attempt = 1, 60 do
            state.Journey = RoadNetwork.Journey(nil, state.Random)
            state.Distance = state.Random:NextNumber(.3, .7) * state.Journey.SpawnLength
            state.Frame = RoadNetwork.Frame(state.Journey, state.Distance, height)
            local crowded = not TrafficRules.ClearSpawn(state.Frame,halfLength)
            for other,observed in pairs(TrafficRules.Vehicles) do
                if other~=vehicle and other.Parent and (observed.Frame.Position-state.Frame.Position).Magnitude<50 then crowded=true;break end
            end
            if not crowded then break end
            if attempt==60 then error("No clear traffic spawn lane") end
        end
    else
        for attempt=1,60 do
            state.Frame=Routes.Frame(route,state.Distance,height)
            if TrafficRules.ClearSpawn(state.Frame,halfLength) and Fleet.CanSpawnAt(state.Frame.Position,45) then break end
            assert(attempt<60,"No clear fixed-route traffic spawn")
            state.Distance=(state.Distance+47)%Routes.Length(route)
        end
    end
    vehicles[vehicle] = state
    vehicle:PivotTo(state.Frame)
    TrafficRules.Observe(vehicle,state.Frame,state.HalfLength)
    return state
end

function Fleet.SetJourney(vehicle,points,speed)
    assert(#points>=2,"A ride needs a road route")
    local cumulative,length={0},0
    for i=2,#points do length+=(points[i].Position-points[i-1].Position).Magnitude;cumulative[i]=length end
    assert(length>.01,"A ride route is too short")
    local state=vehicles[vehicle] or Fleet.Register(vehicle)
    state.Journey={Path=points,Cumulative=cumulative,Length=length,LaneJourney=true}
    state.FiniteJourney=true;state.Distance=0;state.RequestedStop=nil;state.Speed=speed or 40
    state.Frame=RoadNetwork.Frame(state.Journey,0,state.Height)
    vehicle:SetAttribute("JourneyComplete",false)
    vehicle:PivotTo(state.Frame)
    TrafficRules.Observe(vehicle,state.Frame,state.HalfLength)
    return state
end

-- Advance every vehicle from the same snapshot so update order cannot erase following gaps.
if RunService:IsRunning() then
RunService.Heartbeat:Connect(function(dt)
    local step = math.clamp(dt, .001, .05)
    local moves, now = {}, os.clock()
    for vehicle, state in pairs(vehicles) do
        if not vehicle.Parent then
            vehicles[vehicle] = nil
        else
            state.PriorityElapsed=(state.PriorityElapsed or 0)+step
            if vehicle:GetAttribute("TaxiState")=="Driving" and state.PriorityElapsed>=.2 then
                state.PriorityElapsed=0
                TrafficRules.RequestShuttlePriority(vehicle,state.Frame)
                for _,ahead in ipairs({40,80}) do
                    TrafficRules.RequestShuttlePriority(vehicle,RoadNetwork.Frame(state.Journey,math.min(state.Journey.Length,state.Distance+ahead),state.Height))
                end
            end
            local desired = TrafficRules.SpeedLimit(state.Frame, state.Speed)
            local lookFrame
            if state.Journey then
                lookFrame = RoadNetwork.Frame(state.Journey, math.min(state.Journey.Length, state.Distance + 24), state.Height)
            else
                lookFrame = Routes.Frame(state.Route, state.Distance + 24, state.Height)
            end
            local angle = math.acos(math.clamp(state.Frame.LookVector:Dot(lookFrame.LookVector), -1, 1))
            if angle > math.rad(12) then desired = math.min(desired, angle > math.rad(45) and 18 or 24) end
            local braking, acceleration = 28, 15
            local horizon = math.max(12, state.Velocity ^ 2 / (2 * braking) + 3)
            local clearance, anticipation = TrafficRules.Constrain(vehicle, state.Frame, horizon, state.HalfLength, true)
            state.CurveSamples=TrafficRules.CurveSamples(state.Frame,function(ahead)
                return state.Journey and RoadNetwork.Frame(state.Journey,math.min(state.Journey.Length,state.Distance+ahead),state.Height)
                    or Routes.Frame(state.Route,state.Distance+ahead,state.Height)
            end)
            local curvedClearance,curveReason=TrafficRules.FollowCurve(vehicle,state.Frame,clearance,state.HalfLength,state.CurveSamples)
            if curvedClearance<clearance then clearance,anticipation=curvedClearance,curveReason end
            local target = math.min(desired, math.sqrt(2 * braking * math.max(0, clearance - 1)))
            if state.FiniteJourney then
                local remaining=state.Journey.Length-state.Distance
                target=math.min(target,math.sqrt(2*braking*math.max(0,remaining)))
                if remaining<.08 then target=0 end
            end
            if state.RequestedStop then
                target = math.min(target, math.sqrt(2 * braking * math.max(0, state.RequestedStop.Remaining - .5)))
            end
            if now < state.StoppedUntil then target = 0 end
            state.Velocity += math.clamp(target - state.Velocity, -braking * step, acceleration * step)
            local travel = state.Velocity * step
            local length = state.Journey and state.Journey.Length or Routes.Length(state.Route)
            for other, ahead in pairs(vehicles) do
                if other ~= vehicle and other.Parent and not state.Journey and ahead.Route == state.Route then
                    local gap = (ahead.Distance - state.Distance) % length
                    if gap > 0 then
                        local room = gap - state.HalfLength - ahead.HalfLength - 10
                        travel = math.min(travel, math.max(0, room))
                    end
                end
            end
            local actual, reason = TrafficRules.Constrain(vehicle, state.Frame, travel, state.HalfLength)
            travel = actual
            if state.Journey then travel=math.min(travel,math.max(0,state.Journey.Length-state.Distance)) end
            if state.RequestedStop then travel = math.min(travel, math.max(0, state.RequestedStop.Remaining)) end
            state.Velocity = travel / step
            if reason == "" and target < desired and anticipation ~= "" then vehicle:SetAttribute("TrafficStopReason", anticipation) end
            state.Anticipation=anticipation
            moves[state] = travel
        end
    end
    for state, travel in pairs(moves) do
        -- Recheck after earlier vehicles commit their accepted moves this tick.
        local reservations,reason
        travel,reason,reservations=TrafficRules.Constrain(state.Vehicle,state.Frame,travel,state.HalfLength)
        local curveTravel,curveReason=TrafficRules.FollowCurve(state.Vehicle,state.Frame,travel,state.HalfLength,state.CurveSamples)
        if curveTravel<travel then travel=curveTravel;state.Vehicle:SetAttribute("TrafficStopReason",curveReason) end
        local candidate=state.Journey and RoadNetwork.Frame(state.Journey,math.min(state.Distance+travel,state.Journey.Length),state.Height)
            or Routes.Frame(state.Route,state.Distance+travel,state.Height)
        if travel>0 and not TrafficRules.CanMoveTo(state.Vehicle,state.Frame,candidate,state.HalfLength) then
            travel=0;state.Velocity=0;state.Vehicle:SetAttribute("TrafficStopReason","Yielding to Cross Traffic")
        end
        state.Velocity=travel/step
        if travel<.01 and reason=="" and state.Anticipation~="" then state.Vehicle:SetAttribute("TrafficStopReason",state.Anticipation) end
        TrafficRules.CommitMove(state.Vehicle,state.Frame,travel,reservations)
        if state.RequestedStop then state.RequestedStop.Remaining = math.max(0, state.RequestedStop.Remaining - travel) end
        if state.Journey then
            state.Distance+=travel
            if state.FiniteJourney and state.Distance>=state.Journey.Length-.08 then
                state.Distance=state.Journey.Length;state.Velocity=0
                state.Vehicle:SetAttribute("JourneyComplete",true)
            elseif not state.FiniteJourney and state.Distance>=state.Journey.Length then
                state.Distance-=state.Journey.Length
                state.Journey=RoadNetwork.Journey(state.Journey.Finish,state.Random)
                state.Vehicle:SetAttribute("DestinationsVisited",(state.Vehicle:GetAttribute("DestinationsVisited") or 0)+1)
            end
            state.Frame=RoadNetwork.Frame(state.Journey,state.Distance,state.Height)
        else
            state.Distance = (state.Distance + travel) % Routes.Length(state.Route)
            state.Frame=Routes.Frame(state.Route,state.Distance,state.Height)
        end
        state.Vehicle:PivotTo(state.Frame)
        TrafficRules.Observe(state.Vehicle,state.Frame,state.HalfLength)
        state.Vehicle:SetAttribute("CurrentSpeed",travel/step)
    end
end)
end

return Fleet


