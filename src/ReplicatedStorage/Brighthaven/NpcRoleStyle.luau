local Style={Version=3}
local C,V= CFrame.new,Vector3.new
local colors={white=Color3.fromRGB(247,245,232),navy=Color3.fromRGB(35,57,88),teal=Color3.fromRGB(33,153,155),
 gold=Color3.fromRGB(247,193,52),orange=Color3.fromRGB(243,131,43),green=Color3.fromRGB(71,151,94),silver=Color3.fromRGB(213,227,226)}
function Style.Infer(model)
 local p=model:GetFullName();local n=model.Name:lower();local role=model:GetAttribute('NPCRole')
 if model:FindFirstChild('RiderHead') and model:FindFirstChild('RiderBody') then return 'Driver' end
 if role=='Scientist' or n:find('scientist') or p:find('BrighthavenStoryExtension.lab.',1,true) then return 'Scientist' end
 if role=='Student' then return 'Student' end
 if n:find('captainkappa') then return 'Captain' end
 if n:find('nurse') then return 'Nurse' end
 if n:find('reception') then return 'Clinic clerk' end
 if p:find('BrighthavenStoryExtension.clinic.',1,true) and n=='storyhelper' then return 'Nurse' end
 if p:find('BrighthavenStoryExtension.dumpsite.',1,true) and n=='storyhelper' then return 'Recycling worker' end
 if p:find('BrighthavenStoryExtension.wood.',1,true) and n=='storyhelper' then return 'Carpenter' end
 if p:find('BrighthavenStoryExtension.train.',1,true) and n=='storyhelper' then return 'Conductor' end
 if p:find('BrighthavenStoryExtension.power.',1,true) and n=='storyhelper' then return 'Electrician' end
 if p:find('BrighthavenStoryExtension.shop.',1,true) and n=='storyhelper' then return 'Vendor' end
 if n:find('driver') or model:GetAttribute('NPCRole')=='Driver' then return 'Driver' end
 if p:find('SariSariStore_',1,true) and model:FindFirstChildOfClass('Humanoid') then return 'Vendor' end
 if n=='evacuationvolunteer' or p:find('Tutorial_2.TutorialNPC2',1,true) then return 'Teacher' end
 if p:find('Tutorial_1.TutorialNPC1',1,true) then return 'Relief volunteer' end
 if p:find('WarehouseNPCTutorial',1,true) then return 'Warehouse worker' end
 if p:find('BrighthavenTownLife.Resident_1',1,true) then return 'Recycling worker' end
 return nil
