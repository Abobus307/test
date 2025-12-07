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

    local Players = game:GetService("Players")
    local StarterGui = game:GetService("StarterGui")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local HttpService = game:GetService('HttpService')
    local Workspace = game:GetService('Workspace')
    local PathfindingService = game:GetService('PathfindingService')
    local UserInputService = game:GetService('UserInputService')
    local RunService = game:GetService('RunService')
    local TeleportService = game:GetService('TeleportService')
    local LocalPlayer = Players.LocalPlayer

    local lastLobbyTeleport = 0

    local ANTI_MOD_CONFIG = {
        Enabled = false,
        Action = "Notify",
        CheckInterval = 30,
        GroupId = 946378404,
        ModRoleIds = {490360110, 8987625, 4118621240},
        ProximityAlert = true,
        ProximityDistance = 50
    }

    local ModList = {}
    local ModCount = 0
    local LastModCheck = 0
    local AntiModRunning = false

    local function PerformAntiModAction(modName)
        local action = ANTI_MOD_CONFIG.Action
        local message = "System alert: " .. modName
        
        if WindUI then
            WindUI:Notify({
                Title = "SYSTEM",
                Content = message,
                Duration = 10,
                Icon = "alert",
            })
        else
            pcall(function()
                StarterGui:SetCore('SendNotification', {
                    Title = "SYSTEM",
                    Text = message,
                    Duration = 10,
                })
            end)
        end
        
        if action == "Leave" then
            LocalPlayer:Kick("SYSTEM: " .. modName)
        elseif action == "ServerHop" then
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        elseif action == "Destruct" then
            if WindUI then
                WindUI:Notify({
                    Title = "SYSTEM",
                    Content = "Safety protocol activated",
                    Duration = 5,
                    Icon = "alert",
                })
            else
                pcall(function()
                    StarterGui:SetCore('SendNotification', {
                        Title = "SYSTEM",
                        Text = "Safety protocol activated",
                        Duration = 5,
                    })
                end)
            end
        end
    end

    local function UpdateModeratorUI()
        if ModCountParagraph then
            ModCountParagraph:SetDesc(ModCount .. " 🚨")
        end
        
        if ModNamesParagraph then
            if ModCount > 0 then
                ModNamesParagraph:SetDesc(table.concat(ModList, ", "))
            else
                ModNamesParagraph:SetDesc("No alerts")
            end
        end
    end

    local function CheckPlayerRoles(player)
        if not ANTI_MOD_CONFIG.Enabled or not Players:GetPlayerByUserId(player.UserId) then
            return false
        end

        local success, roles = pcall(function()
            return Players:GetRolesInGroupAsync(player.UserId, ANTI_MOD_CONFIG.GroupId)
        end)

        if success and roles then
            local isModerator = false
            
            for _, roleId in ipairs(roles) do
                for _, modRoleId in ipairs(ANTI_MOD_CONFIG.ModRoleIds) do
                    if roleId == modRoleId then
                        isModerator = true
                        break
                    end
                end
                if isModerator then
                    break
                end
            end

            if isModerator and not table.find(ModList, player.Name) then
                table.insert(ModList, player.Name)
                ModCount = ModCount + 1
                UpdateModeratorUI()
                PerformAntiModAction(player.Name)
                return true
            end
        end
        return false
    end

    local function MonitorModProximity()
        if not ANTI_MOD_CONFIG.Enabled or not ANTI_MOD_CONFIG.ProximityAlert or ModCount == 0 then
            return
        end

        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            return
        end

        local playerPos = character.HumanoidRootPart.Position
        
        for _, player in ipairs(Players:GetPlayers()) do
            if table.find(ModList, player.Name) and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local modPos = player.Character.HumanoidRootPart.Position
                local distance = (playerPos - modPos).Magnitude
                
                if distance <= ANTI_MOD_CONFIG.ProximityDistance then
                    if WindUI then
                        WindUI:Notify({
                            Title = "WARNING",
                            Content = "Alert: " .. player.Name .. " proximity! " .. math.floor(distance) .. " units",
                            Duration = 5,
                            Icon = "alert",
                        })
                    else
                        pcall(function()
                            StarterGui:SetCore('SendNotification', {
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

    local function AntiModLoop()
        if AntiModRunning or not ANTI_MOD_CONFIG.Enabled then
            return
        end

        AntiModRunning = true
        
        while ANTI_MOD_CONFIG.Enabled do
            local currentTime = tick()
            
            if currentTime - LastModCheck >= ANTI_MOD_CONFIG.CheckInterval then
                ModList = {}
                ModCount = 0
                
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        CheckPlayerRoles(player)
                        task.wait(0.3)
                    end
                end
                
                LastModCheck = currentTime
                UpdateModeratorUI()
            end
            
            MonitorModProximity()
            task.wait(5)
        end
        
        AntiModRunning = false
    end

    local function ForceFullCheck()
        if not ANTI_MOD_CONFIG.Enabled then
            if WindUI then
                WindUI:Notify({
                    Title = "SYSTEM",
                    Content = "Enable protection first",
                    Duration = 3,
                    Icon = "info",
                })
            else
                pcall(function()
                    StarterGui:SetCore('SendNotification', {
                        Title = "SYSTEM",
                        Text = "Enable protection first",
                        Duration = 3,
                    })
                end)
            end
            return
        end
        
        local originalModCount = ModCount
        ModList = {}
        ModCount = 0
        
        if WindUI then
            WindUI:Notify({
                Title = "SYSTEM",
                Content = "Scanning all players...",
                Duration = 2,
                Icon = "search",
            })
        else
            pcall(function()
                StarterGui:SetCore('SendNotification', {
                    Title = "SYSTEM",
                    Text = "Scanning all players...",
                    Duration = 2,
                })
            end)
        end
        
        local foundModerators = {}
        
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local isMod = CheckPlayerRoles(player)
                if isMod then
                    table.insert(foundModerators, player.Name)
                end
                task.wait(0.2)
            end
        end
        
        LastModCheck = 0
        UpdateModeratorUI()
        
        if #foundModerators > 0 then
            if WindUI then
                WindUI:Notify({
                    Title = "SCAN RESULT",
                    Content = "🚨 DETECTED " .. #foundModerators .. " ALERTS: " .. table.concat(foundModerators, ", "),
                    Duration = 8,
                    Icon = "alert",
                })
            else
                pcall(function()
                    StarterGui:SetCore('SendNotification', {
                        Title = "SCAN RESULT",
                        Text = "🚨 DETECTED " .. #foundModerators .. " ALERTS: " .. table.concat(foundModerators, ", "),
                        Duration = 8,
                    })
                end)
            end
        else
            if WindUI then
                WindUI:Notify({
                    Title = "SCAN RESULT",
                    Content = "✅ NO ALERTS FOUND - System normal",
                    Duration = 5,
                    Icon = "success",
                })
            else
                pcall(function()
                    StarterGui:SetCore('SendNotification', {
                        Title = "SCAN RESULT",
                        Text = "✅ NO ALERTS FOUND - System normal",
                        Duration = 5,
                    })
                end)
            end
        end
    end

    Players.PlayerRemoving:Connect(function(player)
        if table.find(ModList, player.Name) then
            local index = table.find(ModList, player.Name)
            table.remove(ModList, index)
            ModCount = ModCount - 1
            UpdateModeratorUI()
        end
    end)

    local DEBUG = false
    local debounce = false

    local function dbg(...)
        if DEBUG then print("[SYSTEM] ", ...) end
    end

    local function fastFindMenuGui()
        local mg = StarterGui:FindFirstChild("MenuGui")
        if mg then return mg end
        if LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui") then
            return LocalPlayer.PlayerGui:FindFirstChild("MenuGui")
        end
        return nil
    end

    local function collectPlayButtons(menuGui)
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

    local function tryActivateButton(btn)
        if not btn or not btn:IsA("TextButton") then return false end

        if pcall(function() btn:Activate() end) then
            dbg("Activated:", btn:GetFullName())
            return true
        end

        if btn:FindFirstChild("MouseButton1Click") and typeof(btn.MouseButton1Click.Fire) == "function" then
            if pcall(function() btn.MouseButton1Click:Fire() end) then
                dbg("MouseButton1Click fired for", btn:GetFullName())
                return true
            end
        end

        if btn:FindFirstChild("MouseButton1Down") and btn:FindFirstChild("MouseButton1Up") then
            if pcall(function()
                btn.MouseButton1Down:Fire()
                task.wait(0.06)
                btn.MouseButton1Up:Fire()
            end) then
                dbg("Down/Up fired for", btn:GetFullName())
                return true
            end
        end

        return false
    end

    local likelyRemotes = {
        "Play",
        "PlaySound",
        "PlayerLoaded",
        "DisplayChatMessage",
        "PressedPlayButton",
        "OpenDailyRewardsMenu",
        "Roblox_PlayHalloweenSuspectAnimation"
    }

    local function fireNamedRemotes()
        local eventsFolder = ReplicatedStorage:FindFirstChild("Events")
        local firedAny = false

        local function tryFire(obj)
            if not obj then return false end
            if obj:IsA("RemoteEvent") then
                local ok = pcall(function() obj:FireServer() end)
                if ok then
                    dbg("Fired RemoteEvent:", obj:GetFullName())
                    return true
                else
                    dbg("Failed to fire (RemoteEvent):", obj:GetFullName())
                end
            elseif obj:IsA("RemoteFunction") then
                local ok = pcall(function() obj:InvokeServer() end)
                if ok then
                    dbg("Invoked RemoteFunction:", obj:GetFullName())
                    return true
                else
                    dbg("Failed to invoke (RemoteFunction):", obj:GetFullName())
                end
            end
            return false
        end

        if eventsFolder then
            for _, name in ipairs(likelyRemotes) do
                local r = eventsFolder:FindFirstChild(name)
                if r and tryFire(r) then
                    firedAny = true
                end
            end
        end

        for _, name in ipairs(likelyRemotes) do
            if not firedAny then
                local rTop = ReplicatedStorage:FindFirstChild(name)
                if rTop and tryFire(rTop) then
                    firedAny = true
                end
            else
            end
        end

        return firedAny
    end

    local function ultimateClickPlayFast()
        if debounce then
            dbg("debounce active, exit")
            return false
        end
        debounce = true

        task.wait(0.8)

        local menuGui = fastFindMenuGui()
        if not menuGui then
            warn("MenuGui not found")
            debounce = false
            return false
        end

        local playButtons = collectPlayButtons(menuGui)

        if #playButtons > 0 then
            dbg("Found play buttons:", #playButtons)
            for _, pbtn in ipairs(playButtons) do
                dbg("Trying to activate:", pbtn.name)
                if tryActivateButton(pbtn.button) then
                    task.wait(0.45)
                    if not fastFindMenuGui() then
                        dbg("Menu closed after pressing button:", pbtn.name)
                        debounce = false
                        return true
                    end
                end
            end
        else
            dbg("No Play buttons found in MenuGui")
        end

        dbg("Trying to call target remotes from ReplicatedStorage.Events")
        local remotesFired = fireNamedRemotes()
        task.wait(0.6)

        if remotesFired and not fastFindMenuGui() then
            dbg("Menu closed after firing remotes")
            debounce = false
            return true
        end

        dbg("Retrying to activate buttons as fallback")
        for _, pbtn in ipairs(playButtons) do
            if tryActivateButton(pbtn.button) then
                task.wait(0.45)
                if not fastFindMenuGui() then
                    dbg("Menu closed on retry:", pbtn.name)
                    debounce = false
                    return true
                end
            end
        end

        dbg("Nothing closed the menu")
        debounce = false
        return false
    end

    ultimateClickPlayFast()
    task.wait(1)

    local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

    local MAPS = {'Motel Room', 'Humble Abode', 'Bathroom', 'Moolah Manor', 'Gas Station', 'Abandoned Apartment', "Santa's Workshop"}
    local NAME = "CoolMan2"
    local SETTINGS_FILE = "CoolMan2_Settings.json"

    local SETTINGS = {
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
                    return true
                end)
                return success
            end
        end
        return false
    end

    LoadSettings()

    ANTI_MOD_CONFIG.Enabled = SETTINGS.AntiModEnabled
    ANTI_MOD_CONFIG.Action = SETTINGS.AntiModAction
    ANTI_MOD_CONFIG.ProximityAlert = SETTINGS.AntiModProximityAlert

    local AutoState = { Debounce = false, LastAction = 0, RoundHandled = false }
    local TaskRunning = false
    local FPS = 0
    local frameCount = 0
    local lastFpsUpdate = tick()
    local startTime = tick()

    local function Notify(title, text, duration)
        if WindUI then
            WindUI:Notify({
                Title = title or NAME,
                Content = text or '',
                Duration = duration or 3,
                Icon = "info",
            })
        else
            pcall(function()
                StarterGui:SetCore('SendNotification', {
                    Title = title or NAME,
                    Text = text or '',
                    Duration = duration or 3,
                })
            end)
        end
    end

    local function SaveSettings()
        if writefile then
            pcall(function()
                SETTINGS.AntiModEnabled = ANTI_MOD_CONFIG.Enabled
                SETTINGS.AntiModAction = ANTI_MOD_CONFIG.Action
                SETTINGS.AntiModProximityAlert = ANTI_MOD_CONFIG.ProximityAlert
                
                local data = HttpService:JSONEncode(SETTINGS)
                writefile(SETTINGS_FILE, data)
            end)
        end
    end

    local Window = WindUI:CreateWindow({
        Title = NAME .. ' - Armless Detective',
        Author = 'by CoolMan2',
        Folder = 'CoolMan2',
        Theme = "Dark",
        Transparent = true,
    })

    local AutofarmTab = Window:Tab({ Title = 'Autofarm 🎮' })
    local AntiModTab = Window:Tab({ Title = 'Anti-Mod 🛡️' })
    local UtilitiesTab = Window:Tab({ Title = 'Utilities 🛠' })
    local StatisticsTab = Window:Tab({ Title = 'Statistics 📊' })

    local ReturnToLobbyButton = UtilitiesTab:Button({
        Title = 'Return to Lobby 🔄',
        Desc = 'Teleport to lobby',
        Callback = function()
            local currentTime = tick()
            local cooldownRemaining = 3 - (currentTime - lastLobbyTeleport)
            
            if cooldownRemaining > 0 then
                WindUI:Notify({
                    Title = "Cooldown",
                    Content = "Please wait " .. math.ceil(cooldownRemaining) .. " seconds",
                    Duration = 2,
                    Icon = "info",
                })
                return
            end
            
            lastLobbyTeleport = currentTime
            
            WindUI:Notify({
                Title = "Teleporting",
                Content = "Returning to lobby...",
                Duration = 2,
                Icon = "info",
            })
            
            pcall(function()
                TeleportService:Teleport(97719631053849, LocalPlayer)
            end)
        end,
    })

    local AntiModWarningParagraph = AntiModTab:Paragraph({ 
        Title = '⚠️ BETA TESTING', 
        Desc = 'This feature is in testing phase. Bugs may occur!' 
    })

    local ModCountParagraph = AntiModTab:Paragraph({ Title = 'Moderators Online', Desc = '0 🚨' })
    local ModNamesParagraph = AntiModTab:Paragraph({ Title = 'Moderator List', Desc = 'No alerts' })
    
    local initialAntiModStatus = ANTI_MOD_CONFIG.Enabled and '🟢Active' or '🔴Disabled'
    local AntiModStatusParagraph = AntiModTab:Paragraph({ Title = 'System Status', Desc = initialAntiModStatus })

    local AntiModToggle = AntiModTab:Toggle({
        Title = 'Protection System',
        Desc = 'Enable security protection',
        Value = ANTI_MOD_CONFIG.Enabled,
        Callback = function(Value)
            ANTI_MOD_CONFIG.Enabled = Value
            SaveSettings()
            
            if Value then
                AntiModStatusParagraph:SetDesc('🟢Active')
                task.spawn(AntiModLoop)
                Notify('SYSTEM', 'Protection activated 🛡️')
            else
                AntiModStatusParagraph:SetDesc('🔴Disabled')
                ModList = {}
                ModCount = 0
                UpdateModeratorUI()
                Notify('SYSTEM', 'Protection disabled')
            end
        end,
    })

    local AntiModActionDropdown = AntiModTab:Dropdown({
        Title = 'Action on Detection',
        Desc = 'What to do when alert is detected',
        Values = {'Notify', 'Leave', 'ServerHop', 'Destruct'},
        Value = ANTI_MOD_CONFIG.Action,
        Multi = false,
        Callback = function(Option)
            ANTI_MOD_CONFIG.Action = Option
            SaveSettings()
            Notify('SYSTEM', 'Action set to: ' .. Option)
        end,
    })

    local AntiModProximityToggle = AntiModTab:Toggle({
        Title = 'Proximity Alert',
        Desc = 'Warn if alert is nearby',
        Value = ANTI_MOD_CONFIG.ProximityAlert,
        Callback = function(Value)
            ANTI_MOD_CONFIG.ProximityAlert = Value
            SaveSettings()
            Notify('SYSTEM', Value and 'Proximity alerts enabled 📍' or 'Proximity alerts disabled')
        end,
    })

    local ForceFullCheckButton = AntiModTab:Button({
        Title = 'Quick Check All Players 🔄',
        Desc = 'Force check all players and show result',
        Callback = ForceFullCheck
    })

    if ANTI_MOD_CONFIG.Enabled then
        task.spawn(AntiModLoop)
    end

    local CoinsParagraph = StatisticsTab:Paragraph({ Title = 'Coins', Desc = 'Loading... 💰' })
    local SnowflakesParagraph = StatisticsTab:Paragraph({ Title = 'Snowflakes', Desc = 'Loading... ❄️' })

    local TimerParagraph = AutofarmTab:Paragraph({ Title = 'Timer', Desc = '00:00:00 ⏱' })
    local GuiltyParagraph = AutofarmTab:Paragraph({ Title = 'Target', Desc = 'Unknown 🕵️' })
    local QueueParagraph = AutofarmTab:Paragraph({ Title = 'Status', Desc = 'Waiting' })
    local AutofarmStatusParagraph = AutofarmTab:Paragraph({ Title = 'AutoFarm Status', Desc = '🔴Disabled' })

    local AutoFarmToggle = AutofarmTab:Toggle({
        Title = 'Auto Farm',
        Desc = 'Enable auto farming',
        Value = SETTINGS.AutoFarmEnabled,
        Callback = function(Value)
            SETTINGS.AutoFarmEnabled = Value
            SaveSettings()
            Notify('AutoFarm', Value and 'AutoFarm enabled 🎮' or 'AutoFarm disabled')
        end,
    })

    local PauseToggle = AutofarmTab:Toggle({
        Title = 'Pause Autofarm',
        Desc = 'Pause autofarm',
        Value = SETTINGS.AutoFarmPaused,
        Callback = function(Value)
            SETTINGS.AutoFarmPaused = Value
            SaveSettings()
            Notify('AutoFarm', Value and 'AutoFarm paused ⏸' or 'AutoFarm resumed ▶️')
        end,
    })

    local ModeDropdown = AutofarmTab:Dropdown({
        Title = 'Farm Mode',
        Desc = 'Choose farm mode',
        Values = {'Legit (Slow)', 'Blatant (Fast)'},
        Value = SETTINGS.AutofarmMode,
        Multi = false,
        Callback = function(Option)
            SETTINGS.AutofarmMode = Option
            SaveSettings()
            Notify('AutoFarm', 'Mode set to: ' .. Option)
        end,
    })

    local MapDropdown = AutofarmTab:Dropdown({
        Title = 'Select Map',
        Desc = 'Choose map',
        Values = MAPS,
        Value = SETTINGS.SelectedMap,
        Multi = false,
        Callback = function(Option)
            SETTINGS.SelectedMap = Option
            SaveSettings()
            Notify('AutoFarm', 'Selected map: ' .. Option)
        end,
    })

    local PerformanceParagraph = UtilitiesTab:Paragraph({ Title = 'Performance', Desc = 'FPS: 0' })
    local BanRiskParagraph = UtilitiesTab:Paragraph({ Title = 'Risk Level', Desc = 'Low' })

    local SpeedToggle = UtilitiesTab:Toggle({
        Title = 'Enable Speed',
        Desc = 'Enable/disable speed adjustment',
        Value = SETTINGS.SpeedHackEnabled,
        Callback = function(Value)
            SETTINGS.SpeedHackEnabled = Value
            SaveSettings()
            Notify('Speed', Value and 'Speed enabled ⚡' or 'Speed disabled')
        end,
    })

    local SpeedSlider = UtilitiesTab:Slider({
        Title = "Speed Value",
        Desc = "Character movement speed",
        Step = 1,
        Value = {
            Min = 16,
            Max = 90,
            Default = SETTINGS.SpeedValue or 16,
        },
        Callback = function(value)
            SETTINGS.SpeedValue = value
            SaveSettings()
        end
    })

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
        local usePath = SETTINGS.AutofarmMode == 'Legit (Slow)'

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
        local usePath = SETTINGS.AutofarmMode == 'Legit (Slow)'

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
        frameCount = frameCount + 1
        local currentTime = tick()
        if currentTime - lastFpsUpdate >= 1 then
            FPS = math.floor(frameCount / (currentTime - lastFpsUpdate))
            frameCount = 0
            lastFpsUpdate = currentTime
        end

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

    task.spawn(function()
        local lastTimerUpdate = 0
        local lastStatsUpdate = 0

        while true do
            pcall(function()
                local currentTime = tick()
                
                if currentTime - lastTimerUpdate > 0.5 then
                    local elapsed = currentTime - startTime
                    local h = math.floor(elapsed / 3600)
                    local m = math.floor((elapsed % 3600) / 60)
                    local s = math.floor(elapsed % 60)
                    TimerParagraph:SetDesc(string.format('%02d:%02d:%02d ⏱', h, m, s))
                    lastTimerUpdate = currentTime
                end

                if currentTime - lastStatsUpdate > 1 then
                    local coinsAmount = "N/A"
                    local snowflakesAmount = "N/A"
                    
                    pcall(function()
                        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
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
                                            
                                            local snowflakes = holder2:FindFirstChild("Snowflakes")
                                            if snowflakes then
                                                local snowflakesAmountLabel = snowflakes:FindFirstChild("Amount")
                                                if snowflakesAmountLabel and snowflakesAmountLabel:IsA("TextLabel") then
                                                    snowflakesAmount = snowflakesAmountLabel.Text
                                                end
                                            else
                                                for _, child in pairs(holder2:GetChildren()) do
                                                    if string.find(child.Name:lower(), "snow") or string.find(child.Name:lower(), "flake") then
                                                        local amountLabel = child:FindFirstChild("Amount")
                                                        if amountLabel and amountLabel:IsA("TextLabel") then
                                                            snowflakesAmount = amountLabel.Text
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                    
                    CoinsParagraph:SetDesc(coinsAmount .. ' 💰')
                    SnowflakesParagraph:SetDesc(snowflakesAmount .. ' ❄️')
                    lastStatsUpdate = currentTime
                end

                local inLobby = Workspace:FindFirstChild('Lobby') ~= nil
                local queueText = inLobby and 'In Lobby 🏠' or 'In Game 🎮'
                QueueParagraph:SetDesc(queueText)

                PerformanceParagraph:SetDesc('FPS: ' .. tostring(FPS))

                local guilty = 'Unknown'
                pcall(function()
                    if ReplicatedStorage:FindFirstChild('Values') and ReplicatedStorage.Values:FindFirstChild('GuiltySuspect') then
                        guilty = tostring(ReplicatedStorage.Values.GuiltySuspect.Value or 'Unknown')
                    end
                end)
                GuiltyParagraph:SetDesc(guilty .. ' 🕵️')

                local banRisk = 'Low'
                if SETTINGS.AutoFarmEnabled and SETTINGS.AutofarmMode == 'Blatant (Fast)' then 
                    banRisk = 'High'
                elseif SETTINGS.AutoFarmEnabled or SETTINGS.SpeedHackEnabled then 
                    banRisk = 'Medium' 
                end
                BanRiskParagraph:SetDesc(banRisk)

                local autofarmStatus
                if SETTINGS.AutoFarmEnabled and not SETTINGS.AutoFarmPaused then
                    autofarmStatus = '🟢Working'
                elseif SETTINGS.AutoFarmEnabled and SETTINGS.AutoFarmPaused then
                    autofarmStatus = '🟡Paused'
                else
                    autofarmStatus = '🔴Disabled'
                end
                AutofarmStatusParagraph:SetDesc(autofarmStatus)
            end)

            wait(0.1)
        end
    end)

    WindUI:Notify({
        Title = NAME,
        Content = "System loaded successfully! 🌟",
        Duration = 4,
        Icon = "success",
    })
end

initializeScript()
