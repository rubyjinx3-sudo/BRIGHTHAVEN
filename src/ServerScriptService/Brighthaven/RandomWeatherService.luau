local RS=game.ReplicatedStorage
local Settings=require(RS.Brighthaven.WeatherSettings)
local Service={}
local rng=Random.new()
local current={Rain=0,Darkness=0,Cover=.58,Density=.52,CloudColor=Color3.fromRGB(247,249,251),Wind=Vector3.new(2,0,1)}
local from,target,started,transition,deadline,kind,pending,nextThunder
local initialized=false
local clouds=workspace.Terrain:FindFirstChildOfClass('Clouds')
local function seconds(range) return rng:NextNumber(range[1],range[2]) end
function Service.ChooseWetWeather() return rng:NextNumber()<.6 and 'Rain' or 'Storm' end
function Service.SetWeather(value,duration,fade)
 assert(Settings.Presets[value],'Unknown weather')
 from=table.clone(current);target=Settings.Presets[value]
 kind=value;started=workspace:GetServerTimeNow();transition=fade or Settings.TransitionSeconds
 deadline=started+(duration or seconds(Settings[value..'Seconds']))
 nextThunder=started+rng:NextNumber(8,15)
 RS:SetAttribute('BrightHavenWeather',kind);RS:SetAttribute('WeatherEndsAt',deadline)
 RS:SetAttribute('WeatherRevision',(RS:GetAttribute('WeatherRevision') or 0)+1)
 return Service.Status()
end
function Service.Status() return {State=kind,EndsAt=deadline,Intensity=current.Rain,Darkness=current.Darkness} end
local function nextPhase()
 if kind=='Clear' then
  pending=Service.ChooseWetWeather();Service.SetWeather('Cloudy')
 elseif kind=='Cloudy' then Service.SetWeather(pending or Service.ChooseWetWeather())
 elseif kind=='Rain' and rng:NextNumber()<.25 then Service.SetWeather('Storm')
 elseif kind=='Rain' or kind=='Storm' then Service.SetWeather('Clearing')
 else Service.SetWeather('Clear') end
end
function Service.Start()
 if initialized then return end;initialized=true
 Service.SetWeather('Clear',seconds(Settings.ClearSeconds),.1)
 task.spawn(function()
  while true do
   local now=workspace:GetServerTimeNow()
   if now>=deadline then nextPhase() end
   local t=math.clamp((now-started)/math.max(.01,transition),0,1);t=t*t*(3-2*t)
   for key,value in pairs(target) do
    current[key]=typeof(value)=='number' and from[key]+(value-from[key])*t or from[key]:Lerp(value,t)
   end
   local raining=current.Rain>.03
   if RS:GetAttribute('BrightHavenRaining')~=raining then
    RS:SetAttribute('BrightHavenRaining',raining);RS.WeatherEvent:FireAllClients(raining,kind)
   end
   RS:SetAttribute('WeatherIntensity',current.Rain);RS:SetAttribute('WeatherDarkness',current.Darkness)
   workspace.GlobalWind=current.Wind
   if clouds then clouds.Cover=current.Cover;clouds.Density=current.Density;clouds.Color=current.CloudColor end
   if kind=='Storm' and now>=nextThunder then
    RS:SetAttribute('WeatherLightningSerial',(RS:GetAttribute('WeatherLightningSerial') or 0)+1)
    nextThunder=now+rng:NextNumber(10,20)
   end
   task.wait(.25)
  end
 end)
end
return Service
