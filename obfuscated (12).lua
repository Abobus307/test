-- Enhanced Local GUI (Beautiful UI with Show/Hide Button)
-- Language: ENGLISH UI
-- Auto-detection for PC and Mobile devices
-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
wait(2) -- Даем время игре загрузиться

-- Constants / Defaults
local NAME = "Vasia2"
local MAPS = {"Motel Room", "Humble Abode", "Bathroom", "Moolah Manor", "Cursed Cathedral"}
local DEFAULT_SPEED = 16
local SETTINGS_FILE = "Vasia2_Settings.json"

-- Device detection
local IS_MOBILE = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) 
                  or (UserInputService:GetPlatform() == Enum.Platform.IOS) 
                  or (UserInputService:GetPlatform() == Enum.Platform.Android)

local IS_TABLET = false
if IS_MOBILE then
    local viewportSize = Workspace.CurrentCamera.ViewportSize
    IS_TABLET = math.min(viewportSize.X, viewportSize.Y) > 700
end

-- Screen size detection
local VIEWPORT_SIZE = Workspace.CurrentCamera.ViewportSize
local SCREEN_WIDTH = VIEWPORT_SIZE.X
local SCREEN_HEIGHT = VIEWPORT_SIZE.Y

-- UI Sizes based on device
local UI_SCALE = IS_MOBILE and (IS_TABLET and 1.3 or 1.6) or 1
local FONT_SIZE_MULTIPLIER = IS_MOBILE and 1.4 or 1

-- Settings
local SETTINGS = {
    AutoFarmEnabled = false,
    AutoFarmPaused = false,
    AutofarmMode = "Legal (Slow)",
    SelectedMap = "Cursed Cathedral",
    SpeedHackEnabled = false,
    SpeedValue = 16,
    SpeedSmoothing = 8,
}

-- Global dropdown state
local DROPDOWN_STATE = {
    IsOpen = false,
    CurrentDropdown = nil
}

-- ========== СИСТЕМА СОХРАНЕНИЯ И ЗАГРУЗКИ НАСТРОЕК ==========

local function SaveSettings()
    if writefile then
        pcall(function()
            local data = HttpService:JSONEncode(SETTINGS)
            writefile(SETTINGS_FILE, data)
            DebugLog("Settings saved successfully")
        end)
    end
end

local function LoadSettings()
    if readfile and isfile then
        if isfile(SETTINGS_FILE) then
            pcall(function()
                local data = readfile(SETTINGS_FILE)
                local loaded = HttpService:JSONDecode(data)
                for key, value in pairs(loaded) do
                    if SETTINGS[key] ~= nil then
                        SETTINGS[key] = value
                    end
                end
                DebugLog("Settings loaded successfully")
                return true
            end)
        end
    end
    return false
end

-- Функция показа диалога загрузки настроек
local function ShowSettingsLoadDialog()
    local dialogResult = nil
    local countdown = 20
    local autoAccept = false
    
    -- Create confirmation dialog
    local dialogGui = Instance.new("ScreenGui")
    dialogGui.Name = "SettingsConfirmationDialog"
    dialogGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    dialogGui.ResetOnSpawn = false
    
    local background = Instance.new("Frame")
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundColor3 = Color3.new(0, 0, 0)
    background.BackgroundTransparency = 0.3
    background.ZIndex = 100
    background.Parent = dialogGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 400, 0, 200)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -100)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BorderSizePixel = 0
    mainFrame.ZIndex = 101
    mainFrame.Parent = dialogGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 80, 120)
    stroke.Thickness = 2
    stroke.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Load Previous Settings? ⚙️"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.ZIndex = 102
    title.Parent = mainFrame
    
    local message = Instance.new("TextLabel")
    message.Size = UDim2.new(1, -40, 0, 60)
    message.Position = UDim2.new(0, 20, 0, 50)
    message.BackgroundTransparency = 1
    message.Text = "Would you like to load your previous AutoFarm settings?\n\nMap: " .. (SETTINGS.SelectedMap or "Unknown") .. "\nMode: " .. (SETTINGS.AutofarmMode or "Unknown")
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.Font = Enum.Font.Gotham
    message.TextSize = 14
    message.TextWrapped = true
    message.ZIndex = 102
    message.Parent = mainFrame
    
    local timerText = Instance.new("TextLabel")
    timerText.Size = UDim2.new(1, 0, 0, 20)
    timerText.Position = UDim2.new(0, 0, 0, 120)
    timerText.BackgroundTransparency = 1
    timerText.Text = "Auto-accept in: 20 seconds"
    timerText.TextColor3 = Color3.fromRGB(255, 255, 0)
    timerText.Font = Enum.Font.Gotham
    timerText.TextSize = 12
    timerText.ZIndex = 102
    timerText.Parent = mainFrame
    
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -60)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.ZIndex = 102
    buttonContainer.Parent = mainFrame
    
    local yesButton = Instance.new("TextButton")
    yesButton.Size = UDim2.new(0.4, 0, 1, 0)
    yesButton.Position = UDim2.new(0, 0, 0, 0)
    yesButton.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    yesButton.Text = "YES ✓"
    yesButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    yesButton.Font = Enum.Font.GothamBold
    yesButton.TextSize = 14
    yesButton.ZIndex = 103
    yesButton.Parent = buttonContainer
    
    local yesCorner = Instance.new("UICorner")
    yesCorner.CornerRadius = UDim.new(0, 6)
    yesCorner.Parent = yesButton
    
    local noButton = Instance.new("TextButton")
    noButton.Size = UDim2.new(0.4, 0, 1, 0)
    noButton.Position = UDim2.new(0.6, 0, 0, 0)
    noButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    noButton.Text = "NO ✗"
    noButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    noButton.Font = Enum.Font.GothamBold
    noButton.TextSize = 14
    noButton.ZIndex = 103
    noButton.Parent = buttonContainer
    
    local noCorner = Instance.new("UICorner")
    noCorner.CornerRadius = UDim.new(0, 6)
    noCorner.Parent = noButton
    
    dialogGui.Parent = game.CoreGui
    
    -- Button events
    yesButton.MouseButton1Click:Connect(function()
        dialogResult = true
        dialogGui:Destroy()
    end)
    
    noButton.MouseButton1Click:Connect(function()
        dialogResult = false
        dialogGui:Destroy()
    end)
    
    -- Countdown timer
    local countdownConnection
    countdownConnection = RunService.Heartbeat:Connect(function()
        if countdown <= 0 then
            countdownConnection:Disconnect()
            autoAccept = true
            dialogResult = true
            dialogGui:Destroy()
        else
            countdown = countdown - 0.1
            timerText.Text = "Auto-accept in: " .. math.ceil(countdown) .. " seconds"
        end
    end)
    
    -- Wait for dialog result
    while dialogGui.Parent do
        task.wait(0.1)
    end
    
    if autoAccept then
        Notify("Settings", "Auto-loading previous settings... ⏰", 3)
    end
    
    return dialogResult == true
end

