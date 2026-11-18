local Cutscene={}
local Players,Tween,RS,Lighting=game.Players,game.TweenService,game.ReplicatedStorage,game.Lighting
function Cutscene.Play()
 local player=Players.LocalPlayer;local camera=workspace.CurrentCamera
 local old={Type=camera.CameraType,Subject=camera.CameraSubject,CFrame=camera.CFrame,FOV=camera.FieldOfView,Clock=Lighting.ClockTime,Brightness=Lighting.Brightness,Ambient=Lighting.Ambient,Outdoor=Lighting.OutdoorAmbient,Exposure=Lighting.ExposureCompensation}
 local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart');local humanoid=character and character:FindFirstChildOfClass('Humanoid')
 if not root or not humanoid then return false,'Wait for your character to spawn.' end
 local motion={Anchored=root.Anchored,Walk=humanoid.WalkSpeed,Jump=humanoid.JumpPower,Rotate=humanoid.AutoRotate}
 local controls={Disable=function() root.AssemblyLinearVelocity=Vector3.zero;root.Anchored=true;humanoid.WalkSpeed=0;humanoid.JumpPower=0;humanoid.AutoRotate=false end,
 Enable=function() if root.Parent then root.Anchored=motion.Anchored end;if humanoid.Parent then humanoid.WalkSpeed=motion.Walk;humanoid.JumpPower=motion.Jump;humanoid.AutoRotate=motion.Rotate end end}
 local gui=Instance.new('ScreenGui');gui.Name='BrightHavenStormEnding';gui.IgnoreGuiInset=true;gui.DisplayOrder=300;gui.ResetOnSpawn=false;gui.Parent=player.PlayerGui
 local caption=Instance.new('TextLabel');caption.AnchorPoint=Vector2.new(.5,1);caption.Position=UDim2.fromScale(.5,.94);caption.Size=UDim2.fromScale(.82,.17);caption.BackgroundColor3=Color3.fromRGB(16,34,52);caption.BackgroundTransparency=.1;caption.TextColor3=Color3.new(1,1,1);caption.Font=Enum.Font.GothamBold;caption.TextSize=24;caption.TextWrapped=true;caption.Parent=gui
 local corner=Instance.new('UICorner');corner.Parent=caption
 local scene=Instance.new('Folder');scene.Name='LocalFinalStorm';scene.Parent=workspace
 local disabled={};for _,g in ipairs(player.PlayerGui:GetChildren()) do if g:IsA('ScreenGui') and g~=gui and g.Enabled then disabled[g]=true;g.Enabled=false end end
 local oldFlashback=player.PlayerGui:GetAttribute('FlashbackPlaying');player.PlayerGui:SetAttribute('FlashbackPlaying',true)
 local oldPrompt=game.ProximityPromptService.Enabled;game.ProximityPromptService.Enabled=false;controls:Disable();player:SetAttribute('BrighthavenFlashbackPlaying',true)
 local lab=workspace.BrighthavenStoryExtension.lab.HelperAnchor.Position
 local sky=lab+Vector3.new(-6,67,0);local clouds={};local cheers={}
 local function part(size,cf,color,shape)
  local p=Instance.new('Part');p.Size=size;p.CFrame=cf;p.Color=color;p.Shape=shape or Enum.PartType.Ball;p.Anchored=true;p.CanCollide=false;p.CanQuery=false;p.CanTouch=false;p.Material=Enum.Material.SmoothPlastic;p.Parent=scene;return p
 end
 local beam,connection
 local ok,err=xpcall(function()
  camera.CameraType=Enum.CameraType.Scriptable;camera.FieldOfView=64
  Lighting.Brightness=.4;Lighting.Ambient=Color3.fromRGB(45,51,70);Lighting.OutdoorAmbient=Color3.fromRGB(47,57,74);Lighting.ExposureCompensation=-.8;Lighting.ClockTime=18
  for ring=1,5 do for i=1,10 do local angle=i*math.pi/5;local radius=8+ring*7
   local p=part(Vector3.new(13+ring*3,8,13+ring*3),CFrame.new(sky+Vector3.new(math.cos(angle)*radius,ring*4,math.sin(angle)*radius)),Color3.fromRGB(35+ring*5,42+ring*5,58+ring*5));clouds[#clouds+1]={P=p,R=radius,A=angle,Y=ring*4,Size=p.Size}
  end end
  camera.CFrame=CFrame.lookAt(lab+Vector3.new(80,30,85),sky)
  caption.Text='The terrible storm gathers over BrightHaven.\nBut every equal share has helped the barangay prepare.'
  connection=game.RunService.RenderStepped:Connect(function(dt)
   for _,c in ipairs(clouds) do if c.P.Parent then c.A+=dt*(.25+25/c.R);c.P.Position=sky+Vector3.new(math.cos(c.A)*c.R,c.Y,math.sin(c.A)*c.R) end end
  end)
  task.wait(8)
  caption.Text='The relief crews, school deliveries and stocked shops are ready.\nYour reinforced home is safe. The Storm Breaker powers up!'
  Tween:Create(camera,TweenInfo.new(6),{CFrame=CFrame.lookAt(lab+Vector3.new(50,16,48),sky)}):Play()
  task.wait(8)
  beam=part(Vector3.new(4,(sky-lab).Magnitude,4),CFrame.lookAt((sky+lab)/2,sky)*CFrame.Angles(math.pi/2,0,0),Color3.fromRGB(118,239,255),Enum.PartType.Cylinder)
  beam.Size=Vector3.new((sky-lab).Magnitude,4,4);beam.CFrame=CFrame.lookAt((sky+lab)/2,sky)*CFrame.Angles(0,math.pi/2,0);beam.Material=Enum.Material.Neon
  caption.Text='Together, we can overcome the storm!\nThe light breaks through the dark clouds.'
  for _,c in ipairs(clouds) do Tween:Create(c.P,TweenInfo.new(7),{Transparency=1,Size=c.Size*.15}):Play() end
  Tween:Create(Lighting,TweenInfo.new(8),{Brightness=2,Ambient=Color3.fromRGB(145,149,160),OutdoorAmbient=Color3.fromRGB(173,179,184),ExposureCompensation=.1,ClockTime=9}):Play()
  task.wait(8);connection:Disconnect();beam:Destroy()
  local source=workspace.BrighthavenCommunity.Residents:GetChildren()
  for i=1,10 do
   local m=source[(i-1)%#source+1]:Clone();m.Name='CelebratingNeighbor'
   for _,p in ipairs(m:GetDescendants()) do if p:IsA('BaseScript') or p:IsA('ProximityPrompt') or p:IsA('BillboardGui') then p:Destroy() elseif p:IsA('BasePart') then p.Anchored=true;p.CanCollide=false;p.CanTouch=false end end
   m:PivotTo(CFrame.new(lab+Vector3.new(12+(i%5)*4,0,18+math.floor((i-1)/5)*5)));m.Parent=scene
   for _,arm in ipairs({'Left Arm','Right Arm'}) do local a=m:FindFirstChild(arm);if a then a.CFrame=a.CFrame*CFrame.Angles(0,0,arm=='Left Arm' and -.9 or .9)+Vector3.new(0,1,0) end end
   cheers[#cheers+1]=m
  end
  camera.CFrame=CFrame.lookAt(lab+Vector3.new(47,10,51),lab+Vector3.new(20,2,20))
  caption.Text='The storm dissolves. The sun returns, and the neighbors celebrate!\nBrightHaven is safe because you helped, one chunk at a time.'
  for i=1,55 do
   local p=part(Vector3.new(.2,.5,.15),CFrame.new(lab+Vector3.new(10+math.random()*26,17+math.random()*12,14+math.random()*15)),Color3.fromHSV(math.random(),.7,1),Enum.PartType.Block)
   Tween:Create(p,TweenInfo.new(7),{Position=p.Position-Vector3.new(0,19,0),Orientation=Vector3.new(180,math.random(360),180),Transparency=1}):Play()
  end
  task.wait(9)
 end,debug.traceback)
 if connection then connection:Disconnect() end
 scene:Destroy();gui:Destroy()
 camera.CameraType=old.Type;camera.CameraSubject=old.Subject;camera.CFrame=old.CFrame;camera.FieldOfView=old.FOV
 Lighting.ClockTime=old.Clock;Lighting.Brightness=old.Brightness;Lighting.Ambient=old.Ambient;Lighting.OutdoorAmbient=old.Outdoor;Lighting.ExposureCompensation=old.Exposure
 for g in pairs(disabled) do if g.Parent then g.Enabled=true end end
 player.PlayerGui:SetAttribute('FlashbackPlaying',oldFlashback);game.ProximityPromptService.Enabled=oldPrompt;controls:Enable();player:SetAttribute('BrighthavenFlashbackPlaying',false)
 if not ok then warn('[BrightHaven ending]',err) end
 return ok,err
end
return Cutscene
