local B={}
local V,C,A=Vector3.new,CFrame.new,CFrame.Angles
local M=Enum.Material
B.Colors={cream=Color3.fromRGB(255,241,211),ink=Color3.fromRGB(35,66,69),teal=Color3.fromRGB(44,143,141),coral=Color3.fromRGB(225,105,85),gold=Color3.fromRGB(246,190,65),blue=Color3.fromRGB(86,159,190),green=Color3.fromRGB(75,135,82),wood=Color3.fromRGB(143,96,61),pave=Color3.fromRGB(215,203,180)}
local P=B.Colors
function B.model(parent,name)
 local m=Instance.new('Model');m.Name=name;m.Parent=parent;return m
end
function B.part(parent,name,cf,size,col,mat,shape,collide)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=col or P.cream;p.Material=mat or M.SmoothPlastic;p.Anchored=true;p.CanCollide=collide~=false;p.CanTouch=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape then p.Shape=shape end
 if shape==Enum.PartType.Ball and math.max(size.X,size.Y,size.Z)>math.min(size.X,size.Y,size.Z)*2 then p.Shape=Enum.PartType.Block;local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p end
 p.Parent=parent;return p
end
local part=B.part
function B.sign(parent,cf,size,text,color,fg)
 local p=part(parent,'Sign_'..text:sub(1,18),cf,size,color or P.ink,nil,nil,false)
 local g=Instance.new('SurfaceGui');g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(math.max(360,size.X*32),math.max(100,size.Y*32));g.LightInfluence=.2;g.Parent=p
 local l=Instance.new('TextLabel');l.Size=UDim2.fromScale(.94,.88);l.Position=UDim2.fromScale(.03,.06);l.BackgroundTransparency=1;l.Text=text;l.TextColor3=fg or P.cream;l.Font=Enum.Font.GothamBold;l.TextScaled=true;l.TextWrapped=true;l.Parent=g;return p
end
function B.cylinder(parent,name,cf,diam,height,color,mat,collide)
 return part(parent,name,cf*A(0,0,math.pi/2),V(height,diam,diam),color,mat,Enum.PartType.Cylinder,collide)
end
function B.line(parent,name,a,b,width,col,mat)
 return part(parent,name,C((a+b)/2,b),V(width,width,(b-a).Magnitude),col,mat,nil,false)
end
function B.roof(m,cf,w,d,y,col)
 local angle=math.rad(21);local half=(d/2+2)/math.cos(angle)
 for _,s in ipairs({-1,1}) do
  local r=cf*C(0,y+(d/4+1)*math.tan(angle),s*(d/4+1))*A(s*angle,0,0)
  part(m,'PitchedRoof',r,V(w+4,.6,half),col,M.Metal)
  for x=-w/2-1,w/2+1,2.5 do part(m,'RoofSeam',r*C(x,.34,0),V(.08,.1,half),col:Lerp(P.cream,.2),M.Metal,nil,false) end
 end
 part(m,'RoofRidge',cf*C(0,y+(d/2+2)*math.tan(angle)+.15,0),V(w+4,.6,.65),col,M.Metal,nil,false)
end
function B.window(m,cf,w,h)
 part(m,'WindowFrame',cf,V(w+.45,h+.45,.32),P.cream)
 part(m,'BlueGlass',cf*C(0,0,-.19),V(w,h,.12),Color3.fromRGB(104,181,198),M.Glass,nil,false)
 part(m,'WindowMullion',cf*C(0,0,-.3),V(.16,h,.12),P.cream,nil,nil,false)
end
function B.shell(root,name,cf,w,d,h,col,roof,title)
 local m=B.model(root,name);m:SetAttribute('Landmark',title);m:SetAttribute('Entrance',cf:PointToWorldSpace(V(0,1,-d/2-4)))
 part(m,'Foundation',cf*C(0,.4,0),V(w+2,.8,d+2),P.pave,M.Concrete)
 part(m,'Floor',cf*C(0,.9,0),V(w,.25,d),P.cream,M.WoodPlanks)
 part(m,'BackWall',cf*C(0,h/2+.8,d/2),V(w,h,.6),col,M.Concrete)
 for _,s in ipairs({-1,1}) do
  part(m,'SideWall',cf*C(s*w/2,h/2+.8,0),V(.6,h,d),col,M.Concrete)
  local panel=(w-8)/2
  part(m,'FrontWall',cf*C(s*(4+panel/2),h/2+.8,-d/2),V(panel,h,.6),col,M.Concrete)
  B.window(m,cf*C(s*w*.3,6,-d/2-.4),math.min(7,panel-2),5)
 end
 part(m,'DoorHeader',cf*C(0,h-1,-d/2),V(8,3,.65),col,M.Concrete)
 part(m,'FrontStep',cf*C(0,.35,-d/2-1.7),V(10,.7,3),P.pave,M.Concrete)
 part(m,'Skirting',cf*C(0,1.55,d/2+.4),V(w,1,.2),P.cream)
 B.roof(m,cf,w,d,h+1,roof)
 B.sign(m,cf*C(0,h-.7,-d/2-.55),V(w-3,2.5,.2),title,P.ink)
 return m
