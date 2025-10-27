-- Vasia2 - Armless Detective Script (Rayfield Version)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService('Players')
local StarterGui = game:GetService('StarterGui')
local HttpService = game:GetService('HttpService')
local Workspace = game:GetService('Workspace')
local PathfindingService = game:GetService('PathfindingService')
local UserInputService = game:GetService('UserInputService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local LocalPlayer = Players.LocalPlayer

-- Constants
local MAPS = {'Motel Room', 'Humble Abode', 'Bathroom', 'Moolah Manor', 'Cursed Cathedral'}
local NAME = "Vasia2"
local SETTINGS_FILE = "Vasia2_Settings.json"

-- Settings
local SETTINGS = {
    AutoFarmEnabled = false,
    AutoFarmPaused = false,
    AutofarmMode = "Legal (Slow)",
    SelectedMap = "Cursed Cathedral",
    SpeedHackEnabled = false,
    SpeedValue = 16,
}

-- Global state
local AutoState = { Debounce = false, LastAction = 0, RoundHandled = false }
local TaskRunning = false
local FPS = 0
local frameCount = 0
local lastFpsUpdate = tick()
local startTime = tick()

-- Utility Functions
local function Notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore('SendNotification', {
            Title = title or NAME,
            Text = text or '',
            Duration = duration or 3,
        })
    end)
end

local function DebugLog(message)
    print('[DEBUG] ' .. message)
end

-- Save/Load Settings
local function SaveSettings()
    if writefile then
        pcall(function()
            local data = HttpService:JSONEncode(SETTINGS)
            writefile(SETTINGS_FILE, data)
            DebugLog('Settings saved successfully')
        end)
    end
end

local function LoadSettings()
    if readfile and isfile then
        if isfile(SETTINGS_FILE) then
            local success, result = pcall(function()
                local data = readfile(SETTINGS_FILE)
                local loaded = HttpService:JSONDecode(data)
                for key, value in pairs(loaded) do
                    if SETTINGS[key] ~= nil then
                        SETTINGS[key] = value
                    end
                end
                DebugLog('Settings loaded successfully')
                return true
            end)
            return success
        end
    end
    return false
end

-- FPS Counter
RunService.Heartbeat:Connect(function()
    frameCount = frameCount + 1
    local currentTime = tick()
    if currentTime - lastFpsUpdate >= 1 then
        FPS = math.floor(frameCount / (currentTime - lastFpsUpdate))
        frameCount = 0
        lastFpsUpdate = currentTime
    end
end)

-- Game Logic Functions
local function MoveToPosition(targetPos, usePathfinding, timeout)
    timeout = timeout or 15
    if not LocalPlayer or not LocalPlayer.Character then 
        wait(1)
        if not LocalPlayer or not LocalPlayer.Character then 
            return false 
        end
    end
    
    local char = LocalPlayer.Character
    local hrp = char:FindFirstChild('HumanoidRootPart')
    local humanoid = char:FindFirstChild('Humanoid')
    if not hrp or not humanoid then 
        wait(0.5)
        hrp = char:FindFirstChild('HumanoidRootPart')
        humanoid = char:FindFirstChild('Humanoid')
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

