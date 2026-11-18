local ServerStorage = game:GetService("ServerStorage")
local transit = game.ServerScriptService:WaitForChild("BrighthavenTransit")
local Fleet = require(transit:WaitForChild("TransitFleet"))
local Routes = require(transit.TransitRoutes)
local carTemplate = ServerStorage:WaitForChild("Car")
local MAX_CARS, MIN_SPAWN_TIME, MAX_SPAWN_TIME = 2, 6, 10
local activeCars, tracked = 0, {}
local CAR_COLORS = {
    Color3.fromRGB(220, 60, 60), Color3.fromRGB(60, 120, 220),
    Color3.fromRGB(70, 170, 90), Color3.fromRGB(240, 190, 60),
    Color3.fromRGB(220, 120, 50), Color3.fromRGB(150, 80, 180),
    Color3.fromRGB(60, 180, 180), Color3.fromRGB(240, 240, 240),
    Color3.fromRGB(80, 80, 80), Color3.fromRGB(30, 30, 30),
}
repeat task.wait() until Fleet.Ready
local serial = 0
local function spawnCar()
    if activeCars >= MAX_CARS then return end
    serial += 1
    local route = "Roaming"
    local car = carTemplate:Clone()
    car.Name, car.Color = "Car", CAR_COLORS[math.random(1, #CAR_COLORS)]
    car:SetAttribute("Route", route)
    car:SetAttribute("CruiseSpeed", math.random(28,32))
    car:SetAttribute("TransitVehicle", true)
    car:SetAttribute("VehicleKind", "Car")
    car.Anchored, car.CanCollide, car.CanTouch = true, false, false
    tracked[car], activeCars = true, activeCars + 1
    car.Parent = workspace
    local ok=pcall(Fleet.Register,car)
    if not ok then car:Destroy() end
end
workspace.ChildRemoved:Connect(function(child)
    if not tracked[child] then return end
    tracked[child], activeCars = nil, activeCars - 1
    task.delay(math.random(MIN_SPAWN_TIME, MAX_SPAWN_TIME), spawnCar)
end)
for _ = 1, MAX_CARS do
    spawnCar()
    task.wait(math.random(MIN_SPAWN_TIME, MAX_SPAWN_TIME))
end
