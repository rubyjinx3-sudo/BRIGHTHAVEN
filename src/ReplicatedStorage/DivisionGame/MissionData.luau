local MissionData = {}


MissionData.TutorialExamples = {
	{
		id = "tut_1",
		title = "Sharing Cookies Equally",
		story = "You have 12 cookies to share equally among 3 friends. How many does each friend get?",
		dividend = 12,
		divisor = 3,
		expectedQuotient = 4,
		expectedRemainder = 0,
		type = "equal_sharing",
	},
	{
		id = "tut_2",
		title = "Distributing Gems",
		story = "You found 15 gems and need to split them into 5 equal treasure chests. How many gems per chest?",
		dividend = 15,
		divisor = 5,
		expectedQuotient = 3,
		expectedRemainder = 0,
		type = "equal_sharing",
	},
	{
		id = "tut_3",
		title = "Packing Supplies",
		story = "You have 20 supply packs to load onto 4 trucks equally. How many packs per truck?",
		dividend = 20,
		divisor = 4,
		expectedQuotient = 5,
		expectedRemainder = 0,
		type = "equal_sharing",
	},
}


MissionData.TutorialPractice = {
	{ id = "tp_1", dividend = 18, divisor = 3, type = "equal_sharing" },
	{ id = "tp_2", dividend = 24, divisor = 6, type = "equal_sharing" },
	{ id = "tp_3", dividend = 16, divisor = 4, type = "equal_sharing" },
	{ id = "tp_4", dividend = 21, divisor = 7, type = "equal_sharing" },
	{ id = "tp_5", dividend = 30, divisor = 5, type = "equal_sharing" },
	{ id = "tp_6", dividend = 14, divisor = 2, type = "equal_sharing" },
	{ id = "tp_7", dividend = 27, divisor = 9, type = "equal_sharing" },
}


MissionData.ChunkingMissions = {
	{ id = "ch_1", dividend = 48, divisor = 6, story = "Share 48 crystals among 6 wizards." },
	{ id = "ch_2", dividend = 56, divisor = 7, story = "Distribute 56 potions to 7 shops." },
	{ id = "ch_3", dividend = 72, divisor = 8, story = "Load 72 cargo crates onto 8 ships." },
	{ id = "ch_4", dividend = 54, divisor = 9, story = "Split 54 gold bars among 9 knights." },
	{ id = "ch_5", dividend = 42, divisor = 6, story = "Give 42 arrows to 6 archers equally." },
	{ id = "ch_6", dividend = 63, divisor = 7, story = "Divide 63 scrolls among 7 scholars." },
	{ id = "ch_7", dividend = 64, divisor = 8, story = "Share 64 seeds with 8 farmers." },
	{ id = "ch_8", dividend = 81, divisor = 9, story = "Distribute 81 stars to 9 constellations." },
	{ id = "ch_9", dividend = 36, divisor = 6, story = "Place 36 shields in 6 armory slots." },
	{ id = "ch_10", dividend = 49, divisor = 7, story = "Assign 49 tasks to 7 workers." },
}


MissionData.RemainderTasks = {
	{ id = "rem_1", dividend = 50, divisor = 6, story = "Share 50 coins among 6 pirates." },
	{ id = "rem_2", dividend = 45, divisor = 7, story = "Divide 45 apples among 7 baskets." },
	{ id = "rem_3", dividend = 67, divisor = 8, story = "Split 67 gems among 8 vaults." },
	{ id = "rem_4", dividend = 75, divisor = 9, story = "Distribute 75 seeds among 9 plots." },
	{ id = "rem_5", dividend = 38, divisor = 6, story = "Give 38 arrows to 6 archers." },
	{ id = "rem_6", dividend = 53, divisor = 7, story = "Share 53 scrolls among 7 scholars." },
	{ id = "rem_7", dividend = 70, divisor = 8, story = "Load 70 crates onto 8 ships." },
	{ id = "rem_8", dividend = 82, divisor = 9, story = "Assign 82 stars to 9 constellations." },
	{ id = "rem_9", dividend = 29, divisor = 6, story = "Divide 29 coins among 6 chests." },
	{ id = "rem_10", dividend = 61, divisor = 7, story = "Share 61 gems among 7 vaults." },
}


