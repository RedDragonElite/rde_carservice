-- ┌───────────────────────────────────────────────────────────────────────┐
-- │  rde_carservice — NPWD Phone Bridge  |  v1.0.0                       │
-- │  RDE | SerpentsByte | rd-elite.com                                   │
-- │                                                                       │
-- │  Läuft NACH client.lua. Koordiniert:                                  │
-- │  • Live-Status-Push an die NPWD Car Service Phone-App                 │
-- │  • Phone-Notifications bei Service-Events                             │
-- │  • Phone schließen wenn Service gestartet wird                        │
-- └───────────────────────────────────────────────────────────────────────┘

-- ─────────────────────────────────────────────────────────────────────────────
--  HELPERS
-- ─────────────────────────────────────────────────────────────────────────────

local function IsNPWDAvailable()
    return GetResourceState('npwd') == 'started'
end

local function PhoneNotify(content)
    if not IsNPWDAvailable() then return end
    pcall(function()
        exports['npwd']:createNotification({
            notisId          = 'rde_cs_' .. math.random(100000, 999999),
            appId            = 'RDE_CAR',
            content          = tostring(content),
            keepNotification = false,
            firstConnect     = false,
        })
    end)
end

-- Daten live an die React-Phone-App pushen.
-- React empfängt via: useNuiEvent('RDE_CAR', eventName, callback)
local function PushToPhoneApp(eventName, data)
    if not IsNPWDAvailable() then return end
    pcall(function()
        exports['npwd']:sendNPWDMessage('RDE_CAR', eventName, data)
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
--  STATUS PUSH HELPER
--  Wird von Service-Events aufgerufen (Server → Client NetEvents).
--  CSGetActiveService() ist in client.lua als global definiert.
-- ─────────────────────────────────────────────────────────────────────────────

local function PushStatus()
    local s = type(CSGetActiveService) == 'function' and CSGetActiveService() or {}
    PushToPhoneApp('statusUpdate', {
        active = s,
        costs  = {
            delivery = Config.DeliveryCost or 750,
            pickup   = Config.PickupCost   or 500,
        },
    })
end

-- ─────────────────────────────────────────────────────────────────────────────
--  HAKEN IN SERVICE-EVENTS
--  Bestehende NetEvents sind schon in client.lua registriert.
--  AddEventHandler kann für denselben Event mehrfach aufgerufen werden —
--  alle Handler laufen parallel → kein Konflikt.
-- ─────────────────────────────────────────────────────────────────────────────

-- Lieferung läuft — Notification + Status-Push
AddEventHandler('rde_carservice:client:serviceStarted', function()
    PhoneNotify('🚗 Lieferung gestartet — Fahrer ist unterwegs')
    PushStatus()
end)

-- Lieferung abgeschlossen
AddEventHandler('rde_carservice:client:serviceCompleted', function()
    PhoneNotify('🔑 Fahrzeug geliefert — viel Spaß!')
    PushStatus()
end)

-- Abholung abgeschlossen
AddEventHandler('rde_carservice:client:pickupCompleted', function()
    PhoneNotify('🏠 Fahrzeug sicher eingelagert')
    PushStatus()
end)

-- Service abgebrochen
AddEventHandler('rde_carservice:client:serviceCancelled', function()
    PhoneNotify('🛑 Service abgebrochen')
    PushStatus()
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  POLLING FALLBACK
--  Falls die Events nicht gefeuert werden (Edge Cases), pushen wir
--  alle 5 Sekunden den aktuellen Status zur Sicherheit.
-- ─────────────────────────────────────────────────────────────────────────────

CreateThread(function()
    Wait(3000)  -- kurz warten bis client.lua initialisiert ist
    while true do
        Wait(5000)
        if IsNPWDAvailable() then
            PushStatus()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
--  DEBUG
-- ─────────────────────────────────────────────────────────────────────────────

if Config.Debug then
    local status = IsNPWDAvailable() and '^2CONNECTED^7' or '^3NOT FOUND^7'
    print('^6[RDE CarService | NPWD Bridge]^7 Status: ' .. status)
end
