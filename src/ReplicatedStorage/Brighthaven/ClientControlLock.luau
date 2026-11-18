local CAS=game:GetService('ContextActionService')
local player=game.Players.LocalPlayer
local Lock={}
function Lock.New(humanoid,key)
 local object={};local saved,native,locked
 local module=player.PlayerScripts:FindFirstChild('PlayerModule')
 if module and module:IsA('ModuleScript') then local ok,value=pcall(function() return require(module):GetControls() end);if ok then native=value end end
 function object:Disable()
  if locked then return end;locked=true
  saved={WalkSpeed=humanoid.WalkSpeed,JumpPower=humanoid.JumpPower,JumpHeight=humanoid.JumpHeight}
  if native then native:Disable() end
  humanoid.WalkSpeed=0;humanoid.JumpPower=0;humanoid.JumpHeight=0
  CAS:BindActionAtPriority(key,function() return Enum.ContextActionResult.Sink end,false,3000,
   Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Space,
   Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,
   Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA)
 end
 function object:Enable()
  if not locked then return end;locked=false
  CAS:UnbindAction(key)
  if humanoid.Parent then humanoid.WalkSpeed=saved.WalkSpeed;humanoid.JumpPower=saved.JumpPower;humanoid.JumpHeight=saved.JumpHeight end
  if native then native:Enable() end
 end
 return object
end
return Lock
