local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Practice = require(ReplicatedStorage.Brighthaven.TutorialPractice)

local startTutorial1 = ReplicatedStorage:WaitForChild("StartTutorial1")
local showDialogue = ReplicatedStorage:WaitForChild("ShowDialogue")

local tutorialFolder = workspace
	:WaitForChild("Possible Map Replacement")
	:WaitForChild("Tutorial")
	:WaitForChild("Tutorial_1")

local portal1 = workspace:WaitForChild("Portal1")
local portalPrompt = portal1:FindFirstChildWhichIsA("ProximityPrompt", true)

local supplyBox = tutorialFolder:WaitForChild("SupplyBox")
local supplyPrompt = supplyBox:WaitForChild("ProximityPrompt")

local tutorialNPC = tutorialFolder:WaitForChild("TutorialNPC1")
local npcPrompt = tutorialNPC
	:WaitForChild("HumanoidRootPart")
	:WaitForChild("ProximityPrompt")

local totalSupplies = tutorialFolder:WaitForChild("TotalSupplies")
local remainingSupplies = tutorialFolder:WaitForChild("RemainingSupplies")

local counterLabel = supplyBox
	:WaitForChild("CounterPart")
	:WaitForChild("SurfaceGui")
	:WaitForChild("TextLabel")

local tent1Supplies = tutorialFolder
	:WaitForChild("Tent1")
	:WaitForChild("CurrentSupplies")

local tent2Supplies = tutorialFolder
	:WaitForChild("Tent2")
	:WaitForChild("CurrentSupplies")

local tent3Supplies = tutorialFolder
	:WaitForChild("Tent3")
	:WaitForChild("CurrentSupplies")


--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local NumberRules = require(ReplicatedStorage.Brighthaven:WaitForChild("TutorialNumberRules"))

local TORCH_DISTANCE = 12


--------------------------------------------------
-- STATE
--------------------------------------------------

local currentPlayer = nil
local tutorialCompleted = false
local isResetting = false

local guideToken = 0
local guideCleanup = nil

-- Tracks the number of supplies held by players
local playerHeldSupplies = {}


--------------------------------------------------
-- PORTAL CONTROL FUNCTIONS
--------------------------------------------------

local function closePortal()
	-- Disables interaction prompt if present
	if portalPrompt then
		portalPrompt.Enabled = false
	end

	-- Optional visual indicator (e.g., set portal collision or transparency)
	-- If portal1 is a BasePart:
	if portal1:IsA("BasePart") then
		portal1.CanCollide = true -- Keeps door shut or barrier up
	end
end

local function openPortal()
	-- Enables interaction prompt if present
	if portalPrompt then
		portalPrompt.Enabled = true
	end

	-- Optional visual indicator (e.g., disable collision to let player walk through)
	if portal1:IsA("BasePart") then
		portal1.CanCollide = false
	end

	print("Portal 1 is now OPEN!")
end


--------------------------------------------------
-- UPDATE SUPPLY COUNTER
--------------------------------------------------

local function updateCounterDisplay()
	counterLabel.Text = string.format(
		"%d / %d",
		remainingSupplies.Value,
		totalSupplies.Value
	)
end


--------------------------------------------------
-- GET WORLD POSITION
--------------------------------------------------

local function getWorldPosition(instance)
	local success, position = pcall(function()
		return instance:GetPivot().Position
	end)

	if success then
		return position
	end

	return nil
end


--------------------------------------------------
-- COLLECT ARROW TARGETS 1-4 IN ORDER
--------------------------------------------------

local function collectArrowTargets()
	local targets = {}

	for i = 1, 4 do
		local target = workspace:FindFirstChild("Arrow Target " .. i)
		if not target then
			for _, child in ipairs(workspace:GetChildren()) do
				if child:IsA("BasePart") then
					local num = string.match(child.Name, "Arrow Target%s*(%d+)")
					if num and tonumber(num) == i then
						target = child
						break
					end
				end
			end
		end

		if target and target:IsA("BasePart") then
			table.insert(targets, {
				instance = target,
				position = target.Position
			})
		else
			warn(string.format("[Tutorial1ServerController] Arrow Target %d not found!", i))
		end
	end

	return targets
end


