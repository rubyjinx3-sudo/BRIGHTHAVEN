local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local anchor=workspace:WaitForChild("Portal5"):WaitForChild("Teleport"):WaitForChild("ExitPromptAnchor")
local prompt=anchor:WaitForChild("ExitPracticePrompt")
local target=workspace:WaitForChild("Portal6"):WaitForChild("Teleport")
local captain=workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
local pending={}

prompt.Triggered:Connect(function(player)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if pending[player] or not root or not humanoid or humanoid.Health<=0
        or (root.Position-anchor.WorldPosition).Magnitude>prompt.MaxActivationDistance+3 then return end
    if player:GetAttribute("Tutorial3Practice")~="complete" then
        RS.Brighthaven.Tutorial3Remotes.StateChanged:FireClient(player,{Ok=false,Message="Finish your three crate deliveries, then check your answer."})
        return
    end
    pending[player]=true
    if humanoid.SeatPart then
        humanoid.Sit=false
        local deadline=os.clock()+1
        repeat task.wait() until not humanoid.SeatPart or os.clock()>=deadline or player.Character~=character
    end
    if player.Character==character and root.Parent and humanoid.Health>0 and not humanoid.SeatPart then
        local position=target.Position+Vector3.new(-5,3,0)
        character:PivotTo(CFrame.lookAt(position, Vector3.new(captain.Position.X,position.Y,captain.Position.Z)))
        root.AssemblyLinearVelocity,root.AssemblyAngularVelocity=Vector3.zero,Vector3.zero
        player:SetAttribute("WorldArrivalSerial",(player:GetAttribute("WorldArrivalSerial") or 0)+1)
    end
    pending[player]=nil
end)
Players.PlayerRemoving:Connect(function(player) pending[player]=nil end)
