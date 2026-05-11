--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║  🚘 RDE CAR SERVICE - CONFIGURATION v1.0.1                                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

Config = {}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🌐 LANGUAGE SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════
Config.Locale = 'en' -- 'en' or 'de'

Config.Translations = {
    ['en'] = {
        -- Service Messages
        ['service_requested'] = '🚗 Premium Vehicle Service\nProfessional driver dispatched',
        ['service_arriving'] = 'Driver arriving in ~%s minutes',
        ['service_arrived'] = '🚗 Vehicle arrived!\nDriver parking carefully',
        ['service_delivered'] = '🔑 Keys handed over!\nEnjoy your vehicle! 🚀',
        ['driver_leaving'] = 'Driver departing\nVehicle is now yours!',
        
        -- Pickup Messages
        ['pickup_requested'] = '📞 Pickup Service Requested\nDriver en route',
        ['pickup_arriving'] = 'Pickup driver arriving in ~%s minutes',
        ['pickup_arrived'] = 'Driver arrived\nPreparing vehicle storage',
        ['pickup_complete'] = '🏠 Vehicle stored safely in garage',
        
        -- Error Messages
        ['no_vehicle_found'] = 'No vehicle found',
        ['vehicle_too_far'] = 'Vehicle too far from pickup location',
        ['already_active'] = 'Service already active',
        ['service_cancelled'] = 'Service cancelled',
        ['insufficient_funds'] = 'Insufficient funds! Required: $%s',
        ['payment_success'] = 'Payment of $%s processed successfully',
        ['not_owner'] = 'You are not the owner',
        ['vehicle_model_load_failed'] = 'Failed to load vehicle model',
        ['vehicle_spawn_failed'] = 'Failed to spawn vehicle',
        ['driver_spawn_failed'] = 'Failed to spawn driver',
        ['driver_enter_failed'] = 'Driver failed to enter vehicle',
        ['service_timeout'] = 'Service timed out',
        ['not_in_vehicle'] = 'You are not in a vehicle',
        
        -- UI Labels
        ['menu_title'] = '🚘 Premium Vehicle Service',
        ['request_delivery'] = 'Request Delivery',
        ['request_pickup'] = 'Request Pickup',
        ['model'] = 'Model',
        ['plate'] = 'Plate',
        ['location'] = 'Location',
        ['garage'] = 'Garage',
        ['error'] = 'Error',
        ['success'] = 'Success',
        ['enjoy_your_vehicle'] = 'Enjoy your vehicle! 🚗💨',
        ['vehicle_stored'] = 'Vehicle stored in garage',
        ['driver_blip_name'] = '🚗 Vehicle Service Driver',
        ['minutes'] = 'minutes',
        
        -- Feature Descriptions
        ['ultra_realistic_delivery'] = '🌟 Ultra-Realistic Delivery\nSmooth animations & synchronized actions',
        ['convenient_pickup'] = '📦 Convenient Pickup\nFast, secure, and hassle-free',
        
        -- Menu Metadata
        ['delivery_cost'] = 'Delivery Cost',
        ['pickup_cost'] = 'Pickup Cost',
        ['vehicle_class'] = 'Vehicle Class',
        ['estimated_time'] = 'Estimated Time',
    },
    ['de'] = {
        -- Service Messages
        ['service_requested'] = '🚗 Premium Fahrzeugservice\nProfessioneller Fahrer unterwegs',
        ['service_arriving'] = 'Fahrer kommt in ~%s Minuten an',
        ['service_arrived'] = '🚗 Fahrzeug angekommen!\nFahrer parkt vorsichtig',
        ['service_delivered'] = '🔑 Schlüssel übergeben!\nViel Spaß mit deinem Fahrzeug! 🚀',
        ['driver_leaving'] = 'Fahrer verlässt Fahrzeug\nEs gehört jetzt dir!',
        
        -- Pickup Messages
        ['pickup_requested'] = '📞 Abholservice angefordert\nFahrer ist unterwegs',
        ['pickup_arriving'] = 'Abholfahrer kommt in ~%s Minuten an',
        ['pickup_arrived'] = 'Fahrer eingetroffen\nFahrzeug wird vorbereitet',
        ['pickup_complete'] = '🏠 Fahrzeug sicher in Garage verstaut',
        
        -- Error Messages
        ['no_vehicle_found'] = 'Kein Fahrzeug gefunden',
        ['vehicle_too_far'] = 'Fahrzeug zu weit vom Abholort entfernt',
        ['already_active'] = 'Service bereits aktiv',
        ['service_cancelled'] = 'Service abgebrochen',
        ['insufficient_funds'] = 'Nicht genug Geld! Benötigt: $%s',
        ['payment_success'] = 'Zahlung von $%s erfolgreich verarbeitet',
        ['not_owner'] = 'Du bist nicht der Besitzer',
        ['vehicle_model_load_failed'] = 'Fahrzeugmodell konnte nicht geladen werden',
        ['vehicle_spawn_failed'] = 'Fahrzeug konnte nicht gespawnt werden',
        ['driver_spawn_failed'] = 'Fahrer konnte nicht gespawnt werden',
        ['driver_enter_failed'] = 'Fahrer konnte nicht einsteigen',
        ['service_timeout'] = 'Service-Zeitüberschreitung',
        ['not_in_vehicle'] = 'Du sitzt in keinem Fahrzeug',
        
        -- UI Labels
        ['menu_title'] = '🚘 Premium Fahrzeugservice',
        ['request_delivery'] = 'Lieferung anfordern',
        ['request_pickup'] = 'Abholung anfordern',
        ['model'] = 'Modell',
        ['plate'] = 'Kennzeichen',
        ['location'] = 'Standort',
        ['garage'] = 'Garage',
        ['error'] = 'Fehler',
        ['success'] = 'Erfolg',
        ['enjoy_your_vehicle'] = 'Viel Spaß mit deinem Fahrzeug! 🚗💨',
        ['vehicle_stored'] = 'Fahrzeug in Garage verstaut',
        ['driver_blip_name'] = '🚗 Fahrzeugservice-Fahrer',
        ['minutes'] = 'Minuten',
        
        -- Feature Descriptions
        ['ultra_realistic_delivery'] = '🌟 Ultra-realistische Lieferung\nFlüssige Animationen & synchronisierte Aktionen',
        ['convenient_pickup'] = '📦 Bequemer Abholservice\nSchnell, sicher und unkompliziert',
        
        -- Menu Metadata
        ['delivery_cost'] = 'Lieferkosten',
        ['pickup_cost'] = 'Abholkosten',
        ['vehicle_class'] = 'Fahrzeugklasse',
        ['estimated_time'] = 'Geschätzte Zeit',
    }
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 💰 PRICING (Realistic Economy)
-- ═══════════════════════════════════════════════════════════════════════════
Config.DeliveryCost = 750  -- Cost to deliver a vehicle to player
Config.PickupCost = 500    -- Cost to pickup and store a vehicle

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚗 DRIVER & VEHICLE SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════
Config.DriverModels = {
    `s_m_m_valet_01`,        -- Valet (premium look)
    `s_m_m_movprem_01`,      -- Movie Premium
    `s_m_m_pilot_01`,        -- Pilot (professional)
    `s_m_y_dealer_01`,       -- Dealer
    `s_m_m_autoshop_01`,     -- Auto Shop Worker 1
    `s_m_m_autoshop_02`,     -- Auto Shop Worker 2
    `a_m_m_business_01`,     -- Business Man
    `a_m_y_business_01`,     -- Young Business
    `a_m_y_vinewood_01`,     -- Vinewood Guy
}

Config.SpawnDistance = 200.0      -- Distance from player to spawn vehicle (meters)
Config.ParkOffset = 2.0           -- Parking offset near player (meters)
Config.SpawnHeightOffset = 1.0    -- Height offset for spawn position (meters)
Config.DrivingSpeed = 15.0        -- Driver speed in m/s (realistic city driving)
Config.DrivingStyle = 786603      -- Realistic driving style flags

-- ═══════════════════════════════════════════════════════════════════════════
-- ⏱️ TIMINGS (Ultra-Realistic Service Flow)
-- ═══════════════════════════════════════════════════════════════════════════
Config.Timings = {
    driverParkDelay = 4000,         -- Time for driver to park carefully (ms)
    driverExitDelay = 2500,         -- Time for driver to exit vehicle (ms)
    keyHandoverDelay = 3000,        -- Time for key handover animation (ms)
    driverWanderDelay = 15000,      -- Time before driver despawns after delivery (ms)
    cleanupDelay = 30000,           -- Time to cleanup entities (ms)
    serviceTimeout = 600,           -- Service timeout in seconds (10 minutes)
    phoneAnimation = 3000,          -- Phone animation duration (ms)
    blipUpdateInterval = 300,       -- Blip position update interval (ms)
    stateUpdateInterval = 500,      -- Statebag update interval (ms)
    arrivalNotifyDistance = 50.0,   -- Distance to notify "arriving soon" (meters)
    completionDistance = 15.0,      -- Distance to complete delivery (meters)
    pickupCompletionDistance = 5.0, -- Distance to complete pickup (meters)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 UI & VISUAL EFFECTS
-- ═══════════════════════════════════════════════════════════════════════════
Config.UI = {
    menuTitle = '🚘 Premium Vehicle Service',
    menuWidth = 500,
    menuPosition = 'top-right',
    
    icons = {
        delivery = 'car-side',
        pickup = 'truck-pickup',
        money = 'dollar-sign',
        success = 'circle-check',
        error = 'circle-xmark',
        warning = 'triangle-exclamation',
        info = 'circle-info',
        phone = 'phone-volume',
        key = 'key',
        garage = 'warehouse',
    },
    
    colors = {
        delivery = '#3b82f6',    -- Blue
        pickup = '#10b981',      -- Green
        error = '#ef4444',       -- Red
        warning = '#f59e0b',     -- Orange
        success = '#22c55e',     -- Green
        info = '#06b6d4',        -- Cyan
    },
}

Config.Effects = {
    enableParticles = true,         -- Show particle effects on arrival
    enableSounds = true,            -- Play sound effects
    enableBlipAnimation = true,     -- Animated blips with pulse effect
    enableProgressBars = true,      -- Show progress bars for actions
    enablePhoneAnimation = true,    -- Show phone animation during call
}

Config.Sounds = {
    enabled = true,
    
    keyHandover = {
        name = 'CONFIRM_BEEP',
        set = 'HUD_MINI_GAME_SOUNDSET',
        volume = 0.4,
    },
    
    vehicleArrived = {
        name = 'CAR_HORN_HOLD',
        set = 'VEHICLES_HORNS_SOUNDSET',
        volume = 0.3,
    },
    
    vehicleDeparted = {
        name = 'CAR_HORN_HOLD',
        set = 'VEHICLES_HORNS_SOUNDSET',
        volume = 0.2,
    },
    
    serviceRequest = {
        name = 'CONFIRM_BEEP',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        volume = 0.3,
    },
    
    error = {
        name = 'CANCEL',
        set = 'HUD_FRONTEND_DEFAULT_SOUNDSET',
        volume = 0.4,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 BLIP CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════
Config.Blips = {
    delivery = {
        sprite = 523,           -- Car icon
        color = 69,             -- Light Blue
        scale = 0.6,
        flash = false,
        route = true,
        routeColor = 26,
    },
    
    pickup = {
        sprite = 50,            -- Waypoint icon
        color = 25,             -- Green
        scale = 0.85,
        flash = false,
        route = true,
        routeColor = 25,
    },
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🗄️ DATABASE CONFIGURATION
-- ═══════════════════════════════════════════════════════════════════════════
Config.Database = {
    vehicleTable = 'vehicles',      -- Your vehicles table
    plateColumn = 'plate',          -- License plate column
    ownerColumn = 'owner',          -- Owner ID column
    storedColumn = 'stored',        -- Garage/Impound status column
    modelColumn = 'model',          -- Vehicle model column
    dataColumn = 'data',            -- Vehicle properties (JSON) column
}

Config.DefaultGarage = 'legion_garage'  -- Default garage for vehicle storage

-- ═══════════════════════════════════════════════════════════════════════════
-- 🔧 ADVANCED SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════
Config.Advanced = {
    useStateBags = true,             -- Sync vehicle properties via statebags (recommended)
    driverInvincible = true,         -- Driver cannot be killed
    deleteVehicleOnPickup = true,    -- Delete vehicle after pickup completion
    useNavmeshForSpawn = true,       -- Use navmesh for spawn positions (better roads)
    maxSpawnAttempts = 25,           -- Max attempts to find valid spawn position
    vehicleGroundCheck = true,       -- Ensure vehicle is on ground after spawn
    networkOwnership = true,         -- Transfer network ownership to player
    setVehicleAsNoLongerNeeded = true, -- Optimize cleanup
    enableDriverWander = true,       -- Driver walks away after delivery
    propertyApplicationRetries = 3,  -- How many times to retry property application
    propertyApplicationDelays = {100, 500, 1000}, -- Delays between retries (ms)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🛡️ SECURITY SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════
Config.Security = {
    maxActiveServicesPerPlayer = 1,  -- Maximum concurrent services per player
    enableAntiSpam = true,            -- Prevent service request spam
    spamCooldown = 5000,              -- Cooldown between requests (ms)
    validateOwnership = true,         -- Validate vehicle ownership
    enableServerCallbacks = true,     -- Use server callbacks for security
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 📊 STATISTICS & MONITORING
-- ═══════════════════════════════════════════════════════════════════════════
Config.Statistics = {
    enabled = true,                   -- Track service statistics
    trackDeliveries = true,           -- Track delivery count
    trackPickups = true,              -- Track pickup count
    trackRevenue = true,              -- Track total revenue
    trackErrors = true,               -- Track error count
    adminCommands = true,             -- Enable admin commands for stats
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🐛 DEBUG SETTINGS
-- ═══════════════════════════════════════════════════════════════════════════
Config.Debug = false  -- Enable debug logging (set to false in production!)

Config.DebugOptions = {
    logPropertyLoading = true,        -- Log vehicle property loading
    logStatebagApplication = true,    -- Log statebag operations
    logSpawning = true,               -- Log entity spawning
    logCleanup = true,                -- Log cleanup operations
    logMoneyTransactions = true,      -- Log money transactions
    logDatabaseQueries = false,       -- Log database queries (verbose!)
    logServiceLifecycle = true,       -- Log service start/completion
    showTestMarkers = false,          -- Show debug markers (spawn positions, etc.)
    printVehicleProperties = false,   -- Print full property table (very verbose!)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎮 KEYBINDS (Optional)
-- ═══════════════════════════════════════════════════════════════════════════
Config.Keybinds = {
    openMenu = 'F7',                  -- Default keybind to open menu (or use command)
    cancelService = 'X',              -- Cancel active service (not implemented yet)
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎨 VEHICLE CLASS ICONS (for menu display)
-- ═══════════════════════════════════════════════════════════════════════════
Config.VehicleClassIcons = {
    [0] = '🚗',   -- Compacts
    [1] = '🏎️',   -- Sedans
    [2] = '🚙',   -- SUVs
    [3] = '🚐',   -- Coupes
    [4] = '🚗',   -- Muscle
    [5] = '🏍️',   -- Sports Classics
    [6] = '🚙',   -- Sports
    [7] = '🏍️',   -- Super
    [8] = '🏍️',   -- Motorcycles
    [9] = '🏍️',   -- Off-road
    [10] = '🚁',  -- Industrial
    [11] = '🚗',  -- Utility
    [12] = '🚗',  -- Vans
    [13] = '🏍️',  -- Cycles
    [14] = '⛵',  -- Boats
    [15] = '🚁',  -- Helicopters
    [16] = '✈️',  -- Planes
    [17] = '🚙',  -- Service
    [18] = '🚙',  -- Emergency
    [19] = '🚙',  -- Military
    [20] = '🚙',  -- Commercial
    [21] = '🚂',  -- Trains
    [22] = '🏍️',  -- Open Wheel
}

-- ═══════════════════════════════════════════════════════════════════════════
-- 🎯 HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════

---Get localized text
---@param key string
---@param ... any
---@return string
function L(key, ...)
    local locale = Config.Translations[Config.Locale] or Config.Translations['en']
    local text = locale[key] or key
    if ... then 
        return string.format(text, ...) 
    end
    return text
end

---Get config value with default fallback
---@param path string|table
---@param default any
---@return any
function GetConfigValue(path, default)
    if type(path) == 'string' then
        return Config[path] ~= nil and Config[path] or default
    end
    
    if type(path) == 'table' then
        local value = Config
        for _, key in ipairs(path) do
            if value and type(value) == 'table' then
                value = value[key]
            else
                return default
            end
        end
        return value ~= nil and value or default
    end
    
    return default
end

---Get vehicle class icon
---@param vehicleClass number
---@return string
function GetVehicleClassIcon(vehicleClass)
    return Config.VehicleClassIcons[vehicleClass] or '🚗'
end

-- ═══════════════════════════════════════════════════════════════════════════
-- 🚀 INITIALIZATION LOG
-- ═══════════════════════════════════════════════════════════════════════════
if Config.Debug then
    print('^2═══════════════════════════════════════════════════^7')
    print('^2   RDE Car Service - Configuration Loaded^7')
    print('^2═══════════════════════════════════════════════════^7')
    print(string.format('^3Language: ^7%s', Config.Locale))
    print(string.format('^3Delivery Cost: ^7$%d', Config.DeliveryCost))
    print(string.format('^3Pickup Cost: ^7$%d', Config.PickupCost))
    print(string.format('^3Spawn Distance: ^7%.1fm', Config.SpawnDistance))
    print(string.format('^3Effects Enabled: ^7%s', Config.Effects.enableParticles and 'Yes' or 'No'))
    print(string.format('^3Sounds Enabled: ^7%s', Config.Effects.enableSounds and 'Yes' or 'No'))
    print(string.format('^3Debug Mode: ^7%s', Config.Debug and 'ON' or 'OFF'))
    print('^2═══════════════════════════════════════════════════^7')
end

return Config