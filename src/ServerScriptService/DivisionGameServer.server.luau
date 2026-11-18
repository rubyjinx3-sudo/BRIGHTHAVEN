
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.DivisionGame.Config)
local MissionData = require(ReplicatedStorage.DivisionGame.MissionData)
local Remotes = ReplicatedStorage.DivisionGame.Remotes


local playerData = {}

local function createPlayerData(player)
	return {

		tutorial = {
			examplesCompleted = 0,
			practiceCompleted = 0,
			practiceCorrect = 0,
			totalPracticeSteps = 0,
			currentTask = nil,
			hintsUsed = 0,
			masteryPercent = 0,
			unlocked = true,
			completed = false,
		},

		chunking = {
			equalSharingCorrect = 0,
			equalSharingTotal = 0,
			factorMultipleCorrect = 0,
			factorMultipleTotal = 0,
			chunkingTasksCompleted = 0,
			chunkingTasksCorrect = 0,
			remainderCorrect = 0,
			remainderTotal = 0,
			currentMission = nil,
			currentChunks = {},
			runningQuotient = 0,
			runningRemainder = 0,
			hintsUsed = 0,
			masteryPercent = 0,
			unlocked = false,
			completed = false,
		},

		budgeting = {
			missionsCompleted = 0,
			missionsCorrect = 0,
			leftoverCorrect = 0,
			leftoverTotal = 0,
			currentMission = nil,
			currentChunks = {},
			runningQuotient = 0,
			runningRemainder = 0,
			hintsUsed = 0,
			masteryPercent = 0,
			unlocked = false,
			completed = false,

			boostAttempts = {},
			boostWins = 0,
			boostLosses = 0,
			boostBudgetImpact = 0,
		},

		evaluation = {
			integratedCorrect = 0,
			integratedTotal = 0,
			multVerificationCorrect = 0,
			multVerificationTotal = 0,
			currentMission = nil,
			currentChunks = {},
			runningQuotient = 0,
			runningRemainder = 0,
			hintsUsed = 0,
			masteryPercent = 0,
			unlocked = false,
			completed = false,
		},

		analytics = {
			totalTasksCompleted = 0,
			totalCorrect = 0,
			totalHintsUsed = 0,
			completionTimes = {},
			taskStartTime = 0,
			chunkingQualityScores = {},
		},

		currentModule = 1,
		currentPanel = nil,
	}
end

local function getPlayerData(player)
	if not playerData[player.UserId] then
		playerData[player.UserId] = createPlayerData(player)
	end
	return playerData[player.UserId]
end


local function sendFeedback(player, feedbackType, message)
	local remote = Remotes:FindFirstChild("FeedbackToClient")
	if remote then
		remote:FireClient(player, {type = feedbackType, message = message})
	end
end





local function startTutorial(player)
	local data = getPlayerData(player)
	data.currentPanel = "tutorial"
	data.analytics.taskStartTime = tick()

	if data.tutorial.examplesCompleted < 3 then
		local example = MissionData.TutorialExamples[data.tutorial.examplesCompleted + 1]
		data.tutorial.currentTask = example
		data.tutorial.hintsUsed = 0

		Remotes.StartTutorial:FireClient(player, {
			mode = "example",
			step = data.tutorial.examplesCompleted + 1,
			totalSteps = 3,
			story = example.story,
			dividend = example.dividend,
			divisor = example.divisor,
			expectedQuotient = example.expectedQuotient,
			expectedRemainder = example.expectedRemainder,
		})
	else
		local practiceIndex = data.tutorial.practiceCompleted + 1
		if practiceIndex <= #MissionData.TutorialPractice then
			local task = MissionData.TutorialPractice[practiceIndex]
			data.tutorial.currentTask = task
			data.tutorial.hintsUsed = 0

			Remotes.StartTutorial:FireClient(player, {
				mode = "practice",
				step = practiceIndex,
				totalSteps = #MissionData.TutorialPractice,
				story = string.format("Share %d items equally among %d groups.", task.dividend, task.divisor),
				dividend = task.dividend,
				divisor = task.divisor,
				expectedQuotient = task.dividend / task.divisor,
				expectedRemainder = 0,
			})
		end
	end
