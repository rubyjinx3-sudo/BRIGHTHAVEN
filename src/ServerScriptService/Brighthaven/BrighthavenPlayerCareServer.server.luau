local Players=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local Practice=require(RS.Brighthaven.TutorialPractice)
local Bag=require(script.Parent.InventoryService)
local Care=require(script.Parent.SurvivalService)
local request=RS.Brighthaven.PlayerCare.Request
local catalog=require(RS.Brighthaven.ItemCatalog)
local busy,limits={},{}
local stores=workspace.BrighthavenFilipinoNeighborhood
local function shopNear(player)
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    for _,model in ipairs(stores:GetChildren()) do
        local anchor=model:FindFirstChild("BagShop",true)
        if anchor and (anchor.Parent.Position-root.Position).Magnitude<18 then return true end
    end
    return false
end
request.OnServerInvoke=function(player,action,payload)
    local now=os.clock()
    if busy[player] or now-(limits[player] or 0)<.18 then return {Ok=false,Message="One moment!"} end
    limits[player]=now;busy[player]=true
    local ok,result=pcall(function()
        payload=type(payload)=="table" and payload or {}
        local accepted,message=false,"Choose an item in your bag."
        if action=="Get" then accepted=true;message="Your bag is ready."
        elseif not Practice.CanUseWorld(player) then message="Save your supplies for the main world."
        elseif action=="Use" and type(payload.Id)=="string" and type(payload.Slot)=="number" then accepted,message=Care.Use(player,payload.Slot,payload.Id)
        elseif action=="Swap" then accepted,message=Bag.Swap(player,payload.From,payload.To)
        elseif action=="Claim" then accepted,message=Bag.Claim(player)
        elseif action=="Buy" and catalog.Shop[payload.Id] and shopNear(player) then accepted,message=Bag.Buy(player,payload.Id)
        else message="Walk to a sari-sari store to buy supplies." end
        return {Ok=accepted,Message=message,Bag=Bag.Snapshot(player)}
    end)
    busy[player]=nil
    if not ok then warn("[BrightHaven Bag] Request failed",result);return {Ok=false,Message="Your bag could not open. Please try again."} end
    return result
end
Players.PlayerRemoving:Connect(function(p) busy[p],limits[p]=nil,nil end)