end
function B.bench(parent,cf,width)
 width=width or 7
 for _,s in ipairs({-1,1}) do part(parent,'BenchLeg',cf*C(s*(width/2-.7),.8,0),V(.35,1.6,2),P.ink,M.Metal) end
 for i=1,3 do part(parent,'WoodSeatSlat',cf*C(0,1.7,(i-2)*.58),V(width,.25,.5),P.wood,M.WoodPlanks) end
 for i=1,2 do part(parent,'BackSlat',cf*C(0,2.4+i*.48,.9),V(width,.35,.2),P.wood,M.WoodPlanks) end
 local s=Instance.new('Seat');s.Name='RestSeat';s.Size=V(width-1,.1,1.5);s.CFrame=cf*C(0,1.9,0);s.Anchored=true;s.Transparency=1;s.Parent=parent
end
function B.tree(parent,x,z,height,palm)
 local m=B.model(parent,palm and 'CoconutPalm' or 'ShadeTree');local cf=C(x,0,z)
 B.cylinder(m,'Trunk',cf*C(0,height/2,0),palm and 1.1 or 1.5,height,P.wood,M.Wood)
 if palm then
  for i=1,8 do local a=i*math.pi/4;local r=cf*C(0,height,0)*A(0,a,0)
   part(m,'PalmFrond',r*C(0,-.5,-3.6)*A(-.16,0,0),V(1.8,.45,8.5),P.green,M.Grass,Enum.PartType.Ball,false)
   part(m,'DroopingTip',r*C(0,-1.7,-7.7)*A(-.42,0,0),V(1,.25,4),P.green,M.Grass,Enum.PartType.Ball,false)
  end
  for i=1,3 do part(m,'Coconut',cf*C(math.cos(i*2)*.8,height-.5,math.sin(i*2)*.8),V(.9,1.1,.9),Color3.fromRGB(137,144,64),nil,Enum.PartType.Ball,false) end
 else
  for i=1,4 do local a=i*1.7;part(m,'RoundCanopy',cf*C(math.cos(a)*2,height-1+i*.55,math.sin(a)*2),V(9,7,9),i%2==0 and P.green or Color3.fromRGB(102,154,86),M.Grass,Enum.PartType.Ball,false) end
 end
 return m
end
function B.planter(parent,cf,w)
 part(parent,'Planter',cf*C(0,.6,0),V(w,1.2,3),P.cream,M.Concrete)
 part(parent,'Soil',cf*C(0,1.25,0),V(w-.4,.1,2.6),P.wood,M.Ground,nil,false)
 for x=-w/2+1,w/2-1,1.7 do
  part(parent,'Shrub',cf*C(x,1.8,0),V(1.6,1.6,2),P.green,M.Grass,Enum.PartType.Ball,false)
  part(parent,'Bougainvillea',cf*C(x,2.6,.1),V(1.2,1.2,1.4),Color3.fromRGB(224,97,139),nil,Enum.PartType.Ball,false)
 end
end
function B.lamp(parent,x,z)
 local cf=C(x,0,z);B.cylinder(parent,'LampBase',cf*C(0,.25,0),1.8,.5,P.ink,M.Metal)
 B.cylinder(parent,'LampPole',cf*C(0,6.3,0),.35,12.3,P.ink,M.Metal)
 part(parent,'LampArm',cf*C(0,12.5,-1.3),V(.25,.25,3),P.ink,M.Metal)
 local p=part(parent,'WarmLantern',cf*C(0,12,-2.6),V(1.3,1.3,1.3),P.gold,M.Neon,nil,false)
 local l=Instance.new('PointLight');l.Color=Color3.fromRGB(255,219,147);l.Range=23;l.Brightness=1.25;l.Shadows=false;l.Parent=p
 part(parent,'LanternCap',cf*C(0,12.8,-2.6),V(1.8,.25,1.8),P.ink,M.Metal,nil,false)