end

Remotes.StartTutorial.OnServerEvent:Connect(function(player)
	startTutorial(player)
end)

Remotes.SubmitTutorialAnswer.OnServerEvent:Connect(function(player, answer)
	local data = getPlayerData(player)
	local task = data.tutorial.currentTask
	if not task then return end

	local expectedQ = task.expectedQuotient or (task.dividend / task.divisor)
	local expectedR = task.expectedRemainder or 0
	local userQ = tonumber(answer.quotient)
	local userR = tonumber(answer.remainder) or 0

	local correct = (userQ == expectedQ and userR == expectedR)
	local completionTime = tick() - data.analytics.taskStartTime

	if data.tutorial.examplesCompleted < 3 then

		if correct then
			data.tutorial.examplesCompleted = data.tutorial.examplesCompleted + 1
			sendFeedback(player, "success", "Correct! " .. expectedQ .. " each with " .. expectedR .. " left over.")
		else
			sendFeedback(player, "error", "Not quite. The answer is " .. expectedQ .. " each with " .. expectedR .. " left over. Let's try the next one!")
			data.tutorial.examplesCompleted = data.tutorial.examplesCompleted + 1
		end
	else

		data.tutorial.totalPracticeSteps = data.tutorial.totalPracticeSteps + 1
		if correct then
			data.tutorial.practiceCorrect = data.tutorial.practiceCorrect + 1
			sendFeedback(player, "success", "Correct! " .. expectedQ .. " per group.")
		else
			sendFeedback(player, "error", "Not quite. " .. task.dividend .. " / " .. task.divisor .. " = " .. expectedQ .. " r " .. expectedR .. ".")
		end
		data.tutorial.practiceCompleted = data.tutorial.practiceCompleted + 1
		table.insert(data.analytics.completionTimes, completionTime)
	end

	data.analytics.totalTasksCompleted = data.analytics.totalTasksCompleted + 1
	if correct then data.analytics.totalCorrect = data.analytics.totalCorrect + 1 end


	if data.tutorial.practiceCompleted >= Config.Tutorial.GuidedPracticeRequired then
		data.tutorial.masteryPercent = math.floor((data.tutorial.practiceCorrect / data.tutorial.totalPracticeSteps) * 100)
		if data.tutorial.masteryPercent >= Config.Tutorial.MasteryGatePercent then
			data.tutorial.completed = true
			data.chunking.unlocked = true
			sendFeedback(player, "success", "Tutorial complete! Mastery: " .. data.tutorial.masteryPercent .. "%. Chunking module unlocked!")
		else
			sendFeedback(player, "warning", "Mastery: " .. data.tutorial.masteryPercent .. "%. Need " .. Config.Tutorial.MasteryGatePercent .. "% to unlock next module. Keep practicing!")
		end
	end

	Remotes.TutorialStateUpdate:FireClient(player, data.tutorial)
end)


local function startChunkingMission(player)
	local data = getPlayerData(player)
	if not data.chunking.unlocked then
		sendFeedback(player, "error", "Complete the Tutorial first!")
		return
	end
	data.currentPanel = "chunking"
	data.analytics.taskStartTime = tick()


	local missionIndex = data.chunking.equalSharingTotal + 1
	if missionIndex <= #MissionData.ChunkingMissions then
		local mission = MissionData.ChunkingMissions[missionIndex]
		data.chunking.currentMission = mission
		data.chunking.currentChunks = {}
		data.chunking.runningQuotient = 0
		data.chunking.runningRemainder = mission.dividend
		data.chunking.hintsUsed = 0

		Remotes.StartChunkingMission:FireClient(player, {
			story = mission.story,
			dividend = mission.dividend,
			divisor = mission.divisor,
			quotient = 0,
			remaining = mission.dividend,
			chunks = {},
		})
	else
		sendFeedback(player, "info", "All chunking missions completed! Try remainder tasks.")
	end
