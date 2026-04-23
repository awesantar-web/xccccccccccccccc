    --[[
        AJ ELITE PREMIUM - Ultra High Fidelity Overlay
        Glassmorphism | Neon Accents | OBS-Proof
        Toggle: PAGE UP (0x21)
    ]]

    Susano.ResetAllFrames()
    Susano.ResetFrame()

    local visible = false
    local currentTab = 1
    local selectedIndex = 1
    local selectedPlayer = nil
    local inPlayerOptions = false
    local rainbowOffset = 0
    local notifications = {}

    local function pushNotif(title, text, isErr)
        table.insert(notifications, { title = title, text = text, isErr = isErr, time = GetGameTimer() + 3500 })
    end

    local ui = {
        x = 150, y = 150, w = 550,
        headerH = 80, tabH = 45, rowH = 40, footerH = 35,
        colors = {
            bg = {0.05, 0.05, 0.06, 0.95}, -- Dark Charcoal glass
            border = {0.8, 0.1, 0.1, 0.5}, -- Dark Crimson border
            accent1 = {0.9, 0.1, 0.15, 1.0}, -- Vibrant Crimson
            accent2 = {0.8, 0.05, 0.1, 1.0}, -- Deep Crimson
            text = {0.95, 0.95, 0.95, 1.0},
            textDim = {0.6, 0.6, 0.6, 1.0},
            success = {0.9, 0.1, 0.15, 1.0},
            danger = {0.9, 0.2, 0.3, 1.0}
        }
    }

    local tabs = {"SELF", "PLAYERS", "TROLLS", "VEHICLE", "EXPLOITS", "SYSTEM"}
    local menu = {}
    local carRain = false
    local espEnabled = false
    local isBeingCarried = false

    -- [[ DYNAMIC COLORS ]]
    local function getRainbow()
        rainbowOffset = rainbowOffset + 0.005
        local r = math.abs(math.sin(rainbowOffset))
        local g = math.abs(math.sin(rainbowOffset + 2))
        local b = math.abs(math.sin(rainbowOffset + 4))
        return {r, g, b, 1.0}
    end

    -- [[ EVENT LOGGER DETOUR ]]
    local eventLoggerEnabled = false
    local _TriggerServerEvent = TriggerServerEvent
    TriggerServerEvent = function(eventName, ...)
        if eventLoggerEnabled then
            print("[AJ ELITE LOGGER] Caught Event: " .. tostring(eventName))
            local args = {...}
            for i, arg in ipairs(args) do
                print("  -> Arg["..i.."]: " .. tostring(arg))
            end
        end
        _TriggerServerEvent(eventName, ...)
    end

    -- [[ ACTIONS ]]
    local function killPlayer(id) local ped = GetPlayerPed(id); if DoesEntityExist(ped) then SetEntityHealth(ped, 0) end end
    local function tazePlayer(id) local ped = GetPlayerPed(id); if DoesEntityExist(ped) then SetPedToRagdoll(ped, 5000, 5000, 0, 0, 0, 0) end end



    -- [[ HELPER: REQUEST CONTROL ]]
    local function requestControl(entity)
        if not DoesEntityExist(entity) then return false end
        local timeout = GetGameTimer() + 2000
        while not NetworkHasControlOfEntity(entity) and GetGameTimer() < timeout do
            NetworkRequestControlOfEntity(entity)
            Wait(50)
        end
        return NetworkHasControlOfEntity(entity)
    end





    local function weaponKill(id)
        local targetPed = GetPlayerPed(id)
        if not DoesEntityExist(targetPed) then return end
        
        local c = GetEntityCoords(targetPed)
        -- Hash: 0x1B06D571 (WEAPON_PISTOL)
        -- Precision headshot injection
        ShootSingleBulletBetweenCoords(
            c.x, c.y, c.z + 0.9, -- Spawns right above head
            c.x, c.y, c.z + 0.8, -- Impacts the head
            1000, true, 0x1B06D571, PlayerPedId(), false, false, 1000.0
        )
    end

    local function dropCarOnPlayer(id)
        local targetPed = GetPlayerPed(id)
        if not DoesEntityExist(targetPed) then return end

        local model = GetHashKey("jugular")
        Citizen.CreateThread(function()
            RequestModel(model)
            local timeout = 0
            while not HasModelLoaded(model) and timeout < 1000 do
                Wait(10)
                timeout = timeout + 10
            end
            if HasModelLoaded(model) then
                local c = GetEntityCoords(targetPed)
                -- Spawn car 15 units above their head
                local car = CreateVehicle(model, c.x, c.y, c.z + 15.0, 0.0, true, false)
                SetEntityInvincible(car, true)
                SetEntityVelocity(car, 0.0, 0.0, -40.0)
                SetEntityAsNoLongerNeeded(car)
            end
        end)
    end

    local function trapPlayer(id)
        local targetPed = GetPlayerPed(id)
        if not DoesEntityExist(targetPed) then return end

        Citizen.CreateThread(function()
            local propModel = GetHashKey("prop_container_ld_pu")
            if not IsModelInCdimage(propModel) then return end
            RequestModel(propModel)
            while not HasModelLoaded(propModel) do Wait(50) end

            local coords = GetEntityCoords(targetPed)
            local prop = CreateObject(propModel, coords.x, coords.y, coords.z - 1.0, true, true, false)
            FreezeEntityPosition(prop, true)
            SetModelAsNoLongerNeeded(propModel)
        end)
    end

    local function burstPlayerTires(id)
        local targetPed = GetPlayerPed(id)
        if not DoesEntityExist(targetPed) then return end
        
        local vehicle = GetVehiclePedIsIn(targetPed, false)
        if vehicle and vehicle ~= 0 then
            for i = 0, 7 do
                SetVehicleTyreBurst(vehicle, i, true, 1000.0)
            end
            pushNotif("Success", "Blew out tires on target's vehicle.", false)
        else
            pushNotif("Error", "Target is not in a vehicle!", true)
        end
    end

    local function forceDance(id)
        local targetPed = GetPlayerPed(id)
        if DoesEntityExist(targetPed) then
            Citizen.CreateThread(function()
                local dict = "missfbi3_snitch"
                local anim = "dance_low_loop_f"
                RequestAnimDict(dict)
                while not HasAnimDictLoaded(dict) do Wait(10) end
                
                requestControl(targetPed)
                TaskPlayAnim(targetPed, dict, anim, 8.0, -8.0, -1, 1, 0, false, false, false)
                pushNotif("Exploit", "Target is now dancing.", false)
            end)
        end
    end

    local function teleportToPlayer(id)
        local targetPed = GetPlayerPed(id)
        if DoesEntityExist(targetPed) then
            local coords = GetEntityCoords(targetPed)
            local myPed = PlayerPedId()
            SetEntityCoords(myPed, coords.x, coords.y, coords.z, false, false, false, false)
            pushNotif("Success", "Teleported to target.", false)
        end
    end
    
    -- [[ NOCLIP ENGINE ]]
    local noclipEnabled = false
    local noclipCam = nil

    local function toggleNoclip(v)
        noclipEnabled = v
        local ped = PlayerPedId()
        
        if noclipEnabled then
            local coords = GetEntityCoords(ped)
            noclipCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamCoord(noclipCam, coords.x, coords.y, coords.z)
            SetCamRot(noclipCam, 0.0, 0.0, GetEntityHeading(ped), 2)
            RenderScriptCams(true, false, 0, true, true)
            SetEntityVisible(ped, false, false)
            SetEntityCollision(ped, false, false)
            FreezeEntityPosition(ped, true)
        else
            RenderScriptCams(false, false, 0, true, true)
            if noclipCam then DestroyCam(noclipCam, false); noclipCam = nil end
            SetEntityVisible(ped, true, false)
            SetEntityCollision(ped, true, true)
            FreezeEntityPosition(ped, false)
        end
    end

    local function refreshPlayers()
        if inPlayerOptions and selectedPlayer then
            menu[2] = {
                { label = "< BACK TO LIST", type = "button", onClick = function() inPlayerOptions = false; refreshPlayers() end },
                { label = "Teleport to Player", type = "button", onClick = function() teleportToPlayer(selectedPlayer.id) end },
                { label = "Spectate Player", type = "toggle", value = false, onToggle = function(v) NetworkSetInSpectatorMode(v, GetPlayerPed(selectedPlayer.id)) end },
                { label = "Silent Weapon Kill", type = "button", onClick = function() weaponKill(selectedPlayer.id) end },
                { label = "Force Dance", type = "button", onClick = function() forceDance(selectedPlayer.id) end },
                { label = "Drop Car on Player", type = "button", onClick = function() dropCarOnPlayer(selectedPlayer.id) end },
                { label = "Trap Player", type = "button", onClick = function() trapPlayer(selectedPlayer.id) end },
                { label = "Blame Carry", type = "toggle", value = false, onToggle = function(v)
                    local p = PlayerPedId()
                    local t = GetPlayerPed(selectedPlayer.id)
                    if v then
                        Citizen.CreateThread(function()
                            RequestAnimDict("missfinale_c2mcs_1")
                            RequestAnimDict("nm")
                            while not HasAnimDictLoaded("missfinale_c2mcs_1") or not HasAnimDictLoaded("nm") do Wait(10) end
                            
                            if DoesEntityExist(t) then
                                requestControl(t)
                                TaskPlayAnim(t, "missfinale_c2mcs_1", "fin_c2_mcs_1_camman", 8.0, -8.0, -1, 49, 0, 0, 0, 0)
                                TaskPlayAnim(p, "nm", "firemans_carry", 8.0, -8.0, -1, 33, 0, 0, 0, 0)
                                AttachEntityToEntity(p, t, 0, 0.27, 0.15, 0.63, 0.5, 0.5, 0.0, false, false, false, false, 2, false)
                            end
                        end)
                    else
                        requestControl(t)
                        DetachEntity(p, true, false)
                        ClearPedTasksImmediately(p)
                        if DoesEntityExist(t) then ClearPedTasksImmediately(t) end
                    end
                end },
            }
        else
            local pList = { { label = "Refresh Scanner", type = "button", onClick = function() refreshPlayers() end } }
            for _, id in ipairs(GetActivePlayers()) do
                local name = GetPlayerName(id)
                table.insert(pList, { label = " " .. name .. " [ID: " .. id .. "]", type = "button", onClick = function() 
                    selectedPlayer = { id = id, name = name }; 
                    inPlayerOptions = true; 
                    refreshPlayers(); 
                    selectedIndex = 1 
                end })
            end
            menu[2] = pList
        end
    end

    local function buildMenu()
        menu[1] = { -- Self
            { label = "Smooth Noclip / Freecam", type = "toggle", value = false, onToggle = function(v) toggleNoclip(v) end },
            { label = "Godmode (Invisible to Server)", type = "toggle", value = false, onToggle = function(v) SetPlayerInvincible(PlayerId(), v) end },
            { label = "Super Jump", type = "toggle", value = false, onToggle = function(v) end }, -- Logic handled in loop
            { label = "Max Health", type = "button", onClick = function() SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId())) end },
            { label = "Max Armor", type = "button", onClick = function() SetPedArmour(PlayerPedId(), 100) end },
            { label = "No Ragdoll", type = "toggle", value = false, onToggle = function(v) SetPedCanRagdoll(PlayerPedId(), not v) end },
            { label = "ESX: Revive", type = "button", onClick = function() TriggerEvent('esx_ambulancejob:revive') end },
            { label = "ESX: Max Needs", type = "button", onClick = function() 
                TriggerEvent('esx_status:add', 'hunger', 1000000)
                TriggerEvent('esx_status:add', 'thirst', 1000000)
                TriggerEvent('esx_status:remove', 'stress', 500000)
            end },
        }
        refreshPlayers()
        menu[3] = { -- Trolls
            { label = "Silent Kill All", type = "button", onClick = function() 
                for _, player in ipairs(GetActivePlayers()) do 
                    if player ~= PlayerId() then 
                        weaponKill(player)
                        Wait(10)
                    end
                end
            end },
            { label = "Jugular Rain (Lethal)", type = "toggle", value = carRain, onToggle = function(v) carRain = v end },
        }
        menu[4] = { -- Vehicle
            { label = "Repair & Wash", type = "button", onClick = function() 
                local v = GetVehiclePedIsIn(PlayerPedId(), false)
                if v ~= 0 then SetVehicleFixed(v); SetVehicleDirtLevel(v, 0.0) end
            end },
            { label = "Infinite Nitro", type = "toggle", value = false },
            { label = "Engine Power x10", type = "toggle", value = false },
        }
        menu[5] = { -- Exploits
            { label = "Advanced Event Logger", type = "toggle", value = false, onToggle = function(v) eventLoggerEnabled = v end },
            { label = "RUN MASTER EVENT SCAN", type = "button", onClick = function()
                print("^4--- MASTER EVENT SCAN STARTED ---^7")
                local totalHits = 0
                
                -- 1. Framework Substring Scans
                for _, framework in ipairs({"esx_", "cfx-hu-", "qb-"}) do
                    local hits = Susano.FindEvent(framework)
                    totalHits = totalHits + #hits
                    for _, ev in ipairs(hits) do
                        print("^2[SCAN]^7 Found " .. framework:upper() .. " Event: ^5" .. ev.resource .. "^7 | ^3" .. ev.event .. "^7")
                    end
                end
                
                -- 2. Critical Admin Match Scan (Direct Exact Matches)
                local targets = {
                    "esx:setJob", "esx:setGang", "esx_admin:setGroup", "esx:giveInventoryItem", "esx_policejob:handcuff", 
                    "cfx-hu-police:requestarrest", 
                }
                local adminHits = 0
                for _, target in ipairs(targets) do
                    local hits = Susano.FindEvent(target, true)
                    if #hits > 0 then
                        adminHits = adminHits + 1
                        for _, ev in ipairs(hits) do
                            print("^1[CRITICAL]^7 Admin Trigger Found: ^5" .. ev.resource .. "^7 | ^3" .. ev.event .. "^7")
                        end
                    end
                end
                
                pushNotif("Scanner", "Scan Complete. Total Hits: " .. totalHits .. " | Admin: " .. adminHits, false)
                print("^4--- MASTER SCAN COMPLETE ---^7")
            end },
        }
        menu[6] = { -- System
            { label = "Rainbow Accent", type = "toggle", value = false },
            { label = "Self Destruct", type = "button", onClick = function() visible = false; Susano.ResetFrame() end },
        }
    end

    buildMenu()

    -- [[ DRAWING UTILS ]]
    local function drawToggle(x, y, active)
        local w, h = 35, 18
        local bg = active and ui.colors.accent2 or {0.1, 0.1, 0.1, 1.0}
        Susano.DrawRectFilled(x, y + 8, w, h, bg[1], bg[2], bg[3], 1.0, 9)
        local dotX = active and (x + w - 15) or (x + 3)
        Susano.DrawRectFilled(dotX, y + 10, 12, 14, 1, 1, 1, 1.0, 7)
    end

    local function drawNotifs()
        local cTime = GetGameTimer()
        local sw, sh = GetActiveScreenResolution()
        local ny = sh - 120 -- Start near the bottom center
        for i = #notifications, 1, -1 do
            local n = notifications[i]
            if cTime > n.time then
                table.remove(notifications, i)
            else
                local tw1 = Susano.GetTextWidth(n.title, 14) or 100
                local tw2 = Susano.GetTextWidth(n.text, 12) or 100
                local tw = math.max(tw1, tw2)
                
                local boxW = tw + 30
                local nx = (sw / 2) - (boxW / 2)
                
                Susano.DrawRectFilled(nx, ny, boxW, 48, ui.colors.bg[1], ui.colors.bg[2], ui.colors.bg[3], 0.95, 8)
                local r, g, b = 0.2, 0.9, 0.4
                if n.isErr then r, g, b = 0.9, 0.2, 0.2 end
                Susano.DrawRectFilled(nx, ny, 4, 48, r, g, b, 1.0, 4)
                
                Susano.DrawText(nx + 12, ny + 8, n.title, 14, 1, 1, 1, 0.9)
                Susano.DrawText(nx + 12, ny + 26, n.text, 12, 1, 1, 1, 0.5)
                
                ny = ny - 55 -- Stack upwards
            end
        end
    end

    local function drawFancy()
        local active = menu[currentTab] or {}
        local contentH = #active * ui.rowH
        local totalH = ui.headerH + ui.tabH + contentH + ui.footerH
        
        -- Drop Shadow (Multiple layers)
        for i = 1, 4 do
            local offset = i * 2
            local alpha = 0.4 - (i * 0.08)
            Susano.DrawRectFilled(ui.x - offset, ui.y - offset, ui.w + (offset*2), totalH + (offset*2), 0, 0, 0, alpha, 8)
        end
        
        -- Main Glow Border (Cyan/Pink)
        Susano.DrawRectGradient(ui.x - 1, ui.y - 1, ui.w + 2, totalH + 2, 
            ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.8,
            ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 0.8,
            ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.8,
            ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 0.8, 4)
        
        -- Main Body Base
        Susano.DrawRectFilled(ui.x, ui.y, ui.w, totalH, ui.colors.bg[1], ui.colors.bg[2], ui.colors.bg[3], ui.colors.bg[4], 4)
        
        -- Header Gradient
        Susano.DrawRectGradient(ui.x, ui.y, ui.w, ui.headerH, 
            ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.15,
            0, 0, 0, 0,
            ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.15,
            0, 0, 0, 0, 4)
            
        -- Logo
        if Susano.DrawTexture then
            Susano.DrawTexture("logo.png", ui.x + 20, ui.y + 10, 60, 60)
        end

        -- Header Text
        Susano.DrawText(ui.x + (ui.w/2) - 60, ui.y + 25, "JASI", 28, 1, 1, 1, 1.0)
        Susano.DrawText(ui.x + (ui.w/2) - 40, ui.y + 55, "LOVE BUILD", 10, ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 1.0)
        
        -- Divider
        Susano.DrawRectFilled(ui.x + 20, ui.y + ui.headerH, ui.w - 40, 1, ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 0.3, 0)
        
        -- Horizontal Tabs
        local tabW = ui.w / #tabs
        local tabY = ui.y + ui.headerH
        for i, name in ipairs(tabs) do
            local tx = ui.x + (i-1) * tabW
            local isT = (i == currentTab)
            
            if isT then
                -- Glowing Underline
                Susano.DrawRectFilled(tx + 10, tabY + ui.tabH - 2, tabW - 20, 2, ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 1.0, 1)
                -- Subtle background highlight
                Susano.DrawRectFilled(tx, tabY, tabW, ui.tabH, ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.1, 0)
            end
            
            local tw = Susano.GetTextWidth(name, 12) or 30
            local col = isT and ui.colors.text or ui.colors.textDim
            Susano.DrawText(tx + (tabW/2) - (tw/2), tabY + 15, name, 12, col[1], col[2], col[3], col[4])
        end
        
        -- Content Divider
        Susano.DrawRectFilled(ui.x, tabY + ui.tabH, ui.w, 1, ui.colors.border[1], ui.colors.border[2], ui.colors.border[3], 0.1, 0)
        
        -- List Items
        local itemStartY = tabY + ui.tabH
        for i, item in ipairs(active) do
            local ry = itemStartY + (i-1) * ui.rowH
            local isS = (i == selectedIndex)
            
            if isS then
                -- Active Selection Box
                Susano.DrawRectFilled(ui.x + 10, ry + 2, ui.w - 20, ui.rowH - 4, ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 0.15, 4)
                Susano.DrawRectFilled(ui.x + 10, ry + 2, 4, ui.rowH - 4, ui.colors.accent2[1], ui.colors.accent2[2], ui.colors.accent2[3], 1.0, 2)
            end
            
            local col = isS and ui.colors.text or ui.colors.textDim
            Susano.DrawText(ui.x + 30, ry + 12, item.label, 14, col[1], col[2], col[3], col[4])
            
            if item.type == "toggle" then
                drawToggle(ui.x + ui.w - 60, ry + 2, item.value)
            elseif item.type == "button" then
                Susano.DrawText(ui.x + ui.w - 30, ry + 12, ">", 14, col[1], col[2], col[3], isS and 1.0 or 0.3)
            end
        end
        
        -- Footer Divider
        local fy = itemStartY + contentH
        Susano.DrawRectFilled(ui.x + 20, fy, ui.w - 40, 1, ui.colors.border[1], ui.colors.border[2], ui.colors.border[3], 0.1, 0)
        
        -- Footer
        local sn = selectedPlayer and selectedPlayer.name or "NONE"
        Susano.DrawText(ui.x + 20, fy + 10, "TARGET: " .. sn, 11, ui.colors.accent1[1], ui.colors.accent1[2], ui.colors.accent1[3], 0.8)
        
        local ms = GetGameTimer()
        local s = math.floor(ms / 1000) % 60
        local m = math.floor(ms / 60000) % 60
        local h = math.floor(ms / 3600000)
        local uptime = string.format("UPTIME: %02d:%02d:%02d", h, m, s)
        Susano.DrawText(ui.x + ui.w - 110, fy + 10, uptime, 11, ui.colors.textDim[1], ui.colors.textDim[2], ui.colors.textDim[3], 0.8)
    end

    local function handleInput()
        local _, pg = Susano.GetAsyncKeyState(0x21)
        if pg then visible = not visible; if not visible then Susano.ResetFrame() end; Wait(250) end
        if not visible then return end
        
        local active = menu[currentTab] or {}
        local item = active[selectedIndex]
        
        local _, r = Susano.GetAsyncKeyState(0x27)
        if r then currentTab = currentTab % #tabs + 1; selectedIndex = 1; Wait(180) end
        local _, l = Susano.GetAsyncKeyState(0x25)
        if l then currentTab = (currentTab - 2 + #tabs) % #tabs + 1; selectedIndex = 1; Wait(180) end
        
        local _, d = Susano.GetAsyncKeyState(0x28)
        if d then selectedIndex = (selectedIndex % #active) + 1; Wait(130) end
        local _, u = Susano.GetAsyncKeyState(0x26)
        if u then selectedIndex = (selectedIndex - 2 + #active) % #active + 1; Wait(130) end
        
        local _, e = Susano.GetAsyncKeyState(0x0D) -- ENTER
        if e then
            local item = active[selectedIndex]
            if item.type == "toggle" then 
                item.value = not item.value 
                if item.onToggle then item.onToggle(item.value) end
                
                local stateStr = item.value and "ENABLED" or "DISABLED"
                pushNotif("System Alert", item.label .. " is now " .. stateStr, not item.value)
            elseif item.type == "button" and item.onClick then 
                pushNotif("Action Executed", item.label, false)
                item.onClick() 
            end
            Wait(250)
        end
    end

    -- MAIN LOOP
    Citizen.CreateThread(function()
        while true do
            handleInput()
            
            if visible or #notifications > 0 then
                Susano.BeginFrame()
                if visible then drawFancy() end
                if #notifications > 0 then drawNotifs() end
                Susano.SubmitFrame()
            end
            
            -- Noclip Logic
            if noclipEnabled and noclipCam then
                local speed = 1.0
                if IsControlPressed(0, 21) then speed = 3.0 end -- Shift (Sprint)
                if IsControlPressed(0, 19) then speed = 0.2 end -- Alt (Slow)
                
                local rot = GetCamRot(noclipCam, 2)
                local pos = GetCamCoord(noclipCam)
                
                local fwdX = -math.sin(math.rad(rot.z)) * math.cos(math.rad(rot.x))
                local fwdY = math.cos(math.rad(rot.z)) * math.cos(math.rad(rot.x))
                local fwdZ = math.sin(math.rad(rot.x))
                local fwd = vector3(fwdX, fwdY, fwdZ)
                
                local rightX = math.cos(math.rad(rot.z))
                local rightY = math.sin(math.rad(rot.z))
                local right = vector3(rightX, rightY, 0.0)
                
                if IsControlPressed(0, 32) then pos = pos + fwd * speed end -- W
                if IsControlPressed(0, 33) then pos = pos - fwd * speed end -- S
                if IsControlPressed(0, 34) then pos = pos - right * speed end -- A
                if IsControlPressed(0, 35) then pos = pos + right * speed end -- D
                if IsControlPressed(0, 22) then pos = pos + vector3(0, 0, speed) end -- Space
                if IsControlPressed(0, 36) then pos = pos - vector3(0, 0, speed) end -- Ctrl
                
                local rightAxisX = GetControlNormal(0, 220)
                local rightAxisY = GetControlNormal(0, 221)
                local newRotZ = rot.z - (rightAxisX * 5.0)
                local newRotX = rot.x - (rightAxisY * 5.0)
                newRotX = math.max(math.min(newRotX, 89.0), -89.0)
                
                SetCamCoord(noclipCam, pos.x, pos.y, pos.z)
                SetCamRot(noclipCam, newRotX, 0.0, newRotZ, 2)
                SetEntityCoordsNoOffset(PlayerPedId(), pos.x, pos.y, pos.z, false, false, false)
            end
            
            -- Passive Features
            if menu[1][3] and menu[1][3].label == "Super Jump" and menu[1][3].value then
                SetSuperJumpThisFrame(PlayerId())
            end
            
            Wait(0)
        end
    end)

    -- CAR RAIN THREAD
    Citizen.CreateThread(function()
        local VehicleModel = GetHashKey("jugular") 
        local PedModel = GetHashKey("mp_m_freemode_01") 
        while true do
            if carRain then
                RequestModel(VehicleModel)
                RequestModel(PedModel)
                while not HasModelLoaded(VehicleModel) or not HasModelLoaded(PedModel) do Wait(0) end
                
                for _, player in ipairs(GetActivePlayers()) do
                    local targetPed = GetPlayerPed(player)
                    if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) and targetPed ~= PlayerPedId() then
                        local targetCoords = GetEntityCoords(targetPed)
                        local spawnPos = vector3(targetCoords.x, targetCoords.y, targetCoords.z + 65)
                        local car = CreateVehicle(VehicleModel, spawnPos.x, spawnPos.y, spawnPos.z, 0.0, true, false)
                        SetEntityInvincible(car, true)
                        SetEntityVelocity(car, 0.0, 0.0, -45.0)
                        SetEntityAsNoLongerNeeded(car)
                    end
                end
                Citizen.Wait(1200) 
            else
                Citizen.Wait(1000)
            end
        end
    end)