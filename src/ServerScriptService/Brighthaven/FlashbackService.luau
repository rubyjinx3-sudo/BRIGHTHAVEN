local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Practice = require(RS.Brighthaven.TutorialPractice)
local request = RS.Brighthaven.Remotes:WaitForChild("FlashbackRequest")
local Service = {}
local sessions = {}

local function release(player, outcome)
    local session = sessions[player]
    if not session then return end
    sessions[player] = nil
    if session.Removing then session.Removing:Disconnect() end
    local root = session.Root
    if root and root.Parent then
        root.Anchored = session.Anchored
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    if player.Parent then
        player:SetAttribute("BrighthavenFlashbackPending", nil)
        player:SetAttribute("BrighthavenFlashbackPlaying", nil)
        if session.Started and (outcome == "complete" or outcome == "skip") then
            player:SetAttribute("BarangayFlashbackSeen", true)
        end
    end
end

function Service.Begin(player)
    if player:GetAttribute("BarangayFlashbackSeen") == true then return nil end
    if sessions[player] then return sessions[player].Token end
    if player:GetAttribute("CaptainMetThisVisit") ~= true or not Practice.CanUseWorld(player) then return nil end
    local session = {Token = HttpService:GenerateGUID(false), Character = player.Character}
    sessions[player] = session
    player:SetAttribute("BrighthavenFlashbackPending", true)
    session.Removing = player.CharacterRemoving:Connect(function(character)
        if character == session.Character then release(player, "abort") end
    end)
    task.delay(180, function()
        if sessions[player] == session then release(player, "abort") end
    end)
    return session.Token
end

function Service.Handle(player, action, payload)
    if type(payload) ~= "table" or type(payload.Token) ~= "string" then
        return {Ok = false, Message = "Please finish talking to Captain Kappa first."}
    end
    local session = sessions[player]
    if not session or session.Token ~= payload.Token then
        return {Ok = false, Message = "This memory is no longer playing."}
    end
    if action == "Start" then
        if session.Started then return {Ok = false, Message = "The memory is already playing."} end
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local captain = workspace.BrighthavenPrototype.Locations_1_2.Location1_BarangayHall.CaptainKapaPrompt
        if character ~= session.Character or not root or not humanoid or humanoid.Health <= 0
            or humanoid.SeatPart or not Practice.CanUseWorld(player)
            or player:GetAttribute("CaptainMetThisVisit") ~= true
            or (root.Position - captain.Position).Magnitude > 40 then
            release(player, "abort")
            return {Ok = false, Message = "Meet Captain Kappa at Barangay Hall to hear the story."}
        end
        session.Started, session.Root, session.Anchored = true, root, root.Anchored
        root.Anchored = true
        root.AssemblyLinearVelocity = Vector3.zero
        player:SetAttribute("BrighthavenFlashbackPlaying", true)
        return {Ok = true}
    elseif action == "Finish" then
        local outcome = payload.Outcome
        if outcome ~= "complete" and outcome ~= "skip" and outcome ~= "abort" then
            return {Ok = false, Message = "Unknown memory result."}
        end
        if outcome ~= "abort" and not session.Started then
            return {Ok = false, Message = "The memory has not started."}
        end
        release(player, outcome)
        return {Ok = true}
    end
    return {Ok = false, Message = "Unknown memory action."}
end

request.OnServerInvoke = Service.Handle
Players.PlayerRemoving:Connect(function(player) release(player, "abort") end)
return Service