end
function B.prompt(parent,action,name,id)
 local p=Instance.new('ProximityPrompt');p.ActionText=action;p.ObjectText=name;p.HoldDuration=0;p.MaxActivationDistance=11;p.RequiresLineOfSight=false;p:SetAttribute('CompactAction',id);p.Parent=parent;return p
end
function B.npc(parent,cf,name,shirt,id,greeting)
 local n=B.model(parent,name:gsub(' ',''));n:SetAttribute('Greeting',greeting)
 local skin=Color3.fromRGB(185,135,92)
 part(n,'Torso',cf*C(0,3.1,0),V(2,2.1,1),shirt,nil,nil,false)
 for _,s in ipairs({-1,1}) do
  part(n,'Arm',cf*C(s*1.45,3.1,0),V(.8,2.1,.8),skin,nil,nil,false)
  part(n,'Leg',cf*C(s*.55,1.2,0),V(.9,2.1,.9),P.ink,nil,nil,false)
 end
 local head=part(n,'Head',cf*C(0,4.9,0),V(1.5,1.5,1.5),skin,nil,Enum.PartType.Ball,false)
 part(n,'Hair',cf*C(0,5.5,.1),V(1.6,.5,1.5),Color3.fromRGB(49,40,32),nil,Enum.PartType.Ball,false)
 for _,s in ipairs({-1,1}) do part(n,'Eye',cf*C(s*.28,5,-.7),V(.13,.16,.07),P.ink,nil,Enum.PartType.Ball,false) end
 part(n,'Smile',cf*C(0,4.6,-.72),V(.35,.09,.06),P.cream,nil,nil,false)
 B.sign(n,cf*C(0,6.6,0),V(8,1.4,.1),name,P.ink)
 B.prompt(head,'Talk',name,id or 'talk');return n
end
function B.infrastructure(root)
 local m=B.model(root,'StreetsAndLandscape')
 part(m,'TownGround',C(0,-2,0),V(420,4,380),Color3.fromRGB(117,154,91),M.Grass)
 for _,x in ipairs({-105,105}) do
  part(m,'LoopRoad',C(x,.08,0),V(20,.16,210),Color3.fromRGB(59,68,69),M.Asphalt)
  for _,s in ipairs({-1,1}) do part(m,'Sidewalk',C(x+s*14,.2,0),V(7,.4,216),P.pave,M.Concrete) end
  for z=-88,88,12 do part(m,'LaneDash',C(x,.18,z),V(.4,.03,5),P.gold,nil,nil,false) end
 end
 for _,z in ipairs({-95,95}) do
  part(m,'LoopRoad',C(0,.08,z),V(230,.16,20),Color3.fromRGB(59,68,69),M.Asphalt)
  for _,s in ipairs({-1,1}) do part(m,'Sidewalk',C(0,.2,z+s*14),V(223,.4,7),P.pave,M.Concrete) end
  for x=-88,88,12 do part(m,'LaneDash',C(x,.18,z),V(5,.03,.4),P.gold,nil,nil,false) end
 end
 part(m,'ArrivalWalk',C(0,.22,132),V(19,.44,62),P.pave,M.Pavement)
 for _,z in ipairs({-95,95}) do for x=-7,7,3 do part(m,'ZebraCrossing',C(x,.19,z),V(1.5,.04,18),P.cream,nil,nil,false) end end
 for _,x in ipairs({-105,105}) do for z=-7,7,3 do part(m,'ZebraCrossing',C(x,.19,z),V(18,.04,1.5),P.cream,nil,nil,false) end end
 for _,x in ipairs({-119,119}) do for _,z in ipairs({-78,0,78}) do B.lamp(m,x,z) end end
 for _,x in ipairs({-70,70}) do for _,z in ipairs({-80,80}) do B.lamp(m,x,z) end end
 for i,x in ipairs({-190,-155,-110,-65,65,110,155,190}) do B.tree(m,x,172,15+i%3,true);B.tree(m,x,-182,17,true) end
 for _,x in ipairs({-196,196}) do for _,z in ipairs({-105,-20,70,135}) do B.tree(m,x,z,17,true) end end
 -- Low, sculpted green hills frame the town without blocking its streets.
 for _,v in ipairs({{-175,-173,62,21},{175,-173,62,24},{-180,165,55,15},{180,165,58,18},{-205,-40,28,19},{205,30,26,15}}) do
  part(m,'GreenHill',C(v[1],-4,v[2]),V(v[3],v[4],30),Color3.fromRGB(94,139,82),M.Grass,Enum.PartType.Ball)
 end
 -- A shallow blue canal with a complete footbridge on the southern edge.
 part(m,'CanalBed',C(0,-.5,171),V(245,1,17),Color3.fromRGB(82,129,120),M.Slate)
 local water=part(m,'CanalWater',C(0,.05,171),V(243,.15,15),Color3.fromRGB(75,165,181),M.Glass,nil,false);water.Transparency=.25
 for _,z in ipairs({161.5,180.5}) do part(m,'CanalBank',C(0,.5,z),V(248,1,2),P.pave,M.Cobblestone) end
 part(m,'Footbridge',C(0,.65,171),V(17,1.1,23),P.wood,M.WoodPlanks)
 for _,x in ipairs({-8,8}) do
  for z=160,182,5.5 do part(m,'BridgePost',C(x,2.2,z),V(.5,3,.5),P.wood,M.Wood) end
  part(m,'BridgeRailing',C(x,3.5,171),V(.35,.35,23),P.wood,M.Wood)
 end
 return #m:GetDescendants()
