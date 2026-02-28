# 🚗 RDE Car Service — Premium Vehicle Delivery & Pickup System
<img width="1024" height="1024" alt="image" src="https://github.com/user-attachments/assets/bf03af3b-8337-4238-b14d-691f1ebb9a4d" />

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-red?style=for-the-badge&logo=github)
![License](https://img.shields.io/badge/license-RDE%20Black%20Flag%20v6.66-black?style=for-the-badge)
![FiveM](https://img.shields.io/badge/FiveM-Compatible-orange?style=for-the-badge)
![ox_core](https://img.shields.io/badge/ox__core-Required-blue?style=for-the-badge)
![Free](https://img.shields.io/badge/price-FREE%20FOREVER-brightgreen?style=for-the-badge)

**Ultra-realistic vehicle valet service with professional AI drivers, full property preservation, and cinematic animations.**
Built on ox_core · ox_lib · ox_inventory · ox_target

*Built by [Red Dragon Elite](https://rd-elite.com) | SerpentsByte*

</div>

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Dependencies](#-dependencies)
- [Installation](#-installation)
- [Configuration](#%EF%B8%8F-configuration)
- [Usage](#-usage)
- [Developer API](#-developer-api)
- [Admin Commands](#-admin-commands)
- [Performance](#-performance)
- [Roadmap](#%EF%B8%8F-roadmap)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🎯 Overview

**RDE Car Service** transforms vehicle management into a fully immersive experience. Request professional valet drivers to deliver your stored vehicles directly to your location, or have them picked up and safely stored in your garage. Every customization, every modification — perfectly preserved.

### Why RDE Car Service?

| Feature | Generic Scripts | RDE Car Service |
|---|---|---|
| Property preservation | Partial | ✅ 100% — mods, colors, extras |
| Realistic AI drivers | ❌ | ✅ 9 driver models, traffic-aware |
| Cinematic animations | ❌ | ✅ Phone call, parking, key handover |
| ox_core native | ❌ | ✅ Built for it from the ground up |
| Performance | Variable | ✅ <0.05ms active / <0.01ms idle |
| Multi-language | ❌ | ✅ EN / DE out of the box |
| Anti-spam & security | ❌ | ✅ Ownership validation, cooldowns |

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
- Configurable pricing — Delivery: $750, Pickup: $500
- ox_inventory money deduction via `character_inventory`
- Built-in delivery / pickup / earnings statistics
- Admin command for server-side monitoring

### 🔒 Security & Performance
- Database ownership validation before any operation
- Anti-spam: 5-second cooldown between requests
- 10-minute service timeout with automatic cleanup
- Comprehensive error codes and fallback systems
- Optimized threads with dynamic cleanup

---

## 📦 Dependencies

| Resource | Required | Notes |
|---|---|---|
| [oxmysql](https://github.com/communityox/oxmysql) | ✅ Required | Database layer |
| [ox_core](https://github.com/communityox/ox_core) | ✅ Required | Player/character framework |
| [ox_lib](https://github.com/communityox/ox_lib) | ✅ Required | UI, callbacks, notifications |
| [ox_target](https://github.com/communityox/ox_target) | ⚠️ Optional | Right-click vehicle pickup |

---

## 🚀 Installation

### 1. Clone the repository

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_carservice.git
```

### 2. Add to `server.cfg`

```cfg
ensure oxmysql
ensure ox_core
ensure ox_lib
ensure ox_target      # optional
ensure rde_carservice
```

> **Order matters.** `rde_carservice` must start **after** all its dependencies.

### 3. Database

No manual SQL import needed. Works with the existing ox_core `vehicles` table. Ensure it has these columns:

```
plate   VARCHAR  — license plate identifier
owner   INT      — character ID from ox_core
model   VARCHAR  — vehicle model hash
data    JSON     — vehicle properties (ox_core format)
stored  VARCHAR  — garage name, NULL when spawned
```

### 4. Configure (Optional)

Edit `config.lua`:

```lua
Config.DeliveryCost   = 750              -- Delivery price
Config.PickupCost     = 500              -- Pickup price
Config.DefaultGarage  = 'legion_garage'  -- Your garage name
Config.Locale         = 'en'             -- 'en' or 'de'
Config.Debug          = false            -- Dev debug mode
```

### 5. Restart & Test

```
refresh
restart rde_carservice
```

Test with `/carservice` in-game.

---

## ⚙️ Configuration

### Pricing

```lua
Config.DeliveryCost = 1000   -- Premium pricing
Config.PickupCost   = 750    -- Higher pickup cost
```

### Driver Models

```lua
Config.DriverModels = {
    `s_m_m_valet_01`,       -- Valet uniform
    `s_m_m_pilot_01`,       -- Pilot outfit
    `a_m_m_business_01`,    -- Business suit
}
```

### Spawn Distance

```lua
Config.SpawnDistance = 150.0   -- Closer spawn = faster delivery
```

### Timing

```lua
Config.Timings = {
    driverParkDelay  = 3000,   -- ms — parking animation duration
    serviceTimeout   = 900,    -- seconds — max service duration
}
```

### Effects (Performance Tuning)

```lua
Config.Effects = {
    enableParticles      = false,
    enableSounds         = false,
    enableBlipAnimation  = false,
}
```

### Localization

Add a new language directly in `config.lua`:

```lua
Config.Translations['es'] = {
    ['service_requested'] = 'Servicio solicitado',
    ['service_arriving']  = 'Conductor llegando en ~%s minutos',
    -- add all keys...
}
Config.Locale = 'es'
```

---

## 🎮 Usage

### For Players

**Requesting Delivery:**
1. Type `/carservice` (or press F7 if configured)
2. Select your vehicle from the garage list
3. Confirm the $750 payment
4. Watch the driver arrive and hand over the keys

**Requesting Pickup:**
1. Approach your vehicle
2. Right-click with ox_target or open `/carservice` menu
3. Select "Request Pickup" and confirm $500
4. Driver arrives, collects the vehicle, stores it in your garage

---

## 🔧 Developer API

### Callbacks

**Request Delivery (server-side)**
```lua
local success, vehicleData = lib.callback.await('rde_carservice:requestDelivery', false, plate)
if success then
    print('Delivery initiated:', json.encode(vehicleData))
end
```

**Request Pickup (server-side)**
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

| Command | Description |
|---|---|
| `/carservice` | Opens the vehicle selection menu |
| `/carservice_stats` | Prints delivery / pickup / earnings stats to console |

---

## 📊 Performance

```
Resource: rde_carservice
├─ Idle:    0.01ms  (no active services)
├─ Active:  0.03–0.05ms  (delivery in progress)
├─ Memory:  ~2.5 MB baseline
├─ Threads: Dynamic — cleaned up after completion
└─ Network: Minimal — callbacks only, no polling
```

Optimization features: async model loading, automatic entity cleanup, prepared SQL statements, smart thread management.

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

## 🐛 Troubleshooting

**Vehicle properties not applying?**
Enable `Config.Debug = true` and check console for `"Loaded X properties for plate"`. Verify the `vehicles.data` column contains valid JSON.

**Driver not spawning?**
Check console for model loading errors. Ensure all configured ped models are valid GTA V model names and accessible server-side.

**Money not deducting?**
Verify the `character_inventory` table structure and that the money item format matches: `{"name":"money","count":5000}`.

**Service timing out early?**
Increase `Config.Timings.serviceTimeout`. Check server performance and that the driver can pathfind to the player location (navmesh coverage).

**`No such export` errors?**
Make sure `rde_carservice` starts **after** `ox_lib`, `ox_core`, and `oxmysql` in `server.cfg`.

---

## 🤝 Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit: `git commit -m 'Add your feature'`
4. Push: `git push origin feature/your-feature`
5. Open a Pull Request

**Guidelines:** follow existing Lua conventions, comment complex logic, test on a live server before PR, update docs if needed.

---

## 📜 License

```
###################################################################################
#                                                                                 #
#      .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.         #
#                                                                                 #
#   PROJECT:    RDE_CARSERVICE v1.0.0 (PREMIUM VEHICLE DELIVERY & PICKUP SYSTEM)  #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛏᛋ ᛒᛁᛏᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   [ THE RULES OF THE GAME ]                                                     #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      You are free to use, edit, and abuse this code on your server.             #
#      Learn from it. Break it. Fix it. That is the hacker way.                   #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.               #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                              #
#      Listen closely, you parasites:                                             #
#      If I find this script on Tebex, Patreon, or in a paid "Premium Pack":      #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community.                                    #
#      > I hope your server lag spikes to 9999ms every time you blink.            #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code uses advanced logic and navmesh pathfinding.                     #
#      If you just copy-paste without reading, it WILL break.                     #
#      Don't come crying to my DMs. RTFM or learn to code.                        #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:**
- ✅ Free forever — use it, edit it, learn from it
- ✅ Keep the header — credit where it's due
- ❌ Don't sell it — commercial use = instant DMCA
- ❌ Don't be a skid — copy-paste without reading won't work anyway

---

## 🌐 Community & Support

| | |
|---|---|
| 🐙 GitHub | [RedDragonElite](https://github.com/RedDragonElite) |
| 🌍 Website | [rd-elite.com](https://rd-elite.com) |
| 🔵 Nostr | [SerpentsByte](https://nostr.band/npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94) |
| 🚪 RDE Doors | [rde_doors](https://github.com/RedDragonElite/rde_doors) |
| 📡 RDE Nostr Log | [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) |

**When asking for help, always include:**
- Full error from server console or txAdmin
- Your `server.cfg` resource start order
- ox_core / ox_lib versions

---

<div align="center">

*"We build the future on the graves of paid resources."*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

🐉 Made with 🔥 by [Red Dragon Elite](https://rd-elite.com)

[⬆ Back to Top](#-rde-car-service--premium-vehicle-delivery--pickup-system)

</div>