-- Функция загрузки настроек с подтверждением
local function LoadSettingsWithConfirmation()
    if LoadSettings() then
        -- Show confirmation dialog for AutoFarm and Map settings
        local loadSettings = ShowSettingsLoadDialog()
        
        if loadSettings then
            Notify("Settings", "Previous settings loaded! ✅", 3)
            return true
        else
            -- Reset to defaults if user chooses no
            SETTINGS.AutoFarmEnabled = false
            SETTINGS.AutoFarmPaused = false
            SETTINGS.AutofarmMode = "Legal (Slow)"
            SETTINGS.SelectedMap = "Cursed Cathedral"
            Notify("Settings", "Using default settings ⚙️", 3)
            return false
        end
    else
        -- Create default settings file if it doesn't exist
        SaveSettings()
        return false
    end
end

-- Безопасная инициализация ReplicatedStorage кэшей
local RS_Events, RS_Values

local function RefreshReplicatedStorageCaches()
    pcall(function()
        RS_Events = ReplicatedStorage:WaitForChild("Events", 5)
        RS_Values = ReplicatedStorage:WaitForChild("Values", 5)
    end)
    
    if not RS_Events then
        RS_Events = ReplicatedStorage:FindFirstChild("Events")
    end
    if not RS_Values then
        RS_Values = ReplicatedStorage:FindFirstChild("Values")
    end
end

-- Инициализируем сразу
RefreshReplicatedStorageCaches()

-- Helper: notify
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {Title = title or NAME, Text = text or "", Duration = duration or 3})
    end)
end

-- Safe PlayerGui getter
local function getPlayerGui()
    if not LocalPlayer then 
        repeat 
            LocalPlayer = Players.LocalPlayer
            wait(0.1)
        until LocalPlayer
    end
    
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then
        pg = Instance.new("PlayerGui")
        pg.Name = "PlayerGui"
        pg.ResetOnSpawn = false
        pg.Parent = LocalPlayer
    end
    return pg
end

-- FPS Counter
local FPS = 0
local frameCount = 0
local lastFpsUpdate = tick()

RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastFpsUpdate >= 1 then
        FPS = math.floor(frameCount / (currentTime - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = currentTime
    end
end)

-- Debug logging function
local function DebugLog(message)
    print("[DEBUG] " .. message)
end

-- Device info display
DebugLog("Device Detection: Mobile=" .. tostring(IS_MOBILE) .. ", Tablet=" .. tostring(IS_TABLET))
DebugLog("Screen Size: " .. SCREEN_WIDTH .. "x" .. SCREEN_HEIGHT)
DebugLog("UI Scale: " .. UI_SCALE)

-- Загружаем настройки с подтверждением при запуске
LoadSettingsWithConfirmation()

-- ---------- ADAPTIVE BEAUTIFUL UI FOR PC AND MOBILE ----------
local function createBeautifulGui()
    local playerGui = getPlayerGui()
    if not playerGui then 
        DebugLog("PlayerGui not found")
        return nil 
    end

    -- Remove existing GUI
    local existing = playerGui:FindFirstChild("BeautifulWBU_GUI")
    if existing then 
        DebugLog("Removing existing GUI")
        existing:Destroy() 
    end

    -- Create main screen GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "BeautifulWBU_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Adaptive sizes based on device
    local MAIN_WIDTH = IS_MOBILE and (SCREEN_WIDTH * 0.95) or 920
    local MAIN_HEIGHT = IS_MOBILE and (SCREEN_HEIGHT * 0.85) or 740
    local BUTTON_SIZE = IS_MOBILE and 70 or 56
    local FONT_SIZE_SMALL = math.floor(14 * FONT_SIZE_MULTIPLIER)
    local FONT_SIZE_MEDIUM = math.floor(16 * FONT_SIZE_MULTIPLIER)
    local FONT_SIZE_LARGE = math.floor(18 * FONT_SIZE_MULTIPLIER)

    -- Fullscreen dropdown overlay (larger on mobile)
    local dropdownOverlay = Instance.new("Frame")
    dropdownOverlay.Name = "DropdownOverlay"
    dropdownOverlay.Size = UDim2.new(1, 0, 1, 0)
    dropdownOverlay.Position = UDim2.new(0, 0, 0, 0)
    dropdownOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    dropdownOverlay.BackgroundTransparency = IS_MOBILE and 0.3 or 0.7
    dropdownOverlay.Visible = false
    dropdownOverlay.ZIndex = 100
    dropdownOverlay.Parent = screenGui

    local dropdownContainer = Instance.new("Frame")
    dropdownContainer.Name = "DropdownContainer"
    dropdownContainer.Size = IS_MOBILE and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0.8, 0, 0.8, 0)
    dropdownContainer.Position = IS_MOBILE and UDim2.new(0.025, 0, 0.05, 0) or UDim2.new(0.1, 0, 0.1, 0)
    dropdownContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    dropdownContainer.Visible = false
    dropdownContainer.ZIndex = 101
    dropdownContainer.Parent = dropdownOverlay

    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, IS_MOBILE and 16 or 12)
    dropdownCorner.Parent = dropdownContainer

    local dropdownStroke = Instance.new("UIStroke")
    dropdownStroke.Color = Color3.fromRGB(80, 80, 120)
    dropdownStroke.Thickness = 3
    dropdownStroke.Parent = dropdownContainer

    local dropdownHeader = Instance.new("Frame")
    dropdownHeader.Size = UDim2.new(1, 0, 0, IS_MOBILE and 80 or 60)
    dropdownHeader.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    dropdownHeader.BorderSizePixel = 0
    dropdownHeader.ZIndex = 102
    dropdownHeader.Parent = dropdownContainer

    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, IS_MOBILE and 16 or 12)
    headerCorner.Parent = dropdownHeader

    local dropdownTitle = Instance.new("TextLabel")
    dropdownTitle.Size = UDim2.new(1, -100, 1, 0)
    dropdownTitle.Position = UDim2.new(0, 20, 0, 0)
    dropdownTitle.BackgroundTransparency = 1
    dropdownTitle.Text = "Select Option"
    dropdownTitle.TextColor3 = Color3.fromRGB(240, 240, 255)
    dropdownTitle.Font = Enum.Font.GothamBold
    dropdownTitle.TextSize = IS_MOBILE and 24 or 20
    dropdownTitle.TextXAlignment = Enum.TextXAlignment.Left
    dropdownTitle.ZIndex = 103
    dropdownTitle.Parent = dropdownHeader

    local closeDropdownButton = Instance.new("TextButton")
    closeDropdownButton.Size = UDim2.new(0, IS_MOBILE and 50 or 36, 0, IS_MOBILE and 50 or 36)
    closeDropdownButton.Position = UDim2.new(1, -60, 0.5, IS_MOBILE and -25 or -18)
    closeDropdownButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeDropdownButton.Text = "❌"
    closeDropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeDropdownButton.Font = Enum.Font.GothamBold
    closeDropdownButton.TextSize = IS_MOBILE and 22 or 18
    closeDropdownButton.ZIndex = 104
    closeDropdownButton.Parent = dropdownHeader

    local closeButtonCorner = Instance.new("UICorner")
    closeButtonCorner.CornerRadius = UDim.new(0, IS_MOBILE and 12 or 8)
    closeButtonCorner.Parent = closeDropdownButton

    local dropdownContent = Instance.new("ScrollingFrame")
    dropdownContent.Size = UDim2.new(1, -40, 1, -100)
    dropdownContent.Position = UDim2.new(0, 20, 0, 90)
    dropdownContent.BackgroundTransparency = 1
    dropdownContent.ScrollBarThickness = IS_MOBILE and 12 or 8
    dropdownContent.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    dropdownContent.ZIndex = 105
    dropdownContent.Parent = dropdownContainer

    local dropdownLayout = Instance.new("UIListLayout")
    dropdownLayout.Padding = UDim.new(0, IS_MOBILE and 15 or 10)
    dropdownLayout.Parent = dropdownContent

    -- Show/Hide button (larger on mobile)
    local showHideButton = Instance.new("TextButton")
    showHideButton.Size = UDim2.new(0, BUTTON_SIZE, 0, BUTTON_SIZE)
    showHideButton.Position = UDim2.new(0, 20, 0, 20)
    showHideButton.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    showHideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    showHideButton.Text = IS_MOBILE and "📱" or "GUI"
    showHideButton.Font = Enum.Font.GothamBold
    showHideButton.TextSize = IS_MOBILE and 24 or 20
    showHideButton.ZIndex = 10

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, IS_MOBILE and 16 or 12)
    buttonCorner.Parent = showHideButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = Color3.fromRGB(100, 100, 150)
    buttonStroke.Thickness = 2
    buttonStroke.Parent = showHideButton

    -- Main container with glass effect (initially hidden)
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, MAIN_WIDTH, 0, MAIN_HEIGHT)
    mainFrame.Position = IS_MOBILE and UDim2.new(0.5, -MAIN_WIDTH/2, 0.5, -MAIN_HEIGHT/2) or UDim2.new(0, 96, 0, 20)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BackgroundTransparency = 0.06
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.ZIndex = 1

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, IS_MOBILE and 20 or 14)
    corner.Parent = mainFrame

    -- Background gradient
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(32, 32, 46)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 30))
    })
    gradient.Rotation = 45
    gradient.Parent = mainFrame

    -- Stroke effect
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(90, 90, 140)
    stroke.Thickness = 2
    stroke.Transparency = 0.75
    stroke.Parent = mainFrame

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, IS_MOBILE and 60 or 48)
    titleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    titleBar.BorderSizePixel = 0
    titleBar.ZIndex = 2
    titleBar.Parent = mainFrame

    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, IS_MOBILE and 20 or 14)
    titleCorner.Parent = titleBar

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -120, 1, 0)
    titleLabel.Position = UDim2.new(0, 20, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = NAME .. " - " .. (IS_MOBILE and "Mobile" or "PC") .. " Version"
    titleLabel.TextColor3 = Color3.fromRGB(240, 240, 255)
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = IS_MOBILE and 20 or 18
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 3
    titleLabel.Parent = titleBar

    -- Minimize / close
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, IS_MOBILE and 50 or 38, 0, IS_MOBILE and 40 or 34)
    closeButton.Position = UDim2.new(1, -60, 0.5, IS_MOBILE and -20 or -17)
    closeButton.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeButton.Text = "−"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.TextSize = IS_MOBILE and 26 or 22
    closeButton.ZIndex = 3
    closeButton.Parent = titleBar

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, IS_MOBILE and 12 or 10)
    closeCorner.Parent = closeButton

    -- Content area
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -30, 1, -80)
    contentFrame.Position = UDim2.new(0, 15, 0, 70)
    contentFrame.BackgroundTransparency = 1
    contentFrame.ZIndex = 1
    contentFrame.Parent = mainFrame

    -- Scrolling frame for content
    local scrollFrame = Instance.new("ScrollingFrame")
    scrollFrame.Size = UDim2.new(1, 0, 1, 0)
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, IS_MOBILE and 1400 or 1200)
    scrollFrame.ScrollBarThickness = IS_MOBILE and 12 or 8
    scrollFrame.BackgroundTransparency = 1
    scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(110, 110, 165)
    scrollFrame.ZIndex = 1
    scrollFrame.Parent = contentFrame

    local mainLayout = Instance.new("UIListLayout")
    mainLayout.Padding = UDim.new(0, IS_MOBILE and 16 or 12)
    mainLayout.Parent = scrollFrame

    -- Helper functions for elements
    local function createLabel(text, sizeY)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, sizeY or (IS_MOBILE and 32 or 26))
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(230, 230, 250)
        label.Font = Enum.Font.Gotham
        label.TextSize = IS_MOBILE and FONT_SIZE_MEDIUM or 14
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextWrapped = true
        label.ZIndex = 1
        return label
    end

    local function createToggle(name, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, IS_MOBILE and 50 or 40)
        container.BackgroundTransparency = 1
        container.ZIndex = 1

        local label = createLabel(name, IS_MOBILE and 36 or 28)
        label.Size = UDim2.new(0.68, 0, 0, IS_MOBILE and 36 or 28)
        label.Parent = container

        local toggleFrame = Instance.new("Frame")
        toggleFrame.Size = UDim2.new(0, IS_MOBILE and 70 or 58, 0, IS_MOBILE and 38 or 30)
        toggleFrame.Position = UDim2.new(1, IS_MOBILE and -80 or -68, 0.5, IS_MOBILE and -19 or -15)
        toggleFrame.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
        toggleFrame.BorderSizePixel = 0
        toggleFrame.ZIndex = 1
        toggleFrame.Parent = container
        local toggleCorner = Instance.new("UICorner"); toggleCorner.CornerRadius = UDim.new(0, IS_MOBILE and 20 or 16); toggleCorner.Parent = toggleFrame

        local toggleButton = Instance.new("TextButton")
        toggleButton.Size = UDim2.new(0, IS_MOBILE and 34 or 28, 0, IS_MOBILE and 34 or 28)
        toggleButton.Position = default and UDim2.new(1, IS_MOBILE and -34 or -28, 0, IS_MOBILE and 2 or 0) or UDim2.new(0, 0, 0, IS_MOBILE and 2 or 0)
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.Text = ""
        toggleButton.AutoButtonColor = false
        toggleButton.ZIndex = 2
        toggleButton.Parent = toggleFrame
        local bcorner = Instance.new("UICorner"); bcorner.CornerRadius = UDim.new(0,IS_MOBILE and 17 or 14); bcorner.Parent = toggleButton

        toggleButton.MouseButton1Click:Connect(function()
            if DROPDOWN_STATE.IsOpen then return end
            default = not default
            local buttonTween = TweenService:Create(toggleButton, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = default and UDim2.new(1, IS_MOBILE and -34 or -28, 0, IS_MOBILE and 2 or 0) or UDim2.new(0, 0, 0, IS_MOBILE and 2 or 0)
            })
            local frameTween = TweenService:Create(toggleFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(80, 80, 80)
            })
            buttonTween:Play(); frameTween:Play()
            if callback then 
                callback(default)
                SaveSettings() -- Сохраняем настройки при изменении
            end
        end)

        return {Container = container, Button = toggleButton, Frame = toggleFrame}
    end

    -- Close dropdown function
    local function closeDropdown()
        if not DROPDOWN_STATE.IsOpen then return end
        
        DROPDOWN_STATE.IsOpen = false
        DROPDOWN_STATE.CurrentDropdown = nil
        
        local closeTween = TweenService:Create(dropdownContainer, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        
        closeTween.Completed:Connect(function()
            dropdownOverlay.Visible = false
            dropdownContainer.Visible = false
        end)
    end

    local function createDropdown(name, options, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, IS_MOBILE and 80 or 64)
        container.BackgroundTransparency = 1
        container.ZIndex = 1

        local label = createLabel(name, IS_MOBILE and 28 or 22)
        label.Parent = container

        local dropdownButton = Instance.new("TextButton")
        dropdownButton.Size = UDim2.new(1, 0, 0, IS_MOBILE and 46 or 36)
        dropdownButton.Position = UDim2.new(0, 0, 0, IS_MOBILE and 36 or 28)
        dropdownButton.BackgroundColor3 = Color3.fromRGB(50, 50, 76)
        dropdownButton.TextColor3 = Color3.fromRGB(245, 245, 255)
        dropdownButton.Text = default or options[1]
        dropdownButton.Font = Enum.Font.Gotham
        dropdownButton.TextSize = IS_MOBILE and FONT_SIZE_MEDIUM or 14
        dropdownButton.AutoButtonColor = false
        dropdownButton.ZIndex = 1
        dropdownButton.Parent = container

        local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0,IS_MOBILE and 10 or 8); corner.Parent = dropdownButton
        local stroke = Instance.new("UIStroke"); stroke.Color = Color3.fromRGB(100,100,150); stroke.Thickness = 1; stroke.Parent = dropdownButton

        dropdownButton.MouseButton1Click:Connect(function()
            if DROPDOWN_STATE.IsOpen then return end
            
            DROPDOWN_STATE.IsOpen = true
            DROPDOWN_STATE.CurrentDropdown = dropdownButton
            
            -- Update dropdown title
            dropdownTitle.Text = "Select " .. name
            
            -- Clear previous options
            for _, child in ipairs(dropdownContent:GetChildren()) do
                if child:IsA("TextButton") then
                    child:Destroy()
                end
            end
            
            -- Create new option buttons
            for _, option in ipairs(options) do
                local optionButton = Instance.new("TextButton")
                optionButton.Size = UDim2.new(1, -20, 0, IS_MOBILE and 60 or 50)
                optionButton.Position = UDim2.new(0, 10, 0, 0)
                optionButton.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                optionButton.TextColor3 = Color3.fromRGB(235,235,255)
                optionButton.Text = option
                optionButton.Font = Enum.Font.Gotham
                optionButton.TextSize = IS_MOBILE and 18 or 16
                optionButton.AutoButtonColor = false
                optionButton.ZIndex = 106
                optionButton.Parent = dropdownContent
                
                local optionCorner = Instance.new("UICorner")
                optionCorner.CornerRadius = UDim.new(0,IS_MOBILE and 8 or 6)
                optionCorner.Parent = optionButton
                
                local optionStroke = Instance.new("UIStroke")
                optionStroke.Color = Color3.fromRGB(80, 80, 120)
                optionStroke.Thickness = 1
                optionStroke.Parent = optionButton

                optionButton.MouseButton1Click:Connect(function()
                    dropdownButton.Text = option
                    if callback then 
                        callback(option)
                        SaveSettings() -- Сохраняем настройки при изменении
                    end
                    closeDropdown()
                end)
                
                -- Hover effects
                optionButton.MouseEnter:Connect(function()
                    TweenService:Create(optionButton, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(60, 60, 85)
                    }):Play()
                end)
                
                optionButton.MouseLeave:Connect(function()
                    TweenService:Create(optionButton, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                    }):Play()
                end)
            end
            
            -- Update content size
            dropdownContent.CanvasSize = UDim2.new(0, 0, 0, #options * (IS_MOBILE and 70 or 60))
            
            -- Show dropdown with animation
            dropdownOverlay.Visible = true
            dropdownContainer.Visible = true
            dropdownOverlay.BackgroundTransparency = IS_MOBILE and 0.3 or 0.7
            dropdownContainer.Size = UDim2.new(0, 0, 0, 0)
            dropdownContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
            dropdownContainer.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local openTween = TweenService:Create(dropdownContainer, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = IS_MOBILE and UDim2.new(0.95, 0, 0.9, 0) or UDim2.new(0.8, 0, 0.8, 0)
            })
            openTween:Play()
        end)

        return {Container = container, Button = dropdownButton}
    end

    local function createSlider(name, minVal, maxVal, default, callback)
        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 0, IS_MOBILE and 100 or 80)
        container.BackgroundTransparency = 1
        container.ZIndex = 1

        local label = createLabel(name .. ": " .. math.floor(default), IS_MOBILE and 28 or 22)
        label.Parent = container

        local sliderContainer = Instance.new("Frame")
        sliderContainer.Size = UDim2.new(1, 0, 0, IS_MOBILE and 50 or 40)
        sliderContainer.Position = UDim2.new(0, 0, 0, IS_MOBILE and 40 or 34)
        sliderContainer.BackgroundTransparency = 1
        sliderContainer.ZIndex = 1
        sliderContainer.Parent = container

        local sliderBar = Instance.new("Frame")
        sliderBar.Size = UDim2.new(1, -18, 0, IS_MOBILE and 12 or 8)
        sliderBar.Position = UDim2.new(0, 9, 0, IS_MOBILE and 19 or 16)
        sliderBar.BackgroundColor3 = Color3.fromRGB(62, 62, 88)
        sliderBar.BorderSizePixel = 0
        sliderBar.ZIndex = 1
        sliderBar.Parent = sliderContainer
        local barCorner = Instance.new("UICorner"); barCorner.CornerRadius = UDim.new(0, IS_MOBILE and 8 or 6); barCorner.Parent = sliderBar

        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        fill.BorderSizePixel = 0
        fill.ZIndex = 1
        fill.Parent = sliderBar
        local fillCorner = Instance.new("UICorner"); fillCorner.CornerRadius = UDim.new(0,IS_MOBILE and 8 or 6); fillCorner.Parent = fill

        local sliderButton = Instance.new("TextButton")
        sliderButton.Size = UDim2.new(0, IS_MOBILE and 28 or 22, 0, IS_MOBILE and 28 or 22)
        sliderButton.Position = UDim2.new((default - minVal) / (maxVal - minVal), IS_MOBILE and -14 or -11, 0.5, IS_MOBILE and -14 or -11)
        sliderButton.BackgroundColor3 = Color3.fromRGB(255,255,255)
        sliderButton.Text = ""
        sliderButton.AutoButtonColor = false
        sliderButton.ZIndex = 2
        sliderButton.Parent = sliderContainer
        local bcorner = Instance.new("UICorner"); bcorner.CornerRadius = UDim.new(0, IS_MOBILE and 14 or 12); bcorner.Parent = sliderButton

        local function updateSlider(value)
            if DROPDOWN_STATE.IsOpen then return end
            value = math.clamp(value, minVal, maxVal)
            local ratio = (value - minVal) / (maxVal - minVal)
            local fillTween = TweenService:Create(fill, TweenInfo.new(0.08), {Size = UDim2.new(ratio, 0, 1, 0)})
            local buttonTween = TweenService:Create(sliderButton, TweenInfo.new(0.08), {Position = UDim2.new(ratio, IS_MOBILE and -14 or -11, 0.5, IS_MOBILE and -14 or -11)})
            fillTween:Play(); buttonTween:Play()
            label.Text = name .. ": " .. math.floor(value)
            if callback then 
                callback(value)
                SaveSettings() -- Сохраняем настройки при изменении
            end
        end

        sliderButton.MouseButton1Down:Connect(function()
            if DROPDOWN_STATE.IsOpen then return end
            local connection
            connection = RunService.Heartbeat:Connect(function()
                local mousePos = UserInputService:GetMouseLocation()
                local barPos = sliderBar.AbsolutePosition
                local barSize = sliderBar.AbsoluteSize
                local relativeX = (mousePos.X - barPos.X) / barSize.X
                relativeX = math.clamp(relativeX, 0, 1)
                local value = minVal + relativeX * (maxVal - minVal)
                updateSlider(value)
            end)

            local endedConn
            endedConn = UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or (IS_MOBILE and input.UserInputType == Enum.UserInputType.Touch) then
                    if connection then connection:Disconnect() end
                    if endedConn then endedConn:Disconnect() end
                end
            end)
        end)

        return {Container = container, Label = label}
    end

    -- Connect close button
    closeDropdownButton.MouseButton1Click:Connect(closeDropdown)

    -- Fill content based on device type
    local elements = {}

    if IS_MOBILE then
        -- Mobile layout - single column
        local mobileContent = Instance.new("Frame")
        mobileContent.Size = UDim2.new(1, 0, 0, 1400)
        mobileContent.BackgroundTransparency = 1
        mobileContent.ZIndex = 1
        mobileContent.Parent = scrollFrame
        
        local mobileLayout = Instance.new("UIListLayout")
        mobileLayout.Padding = UDim.new(0, 15)
        mobileLayout.Parent = mobileContent

        -- Device info
        local deviceInfo = createLabel("Device: " .. (IS_TABLET and "Tablet" or "Mobile"), 28)
        deviceInfo.Font = Enum.Font.GothamBold
        deviceInfo.Parent = mobileContent

        elements.workingLabel = createLabel("Working: 🔴", 32)
        elements.workingLabel.Parent = mobileContent

        elements.moneyLabel = createLabel("Money: 0 💰", 28)
        elements.moneyLabel.Parent = mobileContent

        elements.candyLabel = createLabel("Candy: 0 🍬", 28)
        elements.candyLabel.Parent = mobileContent

        elements.timerLabel = createLabel("Timer: 00:00:00 ⏱", 28)
        elements.timerLabel.Parent = mobileContent

        elements.guiltyLabel = createLabel("Guilty: Unknown 🕵️", 28)
        elements.guiltyLabel.Parent = mobileContent

        elements.queueLabel = createLabel("Queue: Waiting", 28)
        elements.queueLabel.Parent = mobileContent

        -- Add debug status label
        elements.autofarmStatusLabel = createLabel("AutoFarm: Idle", 28)
        elements.autofarmStatusLabel.Parent = mobileContent

        -- Performance and Risk blocks
        local performanceLabel = createLabel("Performance", 30)
        performanceLabel.Font = Enum.Font.GothamBold
        performanceLabel.Parent = mobileContent

        elements.perfLabel = createLabel("Performance: " .. tostring(FPS) .. " FPS", 28)
        elements.perfLabel.Parent = mobileContent

        local riskLabel = createLabel("Risk Assessment", 30)
        riskLabel.Font = Enum.Font.GothamBold
        riskLabel.Parent = mobileContent

        elements.banRiskLabel = createLabel("Ban Risk: Low", 28)
        elements.banRiskLabel.Parent = mobileContent

        -- AutoFarm section
        local autofarmLabel = createLabel("AutoFarm Settings", 32)
        autofarmLabel.Font = Enum.Font.GothamBold
        autofarmLabel.Parent = mobileContent

        elements.autoFarmToggle = createToggle("Auto Farm", SETTINGS.AutoFarmEnabled, function(val)
            SETTINGS.AutoFarmEnabled = val
            DebugLog("AutoFarm toggled: " .. tostring(val))
        end)
        elements.autoFarmToggle.Container.Parent = mobileContent

        elements.pauseToggle = createToggle("Pause Autofarm", SETTINGS.AutoFarmPaused, function(val)
            SETTINGS.AutoFarmPaused = val
            DebugLog("AutoFarm paused: " .. tostring(val))
        end)
        elements.pauseToggle.Container.Parent = mobileContent

        elements.modeDropdown = createDropdown("Farm Mode", {"Legal (Slow)", "Fast (Brutal)"}, SETTINGS.AutofarmMode, function(val)
            SETTINGS.AutofarmMode = val
            DebugLog("Farm mode changed: " .. val)
        end)
        elements.modeDropdown.Container.Parent = mobileContent

        elements.mapDropdown = createDropdown("Select Map", MAPS, SETTINGS.SelectedMap, function(val)
            SETTINGS.SelectedMap = val
            DebugLog("Map changed: " .. val)
        end)
        elements.mapDropdown.Container.Parent = mobileContent

        -- SpeedHack section
        local speedLabel = createLabel("Speed Hack Settings", 32)
        speedLabel.Font = Enum.Font.GothamBold
        speedLabel.Parent = mobileContent

        elements.speedToggle = createToggle("Enable Speed Hack", SETTINGS.SpeedHackEnabled, function(val)
            SETTINGS.SpeedHackEnabled = val
            DebugLog("Speed hack toggled: " .. tostring(val))
        end)
        elements.speedToggle.Container.Parent = mobileContent

        elements.speedSlider = createSlider("Speed Value", 16, 90, SETTINGS.SpeedValue, function(val)
            SETTINGS.SpeedValue = val
            DebugLog("Speed value changed: " .. val)
        end)
        elements.speedSlider.Container.Parent = mobileContent

    else
        -- PC layout - simplified single column for now
        local pcContent = Instance.new("Frame")
        pcContent.Size = UDim2.new(1, 0, 0, 1400)
        pcContent.BackgroundTransparency = 1
        pcContent.ZIndex = 1
        pcContent.Parent = scrollFrame
        
        local pcLayout = Instance.new("UIListLayout")
        pcLayout.Padding = UDim.new(0, 12)
        pcLayout.Parent = pcContent

        -- Device info
        local deviceInfo = createLabel("Device: PC", 24)
        deviceInfo.Font = Enum.Font.GothamBold
        deviceInfo.Parent = pcContent

        elements.workingLabel = createLabel("Working: 🔴", 26)
        elements.workingLabel.Parent = pcContent

        elements.moneyLabel = createLabel("Money: 0 💰", 22)
        elements.moneyLabel.Parent = pcContent

        elements.candyLabel = createLabel("Candy: 0 🍬", 22)
        elements.candyLabel.Parent = pcContent

        elements.timerLabel = createLabel("Timer: 00:00:00 ⏱", 22)
        elements.timerLabel.Parent = pcContent

        elements.guiltyLabel = createLabel("Guilty: Unknown 🕵️", 22)
        elements.guiltyLabel.Parent = pcContent

        elements.queueLabel = createLabel("Queue: Waiting", 22)
        elements.queueLabel.Parent = pcContent

        -- Add debug status label
        elements.autofarmStatusLabel = createLabel("AutoFarm: Idle", 22)
        elements.autofarmStatusLabel.Parent = pcContent

        -- Performance and Risk blocks
        local performanceLabel = createLabel("Performance", 24)
        performanceLabel.Font = Enum.Font.GothamBold
        performanceLabel.Parent = pcContent

        elements.perfLabel = createLabel("Performance: " .. tostring(FPS) .. " FPS", 22)
        elements.perfLabel.Parent = pcContent

        local riskLabel = createLabel("Risk Assessment", 24)
        riskLabel.Font = Enum.Font.GothamBold
        riskLabel.Parent = pcContent

        elements.banRiskLabel = createLabel("Ban Risk: Low", 22)
        elements.banRiskLabel.Parent = pcContent

        -- AutoFarm section
        local autofarmLabel = createLabel("AutoFarm Settings", 24)
        autofarmLabel.Font = Enum.Font.GothamBold
        autofarmLabel.Parent = pcContent

        elements.autoFarmToggle = createToggle("Auto Farm", SETTINGS.AutoFarmEnabled, function(val)
            SETTINGS.AutoFarmEnabled = val
            DebugLog("AutoFarm toggled: " .. tostring(val))
        end)
        elements.autoFarmToggle.Container.Parent = pcContent

        elements.pauseToggle = createToggle("Pause Autofarm", SETTINGS.AutoFarmPaused, function(val)
            SETTINGS.AutoFarmPaused = val
            DebugLog("AutoFarm paused: " .. tostring(val))
        end)
        elements.pauseToggle.Container.Parent = pcContent

        elements.modeDropdown = createDropdown("Farm Mode", {"Legal (Slow)", "Fast (Brutal)"}, SETTINGS.AutofarmMode, function(val)
            SETTINGS.AutofarmMode = val
            DebugLog("Farm mode changed: " .. val)
        end)
        elements.modeDropdown.Container.Parent = pcContent

        elements.mapDropdown = createDropdown("Select Map", MAPS, SETTINGS.SelectedMap, function(val)
            SETTINGS.SelectedMap = val
            DebugLog("Map changed: " .. val)
        end)
        elements.mapDropdown.Container.Parent = pcContent

        -- SpeedHack section
        local speedLabel = createLabel("Speed Hack Settings", 24)
        speedLabel.Font = Enum.Font.GothamBold
        speedLabel.Parent = pcContent

        elements.speedToggle = createToggle("Enable Speed Hack", SETTINGS.SpeedHackEnabled, function(val)
            SETTINGS.SpeedHackEnabled = val
            DebugLog("Speed hack toggled: " .. tostring(val))
        end)
        elements.speedToggle.Container.Parent = pcContent

        elements.speedSlider = createSlider("Speed Value", 16, 90, SETTINGS.SpeedValue, function(val)
            SETTINGS.SpeedValue = val
            DebugLog("Speed value changed: " .. val)
        end)
        elements.speedSlider.Container.Parent = pcContent
    end

    -- Parent GUI
    mainFrame.Parent = screenGui
    showHideButton.Parent = screenGui
    screenGui.Parent = playerGui

    -- Make draggable by title bar (PC only)
    if not IS_MOBILE then
        local dragging, dragInput, dragStart, startPos
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not DROPDOWN_STATE.IsOpen then
                dragging = true
                dragStart = input.Position
                startPos = mainFrame.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging and not DROPDOWN_STATE.IsOpen then
                local delta = input.Position - dragStart
                mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Show/Hide button with adaptive behavior
    showHideButton.MouseButton1Click:Connect(function()
        if not mainFrame.Visible and not DROPDOWN_STATE.IsOpen then
            mainFrame.Visible = true
            if IS_MOBILE then
                -- Mobile: center the frame
                mainFrame.Position = UDim2.new(0.5, -MAIN_WIDTH/2, 0.5, -MAIN_HEIGHT/2)
            end
            mainFrame.Size = UDim2.new(0, 0, 0, 0)
            local openTween = TweenService:Create(mainFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, MAIN_WIDTH, 0, MAIN_HEIGHT)
            })
            openTween:Play()
        end
    end)

    -- Close/minimize
    closeButton.MouseButton1Click:Connect(function()
        if DROPDOWN_STATE.IsOpen then return end
        local closeTween = TweenService:Create(mainFrame, TweenInfo.new(0.28), {Size = UDim2.new(0, 0, 0, 0)})
        closeTween:Play()
        closeTween.Completed:Connect(function()
            mainFrame.Visible = false
        end)
    end)

    -- Mobile: add touch gestures for better usability
    if IS_MOBILE then
        -- Make dropdown overlay close when tapping outside
        dropdownOverlay.MouseButton1Click:Connect(function()
            closeDropdown()
        end)
        
        -- Prevent closing when tapping inside dropdown container
        dropdownContainer.MouseButton1Click:Connect(function()
            -- Do nothing, just prevent event propagation
        end)
    end

    DebugLog("GUI created successfully for " .. (IS_MOBILE and "mobile" or "PC"))
    return {
        Elements = elements,
        MainFrame = mainFrame,
        ScreenGui = screenGui,
        ShowHideButton = showHideButton,
        DropdownOverlay = dropdownOverlay,
        IsMobile = IS_MOBILE
    }
