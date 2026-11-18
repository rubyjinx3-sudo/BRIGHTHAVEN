local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tutorial = workspace["Possible Map Replacement"].Tutorial.Tutorial_2
local logs = tutorial.Logs
local sessions = {}
local Review=require(game.ServerScriptService.Brighthaven.AnswerReview)
local arena = tutorial.LundagLavaCrater
local function clear(session)
    for _, connection in ipairs(session.Connections or {}) do connection:Disconnect() end
    session.Connections = {}
    if session.Beam then session.Beam:Destroy();session.Beam=nil end
    if session.Origin then session.Origin:Destroy();session.Origin=nil end
    if session.Target then session.Target:Destroy();session.Target=nil end
end
local function point(session, player, position, parent)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not parent then return end
    session.Target = Instance.new("Attachment")
    session.Target.Position = parent.CFrame:PointToObjectSpace(position)
    session.Target.Parent = parent
    session.Origin = Instance.new("Attachment")
    session.Origin.Position, session.Origin.Parent = Vector3.new(0,2,0),root
    local beam = Instance.new("Beam")
    beam.Name,beam.Attachment0,beam.Attachment1 = "FollowArrow",session.Target,session.Origin
    beam.Width0,beam.Width1,beam.FaceCamera,beam.LightEmission = 1,1,true,1
    beam.Texture,beam.TextureLength,beam.TextureSpeed = "rbxassetid://10249261576",5,1
    beam.Color,beam.Transparency = ColorSequence.new(Color3.fromRGB(255,231,96)),NumberSequence.new(0)
    beam.Parent,session.Beam = root,beam
end
local follow
follow = function(player)
    local session = sessions[player]
    if not session then return end
    clear(session)
    local character = player.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root or (root.Position-tutorial.TutorialNPC2.HumanoidRootPart.Position).Magnitude>350 then return end
    local status = player:GetAttribute("Tutorial2Practice")
    if status=="complete" then
        local portal = workspace.Portal3:FindFirstChild("Teleport")
        if portal then
            point(session,player,portal.Position,portal)
            table.insert(session.Connections,portal.Touched:Connect(function(hit)
                if hit:IsDescendantOf(character) then clear(session) end
            end))
        end
        return
    elseif status~="active" then
        local helper = tutorial.TutorialNPC2.HumanoidRootPart
        point(session,player,helper.Position,helper)
        return
    end
    local column = logs:FindFirstChild("Log_column"..session.Row)
    if not column then return end
    local parts = {}
    for _,part in ipairs(column:GetChildren()) do
        if part:IsA("BasePart") then table.insert(parts,part) end
    end
    if #parts==0 then return end
    -- During the challenge, no beam points at a row or a log.
    local reached = false
    for _,part in ipairs(parts) do
        table.insert(session.Connections,part.Touched:Connect(function(hit)
            if reached or not hit:IsDescendantOf(character) or not humanoid or humanoid.Health<=0 then return end
            if player:GetAttribute("Tutorial2Practice")~="active" or session.Resetting
                or player:GetAttribute("Tutorial2LavaFall") or part:GetAttribute("Sinking") then return end
            local expected=tutorial.OriginalNumber.Value*(session.Row+1)
            if part:GetAttribute("IsCorrect")~=true then
                Review.ForPlayer(player,"Skip counting","Lundag Bilang",part.LogLabel.TextLabel.Text,expected)
                part:SetAttribute("Sinking",true)
                session.Misses=(session.Misses or 0)+1
                if session.Misses<2 then
                    player:SetAttribute("Tutorial2Feedback","One try left. The correct count is "..expected..".")
                    return
                end
                session.Resetting=true
                player:SetAttribute("Tutorial2ProblemResetPending",true)
                player:SetAttribute("Tutorial2Feedback","The correct count was "..expected..". A new problem is coming.")
                task.delay(.45,function()
                    session.Resetting=false
                    if sessions[player]~=session or player:GetAttribute("Tutorial2Practice")~="active"
                        or not player:GetAttribute("Tutorial2ProblemResetPending") then return end
                    player:SetAttribute("Tutorial2ProblemResetPending",nil)
                    session.Row,session.Misses=1,0
                    player:SetAttribute("Tutorial2Row",1)
                    player:SetAttribute("Tutorial2Feedback","Two wrong choices. Start the new problem here.")
                    logs:SetAttribute("ResetCount",(logs:GetAttribute("ResetCount") or 0)+1)
                    if player.Character==character and humanoid.Health>0 then
                        character:PivotTo(arena:GetAttribute("RespawnFrame"))
                        root.AssemblyLinearVelocity=Vector3.zero
                        root.AssemblyAngularVelocity=Vector3.zero
                    end
                    follow(player)
                end)
                return
            end
            reached = true
            session.Misses=0
            session.Row+=1
            player:SetAttribute("Tutorial2Feedback",session.Row<=3 and ("Correct: "..expected..". Next count: "..(expected+tutorial.OriginalNumber.Value)..".") or nil)
            player:SetAttribute("Tutorial2Row",session.Row)
            if session.Row>3 then
                player:SetAttribute("Tutorial2Practice","complete")
                ReplicatedStorage.ShowDialogue:FireClient(player,"Great skip counting! You completed all three plank jumps. Follow the guide to the warehouse.","tutorial2_complete","Counting Helper","CH")
            end
            follow(player)
        end))
    end
    if humanoid then table.insert(session.Connections,humanoid.Died:Connect(function()
        session.RetryHere = true
        clear(session)
    end)) end
end
local function prepare(player)
    if sessions[player] then return end
    sessions[player] = {Row=1,Connections={}}
    player:GetAttributeChangedSignal("Tutorial2Practice"):Connect(function()
        player:SetAttribute("Tutorial2ProblemResetPending",nil)
        if player:GetAttribute("Tutorial2Practice")=="active" then
            sessions[player].Row=1
            sessions[player].Misses=0
            player:SetAttribute("Tutorial2Feedback",nil)
            player:SetAttribute("Tutorial2Row",1)
        end
        follow(player)
    end)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("HumanoidRootPart")
        local session=sessions[player]
        if player:GetAttribute("Tutorial2Practice")~="active" or not session.RetryHere then return end
        task.wait(.8)
        if player.Character~=character or player:GetAttribute("Tutorial2Practice")~="active" then return end
        session.RetryHere=false
        follow(player)
    end)
end
for _,player in ipairs(Players:GetPlayers()) do prepare(player) end
Players.PlayerAdded:Connect(prepare)
Players.PlayerRemoving:Connect(function(player) if sessions[player] then clear(sessions[player]);sessions[player]=nil end end)
game.ServerStorage:WaitForChild("StartTutorialArrow").Event:Connect(function(player) prepare(player);follow(player) end)
