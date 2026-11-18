local Rules={Required=6,ChopCooldown=.65,ShotCooldown=1.1,ZoneRadius=42}
Rules.Bins={"Paper","Plastic","Metal"}
function Rules.New(kind,random)
    local sequence={"Paper","Plastic","Metal","Paper","Plastic","Metal"}
    random=random or Random.new()
    for i=#sequence,2,-1 do local j=random:NextInteger(1,i);sequence[i],sequence[j]=sequence[j],sequence[i] end
    return {Kind=kind,Count=0,Sequence=sequence}
end
function Rules.Normalize(old,kind)
    local result=Rules.New(kind,Random.new(1))
    if type(old)~="table" or old.Kind~=kind then return result end
    local count=tonumber(old.Count) or 0
    if count~=count then count=0 end
    result.Count=math.clamp(count,0,Rules.Required)
    result.Count=math.floor(result.Count)
    if type(old.Sequence)=="table" and #old.Sequence==6 then
        local counts={Paper=0,Plastic=0,Metal=0}
        for _,value in old.Sequence do if counts[value]==nil then return result end;counts[value]+=1 end
        if counts.Paper==2 and counts.Plastic==2 and counts.Metal==2 then result.Sequence=table.clone(old.Sequence) end
    end
    return result
end
function Rules.Shot(origin,target,power,gravity)
    if typeof(origin)~="Vector3" or typeof(target)~="Vector3" or type(power)~="number" or power~=power or power<0 or power>1 then return nil end
    local flat=(target-origin)*Vector3.new(1,0,1)
    if flat.Magnitude<.1 then return nil end
    local landing=target+flat.Unit*((power-.75)*24)
    local duration=.7
    local velocity=(landing-origin)/duration+Vector3.new(0,gravity*duration/2,0)
    return {Origin=origin,Velocity=velocity,Duration=duration,Gravity=gravity,Landing=landing,InHoop=(landing-target).Magnitude<=2.2}
end
function Rules.Position(shot,time)
    return shot.Origin+shot.Velocity*time-Vector3.new(0,shot.Gravity*time*time/2,0)
end
return Rules
