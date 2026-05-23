# 🚗 RDE Car Service — Vehicle Delivery & Pickup System

[![Version](https://img.shields.io/badge/version-1.0.2-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_carservice)
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

---

## 📋 Changelog

### v1.0.2 — Race Condition Hardening & Defense-in-Depth Sync

> **Tested in live multiplayer.** All vehicles arrive with full mods every time, across multiple consecutive deliveries, with multiple players online. The v1.0.1 statebag rewrite was architecturally clean but exposed two race conditions that caused vehicles to occasionally — and on busier servers, frequently — arrive stripped of all customizations. v1.0.2 fixes both and adds a direct apply path on the owning client as a defense-in-depth safety net.

**🔴 The races (both fixed)**

1. **Server-side network entity registration race.** When a client calls `CreateVehicle(...networked=true)`, the client receives a `netId` immediately and triggers `rde_carservice:vehicleSpawned` — but the server registers that `netId` in its network entity pool only after the client's network announcement packet arrives, which can lag by 50–300 ms depending on tick rate and network conditions. The v1.0.1 server's `NetworkGetEntityFromNetworkId(netId)` would return `0` on the first attempt, `setVehiclePropertiesStatebag` would bail with an error, the statebag was never set, and mods were silently dropped. This was the actual cause of "delivered without mods" being a near-100% repro on lower-tickrate servers.

2. **Client-side statebag handler entity-not-streamed race.** [Per official FiveM docs](https://github.com/citizenfx/fivem/blob/master/ext/native-decls/AddStateBagChangeHandler.md), `AddStateBagChangeHandler` can fire before the entity is fully synced on the receiving client — `GetEntityFromStateBagName()` returns `0`. The v1.0.1 handler bailed with an early `return` in that case, but **the handler only fires once per state change**, so the apply was permanently lost for that delivery.

**🔧 The fixes**

- **Server (`setVehiclePropertiesStatebag`):** retry loop, up to 50 × 100 ms, waits for `NetworkGetEntityFromNetworkId` to return a valid registered entity before setting the statebag. Worst-case 5 s timeout with an explicit error log if the entity never appears.
- **Client (`AddStateBagChangeHandler`):** the entity-existence check now lives inside the `CreateThread`, retrying up to 5 s for streaming to complete instead of bailing. Distinguishes owner case (immediate hit) from non-owner case (passenger / bystander streaming) and handles both correctly.
- **Client (`deliverVehicle`):** properties are now applied **directly** via `lib.setVehicleProperties()` on the owning client immediately after `CreateVehicle()`. RAGE's native entity sync replicates the standard mod state to all clients in range. The statebag flow continues to fire as a redundant safety net for late-joiners and re-stream events. Both paths are idempotent.

**🛡️ Bonus hardening (silent bugs swept on the way)**

- **`Config.Debug = Config.Debug or true`** evaluated to `true` even when explicitly set to `false` — classic Lua falsy-or-default antipattern. Fixed with explicit `if Config.Debug == nil then ...` nil-check. Same fix applied to the server's `getConfigValue` helper, which had the equivalent `value ~= nil and value or default` pattern that flipped boolean `false` configs back to default.
- **Delivery callback** now requires `AND stored IS NOT NULL` in the `SELECT` — previously the query returned any vehicle owned by the player and money was deducted before checking whether the vehicle was actually in a garage. Returns the `vehicle_not_stored` error code which already existed in the client's error message table.
- **`getValidModel`** returns `nil` instead of `0` for empty strings — `joaat("")` returns `0` which is truthy in Lua, so a corrupt model string would slip through and `CreateVehicle(0, ...)` would silently fail downstream with no useful error.
- **`source` captured locally** at the top of `playerDropped` and `cancelService` handlers — good hygiene for any handler that may yield (the FiveM `source` global gets rebound per-event and is unsafe across `Wait` calls).

### v1.0.1 — Statebag Property Sync Rewrite
- Replaced 3 sequential `applyVehicleProperties()` attempts and the broken `TriggerServerEvent`-into-`ox_lib:setVehicleProperties` pattern with a clean statebag-based flow on an RDE-owned key (`rde:vehicleProperties`).
- Server-authoritative property loading and write; client reacts via `AddStateBagChangeHandler`.
- *(v1.0.2 note: the v1.0.1 architecture was correct in principle but missed the two FiveM-internal timing races that v1.0.2 hardens against.)*

### v1.0.0
- Initial release — delivery and pickup system, ox_core native, full property extraction (5-method), animated blips, phone animations, ox_target integration

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
- Tested across consecutive deliveries with multiple clients — zero strip-on-spawn regressions

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
- **Money never deducted for vehicles not actually in a garage** (v1.0.2)

### 🔒 Security & Performance
- Database ownership validation before any operation
- `stored IS NOT NULL` enforcement at request time — no charging for in-world vehicles
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
ensure rde_carservice
```

| Dependency | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Database layer |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, notifications, `lib.setVehicleProperties` |
| [ox_target](https://github.com/communityox/ox_target) | ⚠️ Optional | Right-click vehicle pickup |

> **Note:** rde_carservice requires FiveM server build `≥ 7290` (declared in `fxmanifest.lua`) — statebag broadcasting (`Entity(...).state:set(key, value, true)`) and `AddStateBagChangeHandler` require OneSync and modern server builds.

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
Config.Debug          = false            -- Dev debug mode (v1.0.2: now actually respects `false`)
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

## 📡 Property Sync — How It Works (v1.0.2 Architecture)

Vehicle property sync uses a **dual-path** architecture: direct apply on the owning client for immediate visual correctness, statebag broadcast for cross-client + late-joiner consistency. This is the same defense-in-depth pattern the RDE ecosystem standardized on after the v1.0.2 race-condition hardening pass.

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

### Path A — Owner-side direct apply

The client that calls `CreateVehicle` **owns** the entity. We apply properties locally and immediately via `lib.setVehicleProperties()` before the driver NPC even gets in the seat. RAGE's standard vehicle mod replication takes care of broadcasting the mod state to nearby clients via the engine's normal entity sync.

**Why this path matters:** the owner is the player who paid for and is watching the delivery. They need instant visual correctness regardless of any server round-trip latency. This path makes the apply independent of server timing.

### Path B — Server statebag broadcast

The client also fires `rde_carservice:vehicleSpawned(netId, plate)` to the server. The server:

1. Validates that `source` has an `activeServices[source]` entry of type `delivery` matching that plate — rejects forged or stale events.
2. Retries `NetworkGetEntityFromNetworkId(netId)` up to 50 × 100 ms until the entity is registered server-side (v1.0.2: handles the network announcement race).
3. Sets `Entity(vehicle).state:set('rde:vehicleProperties', properties, true)` — `broadcast = true` replicates to every client in scope, now and in the future.

On every receiving client, `AddStateBagChangeHandler('rde:vehicleProperties', ...)` fires inside an isolated `CreateThread`, waits up to 5 s for the entity to be available locally (v1.0.2: handles the streaming race), then calls `lib.setVehicleProperties()`.

**Why this path matters:** passengers who join after delivery, players who stream the vehicle in from a distance later, and anyone affected by a re-stream event all need the correct properties applied. Path A only reaches the owner directly; Path B reaches everyone else, plus re-applies to the owner as a safety net.

### Why this is correct

- **Server is always source of truth** — properties come from the DB, validated against `activeServices` before any statebag write
- **`rde:vehicleProperties` is an RDE-owned key** — no collision with ox_lib internals, no chance of accidental overwrites by other resources
- **Owner-side direct apply** removes the dependency on the server round-trip for first-paint visual correctness — and any other client that owns the vehicle later (handover, transfer) re-fires the statebag handler via the broadcast
- **Both paths are idempotent** — calling `lib.setVehicleProperties` twice with the same data is a no-op; the property table is the same in memory both times
- **Retry loops on both sides** — what v1.0.1 was missing and v1.0.2 added; FiveM statebags and networked entity registration are *both* asynchronous and require waiting

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

### Error Codes Returned by Callbacks

| Code | Meaning |
|---|---|
| `player_not_found` | ox_core didn't return a valid player for the source |
| `already_active` | This player already has an active delivery/pickup |
| `invalid_plate` | Plate was nil or empty |
| `vehicle_not_stored` | Vehicle exists but `stored IS NULL` — not in a garage (v1.0.2) |
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
├── config.lua          ← All configuration
├── client.lua          ← Spawn logic, driver AI, direct apply, statebag handler, UI
├── server.lua          ← Callbacks, DB, money, statebag write with retry, security
├── phone_app.lua       ← Phone app integration (optional)
├── LICENSE             ← RDE Black Flag Source License v6.66
└── README.md           ← You are here
```

---

## 🐛 Troubleshooting

**Vehicle properties not applying?**
Enable `Config.Debug = true` and check both consoles. In v1.0.2 you should see this sequence:
- Client console: `🔧 Direct apply on owner: true` (Path A succeeded — owner sees mods immediately)
- Server console: `📡 Statebag rde:vehicleProperties set for netId N` (Path B succeeded — broadcast sent)
- Client console (and other clients in scope): `✅ Properties applied via statebag for entity N` (Path B applied)

If Path A log says `true` but the visual is still default → check that your `data` column in the `vehicles` table actually contains valid properties (turn debug on server-side too — the `loadVehicleProperties` function will log the decoded keys).

If the server logs `entity never appeared for netId N after 5s` → your server is under extreme load or OneSync isn't behaving; this is the v1.0.2 timeout safeguard. The direct apply (Path A) will still have succeeded for the owner.

**Driver not spawning?**
Check console for model loading errors. Ensure all configured ped models are valid GTA V model names.

**Money not deducting / deducting twice?**
Verify the `character_inventory` table structure and that the money item format matches: `{"name":"money","count":5000}`. In v1.0.2, money is only deducted *after* the `stored IS NOT NULL` check passes — players cannot be charged for vehicles not actually in a garage.

**Service timing out early?**
Increase `Config.Timing.serviceTimeout`. Check server performance and that the driver can pathfind to the player location.

**`No such export` errors?**
Make sure `rde_carservice` starts **after** `ox_lib`, `ox_core`, and `oxmysql` in `server.cfg`.

**`Config.Debug = false` isn't disabling debug output?**
Fixed in v1.0.2. Update to the latest release.

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
