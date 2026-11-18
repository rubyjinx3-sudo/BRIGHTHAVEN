local Config = {}


Config.Tutorial = {
	GuidedExamplesRequired = 3,
	GuidedPracticeRequired = 5,
	MasteryGatePercent = 80,
	FeedbackMaxDelaySeconds = 1,
}


Config.Chunking = {
	EqualSharingTasksRequired = 10,
	EqualSharingAccuracyGate = 75,
	FactorMultipleTasksRequired = 10,
	FactorMultipleAccuracyGate = 80,
	TwoDigitDivisionTasksRequired = 10,
	QuotientRemainderTasksRequired = 10,
	QuotientRemainderAccuracyGate = 80,
	MasteryGatePercent = 75,
	Divisors = {6, 7, 8, 9},
	FriendlyMultiples = {2, 5, 10},
}


Config.Budgeting = {
	MoneyMissionsRequired = 8,
	BudgetingAccuracyGate = 75,
	LeftoverFundAccuracyGate = 75,
	BoostCooldownRounds = 1,
}


Config.Evaluation = {
	IntegratedMissionsAccuracyGate = 80,
	MultiplicationVerificationGate = 85,
	UATMinRating = "Satisfactory",
}


Config.General = {
	MaxHintLevel = 3,
	HintPenaltyPercent = 5,
	FeedbackDisplayTime = 3,
	AnimationSpeed = 0.5,
}


Config.Colors = {
	Primary = Color3.fromRGB(30, 80, 140),
	Success = Color3.fromRGB(40, 160, 60),
	Warning = Color3.fromRGB(200, 140, 20),
	Error = Color3.fromRGB(200, 50, 50),
	Info = Color3.fromRGB(60, 140, 200),
	Background = Color3.fromRGB(25, 25, 35),
	Panel = Color3.fromRGB(35, 35, 50),
	Text = Color3.fromRGB(240, 240, 250),
	TextDim = Color3.fromRGB(160, 160, 180),
}

return Config