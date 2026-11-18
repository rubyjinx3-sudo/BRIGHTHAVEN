local Client={}
local Players=game.Players
local Data=require(script.Parent.WorldJobData)
function Client.Create(options)
 local p=Players.LocalPlayer;local active,busy,target
 local gui=Instance.new('ScreenGui');gui.Name='BrightHavenHandsOnJobs';gui.ResetOnSpawn=false;gui.DisplayOrder=70;gui.Parent=p.PlayerGui
 local panel=Instance.new('TextLabel');panel.Name='JobGuide';panel.AnchorPoint=Vector2.new(.5,1);panel.Position=UDim2.new(.5,0,1,-86);panel.Size=UDim2.fromOffset(480,84);panel.BackgroundColor3=Color3.fromRGB(255,248,218);panel.TextColor3=Color3.fromRGB(31,58,73);panel.Font=Enum.Font.GothamBold;panel.TextSize=19;panel.TextWrapped=true;panel.Visible=false;panel.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,12);corner.Parent=panel
 local h=Instance.new('Highlight');h.Name='CurrentJobTarget';h.FillTransparency=.8;h.FillColor=Color3.fromRGB(255,210,60);h.OutlineColor=h.FillColor;h.Enabled=false;h.Parent=workspace
 local view={}
 function view:Hide() active=nil;panel.Visible=false;h.Enabled=false end
 function view:Show(a)
  active=a;local d=Data[a.Node];if not d then self:Hide();return end
  local step=a.Physical.Count+1
  target=workspace.BrighthavenWorldJobs[a.Node]:FindFirstChild('Step'..step)
  panel.Text=d.Title..'  '..a.Physical.Count..'/3\n'..(d.Steps[step] or 'Job complete')..' • E / tap'
  panel.Visible=target~=nil;h.Adornee=target;h.Enabled=target~=nil
 end
 game.ProximityPromptService.PromptTriggered:Connect(function(prompt,who)
  if who and who~=p or not active or busy or prompt.Name~='CampaignJobAction' then return end
  if prompt:GetAttribute('Node')~=active.Node then return end
  busy=true;local result=options.Request('ActivityUse',{Index=prompt:GetAttribute('Step')});busy=false
  if result and result.State and result.State.Active then
   if result.State.Active.Phase=='activity' then view:Show(result.State.Active)
   else view:Hide();options.OnFinished() end
  end
 end)
 p.CharacterRemoving:Connect(function() view:Hide() end)
 game.RunService.Heartbeat:Connect(function()
  panel.Size=UDim2.fromOffset(math.min(480,workspace.CurrentCamera.ViewportSize.X-24),84)
  if active and (p:GetAttribute('HomeInteriorActive') or p:GetAttribute('Sleeping')) then view:Hide();options.OnClose() end
 end)
 return view
end
return Client
