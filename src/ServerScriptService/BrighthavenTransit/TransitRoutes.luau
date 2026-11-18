local Routes = {}
local left, right = -200, 200
local north, south = -175, 175
local radius = 28
local function layout(route)
    local inset = route == "Clockwise" and 8 or -8
    local x0, x1, z0, z1 = left + inset, right - inset, north + inset, south - inset
    local w, h = x1 - x0 - 2 * radius, z1 - z0 - 2 * radius
    local arc = math.pi * radius / 2
    return x0, x1, z0, z1, w, h, arc, 2 * w + 2 * h + 4 * arc
end
function Routes.Length(route)
    local _, _, _, _, _, _, _, length = layout(route)
    return length
end
function Routes.Frame(route, distance, height)
    local x0, x1, z0, z1, w, h, arc, length = layout(route)
    local reverse = route ~= "Clockwise"
    local d = (reverse and -distance or distance) % length
    local pieces = {
        {w, Vector3.new(x0 + radius, 0, z0), Vector3.xAxis},
        {arc, Vector3.new(x1 - radius, 0, z0 + radius), -.5 * math.pi},
        {h, Vector3.new(x1, 0, z0 + radius), Vector3.zAxis},
        {arc, Vector3.new(x1 - radius, 0, z1 - radius), 0},
        {w, Vector3.new(x1 - radius, 0, z1), -Vector3.xAxis},
        {arc, Vector3.new(x0 + radius, 0, z1 - radius), .5 * math.pi},
        {h, Vector3.new(x0, 0, z1 - radius), -Vector3.zAxis},
        {arc, Vector3.new(x0 + radius, 0, z0 + radius), math.pi},
    }
    for _,piece in ipairs(pieces) do
        if d <= piece[1] then
            local p, heading
            if typeof(piece[3]) == "Vector3" then p, heading = piece[2] + piece[3] * d, piece[3]
            else
                local angle = piece[3] + d / radius
                p = piece[2] + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                heading = Vector3.new(-math.sin(angle), 0, math.cos(angle))
            end
            if reverse then heading = -heading end
            p += Vector3.new(0, height or -142.974, 0)
            return CFrame.lookAt(p, p + heading)
        end
        d -= piece[1]
    end
end
return Routes