--------------------------------------------------
-- CREATE TORCH ARROW
--------------------------------------------------

local function createArrow(targetInstance, playerAttachment)
	if not targetInstance then
		return nil, nil
	end

	local targetPart = nil
	if targetInstance:IsA("BasePart") then
		targetPart = targetInstance
	else
		targetPart = targetInstance:FindFirstChildWhichIsA("BasePart", true)
	end

	if not targetPart then
		return nil, nil
	end

	local targetAttachment = targetPart:FindFirstChild("TutorialArrowTarget")

	if not targetAttachment then
		targetAttachment = Instance.new("Attachment")
		targetAttachment.Name = "TutorialArrowTarget"
		targetAttachment.Position = Vector3.new(0, 1.5, 0)
		targetAttachment.Parent = targetPart
	end

	local beam = Instance.new("Beam")
	beam.Name = "TutorialTorchArrow"
	beam.Attachment0 = targetAttachment
	beam.Attachment1 = playerAttachment
	beam.Width0 = 3
	beam.Width1 = 3
	beam.FaceCamera = true
	beam.LightEmission = 1
	beam.Texture = "rbxassetid://10249261576"
	beam.TextureLength = 5
	beam.TextureSpeed = 1
	beam.Transparency = NumberSequence.new(0)
	beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100))
	beam.Parent = workspace

	return beam, nil
end


--------------------------------------------------
-- START TORCH GUIDE
--------------------------------------------------

local function startTorchGuide(player)
	guideToken += 1
	local token = guideToken

	if guideCleanup then
		guideCleanup()
		guideCleanup = nil
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if not root then
		return
	end

	local playerAttachment = Instance.new("Attachment")
	playerAttachment.Name = "TutorialTorchArrowOrigin"
	playerAttachment.Position = Vector3.new(0, 2, 0)
	playerAttachment.Parent = root

	local activeBeam = nil
	local activeTargetAttachment = nil
	local cleaned = false

	local function cleanup()
		if cleaned then return end
		cleaned = true

		if activeBeam then
			activeBeam:Destroy()
			activeBeam = nil
		end

		if activeTargetAttachment then
			activeTargetAttachment:Destroy()
			activeTargetAttachment = nil
		end

		if playerAttachment then
			playerAttachment:Destroy()
		end
	end

	guideCleanup = cleanup

	task.spawn(function()
		local path = collectArrowTargets()
		local targetIndex = 1
		local portalPosition = getWorldPosition(portal1) or portal1.Position

		local function pointTo(instance)
			if activeBeam then
				activeBeam:Destroy()
				activeBeam = nil
			end
			if activeTargetAttachment then
				activeTargetAttachment:Destroy()
				activeTargetAttachment = nil
			end
			activeBeam, activeTargetAttachment = createArrow(instance, playerAttachment)
		end

		if #path > 0 then
			pointTo(path[1].instance)
		else
			pointTo(portal1)
		end

		while token == guideToken and not cleaned do
            if Practice.PlayerStage(player)~=1 then break end
			task.wait(0.25)

			character = player.Character
			root = character and character:FindFirstChild("HumanoidRootPart")

			if not root then break end

			if targetIndex <= #path then
				local distance = (root.Position - path[targetIndex].position).Magnitude

				if distance <= TORCH_DISTANCE then
					targetIndex += 1

					if targetIndex <= #path then
						pointTo(path[targetIndex].instance)
					else
						pointTo(portal1)
					end
				end
			else
				local portalDistance = (root.Position - portalPosition).Magnitude
				if portalDistance <= TORCH_DISTANCE then
					break
				end
			end
		end

		cleanup()

		if guideCleanup == cleanup then
			guideCleanup = nil
		end
	end)
end


--------------------------------------------------
-- RESET ALL SUPPLIES (ON FAIL)
--------------------------------------------------

