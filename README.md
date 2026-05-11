# 🚗 RDE Car Service — Vehicle Delivery & Pickup System

[![Version](https://img.shields.io/badge/version-1.0.1-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_carservice)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](./LICENSE)
[![Framework](https://img.shields.io/badge/Framework-ox__core-blue?style=for-the-badge)](https://github.com/overextended/ox_core)
[![ox_lib](https://img.shields.io/badge/UI-ox__lib-purple?style=for-the-badge)](https://github.com/overextended/ox_lib)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![Free](https://img.shields.io/badge/Price-FREE%20FOREVER-green?style=for-the-badge)](https://github.com/RedDragonElite)
[![Status](https://img.shields.io/badge/status-STABLE-brightgreen?style=for-the-badge)](https://github.com/RedDragonElite/rde_carservice)

<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/1f974250-1b15-46d7-b074-0dbc0680ecf8" />

> **Ultra-realistic vehicle valet service with professional AI drivers, full property preservation, and cinematic animations.**
> Built by [Red Dragon Elite](https://rd-elite.com) — Free Forever. No Paywalls. No Gatekeepers.

---

## 🔥 What is rde_carservice?

**rde_carservice** is a complete, production-ready vehicle delivery and pickup system for FiveM servers running **ox_core**. Request professional valet drivers to deliver your stored vehicles directly to your location, or have them picked up and safely stored in your garage. Every customization, every modification — perfectly preserved via statebag sync.

### Why this changes everything

| ❌ Generic Scripts | ✅ rde_carservice |
|---|---|
| Partial property preservation | ✅ 100% — mods, colors, neon, extras |
| No AI drivers | ✅ 9 driver models, traffic-aware |
| No animations | ✅ Phone call, parking, key handover |
| Legacy framework dependency | ✅ Pure ox_core — zero legacy code |
| Properties lost on spawn | ✅ Server-authoritative statebag sync |
| No security | ✅ Ownership validation, rate limiting |

---

## 📋 Changelog

### v1.0.1 — Statebag Property Sync Rewrite
- **FIX: Vehicle properties (mods, colors, neon) not applying after delivery**
  The original code ran 3 sequential `applyVehicleProperties()` attempts client-side (with `Wait(500)` / `Wait(1000)` delays) plus a `TriggerServerEvent` that called `Entity.state:set('ox_lib:setVehicleProperties', ...)` — an internal ox_lib key that cannot be set externally, causing silent failures. A fourth attempt ran again on driver arrival. This was race-condition chaos with no guaranteed outcome.
  **Now:** Client spawns vehicle → reports `netId` to server via `rde_carservice:vehicleSpawned` → server validates against `activeServices` (security) → sets `Entity(vehicle).state:set('rde:vehicleProperties', properties, true)` — a clean RDE-owned key with `broadcast = true`. `AddStateBagChangeHandler('rde:vehicleProperties', ...)` on the client reacts exactly once, waits `250ms` for the entity to fully stream, then calls `lib.setVehicleProperties()`. Single path. Server is source of truth. Zero retry loops.
- **Verified working in multiplayer** — all connected clients receive the statebag broadcast and see correct vehicle properties.

### v1.0.0
- Initial release — delivery and pickup system, ox_core native, full property extraction (5-method), animated blips, phone animations, ox_target integration

---

## ✨ Features

### 🚘 Vehicle Delivery System

**Intelligent Spawn System**
- Spawns 200m from player on actual roads
- 25-iteration pathfinding for perfect road placement
- Ground level verification & collision detection
- Navmesh-based road snapping

**Professional Drivers**
- 9 realistic driver models (valet, pilot, business)
- Follows traffic laws and signals
- Realistic parking sequences with precision timing
- Natural walk-away behavior after handover

**Full Property Preservation**
- Engine, brakes, transmission upgrades
- All visual mods (bumpers, spoilers, exhausts)
- Custom colors & paint jobs
- Neon lights, window tints, wheels
- Extras (turbo, xenon headlights)
- 5-method extraction for ox_core compatibility
- **Server-authoritative statebag sync** — properties applied once, correctly, every time

**Cinematic Experience**
- Phone call animations with props
- 4-second precision parking sequence
- 3-second key handover animation
- Particle effects on arrival

### 📞 Vehicle Pickup System
- On-demand retrieval via right-click (ox_target) or menu
- AI driver navigates to the vehicle's exact location
- Automatic storage in configured garage
- Complete entity cleanup after completion

### 🎨 UI / UX
- ox_lib context menus — clean, responsive vehicle selection
- Animated pulsating blips with route paths
- Progress bars for phone calls and actions
- Native GTA V sound effects
- 4-tier notification system (info / success / warning / error)

### 💰 Economy Integration
- Configurable pricing — Delivery: `$750`, Pickup: `$500`
- ox_inventory money deduction
- Built-in delivery / pickup / earnings statistics
- Admin command for server-side monitoring

### 🔒 Security & Performance
- Database ownership validation before any operation
- Anti-spam: active service lock per player
- 10-minute service timeout with automatic cleanup
- `rde_carservice:vehicleSpawned` validated against `activeServices` — clients cannot trigger statebag writes for vehicles they don't own
- Optimized threads with dynamic cleanup

---

## 📦 Dependencies

```
# server.cfg — CRITICAL: start in this exact order!
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target
ensure rde_carservice
```

| Dependency | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Database layer |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, notifications |
| [ox_target](https://github.com/communityox/ox_target) | ⚠️ Optional | Right-click vehicle pickup |

> **Note:** rde_carservice requires FiveM server build `≥ 7290` (declared in `fxmanifest.lua`).

---

## 🚀 Installation

```bash
# 1. Clone into your resources folder
cd resources
git clone https://github.com/RedDragonElite/rde_carservice.git
```

```cfg
# 2. Add to server.cfg

ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target      # optional
ensure rde_carservice
```

> **Order matters.** `rde_carservice` must start **after** all its dependencies.

### Database

No manual SQL import needed. Works with the existing ox_core `vehicles` table. Ensure it has these columns:

```
plate   VARCHAR  — license plate identifier
owner   INT      — character ID from ox_core
model   VARCHAR  — vehicle model hash
data    JSON     — vehicle properties (ox_core format)
stored  VARCHAR  — garage name, NULL when spawned
```

### Configure (Optional)

Edit `config.lua`:

```lua
Config.DeliveryCost   = 750              -- Delivery price
Config.PickupCost     = 500              -- Pickup price
Config.DefaultGarage  = 'legion_garage'  -- Your garage name
Config.Locale         = 'en'             -- 'en' or 'de'
Config.Debug          = false            -- Dev debug mode
```

```
# 5. Restart & Test
refresh
restart rde_carservice
```

Test with `/carservice` in-game.

---

## ⚙️ Configuration

All configuration lives in `config.lua`. Key settings:

### Pricing

```lua
Config.DeliveryCost = 750    -- Standard delivery fee
Config.PickupCost   = 500    -- Standard pickup fee
```

### Driver Models

```lua
Config.DriverModels = {
    `a_m_m_business_01`,
    `a_m_y_business_01`,
    `a_m_y_business_02`,
    `a_m_y_vinewood_01`,
}
```

### Spawn Distance

```lua
Config.SpawnDistance = 200.0   -- Meters from player
```

### Timing

```lua
Config.Timing = {
    serviceTimeout = 600,   -- Seconds before active service expires
}
```

### Effects (Performance Tuning)

```lua
Config.Effects = {
    enableParticles     = true,
    enableSounds        = true,
    enableBlipAnimation = true,
    enableProgressBars  = true,
}
```

### Driving Behavior

```lua
Config.DrivingSpeed = 15.0     -- m/s
Config.DrivingStyle = 786603   -- Traffic-aware, no red-light running
```

---

## 📡 Statebag Sync — How It Works

Vehicle property sync is server-authoritative via FiveM statebags — the same pattern used across the RDE ecosystem.

**The flow:**

1. Server receives `requestDelivery` callback — loads properties from DB, stores them in `activeServices[source]`
2. Client spawns the vehicle locally, gets the `netId`
3. Client fires `rde_carservice:vehicleSpawned(netId, plate)` to server
4. Server validates: source must have an active delivery matching that plate — rejects anything else
5. Server calls `Entity(vehicle).state:set('rde:vehicleProperties', properties, true)` — `broadcast = true` replicates to all clients
6. `AddStateBagChangeHandler('rde:vehicleProperties', ...)` fires on every client that can see the entity
7. Handler waits `250ms` for the entity to fully stream, then calls `lib.setVehicleProperties(vehicle, value)` — once, clean, done

**Why this is correct:**
- Server is always source of truth — client cannot forge or inject properties
- `rde:vehicleProperties` is an RDE-owned key — no collision with ox_lib internals
- `broadcast = true` means all players in range see the correct mods, colors, and neon
- No retry loops, no race conditions, no silent failures

---

## 🎮 Usage

### For Players

**Requesting Delivery:**
1. Type `/carservice`
2. Select your vehicle from the garage list
3. Confirm the payment
4. Watch the driver arrive and hand over the keys

**Requesting Pickup:**
1. Approach your vehicle
2. Right-click with ox_target — or open `/carservice` and select "Request Pickup"
3. Confirm the payment
4. Driver arrives, collects the vehicle, stores it in your garage

---

## 🔧 Developer API

### Callbacks

**Request Delivery**
```lua
local success, vehicleData = lib.callback.await('rde_carservice:requestDelivery', false, plate)
if success then
    -- vehicleData = { plate, model, properties }
    print('Delivery initiated:', json.encode(vehicleData))
end
```

**Request Pickup**
```lua
local netId = NetworkGetNetworkIdFromEntity(vehicle)
local success, coords = lib.callback.await('rde_carservice:requestPickup', false, netId)
```

**Cancel Active Service**
```lua
TriggerServerEvent('rde_carservice:cancelService')
```

---

## 📋 Admin Commands

| Command | Restricted | Description |
|---|---|---|
| `/carservice` | No | Opens the vehicle selection menu |
| `/carservice_stats` | `group.admin` | Prints delivery / pickup / revenue stats to console (Debug mode only) |

---

## 📊 Performance

```
Resource: rde_carservice
├─ Idle:    0.01ms  (no active services)
├─ Active:  0.03–0.05ms  (delivery in progress)
├─ Memory:  ~2.5 MB baseline
├─ Threads: Dynamic — cleaned up after completion
└─ Network: Minimal — statebag sync on spawn only, no polling
```

Optimization features: async model loading, automatic entity cleanup, prepared SQL statements, smart thread management, event-driven statebag property application.

---

## 📁 File Structure

```
rde_carservice/
├── fxmanifest.lua      ← Resource manifest (requires build 7290)
├── config.lua          ← All configuration
├── client.lua          ← Spawn logic, driver AI, statebag handler, UI
├── server.lua          ← Callbacks, DB, money, statebag write, security
├── phone_app.lua       ← Phone app integration (optional)
├── LICENSE             ← RDE Black Flag Source License v6.66
└── README.md           ← You are here
```

---

## 🐛 Troubleshooting

**Vehicle properties not applying?**
Enable `Config.Debug = true` and check server console for `📡 Statebag rde:vehicleProperties set for netId` and client console for `✅ Properties applied via statebag`. If the server log appears but the client log doesn't, the entity may not be streamed yet — `forcedArrivalDist` won't apply here, check your streaming distance settings.

**Driver not spawning?**
Check console for model loading errors. Ensure all configured ped models are valid GTA V model names.

**Money not deducting?**
Verify the `character_inventory` table structure and that the money item format matches: `{"name":"money","count":5000}`.

**Service timing out early?**
Increase `Config.Timing.serviceTimeout`. Check server performance and that the driver can pathfind to the player location.

**`No such export` errors?**
Make sure `rde_carservice` starts **after** `ox_lib`, `ox_core`, and `oxmysql` in `server.cfg`.

---

## 🗺️ Roadmap

### Planned for v2.0

- [ ] Multiple garage support — store vehicles in different locations
- [ ] Express delivery — pay extra for instant spawn
- [ ] Real-time GPS tracking of the delivery driver
- [ ] Custom driver uniforms per server
- [ ] Delivery zone restrictions
- [ ] Helicopter delivery for remote locations
- [ ] Damage compensation if driver crashes
- [ ] VIP subscription pass

Have a feature request? [Open a Discussion](https://github.com/RedDragonElite/rde_carservice/discussions).

---

## 📜 License

**RDE Black Flag Source License v6.66** — see [LICENSE](./LICENSE)

**TL;DR:**
- ✅ Free to use, edit, and learn from — forever
- ✅ Keep the header / credit the creator
- ❌ Do NOT sell this on Tebex, Patreon, or in any paid pack
- ❌ Do NOT be a skid

---

## 🌐 Community & Links

| | |
|---|---|
| 🐙 GitHub | [github.com/RedDragonElite](https://github.com/RedDragonElite) |
| 🌍 Website | [rd-elite.com](https://rd-elite.com) |
| 🔵 Nostr | [SerpentsByte](https://nostr.band/npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94) |
| ⚡ rde_nostr_log | [Decentralized Logging](https://github.com/RedDragonElite/rde_nostr_log) |
| 💀 RDE AIMD | [rde_aimd](https://github.com/RedDragonElite/rde_aimd) |
| 📖 OX Standards | [rde_ox_standards](https://github.com/RedDragonElite/rde_ox_standards) |

---

> *"We build the future on the graves of paid resources."*
> **REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**
> 🐍🔥🖤 **RDE FOREVER. SYSTEM FAILURE.** ⚡777⚡