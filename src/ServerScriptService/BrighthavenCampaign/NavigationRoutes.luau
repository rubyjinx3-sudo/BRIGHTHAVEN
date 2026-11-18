local Roads = require(script.Parent.RoadNavigationGraph)
local Routes = {}
local cache, order = {}, {}
local height = Vector3.new(0, -140.734, 0)
local function flat(point) return Vector3.new(point.X, 0, point.Z) end

local function nearest(point)
    local best, distance
    point = flat(point)
    for _, node in ipairs(Roads.Nodes) do
        local gap = (node.Position - point).Magnitude
        if not distance or gap < distance then best, distance = node, gap end
    end
    return best
end

local function simplify(points)
    local result = {}
    for _, point in ipairs(points) do
        if #result >= 2 then
            local a, b = result[#result - 1], result[#result]
            local first, second = b - a, point - b
            -- Only merge exactly straight road edges, never cut across a bend.
            if first.Magnitude > 0 and second.Magnitude > 0 and first.Unit:Dot(second.Unit) > .999999 then
                table.remove(result)
            end
        end
        table.insert(result, point)
    end
    return result
end

function Routes.Between(start, finish)
    local first, last = nearest(start), nearest(finish)
    if not first or not last then return nil, "Unavailable" end
    local key = first.Id .. ">" .. last.Id
    if cache[key] then return table.clone(cache[key]), "Town Roads" end
    local costs, previous, done = {[first] = 0}, {}, {}
    local open = {[first] = (first.Position-last.Position).Magnitude}
    while not done[last] do
        local current, cost
        for node, value in pairs(open) do
            if not cost or value < cost then current, cost = node, value end
        end
        if not current then return nil, "Unavailable" end
        open[current] = nil
        done[current] = true
        for _, neighbor in ipairs(current.Neighbours) do
            local candidate = costs[current] + (current.Position - neighbor.Position).Magnitude
            if not done[neighbor] and (not costs[neighbor] or candidate < costs[neighbor]) then
                costs[neighbor], previous[neighbor] = candidate, current
                open[neighbor] = candidate + (neighbor.Position-last.Position).Magnitude
            end
        end
    end
    local reverse, current = {}, last
    repeat
        table.insert(reverse, current.Position + height)
        current = previous[current]
    until not current
    local points = {}
    for index = #reverse, 1, -1 do table.insert(points, reverse[index]) end
    points = simplify(points)
    cache[key] = points
    table.insert(order, key)
    if #order > 64 then cache[table.remove(order, 1)] = nil end
    return table.clone(points), "Town Roads"
end

return Routes
