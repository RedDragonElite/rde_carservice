--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  🚘 RDE CAR SERVICE - CLIENT v1.0                                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 STATE MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════
local State = {
    activeDelivery = nil,
    activePickup = nil,
    driverPed = nil,
    driverVehicle = nil,
    driverBlip = nil,
    phoneProp = nil,
    isAnimating = false,
    soundId = nil
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔧 CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════
Config = Config or {}
Config.DeliveryCost = Config.DeliveryCost or 500
Config.PickupCost = Config.PickupCost or 300
Config.SpawnDistance = Config.SpawnDistance or 200
Config.DrivingSpeed = Config.DrivingSpeed or 15.0
Config.DrivingStyle = Config.DrivingStyle or 786603
Config.CleanupDelay = Config.CleanupDelay or 10000
Config.Debug = Config.Debug or true

Config.DriverModels = Config.DriverModels or {
    `a_m_m_business_01`,
    `a_m_y_business_01`,
    `a_m_y_business_02`,
    `a_m_y_vinewood_01`
}

Config.Effects = {
    enableParticles = true,
    enableSounds = true,
    enableBlipAnimation = true,
    enableProgressBars = true
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

---@param modelInput string|number
---@return number|nil
local function getValidModel(modelInput)
    if type(modelInput) == 'string' then
        return joaat(modelInput)
    elseif type(modelInput) == 'number' then
        return modelInput
    end
    return nil
end

---@param modelInput string|number
---@return string
local function getModelDisplayName(modelInput)
    local modelHash = getValidModel(modelInput)
    if not modelHash then return "Unknown Vehicle" end

    local displayName = GetDisplayNameFromVehicleModel(modelHash)
    if displayName and displayName ~= "CARNOTFOUND" then
        local labelText = GetLabelText(displayName)
        if labelText and labelText ~= "NULL" then
            return labelText
        end
    end

    return type(modelInput) == 'string' and modelInput or tostring(modelHash)
end

---@param message string
local function debugLog(message)
    if Config.Debug then
        print(("^3[RDE Service]^7 %s"):format(message))
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎵 SOUND SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local Sounds = {
    request = { dict = "HUD_FRONTEND_DEFAULT_SOUNDSET", name = "CONFIRM_BEEP" },
    success = { dict = "HUD_FRONTEND_DEFAULT_SOUNDSET", name = "CHECKPOINT_PERFECT" },
    error = { dict = "HUD_FRONTEND_DEFAULT_SOUNDSET", name = "CANCEL" },
    arrival = { dict = "HUD_MINI_GAME_SOUNDSET", name = "5_SEC_WARNING" }
}

---@param soundType string
local function playSound(soundType)
    if not Config.Effects.enableSounds then return end
    
    local sound = Sounds[soundType]
    if sound then
        PlaySoundFrontend(-1, sound.name, sound.dict, true)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- ✨ PARTICLE EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════

---@param coords vector3
local function playArrivalEffect(coords)
    if not Config.Effects.enableParticles then return end
    
    lib.requestNamedPtfxAsset('core', 2000)
    UseParticleFxAsset('core')
    
    StartParticleFxNonLoopedAtCoord(
        'ent_dst_elec_fire_sp',
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.5, false, false, false
    )
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📱 ENHANCED PHONE ANIMATION
-- ═══════════════════════════════════════════════════════════════════════════

local function startPhoneAnimation()
    if State.isAnimating then return end

    local playerPed = PlayerPedId()
    
    if not lib.requestAnimDict("cellphone@", 3000) then
        debugLog("Failed to load phone animation")
        return
    end

    if not lib.requestModel(`prop_npc_phone_02`, 3000) then
        debugLog("Failed to load phone prop")
        return
    end

    if State.phoneProp and DoesEntityExist(State.phoneProp) then
        DeleteObject(State.phoneProp)
    end

    local playerCoords = GetEntityCoords(playerPed)
    State.phoneProp = CreateObject(
        `prop_npc_phone_02`,
        playerCoords.x, playerCoords.y, playerCoords.z,
        true, true, false
    )

    if DoesEntityExist(State.phoneProp) then
        local boneIndex = GetPedBoneIndex(playerPed, 28422)
        AttachEntityToEntity(
            State.phoneProp, playerPed, boneIndex,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            true, true, false, true, 1, true
        )
        TaskPlayAnim(
            playerPed, "cellphone@", "cellphone_text_read_base",
            3.0, 3.0, -1, 49, 0, false, false, false
        )
        State.isAnimating = true
        playSound('request')
    end
end

local function stopPhoneAnimation()
    if not State.isAnimating then return end

    local playerPed = PlayerPedId()
    StopAnimTask(playerPed, "cellphone@", "cellphone_text_read_base", 1.0)
    ClearPedTasks(playerPed)

    if State.phoneProp and DoesEntityExist(State.phoneProp) then
        DetachEntity(State.phoneProp, true, false)
        DeleteObject(State.phoneProp)
        State.phoneProp = nil
    end

    State.isAnimating = false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 ENHANCED BLIP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

---@param coords vector3
---@param label string
---@param type string 'delivery' or 'pickup'
---@return number
local function createEnhancedBlip(coords, label, type)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    local config = type == 'delivery' and {
        sprite = 225,
        color = 26,
        scale = 0.9
    } or {
        sprite = 50,
        color = 25,
        scale = 0.85
    }
    
    SetBlipSprite(blip, config.sprite)
    SetBlipColour(blip, config.color)
    SetBlipScale(blip, config.scale)
    SetBlipRoute(blip, true)
    SetBlipRouteColour(blip, config.color)
    SetBlipAsShortRange(blip, false)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    
    if Config.Effects.enableBlipAnimation then
        CreateThread(function()
            local alpha = 255
            local direction = -1
            
            while DoesBlipExist(blip) do
                Wait(50)
                alpha = alpha + (direction * 15)
                
                if alpha <= 100 then
                    direction = 1
                elseif alpha >= 255 then
                    direction = -1
                end
                
                SetBlipAlpha(blip, alpha)
            end
        end)
    end
    
    return blip
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🧹 CLEANUP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function cleanupDelivery()
    if State.driverBlip then
        if DoesBlipExist(State.driverBlip) then
            SetBlipRoute(State.driverBlip, false)
            RemoveBlip(State.driverBlip)
        end
        State.driverBlip = nil
    end

    if State.driverPed and DoesEntityExist(State.driverPed) then
        SetEntityAsNoLongerNeeded(State.driverPed)
        DeleteEntity(State.driverPed)
        State.driverPed = nil
    end

    if State.driverVehicle and DoesEntityExist(State.driverVehicle) then
        SetEntityAsNoLongerNeeded(State.driverVehicle)
        DeleteEntity(State.driverVehicle)
        State.driverVehicle = nil
    end

    State.activeDelivery = nil
    stopPhoneAnimation()
end

local function cleanupPickup()
    if State.driverBlip then
        if DoesBlipExist(State.driverBlip) then
            SetBlipRoute(State.driverBlip, false)
            RemoveBlip(State.driverBlip)
        end
        State.driverBlip = nil
    end

    if State.driverPed and DoesEntityExist(State.driverPed) then
        SetEntityAsNoLongerNeeded(State.driverPed)
        DeleteEntity(State.driverPed)
        State.driverPed = nil
    end

    State.activePickup = nil
    stopPhoneAnimation()
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚗 DRIVER & VEHICLE SPAWNING
-- ═══════════════════════════════════════════════════════════════════════════

---@param coords vector3
---@param heading number
---@return number|nil
local function createDriver(coords, heading)
    local model = Config.DriverModels[math.random(#Config.DriverModels)]

    if not lib.requestModel(model, 10000) then
        debugLog(("Failed to load driver model: %s"):format(model))
        return nil
    end

    local ped = CreatePed(4, model, coords.x, coords.y, coords.z, heading, true, true)

    if not DoesEntityExist(ped) then
        debugLog("Failed to create driver ped")
        SetModelAsNoLongerNeeded(model)
        return nil
    end

    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedCombatAttributes(ped, 17, true)
    SetPedRelationshipGroupHash(ped, joaat("CIVMALE"))
    SetPedRandomComponentVariation(ped, true)
    SetPedKeepTask(ped, true)
    SetEntityInvincible(ped, true)
    SetPedCanRagdoll(ped, false)
    SetModelAsNoLongerNeeded(model)

    return ped
end

---@param targetCoords vector3
---@return vector3, number
local function calculateSpawnPosition(targetCoords)
    local attempts = 0
    local maxAttempts = 25
    local bestSpawnCoords = nil
    local bestHeading = 0.0

    while attempts < maxAttempts do
        local heading = math.random(0, 360)
        local rad = math.rad(heading)
        local distance = Config.SpawnDistance + math.random(-50, 50)

        local testCoords = vector3(
            targetCoords.x + math.cos(rad) * distance,
            targetCoords.y + math.sin(rad) * distance,
            targetCoords.z
        )

        local roadFound, roadCoords, roadHeading = GetClosestVehicleNodeWithHeading(
            testCoords.x, testCoords.y, testCoords.z, 1, 3.0, 0
        )

        if roadFound then
            local occupied = IsPositionOccupied(
                roadCoords.x, roadCoords.y, roadCoords.z, 5.0,
                false, true, true, false, false, 0, false
            )

            if not occupied then
                local foundGround, groundZ = GetGroundZFor_3dCoord(
                    roadCoords.x, roadCoords.y, roadCoords.z + 100.0, false
                )

                if foundGround then
                    roadCoords = vector3(roadCoords.x, roadCoords.y, groundZ + 0.5)
                end

                debugLog("Found valid spawn position")
                return roadCoords, roadHeading
            end
        end

        if not bestSpawnCoords then
            local foundGround, groundZ = GetGroundZFor_3dCoord(
                testCoords.x, testCoords.y, testCoords.z + 500.0, false
            )

            if foundGround then
                bestSpawnCoords = vector3(testCoords.x, testCoords.y, groundZ + 1.0)
                bestHeading = heading
            end
        end

        attempts = attempts + 1
    end

    if bestSpawnCoords then
        debugLog("Using fallback spawn position")
        return bestSpawnCoords, bestHeading
    end

    debugLog("Could not find suitable spawn position")
    return vector3(targetCoords.x + 100.0, targetCoords.y + 100.0, targetCoords.z), 0.0
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔥 FIXED: VEHICLE PROPERTIES APPLICATION
-- ═══════════════════════════════════════════════════════════════════════════

---@param vehicle number
---@param properties table
---@return boolean
local function applyVehicleProperties(vehicle, properties)
    if not DoesEntityExist(vehicle) then
        debugLog("❌ Vehicle doesn't exist for property application")
        return false
    end

    if not properties or type(properties) ~= 'table' then
        debugLog("⚠️ No valid properties to apply")
        return false
    end

    -- Count properties
    local propCount = 0
    for _ in pairs(properties) do
        propCount = propCount + 1
    end

    if propCount == 0 then
        debugLog("⚠️ Properties table is empty")
        return false
    end

    debugLog(("🔧 Applying %d properties to vehicle"):format(propCount))

    -- Method 1: Try ox_lib native method first
    local success = pcall(function()
        lib.setVehicleProperties(vehicle, properties)
    end)

    if success then
        debugLog("✅ Properties applied successfully via ox_lib")
        
        -- Verify application
        Wait(100)
        local verified = false
        if properties.modEngine then
            local currentMod = GetVehicleMod(vehicle, 11)
            verified = (currentMod == properties.modEngine)
            debugLog(("🔍 Verification: modEngine=%d, current=%d, match=%s"):format(
                properties.modEngine, currentMod, tostring(verified)
            ))
        end
        
        return true
    end

    debugLog("⚠️ ox_lib method failed, trying manual application...")

    -- Method 2: Manual native application (fallback)
    local manualSuccess = pcall(function()
        -- Set mod kit first
        SetVehicleModKit(vehicle, 0)
        
        -- Apply mods
        local modTypes = {
            {prop = 'modEngine', type = 11},
            {prop = 'modBrakes', type = 12},
            {prop = 'modTransmission', type = 13},
            {prop = 'modSuspension', type = 15},
            {prop = 'modArmor', type = 16},
            {prop = 'modSpoilers', type = 0},
            {prop = 'modFrontBumper', type = 1},
            {prop = 'modRearBumper', type = 2},
            {prop = 'modSideSkirt', type = 3},
            {prop = 'modExhaust', type = 4},
            {prop = 'modFrame', type = 5},
            {prop = 'modGrille', type = 6},
            {prop = 'modHood', type = 7},
            {prop = 'modFender', type = 8},
            {prop = 'modRightFender', type = 9},
            {prop = 'modRoof', type = 10},
            {prop = 'modHorns', type = 14},
            {prop = 'modFrontWheels', type = 23},
            {prop = 'modBackWheels', type = 24}
        }

        for _, mod in ipairs(modTypes) do
            if properties[mod.prop] and properties[mod.prop] >= 0 then
                SetVehicleMod(vehicle, mod.type, properties[mod.prop], false)
                debugLog(("  ✓ Applied %s = %d"):format(mod.prop, properties[mod.prop]))
            end
        end

        -- Apply toggle mods
        if properties.modTurbo ~= nil then
            ToggleVehicleMod(vehicle, 18, properties.modTurbo)
            debugLog(("  ✓ Applied modTurbo = %s"):format(tostring(properties.modTurbo)))
        end

        if properties.modXenon ~= nil then
            ToggleVehicleMod(vehicle, 22, properties.modXenon)
            debugLog(("  ✓ Applied modXenon = %s"):format(tostring(properties.modXenon)))
        end

        -- Apply colors
        if properties.color1 and properties.color2 then
            SetVehicleColours(vehicle, properties.color1, properties.color2)
            debugLog(("  ✓ Applied colors: %d, %d"):format(properties.color1, properties.color2))
        end

        if properties.pearlescentColor and properties.wheelColor then
            SetVehicleExtraColours(vehicle, properties.pearlescentColor, properties.wheelColor)
            debugLog(("  ✓ Applied extra colors: %d, %d"):format(properties.pearlescentColor, properties.wheelColor))
        end

        -- Apply window tint
        if properties.windowTint then
            SetVehicleWindowTint(vehicle, properties.windowTint)
            debugLog(("  ✓ Applied window tint: %d"):format(properties.windowTint))
        end

        -- Apply neon
        if properties.neonEnabled then
            for i = 0, 3 do
                SetVehicleNeonLightEnabled(vehicle, i, properties.neonEnabled[i + 1] or false)
            end
            
            if properties.neonColor then
                SetVehicleNeonLightsColour(vehicle, 
                    properties.neonColor[1] or 255, 
                    properties.neonColor[2] or 255, 
                    properties.neonColor[3] or 255
                )
            end
            debugLog("  ✓ Applied neon lights")
        end

        -- Apply wheel type
        if properties.wheels then
            SetVehicleWheelType(vehicle, properties.wheels)
            debugLog(("  ✓ Applied wheel type: %d"):format(properties.wheels))
        end
    end)

    if manualSuccess then
        debugLog("✅ Properties applied manually")
        return true
    end

    debugLog("❌ All property application methods failed")
    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚗 DELIVERY SYSTEM (FIXED)
-- ═══════════════════════════════════════════════════════════════════════════

---@param vehicleData table
local function deliverVehicle(vehicleData)
    if State.activeDelivery or State.activePickup then
        lib.notify({
            title = 'Car Service',
            description = 'Service bereits aktiv',
            type = 'error',
            icon = 'ban',
            iconColor = '#ef4444'
        })
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local spawnCoords, spawnHeading = calculateSpawnPosition(playerCoords)

    local vehicleModel = getValidModel(vehicleData.model)
    if not vehicleModel then
        lib.notify({
            title = 'Car Service',
            description = 'Ungültiges Fahrzeugmodell',
            type = 'error',
            icon = 'triangle-exclamation'
        })
        stopPhoneAnimation()
        TriggerServerEvent('rde_carservice:cancelService')
        return
    end

    -- Show progress bar
    if Config.Effects.enableProgressBars then
        if lib.progressCircle({
            duration = 2000,
            label = 'Rufe Service an...',
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = false,
                car = false,
                combat = true
            }
        }) then
            startPhoneAnimation()
        end
    else
        startPhoneAnimation()
    end

    if not lib.requestModel(vehicleModel, 15000) then
        lib.notify({
            title = 'Car Service',
            description = 'Fahrzeug konnte nicht geladen werden',
            type = 'error',
            icon = 'xmark'
        })
        stopPhoneAnimation()
        TriggerServerEvent('rde_carservice:cancelService')
        return
    end

    State.driverVehicle = CreateVehicle(
        vehicleModel,
        spawnCoords.x, spawnCoords.y, spawnCoords.z,
        spawnHeading,
        true,
        true
    )

    if not DoesEntityExist(State.driverVehicle) then
        lib.notify({
            title = 'Car Service',
            description = 'Fahrzeug konnte nicht gespawnt werden',
            type = 'error',
            icon = 'xmark'
        })
        stopPhoneAnimation()
        SetModelAsNoLongerNeeded(vehicleModel)
        TriggerServerEvent('rde_carservice:cancelService')
        return
    end

    -- Basic setup
    SetEntityAsMissionEntity(State.driverVehicle, true, true)
    SetVehicleNumberPlateText(State.driverVehicle, vehicleData.plate)
    SetVehicleOnGroundProperly(State.driverVehicle)
    SetVehicleEngineOn(State.driverVehicle, true, true, false)
    SetVehicleFuelLevel(State.driverVehicle, 65.0)
    SetModelAsNoLongerNeeded(vehicleModel)

    debugLog(("📋 Vehicle spawned: plate=%s, model=%s"):format(vehicleData.plate, vehicleData.model))

    -- 🔥 FIXED: Apply properties with multiple attempts
    if vehicleData.properties and next(vehicleData.properties) then
        debugLog(("🔧 Starting property application for: %s"):format(vehicleData.plate))
        
        -- Wait for vehicle to be fully initialized
        Wait(500)
        
        -- Attempt 1: Immediate application
        local success1 = applyVehicleProperties(State.driverVehicle, vehicleData.properties)
        
        -- Attempt 2: After delay
        Wait(1000)
        local success2 = applyVehicleProperties(State.driverVehicle, vehicleData.properties)
        
        -- Attempt 3: Request server-side statebag application
        local netId = NetworkGetNetworkIdFromEntity(State.driverVehicle)
        if netId then
            debugLog(("📡 Requesting server-side property application via statebag (netId: %d)"):format(netId))
            TriggerServerEvent('rde_carservice:applyPropertiesViaStatebag', netId, vehicleData.properties)
        end
        
        if success1 or success2 then
            debugLog("✅ Properties applied successfully")
        else
            debugLog("⚠️ Property application may have failed, relying on statebag")
        end
    else
        debugLog(("⚠️ No properties for: %s"):format(vehicleData.plate))
    end

    -- Create driver
    State.driverPed = createDriver(spawnCoords, spawnHeading)
    if not State.driverPed then
        DeleteEntity(State.driverVehicle)
        lib.notify({
            title = 'Car Service',
            description = 'Fahrer konnte nicht gespawnt werden',
            type = 'error',
            icon = 'user-xmark'
        })
        stopPhoneAnimation()
        TriggerServerEvent('rde_carservice:cancelService')
        return
    end

    TaskWarpPedIntoVehicle(State.driverPed, State.driverVehicle, -1)
    Wait(500)

    State.driverBlip = createEnhancedBlip(spawnCoords, "🚗 Fahrzeug-Lieferung", 'delivery')

    local distance = #(playerCoords - spawnCoords)
    local eta = math.ceil(distance / Config.DrivingSpeed * 2.5)

    lib.notify({
        title = 'Car Service',
        description = ("Fahrer kommt in ~%d Sekunden an"):format(eta),
        type = 'info',
        icon = 'car',
        iconColor = '#3b82f6',
        duration = 5000
    })

    SetTimeout(3000, function()
        stopPhoneAnimation()
    end)

    State.activeDelivery = {
        vehicle = State.driverVehicle,
        driver = State.driverPed,
        plate = vehicleData.plate,
        arrived = false
    }

    TaskVehicleDriveToCoordLongrange(
        State.driverPed,
        State.driverVehicle,
        playerCoords.x, playerCoords.y, playerCoords.z,
        Config.DrivingSpeed,
        Config.DrivingStyle,
        10.0
    )

    -- Delivery tracking thread
    CreateThread(function()
        local notified = false

        while State.activeDelivery and not State.activeDelivery.arrived do
            Wait(500)

            if not DoesEntityExist(State.driverVehicle) or not DoesEntityExist(State.driverPed) then
                cleanupDelivery()
                lib.notify({
                    title = 'Car Service',
                    description = 'Service abgebrochen',
                    type = 'error',
                    icon = 'ban'
                })
                TriggerServerEvent('rde_carservice:cancelService')
                return
            end

            local driverCoords = GetEntityCoords(State.driverVehicle)

            if State.driverBlip and DoesBlipExist(State.driverBlip) then
                SetBlipCoords(State.driverBlip, driverCoords.x, driverCoords.y, driverCoords.z)
            end

            local dist = #(GetEntityCoords(playerPed) - driverCoords)

            if dist < 50.0 and not notified then
                lib.notify({
                    title = 'Car Service',
                    description = 'Fahrer ist gleich da!',
                    type = 'success',
                    icon = 'circle-check',
                    iconColor = '#22c55e'
                })
                playSound('arrival')
                notified = true
            end

            if dist < 15.0 then
                State.activeDelivery.arrived = true

                if State.driverBlip and DoesBlipExist(State.driverBlip) then
                    SetBlipRoute(State.driverBlip, false)
                    RemoveBlip(State.driverBlip)
                    State.driverBlip = nil
                end

                ClearPedTasks(State.driverPed)
                TaskVehicleTempAction(State.driverPed, State.driverVehicle, 27, 3000)
                Wait(3000)

                SetVehicleEngineOn(State.driverVehicle, false, false, true)
                TaskLeaveVehicle(State.driverPed, State.driverVehicle, 0)
                Wait(3000)

                TaskGoToEntity(State.driverPed, playerPed, -1, 2.0, Config.DrivingSpeed, 0, 0)
                Wait(2000)

                -- Final property application after arrival
                if vehicleData.properties and next(vehicleData.properties) then
                    debugLog("🔄 Final property check after delivery")
                    Wait(500)
                    applyVehicleProperties(State.driverVehicle, vehicleData.properties)
                end

                playArrivalEffect(driverCoords)
                playSound('success')

                lib.notify({
                    title = 'Car Service',
                    description = '✅ Fahrzeug erfolgreich geliefert!',
                    type = 'success',
                    icon = 'circle-check',
                    iconColor = '#22c55e'
                })

                TriggerServerEvent('rde_carservice:completeDelivery', vehicleData.plate)

                State.activeDelivery = nil
                TaskWanderStandard(State.driverPed, 10.0, 10)

                local tempDriver = State.driverPed
                State.driverPed = nil

                SetTimeout(Config.CleanupDelay, function()
                    if tempDriver and DoesEntityExist(tempDriver) then
                        SetEntityAsNoLongerNeeded(tempDriver)
                        DeleteEntity(tempDriver)
                    end
                end)

                break
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📞 PICKUP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

---@param vehicleCoords vector3
---@param targetVehicle number
local function pickupVehicle(vehicleCoords, targetVehicle)
    if State.activeDelivery or State.activePickup then
        lib.notify({
            title = 'Car Service',
            description = 'Service bereits aktiv',
            type = 'error',
            icon = 'ban'
        })
        return
    end

    local roadFound, spawnCoords, spawnHeading = GetClosestVehicleNodeWithHeading(
        vehicleCoords.x + 100, vehicleCoords.y + 100, vehicleCoords.z, 1, 3.0, 0
    )

    if not roadFound then
        spawnCoords, spawnHeading = calculateSpawnPosition(vehicleCoords)
    end

    if Config.Effects.enableProgressBars then
        if lib.progressCircle({
            duration = 2000,
            label = 'Rufe Abholung an...',
            position = 'bottom',
            useWhileDead = false,
            canCancel = false,
            disable = {
                move = false,
                car = false,
                combat = true
            }
        }) then
            startPhoneAnimation()
        end
    else
        startPhoneAnimation()
    end

    State.driverPed = createDriver(spawnCoords, spawnHeading)
    if not State.driverPed then
        lib.notify({
            title = 'Car Service',
            description = 'Fahrer konnte nicht gespawnt werden',
            type = 'error',
            icon = 'user-xmark'
        })
        stopPhoneAnimation()
        TriggerServerEvent('rde_carservice:cancelService')
        return
    end

    State.driverBlip = createEnhancedBlip(spawnCoords, "📞 Abhol-Fahrer", 'pickup')

    lib.notify({
        title = 'Car Service',
        description = 'Fahrer ist unterwegs zur Abholung',
        type = 'info',
        icon = 'truck-pickup',
        iconColor = '#10b981',
        duration = 5000
    })

    SetTimeout(3000, function()
        stopPhoneAnimation()
    end)

    State.activePickup = {
        driver = State.driverPed,
        targetCoords = vehicleCoords,
        targetVehicle = targetVehicle,
        arrived = false
    }

    TaskGoToCoordAnyMeans(
        State.driverPed,
        vehicleCoords.x, vehicleCoords.y, vehicleCoords.z,
        1.5, 0, false, 786603, 0.0
    )

    CreateThread(function()
        local notified = false

        while State.activePickup and not State.activePickup.arrived do
            Wait(500)

            if not DoesEntityExist(State.driverPed) then
                cleanupPickup()
                lib.notify({
                    title = 'Car Service',
                    description = 'Service abgebrochen',
                    type = 'error',
                    icon = 'ban'
                })
                TriggerServerEvent('rde_carservice:cancelService')
                return
            end

            local driverCoords = GetEntityCoords(State.driverPed)

            if State.driverBlip and DoesBlipExist(State.driverBlip) then
                SetBlipCoords(State.driverBlip, driverCoords.x, driverCoords.y, driverCoords.z)
            end

            local dist = #(vehicleCoords - driverCoords)

            if dist < 50.0 and not notified then
                lib.notify({
                    title = 'Car Service',
                    description = 'Fahrer ist gleich da!',
                    type = 'success',
                    icon = 'circle-check'
                })
                playSound('arrival')
                notified = true
            end

            if dist < 5.0 then
                State.activePickup.arrived = true

                if State.driverBlip and DoesBlipExist(State.driverBlip) then
                    SetBlipRoute(State.driverBlip, false)
                    RemoveBlip(State.driverBlip)
                    State.driverBlip = nil
                end

                ClearPedTasks(State.driverPed)
                Wait(500)

                local vehicle = targetVehicle
                if not DoesEntityExist(vehicle) then
                    vehicle = GetClosestVehicle(
                        vehicleCoords.x, vehicleCoords.y, vehicleCoords.z,
                        10.0, 0, 71
                    )
                end

                if DoesEntityExist(vehicle) then
                    local plate = GetVehicleNumberPlateText(vehicle)

                    TaskEnterVehicle(State.driverPed, vehicle, 15000, -1, 2.0, 1, 0)
                    Wait(6000)

                    if GetVehiclePedIsIn(State.driverPed, false) == vehicle then
                        SetVehicleEngineOn(vehicle, true, true, false)

                        local randomHeading = math.random(0, 360)
                        local rad = math.rad(randomHeading)
                        local driveAwayCoords = vector3(
                            vehicleCoords.x + math.cos(rad) * 300,
                            vehicleCoords.y + math.sin(rad) * 300,
                            vehicleCoords.z
                        )

                        TaskVehicleDriveToCoord(
                            State.driverPed,
                            vehicle,
                            driveAwayCoords.x, driveAwayCoords.y, driveAwayCoords.z,
                            18.0, 0, GetEntityModel(vehicle), 786603, 2.0, -1.0
                        )

                        Wait(3000)

                        playArrivalEffect(vehicleCoords)
                        playSound('success')

                        lib.notify({
                            title = 'Car Service',
                            description = '💾 Fahrzeug in Garage gelagert',
                            type = 'success',
                            icon = 'circle-check',
                            iconColor = '#22c55e'
                        })

                        TriggerServerEvent('rde_carservice:completePickup', plate:gsub("^%s*(.-)%s*$", "%1"))

                        State.activePickup = nil

                        local tempDriver = State.driverPed
                        local tempVehicle = vehicle
                        State.driverPed = nil

                        SetTimeout(20000, function()
                            if tempDriver and DoesEntityExist(tempDriver) then
                                DeleteEntity(tempDriver)
                            end
                            if tempVehicle and DoesEntityExist(tempVehicle) then
                                DeleteEntity(tempVehicle)
                            end
                        end)
                    else
                        lib.notify({
                            title = 'Car Service',
                            description = 'Fahrer konnte nicht einsteigen',
                            type = 'error',
                            icon = 'xmark'
                        })
                        cleanupPickup()
                    end
                else
                    lib.notify({
                        title = 'Car Service',
                        description = 'Fahrzeug nicht gefunden',
                        type = 'error',
                        icon = 'car-burst'
                    })
                    cleanupPickup()
                end

                break
            end
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📋 MENU SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local function openCarServiceMenu()
    if State.activeDelivery or State.activePickup then
        lib.notify({
            title = 'Car Service',
            description = 'Service bereits aktiv',
            type = 'error',
            icon = 'ban'
        })
        return
    end

    local vehicles = lib.callback.await('rde_carservice:getVehicles', false)

    if not vehicles or #vehicles == 0 then
        lib.notify({
            title = 'Car Service',
            description = 'Keine Fahrzeuge in der Garage',
            type = 'error',
            icon = 'garage'
        })
        return
    end

    local options = {}

    for _, vehicle in ipairs(vehicles) do
        local displayName = getModelDisplayName(vehicle.model)
        local vehicleClass = GetVehicleClassFromName(getValidModel(vehicle.model))
        
        local classIcons = {
            [0] = '🚗', [1] = '🏎️', [2] = '🚙', [3] = '🚐',
            [4] = '🚗', [5] = '🏍️', [6] = '🚙', [7] = '🏍️',
            [8] = '🏍️', [9] = '🏍️', [10] = '🚁', [11] = '🚗',
            [12] = '🚗', [13] = '🏍️', [14] = '⛵', [15] = '🚁',
            [16] = '✈️', [17] = '🚙', [18] = '🚙', [19] = '🚙',
            [20] = '🚙', [21] = '🚂', [22] = '🏍️'
        }
        
        local icon = classIcons[vehicleClass] or '🚗'

        table.insert(options, {
            title = ('%s %s'):format(icon, displayName:upper()),
            description = ('📋 Kennzeichen: %s | 💵 Kosten: $%d'):format(
                vehicle.plate, 
                Config.DeliveryCost
            ),
            icon = 'car-side',
            iconColor = '#3b82f6',
            metadata = {
                {label = 'Kennzeichen', value = vehicle.plate},
                {label = 'Lieferkosten', value = ('$%d'):format(Config.DeliveryCost)}
            },
            onSelect = function()
                local success, result = lib.callback.await('rde_carservice:requestDelivery', false, vehicle.plate)

                if success then
                    playSound('success')
                    lib.notify({
                        title = 'Car Service',
                        description = 'Service angefordert',
                        type = 'success',
                        icon = 'circle-check'
                    })
                    deliverVehicle(result)
                else
                    playSound('error')
                    local errorMessages = {
                        player_not_found = 'Spieler nicht gefunden',
                        already_active = 'Service bereits aktiv',
                        invalid_plate = 'Ungültiges Kennzeichen',
                        no_vehicle_found = 'Fahrzeug nicht gefunden',
                        vehicle_not_stored = 'Fahrzeug nicht in Garage',
                        insufficient_funds = ('Nicht genug Geld ($%d benötigt)'):format(Config.DeliveryCost),
                        account_error = 'Zahlungsfehler'
                    }

                    lib.notify({
                        title = 'Car Service',
                        description = errorMessages[result] or 'Fehler aufgetreten',
                        type = 'error',
                        icon = 'triangle-exclamation'
                    })
                end
            end
        })
    end

    table.insert(options, {
        title = '📞 Abholung anfordern',
        description = ('💾 Fahrzeug in Garage lagern für $%d'):format(Config.PickupCost),
        icon = 'truck-pickup',
        iconColor = '#10b981',
        metadata = {
            {label = 'Abhol-Kosten', value = ('$%d'):format(Config.PickupCost)}
        },
        onSelect = function()
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)

            if vehicle == 0 then
                vehicle = lib.getClosestVehicle(GetEntityCoords(playerPed), 5.0, false)
            end

            if not vehicle or not DoesEntityExist(vehicle) then
                playSound('error')
                lib.notify({
                    title = 'Car Service',
                    description = 'Kein Fahrzeug in der Nähe',
                    type = 'error',
                    icon = 'car-burst'
                })
                return
            end

            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            local success, result = lib.callback.await('rde_carservice:requestPickup', false, netId)

            if success then
                playSound('success')
                lib.notify({
                    title = 'Car Service',
                    description = 'Abholung angefordert',
                    type = 'success',
                    icon = 'circle-check'
                })
                pickupVehicle(result, vehicle)
            else
                playSound('error')
                local errorMessages = {
                    player_not_found = 'Spieler nicht gefunden',
                    already_active = 'Service bereits aktiv',
                    invalid_netid = 'Ungültiges Fahrzeug',
                    vehicle_not_found = 'Fahrzeug nicht gefunden',
                    no_plate = 'Kein Kennzeichen gefunden',
                    not_owner = 'Du bist nicht der Besitzer',
                    insufficient_funds = ('Nicht genug Geld ($%d benötigt)'):format(Config.PickupCost),
                    account_error = 'Zahlungsfehler'
                }

                lib.notify({
                    title = 'Car Service',
                    description = errorMessages[result] or 'Fehler aufgetreten',
                    type = 'error',
                    icon = 'triangle-exclamation'
                })
            end
        end
    })

    lib.registerContext({
        id = 'carservice_menu',
        title = '🚘 Car Service Menü',
        options = options,
        menu = nil
    })

    lib.showContext('carservice_menu')
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎮 COMMANDS & INTERACTIONS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterCommand('carservice', function()
    openCarServiceMenu()
end, false)

-- ox_target integration
CreateThread(function()
    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addGlobalVehicle({
            {
                name = 'carservice_pickup',
                icon = 'fas fa-phone-volume',
                label = ('📞 Abholung anfordern ($%d)'):format(Config.PickupCost),
                distance = 3.0,
                canInteract = function(entity, distance, coords, name, bone)
                    return not (State.activeDelivery or State.activePickup)
                end,
                onSelect = function(data)
                    if not data.entity or not DoesEntityExist(data.entity) then
                        lib.notify({
                            title = 'Car Service',
                            description = 'Fahrzeug nicht gefunden',
                            type = 'error',
                            icon = 'car-burst'
                        })
                        return
                    end

                    local netId = NetworkGetNetworkIdFromEntity(data.entity)
                    local success, result = lib.callback.await('rde_carservice:requestPickup', false, netId)

                    if success then
                        playSound('success')
                        lib.notify({
                            title = 'Car Service',
                            description = 'Abholung angefordert',
                            type = 'success',
                            icon = 'circle-check'
                        })
                        pickupVehicle(result, data.entity)
                    else
                        playSound('error')
                        local errorMessages = {
                            player_not_found = 'Spieler nicht gefunden',
                            already_active = 'Service bereits aktiv',
                            invalid_netid = 'Ungültiges Fahrzeug',
                            vehicle_not_found = 'Fahrzeug nicht gefunden',
                            no_plate = 'Kein Kennzeichen gefunden',
                            not_owner = 'Du bist nicht der Besitzer',
                            insufficient_funds = ('Nicht genug Geld ($%d benötigt)'):format(Config.PickupCost),
                            account_error = 'Zahlungsfehler'
                        }

                        lib.notify({
                            title = 'Car Service',
                            description = errorMessages[result] or 'Fehler aufgetreten',
                            type = 'error',
                            icon = 'triangle-exclamation'
                        })
                    end
                end
            }
        })
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔄 LIFECYCLE EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        cleanupDelivery()
        cleanupPickup()

        if State.phoneProp and DoesEntityExist(State.phoneProp) then
            DeleteObject(State.phoneProp)
            State.phoneProp = nil
        end

        debugLog("Client cleanup completed")
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

CreateThread(function()
    debugLog("✅ RDE | Car Service | Client v1.0 (FREE EDITION) loaded!")
    debugLog(("📋 Costs: Delivery $%d | Pickup $%d"):format(Config.DeliveryCost, Config.PickupCost))
    debugLog("🔧 Property loading: Enhanced with multi-attempt system")
    
    if Config.Effects.enableParticles then
        debugLog("✨ Particle effects enabled")
    end
    if Config.Effects.enableSounds then
        debugLog("🔊 Sound effects enabled")
    end
    if Config.Effects.enableBlipAnimation then
        debugLog("🎯 Animated blips enabled")
    end
end)