end
function B.plaza(root)
 local m=B.model(root,'BayanihanPlaza')
 part(m,'PlazaPaving',C(0,.25,0),V(173,.5,154),P.pave,M.Pavement)
 for _,x in ipairs({-58,58}) do for _,z in ipairs({-40,40}) do
  part(m,'GardenBed',C(x,.57,z),V(32,.6,32),Color3.fromRGB(132,168,105),M.Grass)
  B.tree(m,x,z,16,false)
 end end
 B.cylinder(m,'FountainBase',C(0,.8,0),23,1.2,P.cream,M.Marble)
 B.cylinder(m,'FountainBasin',C(0,1.5,0),20,1.1,P.teal,M.Marble)
 B.cylinder(m,'FountainWater',C(0,2.1,0),17,.12,Color3.fromRGB(108,201,215),M.Glass,false)
 B.cylinder(m,'FountainPedestal',C(0,3.4,0),3.7,3.6,P.cream,M.Marble)
 B.cylinder(m,'UpperBowl',C(0,5.5,0),9,.8,P.cream,M.Marble)
 for i=1,12 do local a=i*math.pi/6;part(m,'WaterFall',C(math.cos(a)*3.5,3.6,math.sin(a)*3.5),V(.16,3.6,.16),Color3.fromRGB(150,220,229),M.Glass,nil,false) end
 part(m,'SunSculpture',C(0,7.2,0),V(2.6,2.6,2.6),P.gold,M.Metal,Enum.PartType.Ball,false)
 for _,x in ipairs({-26,26}) do B.bench(m,C(x,0,8)*A(0,x<0 and math.pi/2 or -math.pi/2,0),9);B.planter(m,C(x,0,-8),12) end
 for _,x in ipairs({-40,40}) do B.planter(m,C(x,0,68),17) end
 for _,x in ipairs({-16,16}) do part(m,'WelcomePillar',C(x,7.5,142),V(2.5,15,2.5),P.teal,M.Concrete);B.planter(m,C(x,0,145),6) end
 B.sign(m,C(0,14.5,142)*A(0,math.pi,0),V(36,4,.9),'BRIGHTHAVEN',P.teal)
 B.sign(m,C(0,11.7,142)*A(0,math.pi,0),V(28,1.5,.3),'MUNTING BAYAN • MALAKING PAG-ASA',P.cream,P.ink)
 local board=B.sign(m,C(-22,5.4,120)*A(0,math.pi,0),V(19,8,.5),'MABUHAY!\nBarangay Hall • straight ahead\nSchool →    ← Clinic & market\nExplore. Help. Belong.',P.ink)
 part(m,'BoardPost',C(-28,2,120),V(.5,4,.5),P.wood,M.Wood);part(m,'BoardPost',C(-16,2,120),V(.5,4,.5),P.wood,M.Wood)
 for _,z in ipairs({-32,35,68}) do
  local aa=V(-80,17,z);local bb=V(80,17,z);B.line(m,'FiestaString',aa,bb,.08,P.ink)
  for i=0,25 do local x=-77+i*6;local p=Instance.new('WedgePart');p.Name='FiestaPennant';p.Size=V(.08,2.1,1.7);p.CFrame=C(x,16,z)*A(0,math.pi/2,math.pi);p.Color=({P.gold,P.coral,P.teal,P.blue})[i%4+1];p.Anchored=true;p.CanCollide=false;p.Parent=m end
 end
 B.npc(m,C(-14,.5,33)*A(0,math.pi,0),'Ate Maya',P.gold,'welcome','Mabuhay! This is our little BrightHaven. Help clean the plaza, share supplies at school, and meet our neighbors.')
 return #m:GetDescendants()
