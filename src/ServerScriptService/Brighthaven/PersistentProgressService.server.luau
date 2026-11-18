-- Persistent progress and safe resume points for BrightHaven - Storm Survival.
-- Currency, bag contents, home upgrades, leaderstats, and campaign jobs have their own services.
local Players=game:GetService("Players")
local DataStoreService=game:GetService("DataStoreService")
local RunService=game:GetService("RunService")
local ServerScriptService=game:GetService("ServerScriptService")

local STORE_NAME="BrightHaven_PlayerProgress_v3"
local store=not RunService:IsStudio() and DataStoreService:GetDataStore(STORE_NAME) or nil
local records,connections,dirty,loading={},{},{},{}
local lastLocationSave={}

local fields={
    Tutorial1Complete="boolean",
    Tutorial2Complete="boolean",
    Tutorial3Complete="boolean",
    EnteredMainWorld="boolean",
    HomeIntroductionSeen="boolean",
    BarangayFlashbackSeen="boolean",
    StoryEndingSeen="boolean",
}

local function finite(value)
    return type(value)=="number" and value==value and value~=math.huge and value~=-math.huge
end

local function cleanResume(resume)
    if type(resume)~="table" or resume.PlaceId~=game.PlaceId then return nil end
    if resume.Kind=="Home" then return {Kind="Home",PlaceId=game.PlaceId} end
    if resume.Kind~="World" and resume.Kind~="Checkpoint" then return nil end
    local values={"X","Y","Z","LX","LZ"}
    for _,key in ipairs(values) do if not finite(resume[key]) then return nil end end
    if math.abs(resume.X)>10000 or math.abs(resume.Z)>10000 or resume.Y<-1000 or resume.Y>2000 then return nil end
    if resume.Kind=="World" and (math.abs(resume.X)>=1150 or math.abs(resume.Z)>=1050 or resume.Y<-170 or resume.Y>-90) then return nil end
    return {Kind=resume.Kind,PlaceId=game.PlaceId,X=resume.X,Y=resume.Y,Z=resume.Z,LX=resume.LX,LZ=resume.LZ}
end

local function clean(saved)
    local record={Version=2}
    if type(saved)=="table" then
        for key in pairs(fields) do record[key]=saved[key]==true end
        record.Resume=cleanResume(saved.Resume)
        if finite(saved.TownElapsed) and saved.TownElapsed>=0 then
            record.TownElapsed=math.floor(saved.TownElapsed)
        end
    end
    return record
end

local function safeResumePosition(player,root,humanoid)
    local p=root.Position
    if player:GetAttribute("HomeInteriorActive")==true then return false end
    if player:GetAttribute("Tutorial2LavaFall")==true or player:GetAttribute("ClinicRecovering")==true or player:GetAttribute("Sleeping")==true
        or player:GetAttribute("BrighthavenFlashbackPlaying")==true or player:GetAttribute("StoryEndingPlaying")==true then return false end
    if humanoid.Health<=0 or humanoid.FloorMaterial==Enum.Material.Air then return false end
    return math.abs(p.X)<10000 and math.abs(p.Z)<10000 and p.Y>-1000 and p.Y<2000
end

local function captureResume(player,record)
    local character=player.Character
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end
    if player:GetAttribute("HomeInteriorActive")==true and humanoid.Health>0 then
        record.Resume={Kind="Home",PlaceId=game.PlaceId}
        return true
    end
    if not safeResumePosition(player,root,humanoid) then return false end
    local p,look=root.Position,root.CFrame.LookVector
    record.Resume={
        Kind="Checkpoint",PlaceId=game.PlaceId,
        X=math.round(p.X*10)/10,Y=math.round(p.Y*10)/10,Z=math.round(p.Z*10)/10,
        LX=math.round(look.X*100)/100,LZ=math.round(look.Z*100)/100,
    }
    return true
end

local function capture(player,record)
    record.Tutorial1Complete=record.Tutorial1Complete or player:GetAttribute("Tutorial1Complete")==true or player:GetAttribute("Tutorial1Practice")=="complete"
    record.Tutorial2Complete=record.Tutorial2Complete or player:GetAttribute("Tutorial2Practice")=="complete"
    record.Tutorial3Complete=record.Tutorial3Complete or player:GetAttribute("Tutorial3Practice")=="complete"
    record.EnteredMainWorld=record.EnteredMainWorld or player:GetAttribute("EnteredMainWorld")==true
    record.HomeIntroductionSeen=record.HomeIntroductionSeen or player:GetAttribute("HomeIntroductionSeen")==true
    record.BarangayFlashbackSeen=record.BarangayFlashbackSeen or player:GetAttribute("BarangayFlashbackSeen")==true
    record.StoryEndingSeen=record.StoryEndingSeen or player:GetAttribute("StoryEndingSeen")==true
    local elapsed=player:GetAttribute("TownElapsed")
    if finite(elapsed) then record.TownElapsed=math.max(record.TownElapsed or 0,elapsed) end
    captureResume(player,record)
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
    player:SetAttribute("TownElapsed",record.TownElapsed or 0)
    player:SetAttribute("ResumeAvailable",record.Resume~=nil)
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
                if snapshot.Resume then merged.Resume=snapshot.Resume end
                if snapshot.TownElapsed then merged.TownElapsed=math.max(merged.TownElapsed or 0,snapshot.TownElapsed) end
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

