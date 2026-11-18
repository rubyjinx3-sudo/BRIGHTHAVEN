local Rules={RainThreshold=120,SlowSpeed=10}
function Rules.IsTired(state) return state.Hunger<=0 or state.Thirst<=0 end
function Rules.New() return {Hunger=100,Thirst=100,Exposure=0,Sick=false,DamageTime=0} end
function Rules.Step(state,dt,context)
    if not context.Active then state.DamageTime=0;return 0 end
    dt=math.clamp(dt,0,2)
    local effort=context.Sprinting and 1.4 or 1
    state.Hunger=math.max(0,state.Hunger-dt*.065*effort)
    state.Thirst=math.max(0,state.Thirst-dt*.095*effort)
    local wet=context.Raining and not context.Sheltered and not context.Protected
    state.Exposure=math.clamp(state.Exposure+(wet and dt or -dt*3),0,180)
    if state.Exposure>=Rules.RainThreshold then state.Sick=true elseif state.Exposure==0 then state.Sick=false end
    local exposureDamage=wet and .05 or 0
    local sickDamage=state.Sick and wet and .25 or 0
    local needsDamage=Rules.IsTired(state) and .25 or 0
    local damaging=exposureDamage>0 or sickDamage>0 or needsDamage>0
    state.DamageTime=damaging and state.DamageTime+dt or 0
    if state.DamageTime>=1 then
        local seconds=math.floor(state.DamageTime);state.DamageTime-=seconds
        return seconds*(exposureDamage+sickDamage+needsDamage)
    end
    return 0
end
return Rules

