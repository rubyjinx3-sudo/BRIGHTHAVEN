local spotsFolder = workspace:WaitForChild("QuestSpots") 
local spots = spotsFolder:GetChildren()

function checkQuest()
	local allCorrect = true
	for _, spot in pairs(spots) do
		-- Simple logic: Find parts touching the spot
		local parts = workspace:GetPartsInPart(spot)
		local count = 0
		for _, part in pairs(parts) do
			if part.Name == "Crate" then count += 1 end
		end

		if count ~= 5 then
			allCorrect = false
		end
	end

	if allCorrect then
		print("Quest Complete! All stacks have 5 crates!")
	end
end