end
function B.civic(root)
 local hallCF=C(0,0,-55)*A(0,math.pi,0)
 local hall=B.shell(root,'BarangayHall',hallCF,57,27,14,P.cream,P.teal,'BARANGAY HALL')
 for _,x in ipairs({-22,22}) do part(hall,'PorticoColumn',hallCF*C(x,6.8,-18),V(1.1,13,1.1),P.cream,M.Concrete) end
 part(hall,'PorticoRoof',hallCF*C(0,13.6,-17),V(59,.6,10),P.teal,M.Metal)
 B.sign(hall,hallCF*C(0,12.4,-22.2),V(43,2.3,.2),'BAYANIHAN STARTS HERE',P.teal)
 part(hall,'ReceptionDesk',hallCF*C(0,2.3,4),V(15,3,4),P.wood,M.WoodPlanks)
 B.npc(hall,hallCF*C(0,.9,8),'Kapitan Kapa',P.teal,'hall','Welcome to BrightHaven! A strong barangay begins with small acts of kindness. Find six pieces of litter around the plaza to earn 12 coins.')
 B.bench(hall,hallCF*C(-18,.9,4),9);B.bench(hall,hallCF*C(18,.9,4),9)
 local pole=part(hall,'Flagpole',C(-36,11,-40),V(.3,22,.3),P.cream,M.Metal)
 part(hall,'FlagBlue',C(-32,20,-40),V(7,1.6,.15),Color3.fromRGB(35,84,176),M.Fabric,nil,false)
 part(hall,'FlagRed',C(-32,18.4,-40),V(7,1.6,.15),Color3.fromRGB(210,65,61),M.Fabric,nil,false)
 part(hall,'FlagWhite',C(-34.5,19.2,-40.1),V(2,3.2,.1),P.cream,M.Fabric,nil,false)
 part(hall,'FlagSun',C(-34.5,19.2,-40.2),V(.8,.8,.12),P.gold,nil,Enum.PartType.Ball,false)
 local cf=C(-158,0,-52)*A(0,-math.pi/2,0)
 local clinic=B.shell(root,'BarangayClinic',cf,40,30,12,Color3.fromRGB(226,238,221),P.coral,'BRIGHTHAVEN CLINIC')
 part(clinic,'MedicalCrossV',cf*C(-14,10,-15.5),V(.8,3,.2),P.coral,nil,nil,false);part(clinic,'MedicalCrossH',cf*C(-14,10,-15.6),V(3,.8,.2),P.coral,nil,nil,false)
 B.npc(clinic,cf*C(8,1,7),'Nurse Ana',P.cream,'clinic','You are always welcome here. Come inside for a free health check.')
 part(clinic,'TreatmentBed',cf*C(-10,2.2,5),V(6,1.3,10),P.cream,M.Fabric)
 part(clinic,'Pillow',cf*C(-10,3,8),V(4,.6,2),P.teal,M.Fabric,nil,false)
 B.prompt(clinic.TreatmentBed,'Rest & recover','Clinic bed','clinic')
 part(clinic,'ReceptionDesk',cf*C(8,2.3,3),V(10,3,3),P.wood,M.WoodPlanks)
 local schoolCF=C(158,0,-52)*A(0,math.pi/2,0)
 local school=B.shell(root,'BrightHavenSchool',schoolCF,62,34,13,Color3.fromRGB(247,218,128),P.coral,'BRIGHTHAVEN ELEMENTARY')
 for _,x in ipairs({-26,26}) do part(school,'VerandaColumn',schoolCF*C(x,6.6,-21),V(.8,12,.8),P.cream,M.Concrete) end
 part(school,'VerandaRoof',schoolCF*C(0,12.8,-20),V(65,.4,9),P.coral,M.Metal)
 B.npc(school,schoolCF*C(0,1,8),'Teacher Lira',P.blue,'school','Let us share fairly! Take supplies from the yellow box and deliver one set to each of our three learning tables.')
 for i=1,3 do
  local x=(i-2)*19
  part(school,'LearningTable'..i,schoolCF*C(x,3.3,1),V(12,.6,5),P.wood,M.WoodPlanks)
  for _,s in ipairs({-1,1}) do part(school,'TableLeg',schoolCF*C(x+s*4,2,1),V(.4,2,.4),P.ink,M.Metal) end
  B.bench(school,schoolCF*C(x,1,-4)*A(0,math.pi,0),10)
  local label=B.sign(school,schoolCF*C(x,7.5,16.5),V(15,4,.15),'LEARNING TABLE '..i..'\nSUPPLIES NEEDED',P.green)
  local anchor=part(school,'Delivery'..i,schoolCF*C(x,3.8,1),V(2,.4,2),P.teal,nil,nil,false);anchor:SetAttribute('TableIndex',i);B.prompt(anchor,'Deliver a set','Learning table '..i,'deliver')
 end
 local box=part(school,'SupplyBox',schoolCF*C(-23,2.6,-23),V(5,4,4),P.gold,M.WoodPlanks)
 B.sign(school,schoolCF*C(-23,3,-25.1),V(4,2,.1),'SCHOOL\nSUPPLIES',P.gold,P.ink);B.prompt(box,'Pick up supplies','Community supply box','supplies')
 return 'Hall, clinic and school furnished'