end

Remotes.StartChunkingMission.OnServerEvent:Connect(function(player)
	startChunkingMission(player)
end)

Remotes.SubmitChunkStep.OnServerEvent:Connect(function(player, chunkData)
	local data = getPlayerData(player)
	local mission = data.chunking.currentMission
	if not mission then return end

	local chunkMultiple = tonumber(chunkData.multiple)
	local chunkQuotient = tonumber(chunkData.chunkQuotient)
	local chunkSubtract = chunkQuotient * mission.divisor


	if chunkSubtract > data.chunking.runningRemainder then
		sendFeedback(player, "error", "Invalid chunk! " .. chunkSubtract .. " is more than the remaining " .. data.chunking.runningRemainder .. ".")
		return
	end

	if chunkSubtract <= 0 then
		sendFeedback(player, "error", "Invalid chunk! Must subtract more than 0.")
		return
	end


	data.chunking.runningQuotient = data.chunking.runningQuotient + chunkQuotient
	data.chunking.runningRemainder = data.chunking.runningRemainder - chunkSubtract
	table.insert(data.chunking.currentChunks, {
		multiple = chunkMultiple,
		chunkQuotient = chunkQuotient,
		subtracted = chunkSubtract,
	})

	sendFeedback(player, "info", "Chunk applied: " .. chunkMultiple .. " x " .. mission.divisor .. " = " .. chunkSubtract .. ". Remaining: " .. data.chunking.runningRemainder)

	Remotes.StartChunkingMission:FireClient(player, {
		story = mission.story,
		dividend = mission.dividend,
		divisor = mission.divisor,
		quotient = data.chunking.runningQuotient,
		remaining = data.chunking.runningRemainder,
		chunks = data.chunking.currentChunks,
	})
end)

