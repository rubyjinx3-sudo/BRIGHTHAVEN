local Rules={ClinicFee=5,WakeMinutes=420,CurfewMinutes=1260,CurfewWarningLeadMinutes=30}
Rules.Upgrades={
    {Id="WaterTank",Name="Clean Water Tank",Cost=15,Description="Wake up with 25 more water points."},
    {Id="SnackShelf",Name="Emergency Food Shelf",Cost=20,Description="Wake up with 20 more food points."},
    {Id="CozyBed",Name="Cozy Bed",Cost=30,Description="A full night's rest fills your health bar."},
}
table.insert(Rules.Upgrades,1,{Id="StormRoof",Name="Reinforced Storm Roof",Cost=20,Description="Main goal: secure your own house against the final storm."})
table.insert(Rules.Upgrades,2,{Id="StormShutters",Name="Storm Window Shutters",Cost=15,Description="Main goal: protect your windows before powering the final beam."})
Rules.ById={}
for _,upgrade in Rules.Upgrades do Rules.ById[upgrade.Id]=upgrade end
function Rules.Rest(upgrades)
    return {Hunger=20+(upgrades.SnackShelf and 20 or 0),Thirst=25+(upgrades.WaterTank and 25 or 0),
        Health=upgrades.CozyBed and 100 or 50}
end
function Rules.FormatTime(minutes)
    local value=math.floor(tonumber(minutes) or 420)%1440
    return string.format("%02d:%02d",math.floor(value/60),value%60)
end
return Rules
