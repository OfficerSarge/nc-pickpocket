# nc-pickpocket

A sophisticated and immersive pickpocketing system for QBCore Framework with dynamic minigames, realistic NPC reactions, and extensive configuration options.

## Preview & Support
![NCHub Pickpocket](https://github.com/user-attachments/assets/e6d98ad2-dd1d-42e4-bcda-b6012d41fdc1)
- [Video Showcase](https://www.youtube.com/watch?v=4iCqRyJrbs4)
- For support and more resources, join our Discord - [Discord.gg/NCHub](https://discord.gg/NCHub)

## Features

- **Interactive Skill-Based Minigame**: Test your timing skills with an engaging arrow-based minigame
- **Intelligent NPC Reactions**: NPCs can call police or become aggressive when they discover theft
- **Multi-Inventory Support**: Compatible with multiple inventory systems (qb, ox, and custom)
- **Police Integration**: Built-in support for qb-dispatch and traditional police alerts
- **Dynamic Item System**: Configurable items with different rarities and values
- **NPC Cooldown System**: Prevents farming the same NPC repeatedly
- **Realistic Animations**: Natural NPC behaviors during and after pickpocketing
- **Adaptive Difficulty**: Configure success rates based on item value and rarity

## Dependencies

- QBCore Framework
- qb-target (for interaction)

## Optional Integrations

- qb-dispatch (for enhanced police notifications)
- Various inventory systems (qb-inventory, ox-inventory, or custom)

## Installation

1. Download or clone this repository
2. Place the resource in your server's `resources` folder
3. Add `ensure nc-pickpocket` to your server.cfg
4. Configure settings in `config.lua` to match your server's economy and requirements
5. Restart your server

## Configuration Options

The `config.lua` file provides extensive customization:

```lua
Config = {
    EnableSkillCheck = true,           -- Toggle skill check minigame
    MaxPickpocketAttempts = 3,         -- Maximum attempts per NPC
    CooldownTime = 30 * 60000,         -- Cooldown between pickpocketing the same NPC
    RequiredPolice = 0,                -- Police required for functionality
    UseQBDispatch = false,             -- Enable qb-dispatch integration
    EmptyPocketChance = 30,            -- Chance of finding nothing (0-100)
    NPCCallPoliceChance = 25,          -- Chance of NPC calling police on failure
    NPCAggressiveChance = 100,         -- Chance of NPC becoming aggressive
    DiscoveryChance = 35,              -- Chance of discovery even after success
    InventoryType = "qb"               -- Inventory system type ("qb", "ox", "custom")
}
```

## Usage

1. Approach any NPC in the game world
2. Use the qb-target interaction to initiate pickpocketing
3. Complete the timing-based minigame by pressing Space in the green zones
4. Successfully pickpocketed items will be added to your inventory
5. Be careful - NPCs may notice your attempt and alert police or attack you!
