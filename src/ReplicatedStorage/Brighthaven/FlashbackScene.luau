local Scene = {}
local ResidentStyle=require(game.ReplicatedStorage.Brighthaven:WaitForChild("ResidentStyle"))
Scene.Duration, Scene.StormStart, Scene.StormStop = 138, 7, 58
Scene.RebuildStart,Scene.RebuildStop=70,88
Scene.WarningStart,Scene.ProposalStart,Scene.SharingStart=88,103,122
Scene.Shots = {
    {Start=0, Stop=7, Title="An Ordinary Day", Caption="It was a normal neighborhood... Neighbors bought groceries, rode their bikes, and walked home. Then everything changed.", From=Vector3.new(112,22,21), To=Vector3.new(88,18,10), Look=Vector3.new(43,5,-22), FOV=64},
    {Start=7, Stop=15, Title="The Typhoon Arrives", Caption="Heavy rain fell. Strong winds tore roofs from homes.", From=Vector3.new(57,20,18), To=Vector3.new(44,15,10), Look=Vector3.new(28,12,-31), FOV=56},
    {Start=15, Stop=22, Title="Run to Higher Ground", Caption="Families hurried to higher ground. Children stayed with trusted adults.", Focus="family", From=Vector3.new(-16,9,24), To=Vector3.new(-13,8,22), Look=Vector3.new(0,3,0), FOV=50},
    {Start=22, Stop=29, Title="Water at the Door", Caption="The rain did not stop. Water began filling the streets.", Focus="door", From=Vector3.new(8,5,13), To=Vector3.new(5,4.8,9), Look=Vector3.new(0,2.4,0), FOV=48},
    {Start=29, Stop=35, Title="The Flood Keeps Rising", Caption="Soon, floodwater covered steps and reached the windows.", Focus="door", From=Vector3.new(14,10,19), To=Vector3.new(9,9,15), Look=Vector3.new(0,4,0), FOV=52},
    {Start=35, Stop=43, Title="Help! Up Here!", Caption='"Help! We are up here!" Neighbors waved from their rooftops.', Focus="roof", From=Vector3.new(10,6,17), To=Vector3.new(5,5,12), Look=Vector3.new(0,3.4,0), FOV=45},
    {Start=43, Stop=50, Title="Our Flooded Barangay", Caption="Many homes were flooded. Neighbors watched out for one another.", From=Vector3.new(103,42,67), To=Vector3.new(82,34,48), Look=Vector3.new(-7,12,-47), FOV=62},
    {Start=50, Stop=58, Title="Nobody Left Behind", Caption="Rescuers brought families and their pets to safety. Every life mattered.", Focus="boat", From=Vector3.new(12,8,14), To=Vector3.new(9,6,11), Look=Vector3.new(0,3,0), FOV=50},
    {Start=58, Stop=64, Title="After the Storm", Caption="The flood drained away. Fallen trees and trash covered our streets.", From=Vector3.new(95,32,38), To=Vector3.new(70,22,28), Look=Vector3.new(0,2,7), FOV=64},
    {Start=64, Stop=70, Title="Our Homes Needed Help", Caption="Roofs were broken. Mud and scattered supplies were everywhere.", Focus="devastation", From=Vector3.new(38,20,-32), To=Vector3.new(25,13,-23), Look=Vector3.new(-9,3,4), FOV=62},
    {Start=70, Stop=79, Title="Linis Barangay", Caption="Neighbors swept the streets and collected trash. Everyone had a way to help.", From=Vector3.new(22,13,31), To=Vector3.new(9,8,25), Look=Vector3.new(0,3,17), FOV=54},
    {Start=79, Stop=88, Title="Bayanihan: Rebuilding Together", Caption="Neighbors repaired roofs and carried wood. Children packed supplies in a safe place.", Focus="rebuild", From=Vector3.new(30,18,-25), To=Vector3.new(17,10,-17), Look=Vector3.new(-8,4,3), FOV=60},
    {Start=88, Stop=96, Title="A Warning From the Radio", Caption='"Storm warning! Another super typhoon is heading toward BrightHaven. It may be even stronger!" Dark clouds gathered far away.', Focus="warning", From=Vector3.new(10,7,15), To=Vector3.new(7,5,11), Look=Vector3.new(0,0,0), FOV=52},
    {Start=96, Stop=103, Title="Not Again!", Caption='"Another storm?" Neighbors gasped. Parents held their children close. "How can we keep our homes safe?"', Focus="panic", From=Vector3.new(4,6,16), To=Vector3.new(1,5,11), Look=Vector3.new(0,3.4,0), FOV=46},
    {Start=103, Stop=112, Title="The Mad Scientist's Plan", Caption='Dr. Liza stepped forward. "I have a plan! We can build the Storm Stopper machine. Its beam can break apart the typhoon!"', Focus="scientist", From=Vector3.new(10,6,15), To=Vector3.new(5,5,11), Look=Vector3.new(0,3.8,0), FOV=48},
    {Start=112, Stop=122, Title="I Need Everybody's Help", Caption='"I cannot build it alone! Find three parts, clear our paths, and help restore power. I need every neighbor!"', Focus="blueprint", From=Vector3.new(5,3,18), To=Vector3.new(1,2,15), Look=Vector3.new(0,0,0), FOV=52},
    {Start=122, Stop=130, Title="Fair Shares Help Us All", Caption='"While we build, share food and clean water equally. Every family needs enough to stay safe and strong."', Focus="shares", From=Vector3.new(0,22,30), To=Vector3.new(0,18,25), Look=Vector3.new(0,1.5,0), FOV=64},
    {Start=130, Stop=138, Title="One Barangay. One Big Mission.", Caption='"Together, we can build the Storm Stopper! Start by helping the families at the school."', From=Vector3.new(38,28,-37), To=Vector3.new(48,35,-20), Look=Vector3.new(0,12,-80), FOV=62},
}
function Scene.ShotAt(time)
    for i,shot in ipairs(Scene.Shots) do if time<shot.Stop then return shot,i end end
    return Scene.Shots[#Scene.Shots],#Scene.Shots
end
local colors={grass=Color3.fromRGB(69,135,83),road=Color3.fromRGB(66,69,72),water=Color3.fromRGB(68,119,145),
    white=Color3.fromRGB(245,247,249),yellow=Color3.fromRGB(255,211,78),wood=Color3.fromRGB(157,116,80),ink=Color3.fromRGB(48,52,55)}
local function make(class,props,parent)
    local v=Instance.new(class);for k,value in pairs(props) do v[k]=value end;v.Parent=parent;return v
end
local function part(parent,name,size,position,color,material)
    return make("Part",{Name=name,Size=size,CFrame=CFrame.new(position),Color=color,Material=material or Enum.Material.SmoothPlastic,
        Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,TopSurface=Enum.SurfaceType.Smooth,BottomSurface=Enum.SurfaceType.Smooth},parent)
end
local visibility=setmetatable({},{__mode="k"})
local function visible(model,shown,force)
    local state=visibility[model]
    if not state then state={Objects=model:GetDescendants()};visibility[model]=state end
    if state.Shown==shown and not force then return end;state.Shown=shown
    for _,v in ipairs(state.Objects) do
        if v:IsA("BasePart") then v.LocalTransparencyModifier=shown and 0 or 1
        elseif v:IsA("BillboardGui") or v:IsA("SurfaceGui") then v.Enabled=shown end
    end
end
local function fearFace(head)
    local plate=part(head,"ExpressionPlate",Vector3.new(head.Size.X*.72,head.Size.Y*1.15,.02),Vector3.zero,colors.white)
    plate.Transparency=1;plate.CFrame=head.CFrame*CFrame.new(0,0,-head.Size.Z*.65-.03)
    local gui=make("SurfaceGui",{Name="StormExpression",Adornee=plate,Face=Enum.NormalId.Front,SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(256,128),
        AlwaysOnTop=false,LightInfluence=.2},plate)
    local root=make("Frame",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Visible=false},gui)
    local function shape(name,x,y,w,h,color,round,parent)
        local v=make("Frame",{Name=name,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),
            BackgroundColor3=color,BorderSizePixel=0},parent or root)
        if round then make("UICorner",{CornerRadius=UDim.new(.5,0)},v) end
        return v
    end
    local black=Color3.fromRGB(25,29,35)
    for _,x in {82,174} do local eye=shape("WideEye",x,43,42,44,colors.white,true)
        shape("Pupil",21,25,15,23,black,true,eye) end
    local left=shape("RaisedEyebrow",79,12,45,6,black,false)
    local right=shape("RaisedEyebrow",177,12,45,6,black,false)
    local mouth=shape("Gasp",128,100,28,31,black,true)
    local sweat=shape("Sweat",219,43,9,17,Color3.fromRGB(117,194,230),true)
    sweat.Rotation=20
    return {Root=root,Left=left,Right=right,Mouth=mouth,Sweat=sweat}