end
function B.neighborhood(root)
 local cf=C(-158,0,36)*A(0,-math.pi/2,0)
 local shop=B.model(root,'AlingRosaSariSari');shop:SetAttribute('Landmark','Sari-sari store')
 part(shop,'Floor',cf*C(0,.4,0),V(37,.8,28),P.pave,M.Concrete)
 part(shop,'BackWall',cf*C(0,6.3,13),V(36,12,.5),P.teal,M.Concrete)
 for _,s in ipairs({-1,1}) do part(shop,'SideWall',cf*C(s*18,6.3,0),V(.5,12,26),P.teal,M.Concrete) end
 part(shop,'Counter',cf*C(0,3.4,-12),V(35,1,3),P.wood,M.WoodPlanks)
 part(shop,'CounterWall',cf*C(0,1.8,-11.5),V(35,3,.6),P.teal,M.Concrete)
 B.roof(shop,cf,36,27,12.5,P.coral)
 B.sign(shop,cf*C(0,11,-13.7),V(34,3,.3),"ALING ROSA'S SARI-SARI",P.ink)
 part(shop,'Awning',cf*C(0,9.1,-17.5)*A(.1,0,0),V(39,.35,9),P.gold,M.Fabric)
 for x=-17,17,4 do part(shop,'AwningStripe',cf*C(x,9.32,-17.5)*A(.1,0,0),V(1.5,.05,9),P.cream,M.Fabric,nil,false) end
 for _,x in ipairs({-18,18}) do part(shop,'AwningPost',cf*C(x,4.5,-21.5),V(.35,9,.35),P.wood,M.Wood) end
 for y=2,8,3 do
  part(shop,'Shelf',cf*C(0,y,11),V(32,.25,3),P.wood,M.WoodPlanks)
  for x=-14,14,3 do
   part(shop,'GroceryPacket',cf*C(x,y+1,10.5),V(1.8,1.7,1.3),({P.gold,P.coral,P.blue,P.cream})[(math.floor(x)+math.floor(y))%4+1],nil,nil,false)
   part(shop,'PacketLabel',cf*C(x,y+1,9.8),V(.9,.4,.05),P.cream,nil,nil,false)
  end
 end
 for x=-15,15,3 do for row=1,3 do part(shop,'HangingSachet',cf*C(x,9-row*.75,-12.5),V(1,.6,.1),({P.coral,P.teal,P.gold})[(x+row)%3+1],M.Fabric,nil,false) end end
 B.npc(shop,cf*C(7,.8,-6),'Aling Rosa',P.coral,'shop','Fresh pandesal and cold water! A snack costs 2 coins and a drink costs 1 coin.')
 local drink=part(shop,'WaterCrate',cf*C(-10,1.3,-18),V(4,2.3,3),P.blue,M.WoodPlanks);B.prompt(drink,'Buy water · 1 coin','Aling Rosa’s store','water')
 local bread=part(shop,'PandesalBasket',cf*C(-2,4.2,-12),V(5,.8,2),P.gold,M.WoodPlanks);B.prompt(bread,'Buy pandesal · 2 coins','Fresh bread','food')
 B.planter(shop,cf*C(22,0,-15),5)
 for i,v in ipairs({{155,30,P.coral,P.teal},{155,122,P.blue,P.gold},{-155,125,P.gold,P.teal}}) do
  local homeCF=C(v[1],0,v[2])*A(0,v[1]>0 and math.pi/2 or -math.pi/2,0)
  local h=B.shell(root,i==1 and 'MyHome' or 'NeighborHome'..i,homeCF,32,25,11,v[3],v[4],i==1 and 'BAHAY MO • YOUR HOME' or 'MALIGAYANG TAHANAN')
  part(h,'Porch',homeCF*C(0,.35,-16),V(34,.7,7),P.wood,M.WoodPlanks)
  B.bench(h,homeCF*C(9,.7,-15),8)
  part(h,'BedFrame',homeCF*C(-8,1.8,5),V(6,1.5,10),P.wood,M.WoodPlanks)
  part(h,'Blanket',homeCF*C(-8,2.7,3),V(5.7,.4,6),v[4],M.Fabric)
  part(h,'Pillow',homeCF*C(-8,2.9,8),V(4,.6,2),P.cream,M.Fabric)
  if i==1 then B.prompt(h.BedFrame,'Sleep & restore','Your bed','sleep') end
  part(h,'DiningTable',homeCF*C(8,2.4,4),V(7,.5,5),P.wood,M.WoodPlanks);B.bench(h,homeCF*C(8,1,8),6)
  B.planter(h,homeCF*C(-20,0,-10),6)
 end
 return 'Store and three homes complete'
