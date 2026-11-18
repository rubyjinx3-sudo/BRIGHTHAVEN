local Theme = {}
Theme.Yellow = Color3.fromRGB(255,211,78)
Theme.White = Color3.new(1,1,1)
Theme.Ink = Color3.fromRGB(48,52,55)
local bound = setmetatable({}, {__mode="k"})
local legacy = {DialogueSystem=true,SupplyGui=true,ForkliftCargoGui=true,ChunkingController=true,DivisionTownUI=true,Tutorial3Deliveries=true}

function Theme.Owns(gui)
    return gui:IsA("ScreenGui") and (gui.Name:lower():find("brighthaven",1,true) ~= nil or legacy[gui.Name] == true)
end

local function mapArt(object)
    local current=object
    while current do
        if current.Name=="TownView" then return true end
        current=current.Parent
    end
    return false
end

local function apply(object)
    if mapArt(object) or object:IsA("ViewportFrame") then return end
    local menu=object:FindFirstAncestor("BrightHavenMenu")
    if menu and not object:IsA("GuiButton") and not object.Parent:IsA("GuiButton") then return end
    if object:IsA("UIGradient") then
        object.Enabled=object:GetAttribute("ThemeGradient")==true
    elseif object:IsA("UIStroke") then
        local semantic=object:GetAttribute("SemanticColor")
        object.Color=typeof(semantic)=="Color3" and semantic or object.Parent:IsA("GuiButton") and Theme.White or Theme.Yellow
    elseif object:IsA("GuiObject") then
        if object.BackgroundTransparency<1 then
            local name=object.Name:lower()
            local accent=object:IsA("GuiButton") and object.Active or name:find("badge",1,true) or name=="fill" or name=="earned"
                or name=="completed" or name=="binding" or name=="chapterribbon"
            local background=accent and Theme.Yellow or Theme.White
            if name=="xpbar" or name=="levelbar" or name=="track"
                or name=="frame" and object.Parent.Parent and object.Parent.Parent.Name=="Vitals" then
                background=Color3.fromRGB(214,218,224)
            end
            local selected=object:GetAttribute("ThemeSelected")
            if object:IsA("GuiButton") and selected~=nil then
                background=selected and Theme.Yellow or Theme.White
            end
            local semantic=object:GetAttribute("SemanticColor")
            if typeof(semantic)=="Color3" then background=semantic end
            if object.BackgroundColor3~=background then object.BackgroundColor3=background end
            object.BorderSizePixel=0
        end
        if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
            local foreground=object:GetAttribute("SemanticTextColor")
            object.TextColor3=typeof(foreground)=="Color3" and foreground or Theme.Ink
            if object.Font==Enum.Font.GothamBlack then object.Font=Enum.Font.FredokaOne end
            if object:IsA("TextBox") then object.PlaceholderColor3=Theme.Ink end
        elseif (object:IsA("ImageLabel") or object:IsA("ImageButton"))
            and (object.Name=="Symbol" or object.Name=="Icon" or object.Name=="CoinIcon" or object.Name=="Checked" or object.Parent:IsA("GuiButton")) then
            local semantic=object:GetAttribute("SemanticColor")
            object.ImageColor3=typeof(semantic)=="Color3" and semantic or object.Name=="CoinIcon" and Theme.Yellow or Theme.Ink
        end
    end
end

function Theme.Bind(gui)
    if bound[gui] or not Theme.Owns(gui) then return end
    bound[gui]=true
    gui:SetAttribute("KidTheme","YellowWhite")
    local function watch(object)
        if bound[object] or mapArt(object) then return end
        bound[object]=true
        local updating=false
        local function refresh()
            if updating then return end
            updating=true
            apply(object)
            updating=false
        end
        refresh()
        object:GetAttributeChangedSignal("SemanticColor"):Connect(refresh)
        object:GetAttributeChangedSignal("SemanticTextColor"):Connect(refresh)
        object:GetAttributeChangedSignal("ThemeSelected"):Connect(refresh)
        object:GetAttributeChangedSignal("ThemeGradient"):Connect(refresh)
        if object:IsA("GuiObject") and not object:IsA("ViewportFrame") then
            object:GetPropertyChangedSignal("BackgroundColor3"):Connect(refresh)
            object:GetPropertyChangedSignal("BackgroundTransparency"):Connect(refresh)
            if object:IsA("GuiButton") then object:GetPropertyChangedSignal("Active"):Connect(refresh) end
            if object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox") then
                object:GetPropertyChangedSignal("TextColor3"):Connect(refresh)
            elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
                object:GetPropertyChangedSignal("ImageColor3"):Connect(refresh)
            end
        elseif object:IsA("UIStroke") then object:GetPropertyChangedSignal("Color"):Connect(refresh) end
    end
    for _,object in ipairs(gui:GetDescendants()) do watch(object) end
    gui.DescendantAdded:Connect(watch)
end

function Theme.DialoguePaper(frame,tint)
    frame.BackgroundColor3=Theme.White
    frame:SetAttribute("SemanticColor",Theme.White)
    local gradient=frame:FindFirstChild("DialogueWash") or Instance.new("UIGradient")
    gradient.Name="DialogueWash"
    gradient.Color=ColorSequence.new(Theme.White,tint)
    gradient.Rotation=90
    gradient:SetAttribute("ThemeGradient",true)
    gradient.Parent=frame
end
return Theme
