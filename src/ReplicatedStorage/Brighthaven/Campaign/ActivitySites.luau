local Sites={}
function Sites.Resolve(player,node)
    local world=workspace:FindFirstChild("BrighthavenStoryExtension")
    local primary=world and world:FindFirstChild(node)
    if node~="wood" then return primary end
    local map=workspace:FindFirstChild("Possible Map Replacement")
    local legacy=map and map:FindFirstChild("WoodCuttingArea")
    local extra=legacy and legacy:FindFirstChild("BrighthavenWorksite")
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not extra then return primary end
    local floor=primary and primary:FindFirstChild("ActivityFloor")
    if not floor or (root.Position-extra.ActivityFloor.Position).Magnitude<(root.Position-floor.Position).Magnitude then return extra end
    return primary
end
function Sites.IsLegacyWoodPrompt(prompt)
    local map=workspace:FindFirstChild("Possible Map Replacement")
    local wood=map and map:FindFirstChild("WoodCuttingArea")
    local npc=workspace:FindFirstChild("WoodCuttingNPC")
    return prompt:GetAttribute("LegacyWoodActivity")==true
        and ((wood and prompt:IsDescendantOf(wood)) or (npc and prompt:IsDescendantOf(npc))) or false
end
return Sites