end
function B.yards(root)
 local m=B.model(root,'CommunityWorkshops')
 for _,v in ipairs({{-75,-141,'LINIS BARANGAY',P.teal},{65,-141,'KAHOY KABAYAN',P.coral}}) do
  local cf=C(v[1],0,v[2])*A(0,math.pi,0)
  part(m,'WorkYard',cf*C(0,.2,0),V(76,.4,40),P.pave,M.Cobblestone)
  B.sign(m,cf*C(0,9,-12),V(38,3,.4),v[3],v[4])
  for _,x in ipairs({-20,20}) do part(m,'WorkshopPost',cf*C(x,5,-9),V(.65,10,.65),P.wood,M.Wood) end
  part(m,'WorkshopCanopy',cf*C(0,11,-1),V(46,.4,26),v[4],M.Metal)
  if v[1]<0 then
   for i=1,3 do local x=(i-2)*12;part(m,'RecyclingBin',cf*C(x,2.4,-2),V(8,4.8,7),({P.blue,P.gold,P.green})[i],M.Metal)
    B.sign(m,cf*C(x,3,-5.6),V(7,2,.1),({'PAPER','PLASTIC','COMPOST'})[i],P.ink)
   end
   B.npc(m,cf*C(-28,.4,-9),'Kuya Nestor',P.gold,'recycling','Every clean street begins with one piece of litter. The plaza has six to collect. Use the E key when you are nearby.')
  else
   for row=1,3 do for j=1,5-row do
    part(m,'StackedLog',cf*C((j-2.5)*3,row*2,2)*A(0,0,0),V(16,2.5,2.5),P.wood,M.Wood,Enum.PartType.Cylinder)
   end end
   B.sign(m,cf*C(21,4,-8),V(13,3,.2),'REBUILD\nTOGETHER',P.gold,P.ink)
  end
 end
 -- Small railway halt at the back of town: track and a roofed waiting area.
 local train=B.model(root,'TrainHalt')
 part(train,'TrackBallast',C(0,.1,-172),V(245,.3,12),Color3.fromRGB(129,129,115),M.Pebble)
 for x=-120,120,5 do part(train,'Sleeper',C(x,.4,-172),V(1,.5,10),P.wood,M.Wood) end
 for _,z in ipairs({-175,-169}) do part(train,'Rail',C(0,.8,z),V(245,.45,.35),Color3.fromRGB(175,188,183),M.Metal) end
 part(train,'Platform',C(0,.8,-155),V(58,1.6,15),P.pave,M.Concrete)
 for _,x in ipairs({-25,25}) do part(train,'PlatformPost',C(x,6,-155),V(.6,11,.6),P.teal,M.Metal) end
 part(train,'PlatformRoof',C(0,12,-155),V(62,.5,19),P.teal,M.Metal)
 B.sign(train,C(0,9,-145)*A(0,math.pi,0),V(42,2,.2),'BRIGHTHAVEN • ESTASYON',P.ink)
 B.bench(train,C(0,1.6,-154)*A(0,math.pi,0),16)
 return 'Community workshops and railway halt complete'
