local Clock=require(game.ServerScriptService.Brighthaven.TownClock)
local BREAK_CHANCE=30
local function setModelVisible(model, visible)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Transparency = visible and 0 or 1
			obj.CanCollide = visible
		end
	end
end

local function breakHouse(house)
	local variants = house:FindFirstChild("Variants")
	if not variants then
		return
	end

	local healthy = variants:FindFirstChild("Healthy")
	local broken = variants:FindFirstChild("Broken")

	if not healthy or not broken then
		return
	end

	setModelVisible(healthy, false)
	setModelVisible(broken, true)

	house:SetAttribute("Broken", true)

	print(house.Name .. " has broken.")
end

local function updateHouses()
	local housesFolder = workspace
		:WaitForChild("Possible Map Replacement")
		:WaitForChild("Houses")

	for _, house in ipairs(housesFolder:GetChildren()) do

		-- Create the attribute automatically if it doesn't exist
		if house:GetAttribute("Broken") == nil then
			house:SetAttribute("Broken", false)
		end

		-- Skip houses that are already broken
		if house:GetAttribute("Broken") then
			continue
		end

		-- 30% chance
		if math.random(1, 100) <= BREAK_CHANCE then
			breakHouse(house)
		else
			print(house.Name .. " survived the rain.")
		end
	end
end

local lastMorningDay=1
Clock.Changed:Connect(function(minutes,day)
    if minutes>=420 and minutes<1080 and day>lastMorningDay then
        lastMorningDay=day
        updateHouses()
    end
end)
Clock.Start()

