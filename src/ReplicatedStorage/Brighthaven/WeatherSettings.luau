return {
    ClearSeconds={55,105}, CloudySeconds={9,15}, RainSeconds={45,75}, StormSeconds={35,60}, ClearingSeconds={10,16},
    TransitionSeconds=8,
    Presets={
        Clear={Rain=0,Darkness=0,Cover=.58,Density=.52,CloudColor=Color3.fromRGB(247,249,251),Wind=Vector3.new(2,0,1)},
        Cloudy={Rain=0,Darkness=.28,Cover=.82,Density=.7,CloudColor=Color3.fromRGB(188,198,208),Wind=Vector3.new(7,0,3)},
        Rain={Rain=.52,Darkness=.5,Cover=.91,Density=.84,CloudColor=Color3.fromRGB(139,151,169),Wind=Vector3.new(12,0,6)},
        Storm={Rain=.95,Darkness=.84,Cover=.98,Density=.95,CloudColor=Color3.fromRGB(91,104,126),Wind=Vector3.new(28,0,12)},
        Clearing={Rain=0,Darkness=0,Cover=.58,Density=.52,CloudColor=Color3.fromRGB(247,249,251),Wind=Vector3.new(2,0,1)},
    },
}