Remotes.SubmitQuotientRemainder.OnServerEvent:Connect(function(player, answer)
	local data = getPlayerData(player)
	local mission = data.chunking.currentMission
	if not mission then return end

	local expectedQ = math.floor(mission.dividend / mission.divisor)
	local expectedR = mission.dividend % mission.divisor
	local userQ = tonumber(answer.quotient)
	local userR = tonumber(answer.remainder) or 0
	local correct = (userQ == expectedQ and userR == expectedR)
	local completionTime = tick() - data.analytics.taskStartTime


	if not correct then
		if userQ ~= expectedQ and userR == expectedR then
			sendFeedback(player, "error", "Quotient is wrong. Check your chunking steps!")
		elseif userQ == expectedQ and userR ~= expectedR then
			sendFeedback(player, "error", "Remainder is wrong. It should be less than the divisor (" .. mission.divisor .. ").")
		elseif userR >= mission.divisor then
			sendFeedback(player, "error", "Remainder must be less than the divisor! " .. userR .. " >= " .. mission.divisor)
		else
			sendFeedback(player, "error", "Not correct. " .. mission.dividend .. " / " .. mission.divisor .. " = " .. expectedQ .. " r " .. expectedR)
		end
	else
		sendFeedback(player, "success", "Correct! " .. mission.dividend .. " / " .. mission.divisor .. " = " .. expectedQ .. " r " .. expectedR)


		local optimalChunks = 1
		local qualityScore = math.max(0, 100 - (#data.chunking.currentChunks - optimalChunks) * 15)
		table.insert(data.analytics.chunkingQualityScores, qualityScore)
	end

	data.chunking.equalSharingTotal = data.chunking.equalSharingTotal + 1
	if correct then
		data.chunking.equalSharingCorrect = data.chunking.equalSharingCorrect + 1
		data.chunking.chunkingTasksCorrect = data.chunking.chunkingTasksCorrect + 1
	end
	data.chunking.chunkingTasksCompleted = data.chunking.chunkingTasksCompleted + 1
	data.chunking.remainderTotal = data.chunking.remainderTotal + 1
	if correct then data.chunking.remainderCorrect = data.chunking.remainderCorrect + 1 end

	data.analytics.totalTasksCompleted = data.analytics.totalTasksCompleted + 1
	if correct then data.analytics.totalCorrect = data.analytics.totalCorrect + 1 end
	table.insert(data.analytics.completionTimes, completionTime)


	if data.chunking.chunkingTasksCompleted >= 10 then
		local accuracy = math.floor((data.chunking.chunkingTasksCorrect / data.chunking.chunkingTasksCompleted) * 100)
		data.chunking.masteryPercent = accuracy
		if accuracy >= Config.Chunking.MasteryGatePercent then
			data.chunking.completed = true
			data.budgeting.unlocked = true
			sendFeedback(player, "success", "Chunking module complete! Accuracy: " .. accuracy .. "%. Budgeting unlocked!")
		end
	end

	Remotes.ChunkingStateUpdate:FireClient(player, data.chunking)
end)


Remotes.SubmitFactorMultiple.OnServerEvent:Connect(function(player, selectedFactors)
	local data = getPlayerData(player)
	local taskIndex = data.chunking.factorMultipleTotal + 1
	if taskIndex > #MissionData.FactorMultipleTasks then
		sendFeedback(player, "info", "All factor tasks completed!")
		return
	end

	local task = MissionData.FactorMultipleTasks[taskIndex]
	local correctCount = 0
	local totalOptions = #task.options

	for _, opt in task.options do
		local isSelected = table.find(selectedFactors, opt) ~= nil
		local isCorrect = table.find(task.correctFactors, opt) ~= nil
		if isSelected == isCorrect then
			correctCount = correctCount + 1
		end
	end

	local accuracy = correctCount / totalOptions
	data.chunking.factorMultipleTotal = data.chunking.factorMultipleTotal + 1
	if accuracy >= 0.8 then
		data.chunking.factorMultipleCorrect = data.chunking.factorMultipleCorrect + 1
		sendFeedback(player, "success", "Great job identifying factors of " .. task.number .. "!")
	else
		sendFeedback(player, "error", "Some factors were missed or incorrect for " .. task.number .. ". The factors are: " .. table.concat(task.correctFactors, ", "))
	end

	Remotes.FactorMultipleStateUpdate:FireClient(player, data.chunking)
end)


local function startBudgetMission(player)
	local data = getPlayerData(player)
	if not data.budgeting.unlocked then
		sendFeedback(player, "error", "Complete the Chunking module first!")
		return
	end
	data.currentPanel = "budgeting"
	data.analytics.taskStartTime = tick()

	local missionIndex = data.budgeting.missionsCompleted + 1
	if missionIndex > #MissionData.BudgetMissions then
		sendFeedback(player, "info", "All budget missions completed!")
		return
	end

	local mission = MissionData.BudgetMissions[missionIndex]
	data.budgeting.currentMission = mission
	data.budgeting.currentChunks = {}
	data.budgeting.runningQuotient = 0
	data.budgeting.runningRemainder = mission.totalBudget
	data.budgeting.hintsUsed = 0

	Remotes.StartBudgetMission:FireClient(player, {
		story = mission.story,
		totalBudget = mission.totalBudget,
		groups = mission.groups,
		perGroup = 0,
		leftover = mission.totalBudget,
		chunks = {},
		leftoverOptions = mission.leftoverOptions,
	})
end

Remotes.StartBudgetMission.OnServerEvent:Connect(function(player)
	startBudgetMission(player)
end)

Remotes.SubmitBudgetAllocation.OnServerEvent:Connect(function(player, allocData)
	local data = getPlayerData(player)
	local mission = data.budgeting.currentMission
	if not mission then return end

	local chunkAmount = tonumber(allocData.chunkAmount)
	if not chunkAmount or chunkAmount <= 0 then
		sendFeedback(player, "error", "Enter a valid chunk amount.")
		return
	end

	if chunkAmount > data.budgeting.runningRemainder then
		sendFeedback(player, "error", "Chunk of $" .. chunkAmount .. " exceeds remaining $" .. data.budgeting.runningRemainder .. "!")
		return
	end


	local chunkQuotient = chunkAmount / mission.groups
	if chunkAmount % mission.groups ~= 0 then
		sendFeedback(player, "error", "Chunk must be divisible by " .. mission.groups .. " groups. Try $" .. (mission.groups * math.floor(chunkAmount / mission.groups)))
		return
	end

	chunkQuotient = math.floor(chunkAmount / mission.groups)
	data.budgeting.runningQuotient = data.budgeting.runningQuotient + chunkQuotient
	data.budgeting.runningRemainder = data.budgeting.runningRemainder - chunkAmount
	table.insert(data.budgeting.currentChunks, {amount = chunkAmount, perGroup = chunkQuotient})

	sendFeedback(player, "info", "Allocated $" .. chunkAmount .. " ($" .. chunkQuotient .. " per group). Remaining: $" .. data.budgeting.runningRemainder)

	Remotes.StartBudgetMission:FireClient(player, {
		story = mission.story,
		totalBudget = mission.totalBudget,
		groups = mission.groups,
		perGroup = data.budgeting.runningQuotient,
		leftover = data.budgeting.runningRemainder,
		chunks = data.budgeting.currentChunks,
		leftoverOptions = mission.leftoverOptions,
	})
end)

Remotes.SubmitLeftoverDecision.OnServerEvent:Connect(function(player, decision)
	local data = getPlayerData(player)
	local mission = data.budgeting.currentMission
	if not mission then return end

	local expectedPerGroup = math.floor(mission.totalBudget / mission.groups)
	local expectedLeftover = mission.totalBudget % mission.groups
	local correctAllocation = (data.budgeting.runningQuotient == expectedPerGroup)


	local leftoverCorrect = false
	if expectedLeftover == 0 then
		leftoverCorrect = true
	elseif decision == "reserve" or decision == "carryover" or decision == "redistribute" then
		leftoverCorrect = true
	end

	local overallCorrect = correctAllocation and leftoverCorrect
	local completionTime = tick() - data.analytics.taskStartTime

	data.budgeting.missionsCompleted = data.budgeting.missionsCompleted + 1
	if correctAllocation then data.budgeting.missionsCorrect = data.budgeting.missionsCorrect + 1 end
	data.budgeting.leftoverTotal = data.budgeting.leftoverTotal + 1
	if leftoverCorrect then data.budgeting.leftoverCorrect = data.budgeting.leftoverCorrect + 1 end

	if overallCorrect then
		sendFeedback(player, "success", "Budget correct! $" .. expectedPerGroup .. " per group, $" .. expectedLeftover .. " leftover (" .. decision .. ").")
	else
		sendFeedback(player, "error", "Budget incorrect. Expected $" .. expectedPerGroup .. " per group with $" .. expectedLeftover .. " leftover.")
	end

	data.analytics.totalTasksCompleted = data.analytics.totalTasksCompleted + 1
	if overallCorrect then data.analytics.totalCorrect = data.analytics.totalCorrect + 1 end
	table.insert(data.analytics.completionTimes, completionTime)


	if data.budgeting.missionsCompleted >= Config.Budgeting.MoneyMissionsRequired then
		local acc = math.floor((data.budgeting.missionsCorrect / data.budgeting.missionsCompleted) * 100)
		local leftoverAcc = math.floor((data.budgeting.leftoverCorrect / data.budgeting.leftoverTotal) * 100)
		data.budgeting.masteryPercent = math.floor((acc + leftoverAcc) / 2)
		if acc >= Config.Budgeting.BudgetingAccuracyGate and leftoverAcc >= Config.Budgeting.LeftoverFundAccuracyGate then
			data.budgeting.completed = true
			data.evaluation.unlocked = true
			sendFeedback(player, "success", "Budgeting complete! Evaluation module unlocked!")
		end
	end

	Remotes.BudgetStateUpdate:FireClient(player, data.budgeting)
end)


Remotes.RequestBoost.OnServerEvent:Connect(function(player)
	local data = getPlayerData(player)
	if not data.budgeting.unlocked then
		sendFeedback(player, "error", "Complete Chunking module first!")
		return
	end


	local dayInfo = Remotes.GetDayInfo:Invoke(player)
	local currentDay = dayInfo and dayInfo.currentDay or 1
	if data.budgeting.boostAttempts[currentDay] then
		sendFeedback(player, "error", "Boost already used today! Wait for the next day.")
		Remotes.BoostStateUpdate:FireClient(player, {
			cooldown = true,
			secondsUntilNextDay = dayInfo and dayInfo.secondsRemaining or 360,
		})
		return
	end


	local challenge = MissionData.BoostChallenges[math.random(1, #MissionData.BoostChallenges)]
	data.budgeting.boostAttempts[currentDay] = challenge.id
	data.currentPanel = "boost"
	data.analytics.taskStartTime = tick()

	Remotes.BoostStateUpdate:FireClient(player, {
		challenge = challenge,
		cooldown = false,
	})
end)

Remotes.SubmitBoostAnswer.OnServerEvent:Connect(function(player, answer)
	local data = getPlayerData(player)
	local dayInfo = Remotes.GetDayInfo:Invoke(player)
	local currentDay = dayInfo and dayInfo.currentDay or 1
	local challengeId = data.budgeting.boostAttempts[currentDay]
	if not challengeId then return end


	local challenge = nil
	for _, c in MissionData.BoostChallenges do
		if c.id == challengeId then challenge = c break end
	end
	if not challenge then return end

	local expected = math.floor(challenge.dividend / challenge.divisor)
	local userAnswer = tonumber(answer.quotient)
	local correct = (userAnswer == expected)
	local completionTime = tick() - data.analytics.taskStartTime

	if correct then
		data.budgeting.boostWins = data.budgeting.boostWins + 1
		data.budgeting.boostBudgetImpact = data.budgeting.boostBudgetImpact + challenge.bonusReward
		sendFeedback(player, "success", "Boost correct! Earned $" .. challenge.bonusReward .. " bonus!")
	else
		data.budgeting.boostLosses = data.budgeting.boostLosses + 1
		sendFeedback(player, "error", "Boost failed. The answer was " .. expected .. ".")
	end

	data.analytics.totalTasksCompleted = data.analytics.totalTasksCompleted + 1
	if correct then data.analytics.totalCorrect = data.analytics.totalCorrect + 1 end
	table.insert(data.analytics.completionTimes, completionTime)

	Remotes.BoostStateUpdate:FireClient(player, {
		result = correct,
		reward = correct and challenge.bonusReward or 0,
		cooldown = true,
		secondsUntilNextDay = dayInfo and dayInfo.secondsRemaining or 360,
	})
end)


local function startIntegratedMission(player)
	local data = getPlayerData(player)
	if not data.evaluation.unlocked then
		sendFeedback(player, "error", "Complete Budgeting module first!")
		return
	end
	data.currentPanel = "evaluation"
	data.analytics.taskStartTime = tick()

	local missionIndex = data.evaluation.integratedTotal + 1
	if missionIndex > #MissionData.IntegratedMissions then
		sendFeedback(player, "info", "All integrated missions completed!")
		return
	end

	local mission = MissionData.IntegratedMissions[missionIndex]
	data.evaluation.currentMission = mission
	data.evaluation.currentChunks = {}
	data.evaluation.runningQuotient = 0
	data.evaluation.runningRemainder = mission.dividend
	data.evaluation.hintsUsed = 0

	Remotes.StartIntegratedMission:FireClient(player, {
		story = mission.story,
		type = mission.type,
		dividend = mission.dividend,
		divisor = mission.divisor,
		requiresBudgeting = mission.requiresBudgeting or false,
		leftoverDecision = mission.leftoverDecision or false,
		quotient = 0,
		remaining = mission.dividend,
		chunks = {},
	})
end

Remotes.StartIntegratedMission.OnServerEvent:Connect(function(player)
	startIntegratedMission(player)
end)

Remotes.SubmitIntegratedAnswer.OnServerEvent:Connect(function(player, answer)
	local data = getPlayerData(player)
	local mission = data.evaluation.currentMission
	if not mission then return end

	local expectedQ = math.floor(mission.dividend / mission.divisor)
	local expectedR = mission.dividend % mission.divisor
	local userQ = tonumber(answer.quotient)
	local userR = tonumber(answer.remainder) or 0
	local correct = (userQ == expectedQ and userR == expectedR)
	local completionTime = tick() - data.analytics.taskStartTime


	local multVerified = false
	if answer.verifiedMultiplication then
		local multResult = userQ * mission.divisor + userR
		multVerified = (multResult == mission.dividend)
		data.evaluation.multVerificationTotal = data.evaluation.multVerificationTotal + 1
		if multVerified then
			data.evaluation.multVerificationCorrect = data.evaluation.multVerificationCorrect + 1
		end
	end

	data.evaluation.integratedTotal = data.evaluation.integratedTotal + 1
	if correct then
		data.evaluation.integratedCorrect = data.evaluation.integratedCorrect + 1
		sendFeedback(player, "success", "Correct! " .. mission.dividend .. " / " .. mission.divisor .. " = " .. expectedQ .. " r " .. expectedR)
	else
		sendFeedback(player, "error", "Not correct. Expected " .. expectedQ .. " r " .. expectedR)
	end

	data.analytics.totalTasksCompleted = data.analytics.totalTasksCompleted + 1
	if correct then data.analytics.totalCorrect = data.analytics.totalCorrect + 1 end
	table.insert(data.analytics.completionTimes, completionTime)


	if data.evaluation.integratedTotal >= 5 then
		local acc = math.floor((data.evaluation.integratedCorrect / data.evaluation.integratedTotal) * 100)
		local multAcc = data.evaluation.multVerificationTotal > 0
			and math.floor((data.evaluation.multVerificationCorrect / data.evaluation.multVerificationTotal) * 100)
			or 0
		data.evaluation.masteryPercent = acc

		if acc >= Config.Evaluation.IntegratedMissionsAccuracyGate
			and multAcc >= Config.Evaluation.MultiplicationVerificationGate then
			data.evaluation.completed = true
			sendFeedback(player, "success", "All modules complete! Final accuracy: " .. acc .. "%, Mult verification: " .. multAcc .. "%")
		end
	end

	Remotes.EvaluationStateUpdate:FireClient(player, data.evaluation)
end)


Remotes.RequestHint.OnServerEvent:Connect(function(player)
	local data = getPlayerData(player)
	local moduleData = data.currentPanel == "tutorial" and data.tutorial
		or data.currentPanel == "chunking" and data.chunking
		or data.currentPanel == "budgeting" and data.budgeting
		or data.currentPanel == "evaluation" and data.evaluation

	if not moduleData then return end
	if moduleData.hintsUsed >= Config.General.MaxHintLevel then
		sendFeedback(player, "warning", "No more hints available for this task.")
		return
	end

	moduleData.hintsUsed = moduleData.hintsUsed + 1
	data.analytics.totalHintsUsed = data.analytics.totalHintsUsed + 1

	local mission = moduleData.currentMission or moduleData.currentTask
	local hint = ""
	if mission then
		local divisor = mission.divisor
		local dividend = mission.dividend or mission.totalBudget
		if moduleData.hintsUsed == 1 then
			hint = "Try using x10 first: " .. (divisor * 10) .. " can be subtracted."
		elseif moduleData.hintsUsed == 2 then
			hint = "After x10, you have " .. (dividend - divisor * 10) .. " remaining."
		else
			hint = "The answer is close to " .. math.floor(dividend / divisor) .. "."
		end
	end

	sendFeedback(player, "hint", "Hint " .. moduleData.hintsUsed .. ": " .. hint)
end)


local getAnalyticsRemote = Remotes:FindFirstChild("GetAnalytics")
if getAnalyticsRemote then
	getAnalyticsRemote.OnServerInvoke = function(player)
		local data = getPlayerData(player)
		local avgTime = 0
		if #data.analytics.completionTimes > 0 then
			local sum = 0
			for _, t in data.analytics.completionTimes do sum = sum + t end
			avgTime = sum / #data.analytics.completionTimes
		end

		local avgChunkQuality = 0
		if #data.analytics.chunkingQualityScores > 0 then
			local sum = 0
			for _, s in data.analytics.chunkingQualityScores do sum = sum + s end
			avgChunkQuality = sum / #data.analytics.chunkingQualityScores
		end

		local overallAccuracy = 0
		if data.analytics.totalTasksCompleted > 0 then
			overallAccuracy = math.floor((data.analytics.totalCorrect / data.analytics.totalTasksCompleted) * 100)
		end

		return {
			overallAccuracy = overallAccuracy,
			tutorialAccuracy = data.tutorial.totalPracticeSteps > 0
				and math.floor((data.tutorial.practiceCorrect / data.tutorial.totalPracticeSteps) * 100) or 0,
			chunkingAccuracy = data.chunking.chunkingTasksCompleted > 0
				and math.floor((data.chunking.chunkingTasksCorrect / data.chunking.chunkingTasksCompleted) * 100) or 0,
			budgetingAccuracy = data.budgeting.missionsCompleted > 0
				and math.floor((data.budgeting.missionsCorrect / data.budgeting.missionsCompleted) * 100) or 0,
			evaluationAccuracy = data.evaluation.integratedTotal > 0
				and math.floor((data.evaluation.integratedCorrect / data.evaluation.integratedTotal) * 100) or 0,
			avgCompletionTime = math.floor(avgTime),
			hintsUsed = data.analytics.totalHintsUsed,
			chunkingQuality = math.floor(avgChunkQuality),
			remainderHandling = data.chunking.remainderTotal > 0
				and math.floor((data.chunking.remainderCorrect / data.chunking.remainderTotal) * 100) or 0,
			budgetingScore = data.budgeting.missionsCompleted > 0
				and math.floor((data.budgeting.missionsCorrect / data.budgeting.missionsCompleted) * 100) or 0,
			boostWins = data.budgeting.boostWins,
			boostLosses = data.budgeting.boostLosses,
			multVerification = data.evaluation.multVerificationTotal > 0
				and math.floor((data.evaluation.multVerificationCorrect / data.evaluation.multVerificationTotal) * 100) or 0,
			module1Unlocked = data.tutorial.unlocked,
			module2Unlocked = data.chunking.unlocked,
			module3Unlocked = data.budgeting.unlocked,
			module4Unlocked = data.evaluation.unlocked,
			overallMastery = overallAccuracy,
		}
	end
end


local getPlayerDataRemote = Remotes:FindFirstChild("GetPlayerData")
if getPlayerDataRemote then
	getPlayerDataRemote.OnServerInvoke = function(player)
		local data = getPlayerData(player)
		return {
			currentModule = data.currentModule,
			tutorial = data.tutorial,
			chunking = data.chunking,
			budgeting = data.budgeting,
			evaluation = data.evaluation,
		}
	end
end


Players.PlayerAdded:Connect(function(player)
	playerData[player.UserId] = createPlayerData(player)
end)

Players.PlayerRemoving:Connect(function(player)
	playerData[player.UserId] = nil
end)


for _, player in Players:GetPlayers() do
	playerData[player.UserId] = createPlayerData(player)
end

print("[DivisionTown] Game server initialized with all 4 modules")