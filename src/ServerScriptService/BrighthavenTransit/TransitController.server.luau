local Fleet = require(script.Parent.TransitFleet)
local traffic = workspace:WaitForChild("BrighthavenTransit")
local function register(vehicle)
    if vehicle:IsA("Model") and vehicle:GetAttribute("TransitVehicle") then Fleet.Register(vehicle) end
end
for _,vehicle in ipairs(traffic:GetChildren()) do register(vehicle) end
traffic.ChildAdded:Connect(register)
Fleet.Ready = true
