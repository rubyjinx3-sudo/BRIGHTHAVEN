local Players=game:GetService('Players')
local RunService=game:GetService('RunService')
local arena=workspace['Possible Map Replacement'].Tutorial.Tutorial_2:WaitForChild('LundagLavaCrater')
local lava=arena:WaitForChild('Lava')
local function burn(character)
 local player=Players:GetPlayerFromCharacter(character)
 local h=character:FindFirstChildOfClass('Humanoid')
 local root=character:FindFirstChild("HumanoidRootPart")
 if not player or not h or h.Health<=0 or not root or player:GetAttribute("Tutorial2LavaFall")
  or player:GetAttribute("Tutorial2ProblemResetPending") then return end
 if player:GetAttribute("Tutorial2Practice")=="active" or player:GetAttribute("Tutorial2Practice")=="complete" then
  player:SetAttribute("Tutorial2LavaFall",true)
  local wasAnchored=root.Anchored
  root.Anchored=true
  task.delay(1,function()
   if root.Parent then root.Anchored=wasAnchored end
   if player.Character~=character or not root.Parent or h.Health<=0 then return end
   local status=player:GetAttribute("Tutorial2Practice")
   if status~="active" and status~="complete" then
    player:SetAttribute("Tutorial2LavaFall",nil)
    return
   end
   local row=player:GetAttribute("Tutorial2Row") or 1
   local platform=({[2]=arena.RestIsland1,[3]=arena.RestIsland2,[4]=arena.FinishPlatform})[row]
   local destination=arena:GetAttribute("RespawnFrame")
   if platform then
    local position=platform.Position+Vector3.new(0,platform.Size.Y/2+3.5,0)
    destination=CFrame.lookAt(position,position+Vector3.zAxis)
   end
   character:PivotTo(destination)
   root.AssemblyLinearVelocity=Vector3.zero
   root.AssemblyAngularVelocity=Vector3.zero
   task.delay(.25,function() player:SetAttribute("Tutorial2LavaFall",nil) end)
  end)
  return
 end
 player:SetAttribute('Tutorial2LavaFall',true)
 h.Health=0
end
lava.Touched:Connect(function(hit)
 local character=hit:FindFirstAncestorOfClass("Model")
 if character then burn(character) end
end)
local elapsed=0
RunService.Heartbeat:Connect(function(dt)
 elapsed+=dt
 if elapsed<.1 then return end
 elapsed=0
 for _,player in Players:GetPlayers() do
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if root then
   local at=lava.CFrame:PointToObjectSpace(root.Position)
   if math.abs(at.X)<lava.Size.X/2 and math.abs(at.Z)<lava.Size.Z/2 and root.Position.Y<arena:GetAttribute("LavaSurfaceY")+2.1 then burn(character) end
  end
 end
end)
local function setup(player)
 player.CharacterAdded:Connect(function(character)
  if not player:GetAttribute("Tutorial2LavaFall") then return end
  local root=character:WaitForChild("HumanoidRootPart",10)
  task.wait(.65)
  if not root or player.Character~=character then return end
  character:PivotTo(arena:GetAttribute("RespawnFrame"))
  root.AssemblyLinearVelocity=Vector3.zero
  player:SetAttribute("Tutorial2LavaFall",nil)
 end)
end
Players.PlayerAdded:Connect(setup)
for _,player in Players:GetPlayers() do setup(player) end