end
function B.details(root)
 local m=B.model(root,'StreetLife')
 -- A compact, recognizable jeepney parked completely inside its bay.
 local cf=C(-73,.25,115)*A(0,math.pi/2,0)
 local j=B.model(m,'BayanihanJeepney')
 part(j,'ParkingBay',C(-73,.2,115),V(32,.4,12),P.pave,M.Concrete)
 part(j,'Chassis',cf*C(0,1.2,0),V(7,1,19),P.ink,M.Metal)
 part(j,'Body',cf*C(0,3.4,2),V(7,3.8,13),P.gold,M.Metal)
 part(j,'Hood',cf*C(0,3,-7),V(6.6,2,5),P.teal,M.Metal)
 part(j,'Roof',cf*C(0,7,0),V(8,.5,18),P.cream,M.Metal)
 for _,x in ipairs({-3.5,3.5}) do
  for z=-4,6,3.3 do
   part(j,'JeepneyWindow',cf*C(x,5.6,z),V(.15,2.1,2.7),Color3.fromRGB(110,176,185),M.Glass,nil,false)
   part(j,'ChromeWindowPost',cf*C(x,5.6,z+1.5),V(.2,2.5,.2),P.cream,M.Metal,nil,false)
  end
  part(j,'SideStripe',cf*C(x,2.6,1.5),V(.1,.45,13),P.coral,M.Metal,nil,false)
  for _,z in ipairs({-6,6}) do
   part(j,'Tyre',cf*C(x,1.5,z),V(.8,3,3),P.ink,M.Rubber,Enum.PartType.Cylinder)
   part(j,'WheelHub',cf*C(x*1.12,1.5,z),V(.12,1.7,1.7),P.cream,M.Metal,Enum.PartType.Cylinder,false)
  end
 end
 part(j,'Windscreen',cf*C(0,5.4,-6.2),V(6.3,2.4,.15),Color3.fromRGB(112,186,199),M.Glass,nil,false)
 part(j,'ChromeGrille',cf*C(0,2.8,-9.6),V(3.5,1.3,.2),P.cream,M.Metal,nil,false)
 for _,x in ipairs({-2.5,2.5}) do part(j,'Headlight',cf*C(x,3.2,-9.65),V(1,1,.2),P.cream,M.Neon,Enum.PartType.Ball,false) end
 B.sign(j,cf*C(0,6.5,-6.4),V(6.5,1,.15),'BAYANIHAN',P.teal)
 B.sign(j,cf*C(0,1.8,-9.8),V(3,.65,.1),'BH • 024',P.gold,P.ink)
 -- Pocket basketball court stays separate from the main walking routes.
 local court=B.model(root,'BasketballCourt')
 part(court,'Court',C(57,.56,6),V(39,.3,49),P.teal,M.Concrete)
 for _,x in ipairs({38,76}) do part(court,'CourtLine',C(x,.73,6),V(.18,.02,48),P.cream,nil,nil,false) end
 for _,z in ipairs({-18,30}) do part(court,'CourtLine',C(57,.73,z),V(38,.02,.18),P.cream,nil,nil,false) end
 part(court,'HalfCourt',C(57,.73,6),V(38,.02,.18),P.cream,nil,nil,false)
 for _,z in ipairs({-16,28}) do
  part(court,'HoopPost',C(57,6,z),V(.5,11,.5),P.ink,M.Metal)
  part(court,'Backboard',C(57,10.5,z),V(7,4,.3),P.cream)
  local t=Instance.new('Part');t.Name='BasketballRim';t.Size=V(.2,2,2);t.Shape=Enum.PartType.Cylinder;t.CFrame=C(57,9.1,z+(z<0 and 2 or -2))*A(0,0,math.pi/2);t.Color=P.coral;t.Anchored=true;t.CanCollide=false;t.Parent=court
 end
 B.bench(court,C(82,.5,6)*A(0,-math.pi/2,0),10)
 local litter=B.model(root,'CleanupTrail')
 for i,v in ipairs({{-40,28},{-73,-7},{27,58},{-58,62},{26,-25},{69,-44}}) do
  local p=part(litter,'Litter'..i,C(v[1],.9,v[2])*A(0,i*.9,.15),V(1.6,.5,1.1),i%2==0 and P.cream or P.blue,M.Plastic,nil,false)
  p:SetAttribute('LitterId',i);B.prompt(p,'Pick up','Keep BrightHaven clean','litter')
 end
 for _,v in ipairs({{-86,66},{86,-65},{-128,90}}) do
  B.cylinder(m,'StreetBin',C(v[1],1.8,v[2]),2.5,3.6,P.teal,M.Metal)
  B.sign(m,C(v[1],2,v[2]-1.3),V(2,1.1,.1),'KEEP\nCLEAN',P.teal)
 end
 return 'Jeepney, basketball and cleanup trail complete'
end
return B