end

-- ========== ЦИКЛ ОБНОВЛЕНИЯ UI ==========
local function startUIUpdateLoop(UI)
    if not UI or not UI.Elements then
        DebugLog("UI or UI.Elements is nil, cannot start update loop")
        return
    end
    
    local startTime = tick()
    local lastCurrencyUpdate = 0
    
    -- Кэшированные значения
    local cachedValues = {
        money = 0,
        candy = 0,
        guilty = "Unknown",
        queue = "Waiting",
        banRisk = "Low"
    }
    
    -- Функция для безопасного обновления текста
    local function safeUpdateLabel(label, text)
        if UI and UI.Elements and UI.Elements[label] then
            UI.Elements[label].Text = text
        end
    end
    
    -- Функция для получения валюты
    local function getCurrency()
        local money, candy = 0, 0
        
        pcall(function()
            local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
            if playerGui then
                -- Попробуем разные возможные пути к интерфейсу игры
                local mainGui = playerGui:FindFirstChild("MainGui") or playerGui:FindFirstChild("MainGUI")
                if mainGui then
                    local holder = mainGui:FindFirstChild("Holder") or mainGui:FindFirstChild("MainFrame")
                    if holder then
                        local top = holder:FindFirstChild("Top") or holder:FindFirstChild("Header")
                        if top then
                            local inner = top:FindFirstChild("Holder") or top:FindFirstChild("CurrencyFrame") or top
                            
                            -- Ищем деньги
                            local coinsObj = inner:FindFirstChild("Coins") or inner:FindFirstChild("Money") or inner:FindFirstChild("Coin")
                            if coinsObj then
                                local amountLabel = coinsObj:FindFirstChild("Amount") or coinsObj:FindFirstChild("Text") or coinsObj:FindFirstChild("Value")
                                if amountLabel and amountLabel:IsA("TextLabel") then
                                    local moneyText = amountLabel.Text:gsub(",", ""):gsub("💰", ""):gsub("$", ""):gsub("%s+", "")
                                    money = tonumber(moneyText) or 0
                                end
                            end
                            
                            -- Ищем конфеты
                            local candyObj = inner:FindFirstChild("Candy") or inner:FindFirstChild("Candies") or inner:FindFirstChild("Sweet")
                            if candyObj then
                                local amountLabel = candyObj:FindFirstChild("Amount") or candyObj:FindFirstChild("Text") or candyObj:FindFirstChild("Value")
                                if amountLabel and amountLabel:IsA("TextLabel") then
                                    local candyText = amountLabel.Text:gsub(",", ""):gsub("🍬", ""):gsub("%s+", "")
                                    candy = tonumber(candyText) or 0
                                end
                            end
                        end
                    end
                end
            end
        end)
        
        return money, candy
    end
    
    -- Основной цикл обновления
    while true do
        pcall(function()
            -- Обновление таймера
            local elapsed = tick() - startTime
            local h = math.floor(elapsed / 3600)
            local m = math.floor((elapsed % 3600) / 60)
            local s = math.floor(elapsed % 60)
            safeUpdateLabel("timerLabel", string.format("Timer: %02d:%02d:%02d ⏱", h, m, s))
            
            -- Обновление статуса очереди
            local inLobby = Workspace:FindFirstChild("Lobby") ~= nil
            local queueText = inLobby and "In Lobby 🏠" or "In Game 🎮"
            safeUpdateLabel("queueLabel", "Queue: " .. queueText)
            
            -- Обновление производительности
            safeUpdateLabel("perfLabel", "Performance: " .. tostring(FPS) .. " FPS")
            
            -- Обновление валюты каждые 2 секунды
            if tick() - lastCurrencyUpdate > 2 then
                local money, candy = getCurrency()
                cachedValues.money = money
                cachedValues.candy = candy
                safeUpdateLabel("moneyLabel", "Money: " .. tostring(money) .. " 💰")
                safeUpdateLabel("candyLabel", "Candy: " .. tostring(candy) .. " 🍬")
                lastCurrencyUpdate = tick()
            else
                -- Используем кэшированные значения
                safeUpdateLabel("moneyLabel", "Money: " .. tostring(cachedValues.money) .. " 💰")
                safeUpdateLabel("candyLabel", "Candy: " .. tostring(cachedValues.candy) .. " 🍬")
            end
            
            -- Обновление статуса виновного
            local guilty = "Unknown"
            pcall(function()
                if RS_Values and RS_Values:FindFirstChild("GuiltySuspect") then
                    guilty = tostring(RS_Values.GuiltySuspect.Value or "Unknown")
                end
            end)
            safeUpdateLabel("guiltyLabel", "Guilty: " .. guilty .. " 🕵️")
            
            -- Обновление риска бана
            local banRisk = "Low"
            if SETTINGS.AutoFarmEnabled and SETTINGS.AutofarmMode == "Fast (Brutal)" then 
                banRisk = "High"
            elseif SETTINGS.AutoFarmEnabled or SETTINGS.SpeedHackEnabled then 
                banRisk = "Medium" 
            end
            safeUpdateLabel("banRiskLabel", "Ban Risk: " .. banRisk)
            
            -- Обновление статуса работы
            local workingStatus = SETTINGS.AutoFarmEnabled and "🟢" or "🔴"
            if SETTINGS.AutoFarmPaused then
                workingStatus = "🟡"
            end
            safeUpdateLabel("workingLabel", "Working: " .. workingStatus)
            
            -- Обновление кэшей ReplicatedStorage
            RefreshReplicatedStorageCaches()
        end)
        
        wait(0.1) -- Частота обновления
    end
