local Rules=require(script.Parent.TrafficRules)
for _,s in ipairs(Rules.Signals) do
    for _,v in ipairs(s.Model:GetDescendants()) do
        if v:IsA("ProximityPrompt") and v.Name=="RequestCrossing" then
            v.Triggered:Connect(function(player)
                local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                if r and (r.Position-v.Parent.Position).Magnitude<10 then s.Requested=true;s.Model:SetAttribute("CrossingRequested",true) end
            end)
        end
    end
end
local elapsed=0
Rules.Update()
game.RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0;Rules.Update()
end)
