local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Brighthaven = ReplicatedStorage:WaitForChild("Brighthaven")
local Remotes = Brighthaven:WaitForChild("Remotes")
local ServerNotice = Remotes:WaitForChild("ServerNotice")

ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
    local dialogue = prompt:GetAttribute("TownLifeDialogue")
    if not dialogue or not player then
        return
    end

    local speaker = prompt.ObjectText ~= "" and prompt.ObjectText or "Brighthaven Neighbor"
    ServerNotice:FireClient(player, {
        Type = "info",
        Speaker = speaker,
        Message = speaker .. ": " .. tostring(dialogue),
    })
end)
