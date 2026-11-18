local UIComponents = {}

function UIComponents.createFrame(name, parent, size, position, bgColor)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size or UDim2.fromScale(1, 1)
	frame.Position = position or UDim2.fromScale(0, 0)
	frame.BackgroundColor3 = bgColor or Color3.fromRGB(30, 40, 60)
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

function UIComponents.addCorner(instance, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 8)
	corner.Parent = instance
	return corner
end

function UIComponents.addStroke(instance, color, thickness)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(255, 255, 255)
	stroke.Thickness = thickness or 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
	return stroke
end

function UIComponents.createTextLabel(name, parent, size, position, text, textSize)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size or UDim2.fromScale(1, 1)
	label.Position = position or UDim2.fromScale(0, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.SourceSans
	label.Text = text or ""
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 18
	label.RichText = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

function UIComponents.createButton(name, parent, size, position, text, bgColor)
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = size or UDim2.fromScale(0.2, 0.1)
	btn.Position = position or UDim2.fromScale(0, 0)
	btn.BackgroundColor3 = bgColor or Color3.fromRGB(0, 160, 230)
	btn.Font = Enum.Font.GothamBold
	btn.Text = text or "BUTTON"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 16
	btn.BorderSizePixel = 0
	UIComponents.addCorner(btn, 8)
	btn.Parent = parent
	return btn
end

function UIComponents.createTextBox(name, parent, size, position, placeholder)
	local textBox = Instance.new("TextBox")
	textBox.Name = name
	textBox.Size = size or UDim2.fromScale(0.2, 0.1)
	textBox.Position = position or UDim2.fromScale(0, 0)
	textBox.BackgroundColor3 = Color3.fromRGB(15, 22, 34)
	textBox.Font = Enum.Font.Gotham
	textBox.PlaceholderText = placeholder or ""
	textBox.Text = ""
	textBox.TextColor3 = Color3.fromRGB(255, 255, 255)
	textBox.TextSize = 18
	textBox.ClearTextOnFocus = true
	UIComponents.addCorner(textBox, 8)
	UIComponents.addStroke(textBox, Color3.fromRGB(0, 225, 255), 2)
	textBox.Parent = parent
	return textBox
end

return UIComponents
