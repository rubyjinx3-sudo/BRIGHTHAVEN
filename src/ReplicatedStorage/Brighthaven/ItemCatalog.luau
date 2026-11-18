local Catalog={SlotCount=7}
Catalog.Order={"FoodPack","WaterBottle","CareKit","Umbrella","HelperBadge","IonStabilizer","AtmosphericCore","WindTurbine"}
Catalog.ById={
    FoodPack={Name="Food Pack",Description="Restores 40 food points. A full food bar has 100 points.",Stack=9,Action="Eat",Hunger=40,Model="ReliefFoodPack",Color=Color3.fromRGB(237,143,90)},
    WaterBottle={Name="Water Bottle",Description="Restores 45 water points. A full water bar has 100 points.",Stack=9,Action="Drink",Thirst=45,Model="ReliefWaterBottle",Color=Color3.fromRGB(61,153,217)},
    CareKit={Name="Care Kit",Description="Rest and use a care kit to feel better.",Stack=5,Action="Use",Health=30,Color=Color3.fromRGB(230,103,122),Model="ReliefCareKit"},
    Umbrella={Name="Umbrella",Description="Open your umbrella to stay dry in the rain.",Stack=1,Action="Open",Color=Color3.fromRGB(132,104,203),Model="BagUmbrella"},
    HelperBadge={Name="Helper Badge",Description="A reward for helping your neighbors prepare for storms.",Stack=99,Color=Color3.fromRGB(226,181,52),Model="BagHelperBadge"},
    IonStabilizer={Name="Ion Stabilizer",Description="A machine part for the Weather Lab.",Stack=1,Quest=true,Model="BagMachinePart",Color=Color3.fromRGB(83,172,153)},
    AtmosphericCore={Name="Atmospheric Core",Description="A machine part for the Weather Lab.",Stack=1,Quest=true,Model="BagMachinePart",Color=Color3.fromRGB(83,172,153)},
    WindTurbine={Name="Wind Turbine",Description="A machine part for the Weather Lab.",Stack=1,Quest=true,Model="BagMachinePart",Color=Color3.fromRGB(83,172,153)},
}
Catalog.Shop={FoodPack=3,WaterBottle=1,CareKit=5,Umbrella=6}
return Catalog

