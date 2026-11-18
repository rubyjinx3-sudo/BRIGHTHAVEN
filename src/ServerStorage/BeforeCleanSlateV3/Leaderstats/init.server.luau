local Players=game:GetService("Players")
local Settings=require(script:WaitForChild("SettingsModule"))
local Money=require(game.ServerScriptService.Brighthaven:WaitForChild("MoneyService"))
local stores,loaded={},{},{}
for _,stat in ipairs(Settings.Stats) do
    if stat.Name~="Coins" and not game:GetService("RunService"):IsStudio() then stores[stat.Name]=game:GetService("DataStoreService"):GetDataStore(stat.Name.."Data") end
end
local function bind(player)
    Money.Bind(player)
    local stats=player:FindFirstChild("leaderstats")
    if not stats then stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player end
    loaded[player]={}
    for _,stat in ipairs(Settings.Stats) do
        if stat.Name~="Coins" then
            local value=stats:FindFirstChild(stat.Name) or stat.Instance:Clone()
            value.Name=stat.Name;value.Parent=stats
            local ok,saved=true,nil
            if Settings.SaveData and not game:GetService("RunService"):IsStudio() then ok,saved=pcall(function() return stores[stat.Name]:GetAsync(tostring(player.UserId)) end) end
            loaded[player][stat.Name]=ok
            value.Value=ok and saved or stat.DefaultValue
        end
    end
end
Players.PlayerAdded:Connect(bind)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(bind,player) end
Players.PlayerRemoving:Connect(function(player)
    if Settings.SaveData and not game:GetService("RunService"):IsStudio() then
        for _,stat in ipairs(Settings.Stats) do
            local value=player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild(stat.Name)
            if stat.Name~="Coins" and value and loaded[player] and loaded[player][stat.Name] then
                pcall(function() stores[stat.Name]:SetAsync(tostring(player.UserId),value.Value) end)
            end
        end
    end
    loaded[player]=nil
end)
