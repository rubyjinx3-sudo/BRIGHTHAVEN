local ReplicatedStorage=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")

-- Keep the old dialogue remote compatible without granting an unrestricted axe.
ReplicatedStorage:WaitForChild("StartWoodCutting").OnServerEvent:Connect(function(player)
    player:SetAttribute("WoodAreaHelperHint",true)
end)
local function removeOldAxes(player)
    local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
    local r=c and c:FindFirstChild("HumanoidRootPart")
    local floor=workspace.BrighthavenStoryExtension.wood.ActivityFloor
    if h and h.Health>0 and r and (r.Position-floor.Position).Magnitude<=42 then return end
    for _,container in {player.Backpack,c} do
        if container then for _,tool in container:GetChildren() do
            if tool:IsA("Tool") and tool.Name==game.ServerStorage.WoodCuttingAxe.Name then tool:Destroy() end
        end end
    end
end
task.spawn(function() while true do task.wait(.5);for _,p in Players:GetPlayers() do removeOldAxes(p) end end end)
