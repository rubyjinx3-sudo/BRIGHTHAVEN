local QuickPlay=require(game.ReplicatedStorage.Brighthaven.QuickPlaySettings)
local Motion = {FadeDuration = 0.4, TourDuration = QuickPlay.IntroTourSeconds, ReturnDuration = QuickPlay.IntroReturnSeconds}

function Motion.Ease(alpha)
    local t = math.clamp(alpha, 0, 1)
    return t * t * t * (t * (t * 6 - 15) + 10)
end

-- School, town center, railway, neighborhood, then Captain Kappa.
local shots = {
 {Vector3.new(-100,95,160),Vector3.new(0,0,0)},
 {Vector3.new(-55,42,70),Vector3.new(0,3,0)},
 {Vector3.new(-35,18,35),Vector3.new(0,1,0)},
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
