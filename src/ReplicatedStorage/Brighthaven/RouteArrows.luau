local RouteArrows={}
function RouteArrows.Create()
    local origin,target
    local beam=Instance.new("Beam")
    beam.Name="ReliefRoute"
    beam.Width0,beam.Width1=1,1
    beam.FaceCamera=true
    beam.LightEmission=1
    beam.Texture="rbxassetid://10249261576"
    beam.TextureLength=5
    beam.TextureSpeed=1
    beam.Color=ColorSequence.new(Color3.fromRGB(255,120,25))
    beam.Transparency=NumberSequence.new(0)
    beam.Enabled=false
    beam.ZOffset=.06
    beam.Parent=workspace
    local glow=beam:Clone()
    glow.Name="ReliefRouteGlow"
    glow.Width0,glow.Width1=1.4,1.4
    glow.Color=ColorSequence.new(Color3.fromRGB(255,146,49))
    glow.Transparency=NumberSequence.new(.75)
    glow.ZOffset=-.06
    glow.Parent=workspace
    return function(root,destination)
        if not root or not destination then
            beam.Enabled=false
            glow.Enabled=false
            return
        end
        if not origin or origin.Parent~=root then
            if origin then origin:Destroy() end
            origin=Instance.new("Attachment")
            origin.Name="ReliefRouteStart"
            origin.Position=Vector3.new(0,2,0)
            origin.Parent=root
            beam.Attachment1=origin
            glow.Attachment1=origin
        end
        if not target or target.Parent~=destination then
            if target then target:Destroy() end
            target=Instance.new("Attachment")
            target.Name="ReliefDestination"
            target.Parent=destination
            beam.Attachment0=target
            glow.Attachment0=target
        end
        beam.Enabled=true
        glow.Enabled=true
    end
end
return RouteArrows