end

-- ========== ИГРОВАЯ ЛОГИКА ==========
local function MoveToPosition(targetPos, usePathfinding, timeout)
    timeout = timeout or 15
    if not LocalPlayer or not LocalPlayer.Character then 
        wait(1)
        if not LocalPlayer or not LocalPlayer.Character then 
            return false 
        end
    end
    
    local char = LocalPlayer.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChild("Humanoid")
    if not hrp or not humanoid then 
        wait(0.5)
        hrp = char:FindFirstChild("HumanoidRootPart")
        humanoid = char:FindFirstChild("Humanoid")
        if not hrp or not humanoid then return false end
    end

    local result = { success = false }
    
    if usePathfinding then
        task.spawn(function()
            local path = PathfindingService:CreatePath({
                AgentRadius = 2, 
                AgentHeight = 5, 
                AgentCanJump = true
            })
            
            path:ComputeAsync(hrp.Position, targetPos)
            
            if path.Status == Enum.PathStatus.Success then
                local waypoints = path:GetWaypoints()
                for _, wp in ipairs(waypoints) do
                    humanoid:MoveTo(wp.Position)
                    
                    local start = tick()
                    local reached = false
                    while tick() - start < 5 do
                        if not humanoid or humanoid.Health <= 0 then break end
                        if (hrp.Position - wp.Position).Magnitude < 4 then
                            reached = true
                            break 
                        end
                        task.wait(0.1)
                    end
                    
                    if not reached then
                        humanoid:MoveTo(targetPos)
                        break
                    end
                    
                    if wp.Action == Enum.PathWaypointAction.Jump then
                        humanoid.Jump = true
                    end
                end
                result.success = true
            else
                humanoid:MoveTo(targetPos)
                result.success = true
            end
        end)
    else
        task.spawn(function()
            pcall(function()
                hrp.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))
                result.success = true
            end)
        end)
    end
    
    local startWait = tick()
    while tick() - startWait < timeout do
        if result.success then 
            wait(0.5)
            return true 
        end
        task.wait(0.1)
    end
    
    if humanoid then
        humanoid:MoveTo(targetPos)
        wait(1)
    end
    
    return result.success
