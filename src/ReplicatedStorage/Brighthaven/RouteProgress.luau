local Progress = {}
local function flat(point) return Vector3.new(point.X, 0, point.Z) end

function Progress.Trim(points, position, cursor)
    if #points < 2 then return table.clone(points), 1 end
    local nearest, projection, distance
    local first = math.clamp(cursor or 1, 1, #points - 1)
    local finish = cursor and math.min(#points - 1, first + 3) or #points - 1
    for index = first, finish do
        local a, b = points[index], points[index + 1]
        local delta = flat(b - a)
        local t = delta.Magnitude > 0 and math.clamp(flat(position - a):Dot(delta) / delta:Dot(delta), 0, 1) or 0
        local point = a:Lerp(b, t)
        local gap = flat(position - point).Magnitude
        if not distance or gap < distance then nearest, projection, distance = index, point, gap end
    end
    -- A player walking in a lot does not create a new diagonal across the lot.
    if distance > 24 then return table.clone(points), first end
    local remaining = {projection}
    for index = nearest + 1, #points do table.insert(remaining, points[index]) end
    return remaining, nearest
end

return Progress
