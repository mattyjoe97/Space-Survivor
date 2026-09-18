# Space Survivors

Vampire Survivors–style space roguelike in **Godot 4.7**.

## Quick Start
1. Import `project.godot` in Godot 4.7+
2. Press F5 → choose ship → Launch

## Characters
- **Viper** — fast, high fire rate, starts with a bit of Luck
- **Bulwark** — tankier, higher damage, dual cannons

## Luck System
Upgrades have rarity: **Common / Uncommon / Rare**.  
Higher **Luck** increases the chance of Uncommon and Rare options on level-up.  
Pick **Fortune Core** to raise Luck further. Viper starts with +5 Luck.

## Elite Schedule
Elites spawn on a fixed timer (pairs):
- **2:30** · **5:00** · **7:30**

1. **Plasma Spitter** — kites and fires 3-shot bursts  
2. **Void Rammer** — telegraphs then charges  

## Run
- 10:00 countdown → **Void Titan** boss  
- Kill boss to clear the sector  

## Progression (3.17)
3-card level-ups (weapon / system / core), per-stat caps, 3-tier behaviour systems, Luck-shaped rarity, a three-visit Merchant with purchase limits, fixed reroll budget. Design rationale and measured curves in `PATCH_NOTES_3_17.txt`; simulator in `tests/ProgressionSim.tscn`.

## Weapons (3.16)
14 distinct weapons (each with its own role, firing behaviour, VFX, silhouette, sound and level-5 transformation) and 7 true superweapons that replace their parent weapons with new behaviour. See `PATCH_NOTES_3_16.txt`.

## Visuals (3.15)
Every ship has its own hull with animated engines, banking and damage states. Enemies have per-variant designs with player-tracking eyes and hit flashes. Particle sparks, smoke, shards, shockwaves, muzzle flashes, dash ghosts. Shader post-processing (vignette, hit distortion, low-hull pulse) and a procedural nebula backdrop.  
Vector icon set (`scripts/GameIcons.gd`) for weapons, ships, enemies and upgrades, used across the HUD, level-up cards, hangar and Codex.  
Cleaner HUD (HP/XP/Luck left, score/timer right, centered wave + boss bar).


## Controls
- **WASD / Arrow Keys** — Move
- **Space / Right Shift** — Dash (brief invulnerability, 2.4s cooldown)
- **E** — Merchant interaction (merchant also opens on contact)


## Audio (3.15)
Procedural SFX via AudioManager (every weapon, hits, explosions, pickups, dash, level-up, UI, boss).  
Procedural music via MusicManager: menu / calm / combat / boss moods that crossfade.  
Volume controlled by the Master / Music / Effects sliders in Settings.

## Performance (3.14)
Enemy list is cached and shared across Player, Projectiles, and Spawner.  
Damage-number count is capped under heavy fire. Enemy art nodes are cached.

## Recent Polish Pass
- Added a responsive dash with a short invulnerability window and burst VFX.
- Added a phase-based Void Titan projectile volley beginning below 60% HP, with a denser/faster pattern below 30%.
- Added clear dash feedback through the existing HUD toast system.

### Progression rebalance
- Six core upgrade slots instead of seven.
- Accelerating XP curve with one deliberate level-up choice per XP pickup.
- Level 5/10/15/20 are guaranteed relic milestones; level 8 is a rare blueprint milestone.
- One free reroll is granted on every level; the merchant can sell another reroll token.
- Normal enemy XP is lower; elite kills are XP jackpots and the boss drops a large XP burst.
- Merchant now appears at 3:00 and sells repair, rerolls, upgrades, rare blueprints, and relics.
- Evolution requirements receive extra weighting once one half of the pair is owned.

## Progression systems added in the polish build
- 3 rerolls maximum per run.
- Banked scrap and persistent Armory upgrades.
- Ship mastery, contracts, achievements, and Codex discovery tracking.
- Endless mode after the standard 10-minute ruleset, with scaling waves and random events.
- Random events: Salvage Surge, Elite Hunt, Void Storm, and Distress Signal.
- Merchant prices were raised and scrap sinks expanded with Overcharge and Mystery Crate.
- Voidrunner unlocks from defeating the Void Titan; Destroyer can be purchased from progression.
- Character-specific signature passives remain active in runs.

## Gameplay Expansion Pass

This build adds:
- Stronger early/mid/late XP progression and six-upgrade build specialization.
- Six space sectors with gameplay modifiers and sector transitions.
- Swarmer, Armored, Leecher, Teleporter, Sniper, and Splitter enemy behaviors.
- Commander mini-boss encounters at mid-run milestones.
- Four-phase Void Titan boss with escalating projectile patterns.
- Cursed upgrade choices at rare blueprint milestones.
- Build archetype HUD tracking (Radiation, Crit, Explosion, Projectile, Void, Sustain).
- Branching Armory paths: Weapons, Defense, and Economy cores.
- Ship-specific Voidrunner and Destroyer combat passives.
- Mastery milestone rewards and secret discoveries.
- Expanded Codex discovery tracking for new enemy types and secrets.
- Richer end-of-run statistics.

The existing maximum of 3 rerolls per run remains enforced.


## Phase 1.1 Balance Pass
- Reduced normal enemy HP scaling and contact damage.
- Increased player starting damage by 8%.
- Reduced normal enemy population cap to 18 with pressure slowing at 14.
- Limited the run to one active elite at a time.
- Reduced Elite Hunt to one elite plus two normal reinforcements.
- Spaced scheduled elites farther apart.
- Added visible health bars to elite enemies.
- Rebuilt the Void Spitter behavior so it functions as a ranged elite instead of inheriting the spawner script.

## Phase 1.3 Combat Pass
- Added the regular Void Spitter ranged enemy with predictive shots and visible aim telegraph.
- Elite health bars remain horizontal while ships rotate.
- Void Titan now uses telegraphed targeted barrages, radial bursts, charges, sweeping shot patterns, and a short black-hole pull, with escalating phases.
- Late-run enemy pacing is slightly more aggressive to reduce safe stationary play.


Phase 2.8 — Scrap Economy & Meta Progression
- Scrap Lab with 12 persistent upgrade tracks, 10 levels each
- Clear upgrade costs and visible purchase controls
- Merchant run upgrades now have explicit stat effects
- Run Results show scrap earned, spent, secured, and banked
- New permanent fire-rate, XP, pickup-range, and crit progression
- Older saves automatically receive defaults for new upgrade tracks
