local inputService = game:GetService('UserInputService')
local tweenService = game:GetService('TweenService')
local runService = game:GetService('RunService')
local coreGui = game:GetService('CoreGui')
local textService = game:GetService('TextService')
local httpService = game:GetService('HttpService')

local guiParent = coreGui

local VapeLib = {
    Categories = {},
    Objects = {},
    Modules = {},
    ModuleCallbacks = {},
    Theme = {
        Main = Color3.fromRGB(26, 25, 26),
        Accent = Color3.fromRGB(44, 120, 224),
        Text = Color3.fromRGB(200, 200, 200),
        Font = Enum.Font.SourceSans,
        Tween = TweenInfo.new(0.16, Enum.EasingStyle.Linear)
    }
}

local isfile = isfile or function(file)
    local suc, res = pcall(function() return readfile(file) end)
    return suc and res ~= nil and res ~= ""
end
local makefolder = makefolder or function() end
local isfolder = isfolder or function() return false end

local function saveConfig(folder, name, data)
    if not writefile then return end
    local path = ""
    for _, part in ipairs(folder:split("/")) do
        path = path .. (path == "" and "" or "/") .. part
        if not isfolder(path) then makefolder(path) end
    end
    writefile(folder .. "/" .. name .. ".json", httpService:JSONEncode(data))
end

local function loadConfig(folder, name)
    if not isfile(folder.."/"..name..".json") then return nil end
    local suc, res = pcall(function() return httpService:JSONDecode(readfile(folder.."/"..name..".json")) end)
    return suc and res or nil
end

local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    corner.CornerRadius = radius or UDim.new(0, 5)
    corner.Parent = parent
    return corner
end

local function addBlur(parent, mainApi)
    local blur = Instance.new("ImageLabel")
    blur.Name = "Blur"
    blur.Size = UDim2.new(1, 89, 1, 52)
    blur.Position = UDim2.fromOffset(-48, -31)
    blur.BackgroundTransparency = 1
    blur.Image = "rbxassetid://14898786664"
    blur.ScaleType = Enum.ScaleType.Slice
    blur.SliceCenter = Rect.new(52, 31, 261, 502)
    blur.ZIndex = -1
    blur.Visible = mainApi and mainApi.Config.GUISettings.BlurEnabled or false
    blur.Parent = parent
    if mainApi then table.insert(mainApi.BlurElements, blur) end
    return blur
end

local globalUIScales = {}
local userScaleMultiplier = 1

local function updateGlobalScale()
    for _, uiScale in pairs(globalUIScales) do
        if uiScale and uiScale.Parent then
            uiScale.Scale = userScaleMultiplier
        end
    end
end

local tooltipGui
local function createTooltip()
    if tooltipGui then return end
    tooltipGui = Instance.new("ScreenGui")
    tooltipGui.Name = httpService:GenerateGUID(false)
    tooltipGui.DisplayOrder = 999
    tooltipGui.Parent = guiParent
    tooltipGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    tooltipGui.IgnoreGuiInset = true
    tooltipGui.ResetOnSpawn = false
    
    local tooltipScale = Instance.new("UIScale")
    tooltipScale.Parent = tooltipGui
    table.insert(globalUIScales, tooltipScale)
    updateGlobalScale()
    
    local tooltipFrame = Instance.new("Frame")
    tooltipFrame.Name = "Tooltip"
    tooltipFrame.Size = UDim2.fromOffset(100, 20)
    tooltipFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tooltipFrame.BorderSizePixel = 0
    tooltipFrame.Visible = false
    tooltipFrame.ZIndex = 1000
    tooltipFrame.Parent = tooltipGui
    addCorner(tooltipFrame, UDim.new(0, 4))
    
    local tooltipLabel = Instance.new("TextLabel")
    tooltipLabel.Name = "TextLabel"
    tooltipLabel.Size = UDim2.new(1, -10, 1, 0)
    tooltipLabel.Position = UDim2.fromOffset(5, 0)
    tooltipLabel.BackgroundTransparency = 1
    tooltipLabel.TextColor3 = VapeLib.Theme.Text
    tooltipLabel.TextSize = 13
    tooltipLabel.Font = VapeLib.Theme.Font
    tooltipLabel.TextXAlignment = Enum.TextXAlignment.Left
    tooltipLabel.ZIndex = 1001
    tooltipLabel.Parent = tooltipFrame
    
    runService.RenderStepped:Connect(function()
        if tooltipFrame.Visible then
            local mousePos = inputService:GetMouseLocation()
            tooltipFrame.Position = UDim2.fromOffset(mousePos.X + 15, mousePos.Y + 5)
        end
    end)
end

local function addTooltip(gui, text)
    if not text or text == "" then return end
    createTooltip()
    gui.MouseEnter:Connect(function()
        if not tooltipGui then return end
        local tooltipFrame = tooltipGui:FindFirstChild("Tooltip")
        if not tooltipFrame then return end
        local tooltipLabel = tooltipFrame:FindFirstChild("TextLabel")
        if not tooltipLabel then return end
        
        tooltipLabel.Text = text
        local textSize = textService:GetTextSize(text, 13, VapeLib.Theme.Font, Vector2.new(300, 1000))
        tooltipFrame.Size = UDim2.fromOffset(textSize.X + 10, textSize.Y + 6)
        tooltipFrame.Visible = true
    end)
    gui.MouseLeave:Connect(function()
        if tooltipGui and tooltipGui:FindFirstChild("Tooltip") then 
            tooltipGui.Tooltip.Visible = false 
        end
    end)
end

