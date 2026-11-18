local traffic = require(game.ServerScriptService.BrighthavenTransit.RoadNetwork)
local Graph = {Roads={},Nodes={}}
local spacing = 6
local candidates, nodes, byKey = {}, {}, {}
local function key(x,z) return x..":"..z end
for _,part in ipairs(traffic.Roads[1].Parent:GetChildren()) do
	if part:IsA("BasePart") and part.Name=="DriveGround" and part.Size.Y<1.5
		and math.min(part.Size.X,part.Size.Z)>=3
		and (math.min(part.Size.X,part.Size.Z)<=60 or part:FindFirstChildOfClass("CylinderMesh"))
		and math.abs(part.Color.R-99/255)<.015 and math.abs(part.Color.G-95/255)<.015 then
		table.insert(Graph.Roads,part)
	end
end

function Graph.Contains(point)
	for _,road in ipairs(Graph.Roads) do
		local p=road.CFrame:PointToObjectSpace(point)
		local x,z=p.X/(road.Size.X/2),p.Z/(road.Size.Z/2)
		if road:FindFirstChildOfClass("CylinderMesh") then
			if x*x+z*z<=1 then return true end
		elseif math.abs(x)<=1 and math.abs(z)<=1 then return true end
	end
	return false
end

-- Candidate generation with yield
local count = 0
for _,road in ipairs(Graph.Roads) do
	local u,v=road.CFrame.RightVector,road.CFrame.LookVector
	local extent=Vector3.new(math.abs(u.X),0,math.abs(u.Z))*road.Size.X/2
		+Vector3.new(math.abs(v.X),0,math.abs(v.Z))*road.Size.Z/2
	for x=math.ceil((road.Position.X-extent.X)/spacing),math.floor((road.Position.X+extent.X)/spacing) do
		for z=math.ceil((road.Position.Z-extent.Z)/spacing),math.floor((road.Position.Z+extent.Z)/spacing) do
			candidates[key(x,z)]={X=x,Z=z}
			count += 1
			if count % 500 == 0 then task.wait() end
		end
	end
end

-- Node validation with yield
count = 0
for id,cell in pairs(candidates) do
	local position=Vector3.new(cell.X*spacing,0,cell.Z*spacing)
	if Graph.Contains(position) then
		local node={Id=id,X=cell.X,Z=cell.Z,Position=position,Neighbours={}}
		table.insert(nodes,node);byKey[id]=node
	end
	count += 1
	if count % 200 == 0 then task.wait() end
end

-- Neighbor validation with yield
count = 0
for _,node in ipairs(nodes) do
	for x=-1,1 do for z=-1,1 do
			local neighbor=(x~=0 or z~=0) and byKey[key(node.X+x,node.Z+z)]
			if neighbor then
				local valid=true
				for step=1,5 do
					if not Graph.Contains(node.Position:Lerp(neighbor.Position,step/6)) then valid=false;break end
				end
				if valid then table.insert(node.Neighbours,neighbor) end
			end
		end end
	count += 1
	if count % 100 == 0 then task.wait() end
end

-- Connected components with yield
local visited={}
Graph.Components=0
count = 0
for _,start in ipairs(nodes) do
	if not visited[start] then
		Graph.Components+=1
		local group,index={start},1
		visited[start]=true
		while index<=#group do
			local node=group[index];index+=1
			for _,neighbor in ipairs(node.Neighbours) do
				if not visited[neighbor] then visited[neighbor]=true;table.insert(group,neighbor) end
			end
		end
		if #group>#Graph.Nodes then Graph.Nodes=group end
	end
	count += 1
	if count % 200 == 0 then task.wait() end
end
assert(#Graph.Nodes>10,"No connected town roads for navigation")
return Graph