local function queue(player,delay)
    if not records[player.UserId] then return end
    dirty[player.UserId]=true
    task.delay(delay or 5,function()
        if player.Parent and dirty[player.UserId] then write(player) end
    end)
end

local function restoreCharacter(player,character)
    task.delay(1.25,function()
        local record=records[player.UserId]
        if not player.Parent or player.Character~=character or not record or not record.Resume then return end
        if player:GetAttribute("ClinicRecovering")==true then return end
        local root=character:FindFirstChild("HumanoidRootPart")
        local humanoid=character:FindFirstChildOfClass("Humanoid")
        if not root or not humanoid or humanoid.Health<=0 then return end
        local resume=record.Resume
        if resume.Kind=="Home" then
            local ok,homeService=pcall(function()
                return require(ServerScriptService:WaitForChild("Brighthaven"):WaitForChild("HomeService"))
            end)
            local house=ok and homeService and homeService.Ensure and homeService.Ensure(player)
            local floor=house and house:FindFirstChild("Floor",true)
            if floor and floor:IsA("BasePart") then
                player:SetAttribute("HomeInteriorActive",true)
                character:PivotTo(CFrame.new(floor.Position+Vector3.new(0,3.5,6)))
            else
                return
            end
        else
            local look=Vector3.new(resume.LX,0,resume.LZ)
            if look.Magnitude<0.05 then look=Vector3.new(0,0,-1) else look=look.Unit end
            player:SetAttribute("HomeInteriorActive",false)
            character:PivotTo(CFrame.lookAt(Vector3.new(resume.X,resume.Y,resume.Z),Vector3.new(resume.X,resume.Y,resume.Z)+look))
        end
        root.AssemblyLinearVelocity=Vector3.zero
        root.AssemblyAngularVelocity=Vector3.zero
        player:SetAttribute("LastLocationRestored",true)
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
    if not player.Parent then loading[player]=nil return end
    records[player.UserId]=record
    apply(player,record)
    player:SetAttribute("PersistentProgressReady",true)
    local watches={"Tutorial1Complete","Tutorial1Practice","Tutorial2Practice","Tutorial3Practice","EnteredMainWorld","HomeIntroductionSeen","BarangayFlashbackSeen","StoryEndingSeen"}
    connections[player]={}
    for _,name in ipairs(watches) do
        table.insert(connections[player],player:GetAttributeChangedSignal(name):Connect(function() queue(player,5) end))
    end
    table.insert(connections[player],player.CharacterAdded:Connect(function(character) restoreCharacter(player,character) end))
    if player.Character then task.spawn(restoreCharacter,player,player.Character) end
    task.spawn(function()
        while player.Parent and records[player.UserId] do
            task.wait(20)
            local recordNow=records[player.UserId]
            local clock=player:GetAttribute("TownElapsed")
            if recordNow and finite(clock) and clock>(recordNow.TownElapsed or 0) then queue(player,0) end
            local before=records[player.UserId] and cleanResume(records[player.UserId].Resume)
            if records[player.UserId] and captureResume(player,records[player.UserId]) then
                local now=records[player.UserId].Resume
                if now and (not before or before.Kind~=now.Kind or before.X~=now.X or before.Y~=now.Y or before.Z~=now.Z) then
                    player:SetAttribute("ResumeAvailable",true)
                    queue(player,20)
                end
            end
        end
    end)
    loading[player]=nil
end

Players.PlayerAdded:Connect(bind)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(bind,player) end
Players.PlayerRemoving:Connect(function(player)
    if records[player.UserId] then
        capture(player,records[player.UserId])
        dirty[player.UserId]=true
    end
    write(player)
    for _,connection in ipairs(connections[player] or {}) do connection:Disconnect() end
    connections[player],records[player.UserId],dirty[player.UserId],loading[player],lastLocationSave[player.UserId]=nil,nil,nil,nil,nil
end)
game:BindToClose(function()
    for _,player in ipairs(Players:GetPlayers()) do
        if records[player.UserId] then capture(player,records[player.UserId]); dirty[player.UserId]=true end
        write(player)
    end
end)
