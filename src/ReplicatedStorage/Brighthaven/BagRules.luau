local Catalog=require(script.Parent.ItemCatalog)
local Rules={}
local function integer(value,max)
    return type(value)=="number" and value==value and value%1==0 and value>=0 and value<=max and value or nil
end
function Rules.Normalize(saved)
    local bag={Version=1,Slots={},Pending={},Receipts={}}
    for i=1,Catalog.SlotCount do
        local old=type(saved)=="table" and type(saved.Slots)=="table" and saved.Slots[tostring(i)]
        local item=type(old)=="table" and Catalog.ById[old.Id]
        bag.Slots[tostring(i)]=item and {Id=old.Id,Count=integer(old.Count,item.Stack) or 0} or {Id="",Count=0}
        if bag.Slots[tostring(i)].Count==0 then bag.Slots[tostring(i)].Id="" end
    end
    if type(saved)=="table" then
        for id,count in pairs(type(saved.Pending)=="table" and saved.Pending or {}) do
            if Catalog.ById[id] and integer(count,999) then bag.Pending[id]=count end
        end
        for id,done in pairs(type(saved.Receipts)=="table" and saved.Receipts or {}) do
            if type(id)=="string" and #id<=100 and done==true then bag.Receipts[id]=true end
        end
    end
    return bag
end
function Rules.Add(bag,id,amount,queue)
    local item=Catalog.ById[id]
    if not item or not integer(amount,99) or amount<1 then return false end
    local free=0
    for i=1,Catalog.SlotCount do local s=bag.Slots[tostring(i)];if s.Id==id then free+=item.Stack-s.Count elseif s.Id=="" then free+=item.Stack end end
    if free<amount and not queue then return false end
    local left=amount
    for pass=1,2 do for i=1,Catalog.SlotCount do
        local s=bag.Slots[tostring(i)]
        if (pass==1 and s.Id==id) or (pass==2 and s.Id=="") then
            local n=math.min(left,item.Stack-s.Count)
            if n>0 then s.Id=id;s.Count+=n;left-=n end
        end
    end end
    if left>0 then bag.Pending[id]=math.min(999,(bag.Pending[id] or 0)+left) end
    return true
end
function Rules.Claim(bag)
    for _,id in ipairs(Catalog.Order) do
        local count=bag.Pending[id] or 0
        while count>0 and Rules.Add(bag,id,1,false) do count-=1 end
        bag.Pending[id]=count>0 and count or nil
    end
end
function Rules.Take(bag,index,id)
    if not integer(index,Catalog.SlotCount) or index<1 then return false end
    local s=bag.Slots[tostring(index)]
    if s.Id~=id or s.Count<1 then return false end
    s.Count-=1;if s.Count==0 then s.Id="" end
    Rules.Claim(bag);return true
end
function Rules.Swap(bag,a,b)
    if not integer(a,Catalog.SlotCount) or not integer(b,Catalog.SlotCount) or a<1 or b<1 then return false end
    bag.Slots[tostring(a)],bag.Slots[tostring(b)]=bag.Slots[tostring(b)],bag.Slots[tostring(a)]
    return true
end
return Rules
