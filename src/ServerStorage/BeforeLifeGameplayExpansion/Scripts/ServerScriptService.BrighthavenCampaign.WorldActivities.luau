local Players=game:GetService("Players")
local Rules=require(game.ReplicatedStorage.Brighthaven.Campaign.ActivityRules)
local Sites=require(game.ReplicatedStorage.Brighthaven.Campaign.ActivitySites)
local Activities={}
local axes,cooldowns={},{}
local function root(player)
    local c=player.Character;local h=c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health>0 and c:FindFirstChild("HumanoidRootPart")
end
local function inZone(player,node)
    local r=root(player);local a=Sites.Resolve(player,node)
    local floor=a and a:FindFirstChild("ActivityFloor")
    return r and floor and (r.Position-floor.Position).Magnitude<=Rules.ZoneRadius
end
local function remove(player)
    if axes[player] then axes[player]:Destroy();axes[player]=nil end
end
local function equip(player)
    if axes[player] and axes[player].Parent then player.Character.Humanoid:EquipTool(axes[player]);return end
    local tool=Instance.new("Tool");tool.Name="Wood Area Axe";tool.CanBeDropped=false
    tool.ToolTip="Game axe - wood area only";tool:SetAttribute("BrighthavenActivityTool",true)
    local handle=Instance.new("Part");handle.Name="Handle";handle.Size=Vector3.new(.28,2.5,.28)
    handle.Color=Color3.fromRGB(143,100,62);handle.Material=Enum.Material.Wood;handle.CanCollide=false;handle.Massless=true;handle.Parent=tool
    local blade=Instance.new("Part");blade.Name="AxeHead";blade.Size=Vector3.new(1.3,.75,.28)
    blade.Color=Color3.fromRGB(199,214,221);blade.Material=Enum.Material.Metal;blade.CanCollide=false;blade.Massless=true
    blade.CFrame=handle.CFrame*CFrame.new(.35,.9,0);blade.Parent=tool
    local weld=Instance.new("WeldConstraint");weld.Part0,weld.Part1,weld.Parent=handle,blade,blade
    for _,v in tool:GetDescendants() do if v:IsA("BasePart") then v.CanTouch=false;v.CanQuery=false end end
    tool.Grip=CFrame.Angles(0,0,math.pi/2);tool.Parent=player.Backpack
    axes[player]=tool;player.Character.Humanoid:EquipTool(tool)
end
function Activities.Handle(player,action,payload,profile,Engine)
    local a=profile.Active
    if not a or a.Phase~="activity" or not a.Physical or not inZone(player,a.Node) then remove(player);return false,"Stay in this area's practice space. Talk to its helper to start." end
    if action=="ActivityEquip" then
        if a.Physical.Kind~="chop" then return false,"This activity does not use an axe." end
        equip(player);return true,"Axe ready! Stand by the stump and click to chop."
    end
    local r=root(player);local scene=Sites.Resolve(player,a.Node)
    if action=="ActivityChop" then
        local tool=axes[player];local log=scene:FindFirstChild("ChoppingLog")
        if a.Physical.Kind~="chop" or not tool or tool.Parent~=player.Character or not log or (r.Position-log.Position).Magnitude>9 then return false,"Equip the provided axe and stand closer to the stump." end
    elseif action=="ActivityShoot" then
        local mark=scene:FindFirstChild("ThrowMark")
        if a.Physical.Kind~="sort" or not mark or (r.Position-mark.Position).Magnitude>7 then return false,"Stand on the throwing spot to take your shot." end
    else return false,"Choose a helping action." end
    local now=os.clock();local delay=action=="ActivityChop" and Rules.ChopCooldown or Rules.ShotCooldown
    if now-(cooldowns[player] or 0)<delay then return false,"One action at a time!" end
    local shot
    if action=="ActivityShoot" then
        local bin=type(payload.Bin)=="string" and scene.SortingBins:FindFirstChild(payload.Bin)
        if not bin or not table.find(Rules.Bins,payload.Bin) then return false,"Choose a sorting bin." end
        shot=Rules.Shot(scene.ThrowMark.Position+Vector3.new(0,4,0),bin.HoopTarget.Position,payload.Power,workspace.Gravity)
        if not shot then return false,"Try your shot again." end
        shot.Item=a.Physical.Sequence[a.Physical.Count+1];shot.Bin=payload.Bin
    end
    cooldowns[player]=now
    local ok,message=Engine.ActivityStep(profile,a.Physical.Kind,payload.Bin,shot and shot.InHoop)
    if shot then shot.Success=ok end
    if a.Phase~="activity" then remove(player) end
    return ok,message,shot
end
Players.PlayerRemoving:Connect(function(p) remove(p);cooldowns[p]=nil end)
task.spawn(function()
    while true do
        task.wait(.25)
        for p,tool in pairs(axes) do
            if not inZone(p,"wood") or not tool.Parent or tool.Parent~=p.Character and tool.Parent~=p.Backpack then remove(p) end
        end
    end
end)
return Activities