end

local AutoState = { Debounce = false, LastAction = 0, RoundHandled = false }

local function RunLobbyRoutine()
    if AutoState.Debounce or SETTINGS.AutoFarmPaused then 
        DebugLog("Lobby routine skipped - debounce or paused")
        return 
    end
    if tick() - AutoState.LastAction < 1 then 
        return 
    end
    AutoState.Debounce = true
    AutoState.LastAction = tick()

    if not Workspace:FindFirstChild("Lobby") then 
        DebugLog("No lobby found")
        AutoState.Debounce = false 
        return 
    end
    
    local lobby = Workspace.Lobby
    local lobbies = lobby:FindFirstChild("Lobbies")
    if not lobbies then 
        DebugLog("No lobbies found")
        AutoState.Debounce = false 
        return 
    end

    local touches = {}
    for _, obj in ipairs(lobbies:GetDescendants()) do
        if obj.Name == "TouchInterest" and obj.Parent and obj.Parent:IsA("BasePart") then
            table.insert(touches, obj.Parent)
        end
    end
    
    if #touches == 0 then 
        DebugLog("No touch interests found")
        AutoState.Debounce = false 
        return 
    end

    local chosen = touches[math.random(1,#touches)]
    local usePath = SETTINGS.AutofarmMode == "Legal (Slow)"
    
    DebugLog("Moving to lobby touch interest (Pathfinding: " .. tostring(usePath) .. ")")
    
    if MoveToPosition(chosen.Position, usePath, 12) then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - chosen.Position).Magnitude < 10 then
            DebugLog("Firing touch interest")
            if typeof(firetouchinterest) == "function" then
                firetouchinterest(hrp, chosen, 0); task.wait(0.08); firetouchinterest(hrp, chosen, 1)
            end
        end
        task.wait(0.5)
        
        if RS_Events and RS_Events:FindFirstChild("CreateParty") then
            pcall(function()
                DebugLog("Creating party for map: " .. SETTINGS.SelectedMap)
                RS_Events.CreateParty:FireServer(1, SETTINGS.SelectedMap, "Anyone")
            end)
        else
            DebugLog("CreateParty event not found")
        end
    else
        DebugLog("Failed to move to lobby touch interest")
    end

    AutoState.Debounce = false
end

local function RunAutoFarmOnce()
    if AutoState.Debounce or SETTINGS.AutoFarmPaused then 
        DebugLog("AutoFarm skipped - debounce or paused")
        return 
    end
    if tick() - AutoState.LastAction < 1 then 
        DebugLog("AutoFarm skipped - too soon since last action")
        return 
    end
    
    AutoState.Debounce = true
    AutoState.LastAction = tick()

    DebugLog("Starting auto-farm cycle")
    
    local mapFolder = Workspace:FindFirstChild("Map")
    local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil
    if not currentMap then 
        DebugLog("No current map found")
        AutoState.Debounce = false 
        return 
    end

    DebugLog("Found map: " .. currentMap.Name)
    
    local exitObj = currentMap:FindFirstChild("Exit") or currentMap:FindFirstChild("exit")
    if not exitObj then
        for _, obj in pairs(currentMap:GetDescendants()) do
            if obj:IsA("BasePart") and (string.lower(obj.Name):find("exit") or string.lower(obj.Name):find("door")) then
                exitObj = obj
                DebugLog("Found exit by name: " .. obj.Name)
                break
            end
        end
    end
    
    if not exitObj then
        DebugLog("No exit object found")
        AutoState.Debounce = false 
        return 
    end

    local exitPrompt = exitObj:FindFirstChildOfClass("ProximityPrompt")
    DebugLog("Exit prompt: " .. tostring(exitPrompt ~= nil))

    local usePath = SETTINGS.AutofarmMode == "Legal (Slow)"
    DebugLog("Moving to exit (Pathfinding: " .. tostring(usePath) .. ")")
    
    if MoveToPosition(exitObj.Position, usePath, 15) then
        DebugLog("Successfully reached exit")
        
        if exitPrompt and typeof(fireproximityprompt) == "function" then
            DebugLog("Activating proximity prompt")
            for i = 1, 3 do
                fireproximityprompt(exitPrompt, 1, false)
                wait(0.2)
            end
        end
        
        wait(0.5)
        
        local suspect = "Unknown"
        pcall(function()
            if RS_Values and RS_Values:FindFirstChild("GuiltySuspect") then
                suspect = tostring(RS_Values.GuiltySuspect.Value or "Unknown")
            end
        end)
        
        DebugLog("Accusing: " .. suspect)
        
        pcall(function()
            if RS_Events and RS_Events:FindFirstChild("AccuseSuspect") then
                RS_Events.AccuseSuspect:FireServer(suspect)
                DebugLog("Accusation fired")
            end
        end)
        
        AutoState.RoundHandled = true
        DebugLog("Round handled successfully")
    else
        DebugLog("Failed to reach exit")
    end

    AutoState.Debounce = false
end

-- AutoFarm Controller
local TaskRunning = false
task.spawn(function()
    while true do
        if SETTINGS.AutoFarmEnabled and not SETTINGS.AutoFarmPaused and not TaskRunning then
            TaskRunning = true
            
            pcall(function()
                local mapFolder = Workspace:FindFirstChild("Map")
                local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil
                
                if currentMap and not AutoState.RoundHandled then
                    DebugLog("State: In Game - Running AutoFarm")
                    if UI and UI.Elements and UI.Elements.autofarmStatusLabel then
                        UI.Elements.autofarmStatusLabel.Text = "AutoFarm: In Game 🎮"
                    end
                    RunAutoFarmOnce()
                elseif Workspace:FindFirstChild("Lobby") then
                    AutoState.RoundHandled = false
                    DebugLog("State: In Lobby - Joining Game")
                    if UI and UI.Elements and UI.Elements.autofarmStatusLabel then
                        UI.Elements.autofarmStatusLabel.Text = "AutoFarm: In Lobby 🏠"
                    end
                    RunLobbyRoutine()
                else
                    DebugLog("State: Loading/Other")
                    if UI and UI.Elements and UI.Elements.autofarmStatusLabel then
                        UI.Elements.autofarmStatusLabel.Text = "AutoFarm: Loading ⏳"
                    end
                    wait(2)
                end
            end)
            
            TaskRunning = false
        else
            if UI and UI.Elements and UI.Elements.autofarmStatusLabel then
                if SETTINGS.AutoFarmPaused then
                    UI.Elements.autofarmStatusLabel.Text = "AutoFarm: Paused ⏸️"
                elseif not SETTINGS.AutoFarmEnabled then
                    UI.Elements.autofarmStatusLabel.Text = "AutoFarm: Disabled 🔴"
                end
            end
        end
        wait(0.5)
    end
end)

-- Speed Hack Implementation
local targetSpeed = DEFAULT_SPEED
local currentSpeed = DEFAULT_SPEED
local lastHumanoidCheck = 0

local function applyToHumanoid(speed)
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    if SETTINGS.SpeedHackEnabled then
        applyToHumanoid(currentSpeed)
        DebugLog("Speed applied to new character: " .. currentSpeed)
    end
end)

