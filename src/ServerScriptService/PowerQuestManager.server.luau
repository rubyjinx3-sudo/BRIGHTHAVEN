local ReplicatedStorage = game:GetService("ReplicatedStorage")

local startPowerQuest = ReplicatedStorage:WaitForChild("StartPowerQuest")

local powerStation = workspace:WaitForChild("Possible Map Replacement"):WaitForChild("PowerStation")

local requiredVoltage = workspace.PowerData.RequiredVoltage
local currentVoltage = workspace.PowerData.CurrentVoltage

local voltageLabel = powerStation
	:WaitForChild("FuseBox")
	:WaitForChild("FuseBox Screen")
	:WaitForChild("SurfaceGui")
	:WaitForChild("TextLabel")

local questActive = false

startPowerQuest.OnServerEvent:Connect(function(player)

	if questActive then
		print("Power quest already active")
		return
	end

	questActive = true

	requiredVoltage.Value = math.random(8,20) * 5
	currentVoltage.Value = 0

	print(player.Name .. " started the Power Station quest!")
	print("Required Voltage:", requiredVoltage.Value .. "V")

	voltageLabel.Text =
		"Power: "
		.. currentVoltage.Value
		.. "V / "
		.. requiredVoltage.Value
		.. "V"

end)