local Motion = {FadeDuration = 0.4, TourDuration = 36, ReturnDuration = 2.5}

function Motion.Ease(alpha)
    local t = math.clamp(alpha, 0, 1)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

-- School, town center, railway, neighborhood, then Captain Kappa.
local shots = {
{Vector3.new(340,115,120),Vector3.new(250,0,20)},
{Vector3.new(260,130,-190),Vector3.new(90,0,-150)},
{Vector3.new(-300,110,-160),Vector3.new(-210,0,60)},
{Vector3.new(-180,90,310),Vector3.new(30,0,240)},
{Vector3.new(-65,65,100),Vector3.new(0,6,0)},
{Vector3.new(-35,25,40),Vector3.new(0,1,0)},
}
local function spline(a,b,c,d,t)
    return (b*2+(c-a)*t+(a*2-b*5+c*4-d)*t*t+(-a+b*3-c*3+d)*t*t*t)*.5
end
function Motion.Sample(captain, alpha)
    local t = Motion.Ease(alpha)*(#shots-1)
    local i = math.min(math.floor(t)+1,#shots-1)
    local q = t-(i-1)
    local a,b,c,d = shots[math.max(1,i-1)],shots[i],shots[i+1],shots[math.min(#shots,i+2)]
    local position = captain+spline(a[1],b[1],c[1],d[1],q)
    local focus = captain+spline(a[2],b[2],c[2],d[2],q)
    return CFrame.lookAt(position, focus, Vector3.yAxis), focus
end

return Motion
