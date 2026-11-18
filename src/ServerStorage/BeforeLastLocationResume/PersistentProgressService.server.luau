-- Persistent progress for all BrightHaven places in this experience.
-- Currency, bag contents, home upgrades, leaderstats, and campaign jobs have their own services.
-- This service stores the shared milestone flags that unlock tutorial and story flow.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")

local STORE_NAME="BrightHaven_PlayerProgress_v1"
local store=not RunService:IsStudio() and DataStoreService:GetDataStore(STORE_NAME) or nil
local records,connections,dirty,loading={},{},{},{}

local fields={
    Tutorial1Complete="boolean",
    Tutorial2Complete="boolean",
    Tutorial3Complete="boolean",
    EnteredMainWorld="boolean",
    HomeIntroductionSeen="boolean",
    BarangayFlashbackSeen="boolean",
    StoryEndingSeen="boolean",
}

local function clean(saved)
    local record={Version=1}
    if type(saved)=="table" then
        for key in pairs(fields) do record[key]=saved[key]==true end
    end
    return record
end

local function capture(player,record)
    record.Tutorial1Complete=record.Tutorial1Complete or player:GetAttribute("Tutorial1Complete")==true or player:GetAttribute("Tutorial1Practice")=="complete"
    record.Tutorial2Complete=record.Tutorial2Complete or player:GetAttribute("Tutorial2Practice")=="complete"
    record.Tutorial3Complete=record.Tutorial3Complete or player:GetAttribute("Tutorial3Practice")=="complete"
    record.EnteredMainWorld=record.EnteredMainWorld or player:GetAttribute("EnteredMainWorld")==true
    record.HomeIntroductionSeen=record.HomeIntroductionSeen or player:GetAttribute("HomeIntroductionSeen")==true
    record.BarangayFlashbackSeen=record.BarangayFlashbackSeen or player:GetAttribute("BarangayFlashbackSeen")==true
    record.StoryEndingSeen=record.StoryEndingSeen or player:GetAttribute("StoryEndingSeen")==true
    return record
end

local function apply(player,record)
    if record.Tutorial1Complete then
        player:SetAttribute("Tutorial1Complete",true)
        player:SetAttribute("Tutorial1Practice","complete")
    end
    if record.Tutorial2Complete then player:SetAttribute("Tutorial2Practice","complete") end
    if record.Tutorial3Complete then player:SetAttribute("Tutorial3Practice","complete") end
    for key in pairs(fields) do
        if key~="Tutorial1Complete" and key~="Tutorial2Complete" and key~="Tutorial3Complete" and record[key] then
            player:SetAttribute(key,true)
        end
    end
end

local function write(player)
    local id=player.UserId
    local record=records[id]
    if not record or not dirty[id] then return true end
    dirty[id]=nil
    capture(player,record)
    if not store then return true end
    local snapshot=clean(record)
    for attempt=1,3 do
        local ok,err=pcall(function()
            store:UpdateAsync("player_"..id,function(previous)
                local merged=clean(previous)
                for key in pairs(fields) do merged[key]=merged[key] or snapshot[key] end
                return merged
            end)
        end)
        if ok then return true end
        warn("[BrightHaven Progress] Save attempt "..attempt.." failed for "..id..": "..tostring(err))
        task.wait(attempt*.5)
    end
    dirty[id]=true
    return false
end

local function queue(player)
    if not records[player.UserId] then return end
    dirty[player.UserId]=true
    task.delay(5,function()
        if player.Parent and dirty[player.UserId] then write(player) end
    end)
end

local function bind(player)
    if loading[player] or records[player.UserId] then return end
    loading[player]=true
    player:SetAttribute("PersistentProgressReady",false)
    local record=clean(nil)
    if store then
        local ok,saved=pcall(function() return store:GetAsync("player_"..player.UserId) end)
        if ok then record=clean(saved) else warn("[BrightHaven Progress] Load failed for "..player.UserId..": "..tostring(saved)) end
    end
    if not player.Parent then loading[player]=nil;return end
    records[player.UserId]=record
    apply(player,record)
    player:SetAttribute("PersistentProgressReady",true)
    local watches={"Tutorial1Complete","Tutorial1Practice","Tutorial2Practice","Tutorial3Practice","EnteredMainWorld","HomeIntroductionSeen","BarangayFlashbackSeen","StoryEndingSeen"}
    connections[player]={}
    for _,name in ipairs(watches) do
        table.insert(connections[player],player:GetAttributeChangedSignal(name):Connect(function() queue(player) end))
    end
    loading[player]=nil
end

Players.PlayerAdded:Connect(bind)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(bind,player) end
Players.PlayerRemoving:Connect(function(player)
    write(player)
    for _,connection in ipairs(connections[player] or {}) do connection:Disconnect() end
    connections[player],records[player.UserId],dirty[player.UserId],loading[player]=nil,nil,nil,nil
end)
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do write(player) end
end)
