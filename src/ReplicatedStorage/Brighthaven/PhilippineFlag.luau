local Flag={}
local V,C=Vector3.new,CFrame.new
local blue,red,white,gold=Color3.fromRGB(0,56,168),Color3.fromRGB(206,17,38),Color3.new(1,1,1),Color3.fromRGB(252,209,22)
function Flag.Create(parent,frame,height)
 local s=(height or 3)/3
 local m=Instance.new('Model');m.Name='PhilippineFlagCorrected';m:SetAttribute('AspectRatio','2:1');m:SetAttribute('SunRays',8);m:SetAttribute('Stars',3)
 local function p(name,size,cf,col,cls)
  local x=Instance.new(cls or 'Part');x.Name=name;x.Size=size*s;x.CFrame=frame*C(cf.Position*s)*cf.Rotation;x.Color=col;x.Material=Enum.Material.Fabric;x.Anchored=true;x.CanCollide=false;x.CanTouch=false;x.CanQuery=false;x.Parent=m;return x
 end
 p('BlueUpper',V(6,1.5,.07),C(0,.75,0),blue);p('RedLower',V(6,1.5,.07),C(0,-.75,0),red)
 local function tri(a,b,c,col,name)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then c,a=a,c elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
  local h=math.abs(ab:Dot(up))
  p(name,V(.13,h,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),col,'WedgePart')
  p(name,V(.13,h,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),col,'WedgePart')
 end
 tri(V(-3,-1.5,0),V(-3,1.5,0),V(-3+1.5*math.sqrt(3),0,0),white,'WhiteHoistTriangle')
 local sun=p('GoldenSun',V(.17,.64,.64),C(-2.13,0,0)*CFrame.Angles(0,math.pi/2,0),gold);sun.Shape=Enum.PartType.Cylinder
 for ray=0,7 do for tine=-1,1 do local angle=ray*math.pi/4+tine*.115;local length=tine==0 and .27 or .21
  p('SunRay'..ray,V(.055,length,.17),C(-2.13+.43*math.cos(angle),.43*math.sin(angle),0)*CFrame.Angles(0,0,angle-math.pi/2),gold)
 end end
 for _,at in ipairs({V(-2.76,1.12,0),V(-2.76,-1.12,0),V(-.95,0,0)}) do
  local vertices={};for i=0,9 do local r=i%2==0 and .16 or .065;local a=math.pi/2+i*math.pi/5;vertices[i+1]=at+V(math.cos(a)*r,math.sin(a)*r,0) end
  for i=1,10 do tri(at,vertices[i],vertices[i%10+1],gold,'FivePointStar') end
 end
 m.Parent=parent;return m
end
return Flag