local function resetSupplies()
	isResetting = true

	-- Keep Portal closed on failure
	closePortal()

	-- Resets total available supply pool
	remainingSupplies.Value = totalSupplies.Value

	-- Resets each tent supply count to zero
	tent1Supplies.Value = 0
	tent2Supplies.Value = 0
	tent3Supplies.Value = 0

	-- Clears held supplies state & destroys carried box tools
	for player, _ in pairs(playerHeldSupplies) do
		playerHeldSupplies[player] = 0

		if player and player.Parent then
			local bpBox = player.Backpack:FindFirstChild("SupplyBox")
			if bpBox then bpBox:Destroy() end

			if player.Character then
				local charBox = player.Character:FindFirstChild("SupplyBox")
				if charBox then charBox:Destroy() end
			end
		end
	end

	updateCounterDisplay()

	task.wait(0.1)
	isResetting = false
end


--------------------------------------------------
-- CHECK TUTORIAL COMPLETION
--------------------------------------------------

local function checkTutorialComplete()
	if not currentPlayer or not tutorialFolder:GetAttribute("PracticeActive") or tutorialCompleted or isResetting then
		return
	end

	--------------------------------------------------
	-- VERIFY ALL SUPPLIES ARE DELIVERED
	--------------------------------------------------

	local totalDelivered = tent1Supplies.Value + tent2Supplies.Value + tent3Supplies.Value

	if remainingSupplies.Value > 0 or totalDelivered < totalSupplies.Value then
		return
	end

	--------------------------------------------------
	-- WAIT FOR ALL VALUES TO FINISH UPDATING
	--------------------------------------------------

	task.defer(function()
		if tutorialCompleted or isResetting then
			return
		end

		local currentDelivered = tent1Supplies.Value + tent2Supplies.Value + tent3Supplies.Value

		if remainingSupplies.Value > 0 or currentDelivered < totalSupplies.Value then
			return
		end

		--------------------------------------------------
		-- VERIFY EQUAL DISTRIBUTION
		--------------------------------------------------

		if tent1Supplies.Value ~= tent2Supplies.Value
			or tent2Supplies.Value ~= tent3Supplies.Value
		then
			-- Portal remains closed on error
			closePortal()

			-- Show error message to player
			showDialogue:FireClient(
				currentPlayer,
				"The groups were different. Try giving the same amount to every shelter.",
				"tutorial1_failed",
				"Supply Helper",
				"SCR"
			)

			-- Reset supply values back to 0
			resetSupplies()
			return
		end


		--------------------------------------------------
		-- SUCCESS: MARK COMPLETE & OPEN PORTAL
		--------------------------------------------------

		tutorialCompleted = true
		tutorialFolder:SetAttribute("PracticeActive",false)
		currentPlayer:SetAttribute("Tutorial1Practice","complete")

		-- Disable supply box & NPC interactions
		supplyPrompt.Enabled = false
		npcPrompt.Enabled = false

		updateCounterDisplay()

		-- Show success completion dialogue
		showDialogue:FireClient(
			currentPlayer,
			--"Excellent work! The counter is 0 / "--
			"Fair sharing! Follow the yellow guide to the Counting Helper.",
			"tutorial1_complete",
			"Supply Helper",
			"SCR"
		)

		-- OPEN THE PORTAL NOW
		openPortal()

		-- Start guiding beam to torches and portal
		task.delay(0.5, function()
			if currentPlayer and currentPlayer.Parent then
				startTorchGuide(currentPlayer)
			end
		end)

	end)
end


--------------------------------------------------
-- START TUTORIAL 1
--------------------------------------------------

startTutorial1.OnServerEvent:Connect(function(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position-tutorialNPC.HumanoidRootPart.Position).Magnitude>18 then return end
	if player:GetAttribute("Tutorial1Practice")=="complete" then
		showDialogue:FireClient(player,"Fair sharing! Follow the guide to the Counting Helper.","tutorial1_complete","Supply Helper")
		return
	end
	if tutorialCompleted or tutorialFolder:GetAttribute("PracticeActive") then return end
	currentPlayer = player
	tutorialCompleted = false
	guideToken += 1

	-- Ensure Portal 1 starts closed when tutorial begins
	closePortal()

	if guideCleanup then
		guideCleanup()
		guideCleanup = nil
	end

	-- Keep the problem the helper showed, so the briefing matches the challenge.
	local total = totalSupplies.Value

	totalSupplies.Value = total
	remainingSupplies.Value = total
	tent1Supplies.Value = 0
	tent2Supplies.Value = 0
	tent3Supplies.Value = 0
	playerHeldSupplies = {}
	tutorialFolder:SetAttribute("PracticeOwner",player.UserId)
	tutorialFolder:SetAttribute("PracticeActive",true)
	player:SetAttribute("Tutorial1Practice","active")

	updateCounterDisplay()

	supplyBox.CounterPart.SurfaceGui.Enabled = true
	supplyPrompt.Enabled = true
	npcPrompt.Enabled = false
end)


