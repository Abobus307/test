print("Loading...")

local function waitForGameLoad()
    while not game:IsLoaded() do
        task.wait(0.1)
    end

    local Players = game:GetService("Players")
    while not Players.LocalPlayer do
        task.wait(0.1)
    end

    local LocalPlayer = Players.LocalPlayer

    while not LocalPlayer.Character do
        task.wait(0.1)
    end

    task.wait(2)
    return true
end

local function initializeScript()
    local success = pcall(waitForGameLoad)
    if not success then
        warn("Error loading script, continuing with caution...")
        task.wait(3)
    end

    local _GAME_SERVICES = {}
    local function _GET_SERVICE(name)
        if not _GAME_SERVICES[name] then
            _GAME_SERVICES[name] = game:GetService(name)
        end
        return _GAME_SERVICES[name]
    end

    local _SYS_PLAYERS = _GET_SERVICE("Players")
    local _SYS_STARTERGUI = _GET_SERVICE("StarterGui")
    local _SYS_REPLICATEDSTORAGE = _GET_SERVICE("ReplicatedStorage")
    local _SYS_HTTPSERVICE = _GET_SERVICE('HttpService')
    local _SYS_WORKSPACE = _GET_SERVICE('Workspace')
    local _SYS_PATHFINDING = _GET_SERVICE('PathfindingService')
    local _SYS_USERINPUT = _GET_SERVICE('UserInputService')
    local _SYS_RUNSERVICE = _GET_SERVICE('RunService')
    local _SYS_TELEPORT = _GET_SERVICE('TeleportService')
    local _SYS_LOCALPLAYER = _SYS_PLAYERS.LocalPlayer

    local _DATA_LASTLOBBYTELEPORT = 0

    local _PROTECTION_CONFIG = {
        Enabled = false,
        Action = "Notify",
        CheckInterval = 30,
        GroupId = 946378404,
        ModRoleIds = {490360110, 8987623965, 4118621240},
        ProximityAlert = true,
        ProximityDistance = 50
    }

    local _PROTECTION_MODLIST = {}
    local _PROTECTION_MODCOUNT = 0
    local _PROTECTION_LASTCHECK = 0
    local _PROTECTION_RUNNING = false

    local function _EXECUTE_ANTI_MOD_ACTION(modName)
        local action = _PROTECTION_CONFIG.Action
        local message = "System alert: " .. modName
        
        if _SYS_WINDUI then
            _SYS_WINDUI:Notify({
                Title = "SYSTEM",
                Content = message,
                Duration = 10,
                Icon = "alert",
            })
        else
            pcall(function()
                _SYS_STARTERGUI:SetCore('SendNotification', {
                    Title = "SYSTEM",
                    Text = message,
                    Duration = 10,
                })
            end)
        end
        
        if action == "Leave" then
            _SYS_LOCALPLAYER:Kick("SYSTEM: " .. modName)
        elseif action == "ServerHop" then
            pcall(function()
                _SYS_TELEPORT:Teleport(game.PlaceId, _SYS_LOCALPLAYER)
            end)
        elseif action == "Destruct" then
            if _SYS_WINDUI then
                _SYS_WINDUI:Notify({
                    Title = "SYSTEM",
                    Content = "Safety protocol activated",
                    Duration = 5,
                    Icon = "alert",
                })
            else
                pcall(function()
                    _SYS_STARTERGUI:SetCore('SendNotification', {
                        Title = "SYSTEM",
                        Text = "Safety protocol activated",
                        Duration = 5,
                    })
                end)
            end
        end
    end

    local function _UPDATE_MODERATOR_UI()
        if _UI_MODCOUNT then
            _UI_MODCOUNT:SetDesc(_PROTECTION_MODCOUNT .. " 🚨")
        end
        
        if _UI_MODNAMES then
            if _PROTECTION_MODCOUNT > 0 then
                _UI_MODNAMES:SetDesc(table.concat(_PROTECTION_MODLIST, ", "))
            else
                _UI_MODNAMES:SetDesc("No alerts")
            end
        end
    end

    local function _CHECK_PLAYER_ROLES(player)
        if not _PROTECTION_CONFIG.Enabled or not _SYS_PLAYERS:GetPlayerByUserId(player.UserId) then
            return false
        end

        local success, roles = pcall(function()
            return _SYS_PLAYERS:GetRolesInGroupAsync(player.UserId, _PROTECTION_CONFIG.GroupId)
        end)

        if success and roles then
            local isModerator = false
            
            for _, roleId in ipairs(roles) do
                for _, modRoleId in ipairs(_PROTECTION_CONFIG.ModRoleIds) do
                    if roleId == modRoleId then
                        isModerator = true
                        break
                    end
                end
                if isModerator then
                    break
                end
            end

            if isModerator and not table.find(_PROTECTION_MODLIST, player.Name) then
                table.insert(_PROTECTION_MODLIST, player.Name)
                _PROTECTION_MODCOUNT = _PROTECTION_MODCOUNT + 1
                _UPDATE_MODERATOR_UI()
                _EXECUTE_ANTI_MOD_ACTION(player.Name)
                return true
            end
        end
        return false
    end

    local function _MONITOR_MOD_PROXIMITY()
        if not _PROTECTION_CONFIG.Enabled or not _PROTECTION_CONFIG.ProximityAlert or _PROTECTION_MODCOUNT == 0 then
            return
        end

        local character = _SYS_LOCALPLAYER.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end

        local playerPos = character.HumanoidRootPart.Position
        
        for _, player in ipairs(_SYS_PLAYERS:GetPlayers()) do
            if table.find(_PROTECTION_MODLIST, player.Name) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local modPos = player.Character.HumanoidRootPart.Position
                local distance = (playerPos - modPos).Magnitude
                
                if distance <= _PROTECTION_CONFIG.ProximityDistance then
                    if _SYS_WINDUI then
                        _SYS_WINDUI:Notify({
                            Title = "WARNING",
                            Content = "Alert: " .. player.Name .. " proximity! " .. math.floor(distance) .. " units",
                            Duration = 5,
                            Icon = "alert",
                        })
                    else
                        pcall(function()
                            _SYS_STARTERGUI:SetCore('SendNotification', {
                                Title = "WARNING",
                                Text = "Alert: " .. player.Name .. " proximity! " .. math.floor(distance) .. " units",
                                Duration = 5,
                            })
                        end)
                    end
                    task.wait(10)
                    break
                end
            end
        end
    end

    local function _ANTI_MOD_LOOP()
        if _PROTECTION_RUNNING or not _PROTECTION_CONFIG.Enabled then
            return
        end

        _PROTECTION_RUNNING = true
        
        while _PROTECTION_CONFIG.Enabled do
            local currentTime = tick()
            
            if currentTime - _PROTECTION_LASTCHECK >= _PROTECTION_CONFIG.CheckInterval then
                _PROTECTION_MODLIST = {}
                _PROTECTION_MODCOUNT = 0
                
                for _, player in ipairs(_SYS_PLAYERS:GetPlayers()) do
                    if player ~= _SYS_LOCALPLAYER then
                        _CHECK_PLAYER_ROLES(player)
                        task.wait(0.3)
                    end
                end
                
                _PROTECTION_LASTCHECK = currentTime
                _UPDATE_MODERATOR_UI()
            end
            
            _MONITOR_MOD_PROXIMITY()
            task.wait(5)
        end
        
        _PROTECTION_RUNNING = false
    end

    local function _FORCE_FULL_CHECK()
        if not _PROTECTION_CONFIG.Enabled then
            if _SYS_WINDUI then
                _SYS_WINDUI:Notify({
                    Title = "SYSTEM",
                    Content = "Enable protection first",
                    Duration = 3,
                    Icon = "info",
                })
            else
                pcall(function()
                    _SYS_STARTERGUI:SetCore('SendNotification', {
                        Title = "SYSTEM",
                        Text = "Enable protection first",
                        Duration = 3,
                    })
                end)
            end
            return
        end
        
        local originalModCount = _PROTECTION_MODCOUNT
        _PROTECTION_MODLIST = {}
        _PROTECTION_MODCOUNT = 0
        
        if _SYS_WINDUI then
            _SYS_WINDUI:Notify({
                Title = "SYSTEM",
                Content = "Scanning all players...",
                Duration = 2,
                Icon = "search",
            })
        else
            pcall(function()
                _SYS_STARTERGUI:SetCore('SendNotification', {
                    Title = "SYSTEM",
                    Text = "Scanning all players...",
                    Duration = 2,
                })
            end)
        end
        
        local foundModerators = {}
        
        for _, player in ipairs(_SYS_PLAYERS:GetPlayers()) do
            if player ~= _SYS_LOCALPLAYER then
                local isMod = _CHECK_PLAYER_ROLES(player)
                if isMod then
                    table.insert(foundModerators, player.Name)
                end
                task.wait(0.2)
            end
        end
        
        _PROTECTION_LASTCHECK = 0
        _UPDATE_MODERATOR_UI()
        
        if #foundModerators > 0 then
            if _SYS_WINDUI then
                _SYS_WINDUI:Notify({
                    Title = "SCAN RESULT",
                    Content = "🚨 DETECTED " .. #foundModerators .. " ALERTS: " .. table.concat(foundModerators, ", "),
                    Duration = 8,
                    Icon = "alert",
                })
            else
                pcall(function()
                    _SYS_STARTERGUI:SetCore('SendNotification', {
                        Title = "SCAN RESULT",
                        Text = "🚨 DETECTED " .. #foundModerators .. " ALERTS: " .. table.concat(foundModerators, ", "),
                        Duration = 8,
                    })
                end)
            end
        else
            if _SYS_WINDUI then
                _SYS_WINDUI:Notify({
                    Title = "SCAN RESULT",
                    Content = "✅ NO ALERTS FOUND - System normal",
                    Duration = 5,
                    Icon = "success",
                })
            else
                pcall(function()
                    _SYS_STARTERGUI:SetCore('SendNotification', {
                        Title = "SCAN RESULT",
                        Text = "✅ NO ALERTS FOUND - System normal",
                        Duration = 5,
                    })
                end)
            end
        end
    end

    _SYS_PLAYERS.PlayerRemoving:Connect(function(player)
        if table.find(_PROTECTION_MODLIST, player.Name) then
            local index = table.find(_PROTECTION_MODLIST, player.Name)
            table.remove(_PROTECTION_MODLIST, index)
            _PROTECTION_MODCOUNT = _PROTECTION_MODCOUNT - 1
            _UPDATE_MODERATOR_UI()
        end
    end)

    local _DEBUG_MODE = false
    local _DEBOUNCE_FLAG = false

    local function _DEBUG_LOG(...)
        if _DEBUG_MODE then print("[SYSTEM] ", ...) end
    end

    local function _FIND_MENU_GUI()
        local mg = _SYS_STARTERGUI:FindFirstChild("MenuGui")
        if mg then return mg end
        if _SYS_LOCALPLAYER and _SYS_LOCALPLAYER:FindFirstChild("PlayerGui") then
            return _SYS_LOCALPLAYER.PlayerGui:FindFirstChild("MenuGui")
        end
        return nil
    end

    local function _COLLECT_PLAY_BUTTONS(menuGui)
        local out = {}
        if not menuGui then return out end
        for _, child in ipairs(menuGui:GetChildren()) do
            local name = tostring(child.Name)
            if name:sub(1,4) == "Play" then
                local clickButton = child:FindFirstChild("Click")
                if clickButton and clickButton:IsA("TextButton") then
                    table.insert(out, {frame = child, button = clickButton, name = child.Name})
                else
                    for _, gc in ipairs(child:GetChildren()) do
                        if gc.Name == "Click" and gc:IsA("TextButton") then
                            table.insert(out, {frame = child, button = gc, name = child.Name})
                            break
                        end
                    end
                end
            end
        end
        return out
    end

    local function _TRY_ACTIVATE_BUTTON(btn)
        if not btn or not btn:IsA("TextButton") then return false end

        if pcall(function() btn:Activate() end) then
            _DEBUG_LOG("Activated:", btn:GetFullName())
            return true
        end

        if btn:FindFirstChild("MouseButton1Click") and typeof(btn.MouseButton1Click.Fire) == "function" then
            if pcall(function() btn.MouseButton1Click:Fire() end) then
                _DEBUG_LOG("MouseButton1Click fired for", btn:GetFullName())
                return true
            end
        end

        if btn:FindFirstChild("MouseButton1Down") and btn:FindFirstChild("MouseButton1Up") then
            if pcall(function()
                btn.MouseButton1Down:Fire()
                task.wait(0.06)
                btn.MouseButton1Up:Fire()
            end) then
                _DEBUG_LOG("Down/Up fired for", btn:GetFullName())
                return true
            end
        end

        return false
    end

    local _REMOTE_NAMES = {
        "Play",
        "PlaySound",
        "PlayerLoaded",
        "DisplayChatMessage",
        "PressedPlayButton",
        "OpenDailyRewardsMenu",
        "Roblox_PlayHalloweenSuspectAnimation"
    }

    local function _FIRE_REMOTES()
        local eventsFolder = _SYS_REPLICATEDSTORAGE:FindFirstChild("Events")
        local firedAny = false

        local function _TRY_FIRE(obj)
            if not obj then return false end
            if obj:IsA("RemoteEvent") then
                local ok = pcall(function() obj:FireServer() end)
                if ok then
                    _DEBUG_LOG("Fired RemoteEvent:", obj:GetFullName())
                    return true
                else
                    _DEBUG_LOG("Failed to fire (RemoteEvent):", obj:GetFullName())
                end
            elseif obj:IsA("RemoteFunction") then
                local ok = pcall(function() obj:InvokeServer() end)
                if ok then
                    _DEBUG_LOG("Invoked RemoteFunction:", obj:GetFullName())
                    return true
                else
                    _DEBUG_LOG("Failed to invoke (RemoteFunction):", obj:GetFullName())
                end
            end
            return false
        end

        if eventsFolder then
            for _, name in ipairs(_REMOTE_NAMES) do
                local r = eventsFolder:FindFirstChild(name)
                if r and _TRY_FIRE(r) then
                    firedAny = true
                end
            end
        end

        for _, name in ipairs(_REMOTE_NAMES) do
            if not firedAny then
                local rTop = _SYS_REPLICATEDSTORAGE:FindFirstChild(name)
                if rTop and _TRY_FIRE(rTop) then
                    firedAny = true
                end
            else
            end
        end

        return firedAny
    end

    local function _QUICK_PLAY_ROUTINE()
        if _DEBOUNCE_FLAG then
            _DEBUG_LOG("debounce active, exit")
            return false
        end
        _DEBOUNCE_FLAG = true

        task.wait(0.8)

        local menuGui = _FIND_MENU_GUI()
        if not menuGui then
            warn("MenuGui not found")
            _DEBOUNCE_FLAG = false
            return false
        end

        local playButtons = _COLLECT_PLAY_BUTTONS(menuGui)

        if #playButtons > 0 then
            _DEBUG_LOG("Found play buttons:", #playButtons)
            for _, pbtn in ipairs(playButtons) do
                _DEBUG_LOG("Trying to activate:", pbtn.name)
                if _TRY_ACTIVATE_BUTTON(pbtn.button) then
                    task.wait(0.45)
                    if not _FIND_MENU_GUI() then
                        _DEBUG_LOG("Menu closed after pressing button:", pbtn.name)
                        _DEBOUNCE_FLAG = false
                        return true
                    end
                end
            end
        else
            _DEBUG_LOG("No Play buttons found in MenuGui")
        end

        _DEBUG_LOG("Trying to call target remotes from ReplicatedStorage.Events")
        local remotesFired = _FIRE_REMOTES()
        task.wait(0.6)

        if remotesFired and not _FIND_MENU_GUI() then
            _DEBUG_LOG("Menu closed after firing remotes")
            _DEBOUNCE_FLAG = false
            return true
        end

        _DEBUG_LOG("Retrying to activate buttons as fallback")
        for _, pbtn in ipairs(playButtons) do
            if _TRY_ACTIVATE_BUTTON(pbtn.button) then
                task.wait(0.45)
                if not _FIND_MENU_GUI() then
                    _DEBUG_LOG("Menu closed on retry:", pbtn.name)
                    _DEBOUNCE_FLAG = false
                    return true
                end
            end
        end

        _DEBUG_LOG("Nothing closed the menu")
        _DEBOUNCE_FLAG = false
        return false
    end

    _QUICK_PLAY_ROUTINE()
    task.wait(1)

    _SYS_WINDUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

    local _MAP_LIST = {'Motel Room', 'Humble Abode', 'Bathroom', 'Moolah Manor', 'Gas Station', 'Abandoned Apartment'}
    local _APP_NAME = "ArmlessToolkit"
    local _SETTINGS_FILE = "ArmlessToolkit_Settings.json"

    local _SETTINGS_DATA = {
        AutoFarmEnabled = false,
        AutoFarmPaused = false,
        AutofarmMode = "Legit (Slow)",
        SelectedMap = "Cursed Cathedral",
        SpeedHackEnabled = false,
        SpeedValue = 16,
        AntiModEnabled = false,
        AntiModAction = "Notify",
        AntiModProximityAlert = true
    }

    local function _LOAD_SETTINGS()
        if readfile and isfile then
            if isfile(_SETTINGS_FILE) then
                local success, result = pcall(function()
                    local data = readfile(_SETTINGS_FILE)
                    local loaded = _SYS_HTTPSERVICE:JSONDecode(data)
                    for key, value in pairs(loaded) do
                        if _SETTINGS_DATA[key] ~= nil then
                            _SETTINGS_DATA[key] = value
                        end
                    end
                    return true
                end)
                return success
            end
        end
        return false
    end

    _LOAD_SETTINGS()

    _PROTECTION_CONFIG.Enabled = _SETTINGS_DATA.AntiModEnabled
    _PROTECTION_CONFIG.Action = _SETTINGS_DATA.AntiModAction
    _PROTECTION_CONFIG.ProximityAlert = _SETTINGS_DATA.AntiModProximityAlert

    local _AUTOFARM_STATE = { Debounce = false, LastAction = 0, RoundHandled = false }
    local _TASK_RUNNING = false
    local _FPS_VALUE = 0
    local _FRAME_COUNTER = 0
    local _LAST_FPS_UPDATE = tick()
    local _START_TIME = tick()

    local function _SHOW_NOTIFICATION(title, text, duration)
        if _SYS_WINDUI then
            _SYS_WINDUI:Notify({
                Title = title or _APP_NAME,
                Content = text or '',
                Duration = duration or 3,
                Icon = "info",
            })
        else
            pcall(function()
                _SYS_STARTERGUI:SetCore('SendNotification', {
                    Title = title or _APP_NAME,
                    Text = text or '',
                    Duration = duration or 3,
                })
            end)
        end
    end

    local function _SAVE_SETTINGS()
        if writefile then
            pcall(function()
                _SETTINGS_DATA.AntiModEnabled = _PROTECTION_CONFIG.Enabled
                _SETTINGS_DATA.AntiModAction = _PROTECTION_CONFIG.Action
                _SETTINGS_DATA.AntiModProximityAlert = _PROTECTION_CONFIG.ProximityAlert
                
                local data = _SYS_HTTPSERVICE:JSONEncode(_SETTINGS_DATA)
                writefile(_SETTINGS_FILE, data)
            end)
        end
    end

    local _MAIN_WINDOW = _SYS_WINDUI:CreateWindow({
        Title = _APP_NAME .. ' - Armless Detective',
        Author = 'by System',
        Folder = 'ArmlessToolkit',
        Theme = "Dark",
        Transparent = true,
    })

    local _TAB_AUTOFARM = _MAIN_WINDOW:Tab({ Title = 'Autofarm 🎮' })
    local _TAB_ANTIMOD = _MAIN_WINDOW:Tab({ Title = 'Anti-Mod 🛡️' })
    local _TAB_UTILITIES = _MAIN_WINDOW:Tab({ Title = 'Utilities 🛠' })
    local _TAB_STATISTICS = _MAIN_WINDOW:Tab({ Title = 'Statistics 📊' })

    local _BUTTON_RETURNLOBBY = _TAB_UTILITIES:Button({
        Title = 'Return to Lobby 🔄',
        Desc = 'Teleport to lobby',
        Callback = function()
            local currentTime = tick()
            local cooldownRemaining = 3 - (currentTime - _DATA_LASTLOBBYTELEPORT)
            
            if cooldownRemaining > 0 then
                _SYS_WINDUI:Notify({
                    Title = "Cooldown",
                    Content = "Please wait " .. math.ceil(cooldownRemaining) .. " seconds",
                    Duration = 2,
                    Icon = "info",
                })
                return
            end
            
            _DATA_LASTLOBBYTELEPORT = currentTime
            
            _SYS_WINDUI:Notify({
                Title = "Teleporting",
                Content = "Returning to lobby...",
                Duration = 2,
                Icon = "info",
            })
            
            pcall(function()
                _SYS_TELEPORT:Teleport(97719631053849, _SYS_LOCALPLAYER)
            end)
        end,
    })

    local _UI_ANTIMODWARNING = _TAB_ANTIMOD:Paragraph({ 
        Title = '⚠️ BETA TESTING', 
        Desc = 'This feature is in testing phase. Bugs may occur!' 
    })

    _UI_MODCOUNT = _TAB_ANTIMOD:Paragraph({ Title = 'Moderators Online', Desc = '0 🚨' })
    _UI_MODNAMES = _TAB_ANTIMOD:Paragraph({ Title = 'Moderator List', Desc = 'No alerts' })
    
    local initialAntiModStatus = _PROTECTION_CONFIG.Enabled and '🟢Active' or '🔴Disabled'
    local _UI_ANTIMODSTATUS = _TAB_ANTIMOD:Paragraph({ Title = 'System Status', Desc = initialAntiModStatus })

    local _TOGGLE_ANTIMOD = _TAB_ANTIMOD:Toggle({
        Title = 'Protection System',
        Desc = 'Enable security protection',
        Value = _PROTECTION_CONFIG.Enabled,
        Callback = function(Value)
            _PROTECTION_CONFIG.Enabled = Value
            _SAVE_SETTINGS()
            
            if Value then
                _UI_ANTIMODSTATUS:SetDesc('🟢Active')
                task.spawn(_ANTI_MOD_LOOP)
                _SHOW_NOTIFICATION('SYSTEM', 'Protection activated 🛡️')
            else
                _UI_ANTIMODSTATUS:SetDesc('🔴Disabled')
                _PROTECTION_MODLIST = {}
                _PROTECTION_MODCOUNT = 0
                _UPDATE_MODERATOR_UI()
                _SHOW_NOTification('SYSTEM', 'Protection disabled')
            end
        end,
    })

    local _DROPDOWN_ANTIMODACTION = _TAB_ANTIMOD:Dropdown({
        Title = 'Action on Detection',
        Desc = 'What to do when alert is detected',
        Values = {'Notify', 'Leave', 'ServerHop', 'Destruct'},
        Value = _PROTECTION_CONFIG.Action,
        Multi = false,
        Callback = function(Option)
            _PROTECTION_CONFIG.Action = Option
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('SYSTEM', 'Action set to: ' .. Option)
        end,
    })

    local _TOGGLE_ANTIMODPROXIMITY = _TAB_ANTIMOD:Toggle({
        Title = 'Proximity Alert',
        Desc = 'Warn if alert is nearby',
        Value = _PROTECTION_CONFIG.ProximityAlert,
        Callback = function(Value)
            _PROTECTION_CONFIG.ProximityAlert = Value
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('SYSTEM', Value and 'Proximity alerts enabled 📍' or 'Proximity alerts disabled')
        end,
    })

    local _BUTTON_FULLCHECK = _TAB_ANTIMOD:Button({
        Title = 'Quick Check All Players 🔄',
        Desc = 'Force check all players and show result',
        Callback = _FORCE_FULL_CHECK
    })

    if _PROTECTION_CONFIG.Enabled then
        task.spawn(_ANTI_MOD_LOOP)
    end

    local _UI_COINS = _TAB_STATISTICS:Paragraph({ Title = 'Coins', Desc = 'Loading... 💰' })

    local _UI_TIMER = _TAB_AUTOFARM:Paragraph({ Title = 'Timer', Desc = '00:00:00 ⏱' })
    local _UI_GUILTY = _TAB_AUTOFARM:Paragraph({ Title = 'Target', Desc = 'Unknown 🕵️' })
    local _UI_QUEUE = _TAB_AUTOFARM:Paragraph({ Title = 'Status', Desc = 'Waiting' })
    local _UI_AUTOFARMSTATUS = _TAB_AUTOFARM:Paragraph({ Title = 'AutoFarm Status', Desc = '🔴Disabled' })

    local _TOGGLE_AUTOFARM = _TAB_AUTOFARM:Toggle({
        Title = 'Auto Farm',
        Desc = 'Enable auto farming',
        Value = _SETTINGS_DATA.AutoFarmEnabled,
        Callback = function(Value)
            _SETTINGS_DATA.AutoFarmEnabled = Value
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('AutoFarm', Value and 'AutoFarm enabled 🎮' or 'AutoFarm disabled')
        end,
    })

    local _TOGGLE_PAUSE = _TAB_AUTOFARM:Toggle({
        Title = 'Pause Autofarm',
        Desc = 'Pause autofarm',
        Value = _SETTINGS_DATA.AutoFarmPaused,
        Callback = function(Value)
            _SETTINGS_DATA.AutoFarmPaused = Value
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('AutoFarm', Value and 'AutoFarm paused ⏸' or 'AutoFarm resumed ▶️')
        end,
    })

    local _DROPDOWN_MODE = _TAB_AUTOFARM:Dropdown({
        Title = 'Farm Mode',
        Desc = 'Choose farm mode',
        Values = {'Legit (Slow)', 'Blatant (Fast)'},
        Value = _SETTINGS_DATA.AutofarmMode,
        Multi = false,
        Callback = function(Option)
            _SETTINGS_DATA.AutofarmMode = Option
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('AutoFarm', 'Mode set to: ' .. Option)
        end,
    })

    local _DROPDOWN_MAP = _TAB_AUTOFARM:Dropdown({
        Title = 'Select Map',
        Desc = 'Choose map',
        Values = _MAP_LIST,
        Value = _SETTINGS_DATA.SelectedMap,
        Multi = false,
        Callback = function(Option)
            _SETTINGS_DATA.SelectedMap = Option
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('AutoFarm', 'Selected map: ' .. Option)
        end,
    })

    local _UI_PERFORMANCE = _TAB_UTILITIES:Paragraph({ Title = 'Performance', Desc = 'FPS: 0' })
    local _UI_BANRISK = _TAB_UTILITIES:Paragraph({ Title = 'Risk Level', Desc = 'Low' })

    local _TOGGLE_SPEED = _TAB_UTILITIES:Toggle({
        Title = 'Enable Speed',
        Desc = 'Enable/disable speed adjustment',
        Value = _SETTINGS_DATA.SpeedHackEnabled,
        Callback = function(Value)
            _SETTINGS_DATA.SpeedHackEnabled = Value
            _SAVE_SETTINGS()
            _SHOW_NOTIFICATION('Speed', Value and 'Speed enabled ⚡' or 'Speed disabled')
        end,
    })

    local _SLIDER_SPEED = _TAB_UTILITIES:Slider({
        Title = "Speed Value",
        Desc = "Character movement speed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 90,
            Default = _SETTINGS_DATA.SpeedValue or 16,
        },
        Callback = function(value)
            _SETTINGS_DATA.SpeedValue = value
            _SAVE_SETTINGS()
        end
    })

    local function _MOVE_TO_POSITION(targetPos, usePathfinding, timeout)
        timeout = timeout or 15
        if not _SYS_LOCALPLAYER or not _SYS_LOCALPLAYER.Character then 
            wait(1)
            if not _SYS_LOCALPLAYER or not _SYS_LOCALPLAYER.Character then 
                return false 
            end
        end

        local char = _SYS_LOCALPLAYER.Character
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
                local path = _SYS_PATHFINDING:CreatePath({
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

    local function _RUN_LOBBY_ROUTINE()
        if _AUTOFARM_STATE.Debounce or _SETTINGS_DATA.AutoFarmPaused then return end
        if tick() - _AUTOFARM_STATE.LastAction < 1 then return end
        _AUTOFARM_STATE.Debounce = true
        _AUTOFARM_STATE.LastAction = tick()

        if not _SYS_WORKSPACE:FindFirstChild('Lobby') then 
            _AUTOFARM_STATE.Debounce = false 
            return 
        end

        local lobby = _SYS_WORKSPACE.Lobby
        local lobbies = lobby:FindFirstChild('Lobbies')
        if not lobbies then 
            _AUTOFARM_STATE.Debounce = false 
            return 
        end

        local touches = {}
        for _, obj in ipairs(lobbies:GetDescendants()) do
            if obj.Name == 'TouchInterest' and obj.Parent and obj.Parent:IsA('BasePart') then
                table.insert(touches, obj.Parent)
            end
        end

        if #touches == 0 then 
            _AUTOFARM_STATE.Debounce = false 
            return 
        end

        local chosen = touches[math.random(1,#touches)]
        local usePath = _SETTINGS_DATA.AutofarmMode == 'Legit (Slow)'

        if _MOVE_TO_POSITION(chosen.Position, usePath, 12) then
            local hrp = _SYS_LOCALPLAYER.Character and _SYS_LOCALPLAYER.Character:FindFirstChild('HumanoidRootPart')
            if hrp and (hrp.Position - chosen.Position).Magnitude < 10 then
                if typeof(firetouchinterest) == 'function' then
                    firetouchinterest(hrp, chosen, 0); task.wait(0.08); firetouchinterest(hrp, chosen, 1)
                end
            end
            task.wait(0.5)

            if _SYS_REPLICATEDSTORAGE:FindFirstChild('Events') and _SYS_REPLICATEDSTORAGE.Events:FindFirstChild('CreateParty') then
                pcall(function()
                    _SYS_REPLICATEDSTORAGE.Events.CreateParty:FireServer(1, _SETTINGS_DATA.SelectedMap, 'Anyone')
                end)
            end
        end

        _AUTOFARM_STATE.Debounce = false
    end

    local function _RUN_AUTOFARM_ONCE()
        if _AUTOFARM_STATE.Debounce or _SETTINGS_DATA.AutoFarmPaused then return end
        if tick() - _AUTOFARM_STATE.LastAction < 1 then return end

        _AUTOFARM_STATE.Debounce = true
        _AUTOFARM_STATE.LastAction = tick()

        local mapFolder = _SYS_WORKSPACE:FindFirstChild('Map')
        local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil
        if not currentMap then 
            _AUTOFARM_STATE.Debounce = false 
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
            _AUTOFARM_STATE.Debounce = false 
            return 
        end

        local exitPrompt = exitObj:FindFirstChildOfClass('ProximityPrompt')
        local usePath = _SETTINGS_DATA.AutofarmMode == 'Legit (Slow)'

        if _MOVE_TO_POSITION(exitObj.Position, usePath, 15) then
            if exitPrompt and typeof(fireproximityprompt) == 'function' then
                for i = 1, 3 do
                    fireproximityprompt(exitPrompt, 1, false)
                    wait(0.2)
                end
            end

            wait(0.5)

            local suspect = 'Unknown'
            pcall(function()
                if _SYS_REPLICATEDSTORAGE:FindFirstChild('Values') and _SYS_REPLICATEDSTORAGE.Values:FindFirstChild('GuiltySuspect') then
                    suspect = tostring(_SYS_REPLICATEDSTORAGE.Values.GuiltySuspect.Value or 'Unknown')
                end
            end)

            pcall(function()
                if _SYS_REPLICATEDSTORAGE:FindFirstChild('Events') and _SYS_REPLICATEDSTORAGE.Events:FindFirstChild('AccuseSuspect') then
                    _SYS_REPLICATEDSTORAGE.Events.AccuseSuspect:FireServer(suspect)
                end
            end)

            _AUTOFARM_STATE.RoundHandled = true
        end

        _AUTOFARM_STATE.Debounce = false
    end

    task.spawn(function()
        while true do
            if _SETTINGS_DATA.AutoFarmEnabled and not _SETTINGS_DATA.AutoFarmPaused and not _TASK_RUNNING then
                _TASK_RUNNING = true

                pcall(function()
                    local mapFolder = _SYS_WORKSPACE:FindFirstChild('Map')
                    local currentMap = mapFolder and mapFolder:GetChildren()[1] or nil

                    if currentMap and not _AUTOFARM_STATE.RoundHandled then
                        _RUN_AUTOFARM_ONCE()
                    elseif _SYS_WORKSPACE:FindFirstChild('Lobby') then
                        _AUTOFARM_STATE.RoundHandled = false
                        _RUN_LOBBY_ROUTINE()
                    else
                        wait(2)
                    end
                end)

                _TASK_RUNNING = false
            end
            wait(0.5)
        end
    end)

    local _TARGET_SPEED = 16
    local _CURRENT_SPEED = 16
    local _LAST_HUMANOID_CHECK = 0

    local function _APPLY_TO_HUMANOID(speed)
        local char = _SYS_LOCALPLAYER and _SYS_LOCALPLAYER.Character
        if not char then return end

        local humanoid = char:FindFirstChild('Humanoid')
        if humanoid then
            humanoid.WalkSpeed = speed
        end
    end

    _SYS_LOCALPLAYER.CharacterAdded:Connect(function(character)
        wait(1)
        if _SETTINGS_DATA.SpeedHackEnabled then
            _APPLY_TO_HUMANOID(_CURRENT_SPEED)
        end
    end)

    _SYS_RUNSERVICE.Heartbeat:Connect(function(dt)
        _FRAME_COUNTER = _FRAME_COUNTER + 1
        local currentTime = tick()
        if currentTime - _LAST_FPS_UPDATE >= 1 then
            _FPS_VALUE = math.floor(_FRAME_COUNTER / (currentTime - _LAST_FPS_UPDATE))
            _FRAME_COUNTER = 0
            _LAST_FPS_UPDATE = currentTime
        end

        if tick() - _LAST_HUMANOID_CHECK > 2 then
            if _SETTINGS_DATA.SpeedHackEnabled then
                _APPLY_TO_HUMANOID(_CURRENT_SPEED)
            end
            _LAST_HUMANOID_CHECK = tick()
        end

        if _SETTINGS_DATA.SpeedHackEnabled then
            _TARGET_SPEED = _SETTINGS_DATA.SpeedValue or 16
        else
            _TARGET_SPEED = 16
        end

        _CURRENT_SPEED = _CURRENT_SPEED + (_TARGET_SPEED - _CURRENT_SPEED) * math.clamp(8 * dt, 0, 1)
        _APPLY_TO_HUMANOID(_CURRENT_SPEED)
    end)

    task.spawn(function()
        local _LAST_TIMER_UPDATE = 0
        local _LAST_STATS_UPDATE = 0

        while true do
            pcall(function()
                local currentTime = tick()
                
                if currentTime - _LAST_TIMER_UPDATE > 0.5 then
                    local elapsed = currentTime - _START_TIME
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = math.floor(elapsed % 60)
                    _UI_TIMER:SetDesc(string.format('%02d:%02d:%02d ⏱', h, m, s))
                    _LAST_TIMER_UPDATE = currentTime
                end

                if currentTime - _LAST_STATS_UPDATE > 1 then
                    local coinsAmount = "N/A"
                    
                    pcall(function()
                        local playerGui = _SYS_LOCALPLAYER:FindFirstChild("PlayerGui")
                        if playerGui then
                            local mainGui = playerGui:FindFirstChild("MainGui")
                            if mainGui then
                                local holder = mainGui:FindFirstChild("Holder")
                                if holder then
                                    local top = holder:FindFirstChild("Top")
                                    if top then
                                        local holder2 = top:FindFirstChild("Holder")
                                        if holder2 then
                                            local coins = holder2:FindFirstChild("Coins")
                                            if coins then
                                                local coinsAmountLabel = coins:FindFirstChild("Amount")
                                                if coinsAmountLabel and coinsAmountLabel:IsA("TextLabel") then
                                                    coinsAmount = coinsAmountLabel.Text
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    
                    _UI_COINS:SetDesc(coinsAmount .. ' 💰')
                    _LAST_STATS_UPDATE = currentTime
                end

                local inLobby = _SYS_WORKSPACE:FindFirstChild('Lobby') ~= nil
                local queueText = inLobby and 'In Lobby 🏠' or 'In Game 🎮'
                _UI_QUEUE:SetDesc(queueText)

                _UI_PERFORMANCE:SetDesc('FPS: ' .. tostring(_FPS_VALUE))

                local guilty = 'Unknown'
                pcall(function()
                    if _SYS_REPLICATEDSTORAGE:FindFirstChild('Values') and _SYS_REPLICATEDSTORAGE.Values:FindFirstChild('GuiltySuspect') then
                        guilty = tostring(_SYS_REPLICATEDSTORAGE.Values.GuiltySuspect.Value or 'Unknown')
                    end
                end)
                _UI_GUILTY:SetDesc(guilty .. ' 🕵️')

                local banRisk = 'Low'
                if _SETTINGS_DATA.AutoFarmEnabled and _SETTINGS_DATA.AutofarmMode == 'Blatant (Fast)' then 
                    banRisk = 'High'
                elseif _SETTINGS_DATA.AutoFarmEnabled or _SETTINGS_DATA.SpeedHackEnabled then 
                    banRisk = 'Medium' 
                end
                _UI_BANRISK:SetDesc(banRisk)

                local autofarmStatus
                if _SETTINGS_DATA.AutoFarmEnabled and not _SETTINGS_DATA.AutoFarmPaused then
                    autofarmStatus = '🟢Working'
                elseif _SETTINGS_DATA.AutoFarmEnabled and _SETTINGS_DATA.AutoFarmPaused then
                    autofarmStatus = '🟡Paused'
                else
                    autofarmStatus = '🔴Disabled'
                end
                _UI_AUTOFARMSTATUS:SetDesc(autofarmStatus)
            end)

            wait(0.1)
        end
    end)

    _SYS_WINDUI:Notify({
        Title = _APP_NAME,
        Content = "System loaded successfully! 🌟",
        Duration = 4,
        Icon = "success",
    })
end

initializeScript()
