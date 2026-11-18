local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Lighting=game:GetService("Lighting")
local Care=require(script.Parent.SurvivalService)
local Settings=require(RS.Brighthaven.Settings)
local Clock={Minutes=420,Day=1}
local absolute=420
local started=false
local changed=Instance.new("BindableEvent")
Clock.Changed=changed.Event

function Clock.IsCurfew(minutes) return minutes>=1320 or minutes<420 end
function Clock.CanSleep() return Clock.Minutes>=1080 or Clock.Minutes<420 end
function Clock.Eligible(player)
    local h=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    return player:GetAttribute("HasStartedGame")==true and Care.InMainWorld(player)
        and not player:GetAttribute("BrighthavenFlashbackPlaying") and h and h.Health>0
end
local function publish()
    Clock.Minutes=absolute%1440;Clock.Day=math.floor(absolute/1440)+1
    local night=Clock.Minutes>=1080 or Clock.Minutes<420
    RS:SetAttribute("TownMinutes",math.floor(Clock.Minutes))
    RS:SetAttribute("TownDay",Clock.Day)
    RS:SetAttribute("TownCurfew",Clock.IsCurfew(Clock.Minutes))
    Lighting.ClockTime=Clock.Minutes/60
    RS:SetAttribute("BrightHavenRaining",night)
    if RS:GetAttribute("BrightHavenIsNight")~=night then
        RS:SetAttribute("BrightHavenIsNight",night)
        RS.WeatherEvent:FireAllClients(night)
    end
    changed:Fire(Clock.Minutes,Clock.Day)
end
function Clock.Step(dt)
    absolute+=math.clamp(dt,0,2)*1440/Settings.DayDurationSeconds
    publish()
end
function Clock.Morning()
    local day=math.floor(absolute/1440)
    if absolute%1440>=420 then day+=1 end
    absolute=day*1440+420
    publish()
end
function Clock.Start()
    if started then return end;started=true;publish()
    task.spawn(function()
        local previous=os.clock()
        while true do
            task.wait(.5)
            local now=os.clock();local active=false
            for _,p in Players:GetPlayers() do if Clock.Eligible(p) then active=true;break end end
            if active then Clock.Step(now-previous) end
            previous=now
        end
    end)
end
return Clock
