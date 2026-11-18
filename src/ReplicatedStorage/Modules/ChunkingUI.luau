local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
local playerGui = localPlayer:WaitForChild("PlayerGui")

local UI = require(script.Parent:WaitForChild("UIComponents"))
local PracticeData = require(script.Parent:WaitForChild("PracticeData"))

local ChunkingUI = {}

-- Theme Palette
local colours = {
	sky = Color3.fromRGB(226, 244, 255),
	blue = Color3.fromRGB(52, 142, 202),
	ink = Color3.fromRGB(24, 47, 62),
	accent = Color3.fromRGB(255, 199, 76),
	green = Color3.fromRGB(91, 190, 123),
	red = Color3.fromRGB(220, 80, 80),
	bg = Color3.fromRGB(240, 246, 250),
	cardBg = Color3.fromRGB(255, 255, 255),
	inputBg = Color3.fromRGB(245, 247, 250),
	inputBorder = Color3.fromRGB(200, 210, 220),
	inputFocus = Color3.fromRGB(52, 142, 202),
	towerBg = Color3.fromRGB(230, 240, 245),
	bracketLine = Color3.fromRGB(100, 120, 140)
}

-- Active State Variables
local screenGui, frame
local currentDividend, currentDivisor
local remaining, currentQuotient
local historySteps
local selectedFactor, currentStepMode -- "select", "multiply", "subtract"
local pendingProduct = 0
local onCompleteCallback

-- UI Element References
local countersContainer, towerScrollFrame, sideText
local instructionLabel, chunkBtnContainer, customChunkInputFrame, customChunkTextBox, applyCustomBtn
local calcInputFrame, calcPromptLabel, calcInputTextBox, calcSubmitBtn

--------------------------------------------------
-- HELPER FUNCTIONS & UI BUILDERS
--------------------------------------------------
local function make(className, properties, parent)
	local inst = Instance.new(className)
	for prop, val in pairs(properties) do
		inst[prop] = val
	end
	if parent then inst.Parent = parent end
	return inst
end

local function round(inst, radius)
	return make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, inst)
end

local function addPadding(inst, leftRight, topBottom)
	return make("UIPadding", {
		PaddingLeft = UDim.new(0, leftRight or 8),
		PaddingRight = UDim.new(0, leftRight or 8),
		PaddingTop = UDim.new(0, topBottom or 0),
		PaddingBottom = UDim.new(0, topBottom or 0)
	}, inst)
end

-- Fixed Portrait Anchor & Positions
local defaultPortraitPosition = UDim2.new(0.5, 0, 0.95, 0)
local liftedPortraitPosition = UDim2.new(0.5, 0, 0.76, 0)

local function syncDialoguePosition(targetFrame)
	if not targetFrame or not targetFrame.Parent then return end
	local guideVisible = playerGui:GetAttribute("BrightHavenGuideVisible") == true
	targetFrame.Position = guideVisible and liftedPortraitPosition or defaultPortraitPosition
end

local function applyPortraitDialogueTheme(targetFrame)
	targetFrame.BackgroundColor3 = colours.bg
	targetFrame.BackgroundTransparency = 0.02
	targetFrame.AnchorPoint = Vector2.new(0.5, 1)
	targetFrame.Position = defaultPortraitPosition
	targetFrame.Size = UDim2.fromOffset(380, 540)

	round(targetFrame, 18)

	make("UIStroke", {Color = Color3.fromRGB(210, 225, 235), Thickness = 3}, targetFrame)
end

