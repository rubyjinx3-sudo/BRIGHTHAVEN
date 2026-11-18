local Appearance={}
local ink=Color3.fromRGB(49,55,59)
local function detail(model,limb,name,offset,size,color,shape)
    local p=Instance.new("Part")
    p.Name,p.Size,p.CFrame,p.Color=name,size,limb.CFrame*offset,color
    p.Anchored,p.Massless,p.CanCollide,p.CanTouch=false,true,false,false
    p.Material=Enum.Material.SmoothPlastic
    if shape then p.Shape=shape end
    p:SetAttribute("CommunityDetail",true);p.Parent=model
    local weld=Instance.new("WeldConstraint");weld.Part0,weld.Part1,weld.Parent=limb,p,p
    return p
end
function Appearance.Apply(model,spec)
    local h=model:FindFirstChildOfClass("Humanoid")
    assert(h and model:FindFirstChild("Torso") and model:FindFirstChild("Head"),"Expected an existing R6 NPC")
    for _,v in ipairs(model:GetDescendants()) do
        if v:IsA("Accessory") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic")
            or v:GetAttribute("CommunityDetail") or v:IsA("BasePart") and table.find({"Hair","NurseCap","CapBadge","StethoscopeTube","StethoscopeDisc","ShirtInset","NameBadge","Lanyard"},v.Name) then v:Destroy() end
    end
    local tone=spec.Tone or Color3.fromRGB(202,150,109)
    local shirt=spec.Shirt or Color3.fromRGB(56,157,147)
    local trousers=spec.Trousers or Color3.fromRGB(58,79,99)
    local colors=model:FindFirstChildOfClass("BodyColors") or Instance.new("BodyColors",model)
    colors.HeadColor3,colors.LeftArmColor3,colors.RightArmColor3=tone,tone,tone
    colors.TorsoColor3,colors.LeftLegColor3,colors.RightLegColor3=shirt,trousers,trousers
    for _,name in ipairs({"Head","Left Arm","Right Arm"}) do model[name].Color=tone end
    model.Torso.Color=shirt;model["Left Leg"].Color=trousers;model["Right Leg"].Color=trousers
    h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None;h.DisplayName=spec.Name
    h.EvaluateStateMachine=false
    model.HumanoidRootPart.Anchored=true
    for _,p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide=false;p.CanTouch=false end
    end
    model:SetAttribute("NPCName",spec.Name);model:SetAttribute("NPCRole",spec.Role)
    model:SetAttribute("Gender",spec.Female and "Female" or "Male")
    model:SetAttribute("AgeGroup",spec.Child and "Child" or spec.Elder and "Elder" or "Adult")
    local hair=spec.Elder and Color3.fromRGB(176,182,185) or Color3.fromRGB(47,37,35)
    detail(model,model.Head,"HairTop",CFrame.new(0,.49,.07),Vector3.new(1.8,.28,1.08),hair)
    if spec.Female then
        detail(model,model.Head,"HairBack",CFrame.new(0,.05,.46),Vector3.new(1.85,1.25,.38),hair)
        detail(model,model.Head,"HairBun",CFrame.new(.55,.3,.72),Vector3.new(.75,.75,.75),hair,Enum.PartType.Ball)
    end
    local torso,role=model.Torso,spec.Role
    if role=="Doctor" or role=="Scientist" then
        for _,x in ipairs({-.68,.68}) do detail(model,torso,"CoatPanel",CFrame.new(x,-.15,-.54),Vector3.new(.56,1.5,.08),Color3.new(1,1,1)) end
        for _,x in ipairs({-.32,.32}) do detail(model,torso,"Stethoscope",CFrame.new(x,.25,-.59),Vector3.new(.09,.75,.09),ink) end
        detail(model,torso,"StethoscopeDisc",CFrame.new(.32,-.25,-.61),Vector3.new(.28,.28,.08),Color3.fromRGB(161,175,179),Enum.PartType.Ball)
    elseif role=="Teacher" or role=="Reception" or role=="Station Helper" then
        detail(model,torso,"Lanyard",CFrame.new(0,.3,-.54),Vector3.new(.12,.8,.08),Color3.fromRGB(244,195,65))
    elseif role=="Shopkeeper" then
        detail(model,torso,"Apron",CFrame.new(0,-.35,-.55),Vector3.new(1.55,1.15,.1),Color3.fromRGB(244,211,95))
    elseif role=="Driver" or role=="Electrician" or role=="Carpenter" or role=="Recycling Worker" or role=="Warehouse Worker" then
        for _,x in ipairs({-.65,.65}) do detail(model,torso,"SafetyVest",CFrame.new(x,0,-.53),Vector3.new(.46,1.75,.08),Color3.fromRGB(250,193,54)) end
        detail(model,torso,"ReflectiveBand",CFrame.new(0,-.45,-.59),Vector3.new(1.8,.17,.07),Color3.fromRGB(239,245,246))
        if role~="Driver" then
            detail(model,model.Head,"HardHat",CFrame.new(0,.66,0),Vector3.new(2.04,.37,1.32),Color3.fromRGB(255,211,64))
            detail(model,model.Head,"HatBrim",CFrame.new(0,.48,-.3),Vector3.new(2.22,.12,1.42),Color3.fromRGB(255,211,64))
        end
    end
    if spec.Child then
        detail(model,torso,"Backpack",CFrame.new(0,0,.8),Vector3.new(1.5,1.5,.65),spec.Bag or Color3.fromRGB(241,106,132))
        for _,x in ipairs({-.5,.5}) do detail(model,torso,"BagStrap",CFrame.new(x,.25,-.54),Vector3.new(.17,1.5,.08),Color3.fromRGB(239,218,86)) end
    else detail(model,torso,"NameBadge",CFrame.new(-.5,.4,-.61),Vector3.new(.5,.32,.06),Color3.new(1,1,1)) end
    return model
end
return Appearance
