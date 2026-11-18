local QuickPlay=require(game.ReplicatedStorage.Brighthaven.QuickPlaySettings)
local Math={}
local function integer(value,minimum,maximum)
    if type(value)~="number" and type(value)~="string" then return nil end
    local n=tonumber(value)
    return n and n==n and n%1==0 and n>=minimum and n<=maximum and n or nil
end
function Math.New(total,minimumChunks)
    return {Remaining=total,Quotient=0,Steps={},NextToken=0,Checked=false,MinimumChunks=minimumChunks or 1}
end
function Math.FactorHint(groups,chunk)
    for factor=10,2,-1 do
        if chunk>10 and chunk%factor==0 then
            local other=chunk/factor
            if other>1 then
                return chunk.." = "..other.." x "..factor..". These are factors: numbers we multiply. Work out "..groups.." x "..other..", then multiply by "..factor.."."
            end
        end
    end
    return "The factors are "..groups.." and "..chunk..": numbers we multiply. Count "..groups.." equal groups of "..chunk..". Skip counting can help!"
end
function Math.Choose(state,groups,number)
    if state.Checked or state.Remaining<groups then return false,"Finish checking your shares first." end
    if state.PendingChunk then return false,"Finish this chunk or choose Start Over." end
    local q=integer(number,1,1000)
    if not q then return false,"Choose a whole number that is at least 1." end
    if q*groups>state.Remaining then return false,"That chunk is too big for every group. Try a smaller chunk." end
    if (state.MinimumChunks or 1)>1 and #state.Steps==0 and state.Remaining-q*groups<groups then
        return false,"Practice two or more chunks. Start with a smaller equal amount, then share what is left."
    end
    state.NextToken=(state.NextToken or 0)+1
    state.PendingChunk={Quotient=q,Before=state.Remaining,Step="multiply",Token=state.NextToken}
    return true,"How many are in all the equal groups? Multiply to count this chunk."
end
function Math.Step(state,groups,action,number,token)
    local p=state.PendingChunk
    if not p or p.Token~=token or p.Before~=state.Remaining then return false,"Use the current step on your page." end
    if action=="cancel" then state.PendingChunk=nil;return true,"Choose a new chunk. Your finished shares are safe." end
    if action~=p.Step then return false,"Finish the step on your page first." end
    local n=integer(number,0,1000000)
    if not n then return false,"Type a whole number, then check." end
    local product=groups*p.Quotient
    if action=="multiply" then
        if n~=product then return false,"Count equal groups with your multiplication facts. Try again!" end
        p.Product=product;p.Step="subtract"
        return true,"Now subtract this chunk from the amount left."
    end
    if action~="subtract" or p.Product~=product then return false,"Check the multiplication first." end
    if n~=p.Before-product then return false,"Take away the whole chunk. How many are left?" end
    state.Quotient+=p.Quotient;state.Remaining=n
    table.insert(state.Steps,{Quotient=p.Quotient,Amount=product,Remaining=n})
    state.PendingChunk=nil
    return true,"Fair round! Every group gets "..p.Quotient.." more. "..n.." are left.",true
end
function Math.Check(state,total,groups,number)
    if state.PendingChunk or state.Remaining~=0 or #state.Steps<(state.MinimumChunks or 1) then return false,"Finish sharing your chunks first." end
    if integer(number,0,1000000)~=state.Quotient*groups or state.Quotient*groups~=total then
        return false,"Multiply one group's share by all the groups. Does it match the starting amount?"
    end
    state.Checked=true
    return true,"Equal shares! You checked every group."
end
function Math.Normalize(old,total,groups)
    local state=Math.New(total,QuickPlay.MinimumChunks)
    if type(old)~="table" then return state end
    for _,step in ipairs(type(old.Steps)=="table" and old.Steps or {}) do
        local q=type(step)=="table" and integer(step.Quotient,1,1000)
        if not q or q*groups>state.Remaining then break end
        state.Quotient+=q;state.Remaining-=q*groups
        table.insert(state.Steps,{Quotient=q,Amount=q*groups,Remaining=state.Remaining})
    end
    state.NextToken=integer(old.NextToken,0,1000000) or #state.Steps
    local pending=old.PendingChunk
    if type(pending)=="table" and state.Remaining>=groups and Math.Choose(state,groups,pending.Quotient) then
        if pending.Step=="subtract" and pending.Product==state.PendingChunk.Quotient*groups then
            state.PendingChunk.Product=pending.Product;state.PendingChunk.Step="subtract"
        end
    end
    state.Checked=old.Checked==true and state.Remaining==0 and state.Quotient*groups==total and #state.Steps>=state.MinimumChunks
    return state
end
return Math