RunService.Heartbeat:Connect(function(dt)
    if tick() - lastHumanoidCheck > 2 then
        if SETTINGS.SpeedHackEnabled then
            applyToHumanoid(currentSpeed)
        end
        lastHumanoidCheck = tick()
    end
    
    if SETTINGS.SpeedHackEnabled then
        targetSpeed = SETTINGS.SpeedValue or DEFAULT_SPEED
    else
        targetSpeed = DEFAULT_SPEED
    end
    
    local s = SETTINGS.SpeedSmoothing or 8
    currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * math.clamp(s * dt, 0, 1)
    
    applyToHumanoid(currentSpeed)
end)

-- ========== СОЗДАНИЕ И ЗАПУСК GUI ==========
DebugLog("Starting GUI creation...")
local success, UI = pcall(function()
    return createBeautifulGui()
end)

if success and UI then
    local deviceType = UI.IsMobile and (IS_TABLET and "Tablet" or "Mobile") or "PC"
    Notify(NAME, deviceType .. " GUI loaded - Tap the button to open!", 3)
    DebugLog("GUI created successfully, starting update loop")
    
    pcall(function()
        startUIUpdateLoop(UI)
    end)
else
    local errorMsg = tostring(UI)
    warn("Failed to create GUI: " .. errorMsg)
    Notify("Error", "Failed to load GUI: " .. errorMsg, 5)
end

DebugLog("Adaptive script fully loaded for " .. (IS_MOBILE and (IS_TABLET and "tablet" or "mobile") or "PC"))
RefreshReplicatedStorageCaches()
