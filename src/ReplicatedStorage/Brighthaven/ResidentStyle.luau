local Style={}
local tops={Color3.fromRGB(239,112,141),Color3.fromRGB(77,166,196),Color3.fromRGB(245,190,67),Color3.fromRGB(98,178,124),
    Color3.fromRGB(176,133,202),Color3.fromRGB(227,131,81),Color3.fromRGB(111,184,184),Color3.fromRGB(202,94,98),Color3.fromRGB(136,170,223)}
local pants={Color3.fromRGB(55,78,108),Color3.fromRGB(75,88,81),Color3.fromRGB(102,88,121),Color3.fromRGB(91,101,120),Color3.fromRGB(61,96,110)}
local tones={Color3.fromRGB(218,169,126),Color3.fromRGB(185,130,89),Color3.fromRGB(235,190,150),Color3.fromRGB(162,112,79),Color3.fromRGB(205,149,104)}
local hairColors={Color3.fromRGB(40,32,30),Color3.fromRGB(75,48,35),Color3.fromRGB(54,46,42),Color3.fromRGB(100,66,44)}
local function detail(model,head,name,offset,size,color,anchored)
    local p=Instance.new("Part");p.Name=name;p.Size=size;p.CFrame=head.CFrame*offset;p.Color=color
    p.Material=Enum.Material.SmoothPlastic;p.Anchored=anchored;p.Massless=true
    p.CanCollide,p.CanTouch,p.CanQuery=false,false,false;p:SetAttribute("ResidentStyleDetail",true);p.Parent=model
    if not anchored then local w=Instance.new("WeldConstraint");w.Part0,w.Part1,w.Parent=head,p,p end
    return p
end
function Style.Apply(model,index,cinematic)
    local head,torso=model:FindFirstChild("Head"),model:FindFirstChild("Torso")
    if not head or not torso then return end
    for _,v in model:GetChildren() do if v:GetAttribute("ResidentStyleDetail") then v:Destroy() end end
    local shirt=tops[(index-1)%#tops+1];local trousers=pants[math.floor((index-1)/#tops)%#pants+1]
    local tone=tones[(index*3-1)%#tones+1]
    local hair=model:GetAttribute("AgeGroup")=="Elder" and Color3.fromRGB(168,171,174) or hairColors[(index-1)%#hairColors+1]
    for _,v in model:GetChildren() do
        if v:IsA("BasePart") then
            if v==head or v.Name:find("Arm") then v.Color=tone
            elseif v==torso then v.Color=shirt
            elseif v.Name:find("Leg") then v.Color=trousers
            elseif v.Name:find("^Hair") then v.Color=hair
            elseif v.Name=="Backpack" then v.Color=tops[(index+3)%#tops+1]
            elseif v.Name=="BagStrap" then v.Color=Color3.fromRGB(250,225,126) end
        end
    end
    local body=model:FindFirstChildOfClass("BodyColors")
    if body then
        body.HeadColor3,body.LeftArmColor3,body.RightArmColor3=tone,tone,tone
        body.TorsoColor3,body.LeftLegColor3,body.RightLegColor3=shirt,trousers,trousers
    end
    local s=head.Size.Y
    if index%3==0 then
        local p=detail(model,head,"HairFringe",CFrame.new(-s*.33,s*.37,-s*.43)*CFrame.Angles(0,0,-.15),Vector3.new(s*.62,s*.16,s*.22),hair,cinematic)
        p.Shape=Enum.PartType.Block
    elseif index%3==1 then
        detail(model,head,"HairPart",CFrame.new(s*.4,s*.44,0),Vector3.new(s*.15,s*.16,s*.94),hair:Lerp(Color3.new(1,1,1),.12),cinematic)
    end
    if model:GetAttribute("Gender")=="Female" and index%2==0 then
        detail(model,head,"HairRibbon",CFrame.new(s*.78,s*.3,s*.16),Vector3.new(s*.35,s*.18,s*.16),shirt:Lerp(Color3.new(1,1,1),.35),cinematic)
    end
    model:SetAttribute("OutfitId",index)
end
return Style
