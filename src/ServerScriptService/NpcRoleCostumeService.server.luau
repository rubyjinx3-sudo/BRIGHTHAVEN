local Players=game.Players
local Style=require(game.ReplicatedStorage.Brighthaven.NpcRoleStyle)
local function apply(model)
 if not model:IsA('Model') or Players:GetPlayerFromCharacter(model) or model:FindFirstAncestor('WorldMapModel') then return end
 if not model:FindFirstChildOfClass('Humanoid') and not (model:FindFirstChild('RiderHead') and model:FindFirstChild('RiderBody')) then return end
 local role=Style.Infer(model)
 if role and (model:GetAttribute('CostumeRole')~=role or model:GetAttribute('RoleCostumeVersion')~=Style.Version) then Style.Apply(model,role) end
end
for _,m in ipairs(workspace:GetDescendants()) do if m:IsA('Model') then apply(m) end end
workspace.DescendantAdded:Connect(function(x)
 if x:IsA('Humanoid') then task.defer(function() if x.Parent then apply(x.Parent) end end)
 elseif x:IsA('Model') then task.defer(function() if x.Parent then apply(x) end end) end
end)
