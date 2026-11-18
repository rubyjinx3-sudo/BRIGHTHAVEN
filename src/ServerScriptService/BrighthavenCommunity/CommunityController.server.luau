local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local community=workspace:WaitForChild("BrighthavenCommunity")
local actors={}
for i,m in ipairs(community.Residents:GetChildren()) do
    local torso=m:FindFirstChild("Torso")
    local shoulder=torso and torso:FindFirstChild("Right Shoulder")
    table.insert(actors,{Model=m,Home=m:GetAttribute("HomeFrame"),Phase=i*.7,Shoulder=shoulder,C0=shoulder and shoulder.C0})
end
for i,m in ipairs(community.Pets:GetChildren()) do
    local actor={Model=m,Home=m:GetAttribute("HomeFrame"),Phase=i,Pet=true,HappyUntil=0};table.insert(actors,actor)
    local prompt=m.PrimaryPart:FindFirstChild("CommunityGreeting")
    prompt.Triggered:Connect(function(player)
        local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r and (r.Position-m.PrimaryPart.Position).Magnitude<10 then actor.HappyUntil=os.clock()+3;m:SetAttribute("PatsReceived",(m:GetAttribute("PatsReceived") or 0)+1) end
    end)
end
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
    elapsed+=dt;if elapsed<.1 then return end;elapsed=0
    local now=os.clock()
    for _,a in ipairs(actors) do
        local nearby=false
        for _,p in ipairs(Players:GetPlayers()) do
            local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            if r and (r.Position-a.Home.Position).Magnitude<18 then nearby=true;break end
        end
        if a.Pet then
            local happy=now<a.HappyUntil
            local bob=happy and math.abs(math.sin(now*7))*.3 or math.sin(now*2+a.Phase)*.035
            a.Model:PivotTo(a.Home*CFrame.new(0,bob,0)*CFrame.Angles(0,math.sin(now*(happy and 4 or .3)+a.Phase)*(happy and .2 or .08),0))
        elseif a.Shoulder then
            local angle=nearby and (-1.7+math.sin(now*4+a.Phase)*.22) or math.sin(now+a.Phase)*.035
            a.Shoulder.C0=a.C0*CFrame.Angles(0,0,angle)
        end
    end
end)
