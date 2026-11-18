local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Catalog=require(RS.Brighthaven.ItemCatalog)
local Rules=require(RS.Brighthaven.BagRules)
local Money=require(script.Parent.MoneyService)
local Service={}
local cache,loading,locks={},{},{}
local store=not game:GetService("RunService"):IsStudio() and game:GetService("DataStoreService"):GetDataStore("BrightHaven_Bag_v1") or nil
local changed=RS.Brighthaven.PlayerCare.BagChanged
local function initial(saved)
    local bag=Rules.Normalize(saved)
    bag.Receipts.starter=true
    return bag
end
local function publish(player,bag)
    cache[player]=bag
    if player.Parent then
        player:SetAttribute("BagReady",true)
        changed:FireClient(player,bag)
    end
end
function Service.Bind(player)
    if cache[player] then return true end
    if loading[player] then repeat task.wait(.05) until not loading[player] or not player.Parent;return cache[player]~=nil end
    loading[player]=true;player:SetAttribute("BagReady",false)
    local ok,bag=true,initial(nil)
    if store then
        for attempt=1,3 do
            ok,bag=pcall(function() return store:UpdateAsync(tostring(player.UserId),initial) end)
            if ok then break end;task.wait(attempt*.5)
        end
    end
    if ok and player.Parent then publish(player,bag) end
    loading[player]=nil
    return cache[player]~=nil
end
function Service.Snapshot(player)
    return Service.Bind(player) and Rules.Normalize(cache[player]) or nil
end
local function transact(player,callback)
    if not Service.Bind(player) then return false,"Your bag is still loading." end
    while locks[player] and player.Parent do task.wait(.05) end
    if not player.Parent then return false,"Player left." end
    locks[player]=true
    local accepted=false
    local receipt="op:"..game:GetService("HttpService"):GenerateGUID(false)
    local function update(saved)
        local bag=initial(saved)
        if bag.Receipts[receipt] then accepted=true;return bag end
        accepted=callback(bag)==true
        if accepted then
            bag.Receipts[receipt]=true
            local operations={}
            for id in pairs(bag.Receipts) do if id:sub(1,3)=="op:" and id~=receipt then table.insert(operations,id) end end
            for i=1,math.max(0,#operations-127) do bag.Receipts[operations[i]]=nil end
        end
        return bag
    end
    local ok,bag=true,nil
    if store then
        for attempt=1,3 do
            ok,bag=pcall(function() return store:UpdateAsync(tostring(player.UserId),update) end)
            if ok then break end;task.wait(attempt*.5)
        end
    else bag=update(cache[player]) end
    if ok then publish(player,bag) end
    locks[player]=nil
    return ok and accepted,not ok and "Your bag could not be saved. Please try again." or not accepted and "Your bag changed. Choose the item again." or ""
end
function Service.GrantOnce(player,receipt,items)
    if not Service.Bind(player) then return false end
    if cache[player].Receipts[receipt] then return true end
    return transact(player,function(bag)
        if bag.Receipts[receipt] then return true end
        for id,count in pairs(items) do if not Rules.Add(bag,id,count,true) then return false end end
        bag.Receipts[receipt]=true;return true
    end)
end
function Service.Take(player,index,id) return transact(player,function(bag) return Rules.Take(bag,index,id) end) end
function Service.Swap(player,a,b) return transact(player,function(bag) return Rules.Swap(bag,a,b) end) end
function Service.Claim(player) return transact(player,function(bag) Rules.Claim(bag);return true end) end
function Service.Install(player,id)
    if not Service.Bind(player) then return false end
    if cache[player].Receipts["installed:"..id] then return true end
    return transact(player,function(bag)
        for i=1,7 do local s=bag.Slots[tostring(i)];if s.Id==id then s.Id="";s.Count=0 end end
        bag.Pending[id]=nil;bag.Receipts["installed:"..id]=true;Rules.Claim(bag);return true
    end)
end
function Service.Buy(player,id)
    local price=Catalog.Shop[id]
    local bag=Service.Snapshot(player)
    if not price or not bag or not Rules.Add(bag,id,1,false) then return false,"Your bag is full. Use a supply first." end
    local receipt="bag:"..game:GetService("HttpService"):GenerateGUID(false)
    local paid,message=Money.Change(player,-price,receipt)
    if not paid then return false,message end
    local ok,text=transact(player,function(saved) return Rules.Add(saved,id,1,false) end)
    if not ok then
        local refunded=Money.Change(player,price,receipt..":refund")
        return false,refunded and "No space in your bag. Your coins were returned." or "The purchase could not finish. Please rejoin."
    end
    return true,"Added "..Catalog.ById[id].Name.." to your bag."
end
Players.PlayerRemoving:Connect(function(player)
    task.delay(5,function() cache[player],locks[player],loading[player]=nil,nil,nil end)
end)
return Service
