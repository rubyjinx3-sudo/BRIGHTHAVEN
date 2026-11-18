local RS=game.ReplicatedStorage
local Math=require(RS.Brighthaven.Campaign.ChunkingMath)
local Money=require(game.ServerScriptService.Brighthaven.MoneyService)
local Clock=require(game.ServerScriptService.Brighthaven.TownClock)
local request=RS.Brighthaven.Supermarket.Request
local stations=workspace.BrightHavenSupermarket.SupermarketStations
local states,limits={},{ }
local function clearCargo(p)
 for _,bag in ipairs({p.Character,p:FindFirstChild('Backpack')}) do if bag then local t=bag:FindFirstChild('MarketCargo');if t then t:Destroy() end end end
end
local function cargo(p,text)
 clearCargo(p);local t=Instance.new('Tool');t.Name='MarketCargo';t.ToolTip=text;t.CanBeDropped=false
 local h=Instance.new('Part');h.Name='Handle';h.Size=Vector3.new(1.7,1.2,1.4);h.Color=Color3.fromRGB(187,139,76);h.Material=Enum.Material.Cardboard;h.CanCollide=false;h.Massless=true;h.Parent=t
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.Parent=h
 local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(1,1);l.Text=text;l.TextScaled=true;l.BackgroundColor3=Color3.fromRGB(255,235,179);l.Parent=g
 t.Parent=p.Backpack;p.Character.Humanoid:EquipTool(t)
end
local function near(p,name,branch)
 local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart');local b=branch or states[p] and states[p].Branch or 'Main';local group=b=='Main' and stations or workspace.BrightHavenMarketBranches:FindFirstChild(b);local s=group and group:FindFirstChild(name)
 return r and s and (r.Position-s.Position).Magnitude<=13
end
local function respond(s,ok,message) return {Ok=ok,Message=message,State=s} end
local function use(p,action,payload)
 local s=states[p]
 if action=='Get' then return respond(s,true,'Receive stock at Sari-Sari Supermart to start a shift.') end
 if not Clock.Eligible(p) or p:GetAttribute('Sleeping') or p:GetAttribute('HomeInteriorActive') or Clock.IsCurfew(Clock.Minutes) then clearCargo(p);return respond(s,false,'Return to work after your morning rest.') end
 if action=='Receiving' then
  local branch=type(payload.Branch)=='string' and payload.Branch or s and s.Branch or 'Main'
  if not near(p,'Receiving',branch) then return respond(s,false,'Visit the receiving counter.') end
  if not s or s.Phase=='done' then
   s={Branch=branch,Id=game.HttpService:GenerateGUID(false),Phase='plan',Math=Math.New(18,2),Stocks={0,0,0},Customers=0,Sales=0};states[p]=s
   return respond(s,true,'Share 18 products equally among 3 aisles. Start with a small chunk.')
  elseif s.Branch~=branch then return respond(s,false,'Finish the shift at the store where you started.')
  elseif s.Phase=='stock' and not s.Carry then
   s.Carry=true;cargo(p,s.Chunk..' items / aisle');return respond(s,true,'Carry one equal chunk to each of the three marked aisles.')
  end
  return respond(s,true,'Your shift is in progress.')
 end
 if not s then return respond(nil,false,'Start a shift at Receiving.') end
 if action=='choose' or action=='multiply' or action=='subtract' then
  if s.Phase~='plan' or not near(p,'Receiving') then return respond(s,false,'Plan the next batch at Receiving.') end
  local ok,message
  if action=='choose' then ok,message=Math.Choose(s.Math,3,payload.Number)
  else
   local pending=s.Math.PendingChunk;local q=pending and pending.Quotient
   local committed;ok,message,committed=Math.Step(s.Math,3,action,payload.Number,payload.Token)
   if committed then
    s.Phase='stock';s.Chunk=q;s.Delivered={};s.Carry=true;cargo(p,q..' items / aisle')
    message='Batch planned! Walk to each aisle and stock the same chunk.'
   end
  end
  return respond(s,ok,message)
 elseif action:match('^Shelf[123]$') then
  if s.Phase~='stock' or not s.Carry or not near(p,action) then return respond(s,false,'Collect your carton, then walk to an aisle.') end
  local index=tonumber(action:sub(-1));if s.Delivered[tostring(index)] then return respond(s,false,'This aisle already received its chunk. Stock another aisle.') end
  s.Delivered[tostring(index)]=true;s.Stocks[index]+=s.Chunk
  local n=0;for _ in pairs(s.Delivered) do n+=1 end
  if n==3 then clearCargo(p);s.Carry=false;s.Phase=s.Math.Remaining==0 and 'customers' or 'plan' end
  return respond(s,true,n==3 and (s.Phase=='customers' and 'Shelves are stocked! Collect the first customer basket, then take it to checkout.' or 'Fair round complete. Return to Receiving for your next chunk.') or 'Aisle stocked! Keep each aisle equal.')
 elseif action:match('^Customer[123]$') then
  local i=tonumber(action:sub(-1))
  if s.Phase~='customers' or i~=s.Customers+1 or not near(p,action) then return respond(s,false,'Serve the next waiting customer in order.') end
  s.Phase='basket';s.Customer=i;s.Quantity=2+i;s.UnitPrice=2+i;s.Basket=true;cargo(p,'Customer '..i..' basket');return respond(s,true,'Take the basket to Checkout. Count the items at their unit price.')
 elseif action=='Checkout' then
  if not near(p,'Checkout') or s.Phase~='basket' then return respond(s,false,'Collect the next customer basket first.') end
  s.Phase='scan';return respond(s,true,'Scan '..s.Quantity..' items at '..s.UnitPrice..' coins each. What is the total?')
 elseif action=='total' then
  if not near(p,'Checkout') or s.Phase~='scan' then return respond(s,false,'Scan the basket at Checkout first.') end
  if tonumber(payload.Number)~=s.Quantity*s.UnitPrice then return respond(s,false,'Count equal groups: items × price. Try again.') end
  local receipt='market:'..s.Id..':'..s.Customer
  local ok,message=Money.Change(p,8,receipt);if not ok then return respond(s,false,message) end
  s.Customers+=1;s.Sales+=8;s.Stocks[s.Customer]-=s.Quantity;s.Phase=s.Customers==3 and 'done' or 'customers';clearCargo(p)
  if s.Phase=='done' then p:SetAttribute('SupermarketShifts',(p:GetAttribute('SupermarketShifts') or 0)+1) end
  return respond(s,true,s.Phase=='done' and 'Shift complete! 24 coins earned. Use your wages to upgrade your own house.' or 'Customer served! 8 coins earned. Collect the next basket.')
 end
 return respond(s,false,'Use the current station.')
end
request.OnServerInvoke=function(p,action,payload)
 if type(action)~='string' or #action>30 or os.clock()-(limits[p] or 0)<.12 then return respond(states[p],false,'One action at a time.') end
 limits[p]=os.clock();local ok,result=pcall(use,p,action,type(payload)=='table' and payload or {})
 if not ok then warn('[Supermarket]',result);return respond(states[p],false,'Try the current station again.') end
 return result
end
local function bind(p)
 p.CharacterRemoving:Connect(function()
  local s=states[p];if not s then return end
  s.Carry=false
  if s.Phase=='basket' or s.Phase=='scan' then s.Phase='customers';s.Basket=nil end
 end)
end
game.Players.PlayerAdded:Connect(bind);for _,p in ipairs(game.Players:GetPlayers()) do bind(p) end
game.Players.PlayerRemoving:Connect(function(p) states[p]=nil;limits[p]=nil end)