local function makeDraggable(gui, dragPart, connections)
    local dragging
    local dragInput
    local dragStart
    local startPos

    dragPart.InputBegan:Connect(function(input)
        if not dragPart.Active then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragPart.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    local con = inputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    if connections then table.insert(connections, con) end
end

function VapeLib:CreateWindow(options)
    options = options or {}
    local scriptName = options.Name or "Vape Lite"
    local scriptIcon = options.Icon or ""
    local iconSize = options.IconSize or 100
    local iconWidth = options.IconSizeWide or options.IconSizeWidth or iconSize
    local isStudio = options.Studio or false
    guiParent = isStudio and game.Players.LocalPlayer:WaitForChild("PlayerGui") or coreGui

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = httpService:GenerateGUID(false)
    screenGui.Parent = guiParent
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true
    screenGui.ResetOnSpawn = false

    local uiScale = Instance.new("UIScale")
    uiScale.Parent = screenGui
    table.insert(globalUIScales, uiScale)

    local configFolder = scriptName .. "/games"
    local configName = tostring(game.PlaceId)

    local mainApi = {
        ScreenGui = screenGui,
        Categories = {},
        Keybind = options.Keybind or Enum.KeyCode.RightShift,
        AccentElements = {},
        Config = loadConfig(configFolder, configName) or {Windows = {}, Modules = {}, GUISettings = {}},
        ModulesEnabled = {},
        Keybinds = {},
        Connections = {},
        BlurElements = {}
    }

    local function connect(signal, callback)
        local con = signal:Connect(callback)
        table.insert(mainApi.Connections, con)
        return con
    end

    connect(inputService.InputBegan, function(input, gpe)
        if gpe then return end
        if mainApi.Keybind ~= nil and input.KeyCode == mainApi.Keybind then
            screenGui.Enabled = not screenGui.Enabled
        end
        
        for modName, bind in pairs(mainApi.Keybinds) do
            if input.KeyCode == bind then
                local modData = VapeLib.Modules[modName]
                if modData and modData.ToggleState then
                    modData.ToggleState(not mainApi.ModulesEnabled[modName])
                end
            end
        end
    end)

    local arrayGui = Instance.new("ScreenGui")
    arrayGui.Name = httpService:GenerateGUID(false)
    arrayGui.DisplayOrder = 500
    arrayGui.Parent = guiParent
    arrayGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    arrayGui.Enabled = false
    arrayGui.IgnoreGuiInset = true
    arrayGui.ResetOnSpawn = false

    local arrayScale = Instance.new("UIScale")
    arrayScale.Parent = arrayGui
    table.insert(globalUIScales, arrayScale)

    local arrayContainer = Instance.new("Frame")
    arrayContainer.Name = "Arraylist"
    arrayContainer.Size = UDim2.fromOffset(200, scriptIcon ~= "" and 155 or 30)
    local savedArrayPos = mainApi.Config.Windows["Arraylist"]
    if savedArrayPos then
        arrayContainer.Position = UDim2.fromOffset(savedArrayPos.X, savedArrayPos.Y)
    else
        arrayContainer.Position = UDim2.new(1, -210, 0, 10)
    end
    arrayContainer.BackgroundTransparency = 1
    arrayContainer.Parent = arrayGui

    local arrayHeader = Instance.new("Frame")
    arrayHeader.Name = "Header"
    arrayHeader.Size = UDim2.new(1, 0, 0, scriptIcon ~= "" and 155 or 30)
    arrayHeader.BackgroundTransparency = 1
    arrayHeader.Parent = arrayContainer

    local arrayTitle
    if scriptIcon ~= "" then
        arrayTitle = Instance.new("ImageLabel")
        arrayTitle.Name = "000_Title"
        arrayTitle.Size = UDim2.new(0, 179, 0, 155)
        arrayTitle.Position = UDim2.new(1, -179, 0, 0)
        arrayTitle.BackgroundTransparency = 1
        arrayTitle.Image = scriptIcon
        arrayTitle.ScaleType = Enum.ScaleType.Fit
        arrayTitle.ImageColor3 = VapeLib.Theme.Accent
        arrayTitle.Parent = arrayHeader
    else
        arrayTitle = Instance.new("TextLabel")
        arrayTitle.Name = "000_Title"
        arrayTitle.Size = UDim2.new(1, 0, 1, 0)
        arrayTitle.BackgroundTransparency = 1
        arrayTitle.Text = scriptName
        arrayTitle.TextColor3 = VapeLib.Theme.Accent
        arrayTitle.TextSize = 20
        arrayTitle.Font = Enum.Font.SourceSansBold
        arrayTitle.TextXAlignment = Enum.TextXAlignment.Right
        arrayTitle.Parent = arrayHeader
    end
    table.insert(mainApi.AccentElements, arrayTitle)

    local pinBtn = Instance.new("ImageButton")
    pinBtn.Name = "Pin"
    pinBtn.Size = UDim2.fromOffset(16, 16)
    pinBtn.Position = UDim2.new(1, -(scriptIcon ~= "" and 199 or (iconWidth + 20)), 0.5, -8)
    pinBtn.BackgroundTransparency = 1
    pinBtn.Image = "rbxassetid://14406214596"
    pinBtn.ImageColor3 = VapeLib.Theme.Text
    pinBtn.Visible = false
    pinBtn.Parent = arrayHeader

    local pinned = mainApi.Config.PinnedArray or false
    local function updatePin()
        pinBtn.ImageColor3 = pinned and VapeLib.Theme.Accent or VapeLib.Theme.Text
        arrayHeader.Active = not pinned
    end
    
    pinBtn.MouseButton1Click:Connect(function()
        pinned = not pinned
        mainApi.Config.PinnedArray = pinned
        saveConfig(scriptName, "config", mainApi.Config)
        updatePin()
    end)

    makeDraggable(arrayContainer, arrayHeader, mainApi.Connections)
    updatePin()

    arrayContainer.MouseEnter:Connect(function()
        if mainWindow.Visible then pinBtn.Visible = true end
    end)
    arrayContainer.MouseLeave:Connect(function()
        pinBtn.Visible = false
    end)

    arrayContainer:GetPropertyChangedSignal("Position"):Connect(function()
        if not pinned then
            mainApi.Config.Windows["Arraylist"] = {X = arrayContainer.AbsolutePosition.X, Y = arrayContainer.AbsolutePosition.Y}
            saveConfig(scriptName, "config", mainApi.Config)
        end
    end)

    local arrayContent = Instance.new("Frame")
    arrayContent.Name = "Content"
    arrayContent.Size = UDim2.new(1, 0, 0, 0)
    arrayContent.Position = UDim2.fromOffset(0, scriptIcon ~= "" and 155 or 30)
    arrayContent.BackgroundTransparency = 1
    arrayContent.Parent = arrayContainer

    local arrayLayout = Instance.new("UIListLayout")
    arrayLayout.Parent = arrayContent
    arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    arrayLayout.SortOrder = Enum.SortOrder.Name

    arrayLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        arrayContent.Size = UDim2.new(1, 0, 0, arrayLayout.AbsoluteContentSize.Y)
        arrayContainer.Size = UDim2.fromOffset(200, (scriptIcon ~= "" and 155 or 30) + arrayLayout.AbsoluteContentSize.Y)
    end)

    function mainApi:UpdateArrayList()
        for _, child in pairs(arrayContent:GetChildren()) do
            if child:IsA("TextLabel") then
                child:Destroy()
            end
        end

        local enabledList = {}
        for modName, modData in pairs(VapeLib.Modules) do
            if mainApi.ModulesEnabled[modName] then
                table.insert(enabledList, modName)
            end
        end
        table.sort(enabledList)

        for _, modName in ipairs(enabledList) do
            local label = Instance.new("TextLabel")
            label.Name = modName
            label.Size = UDim2.new(1, 0, 0, 20)
            label.BackgroundTransparency = 1
            label.Text = modName .. "  "
            label.TextColor3 = VapeLib.Theme.Accent
            label.TextSize = 16
            label.Font = VapeLib.Theme.Font
            label.TextXAlignment = Enum.TextXAlignment.Right
            label.Parent = arrayContent
            table.insert(self.AccentElements, label)
        end
    end

    local notifyGui = Instance.new("ScreenGui")
    notifyGui.Name = httpService:GenerateGUID(false)
    notifyGui.DisplayOrder = 1000
    notifyGui.Parent = guiParent
    notifyGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    notifyGui.IgnoreGuiInset = true
    notifyGui.ResetOnSpawn = false

    local notifyScale = Instance.new("UIScale")
    notifyScale.Parent = notifyGui
    table.insert(globalUIScales, notifyScale)

    updateGlobalScale()

    local notifyContainer = Instance.new("Frame")
    notifyContainer.Name = "Notifications"
    notifyContainer.Size = UDim2.new(0, 300, 1, 0)
    notifyContainer.Position = UDim2.new(1, -310, 0, 0)
    notifyContainer.BackgroundTransparency = 1
    notifyContainer.Parent = notifyGui
    
    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.Parent = notifyContainer
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 10)

    function mainApi:Notify(nOptions)
        local title = nOptions.Title or "Notification"
        local desc = nOptions.Description or ""
        local duration = tonumber(nOptions.Duration) or 5

        local nFrame = Instance.new("Frame")
        nFrame.Size = UDim2.new(1, 0, 0, 60)
        nFrame.BackgroundColor3 = VapeLib.Theme.Main
        nFrame.BorderSizePixel = 0
        nFrame.ClipsDescendants = false
        nFrame.Parent = notifyContainer
        addCorner(nFrame)
        addBlur(nFrame, self)

        local nTitle = Instance.new("TextLabel")
        nTitle.Size = UDim2.new(1, -20, 0, 20)
        nTitle.Position = UDim2.fromOffset(10, 5)
        nTitle.BackgroundTransparency = 1
        nTitle.Text = title
        nTitle.TextColor3 = VapeLib.Theme.Accent
        nTitle.TextSize = 15
        nTitle.Font = Enum.Font.SourceSansBold
        nTitle.TextXAlignment = Enum.TextXAlignment.Left
        nTitle.Parent = nFrame
        table.insert(self.AccentElements, nTitle)

        local nDesc = Instance.new("TextLabel")
        nDesc.Size = UDim2.new(1, -20, 0, 30)
        nDesc.Position = UDim2.fromOffset(10, 25)
        nDesc.BackgroundTransparency = 1
        nDesc.Text = desc
        nDesc.TextColor3 = VapeLib.Theme.Text
        nDesc.TextSize = 14
        nDesc.Font = VapeLib.Theme.Font
        nDesc.TextXAlignment = Enum.TextXAlignment.Left
        nDesc.TextWrapped = true
        nDesc.Parent = nFrame

        local nProgress = Instance.new("Frame")
        nProgress.Size = UDim2.new(1, 0, 0, 2)
        nProgress.Position = UDim2.new(0, 0, 1, -2)
        nProgress.BackgroundColor3 = VapeLib.Theme.Accent
        nProgress.BorderSizePixel = 0
        nProgress.Parent = nFrame
        table.insert(self.AccentElements, nProgress)

        nFrame.Position = UDim2.new(1.2, 0, 0, 0)
        tweenService:Create(nFrame, VapeLib.Theme.Tween, {Position = UDim2.new(0, 0, 0, 0)}):Play()
        tweenService:Create(nProgress, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)}):Play()

        task.delay(duration, function()
            if not nFrame.Parent then return end
            tweenService:Create(nFrame, VapeLib.Theme.Tween, {Position = UDim2.new(1.2, 0, 0, 0)}):Play()
            task.wait(0.2)
            nFrame:Destroy()
        end)
    end

    function mainApi:UpdateAccent(color)
        VapeLib.Theme.Accent = color
        for _, data in pairs(self.AccentElements) do
            local element = typeof(data) == "Instance" and data or data.Instance
            if not element then continue end
            
            local shouldUpdate = true
            if typeof(data) == "table" and data.GetEnabled then
                shouldUpdate = data.GetEnabled()
            end

            if element:IsA("Frame") or element:IsA("TextButton") then
                element.BackgroundColor3 = shouldUpdate and color or (element:IsA("TextButton") and VapeLib.Theme.Main or Color3.fromRGB(45, 44, 45))
            elseif element:IsA("TextLabel") or element:IsA("TextBox") then
                element.TextColor3 = shouldUpdate and color or VapeLib.Theme.Text
            elseif element:IsA("ImageLabel") or element:IsA("ImageButton") then
                element.ImageColor3 = shouldUpdate and color or VapeLib.Theme.Text
            end
        end
    end

    local mainWindow = Instance.new("Frame")
    mainWindow.Name = "MainWindow"
    mainWindow.Size = UDim2.fromOffset(200, 40)
    local savedPos = mainApi.Config.Windows["Main"]
    if savedPos then
        mainWindow.Position = UDim2.fromOffset(savedPos.X, savedPos.Y)
    else
        mainWindow.Position = UDim2.fromOffset(50, 50)
    end
    mainWindow.BackgroundColor3 = VapeLib.Theme.Main
    mainWindow.BorderSizePixel = 0
    mainWindow.ClipsDescendants = false
    mainWindow.Parent = screenGui
    addCorner(mainWindow)
    addBlur(mainWindow, mainApi)

    mainWindow:GetPropertyChangedSignal("Position"):Connect(function()
        mainApi.Config.Windows["Main"] = {X = mainWindow.AbsolutePosition.X, Y = mainWindow.AbsolutePosition.Y}
        saveConfig(scriptName, "config", mainApi.Config)
    end)

    local mainHeader = Instance.new("Frame")
    mainHeader.Name = "Header"
    mainHeader.Size = UDim2.new(1, 0, 0, 40)
    mainHeader.BackgroundTransparency = 1
    mainHeader.Active = true
    mainHeader.Parent = mainWindow
    makeDraggable(mainWindow, mainHeader, mainApi.Connections)

    local mainTitle
    if scriptIcon ~= "" then
        mainTitle = Instance.new("ImageLabel")
        mainTitle.Name = "Title"
        mainTitle.Size = UDim2.fromOffset(iconWidth, 25)
        mainTitle.Position = UDim2.fromOffset(10, 7)
        mainTitle.BackgroundTransparency = 1
        mainTitle.Image = scriptIcon
        mainTitle.ScaleType = Enum.ScaleType.Fit
        mainTitle.ImageColor3 = VapeLib.Theme.Text
        mainTitle.Parent = mainHeader
    else
        mainTitle = Instance.new("TextLabel")
        mainTitle.Name = "Title"
        mainTitle.Size = UDim2.new(1, -60, 1, 0)
        mainTitle.Position = UDim2.fromOffset(10, 0)
        mainTitle.BackgroundTransparency = 1
        mainTitle.Text = scriptName
        mainTitle.TextColor3 = VapeLib.Theme.Text
        mainTitle.TextSize = 17
        mainTitle.Font = Enum.Font.SourceSansBold
        mainTitle.TextXAlignment = Enum.TextXAlignment.Left
        mainTitle.Parent = mainHeader
    end

    local settingsBtn = Instance.new("ImageButton")
    settingsBtn.Name = "Settings"
    settingsBtn.Size = UDim2.fromOffset(18, 18)
    settingsBtn.Position = UDim2.new(1, -25, 0.5, -9)
    settingsBtn.BackgroundTransparency = 1
    settingsBtn.Image = "rbxassetid://14368318994"
    settingsBtn.ImageColor3 = VapeLib.Theme.Text
    settingsBtn.Parent = mainHeader

    local searchToggleBtn = Instance.new("ImageButton")
    searchToggleBtn.Name = "SearchToggle"
    searchToggleBtn.Size = UDim2.fromOffset(18, 18)
    searchToggleBtn.Position = UDim2.new(1, -50, 0.5, -9)
    searchToggleBtn.BackgroundTransparency = 1
    searchToggleBtn.Image = "rbxassetid://14425646684"
    searchToggleBtn.ImageColor3 = VapeLib.Theme.Text
    searchToggleBtn.Parent = mainHeader

    local mainContainer = Instance.new("Frame")
    mainContainer.Name = "Container"
    mainContainer.Size = UDim2.new(1, 0, 0, 0)
    mainContainer.Position = UDim2.fromOffset(0, 40)
    mainContainer.BackgroundColor3 = Color3.fromRGB(22, 21, 22)
    mainContainer.BorderSizePixel = 0
    mainContainer.ClipsDescendants = true
    mainContainer.Parent = mainWindow
    addCorner(mainContainer)

    local searchFrame = Instance.new("Frame")
    searchFrame.Name = "SearchFrame"
    searchFrame.Size = UDim2.new(1, 0, 0, 0)
    searchFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    searchFrame.BorderSizePixel = 0
    searchFrame.ClipsDescendants = true
    searchFrame.Parent = mainContainer

    local searchIcon = Instance.new("ImageLabel")
    searchIcon.Size = UDim2.fromOffset(16, 16)
    searchIcon.Position = UDim2.fromOffset(10, 12)
    searchIcon.BackgroundTransparency = 1
    searchIcon.Image = "rbxassetid://14425646684"
    searchIcon.ImageColor3 = VapeLib.Theme.Text
    searchIcon.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -40, 0, 40)
    searchBox.Position = UDim2.fromOffset(35, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.PlaceholderText = "Search Modules..."
    searchBox.Text = ""
    searchBox.TextColor3 = VapeLib.Theme.Text
    searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 100)
    searchBox.TextSize = 14
    searchBox.Font = VapeLib.Theme.Font
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.Parent = searchFrame

    local searchExpanded = false
    searchToggleBtn.MouseButton1Click:Connect(function()
        searchExpanded = not searchExpanded
        tweenService:Create(searchFrame, VapeLib.Theme.Tween, {
            Size = UDim2.new(1, 0, 0, searchExpanded and 40 or 0)
        }):Play()
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        for modName, modData in pairs(VapeLib.Modules) do
            if modName:lower():find(query) then
                modData.Object.Visible = true
                modData.CategoryWindow.Visible = true
            else
                modData.Object.Visible = false
            end
        end
    end)

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Parent = mainContainer
    mainLayout.SortOrder = Enum.SortOrder.LayoutOrder

    mainLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        mainContainer.Size = UDim2.new(1, 0, 0, mainLayout.AbsoluteContentSize.Y)
        mainWindow.Size = UDim2.new(0, 200, 0, 40 + mainLayout.AbsoluteContentSize.Y)
    end)

    local settingsFrame = Instance.new("Frame")
    settingsFrame.Name = "Settings"
    settingsFrame.Size = UDim2.new(1, 0, 0, 0)
    settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    settingsFrame.BorderSizePixel = 0
    settingsFrame.ClipsDescendants = true
    settingsFrame.Parent = mainContainer

    local settingsLayout = Instance.new("UIListLayout")
    settingsLayout.Parent = settingsFrame
    settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

    settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if settingsFrame.Size.Y.Offset > 0 then
            settingsFrame.Size = UDim2.new(1, 0, 0, settingsLayout.AbsoluteContentSize.Y)
        end
    end)

    local settingsExpanded = false
    settingsBtn.MouseButton1Click:Connect(function()
        settingsExpanded = not settingsExpanded
        tweenService:Create(settingsFrame, VapeLib.Theme.Tween, {
            Size = UDim2.new(1, 0, 0, settingsExpanded and settingsLayout.AbsoluteContentSize.Y or 0)
        }):Play()
    end)

    local function createSettingsCategory(name)
        local catBtn = Instance.new("TextButton")
        catBtn.Size = UDim2.new(1, 0, 0, 30)
        catBtn.BackgroundColor3 = Color3.fromRGB(35, 34, 35)
        catBtn.BorderSizePixel = 0
        catBtn.Text = "  " .. name
        catBtn.TextColor3 = VapeLib.Theme.Text
        catBtn.TextSize = 14
        catBtn.Font = Enum.Font.SourceSansBold
        catBtn.TextXAlignment = Enum.TextXAlignment.Left
        catBtn.Parent = settingsFrame

        local catFrame = Instance.new("Frame")
        catFrame.Size = UDim2.new(1, 0, 0, 0)
        catFrame.BackgroundColor3 = Color3.fromRGB(28, 27, 28)
        catFrame.BorderSizePixel = 0
        catFrame.ClipsDescendants = true
        catFrame.Parent = settingsFrame

        local catLayout = Instance.new("UIListLayout")
        catLayout.Parent = catFrame
        catLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local expanded = false
        catBtn.MouseButton1Click:Connect(function()
            expanded = not expanded
            tweenService:Create(catFrame, VapeLib.Theme.Tween, {
                Size = UDim2.new(1, 0, 0, expanded and catLayout.AbsoluteContentSize.Y or 0)
            }):Play()
        end)

        return catFrame
    end

    local guiSettings = createSettingsCategory("GUI Settings")
    local modulesSettings = createSettingsCategory("Modules")
    local modeSettings = createSettingsCategory("Mode")

    local hueFrame = Instance.new("Frame")
    hueFrame.Size = UDim2.new(1, 0, 0, 45)
    hueFrame.BackgroundTransparency = 1
    hueFrame.Parent = guiSettings

    local hueTitle = Instance.new("TextLabel")
    hueTitle.Size = UDim2.new(1, -20, 0, 20)
    hueTitle.Position = UDim2.fromOffset(20, 5)
    hueTitle.BackgroundTransparency = 1
    hueTitle.Text = "GUI Hue"
    hueTitle.TextColor3 = VapeLib.Theme.Text
    hueTitle.TextSize = 14
    hueTitle.Font = VapeLib.Theme.Font
    hueTitle.TextXAlignment = Enum.TextXAlignment.Left
    hueTitle.Parent = hueFrame

    local hueBkg = Instance.new("Frame")
    hueBkg.Size = UDim2.new(1, -40, 0, 4)
    hueBkg.Position = UDim2.fromOffset(20, 30)
    hueBkg.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
    hueBkg.Parent = hueFrame
    addCorner(hueBkg)

    local hueGradient = Instance.new("UIGradient")
    local hueTable = {}
    for i = 0, 1, 0.1 do table.insert(hueTable, ColorSequenceKeypoint.new(i, Color3.fromHSV(i, 1, 1))) end
    hueGradient.Color = ColorSequence.new(hueTable)
    hueGradient.Parent = hueBkg

    local hueFill = Instance.new("Frame")
    local startH, startS, startV = VapeLib.Theme.Accent:ToHSV()
    hueFill.Size = UDim2.fromScale(startH, 1)
    hueFill.BackgroundTransparency = 1
    hueFill.Parent = hueBkg

    local hueKnob = Instance.new("Frame")
    hueKnob.Size = UDim2.fromOffset(12, 12)
    hueKnob.Position = UDim2.new(1, -6, 0.5, -6)
    hueKnob.BackgroundColor3 = VapeLib.Theme.Text
    hueKnob.Parent = hueFill
    addCorner(hueKnob, UDim.new(1, 0))

    local function setHue(percent, skipSave)
        hueFill.Size = UDim2.fromScale(percent, 1)
        mainApi:UpdateAccent(Color3.fromHSV(percent, 0.7, 0.9))
        if not skipSave then
            mainApi.Config.GUISettings.Hue = percent
            saveConfig(scriptName, "config", mainApi.Config)
        end
    end

    connect(hueBkg.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local move = connect(inputService.InputChanged, function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    local percent = math.clamp((input.Position.X - hueBkg.AbsolutePosition.X) / hueBkg.AbsoluteSize.X, 0, 1)
                    setHue(percent)
                end
            end)
            local endCon
            endCon = connect(inputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    move:Disconnect()
                    endCon:Disconnect()
                end
            end)
            local percent = math.clamp((input.Position.X - hueBkg.AbsolutePosition.X) / hueBkg.AbsoluteSize.X, 0, 1)
            setHue(percent)
        end
    end)

    local rainbowFrame = Instance.new("TextButton")
    rainbowFrame.Size = UDim2.new(1, 0, 0, 30)
    rainbowFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    rainbowFrame.AutoButtonColor = false
    rainbowFrame.Text = ""
    rainbowFrame.Parent = guiSettings

    local rainbowTitle = Instance.new("TextLabel")
    rainbowTitle.Size = UDim2.new(1, -40, 1, 0)
    rainbowTitle.Position = UDim2.fromOffset(20, 0)
    rainbowTitle.BackgroundTransparency = 1
    rainbowTitle.Text = "GUI Rainbow"
    rainbowTitle.TextColor3 = VapeLib.Theme.Text
    rainbowTitle.TextSize = 14
    rainbowTitle.Font = VapeLib.Theme.Font
    rainbowTitle.TextXAlignment = Enum.TextXAlignment.Left
    rainbowTitle.Parent = rainbowFrame

    local rainbowStatus = Instance.new("Frame")
    rainbowStatus.Size = UDim2.fromOffset(12, 12)
    rainbowStatus.Position = UDim2.new(1, -25, 0.5, -6)
    rainbowStatus.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
    rainbowStatus.Parent = rainbowFrame
    addCorner(rainbowStatus, UDim.new(0, 3))

    local rainbowEnabled = false
    local function toggleRainbow(state, skipSave)
        rainbowEnabled = state
        rainbowStatus.BackgroundColor3 = rainbowEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
        if not skipSave then
            mainApi.Config.GUISettings.Rainbow = rainbowEnabled
            saveConfig(scriptName, "config", mainApi.Config)
        end
    end

    rainbowFrame.MouseButton1Click:Connect(function()
        toggleRainbow(not rainbowEnabled)
    end)
    table.insert(mainApi.AccentElements, {
        Instance = rainbowStatus,
        GetEnabled = function() return rainbowEnabled end
    })

    task.spawn(function()
        local hue = 0
        while task.wait(0.01) do
            if not screenGui.Parent then break end
            if rainbowEnabled then
                hue = (hue + 0.005) % 1
                hueFill.Size = UDim2.fromScale(hue, 1)
                mainApi:UpdateAccent(Color3.fromHSV(hue, 0.7, 0.9))
            end
        end
    end)

    local scaleFrame = Instance.new("Frame")
    scaleFrame.Size = UDim2.new(1, 0, 0, 45)
    scaleFrame.BackgroundTransparency = 1
    scaleFrame.Parent = guiSettings

    local scaleTitle = Instance.new("TextLabel")
    scaleTitle.Size = UDim2.new(1, -20, 0, 20)
    scaleTitle.Position = UDim2.fromOffset(20, 5)
    scaleTitle.BackgroundTransparency = 1
    scaleTitle.Text = "GUI Scale: 100%"
    scaleTitle.TextColor3 = VapeLib.Theme.Text
    scaleTitle.TextSize = 14
    scaleTitle.Font = VapeLib.Theme.Font
    scaleTitle.TextXAlignment = Enum.TextXAlignment.Left
    scaleTitle.Parent = scaleFrame

    local scaleBkg = Instance.new("Frame")
    scaleBkg.Size = UDim2.new(1, -40, 0, 4)
    scaleBkg.Position = UDim2.fromOffset(20, 30)
    scaleBkg.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
    scaleBkg.Parent = scaleFrame
    addCorner(scaleBkg)

    local scaleFill = Instance.new("Frame")
    scaleFill.Size = UDim2.fromScale(0.333, 1)
    scaleFill.BackgroundColor3 = VapeLib.Theme.Accent
    scaleFill.Parent = scaleBkg
    addCorner(scaleFill)
    table.insert(mainApi.AccentElements, scaleFill)

    local function setScale(percent, skipSave)
        scaleFill.Size = UDim2.fromScale(percent, 1)
        local scaleVal = 0.5 + (percent * 1.5)
        userScaleMultiplier = scaleVal
        updateGlobalScale()
        scaleTitle.Text = "GUI Scale: " .. math.round(scaleVal * 100) .. "%"
        if not skipSave then
            mainApi.Config.GUISettings.Scale = percent
            saveConfig(scriptName, "config", mainApi.Config)
        end
    end

    connect(scaleBkg.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local move = connect(inputService.InputChanged, function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    local percent = math.clamp((input.Position.X - scaleBkg.AbsolutePosition.X) / scaleBkg.AbsoluteSize.X, 0, 1)
                    setScale(percent)
                end
            end)
            local endCon
            endCon = connect(inputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    move:Disconnect()
                    endCon:Disconnect()
                end
            end)
            local percent = math.clamp((input.Position.X - scaleBkg.AbsolutePosition.X) / scaleBkg.AbsoluteSize.X, 0, 1)
            setScale(percent)
        end
    end)

    local bindFrame = Instance.new("TextButton")
    bindFrame.Size = UDim2.new(1, 0, 0, 30)
    bindFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    bindFrame.AutoButtonColor = false
    bindFrame.Text = ""
    bindFrame.Parent = guiSettings

    local bindTitle = Instance.new("TextLabel")
    bindTitle.Size = UDim2.new(1, -40, 1, 0)
    bindTitle.Position = UDim2.fromOffset(20, 0)
    bindTitle.BackgroundTransparency = 1
    bindTitle.Text = "GUI Bind: " .. mainApi.Keybind.Name
    bindTitle.TextColor3 = VapeLib.Theme.Text
    bindTitle.TextSize = 14
    bindTitle.Font = VapeLib.Theme.Font
    bindTitle.TextXAlignment = Enum.TextXAlignment.Left
    bindTitle.Parent = bindFrame

    local binding = false
    bindFrame.MouseButton1Click:Connect(function()
        if binding then return end
        binding = true
        bindTitle.Text = "GUI Bind: ..."
        local connection
        connection = connect(inputService.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.Keyboard then
                mainApi.Keybind = input.KeyCode
                bindTitle.Text = "GUI Bind: " .. input.KeyCode.Name
                binding = false
                connection:Disconnect()
                mainApi.Config.GUISettings.Bind = input.KeyCode.Name
                saveConfig(scriptName, "config", mainApi.Config)
            end
        end)
    end)

    local sortBtn = Instance.new("TextButton")
    sortBtn.Size = UDim2.new(1, 0, 0, 30)
    sortBtn.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    sortBtn.AutoButtonColor = false
    sortBtn.Text = "  Sort Tabs"
    sortBtn.TextColor3 = VapeLib.Theme.Text
    sortBtn.TextSize = 14
    sortBtn.Font = VapeLib.Theme.Font
    sortBtn.TextXAlignment = Enum.TextXAlignment.Left
    sortBtn.Parent = guiSettings

    sortBtn.MouseButton1Click:Connect(function()
        for i, cat in ipairs(mainApi.Categories) do
            if cat.Window then
                cat.Window.Position = UDim2.fromOffset(260 + ((i-1) * 220), 50)
            end
        end
    end)

    local arrayListFrame = Instance.new("TextButton")
    arrayListFrame.Size = UDim2.new(1, 0, 0, 30)
    arrayListFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    arrayListFrame.AutoButtonColor = false
    arrayListFrame.Text = ""
    arrayListFrame.Parent = guiSettings

    local arrayListTitle = Instance.new("TextLabel")
    arrayListTitle.Size = UDim2.new(1, -40, 1, 0)
    arrayListTitle.Position = UDim2.fromOffset(20, 0)
    arrayListTitle.BackgroundTransparency = 1
    arrayListTitle.Text = "Module List"
    arrayListTitle.TextColor3 = VapeLib.Theme.Text
    arrayListTitle.TextSize = 14
    arrayListTitle.Font = VapeLib.Theme.Font
    arrayListTitle.TextXAlignment = Enum.TextXAlignment.Left
    arrayListTitle.Parent = arrayListFrame

    local arrayListStatus = Instance.new("Frame")
    arrayListStatus.Size = UDim2.fromOffset(12, 12)
    arrayListStatus.Position = UDim2.new(1, -25, 0.5, -6)
    arrayListStatus.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
    arrayListStatus.Parent = arrayListFrame
    addCorner(arrayListStatus, UDim.new(0, 3))
    table.insert(mainApi.AccentElements, {
        Instance = arrayListStatus,
        GetEnabled = function() return arrayListEnabled end
    })

    local function toggleArrayList(state, skipSave)
        arrayListEnabled = state
        arrayListStatus.BackgroundColor3 = arrayListEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
        arrayGui.Enabled = arrayListEnabled
        if not skipSave then
            mainApi.Config.GUISettings.ArrayList = arrayListEnabled
            saveConfig(scriptName, "config", mainApi.Config)
        end
    end

    arrayListFrame.MouseButton1Click:Connect(function()
        toggleArrayList(not arrayListEnabled)
    end)

    local blurFrame = Instance.new("TextButton")
    blurFrame.Size = UDim2.new(1, 0, 0, 30)
    blurFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
    blurFrame.AutoButtonColor = false
    blurFrame.Text = ""
    blurFrame.Parent = guiSettings

    local blurTitle = Instance.new("TextLabel")
    blurTitle.Size = UDim2.new(1, -40, 1, 0)
    blurTitle.Position = UDim2.fromOffset(20, 0)
    blurTitle.BackgroundTransparency = 1
    blurTitle.Text = "GUI Blur"
    blurTitle.TextColor3 = VapeLib.Theme.Text
    blurTitle.TextSize = 14
    blurTitle.Font = VapeLib.Theme.Font
    blurTitle.TextXAlignment = Enum.TextXAlignment.Left
    blurTitle.Parent = blurFrame

    local blurStatus = Instance.new("Frame")
    blurStatus.Size = UDim2.fromOffset(12, 12)
    blurStatus.Position = UDim2.new(1, -25, 0.5, -6)
    blurStatus.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
    blurStatus.Parent = blurFrame
    addCorner(blurStatus, UDim.new(0, 3))
    
    local blurEnabled = false
    local function toggleBlur(state, skipSave)
        blurEnabled = state
        blurStatus.BackgroundColor3 = blurEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
        for _, blur in pairs(mainApi.BlurElements) do
            if blur then blur.Visible = blurEnabled end
        end
        if not skipSave then
            mainApi.Config.GUISettings.BlurEnabled = blurEnabled
            saveConfig(configFolder, configName, mainApi.Config)
        end
    end

    blurFrame.MouseButton1Click:Connect(function()
        toggleBlur(not blurEnabled)
    end)

    table.insert(mainApi.AccentElements, {
        Instance = blurStatus,
        GetEnabled = function() return blurEnabled end
    })

    local globalDestructBtn = Instance.new("TextButton")
    globalDestructBtn.Size = UDim2.new(1, 0, 0, 35)
    globalDestructBtn.BackgroundColor3 = VapeLib.Theme.Main
    globalDestructBtn.AutoButtonColor = false
    globalDestructBtn.Text = "Self Destruct"
    globalDestructBtn.TextColor3 = Color3.fromRGB(200, 80, 80)
    globalDestructBtn.TextSize = 15
    globalDestructBtn.Font = Enum.Font.SourceSansBold
    globalDestructBtn.Parent = settingsFrame

    globalDestructBtn.MouseButton1Click:Connect(function()
        for _, mod in pairs(VapeLib.Modules) do
            if mod.ToggleState then mod.ToggleState(false) end
        end
        for _, con in pairs(mainApi.Connections) do
            if con then con:Disconnect() end
        end
        mainApi.Connections = {}
        if tooltipGui then tooltipGui:Destroy() end
        if notifyGui then notifyGui:Destroy() end
        if arrayGui then arrayGui:Destroy() end
        screenGui:Destroy()
    end)

    inputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == mainApi.Keybind then
            mainWindow.Visible = not mainWindow.Visible
            for _, cat in pairs(mainApi.Categories) do
                cat.Window.Visible = mainWindow.Visible
            end
        end
    end)

    function mainApi:CreateCategory(catOptions)
        catOptions = catOptions or {}
        local catName = catOptions.Name or "Category"
        local iconId = catOptions.Icon or ""

        local catToggle = Instance.new("TextButton")
        catToggle.Name = catName .. "Toggle"
        catToggle.Size = UDim2.new(1, 0, 0, 35)
        catToggle.BackgroundColor3 = VapeLib.Theme.Main
        catToggle.AutoButtonColor = false
        catToggle.BorderSizePixel = 0
        catToggle.Text = ""
        catToggle.Parent = mainContainer

        local toggleIcon = Instance.new("ImageLabel")
        toggleIcon.Name = "Icon"
        toggleIcon.Size = UDim2.fromOffset(18, 18)
        toggleIcon.Position = UDim2.fromOffset(10, 8)
        toggleIcon.BackgroundTransparency = 1
        toggleIcon.Image = iconId
        toggleIcon.ImageColor3 = VapeLib.Theme.Text
        toggleIcon.Parent = catToggle

        local toggleTitle = Instance.new("TextLabel")
        toggleTitle.Name = "Title"
        toggleTitle.Size = UDim2.new(1, -40, 1, 0)
        toggleTitle.Position = UDim2.fromOffset(40, 0)
        toggleTitle.BackgroundTransparency = 1
        toggleTitle.Text = catName
        toggleTitle.TextColor3 = VapeLib.Theme.Text
        toggleTitle.TextSize = 15
        toggleTitle.Font = VapeLib.Theme.Font
        toggleTitle.TextXAlignment = Enum.TextXAlignment.Left
        toggleTitle.Parent = catToggle

        local window = Instance.new("Frame")
        window.Name = catName .. "Window"
        window.Size = UDim2.fromOffset(200, 40)
        local savedPos = mainApi.Config.Windows[catName]
        if savedPos then
            window.Position = UDim2.fromOffset(savedPos.X, savedPos.Y)
        else
            window.Position = UDim2.fromOffset(260 + (#mainApi.Categories * 220), 50)
        end
        window.BackgroundColor3 = VapeLib.Theme.Main
        window.BorderSizePixel = 0
        window.Visible = true
        window.ClipsDescendants = false
        window.Parent = screenGui
        addCorner(window)
        addBlur(window, mainApi)

        local header = Instance.new("Frame")
        header.Name = "Header"
        header.Size = UDim2.new(1, 0, 0, 40)
        header.BackgroundTransparency = 1
        header.Active = true
        header.Parent = window
        makeDraggable(window, header, mainApi.Connections)

        window:GetPropertyChangedSignal("Position"):Connect(function()
            mainApi.Config.Windows[catName] = {X = window.AbsolutePosition.X, Y = window.AbsolutePosition.Y}
            saveConfig(scriptName, "config", mainApi.Config)
        end)

        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.fromOffset(20, 20)
        icon.Position = UDim2.fromOffset(10, 10)
        icon.BackgroundTransparency = 1
        icon.Image = iconId
        icon.ImageColor3 = VapeLib.Theme.Text
        icon.Parent = header

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.Size = UDim2.new(1, -40, 1, 0)
        title.Position = UDim2.fromOffset(40, 0)
        title.BackgroundTransparency = 1
        title.Text = catName
        title.TextColor3 = VapeLib.Theme.Text
        title.TextSize = 17
        title.Font = Enum.Font.SourceSansBold
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Parent = header

        local container = Instance.new("Frame")
        container.Name = "Container"
        container.Size = UDim2.new(1, 0, 0, 0)
        container.Position = UDim2.fromOffset(0, 40)
        container.BackgroundColor3 = Color3.fromRGB(22, 21, 22)
        container.BorderSizePixel = 0
        container.ClipsDescendants = true
        container.Parent = window
        addCorner(container)

        if mainApi.Config.GUISettings.Hue then setHue(mainApi.Config.GUISettings.Hue, true) end
        if mainApi.Config.GUISettings.Scale then setScale(mainApi.Config.GUISettings.Scale, true) end
        if mainApi.Config.GUISettings.Rainbow then toggleRainbow(true, true) end
        if mainApi.Config.GUISettings.ArrayList then toggleArrayList(true, true) end
        if mainApi.Config.GUISettings.Bind then
            local suc, res = pcall(function() return Enum.KeyCode[mainApi.Config.GUISettings.Bind] end)
            if suc then
                mainApi.Keybind = res
                bindTitle.Text = "GUI Bind: " .. res.Name
            end
        end

        local containerLayout = Instance.new("UIListLayout")
        containerLayout.Parent = container
        containerLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local windowExpanded = true
        containerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if windowExpanded then
                container.Size = UDim2.new(1, 0, 0, containerLayout.AbsoluteContentSize.Y)
                window.Size = UDim2.new(0, 200, 0, 40 + containerLayout.AbsoluteContentSize.Y)
            end
        end)

        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton2 then
                windowExpanded = not windowExpanded
                local contentHeight = containerLayout.AbsoluteContentSize.Y
                tweenService:Create(window, VapeLib.Theme.Tween, {
                    Size = UDim2.new(0, 200, 0, windowExpanded and (40 + contentHeight) or 40)
                }):Play()
                tweenService:Create(container, VapeLib.Theme.Tween, {
                    Size = UDim2.new(1, 0, 0, windowExpanded and contentHeight or 0)
                }):Play()
            end
        end)

        catToggle.MouseButton1Click:Connect(function()
            window.Visible = not window.Visible
            toggleTitle.TextColor3 = window.Visible and VapeLib.Theme.Accent or VapeLib.Theme.Text
            toggleIcon.ImageColor3 = window.Visible and VapeLib.Theme.Accent or VapeLib.Theme.Text
        end)
        toggleTitle.TextColor3 = VapeLib.Theme.Accent
        toggleIcon.ImageColor3 = VapeLib.Theme.Accent
        table.insert(mainApi.AccentElements, {
            Instance = toggleTitle,
            GetEnabled = function() return window.Visible end
        })
        table.insert(mainApi.AccentElements, {
            Instance = toggleIcon,
            GetEnabled = function() return window.Visible end
        })

        local catApi = {
            Window = window,
            Modules = {}
        }

        function catApi:CreateModule(modOptions)
            modOptions = modOptions or {}
            local modName = modOptions.Name or "Module"
            local callback = modOptions.Function or function() end
            local tooltip = modOptions.Tooltip or ""

            local modFrame = Instance.new("TextButton")
            modFrame.Name = modName .. "Module"
            modFrame.Size = UDim2.new(1, 0, 0, 35)
            modFrame.BackgroundColor3 = VapeLib.Theme.Main
            modFrame.AutoButtonColor = false
            modFrame.BorderSizePixel = 0
            modFrame.Text = ""
            modFrame.Parent = container
            addTooltip(modFrame, tooltip)

            local modTitle = Instance.new("TextLabel")
            modTitle.Name = "Title"
            modTitle.Size = UDim2.new(1, -40, 1, 0)
            modTitle.Position = UDim2.fromOffset(10, 0)
            modTitle.BackgroundTransparency = 1
            modTitle.Text = modName
            modTitle.TextColor3 = VapeLib.Theme.Text
            modTitle.TextSize = 15
            modTitle.Font = VapeLib.Theme.Font
            modTitle.TextXAlignment = Enum.TextXAlignment.Left
            modTitle.Parent = modFrame

            local expandIcon = Instance.new("TextLabel")
            expandIcon.Name = "Expand"
            expandIcon.Size = UDim2.fromOffset(20, 20)
            expandIcon.Position = UDim2.new(1, -25, 0.5, -10)
            expandIcon.BackgroundTransparency = 1
            expandIcon.Text = "+"
            expandIcon.TextColor3 = VapeLib.Theme.Text
            expandIcon.TextSize = 18
            expandIcon.Font = Enum.Font.SourceSansBold
            expandIcon.Parent = modFrame

            local settingsFrame = Instance.new("Frame")
            settingsFrame.Name = "Settings"
            settingsFrame.Size = UDim2.new(1, 0, 0, 0)
            settingsFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
            settingsFrame.BorderSizePixel = 0
            settingsFrame.ClipsDescendants = true
            settingsFrame.Parent = container

            local settingsLayout = Instance.new("UIListLayout")
            settingsLayout.Parent = settingsFrame
            settingsLayout.SortOrder = Enum.SortOrder.LayoutOrder

            settingsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if settingsFrame.Size.Y.Offset > 0 then
                    settingsFrame.Size = UDim2.new(1, 0, 0, settingsLayout.AbsoluteContentSize.Y)
                end
            end)

            local enabled = false
            local expanded = false
            local binding = false
            local currentBind = nil

            local modApi = {}
            modApi.Enabled = false

            local function toggle(state, skipSave)
                enabled = state
                modApi.Enabled = state
                modTitle.TextColor3 = enabled and VapeLib.Theme.Accent or VapeLib.Theme.Text
                mainApi.ModulesEnabled[modName] = enabled
                mainApi:UpdateArrayList()
                task.spawn(callback, enabled, modApi)
                if not skipSave then
                    mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                    mainApi.Config.Modules[modName].Enabled = enabled
                    saveConfig(configFolder, configName, mainApi.Config)
                end
            end
            function modApi:Toggle(state, skipSave)
                return toggle(state, skipSave)
            end

            local bindBtn = Instance.new("TextButton")
            bindBtn.Name = "Keybind"
            bindBtn.Size = UDim2.fromOffset(40, 20)
            bindBtn.Position = UDim2.new(1, -70, 0.5, -10)
            bindBtn.BackgroundTransparency = 1
            bindBtn.Text = "[NONE]"
            bindBtn.TextColor3 = Color3.fromRGB(150, 150, 150)
            bindBtn.TextSize = 13
            bindBtn.Font = VapeLib.Theme.Font
            bindBtn.TextXAlignment = Enum.TextXAlignment.Right
            bindBtn.Parent = modFrame

            local function setBind(key, skipSave)
                currentBind = key
                bindBtn.Text = key == nil and "[NONE]" or "["..key.Name:upper().."]"
                mainApi.Keybinds[modName] = key
                if not skipSave then
                    mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                    mainApi.Config.Modules[modName].Keybind = key and key.Name or nil
                    saveConfig(configFolder, configName, mainApi.Config)
                end
            end

            bindBtn.MouseButton1Click:Connect(function()
                binding = true
                bindBtn.Text = "[...]"
                local connection
                connection = inputService.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        binding = false
                        connection:Disconnect()
                        if input.KeyCode == Enum.KeyCode.Escape then
                            setBind(nil)
                        else
                            setBind(input.KeyCode)
                        end
                    end
                end)
            end)

            VapeLib.Modules[modName] = {
                Object = modFrame,
                CategoryWindow = window,
                ToggleState = toggle
            }

            modFrame.MouseButton1Click:Connect(function()
                if not binding then
                    toggle(not enabled)
                end
            end)

            if mainApi.Config.Modules[modName] then
                if mainApi.Config.Modules[modName].Enabled then
                    toggle(true, true)
                end
                if mainApi.Config.Modules[modName].Keybind then
                    local suc, res = pcall(function() return Enum.KeyCode[mainApi.Config.Modules[modName].Keybind] end)
                    if suc then setBind(res, true) end
                end
            end

            table.insert(mainApi.AccentElements, {
                Instance = modTitle,
                GetEnabled = function() return enabled end
            })

            modFrame.MouseButton2Click:Connect(function()
                expanded = not expanded
                expandIcon.Text = expanded and "-" or "+"
                tweenService:Create(settingsFrame, VapeLib.Theme.Tween, {
                    Size = UDim2.new(1, 0, 0, expanded and settingsLayout.AbsoluteContentSize.Y or 0)
                }):Play()
            end)

            function modApi:CreateToggle(tOptions)
                tOptions = tOptions or {}
                local tName = tOptions.Name or "Toggle"
                local tDefault = tOptions.Default or false
                local tCallback = tOptions.Function or function() end
                local tTooltip = tOptions.Tooltip or ""
                local tEnabled = tDefault

                local tFrame = Instance.new("TextButton")
                tFrame.Size = UDim2.new(1, 0, 0, 30)
                tFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
                tFrame.AutoButtonColor = false
                tFrame.Text = ""
                tFrame.Parent = settingsFrame
                addTooltip(tFrame, tTooltip)

                local tTitle = Instance.new("TextLabel")
                tTitle.Size = UDim2.new(1, -40, 1, 0)
                tTitle.Position = UDim2.fromOffset(20, 0)
                tTitle.BackgroundTransparency = 1
                tTitle.Text = tName
                tTitle.TextColor3 = VapeLib.Theme.Text
                tTitle.TextSize = 14
                tTitle.Font = VapeLib.Theme.Font
                tTitle.TextXAlignment = Enum.TextXAlignment.Left
                tTitle.Parent = tFrame

                local tStatus = Instance.new("Frame")
                tStatus.Size = UDim2.fromOffset(12, 12)
                tStatus.Position = UDim2.new(1, -25, 0.5, -6)
                tStatus.BackgroundColor3 = tEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
                tStatus.Parent = tFrame
                addCorner(tStatus, UDim.new(0, 3))
                table.insert(mainApi.AccentElements, {
                    Instance = tStatus,
                    GetEnabled = function() return tEnabled end
                })

                local function setToggle(state, skipSave)
                    if typeof(state) == "table" then
                        state = skipSave
                        skipSave = nil -- we don't have a third arg here usually
                    end
                    tEnabled = state
                    tStatus.BackgroundColor3 = tEnabled and VapeLib.Theme.Accent or Color3.fromRGB(45, 44, 45)
                    task.spawn(tCallback, tEnabled)
                    if not skipSave then
                        mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                        mainApi.Config.Modules[modName][tName] = tEnabled
                        saveConfig(configFolder, configName, mainApi.Config)
                    end
                end

                tFrame.MouseButton1Click:Connect(function()
                    setToggle(not tEnabled)
                end)

                if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][tName] ~= nil then
                    setToggle(mainApi.Config.Modules[modName][tName], true)
                end

                return { Set = setToggle }
            end

            function modApi:CreateSlider(sOptions)
                sOptions = sOptions or {}
                local sName = sOptions.Name or "Slider"
                local min = sOptions.Min or 0
                local max = sOptions.Max or 100
                local default = sOptions.Default or min
                local sCallback = sOptions.Function or function() end
                local sTooltip = sOptions.Tooltip or ""

                local sFrame = Instance.new("Frame")
                sFrame.Size = UDim2.new(1, 0, 0, 45)
                sFrame.BackgroundTransparency = 1
                sFrame.Parent = settingsFrame
                addTooltip(sFrame, sTooltip)

                local sTitle = Instance.new("TextBox")
                sTitle.Size = UDim2.new(1, -20, 0, 20)
                sTitle.Position = UDim2.fromOffset(20, 5)
                sTitle.BackgroundTransparency = 1
                sTitle.Text = sName .. ": " .. default
                sTitle.TextColor3 = VapeLib.Theme.Text
                sTitle.TextSize = 14
                sTitle.Font = VapeLib.Theme.Font
                sTitle.TextXAlignment = Enum.TextXAlignment.Left
                sTitle.ClearTextOnFocus = false
                sTitle.Parent = sFrame

                local sBkg = Instance.new("Frame")
                sBkg.Size = UDim2.new(1, -40, 0, 4)
                sBkg.Position = UDim2.fromOffset(20, 30)
                sBkg.BackgroundColor3 = Color3.fromRGB(45, 44, 45)
                sBkg.Parent = sFrame
                addCorner(sBkg)

                local sFill = Instance.new("Frame")
                sFill.Size = UDim2.fromScale((default - min) / (max - min), 1)
                sFill.BackgroundColor3 = VapeLib.Theme.Accent
                sFill.Parent = sBkg
                addCorner(sFill)
                table.insert(mainApi.AccentElements, sFill)

                local value = default
                local function setSlider(val, skipSave)
                    if typeof(val) == "table" then
                        val = skipSave
                        skipSave = nil
                    end
                    value = math.clamp(val, min, max)
                    local percent = (value - min) / (max - min)
                    sFill.Size = UDim2.fromScale(percent, 1)
                    sTitle.Text = sName .. ": " .. value
                    task.spawn(sCallback, value)
                    if not skipSave then
                        mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
                        mainApi.Config.Modules[modName][sName] = value
                        saveConfig(configFolder, configName, mainApi.Config)
                    end
                end

                sTitle.FocusLost:Connect(function(enter)
                    local typed = tonumber(sTitle.Text:match("%d+%.?%d*"))
                    if typed then
                        setSlider(typed)
                    else
                        sTitle.Text = sName .. ": " .. value
                    end
                end)

                sBkg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        local move = inputService.InputChanged:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                local percent = math.clamp((input.Position.X - sBkg.AbsolutePosition.X) / sBkg.AbsoluteSize.X, 0, 1)
                                setSlider(math.round(min + (max - min) * percent))
                            end
                        end)
                        local endCon
                        endCon = inputService.InputEnded:Connect(function(input)
                            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                                move:Disconnect()
                                endCon:Disconnect()
                            end
                        end)
                        local percent = math.clamp((input.Position.X - sBkg.AbsolutePosition.X) / sBkg.AbsoluteSize.X, 0, 1)
                        setSlider(math.round(min + (max - min) * percent))
                    end
                end)

                if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][sName] ~= nil then
                    setSlider(mainApi.Config.Modules[modName][sName], true)
                end

                return { Set = setSlider }
            end

			function modApi:CreateDropdown(dOptions)
				dOptions = dOptions or {}
				local dName = dOptions.Name or "Dropdown"
				local list = dOptions.List or {}
				local default = dOptions.Default or list[1]
				local dCallback = dOptions.Function or function() end
				local dTooltip = dOptions.Tooltip or ""

				local dFrame = Instance.new("TextButton")
				dFrame.Name = dName .. "Dropdown"
				dFrame.Size = UDim2.new(1, 0, 0, 30)
				dFrame.BackgroundColor3 = Color3.fromRGB(30, 29, 30)
				dFrame.AutoButtonColor = false
				dFrame.Text = ""
				dFrame.ClipsDescendants = true
				dFrame.Parent = settingsFrame
				addTooltip(dFrame, dTooltip)
				addCorner(dFrame)

				local dTitle = Instance.new("TextBox")
				dTitle.Name = "Value"
				dTitle.Size = UDim2.new(1, -60, 0, 30)
				dTitle.Position = UDim2.fromOffset(20, 0)
				dTitle.BackgroundTransparency = 1
				dTitle.Text = dName .. ": " .. default
				dTitle.TextColor3 = VapeLib.Theme.Text
				dTitle.TextSize = 14
				dTitle.Font = VapeLib.Theme.Font
				dTitle.TextXAlignment = Enum.TextXAlignment.Left
				dTitle.ClearTextOnFocus = false
				dTitle.Parent = dFrame

				local dArrow = Instance.new("TextLabel")
				dArrow.Name = "Arrow"
				dArrow.Size = UDim2.fromOffset(20, 20)
				dArrow.Position = UDim2.new(1, -25, 0, 5)
				dArrow.BackgroundTransparency = 1
				dArrow.Text = "v"
				dArrow.TextColor3 = VapeLib.Theme.Text
				dArrow.TextSize = 14
				dArrow.Font = Enum.Font.SourceSansBold
				dArrow.Parent = dFrame

				local dList = Instance.new("ScrollingFrame")
				dList.Name = "List"
				dList.Size = UDim2.new(1, -10, 0, 150)
				dList.Position = UDim2.fromOffset(5, 35)
				dList.BackgroundTransparency = 1
				dList.ScrollBarThickness = 2
				dList.ScrollBarImageColor3 = VapeLib.Theme.Accent
				dList.Visible = false
				dList.CanvasSize = UDim2.new(0, 0, 0, 0)
				dList.Parent = dFrame

				local dLayout = Instance.new("UIListLayout")
				dLayout.Parent = dList
				dLayout.Padding = UDim.new(0, 2)

				dLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
					dList.CanvasSize = UDim2.new(0, 0, 0, dLayout.AbsoluteContentSize.Y)
				end)

				local selected = default
				local expanded = false

				local function setDropdown(val, skipSave)
					if typeof(val) == "table" then
						val = skipSave
						skipSave = nil
					end
					selected = val
					dTitle.Text = dName .. ": " .. selected
					task.spawn(dCallback, selected)
					if not skipSave then
						mainApi.Config.Modules[modName] = mainApi.Config.Modules[modName] or {}
						mainApi.Config.Modules[modName][dName] = selected
						saveConfig(configFolder, configName, mainApi.Config)
					end
				end

				local function updateList()
					for _, child in pairs(dList:GetChildren()) do
						if child:IsA("TextButton") then child:Destroy() end
					end
					for _, val in pairs(list) do
						local btn = Instance.new("TextButton")
						btn.Size = UDim2.new(1, 0, 0, 25)
						btn.BackgroundColor3 = Color3.fromRGB(40, 39, 40)
						btn.BorderSizePixel = 0
						btn.Text = val
						btn.TextColor3 = VapeLib.Theme.Text
						btn.TextSize = 13
						btn.Font = VapeLib.Theme.Font
						btn.AutoButtonColor = false
						btn.Parent = dList
						addCorner(btn, UDim.new(0, 3))
						
						btn.MouseButton1Click:Connect(function()
							setDropdown(val)
							expanded = false
							tweenService:Create(dFrame, VapeLib.Theme.Tween, {Size = UDim2.new(1, 0, 0, 30)}):Play()
							dList.Visible = false
							dArrow.Rotation = 0
						end)
					end
				end

				dTitle.FocusLost:Connect(function()
					local text = dTitle.Text:gsub(dName .. ": ", "")
					local bestMatch, bestScore = nil, -1
					for _, val in pairs(list) do
						if val:lower() == text:lower() then
							bestMatch = val
							break
						end
						if val:lower():find(text:lower()) then
							bestMatch = val
							break
						end
					end
					if bestMatch then
						setDropdown(bestMatch)
					else
						dTitle.Text = dName .. ": " .. selected
					end
				end)

				dFrame.MouseButton1Click:Connect(function()
					expanded = not expanded
					updateList()
					dList.Visible = expanded
					dArrow.Rotation = expanded and 180 or 0
					tweenService:Create(dFrame, VapeLib.Theme.Tween, {
						Size = UDim2.new(1, 0, 0, expanded and 190 or 30)
					}):Play()
				end)

				if mainApi.Config.Modules[modName] and mainApi.Config.Modules[modName][dName] ~= nil then
					setDropdown(mainApi.Config.Modules[modName][dName], true)
				end

				return { Set = setDropdown }
			end

            return modApi
        end

        table.insert(mainApi.Categories, {Window = window})
        return catApi
    end

    task.spawn(function()
        if mainApi.Config.GUISettings.Hue then setHue(mainApi.Config.GUISettings.Hue, true) end
        if mainApi.Config.GUISettings.Scale then setScale(mainApi.Config.GUISettings.Scale, true) end
        if mainApi.Config.GUISettings.Rainbow then toggleRainbow(true, true) end
        if mainApi.Config.GUISettings.ArrayList then toggleArrayList(true, true) end
        if mainApi.Config.GUISettings.BlurEnabled then toggleBlur(true, true) end
        if mainApi.Config.GUISettings.Bind then
            local suc, res = pcall(function() return Enum.KeyCode[mainApi.Config.GUISettings.Bind] end)
            if suc then
                mainApi.Keybind = res
                bindTitle.Text = "GUI Bind: " .. res.Name
            end
        end
    end)

    return mainApi
end

return VapeLib
