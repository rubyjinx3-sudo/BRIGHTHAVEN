local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Fleet = require(script.Parent.TransitFleet)
local Routes = require(script.Parent.TransitRoutes)
local traffic = workspace:WaitForChild("BrighthavenTransit")
local sidewalks = workspace:WaitForChild("BrighthavenSidewalks")
local request = ReplicatedStorage:WaitForChild("Brighthaven"):WaitForChild("Transit"):WaitForChild("RideRequest")
local rides, cooldowns, registered = {}, {}, {}
local calls, calledVehicles, callCooldowns = {}, {}, {}
local Practice = require(ReplicatedStorage.Brighthaven.TutorialPractice)

local function cancelCall(player, message)
    local call = calls[player]
    if call then calledVehicles[call.Vehicle] = nil; Fleet.ClearStop(call.Vehicle) end
    calls[player] = nil
    player:SetAttribute("JeepneyCallVehicle", nil)
    player:SetAttribute("JeepneyCallActive", false)
    player:SetAttribute("JeepneyCallMessage", message or "")
    if message then
        task.delay(4, function() if player.Parent and not calls[player] then player:SetAttribute("JeepneyCallMessage", "") end end)
    end
end

local function callJeepney(player)
    if calls[player] then cancelCall(player, "Call canceled."); return end
    local now = os.clock()
    if now < (callCooldowns[player] or 0) then return end
    callCooldowns[player] = now + 2
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart or rides[player]
        or not Practice.CanUseWorld(player) or player:GetAttribute("HasStartedGame") ~= true then return end
    local rays = RaycastParams.new()
    rays.FilterType, rays.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {sidewalks}
    if not workspace:Raycast(root.Position + Vector3.new(0, 4, 0), Vector3.new(0, -18, 0), rays) then
        cancelCall(player, "Walk to a sidewalk to call a jeepney."); return
    end
    local goals = {}
    for _,route in ipairs({"Clockwise", "Counterclockwise"}) do
        local best, distance
        for d = 0, Routes.Length(route), 6 do
            local frame = Routes.Frame(route, d, -142.974)
            local offset = frame:PointToObjectSpace(root.Position)
            if offset.X >= 7 and offset.X <= 38 then
                local gap = Vector2.new(offset.X, offset.Z).Magnitude
                if not best or gap < best then best, distance = gap, d end
            end
        end
        if best and best < 40 then goals[route] = distance end
    end
    local vehicle, goal, bestTime
    for candidate,prompt in pairs(registered) do
        local state = Fleet.GetState(candidate)
        if candidate:GetAttribute("VehicleKind") == "Jeepney" and state and goals[state.Route] and prompt.Enabled and not calledVehicles[candidate] then
            local remaining = (goals[state.Route] - state.Distance) % Routes.Length(state.Route)
            if remaining < 8 then remaining = 8 end
            local eta = remaining / math.max(10, state.Speed)
            if eta < 90 and (not bestTime or eta < bestTime) then
                vehicle, goal, bestTime = candidate, state.Distance + remaining, eta
            end
        end
    end
    if not vehicle then cancelCall(player, "Try a sidewalk beside the main jeepney route."); return end
    if not Fleet.StopAt(vehicle, goal) then return end
    calls[player] = {Vehicle=vehicle, Character=character, Point=root.Position, Expires=now+bestTime+90}
    calledVehicles[vehicle] = player
    player:SetAttribute("JeepneyCallActive", true)
    player:SetAttribute("JeepneyCallVehicle", vehicle.Name)
    player:SetAttribute("JeepneyCallMessage", "Your jeepney is coming. Wait on the sidewalk!")
end

local function refreshPrompt(vehicle)
    local prompt = vehicle:FindFirstChild("RidePrompt", true)
    if not prompt then return end
    local free = 0
    for _,seat in ipairs(vehicle:GetChildren()) do
        if seat:IsA("Seat") and not seat.Occupant and not seat:GetAttribute("Reserved") then free += 1 end
    end
    prompt.Enabled = free > 0
end

