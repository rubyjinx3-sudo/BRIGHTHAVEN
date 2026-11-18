local Service={}
local Players=game:GetService('Players')
local prompts=game:GetService('ProximityPromptService')
local RS=game.ReplicatedStorage
local root=workspace.BarangayCommunityBlocks
local hub=root.CommunityGameHub
local Practice=require(RS.Brighthaven.TutorialPractice)
local resets=game.ServerScriptService:FindFirstChild('BarangayPracticeReset') or Instance.new('BindableEvent')
resets.Name='BarangayPracticeReset';resets.Parent=game.ServerScriptService
local busy,cooldown={},{}
local function ready(p)
 local c=p.Character;local h=c and c:FindFirstChildOfClass('Humanoid');local r=c and c:FindFirstChild('HumanoidRootPart')
 return r and h and h.Health>0 and not h.SeatPart and not p:GetAttribute('Sleeping') and not p:GetAttribute('HomeInteriorActive'),r
end
local function move(p,point)
 local r=p.Character.HumanoidRootPart;r.Anchored=false;r.AssemblyLinearVelocity=Vector3.zero;r.AssemblyAngularVelocity=Vector3.zero
 p.Character:PivotTo(CFrame.new(point));p:SetAttribute('CommunityNotice','Talk to the helper to begin. During a practice visit, press R near the helper to go back to the plaza.')
end
function Service.VisitPractice(p,index)
 local ok,r=ready(p)
 if not ok or type(index)~='number' or index%1~=0 or not Practice.Anchors[index] then return false end
 if (r.Position-Vector3.new(0,-140,122)).Magnitude>55 or os.clock()<(cooldown[p] or 0) then return false end
 local tutorial=workspace['Possible Map Replacement'].Tutorial['Tutorial_'..index]
 local owner=tutorial:GetAttribute('PracticeOwner')
 if owner and owner~=p.UserId and tutorial:GetAttribute('PracticeActive') then return false end
 cooldown[p]=os.clock()+1
 move(p,Practice.Anchors[index].Position+Vector3.new(0,0,7))
 resets:Fire(p,index)
 p:SetAttribute('CommunityPracticeVisit',index)
 return true
end
function Service.Return(p)
 local ok,r=ready(p)
 if not ok or not Practice.PlayerStage(p) then return false end
 local stage=Practice.PlayerStage(p)
 if (r.Position-Practice.Anchors[stage].Position).Magnitude>35 then return false end
 move(p,Vector3.new(0,-140,98));p:SetAttribute('CommunityPracticeVisit',nil)
 return true
end
function Service.ToggleDoor(p,prompt)
 if not prompt or not prompt:IsDescendantOf(root) or prompt.Name~='OpenNeighborhoodDoor' then return false end
 local ok,r=ready(p)
 local door=prompt:FindFirstChild('DoorModel') and prompt.DoorModel.Value
 if not ok or not door or busy[door] or (r.Position-prompt.Parent.Position).Magnitude>11 then return false end
 local closed,hinge=door:GetAttribute('ClosedPivot'),door:GetAttribute('HingeFrame')
 if typeof(closed)~='CFrame' or typeof(hinge)~='CFrame' then return false end
 busy[door]=true
 local opening=not door:GetAttribute('Open')
 local target=opening and hinge*CFrame.Angles(0,math.rad(100),0)*hinge:Inverse()*closed or closed
 local from=door:GetPivot()
 for i=1,12 do door:PivotTo(from:Lerp(target,i/12));task.wait(.025) end
 door:SetAttribute('Open',opening);busy[door]=nil
 return true
end
function Service.Init()
 prompts.PromptTriggered:Connect(function(prompt,p)
  if prompt.Name=='VisitPracticeGame' and prompt:IsDescendantOf(hub) then Service.VisitPractice(p,prompt:GetAttribute('PracticeIndex'))
  elseif prompt.Name=='ReturnToBarangay' then Service.Return(p)
  elseif prompt.Name=='OpenNeighborhoodDoor' then Service.ToggleDoor(p,prompt) end
 end)
 Players.PlayerRemoving:Connect(function(p) cooldown[p]=nil end)
end
return Service
