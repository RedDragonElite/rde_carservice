--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  🚘 RDE CAR SERVICE - SERVER v1.0                                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local Ox = require '@ox_core/lib/init'
local activeServices = {}
local serviceStats = {
    deliveries = 0,
    pickups = 0,
    revenue = 0,
    errors = 0
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔧 CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════

---@param path string|table
---@param default any
---@return any
local function getConfigValue(path, default)
    if not Config then return default end

    if type(path) == 'table' then
        local value = Config
        for _, key in ipairs(path) do
            if value and type(value) == 'table' then
                value = value[key]
            else
                return default
            end
        end
        -- 🔧 FIX: must return value as-is if not nil, otherwise `false` configs flip to default.
        -- Old `value ~= nil and value or default` returned default for boolean false values.
        if value ~= nil then return value end
        return default
    end

    if Config[path] ~= nil then return Config[path] end
    return default
end

local DeliveryCost = getConfigValue('DeliveryCost', 750)
local PickupCost = getConfigValue('PickupCost', 500)
local DefaultGarage = getConfigValue('DefaultGarage', 'legion_garage')
local ServiceTimeout = getConfigValue({'Timing', 'serviceTimeout'}, 600)
local DebugMode = getConfigValue('Debug', true)

-- ═══════════════════════════════════════════════════════════════════════════
-- 📊 LOGGING SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

local LogLevels = {
    DEBUG = { color = '^3', prefix = '🐛' },
    INFO = { color = '^2', prefix = 'ℹ️' },
    WARN = { color = '^3', prefix = '⚠️' },
    ERROR = { color = '^1', prefix = '❌' },
    SUCCESS = { color = '^2', prefix = '✅' }
}

---@param level string
---@param message string
local function log(level, message)
    if not DebugMode and level == 'DEBUG' then return end
    
    local logConfig = LogLevels[level] or LogLevels.INFO
    print(('%s%s [RDE Service] %s^7'):format(
        logConfig.color,
        logConfig.prefix,
        message
    ))
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 💰 MONEY HANDLING
-- ═══════════════════════════════════════════════════════════════════════════

---@param charId number
---@param amount number
---@return boolean
local function hasEnoughMoney(charId, amount)
    if not charId or not amount or amount <= 0 then 
        log('ERROR', ('Invalid parameters: charId=%s, amount=%s'):format(tostring(charId), tostring(amount)))
        return false 
    end

    local success, result = pcall(MySQL.query.await, [[
        SELECT inventory FROM character_inventory
        WHERE charid = ?
        LIMIT 1
    ]], {charId})

    if not success then
        log('ERROR', ('Database error checking money for charId: %d'):format(charId))
        return false
    end

    if not result or not result[1] then 
        log('WARN', ('No inventory found for charId: %d'):format(charId))
        return false 
    end

    local inventory = json.decode(result[1].inventory)
    if not inventory then 
        log('ERROR', ('Failed to decode inventory for charId: %d'):format(charId))
        return false 
    end

    for _, item in ipairs(inventory) do
        if item and item.name == "money" and item.count and item.count >= amount then
            return true
        end
    end

    return false
end

---@param charId number
---@param amount number
---@return boolean
local function removeMoney(charId, amount)
    if not charId or not amount or amount <= 0 then 
        log('ERROR', ('Invalid remove money parameters: charId=%s, amount=%s'):format(tostring(charId), tostring(amount)))
        return false 
    end

    local success, result = pcall(MySQL.query.await, [[
        SELECT inventory FROM character_inventory
        WHERE charid = ?
        LIMIT 1
    ]], {charId})

    if not success then
        log('ERROR', ('Database error removing money for charId: %d'):format(charId))
        return false
    end

    if not result or not result[1] then return false end

    local inventory = json.decode(result[1].inventory)
    if not inventory then return false end

    for _, item in ipairs(inventory) do
        if item and item.name == "money" then
            if not item.count or item.count < amount then return false end

            item.count = item.count - amount

            local updateSuccess = pcall(MySQL.update.await, [[
                UPDATE character_inventory
                SET inventory = ?
                WHERE charid = ?
            ]], {json.encode(inventory), charId})

            if updateSuccess then
                serviceStats.revenue = serviceStats.revenue + amount
                log('SUCCESS', ('Removed $%d from charId: %d (Total revenue: $%d)'):format(
                    amount, charId, serviceStats.revenue
                ))
            end

            return updateSuccess
        end
    end

    return false
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🧹 CLEANUP SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════

---@param source number
---@param reason string
local function cleanupService(source, reason)
    if activeServices[source] then
        local serviceType = activeServices[source].type
        log('INFO', ('Cleanup source=%d, type=%s, reason=%s'):format(source, serviceType, reason))
        
        if reason == 'timeout' or reason == 'cancelled_by_client' then
            serviceStats.errors = serviceStats.errors + 1
        end
    end
    activeServices[source] = nil
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔥 FIXED: VEHICLE PROPERTIES LOADING
-- ═══════════════════════════════════════════════════════════════════════════

---@param plate string
---@return table|nil
local function loadVehicleProperties(plate)
    if not plate or plate == "" then
        log('ERROR', 'Invalid plate (empty)')
        return nil
    end

    plate = plate:gsub("^%s*(.-)%s*$", "%1")
    log('DEBUG', ('━━━━━━━━━ Loading properties for plate: "%s" ━━━━━━━━━'):format(plate))

    local success, result = pcall(MySQL.query.await, [[
        SELECT data, model
        FROM vehicles
        WHERE plate = ?
        LIMIT 1
    ]], {plate})

    if not success then
        log('ERROR', ('Database error for plate: %s'):format(plate))
        return nil
    end

    if not result or not result[1] then
        log('ERROR', ('No vehicle found for plate: %s'):format(plate))
        return nil
    end

    local vehicleData = result[1]

    -- Check if data column exists and is valid
    if not vehicleData.data or vehicleData.data == '' or vehicleData.data == 'null' then
        log('WARN', ('No data column for plate: %s - returning empty properties'):format(plate))
        return {}
    end

    -- Attempt to decode JSON
    local decoded = json.decode(vehicleData.data)
    if not decoded or type(decoded) ~= 'table' then
        log('ERROR', ('Failed to decode data for plate: %s'):format(plate))
        log('DEBUG', ('Raw data type: %s'):format(type(vehicleData.data)))
        log('DEBUG', ('Raw data sample: %s'):format(tostring(vehicleData.data):sub(1, 200)))
        return {}
    end

    -- Debug: Show structure
    if DebugMode then
        log('DEBUG', ('Decoded data type: %s'):format(type(decoded)))
        if type(decoded) == 'table' then
            local keys = {}
            for k, v in pairs(decoded) do
                table.insert(keys, ('%s=%s'):format(k, type(v)))
            end
            log('DEBUG', ('Decoded keys: %s'):format(table.concat(keys, ', ')))
            
            -- If properties exists, show its type and sample
            if decoded.properties then
                log('DEBUG', ('Properties type: %s'):format(type(decoded.properties)))
                if type(decoded.properties) == 'string' then
                    log('DEBUG', ('Properties string length: %d'):format(#decoded.properties))
                    log('DEBUG', ('Properties string sample: %s'):format(decoded.properties:sub(1, 200)))
                elseif type(decoded.properties) == 'table' then
                    local propKeys = {}
                    local count = 0
                    for k, _ in pairs(decoded.properties) do
                        count = count + 1
                        if count <= 5 then
                            table.insert(propKeys, k)
                        end
                    end
                    log('DEBUG', ('Properties table keys sample: %s'):format(table.concat(propKeys, ', ')))
                end
            end
        end
    end

    -- 🔥 CRITICAL FIX: Extract properties from ox_core format
    local properties = nil

    -- Method 1: Direct properties key as table
    if decoded.properties and type(decoded.properties) == 'table' then
        properties = decoded.properties
        log('DEBUG', '✓ Found properties at .properties (table)')
    
    -- Method 2: Properties key as JSON string (NEEDS DECODING)
    elseif decoded.properties and type(decoded.properties) == 'string' then
        log('DEBUG', '✓ Found properties at .properties (string) - decoding...')
        local success, decodedProps = pcall(json.decode, decoded.properties)
        if success and type(decodedProps) == 'table' then
            properties = decodedProps
            log('DEBUG', '✓ Successfully decoded properties string')
        else
            log('ERROR', ('Failed to decode properties string: %s'):format(tostring(decoded.properties):sub(1, 100)))
        end
    
    -- Method 3: Check if decoded is already the properties object
    elseif decoded.modEngine or decoded.color1 or decoded.plate then
        properties = decoded
        log('DEBUG', '✓ Decoded data is properties object')
    
    -- Method 4: Nested in vehicle data
    elseif decoded.vehicle and type(decoded.vehicle) == 'table' then
        if type(decoded.vehicle.properties) == 'table' then
            properties = decoded.vehicle.properties
            log('DEBUG', '✓ Found properties at .vehicle.properties (table)')
        elseif type(decoded.vehicle.properties) == 'string' then
            log('DEBUG', '✓ Found properties at .vehicle.properties (string) - decoding...')
            local success, decodedProps = pcall(json.decode, decoded.vehicle.properties)
            if success and type(decodedProps) == 'table' then
                properties = decodedProps
                log('DEBUG', '✓ Successfully decoded vehicle.properties string')
            end
        end
    
    -- Method 5: Check for stored key
    elseif decoded.stored and type(decoded.stored) == 'table' then
        if type(decoded.stored.properties) == 'table' then
            properties = decoded.stored.properties
            log('DEBUG', '✓ Found properties at .stored.properties (table)')
        elseif type(decoded.stored.properties) == 'string' then
            log('DEBUG', '✓ Found properties at .stored.properties (string) - decoding...')
            local success, decodedProps = pcall(json.decode, decoded.stored.properties)
            if success and type(decodedProps) == 'table' then
                properties = decodedProps
                log('DEBUG', '✓ Successfully decoded stored.properties string')
            end
        end
    end

    if not properties or type(properties) ~= 'table' then
        log('WARN', ('Could not extract properties for plate: %s'):format(plate))
        log('DEBUG', ('Available keys in decoded: %s'):format(table.concat((function()
            local keys = {}
            for k, _ in pairs(decoded) do
                table.insert(keys, k)
            end
            return keys
        end)(), ', ')))
        return {}
    end

    -- Count and log properties
    local propCount = 0
    local sampleProps = {}
    for key, value in pairs(properties) do
        propCount = propCount + 1
        if propCount <= 5 then
            table.insert(sampleProps, ('%s=%s'):format(key, tostring(value)))
        end
    end

    log('SUCCESS', ('✅ Loaded %d properties for plate: %s'):format(propCount, plate))
    
    if DebugMode and #sampleProps > 0 then
        log('DEBUG', ('Sample properties: %s'):format(table.concat(sampleProps, ', ')))
    end

    -- Verify critical properties
    local hasMods = properties.modEngine or properties.modBrakes or properties.modTransmission
    local hasColors = properties.color1 or properties.color2
    local hasExtras = properties.modTurbo ~= nil or properties.modXenon ~= nil

    log('DEBUG', ('Property categories: mods=%s, colors=%s, extras=%s'):format(
        tostring(hasMods ~= nil), 
        tostring(hasColors ~= nil), 
        tostring(hasExtras ~= nil)
    ))

    -- ═══════════════════════════════════════════════════════════════════
    -- 🔧 SANITIZE: Convert all values to plain Lua types
    -- rapidjson decodes arrays as userdata (lua_rapidjson_array) which
    -- cannot be sent over statebags or used by lib.setVehicleProperties.
    -- We re-encode → re-decode the entire table to flush all userdata.
    -- ═══════════════════════════════════════════════════════════════════
    local sanitizeOk, sanitized = pcall(function()
        -- json round-trip forces rapidjson userdata → plain tables/arrays
        return json.decode(json.encode(properties))
    end)

    if sanitizeOk and type(sanitized) == 'table' then
        properties = sanitized
        log('DEBUG', '✓ Properties sanitized (rapidjson userdata flushed)')
    else
        log('WARN', 'Properties sanitize failed — sending raw (may cause statebag issues)')
    end

    return properties
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 👤 PLAYER HELPER
-- ═══════════════════════════════════════════════════════════════════════════

---@param source number
---@return table|nil
local function getPlayer(source)
    local player = Ox.GetPlayer(source)
    if not player or not player.charId then 
        log('WARN', ('Player not found or no charId for source: %d'):format(source))
        return nil 
    end
    return player
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📡 STATEBAG: Vehicle Properties Sync (RDE Standard)
-- ═══════════════════════════════════════════════════════════════════════════

---@param netId number
---@param properties table
---@return boolean
local function setVehiclePropertiesStatebag(netId, properties)
    if not netId or not properties or not next(properties) then
        log('ERROR', 'setVehiclePropertiesStatebag: invalid netId or empty properties')
        return false
    end

    -- 🔧 FIX (CRITICAL): Wait for the server-side network entity to be registered.
    -- When a client calls CreateVehicle(...networked=true), the entity is created
    -- locally and a netId is assigned, but the server registers that netId only after
    -- the client's network announcement packet arrives. The client's TriggerServerEvent
    -- can outrun that registration by 50-300ms, so NetworkGetEntityFromNetworkId
    -- returns 0 on the first try and the statebag never gets set.
    -- This was the actual cause of "cars delivered without mods".
    local vehicle
    for attempt = 1, 50 do  -- up to 5s
        vehicle = NetworkGetEntityFromNetworkId(netId)
        if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then break end
        Wait(100)
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        log('ERROR', ('setVehiclePropertiesStatebag: entity never appeared for netId %d after 5s'):format(netId))
        return false
    end

    -- Set our own statebag key — replicated to all clients (broadcast = true)
    Entity(vehicle).state:set('rde:vehicleProperties', properties, true)

    log('SUCCESS', ('📡 Statebag rde:vehicleProperties set for netId %d'):format(netId))
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 📡 EVENT: Client reports spawned vehicle netId → Server sets statebag
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent('rde_carservice:vehicleSpawned', function(netId, plate)
    local source = source
    local service = activeServices[source]

    if not service or service.type ~= 'delivery' or service.plate ~= plate then
        log('WARN', ('vehicleSpawned: no matching active delivery for source=%d plate=%s'):format(source, plate))
        return
    end

    if not service.vehicle or not next(service.vehicle.properties or {}) then
        log('DEBUG', ('vehicleSpawned: no properties to sync for plate=%s'):format(plate))
        return
    end

    log('INFO', ('📡 vehicleSpawned: setting statebag for netId=%d plate=%s'):format(netId, plate))
    setVehiclePropertiesStatebag(netId, service.vehicle.properties)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 📡 CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════

lib.callback.register('rde_carservice:getVehicles', function(source)
    local player = getPlayer(source)
    if not player then return {} end

    local success, result = pcall(MySQL.query.await, [[
        SELECT plate, model, data
        FROM vehicles
        WHERE owner = ?
        AND stored IS NOT NULL
        AND data IS NOT NULL
        ORDER BY plate ASC
    ]], {player.charId})

    if not success then
        log('ERROR', ('Database error getting vehicles for charId: %d'):format(player.charId))
        return {}
    end

    if not result then return {} end

    log('INFO', ('Found %d stored vehicles for charId: %d'):format(#result, player.charId))
    return result
end)

lib.callback.register('rde_carservice:requestDelivery', function(source, plate)
    local player = getPlayer(source)
    if not player then
        log('ERROR', ('Player not found (source: %d)'):format(source))
        return false, 'player_not_found'
    end

    if activeServices[source] then
        log('WARN', ('Service already active for source: %d'):format(source))
        return false, 'already_active'
    end

    if not plate or plate == "" then
        log('ERROR', 'Invalid plate received')
        return false, 'invalid_plate'
    end

    plate = plate:gsub("^%s*(.-)%s*$", "%1")
    log('INFO', ('━━━━━━━━━ DELIVERY REQUEST ━━━━━━━━━'))
    log('INFO', ('Plate: "%s" | CharId: %d | Source: %d'):format(plate, player.charId, source))

    -- Fetch vehicle data
    -- 🔧 FIX: Require stored IS NOT NULL so we never charge for a vehicle that's already
    -- in the world (e.g. currently being driven). Previously the SELECT would succeed
    -- even on unstored vehicles, money was taken, then the delivery would happen anyway
    -- because the property of being "stored" wasn't enforced at request time.
    local success, vehicleResult = pcall(MySQL.query.await, [[
        SELECT plate, model, data
        FROM vehicles
        WHERE plate = ?
        AND owner = ?
        AND stored IS NOT NULL
        LIMIT 1
    ]], {plate, player.charId})

    if not success then
        log('ERROR', 'Database error while fetching vehicle')
        serviceStats.errors = serviceStats.errors + 1
        return false, 'database_error'
    end

    if not vehicleResult or not vehicleResult[1] then
        log('ERROR', ('No stored vehicle found for plate: %s (owner=%d)'):format(plate, player.charId))
        return false, 'vehicle_not_stored'
    end

    -- Check money
    if not hasEnoughMoney(player.charId, DeliveryCost) then
        log('WARN', ('Insufficient funds for charId: %d'):format(player.charId))
        return false, 'insufficient_funds'
    end

    -- Remove money
    if not removeMoney(player.charId, DeliveryCost) then
        log('ERROR', ('Failed to remove money from charId: %d'):format(player.charId))
        serviceStats.errors = serviceStats.errors + 1
        return false, 'account_error'
    end

    -- 🔥 FIXED: Load properties with enhanced extraction
    local properties = loadVehicleProperties(plate)

    local vehicleData = {
        plate = vehicleResult[1].plate,
        model = vehicleResult[1].model,
        properties = properties or {}
    }

    activeServices[source] = {
        type = 'delivery',
        plate = plate,
        vehicle = vehicleData,
        timestamp = os.time()
    }

    serviceStats.deliveries = serviceStats.deliveries + 1

    local propCount = properties and (function()
        local count = 0
        for _ in pairs(properties) do count = count + 1 end
        return count
    end)() or 0

    log('SUCCESS', ('✅ Delivery started: plate="%s", model=%s, properties=%d'):format(
        plate, 
        vehicleData.model,
        propCount
    ))
    log('INFO', ('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'))

    return true, vehicleData
end)

lib.callback.register('rde_carservice:requestPickup', function(source, netId)
    local player = getPlayer(source)
    if not player then 
        log('ERROR', ('Player not found (source: %d)'):format(source))
        return false, 'player_not_found' 
    end

    if activeServices[source] then 
        log('WARN', ('Service already active for source: %d'):format(source))
        return false, 'already_active' 
    end

    if not netId then 
        log('ERROR', 'Invalid netId')
        return false, 'invalid_netid' 
    end

    local vehicle = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(vehicle) then 
        log('ERROR', ('Vehicle doesn\'t exist (netId: %d)'):format(netId))
        return false, 'vehicle_not_found' 
    end

    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate or plate == "" then 
        log('ERROR', 'No plate found on vehicle')
        return false, 'no_plate' 
    end

    plate = plate:gsub("^%s*(.-)%s*$", "%1")

    log('INFO', ('Pickup request: plate="%s", charId=%d, source=%d'):format(plate, player.charId, source))

    local success, vehicleDataResult = pcall(MySQL.query.await, [[
        SELECT plate
        FROM vehicles
        WHERE plate = ?
        AND owner = ?
        LIMIT 1
    ]], {plate, player.charId})

    if not success or not vehicleDataResult or not vehicleDataResult[1] then
        log('WARN', ('Player not owner of vehicle: %s'):format(plate))
        return false, 'not_owner'
    end

    if not hasEnoughMoney(player.charId, PickupCost) then
        log('WARN', ('Insufficient funds for pickup, charId: %d'):format(player.charId))
        return false, 'insufficient_funds'
    end

    if not removeMoney(player.charId, PickupCost) then
        log('ERROR', ('Failed to remove money for pickup, charId: %d'):format(player.charId))
        serviceStats.errors = serviceStats.errors + 1
        return false, 'account_error'
    end

    activeServices[source] = {
        type = 'pickup',
        plate = plate,
        netId = netId,
        timestamp = os.time()
    }

    serviceStats.pickups = serviceStats.pickups + 1

    log('SUCCESS', ('Pickup started: plate="%s"'):format(plate))
    return true, GetEntityCoords(vehicle)
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 📡 COMPLETION EVENTS
-- ═══════════════════════════════════════════════════════════════════════════

RegisterNetEvent('rde_carservice:completeDelivery', function(plate)
    local source = source
    local service = activeServices[source]

    if not service or service.type ~= 'delivery' or service.plate ~= plate then
        log('WARN', ('Invalid delivery completion: source=%d, plate=%s'):format(source, plate))
        return
    end

    log('INFO', ('Completing delivery for plate: %s'):format(plate))

    SetTimeout(5000, function()
        local success = pcall(MySQL.update.await, [[
            UPDATE vehicles
            SET stored = NULL
            WHERE plate = ?
        ]], {plate})

        if success then
            log('SUCCESS', ('Delivery completed: %s'):format(plate))
            cleanupService(source, "delivery_completed")
        else
            log('ERROR', ('Database error completing delivery: %s'):format(plate))
            serviceStats.errors = serviceStats.errors + 1
            cleanupService(source, "database_error")
        end
    end)
end)

RegisterNetEvent('rde_carservice:completePickup', function(plate)
    local source = source
    local service = activeServices[source]

    if not service or service.type ~= 'pickup' or service.plate ~= plate then
        log('WARN', ('Invalid pickup completion: source=%d, plate=%s'):format(source, plate))
        return
    end

    log('INFO', ('Completing pickup for plate: %s'):format(plate))

    local success = pcall(MySQL.update.await, [[
        UPDATE vehicles
        SET stored = ?
        WHERE plate = ?
    ]], {DefaultGarage, plate})

    if success then
        log('SUCCESS', ('Pickup completed: %s'):format(plate))
        cleanupService(source, "pickup_completed")
    else
        log('ERROR', ('Database error completing pickup: %s'):format(plate))
        serviceStats.errors = serviceStats.errors + 1
        cleanupService(source, "database_error")
    end
end)

RegisterNetEvent('rde_carservice:cancelService', function()
    local source = source  -- 🔧 FIX: capture source before any yielding call (good hygiene)
    log('INFO', ('Service cancelled by client: %d'):format(source))
    cleanupService(source, "cancelled_by_client")
end)

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔄 LIFECYCLE & MONITORING
-- ═══════════════════════════════════════════════════════════════════════════

AddEventHandler('playerDropped', function(reason)
    local source = source  -- 🔧 FIX: capture source explicitly
    if activeServices[source] then
        log('INFO', ('Player dropped during service: %d (reason: %s)'):format(source, reason))
        cleanupService(source, "player_disconnected")
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        local count = 0
        for source, _ in pairs(activeServices) do
            count = count + 1
            cleanupService(source, "resource_stop")
        end
        if count > 0 then
            log('INFO', ('Cleaned up %d services on resource stop'):format(count))
        end
        
        log('INFO', '═══════════ SERVICE STATISTICS ═══════════')
        log('INFO', ('Total Deliveries: %d'):format(serviceStats.deliveries))
        log('INFO', ('Total Pickups: %d'):format(serviceStats.pickups))
        log('INFO', ('Total Revenue: $%d'):format(serviceStats.revenue))
        log('INFO', ('Total Errors: %d'):format(serviceStats.errors))
        log('INFO', '═══════════════════════════════════════════')
        
        activeServices = {}
    end
end)

-- Timeout system
if ServiceTimeout and ServiceTimeout > 0 then
    CreateThread(function()
        while true do
            Wait(60000)
            local currentTime = os.time()
            local timedOut = {}

            for source, service in pairs(activeServices) do
                if currentTime - service.timestamp > ServiceTimeout then
                    table.insert(timedOut, source)
                    if GetPlayerPing(source) > 0 then
                        TriggerClientEvent('ox_lib:notify', source, {
                            title = 'Car Service',
                            description = 'Service timed out',
                            type = 'error',
                            icon = 'clock'
                        })
                    end
                end
            end

            for _, source in ipairs(timedOut) do
                log('WARN', ('Service timeout for source: %d'):format(source))
                cleanupService(source, "timeout")
            end
        end
    end)
end

-- Admin commands
if DebugMode then
    lib.addCommand('carservice_stats', {
        help = 'Show car service statistics',
        restricted = 'group.admin'
    }, function(source)
        log('INFO', '═════════════ LIVE STATISTICS ═════════════')
        log('INFO', ('Active Services: %d'):format(
            (function()
                local count = 0
                for _ in pairs(activeServices) do count = count + 1 end
                return count
            end)()
        ))
        log('INFO', ('Total Deliveries: %d'):format(serviceStats.deliveries))
        log('INFO', ('Total Pickups: %d'):format(serviceStats.pickups))
        log('INFO', ('Total Revenue: $%d'):format(serviceStats.revenue))
        log('INFO', ('Total Errors: %d'):format(serviceStats.errors))
        log('INFO', '═══════════════════════════════════════════')
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════════════

log('SUCCESS', '═════════════════════════════════════════════════════════')
log('SUCCESS', '   RDE | Car Service | Server v1.0 (FREE EDITION) loaded!')
log('SUCCESS', '═════════════════════════════════════════════════════════')
log('INFO', ('Delivery Cost: $%d | Pickup Cost: $%d'):format(DeliveryCost, PickupCost))
log('INFO', ('Service Timeout: %ds | Debug Mode: %s'):format(ServiceTimeout, DebugMode and 'ON' or 'OFF'))
log('INFO', ('Default Garage: %s'):format(DefaultGarage))
log('INFO', '🔧 Property loading: Enhanced extraction from ox_core')
log('SUCCESS', '═════════════════════════════════════════════════════════')