local function release(player)
    local ride = rides[player]
    if not ride then return end
    rides[player] = nil
    for _,connection in ipairs(ride.Connections) do connection:Disconnect() end
    if ride.Seat.Occupant == ride.Humanoid and not ride.Exiting then
        local weld = ride.Seat:FindFirstChild("SeatWeld")
        if weld and weld:IsA("Weld") and weld.Part1 and weld.Part1:IsDescendantOf(ride.Humanoid.Parent) then weld:Destroy() end
        ride.Humanoid.Sit = false
    end
    ride.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, ride.JumpEnabled)
    ride.Seat:SetAttribute("Reserved", nil)
    player:SetAttribute("BrighthavenRiding", nil)
    player:SetAttribute("BrighthavenRideVehicle", nil)
    player:SetAttribute("BrighthavenRideKind", nil)
    player:SetAttribute("BrighthavenRideWaiting", nil)
    refreshPrompt(ride.Vehicle)
end

local function safeExit(ride)
    local state = Fleet.GetState(ride.Vehicle)
    local character = ride.Humanoid.Parent
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not state or not root then return nil end
    local rays = RaycastParams.new()
    rays.FilterType, rays.FilterDescendantsInstances = Enum.RaycastFilterType.Include, {sidewalks}
    local overlap = OverlapParams.new()
    local ignore = {character, traffic}
    for _,child in ipairs(workspace:GetChildren()) do
        if child:IsA("BasePart") and child:GetAttribute("TransitVehicle") then table.insert(ignore, child) end
    end
    overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, ignore
    overlap.RespectCanCollide = true
    for _,offset in ipairs({0, 8, -8, 16, -16, 24, -24, 32, -32, 48, -48}) do
        local frame = Routes.Frame(state.Route, state.Distance + offset, state.Height)
        for _,curbDistance in ipairs({15, 20, 25, 30, -31, -36, -41, -46}) do
        local point = frame:PointToWorldSpace(Vector3.new(curbDistance, 0, 0))
        local hit = workspace:Raycast(point + Vector3.new(0, 20, 0), Vector3.new(0, -40, 0), rays)
        if hit then
            local foot = hit.Position + Vector3.new(0, .2, 0)
            local size = Vector3.new(3, math.max(6, ride.Humanoid.HipHeight + root.Size.Y + 2), 3)
            local obstructed = false
            for _,part in ipairs(workspace:GetPartBoundsInBox(CFrame.new(foot + Vector3.new(0, size.Y / 2, 0)), size, overlap)) do
                if part.CanCollide and not part:IsDescendantOf(sidewalks) then obstructed = true; break end
            end
            if not obstructed then
                local leg = ride.Humanoid.RigType == Enum.HumanoidRigType.R6 and character:FindFirstChild("Left Leg")
                local floorHeight = ride.Humanoid.HipHeight + root.Size.Y / 2 + (leg and leg.Size.Y or 0)
                local position = foot + Vector3.new(0, floorHeight, 0)
                return CFrame.lookAt(position, position + frame.RightVector)
            end
        end
        end
    end
    return nil
end

local function getOff(player)
    local ride = rides[player]
    if not ride or ride.Exiting then return end
    local destination = safeExit(ride)
    if not destination then
        ride.PendingExit = true
        player:SetAttribute("BrighthavenRideWaiting", true)
        return
    end
    ride.Exiting = true
    Fleet.Pause(ride.Vehicle, 1.5)
    local humanoid, root = ride.Humanoid, ride.Humanoid.Parent:FindFirstChild("HumanoidRootPart")
    local weld = ride.Seat:FindFirstChild("SeatWeld")
    if weld and weld:IsA("Weld") and weld.Part1 and weld.Part1:IsDescendantOf(humanoid.Parent) then weld:Destroy() end
    humanoid.Sit = false
    if root and humanoid.Health > 0 then
        local wasAnchored = root.Anchored
        -- Hold the exit position until the client has received the removed seat weld.
        root.Anchored = true
        root.CFrame = destination
        root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
        humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        request:FireClient(player, "Exit", destination, humanoid.Parent)
        task.delay(.25, function()
            if not root.Parent then return end
            if player.Character == humanoid.Parent and humanoid.Health > 0 then
                root.CFrame = destination
                root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            end
            root.Anchored = wasAnchored
            if not wasAnchored and root:CanSetNetworkOwnership() then root:SetNetworkOwnershipAuto() end
        end)
    end
    release(player)
    cooldowns[player] = os.clock() + 2
