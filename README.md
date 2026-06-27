# 🚗 RDE Car Service — Vehicle Delivery & Pickup System

[![Version](https://img.shields.io/badge/version-1.1.0-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_carservice)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](./LICENSE)
[![Framework](https://img.shields.io/badge/Framework-ox__core-blue?style=for-the-badge)](https://github.com/overextended/ox_core)
[![ox_lib](https://img.shields.io/badge/UI-ox__lib-purple?style=for-the-badge)](https://github.com/overextended/ox_lib)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![Free](https://img.shields.io/badge/Price-FREE%20FOREVER-green?style=for-the-badge)](https://github.com/RedDragonElite)
[![Status](https://img.shields.io/badge/status-STABLE-brightgreen?style=for-the-badge)](https://github.com/RedDragonElite/rde_carservice)
[![Ecosystem](https://img.shields.io/badge/RDE%20Ecosystem-rde__parking-orange?style=for-the-badge)](https://github.com/RedDragonElite/rde_parking)

<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/1f974250-1b15-46d7-b074-0dbc0680ecf8" />

> **Ultra-realistic vehicle valet service with professional AI drivers, full property preservation, cinematic animations — and full integration with `rde_parking` as part of the RDE ecosystem.**
> Built by [Red Dragon Elite](https://rd-elite.com) — Free Forever. No Paywalls. No Gatekeepers.

> 🤝 **RDE Ecosystem:** `rde_carservice` and [`rde_parking`](https://github.com/RedDragonElite/rde_parking) are designed to work together. Call carservice on a parked vehicle — it auto-unparks it and delivers it seamlessly. Pick it up via carservice — the parking entry is gone. Get it delivered — all parking options reset instantly. Two scripts, one coherent system, zero conflicts.

---

## 🔥 What is rde_carservice?

**rde_carservice** is a complete, production-ready vehicle delivery and pickup system for FiveM servers running **ox_core**. Request professional valet drivers to deliver your stored vehicles directly to your location, or have them picked up and safely stored in your garage. Every customization, every modification — perfectly preserved via dual-path property sync.

### Why this changes everything

| ❌ Generic Scripts | ✅ rde_carservice |
|---|---|
| Partial property preservation | ✅ 100% — mods, colors, neon, extras |
| No AI drivers | ✅ 9 driver models, traffic-aware |
| No animations | ✅ Phone call, parking, key handover |
| Legacy framework dependency | ✅ Pure ox_core — zero legacy code |
| Properties lost on spawn | ✅ Race-proof dual-path sync (owner-direct + statebag broadcast) |
| No security | ✅ Ownership validation, rate limiting, stored-state enforcement |
| Conflicts silently with parking scripts | ✅ Full rde_parking integration — bidirectional event sync, zero conflicts |

---

## 📋 Changelog

### v1.1.0 — rde_parking Integration

> **Full bidirectional integration with `rde_parking` v1.1.1+.** Two silent cross-resource bugs that existed when both scripts ran on the same server are now completely fixed via a cross-event sync architecture. Neither resource requires the other — both degrade gracefully without errors if only one is installed.

**🔴 The bugs (both fixed)**

**Bug 1 — Duplicate entity / disappearing parked vehicle.** When a vehicle was parked via rde_parking, it set `vehicles.stored = 'parked'`. rde_carservice read `stored IS NOT NULL` as "vehicle is in a garage, ready to deliver" and spawned a second entity for the same plate. GTA V deleted one of the two entities sharing the same plate — the parked vehicle vanished, and the delivered one showed up without its mods because ownership tracking was confused.

**Bug 2 — "Not your vehicle" / can't park after delivery.** After rde_carservice delivered a vehicle, the client's `parkedCache[plate]` inside rde_parking was still `true` from the previous parking session. `IsParkedLocally()` returned `true`, silently blocking `ParkVehicle()`. The ox_target "Park Vehicle" option disappeared; "Retrieve Vehicle" showed instead — neither worked correctly.

**🔧 The fixes**

- **`requestDelivery` (server):** detects vehicles parked via rde_parking and instead of blocking, performs an **auto-unpark delivery**: fetches props from `rde_parked_vehicles`, validates ownership server-side, deducts money, fires `rde_carservice:prepareDeliveryOfParked` → rde_parking clears DB + parkIndex + notifies client cache (entity stays alive, proximity despawn handles it after `despawnGraceMs`), then proceeds with normal NPC delivery. Also adds `AND stored != 'rde_parking'` to the garage SQL as belt-and-suspenders.
- **`completeDelivery` (server):** fires `TriggerEvent('rde_carservice:vehicleDelivered', source, plate)` — rde_parking clears any residual state.
- **`completePickup` (server):** fires `TriggerEvent('rde_carservice:vehiclePickedUp', source, plate)` — rde_parking removes stale `rde_parked_vehicles` row, preventing re-spawn on next proximity sweep.

### v1.0.2 — Race Condition Hardening & Defense-in-Depth Sync

> **Tested in live multiplayer.** All vehicles arrive with full mods every time, across multiple consecutive deliveries, with multiple players online.

**🔴 The races (both fixed)**

1. **Server-side network entity registration race.** When a client calls `CreateVehicle(...networked=true)`, the client receives a `netId` immediately and triggers `rde_carservice:vehicleSpawned` — but the server registers that `netId` only after the client's network announcement packet arrives (50–300 ms lag). `NetworkGetEntityFromNetworkId(netId)` returned `0`, the statebag was never set, mods were silently dropped. Near-100% repro on lower-tickrate servers.

2. **Client-side statebag handler entity-not-streamed race.** `AddStateBagChangeHandler` can fire before the entity is fully synced on the receiving client — `GetEntityFromStateBagName()` returned `0`. The v1.0.1 handler bailed with an early `return`, and **the handler only fires once per state change**, so the apply was permanently lost.

**🔧 The fixes**

- **Server (`setVehiclePropertiesStatebag`):** retry loop, up to 50 × 100 ms, waits for `NetworkGetEntityFromNetworkId` to return a valid entity.
- **Client (`AddStateBagChangeHandler`):** entity-existence check inside `CreateThread`, retrying up to 5 s for streaming to complete.
- **Client (`deliverVehicle`):** properties applied **directly** via `lib.setVehicleProperties()` on the owning client immediately after `CreateVehicle()`. Statebag flow continues as redundant safety net for late-joiners and re-stream events. Both paths are idempotent.

**🛡️ Bonus hardening**

- `Config.Debug = Config.Debug or true` evaluated to `true` even when explicitly set to `false` — fixed with explicit nil-check.
- Delivery callback now requires `AND stored IS NOT NULL` — money is never deducted for vehicles not in a garage.
- `getValidModel` returns `nil` instead of `0` for empty strings.
- `source` captured locally across all event handlers — yield-safe.

### v1.0.1 — Statebag Property Sync Rewrite
- Replaced 3 sequential `applyVehicleProperties()` attempts with a clean statebag-based flow on an RDE-owned key (`rde:vehicleProperties`).
- Server-authoritative property loading and write; client reacts via `AddStateBagChangeHandler`.

### v1.0.0 — Initial Release
- Delivery and pickup system, ox_core native, full property extraction (5-method), animated blips, phone animations, ox_target integration.

---

## ✨ Features

### 🚘 Vehicle Delivery System

**Intelligent Spawn System**
- Spawns 200 m from player on actual roads
- 25-iteration pathfinding for perfect road placement
- Ground level verification & collision detection
- Navmesh-based road snapping

**Professional Drivers**
- 9 realistic driver models (valet, pilot, business)
- Follows traffic laws and signals
- Realistic parking sequences with precision timing
- Natural walk-away behavior after handover

**Full Property Preservation — Race-Proof**
- Engine, brakes, transmission upgrades
- All visual mods (bumpers, spoilers, exhausts)
- Custom colors & paint jobs
- Neon lights, window tints, wheels
- Extras (turbo, xenon headlights)
- 5-method extraction for ox_core compatibility
- **Dual-path application** — owner-side direct apply for instant first-paint correctness, statebag broadcast for cross-client + late-joiner consistency

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

### 🔗 rde_parking Integration (v1.1.0+)
- Vehicles parked via rde_parking are **automatically unparked and delivered** — the entity at the parking spot despawns, an NPC driver brings the car to the player. Zero friction, no "go retrieve it yourself"
- Cross-event state sync on delivery and pickup — rde_parking's client cache always reflects current reality
- Graceful degradation if rde_parking is not installed — zero errors, zero config changes needed

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
- Money never deducted for vehicles not actually in a garage

### 🔒 Security & Performance
- Database ownership validation before any operation
- `stored IS NOT NULL` enforcement at request time — no charging for in-world vehicles
- `stored != 'rde_parking'` exclusion — no delivering a live world entity managed by rde_parking
- Anti-spam: active service lock per player
- 10-minute service timeout with automatic cleanup
- `rde_carservice:vehicleSpawned` validated against `activeServices` — clients cannot trigger statebag writes for vehicles they don't own
- `source` captured locally across all event handlers — yield-safe
- Optimized threads with dynamic cleanup

---

## 📦 Dependencies

```
# server.cfg — CRITICAL: start in this exact order!
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_target
ensure rde_parking    # optional — enables full cross-system integration
ensure rde_carservice
```

| Dependency | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Database layer |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, notifications, `lib.setVehicleProperties` |
| [ox_target](https://github.com/communityox/ox_target) | ⚠️ Optional | Right-click vehicle pickup |
| [rde_parking](https://github.com/RedDragonElite/rde_parking) | ⭕ Optional | Full bidirectional parking integration (requires rde_parking ≥ v1.1.1) |

> **Note:** rde_carservice requires FiveM server build `≥ 7290` — statebag broadcasting and `AddStateBagChangeHandler` require OneSync and modern server builds.

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
ensure ox_target        # optional
ensure rde_parking      # optional — install before rde_carservice for full integration
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

> **Note for rde_parking users:** rde_parking v1.1.1 writes `stored = 'rde_parking'` for vehicles it manages. rde_carservice v1.1.0 explicitly excludes this value from all delivery queries — no manual DB changes required.

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

## 🔗 rde_parking Integration

rde_carservice v1.1.0 introduces full bidirectional integration with `rde_parking` (requires `rde_parking` ≥ v1.1.1). Both resources are optional to each other — if either isn't running, the other degrades gracefully with no errors.

### The Problem It Solves

Without integration, two silent bugs existed when both scripts ran on the same server:

**Bug 1 — Duplicate entity / disappearing parked vehicle:** rde_parking set `vehicles.stored = 'parked'`. rde_carservice read `stored IS NOT NULL` as "in garage" and spawned a second entity for the same plate. GTA V removed the older one — the parked vehicle vanished with no error.

**Bug 2 — Can't park delivered vehicle / "not your vehicle":** After delivery, rde_parking's client-side `parkedCache[plate]` was still `true`. `IsParkedLocally()` blocked `ParkVehicle()` silently. The player saw the wrong ox_target option and could not re-park their vehicle.

### How It Works

```
Park via rde_parking (v1.1.1+)
  └─ UPDATE vehicles SET stored = 'rde_parking'

rde_carservice Delivery of a PARKED vehicle (auto-unpark flow)
  └─ requestDelivery: plate found in rde_parked_vehicles (ownership verified via JOIN)
  └─ Money checked + deducted
  └─ TriggerEvent('rde_carservice:prepareDeliveryOfParked', source, plate)
  └─ rde_parking server:
       ├─ DELETE FROM rde_parked_vehicles WHERE plate = ?   (DB cleared — no re-spawn)
       ├─ State.parkIndex[id] = nil                          (removed from spawn candidates)
       ├─ State.spawnedVehicles[id] kept → entity stays alive, handled by proximity despawn
       └─ TriggerClientEvent('rde_parking:clearParkedCache', source, plate)
  └─ rde_parking client: State.parkedCache[plate] = nil
  └─ UPDATE vehicles SET stored = NULL (in transit)
  └─ Return vehicleData → NPC driver delivers car to player ✅
  └─ Old entity at parking spot: proximity despawn removes it after 30s with no players nearby

rde_carservice Delivery from GARAGE (normal flow)
  └─ requestDelivery: SQL WHERE stored IS NOT NULL AND stored != 'rde_parking'
  └─ Normal NPC delivery → completeDelivery fires vehicleDelivered event (no-op) ✅

rde_carservice Pickup (world → garage)
  └─ completePickup → UPDATE stored = DefaultGarage
  └─ TriggerEvent('rde_carservice:vehiclePickedUp', source, plate)
  └─ rde_parking: ClearParkedByPlate → stale DB row removed, no re-spawn on next sweep ✅
```

### Integration Checklist

| | Check |
|---|---|
| `rde_carservice` ≥ v1.1.0 | ✅ This release |
| `rde_parking` ≥ v1.1.1 | Required for the parking side of the events |
| `rde_parking` before `rde_carservice` in server.cfg | Ensures `GetResourceState('rde_parking')` resolves correctly |
| No config changes needed | Integration is automatic, zero config |

---

## 📡 Property Sync — How It Works (v1.0.2 Architecture)

Vehicle property sync uses a **dual-path** architecture: direct apply on the owning client for immediate visual correctness, statebag broadcast for cross-client + late-joiner consistency.

### The flow

```
┌─────────────────────────────────────────────────────────────────────┐
│  1. CLIENT → SERVER       lib.callback.await('requestDelivery')     │
│  2. SERVER                 Load properties from DB                  │
│                            Stash in activeServices[source]          │
│                            Return vehicleData to client             │
│  3. CLIENT                 CreateVehicle(...networked=true)         │
│  4. CLIENT  [PATH A]       lib.setVehicleProperties(veh, props)  ←─ instant
│  5. CLIENT → SERVER        TriggerServerEvent('vehicleSpawned')     │
│  6. SERVER  [PATH B]       Validate against activeServices          │
│                            Retry NetworkGetEntityFromNetworkId      │
│                            Entity(veh).state:set(..., true)      ←─ broadcast
│  7. ALL CLIENTS IN SCOPE   AddStateBagChangeHandler fires           │
│                            Wait for entity to stream (≤5s)          │
│                            lib.setVehicleProperties(veh, value)     │
└─────────────────────────────────────────────────────────────────────┘
```

**Path A — Owner-side direct apply:** The client that called `CreateVehicle` owns the entity. Properties are applied immediately via `lib.setVehicleProperties()`. RAGE's native entity sync broadcasts the mod state to nearby clients.

**Path B — Server statebag broadcast:** The server validates the `vehicleSpawned` event against `activeServices`, retries `NetworkGetEntityFromNetworkId` up to 5 s, then writes `Entity(vehicle).state:set('rde:vehicleProperties', properties, true)`. Every client in scope reacts via `AddStateBagChangeHandler` — including late joiners and re-stream events.

Both paths are **idempotent** — applying the same property table twice is a no-op.

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

**If your vehicle is parked via rde_parking:** Just call carservice as normal — the parked entity at the spot is automatically despawned and the NPC driver delivers the car to your location. No manual retrieval needed.

---

## 🔧 Developer API

### Server Events (fired, listen from other resources)

```lua
-- Fired by rde_carservice after a successful delivery (garage → world)
-- rde_parking v1.1.1 listens to this automatically
AddEventHandler('rde_carservice:vehicleDelivered', function(source, plate) ... end)

-- Fired by rde_carservice after a successful pickup (world → garage)
-- rde_parking v1.1.1 listens to this automatically
AddEventHandler('rde_carservice:vehiclePickedUp', function(source, plate) ... end)
```

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

### Error Codes Returned by Callbacks

| Code | Meaning |
|---|---|
| `player_not_found` | ox_core didn't return a valid player for the source |
| `already_active` | This player already has an active delivery/pickup |
| `invalid_plate` | Plate was nil or empty |
| `vehicle_not_stored` | Vehicle exists but `stored IS NULL` — not in a garage |
| `vehicle_is_parked` | Reserved — not returned in normal flow (auto-unpark handles it seamlessly) |
| `invalid_netid` | netId argument was nil/0 |
| `vehicle_not_found` | netId did not resolve to an entity |
| `no_plate` | Vehicle entity has no plate text |
| `not_owner` | Vehicle owner does not match the requester's charId |
| `insufficient_funds` | Player doesn't have enough money for the operation |
| `account_error` | Money deduction failed at the DB layer |
| `database_error` | Generic MySQL query failure |

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
├─ Idle:    0.01 ms (no active services)
├─ Active:  0.03–0.05 ms (delivery in progress)
├─ Memory:  ~2.5 MB baseline
├─ Threads: Dynamic — cleaned up after completion
└─ Network: Minimal — statebag set once on spawn, no polling
```

Optimization features: async model loading, automatic entity cleanup, prepared SQL statements, smart thread management, event-driven statebag property application, idempotent dual-path sync.

---

## 📁 File Structure

```
rde_carservice/
├── fxmanifest.lua      ← Resource manifest (requires build 7290)
├── config.lua          ← All configuration + EN/DE locales
├── client.lua          ← Spawn logic, driver AI, direct apply, statebag handler, UI
├── server.lua          ← Callbacks, DB, money, statebag write with retry, security, rde_parking integration
├── phone_app.lua       ← NPWD Phone App bridge (optional)
├── LICENSE             ← RDE Black Flag Source License v6.66
└── README.md           ← You are here
```

---

## 🐛 Troubleshooting

**Vehicle properties not applying?**
Enable `Config.Debug = true` and check both consoles. In v1.0.2+ you should see:
- Client: `🔧 Direct apply on owner: true` (Path A succeeded)
- Server: `📡 Statebag rde:vehicleProperties set for netId N` (Path B succeeded)
- All clients in scope: `✅ Properties applied via statebag for entity N`

If server logs `entity never appeared for netId N after 5s` → extreme server load or OneSync issue. Path A still succeeded for the owner.

**Parked vehicle disappeared but no NPC arrived?**
Enable `Config.Debug = true` in rde_parking. Check server console for `rde_carservice:prepareDeliveryOfParked` and `prepareDeliveryOfParked: DB cleared for plate=...` — this confirms the unpark side is working. Then check carservice client console for `Auto-unpark delivery started` and `vehicleSpawned`. If the entity despawned but no driver appeared, check for model-loading errors in client console.

**After carservice delivery, can't park the vehicle / wrong ox_target option showing?**
Ensure both `rde_parking` ≥ v1.1.1 and `rde_carservice` ≥ v1.1.0 are installed and running. The `rde_parking:clearParkedCache` client event fires via `prepareDeliveryOfParked` — enable `Config.Debug` in rde_parking and check for the `DB cleared for plate=...` log line.

**Parked vehicle disappeared when calling carservice?**
This was the duplicate-entity bug fixed in v1.1.0. Update both `rde_carservice` and `rde_parking` to the latest versions.

**Driver not spawning?**
Check console for model loading errors. Ensure all configured ped models are valid GTA V model names.

**Money deducting twice / not deducting?**
Verify the `character_inventory` table structure. Money is only deducted after the `stored IS NOT NULL` check passes.

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
| 🅿️ RDE Parking | [rde_parking](https://github.com/RedDragonElite/rde_parking) |
| ⚡ rde_nostr_log | [Decentralized Logging](https://github.com/RedDragonElite/rde_nostr_log) |
| 💀 RDE AIMD | [rde_aimd](https://github.com/RedDragonElite/rde_aimd) |
| 📖 OX Standards | [rde_ox_standards](https://github.com/RedDragonElite/rde_ox_standards) |

---

> *"We build the future on the graves of paid resources."*
> **REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**
> 🐍🔥🖤 **RDE FOREVER. SYSTEM FAILURE.** ⚡777⚡
