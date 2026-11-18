local Settings = {}

Settings.SaveData = true -- Turn this off if you DONT, again DONT, want to save the Data

-- If you want more stats just add it here
Settings.Stats = {
	{ Name = "Rank", DefaultValue = 0, Instance = Instance.new("IntValue") },
	{ Name = "Coins", DefaultValue = 0, Instance = Instance.new("IntValue") },
}

return Settings