end

local function board(player, vehicle, prompt)
    if rides[player] or os.clock() < (cooldowns[player] or 0) then return end
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root or humanoid.Health <= 0 or humanoid.SeatPart then return end
    if (root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance + 3 then return end
    local seat
    for _,candidate in ipairs(vehicle:GetChildren()) do
        if candidate:IsA("Seat") and not candidate.Occupant and not candidate:GetAttribute("Reserved") then seat = candidate; break end
    end
    if not seat then return end
    seat:SetAttribute("Reserved", true)
    Fleet.Pause(vehicle, 2)
    local ride = {Vehicle = vehicle, Seat = seat, Humanoid = humanoid, Connections = {},
        JumpEnabled = humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping)}
    rides[player] = ride
    cancelCall(player)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    seat:Sit(humanoid)
    player:SetAttribute("BrighthavenRideKind", vehicle:GetAttribute("VehicleKind"))
    player:SetAttribute("BrighthavenRideVehicle", vehicle.Name)
    player:SetAttribute("BrighthavenRiding", true)
    cooldowns[player] = os.clock() + .75
    table.insert(ride.Connections, humanoid.Died:Connect(function() release(player) end))
    table.insert(ride.Connections, player.CharacterRemoving:Connect(function() release(player) end))
    table.insert(ride.Connections, seat:GetPropertyChangedSignal("Occupant"):Connect(function()
        if seat.Occupant ~= humanoid and not ride.Exiting then release(player) end
        refreshPrompt(vehicle)
    end))
    task.delay(.5, function()
        if rides[player] == ride and seat.Occupant ~= humanoid then release(player) end
    end)
    refreshPrompt(vehicle)
end

local function register(vehicle)
    if registered[vehicle] or vehicle:GetAttribute("PrivateTaxi") or (vehicle:GetAttribute("VehicleKind") ~= "Jeepney" and not vehicle:GetAttribute("PublicRideEnabled")) then return end
    local prompt = vehicle:FindFirstChild("RidePrompt", true)
    if not prompt then return end
    registered[vehicle] = prompt
    prompt.Triggered:Connect(function(player) board(player, vehicle, prompt) end)
end
for _,vehicle in ipairs(traffic:GetChildren()) do register(vehicle) end
traffic.ChildAdded:Connect(register)
request.OnServerEvent:Connect(function(player, action)
    if action == "Exit" and os.clock() >= (cooldowns[player] or 0) then getOff(player) end
end)
Players.PlayerRemoving:Connect(function(player) cancelCall(player); release(player); cooldowns[player], callCooldowns[player] = nil, nil end)

-- Only an explicit call reserves a curb stop; nearby players no longer stop traffic.
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < .25 then return end
    elapsed = 0
    for player, ride in pairs(rides) do
        if ride.PendingExit then getOff(player) end
    end
    for player,call in pairs(calls) do
        local root = player.Character == call.Character and call.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = call.Character:FindFirstChildOfClass("Humanoid")
        local state = Fleet.GetState(call.Vehicle)
        if not root or not humanoid or humanoid.Health <= 0 or humanoid.SeatPart
            or not state or not call.Vehicle.Parent or (root.Position - call.Point).Magnitude > 45 or os.clock() > call.Expires then
            cancelCall(player, "Call ended. You can call again from a sidewalk.")
        elseif state.RequestedStop and state.RequestedStop.Remaining < 1.5 then
            if not call.Arrived then
                call.Arrived = true; call.Expires = os.clock() + 25
                player:SetAttribute("JeepneyCallMessage", "Your jeepney is here! Get on at the back.")
            end
        end
    end
end)
