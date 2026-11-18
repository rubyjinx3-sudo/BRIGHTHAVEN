local ReplicatedStorage = game:GetService("ReplicatedStorage")

local startForkliftQuest = ReplicatedStorage:WaitForChild("StartForkliftQuest")

startForkliftQuest.OnServerEvent:Connect(function(player)

	-- Static cargo assigned when the quest begins
	local cargoAmount = 144

	player:SetAttribute("ForkliftCargo", cargoAmount)
	player:SetAttribute("ForkliftQuestActive", true)

	print(player.Name .. " started the forklift quest!")
	print("Assigned cargo:", cargoAmount)

end)