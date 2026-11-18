local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local event = game.ReplicatedStorage:WaitForChild("SprintEvent")
local wanted, lastRequest = {}, {}
local WALK_SPEED, RUN_SPEED = 16, 26

local function apply(player)
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end
    local blocked = humanoid.SeatPart ~= nil or player:GetAttribute("SchoolShuttleRiding") == true
        or player:GetAttribute("BrighthavenRiding") == true or humanoid.WalkSpeed == 0
        or player:GetAttribute("Sleeping") == true or player:GetAttribute("ClinicRecovering") == true
        or player:GetAttribute("HasStartedGame") ~= true
    local tired = player:GetAttribute("NeedsRest") == true
    local running = wanted[player] == true and not blocked and not tired
    player:SetAttribute("Sprinting", running)
    if blocked then return end
    local box = character:FindFirstChild("GarbageBox")
    local count = box and box:FindFirstChild("GarbageCount")
    local penalty = count and math.max(0, count.Value) * .15 or 0
    local speed = math.max(8, (tired and 10 or running and RUN_SPEED or WALK_SPEED) - penalty)
    if math.abs(humanoid.WalkSpeed - speed) > .01 then humanoid.WalkSpeed = speed end
end

event.OnServerEvent:Connect(function(player, running)
    if type(running) ~= "boolean" then return end
    local now = os.clock()
    if running and now - (lastRequest[player] or 0) < .08 then return end
    lastRequest[player] = now
    wanted[player] = running
    apply(player)
end)
local function joined(player)
    player.CharacterAdded:Connect(function() wanted[player] = false; player:SetAttribute("Sprinting", false) end)
end
Players.PlayerAdded:Connect(joined)
for _,player in ipairs(Players:GetPlayers()) do joined(player) end
Players.PlayerRemoving:Connect(function(player) wanted[player], lastRequest[player] = nil, nil end)
local elapsed = 0
RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    if elapsed < .1 then return end
    elapsed = 0
    for _,player in ipairs(Players:GetPlayers()) do apply(player) end
end)

