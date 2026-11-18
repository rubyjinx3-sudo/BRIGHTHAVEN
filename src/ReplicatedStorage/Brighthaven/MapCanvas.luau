local MapCanvas = {}
local function make(class, props, parent)
    local object = Instance.new(class)
    for key,value in pairs(props) do object[key] = value end
    object.Parent = parent
    return object
end
local function round(object) make("UICorner", {CornerRadius=UDim.new(0,8)}, object) end

function MapCanvas.Create(parent, name, compact)
    local root = make(compact and "CanvasGroup" or "Frame", {Name=name, BackgroundTransparency=1, ClipsDescendants=true, Active=true}, parent)
    if compact then make("UICorner", {CornerRadius=UDim.new(.5,0)}, root) end
    local view = make("ViewportFrame", {Name="Scene", Size=UDim2.fromScale(1,1), BorderSizePixel=0,
        BackgroundColor3=Color3.fromRGB(116,196,220), Ambient=Color3.fromRGB(220,220,220),
        LightColor=Color3.new(1,1,1), LightDirection=Vector3.new(-1,-2,-1)}, root)
    local world = make("WorldModel", {}, view)
    local inputSurface=make("TextButton",{Name="MapInput",Size=UDim2.fromScale(1,1),Text="",AutoButtonColor=false,
        BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1},root)
    local camera = make("Camera", {FieldOfView=40}, view)
    view.CurrentCamera = camera
    local lines = make("Frame", {Name="Route", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=2}, root)
    local pins = make("Frame", {Name="Pins", Size=UDim2.fromScale(1,1), BackgroundTransparency=1, ZIndex=3}, root)
    local cache, markerPass, pool, labels, labelPass, occupied, labelLeaders = {}, {}, {}, {}, {}, {}, {}
    local pass, visibleLines = 0, 0
    local lastCenter, lastHalfHeight, lastUp, lastSize
    local self = {Root=root, View=view, Input=inputSurface, Camera=camera, Ready=false}
    task.spawn(function()
        local practice = require(game.ReplicatedStorage.Brighthaven.TutorialPractice)
        repeat task.wait(.25) until practice.CanUseWorld(game.Players.LocalPlayer) or not root.Parent
        if not root.Parent then return end
        local source = game.ReplicatedStorage.Brighthaven:WaitForChild("WorldMapModel")
        local count, started, slice = 0, os.clock(), os.clock()
        -- The authored preview is already simplified; warm it once in small batches.
        for _,part in ipairs(source:GetChildren()) do
            if not root.Parent then return end
            if part:IsA("BasePart") then
                part:Clone().Parent = world
                count += 1
            end
            if os.clock()-slice > .002 then task.wait(); slice=os.clock() end
        end
        root:SetAttribute("VisualParts", count)
        root:SetAttribute("BuildMilliseconds", (os.clock()-started)*1000)
        self.Ready = true
    end)

    function self:SetCamera(center, halfHeight, up)
        up = up or Vector3.new(0,0,-1)
        local size = view.AbsoluteSize
        if lastCenter==center and lastHalfHeight==halfHeight and lastUp==up and lastSize==size then return false end
        lastCenter, lastHalfHeight, lastUp, lastSize = center, halfHeight, up, size
        local height = halfHeight / math.tan(math.rad(20))
        camera.CFrame = CFrame.lookAt(center + Vector3.new(0,height,0), center, up)
        return true
    end
    function self:Project(position)
        local point = camera.CFrame:PointToObjectSpace(position)
        local depth = -point.Z
        if depth <= 0 then return nil end
        local size = view.AbsoluteSize
        local scale = size.Y / (2 * math.tan(math.rad(camera.FieldOfView/2)) * depth)
        return Vector2.new(size.X/2+point.X*scale, size.Y/2-point.Y*scale)
    end
    function self:Unproject(point)
        local size=view.AbsoluteSize
        local scale=2*math.tan(math.rad(camera.FieldOfView/2))/math.max(1,size.Y)
        local ray=camera.CFrame:VectorToWorldSpace(Vector3.new((point.X-size.X/2)*scale,-(point.Y-size.Y/2)*scale,-1))
        if math.abs(ray.Y)<.001 then return nil end
        return camera.CFrame.Position+ray*((-140-camera.CFrame.Position.Y)/ray.Y)
    end
    function self:Route(points)
        local used = 0
        for index=2,#points do
            local a,b = self:Project(points[index-1]), self:Project(points[index])
            if a and b and (b-a).Magnitude > .5 then
                used += 1
                local line = pool[used]
                if not line then
                    line = make("Frame", {Name="Segment"..used, AnchorPoint=Vector2.new(.5,.5), BorderSizePixel=0,
                        BackgroundColor3=Color3.fromRGB(255,211,78), ZIndex=2}, lines)
                    make("UIStroke", {Color=Color3.new(1,1,1), Thickness=1.5}, line)
                    pool[used] = line
                end
                local delta = b-a
                line.Position = UDim2.fromOffset((a.X+b.X)/2,(a.Y+b.Y)/2)
                line.Size = UDim2.fromOffset(delta.Magnitude,compact and 3 or 4)
                line.Rotation = math.deg(math.atan2(delta.Y,delta.X))
                line.Visible = true
            end
        end
        for index=used+1,visibleLines do pool[index].Visible=false end
        visibleLines = used
        root:SetAttribute("RouteSegments", used)
    end
    function self:BeginMarkers()
        pass += 1
        table.clear(occupied)
    end
    function self:EndMarkers()
        for id,marker in pairs(cache) do
            if markerPass[id]~=pass then marker.Visible=false end
        end
        for id,label in pairs(labels) do
            if labelPass[id]~=pass then label.Visible=false;if labelLeaders[id] then labelLeaders[id].Visible=false end end
        end
    end
    function self:Marker(id, position, color, callback, isPlayer, facing)
        markerPass[id] = pass
        local marker = cache[id]
        if not marker then
            marker = make("ImageButton", {Name=id, Size=UDim2.fromOffset(isPlayer and 30 or compact and 26 or 34,isPlayer and 30 or compact and 26 or 34),
                AnchorPoint=Vector2.new(.5,.5), BackgroundColor3=isPlayer and color or Color3.fromRGB(255,211,78), BackgroundTransparency=isPlayer and 1 or 0, BorderSizePixel=0,
                Image=isPlayer and "rbxassetid://137201810153515" or "rbxassetid://71533546151541", ZIndex=isPlayer and 7 or 4}, pins)
            round(marker)
            if not isPlayer then
                marker.UICorner.CornerRadius=UDim.new(.5,0)
                make("UIStroke",{Color=Color3.new(1,1,1),Thickness=2},marker)
            end
            if callback then
                local last=0
                marker.Activated:Connect(function()
                    local now=os.clock()
                    if now-last<.35 then last=0;callback() else last=now end
                end)
            end
            marker.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton2 and self.OnClear then self.OnClear() end
            end)
            cache[id] = marker
        end
        marker.ImageColor3 = isPlayer and color or Color3.fromRGB(48,52,55)
        marker.BackgroundColor3=isPlayer and color or Color3.fromRGB(255,211,78)
        local point = self:Project(position)
        marker.Visible = point~=nil and point.X>=10 and point.Y>=10 and point.X<=view.AbsoluteSize.X-10 and point.Y<=view.AbsoluteSize.Y-10
        if point then
            marker.Position = UDim2.fromOffset(point.X,point.Y)
            if isPlayer and facing then
                local forward = self:Project(position+facing*10)
                if forward then marker.Rotation = math.deg(math.atan2(forward.X-point.X,-(forward.Y-point.Y)))-45 end
            end
        end
        return marker
    end
    function self:Label(id,position,title,callback)
        local point=self:Project(position)
        if not point then return end
        local size=view.AbsoluteSize
        local width=compact and 112 or math.clamp(#title*7+16,72,156)
        local p=Vector2.new(point.X-width/2,point.Y+17)
        if point.X<0 or point.Y<0 or point.X>size.X or point.Y>size.Y then return end
        local function free(candidate)
            if candidate.X<3 or candidate.Y<3 or candidate.X+width>size.X-3 or candidate.Y+24>size.Y-3 then return false end
            if compact then
                for _,corner in ipairs({candidate,candidate+Vector2.new(width,0),candidate+Vector2.new(0,24),candidate+Vector2.new(width,24)}) do
                    if (corner-size/2).Magnitude>size.X/2-5 then return false end
                end
            end
            for _,box in ipairs(occupied) do
                if candidate.X<box.X+box.W and candidate.X+width>box.X and candidate.Y<box.Y+26 and candidate.Y+24>box.Y then return false end
            end
            return true
        end
        if not free(p) then
            local found=false
            for _,offset in ipairs({-64,46,-92,74,-120,102}) do
                local candidate=Vector2.new(p.X,p.Y+offset)
                if free(candidate) then p=candidate;found=true;break end
            end
            if not found then return end
        end
        table.insert(occupied,{X=p.X,Y=p.Y,W=width})
        labelPass[id]=pass
        local label=labels[id]
        if not label then
            label=make("TextButton",{Name="Label_"..id,Size=UDim2.fromOffset(width,24),BackgroundColor3=Color3.new(1,1,1),
                BackgroundTransparency=.08,BorderSizePixel=0,TextColor3=Color3.fromRGB(36,51,57),Font=Enum.Font.GothamBold,
                TextSize=compact and 11 or 13,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6},pins)
            round(label)
            if callback then
                local last=0
                label.Activated:Connect(function()
                    local now=os.clock()
                    if now-last<.35 then last=0;callback() else last=now end
                end)
            end
            label.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton2 and self.OnClear then self.OnClear() end
            end)
            labels[id]=label
        end
        label.Position=UDim2.fromOffset(p.X,p.Y);label.Text=title;label.Visible=true
        local leader=labelLeaders[id]
        if not leader then
            leader=make("Frame",{Name="LabelLeader_"..id,AnchorPoint=Vector2.new(.5,.5),BorderSizePixel=0,
                BackgroundColor3=Color3.fromRGB(23,128,108),ZIndex=3},pins)
            labelLeaders[id]=leader
        end
        local endPoint=Vector2.new(math.clamp(point.X,p.X,p.X+width),math.clamp(point.Y,p.Y,p.Y+24))
        local delta=endPoint-point
        leader.Visible=delta.Magnitude>40
        leader.Position=UDim2.fromOffset((point.X+endPoint.X)/2,(point.Y+endPoint.Y)/2)
        leader.Size=UDim2.fromOffset(delta.Magnitude,1)
        leader.Rotation=math.deg(math.atan2(delta.Y,delta.X))
    end
    return self
end

return MapCanvas
