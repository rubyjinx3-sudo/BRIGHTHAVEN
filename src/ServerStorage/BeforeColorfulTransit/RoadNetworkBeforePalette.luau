local Network = {}
local spacing, clearance = 12, 10
local roads, nodes, byKey = {}, {}, {}
local function key(x, z) return x .. ":" .. z end
local function onRoad(point)
    for _, road in ipairs(roads) do
        local p = road.CFrame:PointToObjectSpace(point)
        if math.abs(p.X) <= road.Size.X / 2 and math.abs(p.Z) <= road.Size.Z / 2 then return true end
    end
    return false
end
local function safe(point)
    if not onRoad(point) then return false end
    for i = 0, 7 do
        local angle = i * math.pi / 4
        if not onRoad(point + Vector3.new(math.cos(angle) * clearance, 0, math.sin(angle) * clearance)) then return false end
    end
    return true
end
local roadParts = {}
for _, child in ipairs(workspace["Possible Map Replacement"]:GetChildren()) do
    if child.Name == "DriveGround" and child:IsA("Model") then
        for _, part in ipairs(child:GetChildren()) do
            if part:IsA("BasePart") then table.insert(roadParts, part) end
        end
    elseif child.Name == "DriveGround" and child:IsA("BasePart") then
        table.insert(roadParts, child)
    end
end
if #roadParts == 0 then warn("[RoadNetwork] No DriveGround parts found; traffic disabled.") end
for _, part in ipairs(roadParts) do
    if part.Size.Y < .8 and math.min(part.Size.X, part.Size.Z) >= 18
        and math.min(part.Size.X, part.Size.Z) <= 60 and math.abs(part.Color.R - 99 / 255) < .015 then
        table.insert(roads, part)
    end
end
local candidates = {}
for _, road in ipairs(roads) do
    local u,v=road.CFrame.RightVector,road.CFrame.LookVector
    local extent = Vector3.new(math.abs(u.X),0,math.abs(u.Z))*road.Size.X/2 + Vector3.new(math.abs(v.X),0,math.abs(v.Z))*road.Size.Z/2
    for x = math.ceil((road.Position.X - extent.X) / spacing), math.floor((road.Position.X + extent.X) / spacing) do
        for z = math.ceil((road.Position.Z - extent.Z) / spacing), math.floor((road.Position.Z + extent.Z) / spacing) do
            candidates[key(x, z)] = {X = x, Z = z}
        end
    end
end
for id, cell in pairs(candidates) do
    local position = Vector3.new(cell.X * spacing, 0, cell.Z * spacing)
    if safe(position) then
        local node = {Id = id, X = cell.X, Z = cell.Z, Position = position, Neighbours = {}}
        byKey[id] = node
        table.insert(nodes, node)
    end
end
for _, node in ipairs(nodes) do
    for x = -1, 1 do for z = -1, 1 do
        if x ~= 0 or z ~= 0 then
            local neighbour = byKey[key(node.X + x, node.Z + z)]
            if neighbour then
                local valid = true
                for step = 1, 3 do if not safe(node.Position:Lerp(neighbour.Position, step / 4)) then valid = false; break end end
                if valid then table.insert(node.Neighbours, neighbour) end
            end
        end
    end end
end
-- Keep destinations on the largest connected street network, never across an unpaved gap.
local visited, largest = {}, {}
for _, start in ipairs(nodes) do
    if not visited[start] then
        local group, index = {start}, 1
        visited[start] = true
        while index <= #group do
            local node = group[index]; index += 1
            for _, neighbour in ipairs(node.Neighbours) do
                if not visited[neighbour] then visited[neighbour] = true; table.insert(group, neighbour) end
            end
        end
        if #group > #largest then largest = group end
    end
end
Network.Nodes, Network.Roads = largest, roads
if #largest <= 10 then warn("[RoadNetwork] No connected road-only traffic network found; traffic disabled.") end

function Network.Frame(journey, distance, height)
    local d = math.clamp(distance, 0, journey.Length)
    for i = 2, #journey.Path do
        local a, b = journey.Path[i - 1].Position, journey.Path[i].Position
        local length = (b - a).Magnitude
        if d <= length or i == #journey.Path then
            local p = a:Lerp(b, math.clamp(d / length, 0, 1)) + Vector3.new(0, height, 0)
            return CFrame.lookAt(p, p + b - a)
        end
        d -= length
    end
end

function Network.Journey(start, rng, avoid)
    rng = rng or Random.new()
    if avoid then avoid = Vector3.new(avoid.X, 0, avoid.Z) end
    start = start or largest[rng:NextInteger(1, #largest)]
    start = start.Anchor or start
    local queue, previous, index = {start}, {[start] = false}, 1
    while index <= #queue do
        local node = queue[index]; index += 1
        for _, neighbour in ipairs(node.Neighbours) do
            local clear = not avoid or (neighbour.Position - avoid).Magnitude >= (start.Position - avoid).Magnitude - 1
            if previous[neighbour] == nil and clear then previous[neighbour] = node; table.insert(queue, neighbour) end
        end
    end
    local choices = {}
    for _, node in ipairs(queue) do if (node.Position - start.Position).Magnitude > 180 then table.insert(choices, node) end end
    if #choices == 0 then for _, node in ipairs(queue) do if node ~= start then table.insert(choices, node) end end end
    if #choices == 0 and avoid then return Network.Journey(start, rng) end
    local finish = choices[rng:NextInteger(1, #choices)]
    local reverse, node = {}, finish
    while node do table.insert(reverse, node); node = previous[node] end
    local path, length = {}, 0
    for i = #reverse, 1, -1 do
        table.insert(path, reverse[i])
        if #path > 1 then length += (path[#path].Position - path[#path - 1].Position).Magnitude end
    end
    return {Path = path, Length = length, Finish = finish}
end

function Network.Detour(journey, distance, rng, avoid)
    local current = Network.Frame(journey, distance, 0).Position
    local left = distance
    local previous = journey.Path[1]
    for i = 2, #journey.Path do
        local length = (journey.Path[i].Position - journey.Path[i - 1].Position).Magnitude
        previous = journey.Path[i - 1]
        if left <= length then break end
        left -= length
    end
    previous = previous.Anchor or previous
    local result = Network.Journey(previous, rng, avoid)
    if (current - previous.Position).Magnitude > .01 then
        table.insert(result.Path, 1, {Position = current, Anchor = previous})
        result.Length += (current - previous.Position).Magnitude
    end
    return result
end

function Network.Contains(frame, size)
    for _, x in ipairs({-size.X / 2, 0, size.X / 2}) do
        for _, z in ipairs({-size.Z / 2, 0, size.Z / 2}) do
            if not onRoad(frame:PointToWorldSpace(Vector3.new(x, 0, z))) then return false end
        end
    end
    return true
end
return Network