end
local function actor(assets,parent,template,name)
    local model=assets.Actors[template]:Clone();model.Name=name;model.Parent=parent
    local index=(parent:GetAttribute("CastingIndex") or 0)+1;parent:SetAttribute("CastingIndex",index)
    if template~="Dog" and template~="Scientist" then ResidentStyle.Apply(model,index,true) end
    local head=model:FindFirstChild("Head")
    local shapes=head and template~="Dog" and fearFace(head)
    local limbs,faces={},{}
    for _,v in model:GetDescendants() do
        if v:IsA("BasePart") then
            local followsHead=head and (v==head or v.Name:find("^Hair") or v.Name=="ExpressionPlate")
            table.insert(limbs,{Part=v,Frame=model:GetPivot():ToObjectSpace(v.CFrame),HeadRelative=followsHead and head.CFrame:ToObjectSpace(v.CFrame)})
        elseif v:IsA("Decal") and v.Parent==head and v.Face==Enum.NormalId.Front then
            table.insert(faces,{Decal=v,CalmTransparency=v.Transparency})
        end
    end
    return {Model=model,Limbs=limbs,Faces=faces,FaceShapes=shapes,
        HeadFrame=head and model:GetPivot():ToObjectSpace(head.CFrame),FootOffset=model:GetAttribute("FootOffset") or 2.9}
end
local function expression(data,time)
    local mood=(time<Scene.StormStart or time>=70) and "calm" or time<15 and "startled" or "scared"
    if data.Reassuring then mood="calm"
    elseif time>=Scene.WarningStart and time<Scene.ProposalStart then
        mood=(data.Model:GetAttribute("OutfitId") or 0)%3==0 and "startled" or "scared"
    elseif time<Scene.StormStart then mood="calm"
    elseif time>=58 and time<70 or time>=24 and time<58 and (data.Model:GetAttribute("OutfitId") or 0)%3==0 then mood="sad" end
    if data.Emotion==mood then return end
    data.Emotion=mood;data.Model:SetAttribute("Emotion",mood)
    local afraid=mood~="calm"
    for _,face in data.Faces do face.Decal.Transparency=afraid and 1 or face.CalmTransparency end
    local shapes=data.FaceShapes
    if shapes then
        shapes.Root.Visible=afraid
        shapes.Left.Rotation,shapes.Right.Rotation=mood=="startled" and -7 or -20,mood=="startled" and 7 or 20
        shapes.Mouth.Size=mood=="sad" and UDim2.fromOffset(34,9) or mood=="startled" and UDim2.fromOffset(24,25) or UDim2.fromOffset(28,31)
        shapes.Sweat.Visible=mood=="scared" or mood=="sad"
        shapes.Sweat.Position=mood=="sad" and UDim2.fromOffset(178,69) or UDim2.fromOffset(219,43)
    end
end
local function pose(data,frame,kind,time)
    local afraid=data.Emotion~="calm" and data.FaceShapes~=nil
    if afraid and kind=="idle" and not data.Steady then kind=data.Emotion=="startled" and "startled" or "cower" end
    if afraid and kind=="run" then frame*=CFrame.Angles(.1,0,math.sin(time*7)*.025) end
    local headFrame=data.HeadFrame
    if headFrame and afraid then
        headFrame=CFrame.new(headFrame.Position)*CFrame.Angles(.04,math.sin(time*3.2)*.18,math.sin(time*5)*.035)*headFrame.Rotation
    end
    for _,limb in ipairs(data.Limbs) do
        local v,base=limb.Part,limb.Frame;local angle,roll=0,0
        local side=v.Name:find("Left") and -1 or 1
        if limb.HeadRelative then v.CFrame=frame*headFrame*limb.HeadRelative;continue end
        if kind=="run" and (v.Name:find("Arm") or v.Name:find("Leg")) then
            angle=math.sin(time*(afraid and 15 or 12))*(afraid and .9 or .75)*side*(v.Name:find("Arm") and -1 or 1)
            if afraid and v.Name:find("Arm") then angle+=.4;roll=side*.22 end
        elseif kind=="startled" and v.Name:find("Arm") then angle=.3;roll=side*(1.3+math.sin(time*7)*.1)
        elseif kind=="cower" and v.Name:find("Arm") then angle=1.7+math.sin(time*8)*.09;roll=-side*.18
        elseif kind=="wave" and v.Name:find("Arm") then roll=side*(2.3+math.sin(time*(afraid and 7 or 5))*.25)
        elseif kind=="hammer" and v.Name=="Right Arm" then angle=-1.2+math.sin(time*9)*.7
        elseif kind=="sweep" and v.Name:find("Arm") then angle=-.65+math.sin(time*3)*.18;roll=side*.15
        elseif kind=="explain" and v.Name:find("Arm") then angle=v.Name=="Right Arm" and -.85+math.sin(time*2)*.15 or -.45;roll=side*.25
        elseif kind=="carry" and v.Name:find("Arm") then angle=-.85
        elseif kind=="bike" then
            if v.Name:find("Arm") then angle=-1.05
            elseif v.Name:find("Leg") then angle=.7+math.sin(time*7)*.25*side end
        elseif kind=="walk" and (v.Name:find("Arm") or v.Name:find("Leg")) then angle=math.sin(time*5)*.28*side end
        if angle~=0 or roll~=0 then
            local joint=base.Position+Vector3.new(0,v.Size.Y/2,0)
            v.CFrame=frame*CFrame.new(joint)*CFrame.Angles(angle,0,roll)*CFrame.new(0,-v.Size.Y/2,0)*base.Rotation
        else v.CFrame=frame*base end
    end