MissionData.FactorMultipleTasks = {
	{ id = "fm_1", number = 24, question = "Which of these are factors of 24?", options = {2, 3, 4, 5, 6, 8, 9}, correctFactors = {2, 3, 4, 6, 8} },
	{ id = "fm_2", number = 36, question = "Which of these are factors of 36?", options = {2, 3, 4, 5, 6, 8, 9}, correctFactors = {2, 3, 4, 6, 9} },
	{ id = "fm_3", number = 48, question = "Which of these are factors of 48?", options = {2, 3, 4, 5, 6, 7, 8}, correctFactors = {2, 3, 4, 6, 8} },
	{ id = "fm_4", number = 30, question = "Which of these are factors of 30?", options = {2, 3, 4, 5, 6, 7, 8}, correctFactors = {2, 3, 5, 6} },
	{ id = "fm_5", number = 56, question = "Which of these are factors of 56?", options = {2, 3, 4, 5, 6, 7, 8}, correctFactors = {2, 4, 7, 8} },
	{ id = "fm_6", number = 42, question = "Which of these are factors of 42?", options = {2, 3, 4, 5, 6, 7, 8}, correctFactors = {2, 3, 6, 7} },
	{ id = "fm_7", number = 72, question = "Which of these are factors of 72?", options = {2, 3, 4, 5, 6, 8, 9}, correctFactors = {2, 3, 4, 6, 8, 9} },
	{ id = "fm_8", number = 54, question = "Which of these are factors of 54?", options = {2, 3, 4, 5, 6, 8, 9}, correctFactors = {2, 3, 6, 9} },
	{ id = "fm_9", number = 63, question = "Which of these are factors of 63?", options = {2, 3, 5, 6, 7, 8, 9}, correctFactors = {3, 7, 9} },
	{ id = "fm_10", number = 45, question = "Which of these are factors of 45?", options = {2, 3, 4, 5, 6, 8, 9}, correctFactors = {3, 5, 9} },
}


MissionData.BudgetMissions = {
	{ id = "bud_1", totalBudget = 240, groups = 6, story = "Allocate $240 among 6 departments equally.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_2", totalBudget = 350, groups = 7, story = "Divide $350 among 7 project teams.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_3", totalBudget = 480, groups = 8, story = "Split $480 among 8 store branches.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_4", totalBudget = 540, groups = 9, story = "Distribute $540 among 9 charity funds.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_5", totalBudget = 180, groups = 6, story = "Allocate $180 among 6 classrooms.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_6", totalBudget = 294, groups = 7, story = "Divide $294 among 7 research labs.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_7", totalBudget = 392, groups = 8, story = "Split $392 among 8 food banks.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
	{ id = "bud_8", totalBudget = 459, groups = 9, story = "Distribute $459 among 9 shelters.", leftoverOptions = {"reserve", "carryover", "redistribute"} },
}


MissionData.BoostChallenges = {
	{ id = "boost_1", dividend = 96, divisor = 8, bonusReward = 50, story = "Solve for a $50 bonus!" },
	{ id = "boost_2", dividend = 84, divisor = 7, bonusReward = 75, story = "Solve for a $75 bonus!" },
	{ id = "boost_3", dividend = 108, divisor = 9, bonusReward = 100, story = "Solve for a $100 bonus!" },
	{ id = "boost_4", dividend = 66, divisor = 6, bonusReward = 60, story = "Solve for a $60 bonus!" },
	{ id = "boost_5", dividend = 77, divisor = 7, bonusReward = 80, story = "Solve for a $80 bonus!" },
}


MissionData.IntegratedMissions = {
	{
		id = "int_1",
		type = "routine",
		story = "A factory produces 144 toys. They need to pack them into boxes of 8. How many full boxes and how many toys left over?",
		dividend = 144,
		divisor = 8,
		requiresBudgeting = false,
	},
	{
		id = "int_2",
		type = "non_routine",
		story = "You have $500 to split among 7 teams. Each team gets an equal share. How much per team and how much is left? Decide what to do with the leftover.",
		dividend = 500,
		divisor = 7,
		requiresBudgeting = true,
		leftoverDecision = true,
	},
	{
		id = "int_3",
		type = "routine",
		story = "A baker made 126 cookies for 9 parties. How many cookies per party?",
		dividend = 126,
		divisor = 9,
		requiresBudgeting = false,
	},
	{
		id = "int_4",
		type = "non_routine",
		story = "A school has $840 for 8 classrooms. Allocate the budget equally. What happens to any leftover?",
		dividend = 840,
		divisor = 8,
		requiresBudgeting = true,
		leftoverDecision = true,
	},
	{
		id = "int_5",
		type = "routine",
		story = "Divide 96 energy cells among 6 reactors equally.",
		dividend = 96,
		divisor = 6,
		requiresBudgeting = false,
	},
}

return MissionData