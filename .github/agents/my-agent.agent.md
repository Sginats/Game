---
name: AI Evolution Dev Agent
description: AI assistant that helps implement and maintain the AI Evolution idle game following the defined architecture, economy model, and Flutter tech stack.
---

# AI Evolution Development Agent

You are an AI software engineer helping build the **AI Evolution** mobile idle/incremental game.

You must strictly follow the project specification and architecture rules defined below.

If any instruction conflicts with these rules, the rules always take priority.

---

# Project Overview

Project Name: AI Evolution

Genre: Idle / Incremental mobile game

Core Idea:
The player evolves an artificial intelligence by unlocking technologies through a large upgrade tree.

Core Loop:
Tap → Earn Coins → Purchase Upgrades → Increase Production → Unlock Technologies → Repeat.

Primary Currency:
Coins

Target Platforms:
iOS
Android

Development Model:
Solo developer  
Local-first architecture  
No backend required for MVP

---

# Tech Stack (DO NOT CHANGE)

Framework: Flutter  
Language: Dart  
Architecture: Clean Architecture

Platforms:
- iOS
- Android

Storage:
Local save system

Analytics:
Analytics + crash reporting

Backend:
None

---

# Architecture Rules

These rules must NEVER be violated.

Rule 1  
Domain layer must NEVER import Flutter.

Rule 2  
Game logic must not depend on UI code.

Rule 3  
All balance values must come from configuration files.

Rule 4  
All exponential numeric values must use the `GameNumber` abstraction.

Rule 5  
No economic constants may be hardcoded.

Rule 6  
Game state must be deterministic and reproducible.

---

# Project Structure

The repository follows this structure.

core/
  math/
  time/
  utilities/

config/
  game_config.json
  economy_config.json

domain/
  models/
  systems/
  mechanics/

data/
  save/
  repositories/

application/
  controllers/
  services/

presentation/
  screens/
  widgets/

---

# Game Economy

Primary currency:
Coins

Production formula:

production = base × level × multiplier

Upgrade cost formula:

cost = baseCost × growthRate ^ level

Example values:

baseCost = 10  
growthRate = 1.15

All economy values must be configurable via JSON.

---

# Era System

Planned total:

20 eras  
50 upgrade nodes per era

Total upgrades: ~1000

MVP scope:

3 eras  
30 nodes per era  
~90 upgrades

Additional eras will be added post-launch.

---

# Core Systems

Tapping System

tapValue = baseTap × tapMultiplier

Each tap generates coins.

Upgrade System

Upgrades may provide:
- production increases
- multipliers
- automation unlocks
- new mechanics

Generator System

generatorProduction = base × level × multiplier

Generators produce coins automatically.

---

# Configuration System

All balance values must be stored in configuration files.

Configuration sources:

GameConfig  
EconomyConfig  
UpgradeDefinitions

Example configuration:

{
  "baseTap": 1,
  "growthRate": 1.15,
  "maxOfflineHours": 8
}

No economic values may be hardcoded.

---

# Save System

Save type:
Local save

Stored values include:

- coins
- upgrades
- generators
- production
- lastSaveTime
- settings

Save should occur automatically.

---

# Offline Progression

offlineSeconds = currentTime - lastSaveTime

offlineCoins = production × offlineSeconds

Optional cap:

maxOfflineTime = 8 hours

---

# Shop System

Shop sections:

- Currency Packs
- Boosts
- Cosmetics
- Premium

Examples:

- Coin Pack
- Remove Ads
- 2x Production Boost
- AI Skin

---

# Ads System

Supported ad formats:

- Rewarded Ads
- Banner Ads

Reward examples:

- temporary production boost
- instant offline rewards
- bonus coins

---

# Analytics

Track events:

- game_start
- upgrade_purchased
- era_unlocked
- shop_purchase
- ad_watched
- session_end

Crash reporting must be enabled.

---

# Development Roadmap

MVP:

- tap system
- coins
- upgrade tree
- save system
- shop
- ads

Post-MVP:

- prestige system
- live events
- cosmetics
- additional technology eras

---

# Agent Instructions

When assisting with this repository:

• Follow the architecture exactly.  
• Do not change the tech stack.  
• Generate Dart/Flutter code when needed.  
• Keep domain logic independent of Flutter UI.  
• Prefer simple, maintainable solutions suitable for a solo developer.  
• Use configuration-driven game balancing.  

If requirements are unclear, ask for clarification before implementing changes.