end
function Style.Apply(model,role)
 role=role or Style.Infer(model);if not role then return false end
 local head=model:FindFirstChild('Head') or model:FindFirstChild('RiderHead');local torso=model:FindFirstChild('Torso') or model:FindFirstChild('UpperTorso') or model:FindFirstChild('RiderBody')
 if not head or not torso then return false end
 local old=model:FindFirstChild('RoleCostume');if old then old:Destroy() end
 local folder=Instance.new('Model');folder.Name='RoleCostume'
 local scale=torso.Size.Y/2
 local function part(name,anchor,cf,size,color)
  local p=Instance.new('Part');p.Name=name;p.Size=size*scale
  p.CFrame=anchor.CFrame*C(cf.Position*scale)*cf.Rotation;p.Color=color;p.Material=Enum.Material.Fabric
  p.Anchored=anchor.Anchored;p.Massless=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false
  p.Parent=folder
  local w=Instance.new('WeldConstraint');w.Part0=anchor;w.Part1=p;w.Parent=p
  return p
 end
 local function label(p,text,color)
  local gui=Instance.new('SurfaceGui');gui.Face=Enum.NormalId.Front;gui.CanvasSize=Vector2.new(320,160);gui.LightInfluence=.3;gui.Parent=p
  local t=Instance.new('TextLabel');t.Size=UDim2.fromScale(1,1);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=color or colors.navy;t.TextScaled=true;t.Font=Enum.Font.GothamBold;t.Parent=gui
 end
 local function front(name,x,y,w,h,col,z)
  return part(name,torso,C(x,y,-torso.Size.Z/scale/2-(z or .09)),V(w,h,.12),col)
 end
 local function badge(text,col)
  local p=front('RoleBadge',-.52,.35,.62,.54,col or colors.white,.19);label(p,text,colors.navy)
 end
 local function cap(col,helmet)
  local y=head.Size.Y/scale/2+.1
  local dome=part('HairRoleCap',head,C(0,y+.16,0),V(1.72,.5,1.6),col)
  dome.Material=Enum.Material.SmoothPlastic
  local brim=part('RoleHatBrim',head,C(0,y-.02,-.15),V(1.95,.12,1.9),col);brim.Material=Enum.Material.SmoothPlastic
  if helmet then part('HelmetRidge',head,C(0,y+.43,0),V(.18,.12,1.35),col:Lerp(colors.white,.25)) end
 end
 local variant=0
 for i=1,#model:GetFullName() do variant=(variant*31+model:GetFullName():byte(i))%997 end
 local top,pants=colors.white,colors.navy
 local apron=({Color3.fromRGB(155,68,58),Color3.fromRGB(43,103,112),Color3.fromRGB(119,67,124)})[variant%3+1]
 local teacher=({Color3.fromRGB(51,77,110),Color3.fromRGB(112,75,122),Color3.fromRGB(48,106,93)})[variant%3+1]
 if role=='Nurse' then top=colors.teal
 elseif role=='Driver' then top=Color3.fromRGB(65,128,180)
 elseif role=='Electrician' then top=Color3.fromRGB(48,101,170)
 elseif role=='Carpenter' then top=Color3.fromRGB(95,124,146)
 elseif role=='Recycling worker' then top=colors.green
 elseif role=='Warehouse worker' then top=Color3.fromRGB(67,105,145)
 elseif role=='Conductor' then top=colors.navy
 elseif role=='Vendor' then top=Color3.fromRGB(224,164,98);pants=Color3.fromRGB(77,74,74)
 elseif role=='Scientist' then top=colors.teal
 elseif role=='Captain' then top=Color3.fromRGB(240,227,192)
 end
 for _,x in ipairs(model:GetChildren()) do
  if x:IsA('BasePart') then
   if x==torso or x.Name=='LowerTorso' or x.Name:find('Arm') then x.Color=top end
   if x.Name:find('Leg') or x.Name:find('Foot') then x.Color=pants end
  end
 end
 for _,x in ipairs(model:GetChildren()) do if x:IsA('Shirt') or x:IsA('Pants') or x:IsA('ShirtGraphic') then x:Destroy() end end
 local body=model:FindFirstChildOfClass('BodyColors')
 if body then body.TorsoColor3=top;body.LeftArmColor3=top;body.RightArmColor3=top;body.LeftLegColor3=pants;body.RightLegColor3=pants end
 if role=='Scientist' then
  front('LeftCoat',-.64,-.35,.7,2.8,colors.white);front('RightCoat',.64,-.35,.7,2.8,colors.white)
  part('CoatBack',torso,C(0,-.35,torso.Size.Z/scale/2+.06),V(2.05,2.8,.1),colors.white)
  front('CoatLapelLeft',-.48,.65,.32,.8,colors.white,.18);front('CoatLapelRight',.48,.65,.32,.8,colors.white,.18)
  for _,side in ipairs({'Left Arm','Right Arm','LeftUpperArm','RightUpperArm'}) do local arm=model:FindFirstChild(side);if arm then arm.Color=colors.white end end
  local y=head.Size.Y/scale*.1
  for _,x in ipairs({-.4,.4}) do part('SafetyGoggles',head,C(x,y,-head.Size.Z/scale/2-.08),V(.68,.38,.12),Color3.fromRGB(81,188,207)).Material=Enum.Material.Glass end
  badge('LAB\nID')
 elseif role=='Nurse' then
  cap(colors.white,false);local p=part('NurseCapBadge',head,C(0,head.Size.Y/scale/2+.18,-.88),V(.5,.3,.08),colors.teal);label(p,'+',colors.white)
  front('ScrubPocket',.55,-.15,.48,.6,colors.teal:Lerp(colors.white,.15),.16);badge('NURSE')
 elseif role=='Electrician' or role=='Carpenter' or role=='Warehouse worker' or role=='Recycling worker' then
  local vest=({["Recycling worker"]=Color3.fromRGB(168,211,57),Carpenter=colors.orange,
      Electrician=colors.gold,["Warehouse worker"]=Color3.fromRGB(61,173,197)})[role]
  front('SafetyVestLeft',-.58,0,.72,1.9,vest);front('SafetyVestRight',.58,0,.72,1.9,vest)
  for _,y in ipairs({-.55,.5}) do front('ReflectiveStripe',0,y,1.97,.14,colors.silver,.17) end
  local helmet=({Carpenter=colors.orange,Electrician=colors.white,["Recycling worker"]=colors.gold,
      ["Warehouse worker"]=Color3.fromRGB(45,105,144)})[role]
  cap(helmet,true)
  front('UtilityBelt',0,-.82,2.05,.22,Color3.fromRGB(72,63,53),.2);badge(role=='Electrician' and 'POWER' or role=='Recycling worker' and 'ECO' or 'CREW')
 elseif role=='Conductor' then
  cap(colors.navy,false);front('GoldTrim',0,.7,1.95,.1,colors.gold,.16)
  front('UniformTie',0,.1,.22,1.2,colors.gold,.18);badge('RAIL',colors.gold)
 elseif role=='Captain' then
  for _,x in ipairs({-.2,0,.2}) do front('BarongEmbroidery',x,0,.04,1.75,Color3.fromRGB(220,195,139),.16) end
  for _,x in ipairs({-.8,.8}) do front('CaptainEpaulette',x,.83,.4,.18,colors.gold,.17) end
  front('FlagBlue',.56,.5,.54,.18,Color3.fromRGB(35,76,165),.19);front('FlagRed',.56,.3,.54,.18,Color3.fromRGB(206,63,66),.19)
  badge('BRGY\nCAPTAIN',colors.gold)
 elseif role=='Teacher' or role=='Student' or role=='Clinic clerk' then
  front('UniformVestLeft',-.67,0,.6,1.9,role=='Clinic clerk' and colors.teal or teacher)
  front('UniformVestRight',.67,0,.6,1.9,role=='Clinic clerk' and colors.teal or teacher)
  front('Tie',0,.24,.24,1.1,role=='Student' and colors.green or colors.gold,.18)
  badge(role=='Teacher' and 'TEACHER' or role=='Student' and 'SCHOOL' or 'CLINIC')
 elseif role=='Vendor' then
  front('VendorApron',0,-.35,1.65,2.6,apron);front('ApronPocket',0,-.65,1,.55,Color3.fromRGB(235,197,137),.18)
  front('ApronStrap',0,.8,.38,.5,apron,.17);badge('TINDAHAN')
 elseif role=='Driver' then
  if model:FindFirstChild('Helmet') then model.Helmet.Color=colors.navy else cap(colors.navy,false) end;front('DriverStripe',0,.4,1.95,.16,colors.gold,.16);badge('DRIVER')
 elseif role=='Relief volunteer' then
  front('VolunteerVest',0,0,1.9,1.9,colors.orange)
  local sash=front('ReliefSash',0,.08,.24,1.75,colors.white,.22)
  sash.CFrame*=CFrame.Angles(0,0,math.rad(-25))
  badge('RELIEF')
 end
 folder.Parent=model;model:SetAttribute('RoleCostumeVersion',Style.Version);model:SetAttribute('CostumeRole',role)
 return true
end
return Style