end
local function levelHouse(model)
    local floor
    for _,v in model:GetDescendants() do
        if v:IsA("BasePart") and v.Name=="Foundation" and v.Size.Y<2 and v.Size.Z>40 then floor=v;break end
    end
    if not floor or floor.CFrame.UpVector:Dot(Vector3.yAxis)>.9999 then return end
    local forward=floor.CFrame.LookVector*Vector3.new(1,0,1)
    assert(forward.Magnitude>.01,"Cannot level "..model.Name)
    local correction=CFrame.lookAt(floor.Position,floor.Position+forward.Unit)*floor.CFrame:Inverse()
    local roof
    -- Level the imported structure while keeping its already-flat roof panels horizontal.
    for _,v in model:GetDescendants() do
        if v:IsA("BasePart") then
            local before=v.CFrame;local corrected=correction*before
            if before.UpVector:Dot(Vector3.yAxis)>.9999 and v.Size.Y<3 then corrected=CFrame.new(corrected.Position)*before.Rotation end
            v.CFrame=corrected
            if v.Name=="Foundation" and v.Size.Y<3 and (not roof or v.Position.Y>roof.Position.Y) then roof=v end
        end
    end
    assert(roof,"No roof found while leveling "..model.Name)
    local support=model:FindFirstChild("Roof Wall",true)
    if support and support:IsA("BasePart") then
        local height=support.Position.Y+support.Size.Y/2+.5+roof.Size.Y/2
        roof.CFrame=CFrame.new(roof.Position.X,height,roof.Position.Z)*roof.CFrame.Rotation
    end
    for _,v in model:GetDescendants() do
        if v:IsA("Part") and v.Shape==Enum.PartType.Wedge and v.Size.X>25 and v.Size.Z>25 then
            v.Name="StormCeiling";v.Shape=Enum.PartType.Block;v.Size=Vector3.new(v.Size.X,.5,v.Size.Z)
            v.CFrame=CFrame.new(roof.Position-Vector3.new(0,roof.Size.Y/2+.25,0))*v.CFrame.Rotation
        end
    end
    model.PrimaryPart=nil;model.WorldPivot=CFrame.identity
    local cf,size=model:GetBoundingBox()
    model.WorldPivot=CFrame.new(roof.Position.X,cf.Y-size.Y/2,roof.Position.Z)
    model:PivotTo(CFrame.identity)
