local logs=workspace['Possible Map Replacement'].Tutorial.Tutorial_2:WaitForChild('Logs')
for row=1,3 do for _,log in logs['Log_column'..row]:GetChildren() do if log:IsA('BasePart') then
 local gui=log:WaitForChild('TopNumber')
 local marker=log:WaitForChild('UprightNumber')
 local back=marker:WaitForChild('BackNumber')
 local function update()
  local text=gui.TextLabel.Text
  local show=gui.Enabled and not log:GetAttribute('Sinking') and text:match('^%d+$')~=nil
  back.TextLabel.Text=text;back.Enabled=show
  for _,p in marker:GetChildren() do if p:IsA('BasePart') then p.Transparency=show and (p:GetAttribute('ShownTransparency') or 0) or 1 end end
 end
 gui.TextLabel:GetPropertyChangedSignal('Text'):Connect(update)
 gui:GetPropertyChangedSignal('Enabled'):Connect(update)
 log:GetAttributeChangedSignal('Sinking'):Connect(update)
 update()
end end end