--------------------------------------------------
-- DYNAMIC GROUP COUNTERS
--------------------------------------------------
local function renderGroupCounters(m, active)
	countersContainer:ClearAllChildren()

	if m.Mode == "measure" then
		make("TextLabel", {
			Name = "MeasureText",
			Size = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = colours.ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.format("Pieces made: %d   │   Log left: %d m", active.Quotient, active.Remaining)
		}, countersContainer)

		local bar = make("Frame", {
			Name = "LogMeter",
			Size = UDim2.new(1, 0, 0, 10),
			BackgroundColor3 = Color3.fromRGB(210, 230, 240),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, 20)
		}, countersContainer)
		round(bar, 5)

		local fillPct = math.clamp(active.Remaining / m.Dividend, 0, 1)
		local fill = make("Frame", {
			Name = "RemainingLength",
			Size = UDim2.fromScale(fillPct, 1),
			BackgroundColor3 = colours.blue,
			BorderSizePixel = 0
		}, bar)
		round(fill, 5)
		return
	end

	-- Partitive Grid Mode
	local grid = make("Frame", {
		Name = "GroupCounters",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, math.ceil(m.Divisor / 3) * 32)
	}, countersContainer)

	make("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -4, 0, 28),
		CellPadding = UDim2.fromOffset(4, 4)
	}, grid)

	for index = 1, m.Divisor do
		local cell = make("TextLabel", {
			Name = "Group" .. index,
			BackgroundColor3 = colours.sky,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamBold,
			TextSize = 10,
			TextColor3 = colours.ink,
			TextWrapped = true,
			Text = string.format("%s %d\n%d %s", (m.Group or "Group"):gsub("^%l", string.upper), index, active.Quotient, m.Resource or "items")
		}, grid)
		round(cell, 6)
	end
end

