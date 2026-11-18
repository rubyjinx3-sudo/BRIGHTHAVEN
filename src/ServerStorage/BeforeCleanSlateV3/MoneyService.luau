local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local Money={StartingCoins=20,Fare=10}
local wallets,loading,locks={},{},{}
local store=not RunService:IsStudio() and game:GetService("DataStoreService"):GetDataStore("CoinsData") or nil
function Money.Normalize(saved)
    if type(saved)~="table" then
        local old=type(saved)=="number" and saved==saved and math.clamp(math.floor(saved),0,1000000000) or Money.StartingCoins
        return {Version=2,Balance=old,Receipts={},LegacySchoolImported=false}
    end
    local balance=tonumber(saved.Balance) or 0
    return {Version=2,Balance=balance==balance and math.clamp(math.floor(balance),0,1000000000) or 0,
        Receipts=type(saved.Receipts)=="table" and table.clone(saved.Receipts) or {},LegacySchoolImported=saved.LegacySchoolImported==true}
end
local function publish(player,wallet)
    wallets[player]=wallet
    if not player.Parent then return end
    local stats=player:FindFirstChild("leaderstats")
    if not stats then stats=Instance.new("Folder");stats.Name="leaderstats";stats.Parent=player end
    local value=stats:FindFirstChild("Coins")
    if not value then value=Instance.new("IntValue");value.Name="Coins";value.Parent=stats end
    value.Value=wallet.Balance
    player:SetAttribute("Coins",wallet.Balance);player:SetAttribute("WalletReady",true)
end
function Money.Bind(player)
    if wallets[player] then return true end
    if loading[player] then
        repeat task.wait(.05) until not loading[player] or not player.Parent
        return wallets[player]~=nil
    end
    loading[player]=true;player:SetAttribute("WalletReady",false)
    local ok,wallet=true,Money.Normalize(nil)
    if store then
        for attempt=1,3 do
            ok,wallet=pcall(function() return store:UpdateAsync(tostring(player.UserId),Money.Normalize) end)
            if ok then break end
            task.wait(attempt*.5)
        end
    end
    if ok and player.Parent then publish(player,wallet) end
    loading[player]=nil
    if not ok then warn("[BrightHaven Wallet] Load failed; saved coins were not overwritten.") end
    return ok and wallets[player]~=nil
end
function Money.Balance(player)
    if not Money.Bind(player) then return nil end
    return wallets[player].Balance
end
-- One atomic, server-issued transaction for each fare or reward.
function Money.Change(player,delta,receipt,importSchool,partialFee)
    if type(delta)~="number" or delta~=delta or delta%1~=0 or math.abs(delta)>1000000 or type(receipt)~="string" or #receipt>100 then
        return false,"That coin amount is not valid."
    end
    if not Money.Bind(player) then return false,"Your coins are still loading. Please try again." end
    if wallets[player].Receipts[receipt] or (importSchool and wallets[player].LegacySchoolImported) then return true,"",false end
    while locks[player] and player.Parent do task.wait(.05) end
    if not player.Parent then return false,"Player left." end
    locks[player]=true
    local message,applied,charged="",false,0
    local function update(saved)
        local wallet=Money.Normalize(saved)
        applied=false
        if wallet.Receipts[receipt] or (importSchool and wallet.LegacySchoolImported) then return wallet end
        local amount=partialFee and delta<0 and -math.min(wallet.Balance,-delta) or delta
        if wallet.Balance+amount<0 then message="You do not have enough coins.";return wallet end
        wallet.Balance=math.clamp(wallet.Balance+amount,0,1000000000)
        charged=math.max(0,-amount)
        wallet.Receipts[receipt]=os.time()
        if importSchool then wallet.LegacySchoolImported=true end
        local disposable={}
        for id,time in pairs(wallet.Receipts) do
            if id:sub(1,7)=="market:" or id:sub(1,5)=="ride:" or id:sub(1,7)=="school:" or id:sub(1,4)=="bag:" or id:sub(1,7)=="clinic:" then table.insert(disposable,{Id=id,Time=time}) end
        end
        if #disposable>256 then
            table.sort(disposable,function(a,b) return a.Time<b.Time end)
            for i=1,#disposable-256 do wallet.Receipts[disposable[i].Id]=nil end
        end
        applied=true;return wallet
    end
    local ok,wallet=true,nil
    if store then
        for attempt=1,3 do
            message=""
            ok,wallet=pcall(function() return store:UpdateAsync(tostring(player.UserId),update) end)
            if ok then break end
            task.wait(attempt*.5)
        end
    else wallet=update(wallets[player]) end
    if ok then publish(player,wallet) end
    locks[player]=nil
    if not ok then return false,"Your coins could not be saved. Please try again." end
    return message=="",message,applied,charged
end
function Money.HasReceipt(player,receipt)
    return Money.Bind(player) and wallets[player].Receipts[receipt]~=nil
end
function Money.ClinicFee(player,receipt)
    return Money.Change(player,-5,receipt,false,true)
end
function Money.ImportSchool(player,profile)
    local old=not profile.WalletMirrored and math.max(0,math.floor(profile.Coins or 0)) or 0
    local ok=Money.Change(player,old,"legacy-school",true)
    if ok then profile.Coins=Money.Balance(player);profile.WalletMirrored=true end
    return ok
end
Players.PlayerAdded:Connect(function(player) task.spawn(Money.Bind,player) end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(Money.Bind,player) end
Players.PlayerRemoving:Connect(function(player)
    task.delay(5,function() wallets[player],loading[player],locks[player]=nil,nil,nil end)
end)
return Money