--------------------------------------------------
-- SUPPLY CHANGES
--------------------------------------------------

remainingSupplies.Changed:Connect(function()
	updateCounterDisplay()
	checkTutorialComplete()
end)

tent1Supplies.Changed:Connect(checkTutorialComplete)
tent2Supplies.Changed:Connect(checkTutorialComplete)
tent3Supplies.Changed:Connect(checkTutorialComplete)


--------------------------------------------------
-- INITIAL STATE
--------------------------------------------------

closePortal() -- Closed by default on game load
tutorialFolder:SetAttribute("PracticeActive",false)
totalSupplies.Value = NumberRules.ChooseTotal()
remainingSupplies.Value = totalSupplies.Value
updateCounterDisplay()
supplyPrompt.Enabled = false
npcPrompt.Enabled = true

local function returnCarriedSupplies(player)
	if player~=currentPlayer then return end
	local returned=0
	local containers={}
	if player.Character then table.insert(containers,player.Character) end
	local backpack=player:FindFirstChildOfClass("Backpack")
	if backpack then table.insert(containers,backpack) end
	for _,container in ipairs(containers) do
		if container then
			for _,tool in ipairs(container:GetChildren()) do
				if tool:IsA("Tool") and tool.Name=="SupplyBox" then
					returned+=math.max(0,tonumber(tool:GetAttribute("Amount")) or 0)
					tool:Destroy()
				end
			end
		end
	end
	local delivered=tent1Supplies.Value+tent2Supplies.Value+tent3Supplies.Value
	remainingSupplies.Value=math.min(totalSupplies.Value-delivered,remainingSupplies.Value+returned)
end

local function release(player)
	if currentPlayer~=player then return end
	returnCarriedSupplies(player)
	guideToken+=1
	if guideCleanup then guideCleanup();guideCleanup=nil end
	currentPlayer=nil
	tutorialCompleted=false
	tutorialFolder:SetAttribute("PracticeActive",false)
	tutorialFolder:SetAttribute("PracticeOwner",nil)
	totalSupplies.Value=NumberRules.ChooseTotal(totalSupplies.Value)
	remainingSupplies.Value=totalSupplies.Value
	tent1Supplies.Value,tent2Supplies.Value,tent3Supplies.Value=0,0,0
	closePortal()
	supplyPrompt.Enabled=false
	npcPrompt.Enabled=true
	updateCounterDisplay()
end

local function bind(player)
	local function characterAdded(character)
		local humanoid=character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function() returnCarriedSupplies(player) end)
	end
	player.CharacterAdded:Connect(characterAdded)
	player.CharacterRemoving:Connect(function() returnCarriedSupplies(player) end)
	if player.Character then task.spawn(characterAdded,player.Character) end
end
Players.PlayerAdded:Connect(bind)
Players.PlayerRemoving:Connect(release)
for _,player in ipairs(Players:GetPlayers()) do bind(player) end
task.spawn(function()
	while true do
		task.wait(1)
		local character=currentPlayer and currentPlayer.Character
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health>0 and character:FindFirstChild("HumanoidRootPart") and Practice.PlayerStage(currentPlayer)~=1 then release(currentPlayer) end
	end
end)


-- Community hub: start a fresh optional round without changing campaign progress.
game.ServerScriptService:WaitForChild('BarangayPracticeReset').Event:Connect(function(player,index)
 if index~=1 or currentPlayer and currentPlayer~=player and tutorialFolder:GetAttribute('PracticeActive') then return end
 if currentPlayer==player then release(player) end
 currentPlayer=nil;tutorialCompleted=false;tutorialFolder:SetAttribute('PracticeActive',false);tutorialFolder:SetAttribute('PracticeOwner',nil)
 player:SetAttribute('Tutorial1Practice',nil);resetSupplies();npcPrompt.Enabled=true;supplyPrompt.Enabled=false
end)