--------------------------------------------------
-- MODERN VISUAL DIVISION TOWER BUILDER (IMAGE MATCHING)
--------------------------------------------------
local function renderModernDivisionTower()
	towerScrollFrame:ClearAllChildren()

	local container = make("Frame", {
		Name = "TowerContainer",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1
	}, towerScrollFrame)

	addPadding(container, 12, 12)

	----------------------------------------------
	-- 1. TOP PARTIAL QUOTIENTS ROW (MATCHES IMAGE)
	----------------------------------------------
	local quotientRow = make("Frame", {
		Name = "QuotientRow",
		Position = UDim2.fromOffset(60, 0),
		Size = UDim2.new(1, -60, 0, 36),
		BackgroundTransparency = 1
	}, container)

	local qRowLayout = make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		VerticalAlignment = Enum.VerticalAlignment.Center
	}, quotientRow)

	for idx, step in ipairs(historySteps) do
		if idx > 1 then
			local plusLabel = make("TextLabel", {
				LayoutOrder = (idx * 2) - 1,
				Size = UDim2.fromOffset(12, 30),
				BackgroundTransparency = 1,
				Font = Enum.Font.GothamBlack,
				TextSize = 16,
				TextColor3 = colours.ink,
				Text = "+"
			}, quotientRow)
		end

		local qTile = make("TextLabel", {
			Name = "QTile_" .. idx,
			LayoutOrder = idx * 2,
			Size = UDim2.fromOffset(42, 32),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Font = Enum.Font.GothamBlack,
			TextSize = 18,
			TextColor3 = colours.ink,
			Text = tostring(step.q)
		}, quotientRow)
		round(qTile, 8)
		make("UIStroke", {Color = Color3.fromRGB(210, 220, 230), Thickness = 1.5}, qTile)
	end

	-- Final Quotient Text Label
	local isFinished = (remaining < currentDivisor and currentStepMode == "select")
	local totalQuotientText = make("TextLabel", {
		Name = "TotalQuotientText",
		LayoutOrder = 999,
		Size = UDim2.fromOffset(110, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 18,
		TextColor3 = colours.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format("Quotient: %d", currentQuotient)
	}, quotientRow)

	----------------------------------------------
	-- 2. DIVISION BRACKET & WORK AREA
	----------------------------------------------
	local mainWorkFrame = make("Frame", {
		Name = "MainWorkFrame",
		Position = UDim2.fromOffset(0, 42),
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1
	}, container)

	-- Divisor Label (Left side outside bracket)
	local divisorLabel = make("TextLabel", {
		Name = "DivisorLabel",
		Position = UDim2.fromOffset(20, 4),
		Size = UDim2.fromOffset(30, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 22,
		TextColor3 = colours.ink,
		Text = tostring(currentDivisor)
	}, mainWorkFrame)

	-- Long Division Bracket Line Frame
	local bracketTopLine = make("Frame", {
		Name = "BracketTopLine",
		Position = UDim2.fromOffset(60, 0),
		Size = UDim2.new(1, -70, 0, 3),
		BackgroundColor3 = colours.bracketLine,
		BorderSizePixel = 0
	}, mainWorkFrame)
	round(bracketTopLine, 2)

	local bracketLeftCurve = make("Frame", {
		Name = "BracketLeftCurve",
		Position = UDim2.fromOffset(56, 0),
		Size = UDim2.fromOffset(4, 30),
		BackgroundColor3 = colours.bracketLine,
		BorderSizePixel = 0
	}, mainWorkFrame)
	round(bracketLeftCurve, 2)

	-- Inner Math Steps Container
	local stepsContainer = make("Frame", {
		Name = "StepsContainer",
		Position = UDim2.fromOffset(70, 8),
		Size = UDim2.new(0, 120, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1
	}, mainWorkFrame)

	local stepsLayout = make("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Right
	}, stepsContainer)

	-- Initial Dividend
	local initialDividendLabel = make("TextLabel", {
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 26),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 20,
		TextColor3 = colours.ink,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = tostring(currentDividend)
	}, stepsContainer)

	-- Historical Steps
	local orderCounter = 2
	for idx, step in ipairs(historySteps) do
		-- Subtraction Line Row
		local subRow = make("Frame", {
			Name = "SubRow_" .. idx,
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1
		}, stepsContainer)

		local minusSign = make("TextLabel", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(20, 26),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			Text = "-"
		}, subRow)

		local subValue = make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(step.sub)
		}, subRow)

		orderCounter += 1

		-- Horizontal Line Separator
		local sepLine = make("Frame", {
			Name = "SepLine_" .. idx,
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = colours.bracketLine,
			BorderSizePixel = 0
		}, stepsContainer)

		orderCounter += 1

		-- Remainder Result Row
		local remLabel = make("TextLabel", {
			Name = "RemLabel_" .. idx,
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(step.rem)
		}, stepsContainer)

		orderCounter += 1
	end

	-- Active Input Steps Display
	if currentStepMode == "multiply" then
		local activeSubRow = make("Frame", {
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1
		}, stepsContainer)

		make("TextLabel", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(20, 26),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			Text = "-"
		}, activeSubRow)

		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 18,
			TextColor3 = Color3.fromRGB(210, 100, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "?"
		}, activeSubRow)

	elseif currentStepMode == "subtract" then
		local activeSubRow = make("Frame", {
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1
		}, stepsContainer)

		make("TextLabel", {
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.fromOffset(20, 26),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			Text = "-"
		}, activeSubRow)

		make("TextLabel", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 20,
			TextColor3 = colours.ink,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = tostring(pendingProduct)
		}, activeSubRow)

		orderCounter += 1

		make("Frame", {
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 2),
			BackgroundColor3 = colours.bracketLine,
			BorderSizePixel = 0
		}, stepsContainer)

		orderCounter += 1

		make("TextLabel", {
			LayoutOrder = orderCounter,
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundTransparency = 1,
			Font = Enum.Font.GothamBlack,
			TextSize = 18,
			TextColor3 = Color3.fromRGB(210, 100, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = "?"
		}, stepsContainer)
	end

	task.defer(function()
		if towerScrollFrame then
			towerScrollFrame.CanvasPosition = Vector2.new(0, towerScrollFrame.AbsoluteCanvasSize.Y)
		end
	end)
end

local function updateUI()
	local modeData = {
		Mode = "measure",
		Dividend = currentDividend,
		Divisor = currentDivisor,
		Group = "Group",
		Resource = "Items"
	}
	renderGroupCounters(modeData, { Quotient = currentQuotient, Remaining = remaining })
	renderModernDivisionTower()
end

--------------------------------------------------
-- INTERACTION & WORKFLOW LOGIC
--------------------------------------------------
local function resetToChunkSelection()
	currentStepMode = "select"
	selectedFactor = nil
	pendingProduct = 0

	chunkBtnContainer.Visible = true
	customChunkInputFrame.Visible = false
	calcInputFrame.Visible = false
	calcInputTextBox.Text = ""
	customChunkTextBox.Text = ""
	instructionLabel.Text = "Step 1: Pick or enter a multiplier chunk:"
	sideText.Text = "<b><font color=\"#D84315\">💡 MATH TOOL</font></b>\nSelect a multiplier or type a custom factor to split the remaining dividend."
	updateUI()
end

local function onFactorChosen(factor)
	if not factor or factor <= 0 then return end
	selectedFactor = factor
	currentStepMode = "multiply"

	chunkBtnContainer.Visible = false
	customChunkInputFrame.Visible = false
	calcInputFrame.Visible = true

	calcPromptLabel.Text = string.format("%d × %d =", currentDivisor, selectedFactor)
	calcInputTextBox.PlaceholderText = "?"
	calcInputTextBox.Text = ""
	instructionLabel.Text = "Step 2: Calculate product & submit:"
	sideText.Text = string.format("<b><font color=\"#D84315\">💡 MATH TOOL</font></b>\nCalculate <b>%d × %d</b> and type the product.", currentDivisor, selectedFactor)

	updateUI()
	task.defer(function()
		calcInputTextBox:CaptureFocus()
	end)
end

local function submitCustomFactor()
	local cleanText = customChunkTextBox.Text:gsub("%D", "")
	local val = tonumber(cleanText)
	if val and val > 0 then
		onFactorChosen(val)
	else
		customChunkTextBox.Text = ""
		sideText.Text = "<b><font color=\"#C62828\">⚠️ INVALID FACTOR</font></b>\nPlease enter a valid number greater than 0."
	end
end

local function processStepInput()
	local cleanText = calcInputTextBox.Text:gsub("%D", "")
	local userVal = tonumber(cleanText)

	if not userVal then
		calcInputTextBox.Text = ""
		return
	end

	if currentStepMode == "multiply" then
		local correctProduct = currentDivisor * selectedFactor
		if userVal ~= correctProduct then
			sideText.Text = string.format("<b><font color=\"#C62828\">❌ INCORRECT PRODUCT</font></b>\n%d × %d is not %d. Check your calculation!", currentDivisor, selectedFactor, userVal)
			calcInputTextBox.Text = ""
			return
		end

		if correctProduct > remaining then
			sideText.Text = string.format("<b><font color=\"#C62828\">⚠️ CHUNK TOO LARGE</font></b>\n%d exceeds remaining %d. Choose a smaller factor!", correctProduct, remaining)
			resetToChunkSelection()
			return
		end

		pendingProduct = correctProduct
		currentStepMode = "subtract"
		calcPromptLabel.Text = string.format("%d - %d =", remaining, pendingProduct)
		calcInputTextBox.PlaceholderText = "?"
		calcInputTextBox.Text = ""
		instructionLabel.Text = "Step 3: Perform subtraction:"
		sideText.Text = string.format("<b><font color=\"#2E7D32\">✔ CORRECT MULTIPLICATION!</font></b>\nNow compute remaining: <b>%d - %d</b>.", remaining, pendingProduct)

		updateUI()
		task.defer(function()
			calcInputTextBox:CaptureFocus()
		end)

	elseif currentStepMode == "subtract" then
		local expectedRem = remaining - pendingProduct
		if userVal ~= expectedRem then
			sideText.Text = string.format("<b><font color=\"#C62828\">❌ INCORRECT SUBTRACTION</font></b>\n%d - %d is not %d. Check your math!", remaining, pendingProduct, userVal)
			calcInputTextBox.Text = ""
			return
		end

		remaining = expectedRem
		currentQuotient += selectedFactor
		table.insert(historySteps, { q = selectedFactor, sub = pendingProduct, rem = remaining })

		if remaining < currentDivisor then
			currentStepMode = "select"
			updateUI()
			if onCompleteCallback then
				onCompleteCallback(currentQuotient, remaining)
			end
		else
			resetToChunkSelection()
		end
	end
end

--------------------------------------------------
-- MAIN UI SETUP
--------------------------------------------------
function ChunkingUI.start(dividend, divisor, startInPracticeMode, onComplete)
	currentDividend = dividend
	currentDivisor = divisor
	remaining = dividend
	currentQuotient = 0
	historySteps = {}
	currentStepMode = "select"
	onCompleteCallback = onComplete

	if screenGui then screenGui:Destroy() end

	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "ChunkingPortraitGui"
	screenGui.DisplayOrder = 35
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	-- Main Frame
	frame = make("Frame", {Name = "MainFrame"}, screenGui)
	applyPortraitDialogueTheme(frame)

	-- Header Title
	local title = make("TextLabel", {
		Name = "SpeakerTitle",
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 14,
		TextColor3 = colours.ink,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.format("Captain Kapa: Chunking Lab  |  Solve: %d ÷ %d", currentDividend, currentDivisor)
	}, frame)

	-- Group Counters / Meter Container
	countersContainer = make("Frame", {
		Name = "GroupCountersContainer",
		Position = UDim2.fromOffset(14, 44),
		Size = UDim2.new(1, -28, 0, 32),
		BackgroundTransparency = 1
	}, frame)

	-- Long Division Visual Canvas Frame
	towerScrollFrame = make("ScrollingFrame", {
		Name = "TowerScrollFrame",
		Position = UDim2.fromOffset(14, 82),
		Size = UDim2.new(1, -28, 0, 240),
		BackgroundColor3 = colours.towerBg,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colours.blue,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y
	}, frame)
	round(towerScrollFrame, 12)
	make("UIStroke", {Color = Color3.fromRGB(200, 220, 230), Thickness = 1.5}, towerScrollFrame)

	-- Interactive Action Panel
	local interactionPanel = make("Frame", {
		Name = "InteractionPanel",
		Position = UDim2.fromOffset(14, 332),
		Size = UDim2.new(1, -28, 0, 96),
		BackgroundColor3 = colours.cardBg
	}, frame)
	round(interactionPanel, 8)
	make("UIStroke", {Color = colours.inputBorder, Thickness = 1}, interactionPanel)

	instructionLabel = make("TextLabel", {
		Name = "Instructions",
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.new(1, -20, 0, 16),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextColor3 = colours.ink,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "Step 1: Pick or enter a multiplier chunk:"
	}, interactionPanel)

	-- Chunk Selection Grid
	chunkBtnContainer = make("Frame", {
		Name = "ChunkBtnContainer",
		Position = UDim2.fromOffset(10, 28),
		Size = UDim2.new(1, -20, 0, 60),
		BackgroundTransparency = 1
	}, interactionPanel)

	make("UIGridLayout", {
		CellSize = UDim2.new(0.31, 0, 0, 26),
		CellPadding = UDim2.fromOffset(6, 6)
	}, chunkBtnContainer)

	local chunks = { { "× 1", 1 }, { "× 2", 2 }, { "× 5", 5 }, { "× 10", 10 }, { "× 20", 20 } }
	for _, chunkInfo in ipairs(chunks) do
		local btn = make("TextButton", {
			Name = "Btn" .. chunkInfo[2],
			BackgroundColor3 = colours.blue,
			Font = Enum.Font.GothamBlack,
			TextSize = 11,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Text = chunkInfo[1]
		}, chunkBtnContainer)
		round(btn, 6)
		btn.Activated:Connect(function() onFactorChosen(chunkInfo[2]) end)
	end

	local customBtn = make("TextButton", {
		Name = "BtnCustom",
		BackgroundColor3 = colours.accent,
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = colours.ink,
		Text = "Custom"
	}, chunkBtnContainer)
	round(customBtn, 6)

	-- Custom Chunk Multiplier Sub-Frame
	customChunkInputFrame = make("Frame", {
		Name = "CustomChunkInputFrame",
		Position = UDim2.fromOffset(10, 32),
		Size = UDim2.new(1, -20, 0, 52),
		BackgroundTransparency = 1,
		Visible = false
	}, interactionPanel)

	customChunkTextBox = make("TextBox", {
		Name = "CustomInput",
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.new(0.48, 0, 0, 34),
		BackgroundColor3 = colours.inputBg,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = colours.ink,
		PlaceholderColor3 = Color3.fromRGB(160, 170, 180),
		PlaceholderText = "e.g. 3",
		ClearTextOnFocus = false
	}, customChunkInputFrame)
	round(customChunkTextBox, 6)
	addPadding(customChunkTextBox, 8, 0)
	local customStroke = make("UIStroke", {Color = colours.inputBorder, Thickness = 1.5}, customChunkTextBox)

	applyCustomBtn = make("TextButton", {
		Name = "ApplyCustomBtn",
		Position = UDim2.new(0.51, 0, 0, 0),
		Size = UDim2.new(0.25, 0, 0, 34),
		BackgroundColor3 = colours.green,
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "USE"
	}, customChunkInputFrame)
	round(applyCustomBtn, 6)

	local cancelCustomBtn = make("TextButton", {
		Name = "CancelCustomBtn",
		Position = UDim2.new(0.78, 0, 0, 0),
		Size = UDim2.new(0.22, 0, 0, 34),
		BackgroundColor3 = colours.red,
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "Back"
	}, customChunkInputFrame)
	round(cancelCustomBtn, 6)

	-- Calculation Input Frame
	calcInputFrame = make("Frame", {
		Name = "CalcInputFrame",
		Position = UDim2.fromOffset(10, 32),
		Size = UDim2.new(1, -20, 0, 52),
		BackgroundTransparency = 1,
		Visible = false
	}, interactionPanel)

	calcPromptLabel = make("TextLabel", {
		Name = "CalcPrompt",
		Size = UDim2.new(0.46, 0, 0, 34),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextSize = 12,
		TextColor3 = colours.ink,
		TextXAlignment = Enum.TextXAlignment.Left
	}, calcInputFrame)

	calcInputTextBox = make("TextBox", {
		Name = "CalcInputTextBox",
		Position = UDim2.new(0.46, 0, 0, 0),
		Size = UDim2.new(0.26, 0, 0, 34),
		BackgroundColor3 = colours.inputBg,
		Font = Enum.Font.GothamBold,
		TextSize = 13,
		TextColor3 = colours.ink,
		PlaceholderColor3 = Color3.fromRGB(160, 170, 180),
		ClearTextOnFocus = false
	}, calcInputFrame)
	round(calcInputTextBox, 6)
	addPadding(calcInputTextBox, 8, 0)
	local calcStroke = make("UIStroke", {Color = colours.inputBorder, Thickness = 1.5}, calcInputTextBox)

	calcSubmitBtn = make("TextButton", {
		Name = "SubmitBtn",
		Position = UDim2.new(0.75, 0, 0, 0),
		Size = UDim2.new(0.25, 0, 0, 34),
		BackgroundColor3 = colours.blue,
		Font = Enum.Font.GothamBlack,
		TextSize = 11,
		TextColor3 = Color3.fromRGB(255, 255, 255),
		Text = "SUBMIT"
	}, calcInputFrame)
	round(calcSubmitBtn, 6)

	-- Input Focus Stroke Behaviors
	customChunkTextBox.Focused:Connect(function() customStroke.Color = colours.inputFocus end)
	customChunkTextBox.FocusLost:Connect(function() customStroke.Color = colours.inputBorder end)
	calcInputTextBox.Focused:Connect(function() calcStroke.Color = colours.inputFocus end)
	calcInputTextBox.FocusLost:Connect(function() calcStroke.Color = colours.inputBorder end)

	-- Sanitize numeric input
	calcInputTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		calcInputTextBox.Text = calcInputTextBox.Text:gsub("%D", "")
	end)
	customChunkTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		customChunkTextBox.Text = customChunkTextBox.Text:gsub("%D", "")
	end)

	-- Event Wiring
	customBtn.Activated:Connect(function()
		chunkBtnContainer.Visible = false
		customChunkInputFrame.Visible = true
		customChunkTextBox.Text = ""
		customChunkTextBox:CaptureFocus()
	end)

	cancelCustomBtn.Activated:Connect(function()
		resetToChunkSelection()
	end)

	applyCustomBtn.Activated:Connect(submitCustomFactor)
	customChunkTextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then submitCustomFactor() end
	end)

	-- Guidance Section Frame
	local sideFrame = make("Frame", {
		Name = "SideFrame",
		Position = UDim2.fromOffset(14, 436),
		Size = UDim2.new(1, -28, 0, 86),
		BackgroundColor3 = colours.cardBg
	}, frame)
	round(sideFrame, 8)
	make("UIStroke", {Color = Color3.fromRGB(210, 220, 230), Thickness = 1}, sideFrame)

	sideText = make("TextLabel", {
		Name = "SideText",
		Size = UDim2.fromScale(0.92, 0.92),
		Position = UDim2.fromScale(0.04, 0.04),
		BackgroundTransparency = 1,
		RichText = true,
		Font = Enum.Font.Gotham,
		TextSize = 11,
		TextColor3 = colours.ink,
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		Text = "<b><font color=\"#D84315\">💡 TEACHER GUIDE</font></b>\n\nPick a multiplier chunk to start solving."
	}, sideFrame)

	calcSubmitBtn.Activated:Connect(processStepInput)
	calcInputTextBox.FocusLost:Connect(function(enterPressed)
		if enterPressed then processStepInput() end
	end)

	playerGui:GetAttributeChangedSignal("BrightHavenGuideVisible"):Connect(function()
		syncDialoguePosition(frame)
	end)
	syncDialoguePosition(frame)

	resetToChunkSelection()
end

return ChunkingUI