local function RunLobbyRoutine()
    if AutoState.Debounce or SETTINGS.AutoFarmPaused then return end
    if tick() - AutoState.LastAction < 1 then return end
    AutoState.Debounce = true
    AutoState.LastAction = tick()

    if not Workspace:FindFirstChild('Lobby') then 
        AutoState.Debounce = false 
        return 
    end
    
    local lobby = Workspace.Lobby
    local lobbies = lobby:FindFirstChild('Lobbies')
    if not lobbies then 
        AutoState.Debounce = false 
        return 
    end

    local touches = {}
    for _, obj in ipairs(lobbies:GetDescendants()) do
        if obj.Name == 'TouchInterest' and obj.Parent and obj.Parent:IsA('BasePart') then
            table.insert(touches, obj.Parent)
        end
    end
    
    if #touches == 0 then 
        AutoState.Debounce = false 
        return 
    end

    local chosen = touches[math.random(1,#touches)]
    local usePath = SETTINGS.AutofarmMode == 'Legal (Slow)'
    
    if MoveToPosition(chosen.Position, usePath, 12) then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart')
        if hrp and (hrp.Position - chosen.Position).Magnitude < 10 then
            if typeof(firetouchinterest) == 'function' then
                firetouchinterest(hrp, chosen, 0); task.wait(0.08); firetouchinterest(hrp, chosen, 1)
            end
        end
        task.wait(0.5)
        
        if ReplicatedStorage:FindFirstChild('Events') and ReplicatedStorage.Events:FindFirstChild('CreateParty') then
            pcall(function()
                ReplicatedStorage.Events.CreateParty:FireServer(1, SETTINGS.SelectedMap, 'Anyone')
            end)
        end
    end

    AutoState.Debounce = false
end

local function RunAutoFarmOnce()
    if AutoState.Debounce or SETTINGS.AutoFarmPaused then return end
    if tick() - AutoState.LastAction < 1 then return end
    
    AutoState.Debounce = true
    AutoState.LastAction = tick()

    local mapFolder = Workspace:FindFirstChild('Map')
    local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil
    if not currentMap then 
        AutoState.Debounce = false 
        return 
    end
    
    local exitObj = currentMap:FindFirstChild('Exit') or currentMap:FindFirstChild('exit')
    if not exitObj then
        for _, obj in pairs(currentMap:GetDescendants()) do
            if obj:IsA('BasePart') and (string.lower(obj.Name):find('exit') or string.lower(obj.Name):find('door')) then
                exitObj = obj
                break
            end
        end
    end
    
    if not exitObj then
        AutoState.Debounce = false 
        return 
    end

    local exitPrompt = exitObj:FindFirstChildOfClass('ProximityPrompt')
    local usePath = SETTINGS.AutofarmMode == 'Legal (Slow)'
    
    if MoveToPosition(exitObj.Position, usePath, 15) then
        if exitPrompt and typeof(fireproximityprompt) == 'function' then
            for i = 1, 3 do
                fireproximityprompt(exitPrompt, 1, false)
                wait(0.2)
            end
        end
        
        wait(0.5)
        
        local suspect = 'Unknown'
        pcall(function()
            if ReplicatedStorage:FindFirstChild('Values') and ReplicatedStorage.Values:FindFirstChild('GuiltySuspect') then
                suspect = tostring(ReplicatedStorage.Values.GuiltySuspect.Value or 'Unknown')
            end
        end)
        
        pcall(function()
            if ReplicatedStorage:FindFirstChild('Events') and ReplicatedStorage.Events:FindFirstChild('AccuseSuspect') then
                ReplicatedStorage.Events.AccuseSuspect:FireServer(suspect)
            end
        end)
        
        AutoState.RoundHandled = true
    end

    AutoState.Debounce = false
end

-- AutoFarm Controller
task.spawn(function()
    while true do
        if SETTINGS.AutoFarmEnabled and not SETTINGS.AutoFarmPaused and not TaskRunning then
            TaskRunning = true
            
            pcall(function()
                local mapFolder = Workspace:FindFirstChild('Map')
                local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil
                
                if currentMap and not AutoState.RoundHandled then
                    RunAutoFarmOnce()
                elseif Workspace:FindFirstChild('Lobby') then
                    AutoState.RoundHandled = false
                    RunLobbyRoutine()
                else
                    wait(2)
                end
            end)
            
            TaskRunning = false
        end
        wait(0.5)
    end
end)

-- Speed Hack Implementation
local targetSpeed = 16
local currentSpeed = 16
local lastHumanoidCheck = 0

local function applyToHumanoid(speed)
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild('Humanoid')
    if humanoid then
        humanoid.WalkSpeed = speed
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    wait(1)
    if SETTINGS.SpeedHackEnabled then
        applyToHumanoid(currentSpeed)
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
        targetSpeed = SETTINGS.SpeedValue or 16
    else
        targetSpeed = 16
    end
    
    currentSpeed = currentSpeed + (targetSpeed - currentSpeed) * math.clamp(8 * dt, 0, 1)
    applyToHumanoid(currentSpeed)
end)

-- Currency function
local function getCurrency()
    local money, candy = 0, 0
    
    pcall(function()
        local playerGui = LocalPlayer and LocalPlayer:FindFirstChild('PlayerGui')
        if playerGui then
            -- Try to find currency in different locations
            local function findCurrencyValue(currencyNames)
                for _, name in ipairs(currencyNames) do
                    local locations = {
                        playerGui:FindFirstChild('MainGui'),
                        playerGui:FindFirstChild('MainGUI'), 
                        playerGui:FindFirstChild('GameUI'),
                        playerGui:FindFirstChild('Interface')
                    }
                    
                    for _, location in ipairs(locations) do
                        if location then
                            for _, child in ipairs(location:GetDescendants()) do
                                if child:IsA('TextLabel') or child:IsA('TextButton') then
                                    local text = string.lower(child.Text)
                                    if string.find(text, name) or string.find(child.Name, name) then
                                        local numbers = string.gsub(text, '%D+', '')
                                        if numbers ~= '' then
                                            return tonumber(numbers) or 0
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
                return 0
            end
            
            money = findCurrencyValue({'coin', 'money', 'cash', '💰', '$'})
            candy = findCurrencyValue({'candy', 'sweet', '🍬'})
            
            -- Alternative method: check ReplicatedStorage
            if money == 0 and candy == 0 then
                pcall(function()
                    if ReplicatedStorage:FindFirstChild('Values') then
                        local values = ReplicatedStorage.Values
                        if values:FindFirstChild('Coins') then
                            money = values.Coins.Value or 0
                        end
                        if values:FindFirstChild('Candy') then
                            candy = values.Candy.Value or 0
                        end
                    end
                end)
            end
        end
    end)
    
    return money, candy
end

-- Load settings first
LoadSettings()

-- Main UI with Rayfield
local Window = Rayfield:CreateWindow({
    Name = NAME .. ' - Armless Detective',
    LoadingTitle = NAME,
    LoadingSubtitle = 'by Vasia2',
    ConfigurationSaving = { Enabled = true, FolderName = 'Vasia2', FileName = 'config' },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- Tabs
local AutofarmTab = Window:CreateTab('Autofarm 🎮')
local UtilitiesTab = Window:CreateTab('Utilities 🛠')

-- Status Labels
local MoneyLabel = AutofarmTab:CreateLabel('Money: 0 💰')
local CandyLabel = AutofarmTab:CreateLabel('Candy: 0 🍬')
local TimerLabel = AutofarmTab:CreateLabel('Timer: 00:00:00 ⏱')
local GuiltyLabel = AutofarmTab:CreateLabel('Guilty: Unknown 🕵️')
local QueueLabel = AutofarmTab:CreateLabel('Queue: Waiting')
local AutofarmStatusLabel = AutofarmTab:CreateLabel('AutoFarm: Idle')

-- Autofarm Toggles
local AutoFarmToggle = AutofarmTab:CreateToggle({
    Name = 'Auto Farm',
    CurrentValue = SETTINGS.AutoFarmEnabled,
    Flag = 'AutoFarmToggle',
    Callback = function(Value)
        SETTINGS.AutoFarmEnabled = Value
        SaveSettings()
        Notify('AutoFarm', Value and 'AutoFarm enabled 🎮' or 'AutoFarm disabled', 3)
    end,
})

local PauseToggle = AutofarmTab:CreateToggle({
    Name = 'Pause Autofarm',
    CurrentValue = SETTINGS.AutoFarmPaused,
    Flag = 'AutoFarmPauseToggle',
    Callback = function(Value)
        SETTINGS.AutoFarmPaused = Value
        SaveSettings()
        Notify('AutoFarm', Value and 'AutoFarm paused ⏸' or 'AutoFarm resumed ▶️', 3)
    end,
})

-- Dropdowns
local ModeDropdown = AutofarmTab:CreateDropdown({
    Name = 'Farm Mode',
    Options = {'Legal (Slow)', 'Fast (Brutal)'},
    CurrentOption = {SETTINGS.AutofarmMode},
    MultipleOptions = false,
    Flag = 'AutofarmMode',
    Callback = function(option)
        SETTINGS.AutofarmMode = option[1]
        SaveSettings()
        Notify('AutoFarm', 'Mode set to: ' .. option[1], 3)
    end,
})

local MapDropdown = AutofarmTab:CreateDropdown({
    Name = 'Select Map',
    Options = MAPS,
    CurrentOption = {SETTINGS.SelectedMap},
    MultipleOptions = false,
    Flag = 'SelectedMap',
    Callback = function(option)
        SETTINGS.SelectedMap = option[1]
        SaveSettings()
        Notify('AutoFarm', 'Selected map: ' .. option[1], 3)
    end,
})

-- Utilities Tab
local PerformanceLabel = UtilitiesTab:CreateLabel('FPS: 0')
local BanRiskLabel = UtilitiesTab:CreateLabel('Ban Risk: Low')

-- Speed Hack
local SpeedToggle = UtilitiesTab:CreateToggle({
    Name = 'Enable Speed Hack',
    CurrentValue = SETTINGS.SpeedHackEnabled,
    Flag = 'SpeedHackToggle',
    Callback = function(Value)
        SETTINGS.SpeedHackEnabled = Value
        SaveSettings()
        Notify('Speed Hack', Value and 'Speed hack enabled ⚡' or 'Speed hack disabled', 3)
    end,
})

local SpeedSlider = UtilitiesTab:CreateSlider({
    Name = 'Speed Value',
    Range = {16, 90},
    Increment = 1,
    CurrentValue = SETTINGS.SpeedValue,
    Flag = 'SpeedHackValue',
    Callback = function(Value)
        SETTINGS.SpeedValue = Value
        SaveSettings()
        if SpeedToggle:Get() and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid') then
            LocalPlayer.Character.Humanoid.WalkSpeed = Value
        end
    end,
})

-- UI Update Loop
task.spawn(function()
    local lastCurrencyUpdate = 0
    local lastTimerUpdate = 0
    local cachedValues = {
        money = 0,
        candy = 0,
        guilty = 'Unknown',
        queue = 'Waiting',
        banRisk = 'Low'
    }
    
    while true do
        pcall(function()
            -- Timer update
            local currentTime = tick()
            if currentTime - lastTimerUpdate > 0.5 then
                local elapsed = currentTime - startTime
                local h = math.floor(elapsed / 3600)
                local m = math.floor((elapsed % 3600) / 60)
                local s = math.floor(elapsed % 60)
                TimerLabel:Set(string.format('Timer: %02d:%02d:%02d ⏱', h, m, s))
                lastTimerUpdate = currentTime
            end
            
            -- Queue status
            local inLobby = Workspace:FindFirstChild('Lobby') ~= nil
            local queueText = inLobby and 'In Lobby 🏠' or 'In Game 🎮'
            QueueLabel:Set('Queue: ' .. queueText)
            
            -- Performance
            PerformanceLabel:Set('FPS: ' .. tostring(FPS))
            
            -- Currency update
            if tick() - lastCurrencyUpdate > 3 then
                local money, candy = getCurrency()
                cachedValues.money = money
                cachedValues.candy = candy
                MoneyLabel:Set('Money: ' .. tostring(money) .. ' 💰')
                CandyLabel:Set('Candy: ' .. tostring(candy) .. ' 🍬')
                lastCurrencyUpdate = tick()
            else
                MoneyLabel:Set('Money: ' .. tostring(cachedValues.money) .. ' 💰')
                CandyLabel:Set('Candy: ' .. tostring(cachedValues.candy) .. ' 🍬')
            end
            
            -- Guilty suspect
            local guilty = 'Unknown'
            pcall(function()
                if ReplicatedStorage:FindFirstChild('Values') and ReplicatedStorage.Values:FindFirstChild('GuiltySuspect') then
                    guilty = tostring(ReplicatedStorage.Values.GuiltySuspect.Value or 'Unknown')
                end
            end)
            GuiltyLabel:Set('Guilty: ' .. guilty .. ' 🕵️')
            
            -- Ban risk
            local banRisk = 'Low'
            if SETTINGS.AutoFarmEnabled and SETTINGS.AutofarmMode == 'Fast (Brutal)' then 
                banRisk = 'High'
            elseif SETTINGS.AutoFarmEnabled or SETTINGS.SpeedHackEnabled then 
                banRisk = 'Medium' 
            end
            BanRiskLabel:Set('Ban Risk: ' .. banRisk)
            
            -- Autofarm status
            local autofarmStatus = 'Idle'
            if SETTINGS.AutoFarmEnabled and not SETTINGS.AutoFarmPaused then
                local inLobby = Workspace:FindFirstChild('Lobby') ~= nil
                local inGame = Workspace:FindFirstChild('Map') ~= nil
                
                if inLobby then
                    autofarmStatus = 'In Lobby 🏠'
                elseif inGame then
                    autofarmStatus = 'In Game 🎮'
                else
                    autofarmStatus = 'Searching 🔍'
                end
            elseif SETTINGS.AutoFarmPaused then
                autofarmStatus = 'Paused ⏸️'
            else
                autofarmStatus = 'Disabled 🔴'
            end
            AutofarmStatusLabel:Set('AutoFarm: ' .. autofarmStatus)
        end)
        
        wait(0.1)
    end
end)

-- Initial notification
Notify(NAME, 'Script loaded successfully! 🌟', 4)