end
local function progress(t,a,b) return math.clamp((t-a)/(b-a),0,1) end
local function smooth(q) return q*q*(3-2*q) end
local function pathPoint(points,q)
    local length=0;for i=2,#points do length+=(points[i]-points[i-1]).Magnitude end
    local distance=length*math.clamp(q,0,1)
    for i=2,#points do local segment=(points[i]-points[i-1]).Magnitude
        if distance<=segment then return points[i-1]:Lerp(points[i],distance/segment) end;distance-=segment end
    return points[#points]
end
local function buildScene(assets,root)
    local self={Origin=Vector3.new(0,8000,0),Time=0}
    local origin=self.Origin
    self.Root=root
    local function p(parent,name,size,position,color,material) return part(parent,name,size,origin+position,color,material) end
    local function clone(template,name,position,scale,yaw)
        local model=assets.Buildings[template]:Clone();model.Name=name
        if template=="HouseA" or template=="HouseB" then levelHouse(model) end
        if template=="HouseA" or template=="HouseB" or template=="Hall" or template=="Store" or template=="WaitingShed" then
            for _,piece in model:GetDescendants() do
                if piece:IsA("BasePart") then
                    if piece:IsA("Part") then
                        piece.TopSurface=Enum.SurfaceType.Smooth
                        piece.BottomSurface=Enum.SurfaceType.Smooth
                    end
                    if piece.Material==Enum.Material.Plastic then piece.Material=Enum.Material.SmoothPlastic end
                end
            end
        end
        if scale then model:ScaleTo(model:GetScale()*scale) end
        model:PivotTo(CFrame.new(origin+position)*CFrame.Angles(0,yaw or math.pi,0));model.Parent=root;return model
    end
    p(root,"Ground",Vector3.new(330,2,340),Vector3.new(0,-1,-49),colors.grass,Enum.Material.Grass)
    p(root,"BarangayStreet",Vector3.new(270,.18,18),Vector3.new(0,.09,7),colors.road,Enum.Material.Asphalt)
        for x=-128,128,12 do
        if math.abs(x)>13 then p(root,"CenterLine",Vector3.new(6,.045,.22),Vector3.new(x,.205,7),colors.yellow) end
    end
    for _,z in {-4,18} do p(root,"Sidewalk",Vector3.new(270,.4,3.7),Vector3.new(0,.2,z),colors.white,Enum.Material.Concrete) end
    for x=-9,9,3 do p(root,"Crosswalk",Vector3.new(1.5,.045,16),Vector3.new(x,.205,7),colors.white) end
    p(root,"RaisedSafeGround",Vector3.new(112,8,95),Vector3.new(0,4,-111.5),colors.grass,Enum.Material.Grass)
    for _,approach in {{X=48,Width=14},{X=-54,Width=8}} do
        for i=1,8 do p(root,"SafeSteps",Vector3.new(approach.Width,i,2),Vector3.new(approach.X,i/2,-46-i*2),colors.white,Enum.Material.Concrete) end
        p(root,"Landing",Vector3.new(approach.Width,8,5),Vector3.new(approach.X,4,-64.5),colors.white,Enum.Material.Concrete)
    end
    clone("Hall","CurrentBarangayHall",Vector3.new(0,8,-112),.9)
    clone("Store","CurrentSariSariStore",Vector3.new(89,0,-35),.85)
    clone("WaitingShed","BarangayWaitingShed",Vector3.new(-119,0,-9),.9)
    clone("Jeepney","ParkedJeepney",Vector3.new(106,.2,8),1,math.pi/2)
    clone("Tricycle","ParkedTricycle",Vector3.new(-112,.2,9),1,math.pi/2)
    local trees={}
    for i,point in ipairs({Vector3.new(-118,0,-58),Vector3.new(-72,0,-18),Vector3.new(60,0,-17),Vector3.new(123,0,-72),
        Vector3.new(-137,0,55),Vector3.new(129,0,53),Vector3.new(-107,0,-119),Vector3.new(119,0,-146),Vector3.new(-73,0,-149),Vector3.new(65,0,-157)}) do
        local model=clone("Tree","BarangayTree"..i,point,1+(i%3)*.14,0)
        table.insert(trees,{Model=model,Frame=model:GetPivot(),Ground=origin+point})
    end
    for i,x in ipairs({-99,-49,46,118}) do clone("Streetlight","Streetlight"..i,Vector3.new(x,0,-4),.65,0) end
    for i,x in ipairs({-63,58}) do clone("Hydrant","Hydrant"..i,Vector3.new(x,0,18),1,0) end
    local homes,damaged={},{}
    for i,point in ipairs({Vector3.new(-36,0,-34),Vector3.new(30,0,-26),Vector3.new(-88,0,42),Vector3.new(66,0,43),Vector3.new(-94,0,-85),Vector3.new(94,0,-107)}) do
        local model=clone(i%2==1 and "HouseA" or "HouseB","CurrentBarangayHome"..i,point,i%2==1 and .7 or .55)
        local roofPanel
        for _,v in model:GetDescendants() do
            if v:IsA("BasePart") and v.Name=="Foundation" and v.Size.X>10 and v.Size.Z>10
                and (not roofPanel or v.Position.Y>roofPanel.Position.Y) then roofPanel=v end
        end
        assert(roofPanel,"No roof panel in "..model.Name)
        local roof=make("Model",{Name="StormRoof"},model)
        for _,v in model:GetDescendants() do
            if v:IsA("BasePart") and (v.Name=="StormCeiling" or v.Position.Y>=roofPanel.Position.Y-.1 and v.Size.Y<3) then v.Parent=roof end
        end
        assert(#roof:GetChildren()>0,"No roof in "..model.Name)
        local rcf,rs=roof:GetBoundingBox();roof.WorldPivot=rcf
        local rooftop=Vector3.new(rcf.X-origin.X,rcf.Y+rs.Y/2-origin.Y,rcf.Z-origin.Z)
        local door
        for _,v in model:GetDescendants() do if v:IsA("BasePart") and v.Name=="Door" then door=v;break end end
        local doorPoint=door and door:IsA("BasePart") and Vector3.new(door.Position.X-origin.X,0,door.Position.Z-origin.Z) or point+Vector3.new(0,0,12)
        local outward=doorPoint-Vector3.new(rooftop.X,0,rooftop.Z)
        outward=outward.Magnitude>.1 and outward.Unit or Vector3.zAxis
        homes[i]={Model=model,Roof=roof,Frame=rcf,Rooftop=rooftop,Door=doorPoint,Front=outward,Side=Vector3.new(outward.Z,0,-outward.X)}
        if i%2==0 then table.insert(damaged,{Model=roof,Parts=roof:GetChildren(),Original=rcf,Debris=rcf*CFrame.new(9,-rooftop.Y+1,15)*CFrame.Angles(.45,.25,.75),At=8+i*.8}) end
    end
    self.Homes=homes
    self.PeakFlood=math.min(homes[1].Rooftop.Y,homes[3].Rooftop.Y,homes[5].Rooftop.Y)-.35
    local scaffolds={}
    for _,i in {2,4,6} do
        local home=homes[i];local scaffold=make("Model",{Name="CommunityScaffold"..i},root)
        local _,size=home.Roof:GetBoundingBox();local center=home.Rooftop
        for _,x in {-size.X/2-.7,size.X/2+.7} do
            for _,z in {-size.Z/2-.7,size.Z/2+.7} do
                p(scaffold,"SupportPost",Vector3.new(.3,center.Y,.3),Vector3.new(center.X+x,center.Y/2,center.Z+z),colors.wood,Enum.Material.WoodPlanks)
            end
            for _,y in {center.Y*.5,center.Y-.6} do
                p(scaffold,"ScaffoldRail",Vector3.new(.3,.3,size.Z+1.4),Vector3.new(center.X+x,y,center.Z),colors.wood,Enum.Material.WoodPlanks)
            end
        end
        table.insert(scaffolds,scaffold)
    end
    local wreckage,dirty,brokenSupports={},{},{}
    for i,home in homes do
        for _,v in home.Model:GetDescendants() do
            if v:IsA("BasePart") and not v:IsDescendantOf(home.Roof) and v.Transparency<.8 then
                table.insert(dirty,{Part=v,Original=v.Color,Muddy=v.Color:Lerp(Color3.fromRGB(115,106,96),.48),Home=i})
                if i%2==0 and v.Name=="Roof Wall" then table.insert(brokenSupports,v) end
            end
        end
        for j=1,5 do
            local at=home.Door+home.Side*((j-3)*2.2)+home.Front*(3+j%2*3)+Vector3.new(0,.2,0)
            local v=p(root,"BrokenTimber",Vector3.new(4.2,.28,.7),at,colors.wood,Enum.Material.WoodPlanks)
            v.CFrame*=CFrame.Angles(0,j*1.7,.04);table.insert(wreckage,{Part=v,Home=i})
        end
        local mud=p(root,"StormMud",Vector3.new(13,.025,9),home.Door+home.Front*4+Vector3.new(0,.08,0),Color3.fromRGB(105,97,86))
        mud.Transparency=.32;table.insert(wreckage,{Part=mud,Home=i})
        local rubble=p(root,"BrokenMasonry",Vector3.new(2.2,.9,1.4),home.Door+home.Side*5+home.Front*7+Vector3.new(0,.45,0),Color3.fromRGB(134,137,136),Enum.Material.Concrete)
        rubble.CFrame*=CFrame.Angles(0,i,0);table.insert(wreckage,{Part=rubble,Home=i})
    end
    for i=1,12 do
        local timber=p(root,"StreetDebris",Vector3.new(3.8,.2,.65),Vector3.new(-63+i*10,.35,3+i%3*3),colors.wood,Enum.Material.WoodPlanks)
        timber.CFrame*=CFrame.Angles(0,i*1.2,0);table.insert(wreckage,{Part=timber,Home=i%6+1})
    end
    local rubbishColors={Color3.fromRGB(242,241,229),Color3.fromRGB(75,154,183),Color3.fromRGB(203,91,71),Color3.fromRGB(60,74,68)}
    for i=1,72 do
        local at=Vector3.new(-114+(i*37)%228,.3,-2+(i*13)%24)
        local bottle=i%3==0
        local v=p(root,bottle and "DiscardedBottle" or i%3==1 and "StormLitter" or "TrashBag",
            bottle and Vector3.new(.45,.45,1.2) or i%3==1 and Vector3.new(1.6,.05,1.2) or Vector3.new(1.1,.9,1.1),
            at,rubbishColors[i%4+1],Enum.Material.SmoothPlastic)
        if i%3==2 then v.Shape=Enum.PartType.Ball end
        v.CFrame*=CFrame.Angles(0,i*1.73,.09)
        table.insert(wreckage,{Part=v,Home=i%6+1})
    end
    self.Wreckage=wreckage
    local gauge=homes[1].Door+Vector3.new(-4,0,1)
    p(root,"DoorPost",Vector3.new(.25,9,.25),gauge+Vector3.new(0,4.5,0),colors.wood)
    for y=1,8 do p(root,"WaterHeightBand",Vector3.new(.45,.15,.35),gauge+Vector3.new(0,y,0),colors.white) end
    local water=p(root,"Floodwater",Vector3.new(320,.3,325),Vector3.new(0,-2,-48),colors.water,Enum.Material.Glass)
    water.Transparency,water.Reflectance=.17,.04;self.Water=water
    local currents={}
    for i=1,32 do local v=p(root,"FloodCurrent",Vector3.new(4+i%5,.035,.16),Vector3.zero,Color3.fromRGB(183,214,226))
        v.Transparency=.52;table.insert(currents,{Part=v,X=(i*31)%220-110,Z=(i*19)%210-130}) end
    local emitter=p(root,"RainEmitter",Vector3.new(200,.1,220),Vector3.new(0,52,-44),colors.white);emitter.Transparency=1
    self.Rain=make("ParticleEmitter",{Texture="rbxasset://textures/particles/sparkles_main.dds",Rate=0,EmissionDirection=Enum.NormalId.Bottom,
        Lifetime=NumberRange.new(.65,.9),Speed=NumberRange.new(80,100),Acceleration=Vector3.new(28,-40,0),SpreadAngle=Vector2.new(3,3),
        Color=ColorSequence.new(Color3.fromRGB(205,226,237)),Transparency=NumberSequence.new(.5),Size=NumberSequence.new(.1),Squash=NumberSequence.new(5)},emitter)
    local rain={}
    for i=1,180 do local v=p(root,"HeavyRain",Vector3.new(.055,2.7,.055),Vector3.zero,Color3.fromRGB(203,225,239),Enum.Material.Neon)
        v.Transparency=.55;table.insert(rain,{Part=v,X=(i*31)%190-95,Z=(i*23)%220-142,Phase=i*1.37}) end
    local nearRain={}
    for i=1,72 do
        local v=p(root,"CloseupRain",Vector3.new(.035,1.8,.035),Vector3.zero,Color3.fromRGB(213,229,239),Enum.Material.Neon)
        v.Transparency=.62;table.insert(nearRain,{Part=v,X=(i*13)%46-23,Z=-8-(i*7)%24,Phase=i*1.71})
    end
    local family={actor(assets,root,"Mother","RunningMother"),actor(assets,root,"Child","RunningChild"),actor(assets,root,"Father","RunningFather")}
    local crowds={}
    for group=1,6 do for member=1,3 do
        local template=member==2 and "Child" or "Neighbor"..((group+member-2)%6+1)
        table.insert(crowds,{Actor=actor(assets,root,template,"EvacuatingNeighbor"..group.."_"..member),Group=group,Member=member})
    end end
    local roofFamilies={}
    for group,homeIndex in ipairs({3,5}) do for member=1,3 do
        table.insert(roofFamilies,{Actor=actor(assets,root,member==2 and "Child" or member==1 and "Mother" or "Father","RooftopNeighbor"..group.."_"..member),Home=homeIndex,Member=member})
    end end
    local workers={actor(assets,root,"Father","RoofRepairer"),actor(assets,root,"Mother","SupplyHelper"),actor(assets,root,"Child","PackingHelper")}
    local volunteers={};for i=1,6 do table.insert(volunteers,actor(assets,root,"Neighbor"..i,"ReliefVolunteer"..i)) end
    local dogs={actor(assets,root,"Dog","EvacuatingDog"),actor(assets,root,"Dog","ShelteredDog")}
    local rescuers={actor(assets,root,"Father","Rescuer"),actor(assets,root,"Mother","RescueVolunteer")}
    for _,v in rescuers do v.Model.Torso.Color=Color3.fromRGB(249,133,45);v.Steady=true end
    local scientist=actor(assets,root,"Scientist","DrLizaMadScientist")
    scientist.Steady=true;scientist.Reassuring=true
    local scientistPoint=Vector3.new(10,8,-68)
    local help=make("BillboardGui",{Name="SilentHelp",Size=UDim2.fromOffset(164,46),StudsOffset=Vector3.new(0,3,0),AlwaysOnTop=true,MaxDistance=100,Enabled=false},family[1].Model.Head)
    make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.white,BorderSizePixel=0,Text="Help! Up here!",TextColor3=colors.ink,
        Font=Enum.Font.FredokaOne,TextSize=19,TextStrokeTransparency=1},help)
    local boat=make("Model",{Name="RescueBoat"},root)
    p(boat,"Hull",Vector3.new(6,1,13),Vector3.zero,Color3.fromRGB(244,128,48))
    for _,x in {-2.7,2.7} do p(boat,"Side",Vector3.new(.4,1.4,13),Vector3.new(x,.7,0),colors.yellow) end
    for _,z in {-5.8,5.8} do p(boat,"End",Vector3.new(6,1.4,.4),Vector3.new(0,.7,z),colors.yellow) end
    for _,z in {-3,3} do p(boat,"Bench",Vector3.new(5,.3,1.4),Vector3.new(0,.9,z),colors.white) end
    boat.WorldPivot=CFrame.new(origin)
    local prep=make("Model",{Name="EqualSupplyBundles"},root)
    local tablePoint=Vector3.new(-5,8,-76)
    p(prep,"SupplyTable",Vector3.new(12,.5,4),tablePoint+Vector3.new(0,2,0),colors.wood,Enum.Material.WoodPlanks)
    for _,x in {-10,0} do p(prep,"TableLeg",Vector3.new(.4,2,.4),Vector3.new(x,9,-76),colors.wood) end
    p(prep,"EmergencyBag",Vector3.new(2,2.5,1),Vector3.new(-9,11.5,-76),colors.yellow)
    local radioPoint=Vector3.new(-4,10.8,-76)
    local radio=p(prep,"Radio",Vector3.new(1.5,1,.6),radioPoint,colors.ink)
    local warning=make("BillboardGui",{Name="IncomingStormWarning",Size=UDim2.fromOffset(176,34),StudsOffset=Vector3.new(0,2.2,0),AlwaysOnTop=false,Enabled=false},radio)
    make("TextLabel",{Size=UDim2.fromScale(1,1),BackgroundColor3=colors.yellow,Text="STORM WARNING",TextColor3=colors.ink,
        TextSize=19,Font=Enum.Font.FredokaOne,BorderSizePixel=0},warning)
    local incoming=make("Model",{Name="IncomingSuperTyphoonClouds"},root)
    for i=1,10 do
        local cloud=p(incoming,"DistantStormCloud",Vector3.new(24+i%3*7,10+i%2*5,20),Vector3.new(-126+i*23,51+i%3*4,-211-i%2*9),Color3.fromRGB(92,101,114))
        cloud.Shape=Enum.PartType.Ball;cloud.Transparency=.18
    end
    local blueprint=make("Model",{Name="StormStopperBlueprint"},root)
    local blueprintPoint=Vector3.new(23,13,-69)
    local board=p(blueprint,"PlanBoard",Vector3.new(17,9,.4),blueprintPoint,colors.yellow)
    board.CFrame*=CFrame.Angles(0,math.pi,0)
    for _,x in {-6,6} do p(blueprint,"BoardStand",Vector3.new(.5,5,.5),blueprintPoint+Vector3.new(x,-3.5,-.45),colors.wood) end
    local plan=make("SurfaceGui",{Adornee=board,Face=Enum.NormalId.Front,SizingMode=Enum.SurfaceGuiSizingMode.FixedSize,CanvasSize=Vector2.new(900,480),LightInfluence=.15},board)
    local page=make("Frame",{Position=UDim2.fromOffset(16,16),Size=UDim2.new(1,-32,1,-32),BackgroundColor3=colors.white,BorderSizePixel=0},plan)
    local function planText(text,pos,size,font)
        return make("TextLabel",{Position=pos,Size=size,Text=text,TextColor3=colors.ink,Font=Enum.Font.FredokaOne,TextSize=font or 25,
            BackgroundTransparency=1,TextWrapped=true},page)
    end
    planText("STORM STOPPER",UDim2.fromOffset(20,12),UDim2.new(1,-40,0,48),38)
    planText("3 missing parts + helping hands",UDim2.fromOffset(20,62),UDim2.new(1,-40,0,38),25)
    for i,name in {"Ion Stabilizer","Atmospheric Core","Wind Turbine"} do
        local socket=make("Frame",{Position=UDim2.fromOffset(87+(i-1)*290,124),Size=UDim2.fromOffset(114,114),BackgroundColor3=colors.yellow,BorderSizePixel=0},page)
        make("UICorner",{CornerRadius=UDim.new(.5,0)},socket)
        make("TextLabel",{Size=UDim2.fromScale(1,1),Text="?",TextSize=68,Font=Enum.Font.FredokaOne,TextColor3=colors.ink,BackgroundTransparency=1},socket)
        planText(name,UDim2.fromOffset(14+(i-1)*290,250),UDim2.fromOffset(268,60),25)
    end
    planText("Find Parts   +   Share Supplies   +   Restore Power",UDim2.fromOffset(20,336),UDim2.new(1,-40,0,62),25)
    local bundles={}
    for i,x in ipairs({-19,0,19}) do
        local basket=make("Model",{Name="FamilySupplyBundle"..i},prep)
        local point=Vector3.new(x,8,-68)
        p(basket,"SupplyCrate",Vector3.new(6,1.4,4),point+Vector3.new(0,.7,0),colors.wood,Enum.Material.WoodPlanks)
        local contents=make("Model",{Name="EqualFoodAndWater"},basket)
        for item=1,3 do p(contents,"FoodPack",Vector3.new(1.2,.45,1.3),point+Vector3.new(-1.7+(item-1)*1.4,1.65,1),colors.white) end
        for item=1,2 do
            p(contents,"WaterBottle",Vector3.new(.55,1.4,.55),point+Vector3.new(-.7+(item-1)*1.4,2,-1),Color3.fromRGB(67,149,199),Enum.Material.Glass)
            p(contents,"BottleCap",Vector3.new(.4,.18,.4),point+Vector3.new(-.7+(item-1)*1.4,2.8,-1),colors.white)
        end
        bundles[i]={Contents=contents,Point=point}
    end
    local delivery=p(prep,"MovingFoodPack",Vector3.new(1.3,.55,1.3),tablePoint+Vector3.new(0,2.6,0),colors.white)
    local hammer=p(root,"HammerHandle",Vector3.new(.25,1.3,.25),Vector3.zero,colors.wood)
    local hammerHead=p(root,"HammerHead",Vector3.new(.9,.4,.4),Vector3.zero,colors.ink,Enum.Material.Metal)
    local planks={};for i=1,4 do table.insert(planks,p(root,"RepairLumber",Vector3.new(6,.3,.7),homes[2].Door+homes[2].Front*7+homes[2].Side*5+Vector3.new(0,i*.3,0),colors.wood,Enum.Material.WoodPlanks)) end
    self.Actors={Family=family,Crowds=crowds,RoofFamilies=roofFamilies,Workers=workers,Rescuers=rescuers,Volunteers=volunteers,Dogs=dogs,Scientist=scientist}
    self.ActorCount=4+#crowds+#roofFamilies+#workers+#rescuers+#volunteers+#dogs
    local carried={}
    for i,v in volunteers do
        carried[i]=p(root,"CommunityRepairLumber",Vector3.new(4.2,.3,.8),Vector3.zero,colors.wood,Enum.Material.WoodPlanks)
    end
    local cleaners={}
    for i=1,4 do
        local broom=make("Model",{Name="CleanupBroom"..i},root)
        p(broom,"Handle",Vector3.new(.14,3.8,.14),Vector3.zero,colors.wood,Enum.Material.Wood)
        p(broom,"Bristles",Vector3.new(1.2,.65,.25),Vector3.new(0,-2,0),Color3.fromRGB(211,174,85))
        broom.WorldPivot=CFrame.new(origin)
        local bag=p(root,"CollectedTrash"..i,Vector3.new(1.5,1.6,1.5),Vector3.new(-24+(i-1)*16,.8,20),Color3.fromRGB(54,71,65))
        bag.Shape=Enum.PartType.Ball
        cleaners[i]={Broom=broom,Bag=bag}
    end
    local groceries={}
    for _,index in {1,3,10} do
        local bag=make("Model",{Name="GroceryBag"..index},root)
        p(bag,"PaperBag",Vector3.new(.9,1.2,.6),Vector3.zero,Color3.fromRGB(218,180,115))
        p(bag,"Vegetables",Vector3.new(.65,.4,.5),Vector3.new(0,.7,0),Color3.fromRGB(93,161,65))
        groceries[index]=bag
    end
    local bicycles={}
    for _,index in {4,13} do
        local bike=make("Model",{Name="EverydayBicycle"..index},root)
        for _,z in {-1.9,1.9} do
            local wheel=p(bike,"Wheel",Vector3.new(.24,2.2,2.2),Vector3.new(0,1.1,z),colors.ink)
            wheel.Shape=Enum.PartType.Cylinder
            p(bike,"WheelHub",Vector3.new(.3,.3,.3),Vector3.new(0,1.1,z),colors.white)
        end
        p(bike,"Frame",Vector3.new(.3,.3,3.7),Vector3.new(0,1.5,0),colors.yellow)
        p(bike,"SeatPost",Vector3.new(.25,1.6,.25),Vector3.new(0,2,0),colors.yellow)
        p(bike,"Seat",Vector3.new(.9,.22,.8),Vector3.new(0,2.85,0),colors.ink)
        p(bike,"HandleStem",Vector3.new(.22,1.8,.22),Vector3.new(0,2.5,-1.9),colors.white)
        p(bike,"Handlebar",Vector3.new(1.8,.2,.2),Vector3.new(0,3.4,-1.9),colors.ink)
        bike.WorldPivot=CFrame.new(origin);bicycles[index]=bike
    end
    local routineStarts={Vector3.new(89,.4,-10),Vector3.new(-65,.4,-13),Vector3.new(86,.4,32),
        Vector3.new(-115,.4,17),Vector3.new(99,.4,-74),Vector3.new(-35,.4,47)}
    local function refuge(index)
        local home=homes[({1,3,5})[(index-1)%3+1]]
        local slot=math.floor((index-1)/3)
        return home.Rooftop+Vector3.new((slot%4-1.5)*3.6,0,-5-math.floor(slot/4)*3.8)
    end
    local function placed(data,point,yaw,kind,time)
        expression(data,self.Time)
        pose(data,CFrame.new(origin+point+Vector3.new(0,data.FootOffset,0))*CFrame.Angles(0,yaw or 0,0),kind,time)
    end
    local function routinePoint(group,member,time)
        local start=group==0 and Vector3.new(-25,.4,20) or routineStarts[group]
        return start+Vector3.new((member-2)*2,0,0)
            +Vector3.new(math.sin(time*.35+group)*2,0,math.cos(time*.3+group)*1.3)
    end
    -- Authored sidewalk corridors avoid the imported houses' actual footprints.
    -- Build the rails once, rather than finding paths during every cinematic frame.
    local routes={}
    for group=0,6 do
        routes[group]={}
        for member=1,3 do
            local offset=Vector3.new((member-2)*2,0,0)
            local start=routinePoint(group,member,7)
            local west=group%2==0
            local points={start}
            local function add(point) table.insert(points,point+offset) end
            local index=(group-1)*3+member
            if group>0 and (index==4 or index==13) then
                start=Vector3.new(index==4 and 97 or 7,.4,index==4 and 5 or 7)
                points[1]=start
                west=false
                add(Vector3.new(start.X,.4,-4))
            elseif group==4 then
                add(Vector3.new(-137,.4,17))
                add(Vector3.new(-137,.4,-25))
                add(Vector3.new(-54,.4,-25))
            elseif group==5 then
                add(Vector3.new(115,.4,-74))
                add(Vector3.new(115,.4,-4))
            else
                add(Vector3.new(start.X-offset.X,.4,-4))
            end
            local approach=west and -54 or 48
            if group~=4 then add(Vector3.new(approach,.4,-4)) end
            add(Vector3.new(approach,.4,-46))
            for step=1,8 do add(Vector3.new(approach,step,-46-step*2)) end
            add(Vector3.new(approach,8,-64))
            if west then add(Vector3.new(-54,8,-68.5));add(Vector3.new(-45,8,-68.5)) end
            add(Vector3.new(west and -45 or 48,8,-78-math.floor(group/2)*7))
            routes[group][member]=points
        end
    end
    self.EvacuationRoutes=routes
    local function evacuation(group,member,time)
        local points=routes[group][member]
        local began=8+(group*7%5)*.45
        local q=progress(time,began,20+(group*3%4))
        if time<7 then return routinePoint(group,member,time),"walk",group%2==0 and math.pi*.5 or -math.pi*.5 end
        local point=pathPoint(points,q)
        local nextPoint=pathPoint(points,math.min(1,q+.005))
        local delta=nextPoint-point
        local yaw=delta.Magnitude>.005 and math.atan2(-delta.X,-delta.Z) or math.pi
        return point,q>0 and q<1 and "run" or "idle",yaw
    end
    function self:Update(time)
        self.Time=time
        local shot,index=Scene.ShotAt(time);local q=smooth(progress(time,shot.Start,shot.Stop))
        local storm=time>=Scene.StormStart and time<Scene.StormStop
        local level=time<24 and -2 or time<40 and -2+smooth(progress(time,24,40))*(self.PeakFlood+2)
            or time<58 and self.PeakFlood or self.PeakFlood-smooth(progress(time,58,64))*(self.PeakFlood+2)
        local rebuilding=progress(time,Scene.RebuildStart,Scene.RebuildStop)
        for _,v in scaffolds do visible(v,time>=70 and time<88) end
        root:SetAttribute("FloodLevel",level);root:SetAttribute("Phase",time<7 and "ordinary" or time<58 and "storm" or time<70 and "devastated" or time<88 and "rebuilding" or time<103 and "warning" or time<122 and "proposal" or "prepared")
        visible(incoming,time>=Scene.WarningStart)
        visible(blueprint,time>=Scene.ProposalStart)
        warning.Enabled=time>=Scene.WarningStart and time<Scene.ProposalStart
        water.CFrame=CFrame.new(origin+Vector3.new(0,level,-48));water.LocalTransparencyModifier=level<.15 and 1 or 0
        self.Rain.Rate=storm and 650 or 0
        for _,drop in rain do local fall=(time*79+drop.Phase)%48
            drop.Part.CFrame=CFrame.new(origin+Vector3.new(drop.X+fall*.27,49-fall,drop.Z))*CFrame.Angles(0,0,.27)
            drop.Part.LocalTransparencyModifier=storm and 0 or 1 end
        for _,v in currents do
            v.Part.CFrame=CFrame.new(origin+Vector3.new(v.X+math.sin(time*.45+v.Z)*4,level+.18,v.Z+(time*4)%13))
            v.Part.LocalTransparencyModifier=level<.15 and 1 or 0 end
        for i,v in trees do
            local fallen=(i==2 or i==5 or i==6 or i==8) and smooth(progress(time,12,19)) or 0
            local tilt=CFrame.Angles(0,0,fallen*1.46+(storm and math.sin(time*2)*.045 or 0))
            local cleared=time>=82 and fallen>0
            v.Model:PivotTo(CFrame.new(v.Ground)*tilt*CFrame.new(-v.Ground)*v.Frame)
            visible(v.Model,not cleared)
        end
        for _,v in damaged do
            -- Clear broken panels before the repair montage, avoiding a roof sweeping through the house.
            local transparency=0
            if time<76 then
                v.Model:PivotTo(v.Original:Lerp(v.Debris,smooth(progress(time,v.At,v.At+2.5))))
                transparency=smooth(progress(time,70,76))
            else
                v.Model:PivotTo(v.Original+Vector3.new(0,1.2*(1-smooth(progress(time,76,86))),0))
                transparency=1-smooth(progress(time,76,82))
            end
            for _,panel in v.Parts do panel.LocalTransparencyModifier=transparency end
        end
        for _,v in brokenSupports do v.LocalTransparencyModifier=smooth(progress(time,10,15))*(1-smooth(rebuilding)) end
        for _,v in dirty do v.Part.Color=v.Original:Lerp(v.Muddy,smooth(progress(time,10,22))*(1-smooth(rebuilding))) end
        for _,v in wreckage do
            local cleared=progress(time,70+(v.Home-1)*1.6,77+(v.Home-1)*1.6)
            v.Part.LocalTransparencyModifier=time<12 and 1 or cleared
        end
        for i,v in family do
            local point,kind,yaw=evacuation(0,i,time)
            if time>=24 and time<70 then point,kind=homes[1].Rooftop+Vector3.new((i-2)*3.5,0,-1),"wave" end
            if time>=70 then point,kind=Vector3.new(-24+(i-1)*3,8,-80),"carry" end
            if time>=Scene.WarningStart then kind=time<Scene.ProposalStart and "idle" or "carry" end
            placed(v,point,time>=24 and math.pi or yaw,kind,time+i);visible(v.Model,time<Scene.StormStop or time>=Scene.RebuildStart)
        end
        for index,v in crowds do
            local point,kind,yaw=evacuation(v.Group,v.Member,time)
            if bicycles[index] and time<7 then
                local direction=index==4 and 1 or -1
                point=Vector3.new(index==4 and 55+time*6 or 42-time*5,.4,index==4 and 5 or 7)
                yaw=direction>0 and -math.pi/2 or math.pi/2;kind="bike"
                bicycles[index]:PivotTo(CFrame.new(origin+point)*CFrame.Angles(0,yaw,0));point+=Vector3.new(0,.4,0)
            end
            if bicycles[index] then visible(bicycles[index],time<7) end
            if time>=24 and time<70 then point,kind=refuge(index+3),"idle"
            elseif time>=70 and time<88 then
                if v.Actor.Model:GetAttribute("AgeGroup")=="Child" then point,kind=Vector3.new(-26+index*2,8,-86),"carry"
                else
                    local home=homes[v.Group];point=home.Door+home.Side*(-16-v.Member*4)+home.Front*4
                    kind=v.Member==1 and "hammer" or "carry"
                end
            elseif time>=88 then point,kind=Vector3.new(-30+(v.Group-1)*12+(v.Member-2)*3.3,8,-73),"idle" end
            placed(v.Actor,point,time>=24 and math.pi or yaw,kind,time+v.Group+v.Member)
            visible(v.Actor.Model,time<24 or time>=70)
            if groceries[index] then
                groceries[index]:PivotTo(v.Actor.Model["Right Arm"].CFrame*CFrame.new(0,-1.4,0))
                visible(groceries[index],time<7)
            end
        end
        for _,v in roofFamilies do
            local point=homes[v.Home].Rooftop+Vector3.new((v.Member-2)*2.4,0,-1)
            placed(v.Actor,point,math.pi,"wave",time+v.Member);visible(v.Actor.Model,time>=24 and time<Scene.StormStop)
        end
        help.Enabled=time>=35 and time<47
        local boatPoint=Vector3.new(9,self.PeakFlood+.35,6):Lerp(homes[1].Door+Vector3.new(7,self.PeakFlood+.35,0),smooth(progress(time,48,56)))
        local boatFrame=CFrame.lookAt(origin+boatPoint,origin+boatPoint+Vector3.new(-1,0,-.3))
        boat:PivotTo(boatFrame);visible(boat,time>=48 and time<58)
        for i,v in rescuers do
            placed(v,(boatFrame*CFrame.new(-1.5,1.1,(i-1.5)*4)).Position-origin,1.2,i==2 and "wave" or "idle",time);visible(v.Model,time>=48 and time<58)
        end
        local working=time>=70 and time<88
        for i,v in workers do
            local point=working and (i==3 and Vector3.new(0,8,-83) or homes[2].Door+homes[2].Front*5+homes[2].Side*(-10-i*6))
                or Vector3.new(-8+(i-1)*3.1,8,-79)
            placed(v,point,math.pi,working and (i==1 and "hammer" or "carry") or "carry",time);visible(v.Model,time>=70)
        end
        for i,v in volunteers do
            local point=refuge(i+21);local kind="idle"
            if time>=70 and time<88 then
                local home=homes[i];local q=(time-70+i*.4)%4/4
                point=(home.Door-home.Side*14+home.Front*7):Lerp(home.Door-home.Side*21+home.Front*4,q)
                kind=v.Model:GetAttribute("AgeGroup")=="Child" and "idle" or "carry"
                if v.Model:GetAttribute("AgeGroup")=="Child" then point=Vector3.new(-21+i*4,8,-88) end
                if cleaners[i] and v.Model:GetAttribute("AgeGroup")~="Child" then
                    point=Vector3.new(-24+(i-1)*16,.4,17);kind="sweep"
                end
            elseif time>=88 then point,kind=Vector3.new(-30+i*9,8,-89),"carry" end
            placed(v,point,math.pi,kind,time+i);visible(v.Model,time>=70)
            carried[i].CFrame=v.Model.Torso.CFrame*CFrame.new(0,-.3,-1)
            carried[i].LocalTransparencyModifier=working and kind=="carry" and 0 or 1
            if cleaners[i] then
                cleaners[i].Broom:PivotTo(v.Model["Right Arm"].CFrame*CFrame.new(0,-.5,-.7)*CFrame.Angles(.25,0,math.sin(time*3)*.12))
                visible(cleaners[i].Broom,working and kind=="sweep")
                cleaners[i].Bag.LocalTransparencyModifier=time>=73 and time<88 and kind=="sweep" and 0 or 1
            end
        end
        local dogPoint,dogKind,dogYaw=evacuation(3,2,time)
        dogPoint+=Vector3.new(2,0,1)
        if time>=24 and time<70 then dogPoint=homes[3].Rooftop+Vector3.new(4.5,0,-1) end
        if time>=70 then dogPoint=Vector3.new(24,8,-84) end
        if time>=52 and time<58 then dogPoint=(boatFrame*CFrame.new(1.4,1.4,-3.8)).Position-origin end
        placed(dogs[1],dogPoint,dogYaw,time>=24 and "idle" or dogKind,time);visible(dogs[1].Model,time<58 or time>=70)
        local secondPet=homes[5].Rooftop+Vector3.new(4.5,0,-1)
        if time>=54 and time<58 then secondPet=(boatFrame*CFrame.new(1.4,1.5,3.8)).Position-origin end
        if time>=70 then secondPet=Vector3.new(31,8,-86) end
        placed(dogs[2],secondPet,math.pi,"idle",time);visible(dogs[2].Model,time>=24 and time<58 or time>=70)
        local arm=workers[1].Model:FindFirstChild("Right Arm")
        if arm then hammer.CFrame=arm.CFrame*CFrame.new(0,-.9,-.4);hammerHead.CFrame=hammer.CFrame*CFrame.new(0,.7,0) end
        hammer.LocalTransparencyModifier,hammerHead.LocalTransparencyModifier=working and 0 or 1,working and 0 or 1
        for _,v in planks do v.LocalTransparencyModifier=working and 0 or 1 end
        local entry=scientistPoint+Vector3.new(8,0,-12):Lerp(Vector3.zero,smooth(progress(time,Scene.ProposalStart,Scene.ProposalStart+2.5)))
        placed(scientist,entry,math.pi,time<Scene.ProposalStart+2.5 and "walk" or "explain",time)
        visible(scientist.Model,time>=Scene.ProposalStart)
        visible(prep,time>=88)
        local sharingAt=Scene.SharingStart+1
        for i,v in bundles do visible(v.Contents,time>=sharingAt+i*1.8,true) end
        delivery.LocalTransparencyModifier=time>=sharingAt and time<130 and 0 or 1
        local bundle=math.clamp(math.floor((time-sharingAt)/2)+1,1,3)
        local move=progress(time,sharingAt+(bundle-1)*2,sharingAt+2+(bundle-1)*2)
        delivery.CFrame=CFrame.new(origin+(tablePoint+Vector3.new(0,2.6,0)):Lerp(bundles[bundle].Point+Vector3.new(0,2.4,0),move)+Vector3.new(0,math.sin(move*math.pi)*.8,0))
        local focus
        if shot.Focus=="family" then focus=evacuation(0,2,time)
        elseif shot.Focus=="door" then focus=homes[1].Door
        elseif shot.Focus=="roof" then focus=homes[1].Rooftop
        elseif shot.Focus=="rebuild" or shot.Focus=="devastation" then focus=homes[2].Door
        elseif shot.Focus=="boat" then focus=boatPoint
        elseif shot.Focus=="supplies" then focus=tablePoint
        elseif shot.Focus=="shares" then focus=Vector3.new(0,8,-68)
        elseif shot.Focus=="warning" then focus=radioPoint
        elseif shot.Focus=="panic" then focus=Vector3.new(-21,8,-80)
        elseif shot.Focus=="scientist" then focus=entry
        elseif shot.Focus=="blueprint" then focus=blueprintPoint end
        local cam=shot.From:Lerp(shot.To,q);local look=shot.Look
        if focus then cam+=focus;look+=focus end
        local drift=shot.Focus=="family" and math.sin(time*5)*.055 or storm and math.sin(time*3)*.04 or 0
        local frame=CFrame.lookAt(origin+cam+Vector3.new(drift,0,0),origin+look)
        -- Nearby streaks keep the rain readable during moving close-ups.
        for _,drop in nearRain do
            local position=(frame*CFrame.new(drop.X,18-(time*55+drop.Phase)%36,drop.Z)).Position
            drop.Part.CFrame=CFrame.new(position)*CFrame.Angles(0,0,.27)
            drop.Part.LocalTransparencyModifier=storm and 0 or 1
        end
        return frame,shot,index,shot.FOV
    end
    function self:Destroy() root:Destroy() end
    self:Update(0)
    root:SetAttribute("ActorCount",self.ActorCount);root:SetAttribute("BuildingCount",#homes+3)
    return self
end
function Scene.Create(assets)
    local root=make("Model",{Name="BrightHavenFlashbackSet"},workspace)
    local ok,result=pcall(buildScene,assets,root)
    if not ok then root:Destroy();error(result,0) end
    return result
end
return Scene
