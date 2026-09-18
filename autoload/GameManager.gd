extends Node

signal player_leveled_up(level: int)
signal player_died
signal wave_changed(wave: int)
signal score_changed(score: int)
signal boss_spawned
signal boss_health_changed(current: float, max_hp: float)
signal victory
signal run_time_updated(time_left: float)
signal luck_changed(luck: float)
signal scrap_changed(scrap: int)
signal mission_updated(text: String)
signal relic_gained(relic_name: String)
signal evolution_unlocked(evo_name: String)
signal upgrade_levels_changed
signal dash_used
signal random_event(text: String)
signal sector_changed(name: String, gimmick: String)
signal build_changed(text: String)
signal mastery_reward(text: String)
signal secret_found(text: String)
signal threat_changed(level: int, label: String)
signal synergy_activated(synergy_id: String)
var event_scrap_multiplier: float = 1.0
var event_scrap_time: float = 0.0
var event_enemy_speed_multiplier: float = 1.0
var event_enemy_time: float = 0.0

const RUN_DURATION := 600.0
const MAX_UPGRADE_LEVEL := 6      # generic fallback; real caps live in CORE_DEFS
const MAX_SYSTEM_LEVEL := 3       # systems are 3 discrete tiers
const MAX_WEAPON_LEVEL := 5
const MAX_SYSTEMS_DISTINCT := 4   # build identity: at most 4 different systems per run
const LEVELUP_CHOICES := 3
const BASE_REROLLS := 2
const RELIC_MILESTONES := [6, 12, 18, 24]
## Overcharge: small run-only bonuses offered only when no normal choice remains (endless-safe).
const OVERCHARGE_DEFS: Dictionary = {
	"oc_damage": {"name": "Overcharge: Weapons", "desc": "+1.5% weapon damage", "color": Color(1.0, 0.45, 0.4)},
	"oc_fire_rate": {"name": "Overcharge: Cyclers", "desc": "+1% fire rate", "color": Color(1.0, 0.75, 0.35)},
	"oc_speed": {"name": "Overcharge: Thrusters", "desc": "+2% move speed", "color": Color(0.45, 0.9, 1.0)},
	"oc_hull": {"name": "Overcharge: Hull", "desc": "+2% max hull", "color": Color(0.35, 1.0, 0.55)},
	"oc_proj_speed": {"name": "Overcharge: Rails", "desc": "+2% projectile speed", "color": Color(0.8, 0.9, 1.0)},
	"oc_crit": {"name": "Overcharge: Targeting", "desc": "+0.5% crit chance", "color": Color(1.0, 0.85, 0.45)},
}
var overcharge_levels: int = 0
const RARE_MILESTONE := 9
const RARITY_NAMES := ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const RARITY_VALUES := [0.02, 0.04, 0.06, 0.08, 0.10]
## Rarity scales a core upgrade's base step; caps count picks, not value, so a lucky
## Legendary is a bigger step, never an extra step.
const RARITY_MULT := [1.0, 1.35, 1.75, 2.25, 3.0]
const RARITY_BASE_WEIGHTS := [70.0, 20.0, 7.0, 2.5, 0.5]
const LUCK_CAP := 40.0
## Core (stat) upgrades: base step per pick and per-stat pick cap. Different stats
## scale on different curves on purpose: multiplicative combat stats get small
## steps and low caps; utility stats get big steps and very low caps.
const CORE_DEFS: Dictionary = {
	"damage":           {"step": 0.08, "cap": 6, "kind": "mult"},
	"fire_rate":        {"step": 0.06, "cap": 5, "kind": "mult"},
	"max_hp":           {"step": 0.12, "cap": 5, "kind": "mult"},
	"speed":            {"step": 0.06, "cap": 4, "kind": "mult"},
	"crit":             {"step": 0.05, "cap": 5, "kind": "add"},
	"projectile_speed": {"step": 0.12, "cap": 3, "kind": "mult"},
	"xp_magnet":        {"step": 0.25, "cap": 3, "kind": "mult"},
	"xp_gain":          {"step": 0.10, "cap": 3, "kind": "add"},
	"scrap":            {"step": 0.15, "cap": 3, "kind": "add"},
	"luck":             {"step": 4.0,  "cap": 4, "kind": "flat"},
}
const UPGRADE_RARITY_VALUES: Dictionary = {
	"damage": [0.05, 0.08, 0.12, 0.17, 0.22],
	"speed": [0.05, 0.08, 0.12, 0.17, 0.22],
	"fire_rate": [0.05, 0.09, 0.13, 0.19, 0.25],
	"projectile_speed": [0.08, 0.14, 0.21, 0.30, 0.40],
	"max_hp": [0.05, 0.09, 0.14, 0.20, 0.28],
	"xp_magnet": [0.15, 0.25, 0.40, 0.60, 0.85],
	"xp_gain": [0.05, 0.08, 0.12, 0.17, 0.23],
	"luck": [3.0, 5.0, 8.0, 12.0, 18.0],
	"crit": [0.04, 0.07, 0.10, 0.14, 0.18],
	"proj_size": [0.08, 0.14, 0.20, 0.30, 0.42],
	"aura_size": [0.15, 0.25, 0.40, 0.60, 0.85],
	"area": [0.12, 0.20, 0.30, 0.45, 0.60],
	"explode_damage": [0.10, 0.16, 0.24, 0.35, 0.50],
	"scrap": [0.10, 0.18, 0.28, 0.40, 0.55]
}
const DAMAGE_SOURCE_NAMES: Dictionary = {
	"primary_fire": "Primary Cannons (legacy)",
	"ship_ability": "Ship Ability",
	"missile_system": "Hunter Missiles",
	"plasma_lance": "Plasma Lance",
	"arc_coil": "Arc Coil",
	"void_blades": "Void Blades",
	"ion_burst": "Ion Burst",
	"railgun": "Railgun",
	"drone_swarm": "Drone Swarm",
	"graviton_mines": "Graviton Mines",
	"radiation": "Radiation",
	"side_guns": "Side Batteries",
	"tesla_coil": "Tesla Coil",
	"flamethrower": "Plasma Flamethrower",
	"torpedo_bay": "Torpedo Bay",
	"scattergun": "Photon Scattergun",
	"phase_disruptor": "Phase Disruptor",
	"dreadnought_salvo": "Dreadnought Salvo",
	"hellfire_lance": "Hellfire Lance",
	"storm_grid": "Storm Grid",
	"dimensional_reaper": "Dimensional Reaper",
	"starbreaker": "Starbreaker",
	"frozen_singularity": "Frozen Singularity",
	"nuclear_broadside": "Nuclear Broadside",
	"cryo_field": "Cryo Field",
	"ship_signature": "Ship Signature",
	"orbit_drones": "Orbit Drones",
}
const SYSTEM_COMPATIBILITY: Dictionary = {
	"extra_projectile": ["missile_system", "plasma_lance", "void_blades", "graviton_mines", "side_guns", "torpedo_bay", "scattergun", "tesla_coil"],
	"pierce": ["missile_system", "plasma_lance", "railgun", "side_guns", "scattergun", "phase_disruptor"],
	"area": ["void_blades", "graviton_mines", "radiation", "cryo_field", "flamethrower", "torpedo_bay", "tesla_coil", "phase_disruptor"],
	"proj_size": ["missile_system", "plasma_lance", "railgun", "side_guns", "torpedo_bay", "scattergun"],
	"explosive": ["missile_system", "side_guns", "scattergun", "torpedo_bay", "graviton_mines"],
	"duration": ["plasma_lance", "tesla_coil", "graviton_mines", "flamethrower", "phase_disruptor", "cryo_field", "void_blades"],
	"homing": ["side_guns", "scattergun", "torpedo_bay", "railgun"],
	"incendiary": ["missile_system", "plasma_lance", "side_guns", "scattergun", "railgun", "torpedo_bay", "arc_coil"],
	"cryo_rounds": ["missile_system", "side_guns", "scattergun", "railgun", "torpedo_bay", "phase_disruptor"],
}
const SYSTEM_EFFECT_TEXT: Dictionary = {
	"extra_projectile": {"missile_system": "+1 missile per volley", "plasma_lance": "+1 lance beam", "void_blades": "+1 orbiting blade", "graviton_mines": "+1 mine per drop", "side_guns": "+1 shell per burst", "torpedo_bay": "+1 torpedo", "scattergun": "+3 pellets", "tesla_coil": "+1 coil"},
	"pierce": {"missile_system": "+1 target penetration", "plasma_lance": "Beam reaches further", "railgun": "Rail crosses further", "side_guns": "+1 shell penetration", "scattergun": "+1 ricochet", "phase_disruptor": "Wave travels further"},
	"area": {"void_blades": "Wider orbit", "graviton_mines": "Bigger pull/blast", "radiation": "Wider field", "cryo_field": "Wider field", "flamethrower": "Longer cone", "torpedo_bay": "Bigger blast", "tesla_coil": "Longer coil range", "phase_disruptor": "Wider wave"},
	"proj_size": {"missile_system": "Larger missiles", "plasma_lance": "Wider beam", "railgun": "Wider rail", "side_guns": "Larger shells", "torpedo_bay": "Bigger torpedoes", "scattergun": "Bigger pellets"},
	"explosive": {"missile_system": "Missiles detonate", "side_guns": "Shells detonate", "scattergun": "Pellets pop", "torpedo_bay": "Bigger torpedo blast", "graviton_mines": "Stronger detonation"},
	"duration": {"plasma_lance": "Longer beam", "tesla_coil": "Longer coil uptime", "graviton_mines": "Longer pull", "flamethrower": "Longer-lasting pools", "phase_disruptor": "Longer marks", "cryo_field": "Longer freeze", "void_blades": "Longer lash"},
	"homing": {"side_guns": "Broadsides track targets", "scattergun": "Pellets curve into targets", "torpedo_bay": "Torpedoes steer harder", "railgun": "Rail aims at the strongest target"},
	"incendiary": {"missile_system": "Missiles ignite", "plasma_lance": "Beam burns hotter", "side_guns": "Shells ignite", "scattergun": "Pellets ignite", "railgun": "Rail ignites", "torpedo_bay": "Blast ignites", "arc_coil": "Chains ignite"},
	"cryo_rounds": {"missile_system": "Missiles chill", "side_guns": "Shells chill", "scattergun": "Pellets chill", "railgun": "Rail chills", "torpedo_bay": "Blast chills", "phase_disruptor": "Wave chills"},
}
# Per-run additive caps keep scaling meaningful without allowing runaway stacking.
# Permanent progression caps are intentionally different by category so
# combat remains meaningful while economy/utility cannot snowball forever.
const WEAPON_UPGRADES := [
	"missile_system", "plasma_lance", "arc_coil", "void_blades", "railgun", "graviton_mines", "radiation", "cryo_field", "side_guns",
	"tesla_coil", "flamethrower", "torpedo_bay", "scattergun", "phase_disruptor"
]
const SYSTEM_UPGRADES := [
	"extra_projectile", "pierce", "area", "proj_size", "explosive", "duration", "homing", "incendiary", "cryo_rounds"
]
## Per-tier text for systems (3 tiers, no rarity).
const SYSTEM_TIERS: Dictionary = {
	"extra_projectile": ["+1 projectile / blade / mine / coil", "+1 more", "+1 more"],
	"pierce": ["+1 penetration on every piercing weapon", "+1 more", "+1 more"],
	"area": ["+18% area on fields, cones, blasts and orbits", "+18% more", "+18% more"],
	"proj_size": ["+18% projectile & beam size", "+18% more, +6% damage", "+18% more, +6% damage"],
	"explosive": ["Projectiles detonate on impact", "+35% blast radius", "+50% blast damage"],
	"duration": ["+25% beam / coil / mine / pool / mark duration", "+25% more", "+25% more"],
	"homing": ["Cannon, side and scatter shots gently home", "Stronger tracking", "Full lock-on tracking"],
	"incendiary": ["Projectile & beam hits ignite (burn DoT)", "Hotter burn", "Burn spreads to a neighbour on kill"],
	"cryo_rounds": ["Projectile hits build freeze", "Faster freeze", "Frozen enemies take +20% from projectiles"],
}
const MODIFIER_UPGRADES := ["slow_field", "lifesteal"]
const MAX_WEAPON_SLOTS_BASE := 4
const MAX_WEAPON_SLOTS := 5
const WEAPON_SLOT_PERMANENT_COSTS := [2500, 9000]

const WEAPON_DEFS := {
	"missile_system": {"name":"Hunter Missiles", "role":"ORDNANCE", "color":Color(0.35,0.75,1.0),
		"desc":"Launches volleys of smart missiles that swing wide, then hunt the nearest target.",
		"levels":["2-missile volley", "3 missiles, sharper tracking", "Missiles carry a small warhead blast", "4 missiles, faster reload", "MAX: missiles split into 2 micro-seekers on impact"]},
	"plasma_lance": {"name":"Plasma Lance", "role":"ENERGY", "color":Color(1.0,0.25,0.35),
		"desc":"A sustained plasma beam that sweeps onto its target and burns everything along its length.",
		"levels":["Sustained beam, 0.7s", "Longer, wider beam", "Beam applies a burn that ticks after contact", "Faster sweep, longer burn", "MAX: beam refracts off the first target into a second beam"]},
	"arc_coil": {"name":"Arc Coil", "role":"ENERGY", "color":Color(0.45,0.75,1.0),
		"desc":"Discharges chain lightning that leaps enemy to enemy and stuns briefly.",
		"levels":["3-jump chain", "4 jumps, longer reach", "Each jump micro-stuns the target", "5 jumps, faster recharge", "MAX: chain ends leave an overcharge node that re-arcs after a moment"]},
	"void_blades": {"name":"Void Blades", "role":"VOID", "color":Color(0.65,0.35,1.0),
		"desc":"Rotating blades orbit the ship and shred anything they touch. Always on.",
		"levels":["2 orbiting blades", "3 blades, wider orbit", "Blades spin faster", "4 blades, longer blades", "MAX: blades periodically lash outward to double range"]},
	"railgun": {"name":"Railgun", "role":"KINETIC", "color":Color(0.85,0.9,1.0),
		"desc":"Charges for a moment, then fires a hyper-velocity slug that crosses the whole arena.",
		"levels":["Charged rail shot", "Higher damage, faster charge", "Slug knocks targets back", "Rail crosses further, wider", "MAX: fires a second perpendicular cross-rail"]},
	"graviton_mines": {"name":"Graviton Mines", "role":"ORDNANCE", "color":Color(0.75,0.5,1.0),
		"desc":"Deploys drifting mines that arm, drag enemies in, then detonate.",
		"levels":["2 mines per drop", "3 mines, stronger pull", "Mines arm faster, bigger blast", "4 mines, longer drift", "MAX: mines collapse into a brief singularity before detonating"]},
	"radiation": {"name":"Radiation Field", "role":"AURA", "color":Color(0.4,1.0,0.35),
		"desc":"A persistent toxic aura. Enemies inside become irradiated and keep taking damage after they leave.",
		"levels":["Aura DoT", "Wider aura, stronger dose", "Irradiated enemies keep ticking outside the field", "Faster tick rate", "MAX: irradiated enemies burst on death, spreading a fallout cloud"]},
	"cryo_field": {"name":"Cryo Field", "role":"CONTROL", "color":Color(0.45,0.85,1.0),
		"desc":"Pulses cold that slows enemies and builds freeze. Frozen enemies are locked in place.",
		"levels":["Cryo pulses build freeze", "Wider field, more freeze", "Frozen enemies take +25% damage", "Faster pulses, longer freeze", "MAX: frozen enemies shatter on death, chilling neighbours"]},
	"side_guns": {"name":"Side Batteries", "role":"KINETIC", "color":Color(1.0,0.75,0.3),
		"desc":"Broadside cannons on both flanks fire alternating bursts perpendicular to your heading.",
		"levels":["Twin broadsides, 2-shot bursts", "3-shot bursts", "Heavier shells, +knockback", "4-shot bursts, faster cycle", "MAX: quad batteries fire on all four sides"]},
	"tesla_coil": {"name":"Tesla Coil", "role":"ENERGY", "color":Color(0.6,0.9,1.0),
		"desc":"Drops a stationary coil turret behind the ship that zaps every enemy in range until it burns out.",
		"levels":["1 coil, 6s uptime", "Longer uptime, faster zaps", "Coil zaps 2 targets at once", "2 coils active", "MAX: nearby coils link a lightning wall between them"]},
	"flamethrower": {"name":"Plasma Flamethrower", "role":"ENERGY", "color":Color(1.0,0.5,0.15),
		"desc":"A continuous cone of plasma fire in your aim direction. Stacks burning on everything it touches.",
		"levels":["Short cone, burn stacks", "Longer cone", "Burn stacks hotter", "Wider cone, faster tick", "MAX: flames leave burning pools on the ground"]},
	"torpedo_bay": {"name":"Torpedo Bay", "role":"ORDNANCE", "color":Color(1.0,0.6,0.35),
		"desc":"Launches slow, heavy torpedoes that accelerate and detonate in a huge blast with knockback.",
		"levels":["1 torpedo", "Bigger warhead", "2 torpedoes", "Faster acceleration, bigger blast", "MAX: torpedoes burst into 3 cluster bomblets"]},
	"scattergun": {"name":"Photon Scattergun", "role":"KINETIC", "color":Color(1.0,0.9,0.4),
		"desc":"Close-range spray of photon pellets that ricochet off enemies into new targets.",
		"levels":["6-pellet spray", "8 pellets, wider cone", "Pellets ricochet once", "10 pellets, faster reload", "MAX: pellets ricochet twice and double-tap"]},
	"phase_disruptor": {"name":"Phase Disruptor", "role":"VOID", "color":Color(0.85,0.45,1.0),
		"desc":"Fires a wave that phases through enemies, marking them. Phased enemies take extra damage from everything.",
		"levels":["Phase wave, +15% damage taken", "Wider wave, +20%", "Phased enemies are shoved back", "Longer mark, +25%", "MAX: marks collapse into a rift that pulses damage"]},
}

const WEAPON_SYNERGIES := {
	"dreadnought_salvo": {"name":"DREADNOUGHT SALVO", "requires":["missile_system","torpedo_bay"], "color":Color(1.0,0.62,0.3),
		"desc":"Missiles and torpedoes merge into a single launcher that fires a rolling 8-warhead salvo: homing torpedoes that carpet-bomb the target area."},
	"hellfire_lance": {"name":"HELLFIRE LANCE", "requires":["plasma_lance","flamethrower"], "color":Color(1.0,0.35,0.15),
		"desc":"The lance becomes a wide flaming beam that sweeps a full circle around the ship, leaving burning trails behind it."},
	"storm_grid": {"name":"STORM GRID", "requires":["arc_coil","tesla_coil"], "color":Color(0.55,0.85,1.0),
		"desc":"Four tesla nodes orbit the ship linked by live lightning walls. Anything crossing the grid is chain-shocked."},
	"dimensional_reaper": {"name":"DIMENSIONAL REAPER", "requires":["void_blades","phase_disruptor"], "color":Color(0.8,0.4,1.0),
		"desc":"Blades become two huge phase scythes orbiting at range. Every enemy they cut is torn into a rift that drags neighbours in."},
	"starbreaker": {"name":"STARBREAKER", "requires":["railgun","scattergun"], "color":Color(1.0,0.95,0.7),
		"desc":"A long charge fires a colossal rail that shatters along its length, spraying photon shrapnel sideways from every impact."},
	"frozen_singularity": {"name":"FROZEN SINGULARITY", "requires":["graviton_mines","cryo_field"], "color":Color(0.6,0.85,1.0),
		"desc":"A persistent black hole hunts ahead of the ship, freezing and dragging everything into it, then collapses in a shatter burst."},
	"nuclear_broadside": {"name":"NUCLEAR BROADSIDE", "requires":["radiation","side_guns"], "color":Color(0.6,1.0,0.4),
		"desc":"Broadsides fire fission shells that leave fallout zones on impact, and the aura grows into a reactor bloom."},
}


const SHIP_SIGNATURES := {
	"viper": {"weapon":"missile_system", "trait":"PREDATOR PROTOCOL", "trait_text":"+0.8% Crit Chance per player level"},
	"bulwark": {"weapon":"radiation", "trait":"REINFORCED PLATING", "trait_text":"+4 Max Hull per player level"},
	"nova": {"weapon":"plasma_lance", "trait":"ENERGY CONDUIT", "trait_text":"+1.5% Weapon Damage per player level"},
	"voidrunner": {"weapon":"void_blades", "trait":"PHASE DRIVE", "trait_text":"+1% Move Speed and +1.5% blade orbit & reach per player level"},
	"destroyer": {"weapon":"railgun", "trait":"BALLISTICS COMPUTER", "trait_text":"+1.5% Weapon Damage per player level"},
	"aegis": {"weapon":"graviton_mines", "trait":"GRAVITIC CORE", "trait_text":"+2% Area per player level"},
	"tempest": {"weapon":"arc_coil", "trait":"CAPACITOR FEEDBACK", "trait_text":"+1% Fire Rate per level (drives Arc Coil discharge); Arc Coil +1 jump every 5 levels"},
	"dreadnought": {"weapon":"side_guns", "trait":"HEAVY ORDNANCE", "trait_text":"+1.5% Weapon Damage per player level"},
	"singularity": {"weapon":"cryo_field", "trait":"ANOMALY CORE", "trait_text":"+1 Luck per player level"}
}

func get_ship_signature(id: String = selected_character) -> Dictionary:
	return SHIP_SIGNATURES.get(id, {})

func get_ship_trait_text(id: String = selected_character) -> String:
	return str(get_ship_signature(id).get("trait_text", ""))

func apply_ship_level_trait(level: int) -> void:
	if not player or level <= 0:
		return
	var trait_id := str(get_ship_signature(selected_character).get("trait", ""))
	match trait_id:
		"PREDATOR PROTOCOL":
			player.crit_chance = minf(0.85, player.crit_chance + 0.008)
		"REINFORCED PLATING":
			player.max_hp += 4.0
			player.current_hp = min(player.max_hp, player.current_hp + 4.0)
			player.health_changed.emit(player.current_hp, player.max_hp)
		"ENERGY CONDUIT", "BALLISTICS COMPUTER", "HEAVY ORDNANCE":
			player.damage *= 1.015
		"PHASE DRIVE":
			player.speed *= 1.01
			player.aura_radius *= 1.015
		"GRAVITIC CORE":
			player.aura_radius *= 1.02
			player.explode_radius *= 1.02
		"CAPACITOR FEEDBACK":
			player.fire_rate = maxf(0.06, player.fire_rate * 0.99)
		"ANOMALY CORE":
			player_luck += 1.0
			luck_changed.emit(player_luck)

func apply_signature_weapon() -> void:
	var signature: Dictionary = get_ship_signature()
	var weapon_id := str(signature.get("weapon", ""))
	if weapon_id != "":
		upgrade_levels[weapon_id] = max(1, int(upgrade_levels.get(weapon_id, 0)))

const PERMANENT_UPGRADE_CAPS: Dictionary = {
	"damage": 12,
	"fire_rate": 12,
	"weapons_core": 8,
	"crit": 10,
	"hull": 12,
	"defense_core": 8,
	"speed": 10,
	"magnet": 10,
	"xp": 10,
	"luck": 12,
	"scrap": 10,
	"economy_core": 10,
	"arsenal": 2
}
const MAX_UNIQUE_UPGRADES := 6  # distinct core/stat upgrades per run (build identity)

var player: Node2D = null
var cached_enemies: Array = []
var _enemy_cache_timer: float = 0.0
const ENEMY_CACHE_INTERVAL := 0.08
var score: int = 0
var scrap: int = 0
var current_wave: int = 1
var game_time: float = 0.0
var is_paused: bool = false
var is_game_over: bool = false
var is_boss_phase: bool = false
var is_victory: bool = false
var boss_spawned_flag: bool = false
var player_luck: float = 0.0
var selected_character: String = "viper"
var unlocked_ships: Dictionary = {"viper": true, "bulwark": true, "nova": true, "voidrunner": false, "destroyer": false, "aegis": false, "tempest": false, "dreadnought": false, "singularity": false}
var active_relics: Array[String] = []
var relic_offers_seen: Array[String] = []
var active_evolutions: Array[String] = []
var active_synergies: Array[String] = []
var upgrade_levels: Dictionary = {}  # id -> level
var mission_text: String = ""
var mission_progress: int = 0
var mission_target: int = 0
var elites_killed: int = 0
var rerolls_available: int = 0
const MAX_REROLLS_PER_RUN := 3
var banked_scrap: int = 0
var total_kills: int = 0
var total_runs: int = 0
var mastery_kills: Dictionary = {"viper": 0, "bulwark": 0, "nova": 0, "voidrunner": 0, "destroyer": 0, "aegis": 0, "tempest": 0, "dreadnought": 0, "singularity": 0}
var mastery_xp: Dictionary = {"viper": 0, "bulwark": 0, "nova": 0, "voidrunner": 0, "destroyer": 0, "aegis": 0, "tempest": 0, "dreadnought": 0, "singularity": 0}
var permanent_upgrades: Dictionary = {"damage": 0, "hull": 0, "scrap": 0, "speed": 0, "luck": 0, "weapons_core": 0, "defense_core": 0, "economy_core": 0, "fire_rate": 0, "xp": 0, "magnet": 0, "crit": 0, "arsenal": 0}
var achievements: Dictionary = {}
var codex_entries: Dictionary = {}
var completed_contracts: int = 0
var current_contracts: Array[Dictionary] = []
var run_mode: String = "standard"
var endless_time: float = 0.0
var current_sector: String = "ASTEROID BELT"
var current_sector_gimmick: String = "Destroy asteroids for bonus scrap"
var sector_index: int = 0
var build_tags: Array[String] = []
var cursed_upgrades: Array[String] = []
var secret_flags: Dictionary = {}
var mastery_rewards_claimed: Dictionary = {}
var run_kills: int = 0
var run_scrap_earned: int = 0
var run_scrap_spent: int = 0
var run_upgrade_bonuses: Dictionary = {}
var damage_by_weapon: Dictionary = {}
var threat_level: int = 1
var threat_label: String = "LOW"
const SAVE_PATH := "user://space_survivors_progress.json"
const MILESTONE_LEVELS := [5, 8, 10, 15, 20]

const SECTORS := [
	{"name":"ASTEROID BELT", "gimmick":"Destroy asteroids for bonus scrap", "enemy_bias":"swarm"},
	{"name":"DERELICT STATION", "gimmick":"Supply caches appear near the battlefield", "enemy_bias":"armored"},
	{"name":"ALIEN GRAVEYARD", "gimmick":"Leechers and splitters dominate", "enemy_bias":"leech"},
	{"name":"NEBULA", "gimmick":"Enemies emerge faster from the haze", "enemy_bias":"teleporter"},
	{"name":"BLACK HOLE", "gimmick":"Gravity pulls everything toward you", "enemy_bias":"gravity"},
	{"name":"VOID RIFT", "gimmick":"Elite enemies become unstable and aggressive", "enemy_bias":"elite"}
]

const CURSED_UPGRADES := [
	{"id":"glass_reactor","name":"Glass Reactor","desc":"+100% damage, -50% max HP","rarity":2,"icon_color":Color(1.0,0.35,0.45)},
	{"id":"unstable_ai","name":"Unstable AI","desc":"+65% fire rate, occasional misfire","rarity":2,"icon_color":Color(0.75,0.45,1.0)},
	{"id":"void_core","name":"Void Core","desc":"+50% XP gain, enemies move 20% faster","rarity":2,"icon_color":Color(0.45,0.25,1.0)},
	{"id":"blood_battery","name":"Blood Battery","desc":"Heal on kills, maximum HP slowly decays","rarity":2,"icon_color":Color(1.0,0.25,0.35)}
]

const CHARACTERS := {
	"viper": {
		"name": "Viper",
		"desc": "Agile interceptor\n+Speed  +Fire Rate  +Luck  -Hull",
		"color": Color(0.35, 0.85, 1.0),
		"base_speed": 280.0,
		"base_max_hp": 80.0,
		"base_damage": 11.0,
		"base_fire_rate": 0.32,
		"base_projectile_speed": 520.0,
		"base_xp_magnet": 110.0,
		"start_projectiles": 0,
		"base_luck": 8.0,
	},
	"bulwark": {
		"name": "Bulwark",
		"desc": "Armored cruiser\nRadiation Field control ship  +Hull  +Damage  -Speed",
		"color": Color(1.0, 0.55, 0.28),
		"base_speed": 200.0,
		"base_max_hp": 145.0,
		"base_damage": 16.0,
		"base_fire_rate": 0.48,
		"base_projectile_speed": 440.0,
		"base_xp_magnet": 95.0,
		"start_projectiles": 0,
		"base_luck": 0.0,
	},
	"nova": {
		"name": "Nova",
		"desc": "Glass cannon\n+Damage  +Pierce  +Proj Speed  -Hull",
		"color": Color(0.95, 0.4, 1.0),
		"base_speed": 245.0,
		"base_max_hp": 70.0,
		"base_damage": 18.0,
		"base_fire_rate": 0.38,
		"base_projectile_speed": 580.0,
		"base_xp_magnet": 100.0,
		"start_projectiles": 0,
		"base_luck": 3.0,
		"start_pierce": 1,
		"unlock_cost": 0,
	},
	"voidrunner": {
		"name": "Voidrunner",
		"desc": "Phase skirmisher\n+Speed  +Crit  +Projectile Speed  -Hull",
		"color": Color(0.35, 0.95, 0.85),
		"base_speed": 275.0,
		"base_max_hp": 68.0,
		"base_damage": 14.0,
		"base_fire_rate": 0.32,
		"base_projectile_speed": 630.0,
		"base_xp_magnet": 108.0,
		"start_projectiles": 0,
		"base_luck": 12.0,
		"unlock_cost": 3500,
	},
	"destroyer": {
		"name": "Destroyer",
		"desc": "Heavy gunship\nRailgun siege ship  +Damage  +Hull  -Speed",
		"color": Color(1.0, 0.38, 0.22),
		"base_speed": 170.0,
		"base_max_hp": 190.0,
		"base_damage": 26.0,
		"base_fire_rate": 0.56,
		"base_projectile_speed": 410.0,
		"base_xp_magnet": 92.0,
		"start_projectiles": 0,
		"base_luck": 0.0,
		"unlock_cost": 6500,
	},
	"aegis": {
		"name": "Aegis",
		"desc": "Defense frigate\n+Hull  +Magnet  +Balanced Firepower",
		"color": Color(0.35, 0.72, 1.0),
		"base_speed": 215.0,
		"base_max_hp": 215.0,
		"base_damage": 19.0,
		"base_fire_rate": 0.44,
		"base_projectile_speed": 500.0,
		"base_xp_magnet": 135.0,
		"start_projectiles": 0,
		"base_luck": 4.0,
		"unlock_cost": 10000,
	},
	"tempest": {
		"name": "Tempest",
		"desc": "Storm interceptor\n+Speed  +Fire Rate  +Luck  -Hull",
		"color": Color(0.35, 0.55, 1.0),
		"base_speed": 315.0,
		"base_max_hp": 105.0,
		"base_damage": 16.0,
		"base_fire_rate": 0.25,
		"base_projectile_speed": 670.0,
		"base_xp_magnet": 118.0,
		"start_projectiles": 0,
		"base_luck": 14.0,
		"unlock_cost": 15000,
	},
	"dreadnought": {
		"name": "Dreadnought",
		"desc": "Siege battleship\n+Massive Hull  +Damage  Triple Barrage  -Speed",
		"color": Color(0.92, 0.34, 0.28),
		"base_speed": 150.0,
		"base_max_hp": 280.0,
		"base_damage": 31.0,
		"base_fire_rate": 0.68,
		"base_projectile_speed": 380.0,
		"base_xp_magnet": 88.0,
		"start_projectiles": 0,
		"base_luck": -2.0,
		"unlock_cost": 22000,
	},
	"singularity": {
		"name": "Singularity",
		"desc": "Anomaly cruiser\n+Crit  +XP Magnet  +Damage  Rare frame",
		"color": Color(0.66, 0.34, 1.0),
		"base_speed": 230.0,
		"base_max_hp": 135.0,
		"base_damage": 23.0,
		"base_fire_rate": 0.36,
		"base_projectile_speed": 560.0,
		"base_xp_magnet": 155.0,
		"start_projectiles": 0,
		"base_luck": 18.0,
		"unlock_cost": 32000,
	},
}

var available_upgrades: Array[Dictionary] = [
	{"id": "damage", "name": "Plasma Boost", "desc": "Damage scales with rarity", "icon_color": Color(1.0, 0.45, 0.25), "rarity": 0},
	{"id": "speed", "name": "Thrusters", "desc": "Move speed scales with rarity", "icon_color": Color(0.35, 0.8, 1.0), "rarity": 0},
	{"id": "fire_rate", "name": "Rapid Fire", "desc": "Fire rate scales with rarity", "icon_color": Color(1.0, 0.9, 0.3), "rarity": 0},
	{"id": "projectile_speed", "name": "Accelerators", "desc": "Projectile speed scales with rarity", "icon_color": Color(0.65, 0.4, 1.0), "rarity": 0},
	{"id": "max_hp", "name": "Reinforced Hull", "desc": "Max hull scales with rarity + restores hull", "icon_color": Color(0.3, 1.0, 0.45), "rarity": 0},
	{"id": "xp_magnet", "name": "Gravity Well", "desc": "Magnet range scales with rarity", "icon_color": Color(0.9, 0.3, 0.9), "rarity": 1},
	{"id": "xp_gain", "name": "Neural Uplink", "desc": "XP gain scales with rarity", "icon_color": Color(0.35, 1.0, 0.72), "rarity": 1},
	{"id": "scrap", "name": "Salvage Yield", "desc": "Increases Scrap earned from drops and rewards", "icon_color": Color(1.0, 0.78, 0.25), "rarity": 1},
	{"id": "extra_projectile", "name": "Multi-Cannon", "desc": "+1 projectile on every multi-shot weapon", "icon_color": Color(1.0, 0.65, 0.2), "rarity": 1},
	{"id": "pierce", "name": "Piercing Shots", "desc": "+1 penetration / reach on piercing weapons", "icon_color": Color(0.4, 1.0, 0.85), "rarity": 1},
	{"id": "area", "name": "Wide Array", "desc": "Fields, cones, blasts and orbits grow", "icon_color": Color(0.5, 0.9, 1.0), "rarity": 1},
	{"id": "luck", "name": "Fortune Core", "desc": "Luck scales with rarity", "icon_color": Color(1.0, 0.85, 0.3), "rarity": 2},
	{"id": "proj_size", "name": "Heavy Shells", "desc": "Projectile size scales with rarity", "icon_color": Color(0.8, 0.5, 1.0), "rarity": 1},
	{"id": "radiation", "name": "Radiation Field", "desc": "Aura damage around ship", "icon_color": Color(0.4, 1.0, 0.35), "rarity": 1},
	{"id": "explosive", "name": "Unstable Rounds", "desc": "Projectiles detonate on impact; tiers add radius and blast damage", "icon_color": Color(1.0, 0.5, 0.2), "rarity": 1},
	{"id": "duration", "name": "Capacitor Bank", "desc": "Beams, coils, mines, pools and marks last longer", "icon_color": Color(0.5, 0.95, 0.85), "rarity": 1},
	{"id": "homing", "name": "Seeker Firmware", "desc": "Shots curve toward targets", "icon_color": Color(0.35, 0.75, 1.0), "rarity": 1},
	{"id": "incendiary", "name": "Thermite Load", "desc": "Hits ignite enemies with a burning DoT", "icon_color": Color(1.0, 0.45, 0.15), "rarity": 1},
	{"id": "cryo_rounds", "name": "Cryo Rounds", "desc": "Projectile hits build freeze", "icon_color": Color(0.6, 0.9, 1.0), "rarity": 1},
	{"id": "side_guns", "name": "Side Batteries", "desc": "Fire extra side shots", "icon_color": Color(1.0, 0.75, 0.3), "rarity": 1},
	{"id": "cryo_field", "name": "Cryo Field", "desc": "Persistent pulses build freeze and deal damage", "icon_color": Color(0.45, 0.85, 1.0), "rarity": 1},
	{"id": "slow_field", "name": "Temporal Drag", "desc": "Nearby enemies move slower", "icon_color": Color(0.4, 0.6, 1.0), "rarity": 1},
	{"id": "crit", "name": "Targeting AI", "desc": "Crit chance scales with rarity (2x damage)", "icon_color": Color(1.0, 0.3, 0.5), "rarity": 1},
	{"id": "lifesteal", "name": "Energy Siphon", "desc": "Heal on kills (small)", "icon_color": Color(0.3, 1.0, 0.7), "rarity": 2},
	{"id": "missile_system", "name": "Hunter Missiles", "desc": "Fires smart missiles that softly track targets", "icon_color": Color(0.35, 0.75, 1.0), "rarity": 1},
	{"id": "plasma_lance", "name": "Plasma Lance", "desc": "Periodic high-damage piercing laser beam", "icon_color": Color(1.0, 0.25, 0.35), "rarity": 1},
	{"id": "arc_coil", "name": "Arc Coil", "desc": "Lightning jumps between nearby enemies", "icon_color": Color(0.45, 0.75, 1.0), "rarity": 1},
	{"id": "void_blades", "name": "Void Blades", "desc": "Rotating blades shred enemies around the ship", "icon_color": Color(0.65, 0.35, 1.0), "rarity": 1},
	{"id": "railgun", "name": "Railgun", "desc": "High-power narrow kinetic shot", "icon_color": Color(0.85, 0.9, 1.0), "rarity": 2},
	{"id": "graviton_mines", "name": "Graviton Mines", "desc": "Gravity mines pull enemies together", "icon_color": Color(0.75, 0.5, 1.0), "rarity": 1},
	{"id": "tesla_coil", "name": "Tesla Coil", "desc": "Deployable coil turret", "icon_color": Color(0.6, 0.9, 1.0), "rarity": 1},
	{"id": "flamethrower", "name": "Plasma Flamethrower", "desc": "Continuous burning cone", "icon_color": Color(1.0, 0.5, 0.15), "rarity": 1},
	{"id": "torpedo_bay", "name": "Torpedo Bay", "desc": "Slow heavy torpedoes, huge blast", "icon_color": Color(1.0, 0.6, 0.35), "rarity": 1},
	{"id": "scattergun", "name": "Photon Scattergun", "desc": "Ricocheting close-range spray", "icon_color": Color(1.0, 0.9, 0.4), "rarity": 1},
	{"id": "phase_disruptor", "name": "Phase Disruptor", "desc": "Marks enemies to take extra damage", "icon_color": Color(0.85, 0.45, 1.0), "rarity": 2},
]

const EVOLUTIONS := WEAPON_SYNERGIES

var available_relics: Array[Dictionary] = [
	{"id": "orbit_drones", "name": "Orbit Drones", "desc": "Drones orbit and shoot", "color": Color(0.4, 1.0, 0.9)},
	{"id": "thorns", "name": "Reactive Plating", "desc": "Reflect 40% contact damage", "color": Color(1.0, 0.5, 0.3)},
	{"id": "second_wind", "name": "Emergency Shield", "desc": "Once: survive lethal hit", "color": Color(0.5, 0.8, 1.0)},
	{"id": "scrap_magnet", "name": "Salvage Protocol", "desc": "+50% scrap drops", "color": Color(1.0, 0.85, 0.4)},
	{"id": "twin_thrusters", "name": "Twin Thrusters", "desc": "+1 dash charge; charges recharge independently", "color": Color(0.45, 0.9, 1.0)},
	{"id": "phase_thrusters", "name": "Phase Thrusters", "desc": "+1 dash charge; enemies you dash through are briefly slowed", "color": Color(0.75, 0.5, 1.0)},
]

func _ready() -> void:
	set_process(true)
	randomize()
	_load_progress()
	_roll_contracts()

func _process(delta: float) -> void:
	_enemy_cache_timer -= delta
	if _enemy_cache_timer <= 0.0:
		_enemy_cache_timer = ENEMY_CACHE_INTERVAL
		var tree := get_tree()
		if tree:
			cached_enemies = tree.get_nodes_in_group("enemies")

func get_enemies() -> Array:
	return cached_enemies

func _init_contracts() -> void:
	if not current_contracts.is_empty():
		return
	_roll_contracts()

func _roll_contracts() -> void:
	current_contracts.clear()
	var pool = [
		{"id":"hunter","title":"HUNTER","desc":"Kill 75 enemies","target":75,"progress":0,"reward":60,"type":"kills"},
		{"id":"scavenger","title":"SCAVENGER","desc":"Collect 150 scrap","target":150,"progress":0,"reward":75,"type":"scrap"},
		{"id":"elite","title":"ELITE HUNTER","desc":"Kill 2 elites","target":2,"progress":0,"reward":110,"type":"elites"},
		{"id":"survivor","title":"SURVIVOR","desc":"Reach 6:00","target":360,"progress":0,"reward":90,"type":"time"},
		{"id":"champion","title":"CHAMPION","desc":"Defeat the Void Titan","target":1,"progress":0,"reward":200,"type":"boss"}
	]
	pool.shuffle()
	current_contracts = [pool[0].duplicate(), pool[1].duplicate()]

func _load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_save_progress()
		return
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	banked_scrap = int(parsed.get("banked_scrap", 0))
	total_kills = int(parsed.get("total_kills", 0))
	total_runs = int(parsed.get("total_runs", 0))
	mastery_kills = parsed.get("mastery_kills", mastery_kills)
	mastery_xp = parsed.get("mastery_xp", mastery_xp)
	# Migrate older saves with the expanded fleet roster.
	for ship_id in CHARACTERS.keys():
		mastery_kills[ship_id] = int(mastery_kills.get(ship_id, 0))
		mastery_xp[ship_id] = int(mastery_xp.get(ship_id, 0))
		unlocked_ships[ship_id] = bool(unlocked_ships.get(ship_id, bool(ship_id in ["viper", "bulwark", "nova"])))
	unlocked_ships = parsed.get("unlocked_ships", unlocked_ships)
	permanent_upgrades = parsed.get("permanent_upgrades", permanent_upgrades)
	# Migrate older saves so new progression nodes always have a numeric level.
	for id in ["damage", "hull", "scrap", "speed", "luck", "weapons_core", "defense_core", "economy_core", "fire_rate", "xp", "magnet", "crit", "arsenal"]:
		if not permanent_upgrades.has(id):
			permanent_upgrades[id] = 0
	for id in PERMANENT_UPGRADE_CAPS.keys():
		permanent_upgrades[id] = clampi(int(permanent_upgrades.get(id, 0)), 0, get_permanent_upgrade_cap(id))
	achievements = parsed.get("achievements", {})
	codex_entries = parsed.get("codex_entries", {})
	completed_contracts = int(parsed.get("completed_contracts", 0))
	secret_flags = parsed.get("secret_flags", {})
	mastery_rewards_claimed = parsed.get("mastery_rewards_claimed", {})

func _save_progress() -> void:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not f:
		return
	var data = {"banked_scrap":banked_scrap,"total_kills":total_kills,"total_runs":total_runs,"mastery_kills":mastery_kills,"mastery_xp":mastery_xp,"unlocked_ships":unlocked_ships,"permanent_upgrades":permanent_upgrades,"achievements":achievements,"codex_entries":codex_entries,"completed_contracts":completed_contracts,"secret_flags":secret_flags,"mastery_rewards_claimed":mastery_rewards_claimed}
	f.store_string(JSON.stringify(data))

func record_kill(enemy_type: String = "enemy") -> void:
	total_kills += 1
	run_kills += 1
	mastery_kills[selected_character] = int(mastery_kills.get(selected_character, 0)) + 1
	mastery_xp[selected_character] = int(mastery_xp.get(selected_character, 0)) + 10
	check_mastery_rewards()
	codex_entries[enemy_type] = true
	_update_contract("kills", 1)
	_check_achievements()

func record_elite_kill() -> void:
	elites_killed += 1
	_update_contract("elites", 1)
	update_mission("elites", 1)
	record_kill("elite")

func _update_contract(type: String, amount: int) -> void:
	for c in current_contracts:
		if c.type == type:
			c.progress = mini(int(c.progress) + amount, int(c.target))
		if c.progress >= c.target and not c.get("claimed", false):
			c.claimed = true
			completed_contracts += 1
			banked_scrap += int(c.reward)
			add_score(500)
	_save_progress()

func update_time_contract(seconds: int) -> void:
	_update_contract("time", seconds)

func record_boss_defeated() -> void:
	_update_contract("boss", 1)
	codex_entries["void_titan"] = true
	_check_achievements()

func _check_achievements() -> void:
	var checks = {
		"first_blood": total_kills >= 1,
		"centurion": total_kills >= 100,
		"elite_hunter": elites_killed >= 10,
		"void_slayer": codex_entries.has("void_titan"),
		"fully_armed": unique_upgrade_count() >= MAX_UNIQUE_UPGRADES,
		"mastery_100": int(mastery_kills.get(selected_character,0)) >= 500,
		"survivor": game_time >= 360.0,
		"collector": active_relics.size() >= 4,
		"evolver": active_evolutions.size() >= 1,
		"endless": run_mode == "endless" and endless_time >= RUN_DURATION + 180.0
	}
	for id in checks.keys():
		if checks[id] and not achievements.get(id, false):
			achievements[id] = true
	_save_progress()

func is_ship_unlocked(id: String) -> bool:
	return bool(unlocked_ships.get(id, false))

func unlock_ship(id: String, cost: int = 0) -> bool:
	if is_ship_unlocked(id):
		return true
	if cost > 0 and not spend_banked_scrap(cost):
		return false
	unlocked_ships[id] = true
	codex_entries["ship_" + id] = true
	_save_progress()
	return true

func mastery_percent(id: String) -> int:
	return mini(100, int(int(mastery_kills.get(id, 0)) / 5))

func get_mastery_bonus(id: String) -> Dictionary:
	var m = mastery_percent(id)
	return {"damage": 1.0 + m * 0.002, "hull": 1.0 + m * 0.003, "scrap": 1.0 + m * 0.004}

func get_permanent_upgrade_cap(id: String) -> int:
	return int(PERMANENT_UPGRADE_CAPS.get(id, 10))

func buy_permanent_upgrade(id: String, cost: int) -> bool:
	var current_level := int(permanent_upgrades.get(id, 0))
	var cap := get_permanent_upgrade_cap(id)
	if current_level >= cap:
		return false
	if not spend_banked_scrap(cost):
		return false
	permanent_upgrades[id] = current_level + 1
	_save_progress()
	return true

func spend_banked_scrap(amount: int) -> bool:
	if banked_scrap < amount:
		return false
	banked_scrap -= amount
	_save_progress()
	return true

func grant_reroll() -> void:
	rerolls_available = mini(MAX_REROLLS_PER_RUN, rerolls_available + 1)

func reset_rerolls() -> void:
	rerolls_available = BASE_REROLLS
	merchant_visit = 0
	merchant_offers.clear()
	merchant_refreshed = false
	merchant_purchases = 0
	merchant_reroll_bought = false

func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)

func add_scrap(amount: int) -> void:
	var mult = 1.5 if "scrap_magnet" in active_relics else 1.0
	mult *= 1.0 + float(permanent_upgrades.get("scrap", 0)) * 0.05
	mult *= 1.0 + float(permanent_upgrades.get("economy_core", 0)) * 0.01
	mult *= event_scrap_multiplier
	if player != null:
		mult *= float(player.get("scrap_gain_mult"))
	var gained = int(amount * mult)
	scrap += gained
	run_scrap_earned += gained
	_update_contract("scrap", gained)
	scrap_changed.emit(scrap)

func spend_scrap(amount: int) -> bool:
	if scrap >= amount:
		scrap -= amount
		run_scrap_spent += amount
		scrap_changed.emit(scrap)
		return true
	return false

func next_wave() -> void:
	current_wave += 1
	wave_changed.emit(current_wave)

func set_threat(level: int) -> void:
	threat_level = clampi(level, 1, 10)
	var labels = ["LOW", "LOW", "ELEVATED", "ELEVATED", "HIGH", "HIGH", "SEVERE", "SEVERE", "CRITICAL", "CRITICAL", "APOCALYPTIC"]
	threat_label = labels[threat_level]
	threat_changed.emit(threat_level, threat_label)

func get_threat_multiplier() -> float:
	return 1.0 + float(max(0, threat_level - 1)) * 0.055

# ---------------------------------------------------------------------------
# Run world lifecycle (3.16.1)
# Every run-scoped entity (enemies, drops, projectiles, weapon objects, VFX) is
# parented under the current run's Main scene via spawn(), so it is destroyed
# with the scene. reset() additionally purges anything still alive by group.
# ---------------------------------------------------------------------------
const RUN_GROUPS := ["void_reticles", "enemies", "elites", "boss", "xp_gems", "scrap_pickups", "pickups", "tesla_coils",
	"merchants", "planets", "run_entity", "enemy_bullets", "projectiles", "damage_numbers", "run_vfx"]
var world: Node = null

func register_world(node: Node) -> void:
	world = node

func unregister_world(node: Node) -> void:
	if world == node:
		world = null

## Parent for anything that belongs to the current run.
func world_root() -> Node:
	if is_instance_valid(world) and world.is_inside_tree():
		return world
	var tree := get_tree()
	if tree and tree.current_scene:
		return tree.current_scene
	return get_tree().root

## Single entry point for spawning run-scoped nodes.
func spawn(node: Node, deferred: bool = false) -> void:
	if node == null:
		return
	node.add_to_group("run_entity")
	var parent := world_root()
	if deferred:
		parent.call_deferred("add_child", node)
	else:
		parent.add_child(node)

## Destroys every run-scoped entity still alive anywhere in the tree.
func purge_run_entities() -> int:
	var tree := get_tree()
	if tree == null:
		return 0
	var n := 0
	var seen: Dictionary = {}
	for g in RUN_GROUPS:
		for node in tree.get_nodes_in_group(g):
			if not is_instance_valid(node) or seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			node.queue_free()
			n += 1
	return n

func reset() -> void:
	# Kill anything left over from the previous run before touching state.
	purge_run_entities()
	endless_time = 0.0
	overcharge_levels = 0
	# Clear the previous scene's player reference before constructing a new run.
	player = null
	score = 0
	scrap = 0
	current_wave = 1
	game_time = 0.0
	threat_level = 1
	threat_label = "LOW"
	is_paused = false
	is_game_over = false
	is_boss_phase = false
	is_victory = false
	boss_spawned_flag = false
	player_luck = 0.0
	active_relics.clear()
	relic_offers_seen.clear()
	active_evolutions.clear()
	active_synergies.clear()
	upgrade_levels.clear()
	apply_signature_weapon()
	mission_text = ""
	mission_progress = 0
	mission_target = 0
	elites_killed = 0
	rerolls_available = BASE_REROLLS
	run_kills = 0
	run_scrap_earned = 0
	run_scrap_spent = 0
	run_upgrade_bonuses.clear()
	damage_by_weapon.clear()
	event_scrap_multiplier = 1.0
	event_scrap_time = 0.0
	event_enemy_speed_multiplier = 1.0
	event_enemy_time = 0.0
	cursed_upgrades.clear()
	build_tags.clear()
	set_sector(0)
	score_changed.emit(score)
	scrap_changed.emit(scrap)
	wave_changed.emit(current_wave)
	luck_changed.emit(player_luck)
	_roll_mission()
	_roll_contracts()

func finalize_run(victory_run: bool) -> void:
	total_runs += 1
	banked_scrap += scrap
	mastery_xp[selected_character] = int(mastery_xp.get(selected_character, 0)) + int(game_time)
	if victory_run:
		record_boss_defeated()
	_check_achievements()
	_save_progress()

func set_sector(index: int) -> void:
	sector_index = clampi(index, 0, SECTORS.size() - 1)
	current_sector = SECTORS[sector_index].name
	current_sector_gimmick = SECTORS[sector_index].gimmick
	sector_changed.emit(current_sector, current_sector_gimmick)

func get_sector_bias() -> String:
	return SECTORS[sector_index].enemy_bias

func get_build_summary() -> String:
	var parts: Array[String] = []
	for id in WEAPON_UPGRADES:
		if get_upgrade_level(id) > 0:
			parts.append(str(WEAPON_DEFS[id].name).to_upper())
	for id in ["radiation", "explode_on_hit", "cryo_field", "crit", "lifesteal"]:
		if get_upgrade_level(id) >= 1:
			parts.append(id.replace("_", " ").to_upper())
	build_tags = parts.slice(0, 4)
	var summary: String = " • ".join(build_tags) if not build_tags.is_empty() else "BUILD IN PROGRESS"
	if not active_synergies.is_empty():
		var synergy_name: String = str(WEAPON_SYNERGIES[active_synergies[0]].get("name", "SUPERWEAPON"))
		return summary + "  •  ★ " + synergy_name
	return summary

func apply_cursed_upgrade(id: String) -> bool:
	if id in cursed_upgrades or not player:
		return false
	cursed_upgrades.append(id)
	match id:
		"glass_reactor":
			player.damage *= 2.0
			player.max_hp *= 0.5
			player.current_hp = mini(player.current_hp, player.max_hp)
		"unstable_ai":
			player.fire_rate = max(0.05, player.fire_rate * 0.35)
		"void_core":
			player.gem_value_mult *= 1.5
			event_enemy_speed_multiplier *= 1.2
		"blood_battery":
			player.lifesteal = true
			player.max_hp *= 0.9
	mastery_reward.emit("CURSED TECH: " + id.replace("_", " ").to_upper())
	return true

func check_mastery_rewards() -> void:
	var m := mastery_percent(selected_character)
	var rewards = [25, 50, 75, 100]
	for threshold in rewards:
		var key = selected_character + "_" + str(threshold)
		if m >= threshold and not mastery_rewards_claimed.get(key, false):
			mastery_rewards_claimed[key] = true
			if threshold == 25: add_score(500)
			elif threshold == 50: add_scrap(150)
			elif threshold == 75: add_luck(8)
			else: codex_entries["mastery_" + selected_character] = true
			mastery_reward.emit("%s MASTERY %d%% REWARD" % [selected_character.to_upper(), threshold])
	_save_progress()

func find_secret(id: String, text: String) -> void:
	if secret_flags.get(id, false):
		return
	secret_flags[id] = true
	codex_entries["secret_" + id] = true
	add_score(750)
	add_scrap(100)
	secret_found.emit(text)
	_save_progress()

func get_progress_summary() -> String:
	return "BANKED SCRAP %d  •  RUNS %d  •  KILLS %d" % [banked_scrap, total_runs, total_kills]

func get_contract_text() -> String:
	var out: Array[String] = []
	for c in current_contracts:
		out.append("%s  %d/%d  +%d" % [c.title, int(c.progress), int(c.target), int(c.reward)])
	return "\n".join(out)

func get_time_left() -> float:
	return max(0.0, RUN_DURATION - game_time)

func get_character_data() -> Dictionary:
	return CHARACTERS.get(selected_character, CHARACTERS["viper"])

func add_luck(amount: float) -> void:
	player_luck += amount
	luck_changed.emit(player_luck)

func get_upgrade_level(id: String) -> int:
	return int(upgrade_levels.get(id, 0))

func is_milestone_level(level: int) -> bool:
	return level in MILESTONE_LEVELS

func is_relic_milestone(level: int) -> bool:
	return level in RELIC_MILESTONES

func is_rare_milestone(level: int) -> bool:
	return level == RARE_MILESTONE

func use_reroll() -> bool:
	if rerolls_available <= 0 or rerolls_available > MAX_REROLLS_PER_RUN:
		return false
	rerolls_available -= 1
	return true


func get_rarity_name(rarity: int) -> String:
	return RARITY_NAMES[clampi(rarity, 0, RARITY_NAMES.size() - 1)]

func get_rarity_value(rarity: int) -> float:
	return RARITY_VALUES[clampi(rarity, 0, RARITY_VALUES.size() - 1)]

func get_upgrade_roll_value(id: String, rarity: int) -> float:
	if CORE_DEFS.has(id):
		return float(CORE_DEFS[id]["step"]) * float(RARITY_MULT[clampi(rarity, 0, RARITY_MULT.size() - 1)])
	var values: Array = UPGRADE_RARITY_VALUES.get(id, RARITY_VALUES)
	return float(values[clampi(rarity, 0, values.size() - 1)]) if not values.is_empty() else 0.0

func core_cap(id: String) -> int:
	if is_modifier_upgrade(id):
		return 1 if id == "lifesteal" else 3
	return int(CORE_DEFS.get(id, {}).get("cap", MAX_UPGRADE_LEVEL))

func system_tier_text(id: String, tier_index: int) -> String:
	var tiers: Array = SYSTEM_TIERS.get(id, [])
	if tiers.is_empty():
		return ""
	return str(tiers[clampi(tier_index, 0, tiers.size() - 1)])

func distinct_system_count() -> int:
	var n := 0
	for id in SYSTEM_UPGRADES:
		if get_upgrade_level(id) > 0:
			n += 1
	return n

func get_equipped_weapon_ids() -> Array[String]:
	var equipped: Array[String] = []
	for id in WEAPON_UPGRADES:
		if get_upgrade_level(id) > 0:
			equipped.append(id)
	return equipped

func is_system_compatible(id: String) -> bool:
	if not SYSTEM_COMPATIBILITY.has(id):
		return false
	var allowed: Array = SYSTEM_COMPATIBILITY[id]
	for weapon_id in get_equipped_weapon_ids():
		if weapon_id in allowed:
			return true
	return false

func get_system_compatibility_ids(id: String) -> Array[String]:
	var result: Array[String] = []
	if not SYSTEM_COMPATIBILITY.has(id):
		return result
	var allowed: Array = SYSTEM_COMPATIBILITY[id]
	for weapon_id in get_equipped_weapon_ids():
		if weapon_id in allowed:
			result.append(weapon_id)
	return result

func get_system_compatibility(id: String) -> String:
	var ids := get_system_compatibility_ids(id)
	var labels: Array[String] = []
	for weapon_id in ids:
		labels.append(str(WEAPON_DEFS.get(weapon_id, {}).get("name", weapon_id)))
	return " • ".join(labels)

func get_system_effect_text(id: String) -> String:
	var effects: Dictionary = SYSTEM_EFFECT_TEXT.get(id, {})
	var labels: Array[String] = []
	for weapon_id in get_system_compatibility_ids(id):
		labels.append(str(effects.get(weapon_id, "Compatible system effect")))
	return " • ".join(labels)

## Damage accounting (3.19): callers announce the SOURCE of the hit they are about to land;
## the enemy's take_damage() commits the EFFECTIVE amount (after armor / burst caps, capped
## at remaining HP, never against a dead target). Attempted/overkill damage is not charted.
## Attribution is atomic (3.19.1): record_damage() announces the source for the very next
## take_damage() call, which CONSUMES it at entry — before shield, dead-target or zero-damage
## exits — so a blocked hit can never leave a source behind for an unrelated later hit.
var _pending_source: String = ""
func record_damage(source_id: String, _attempted: float) -> void:
	_pending_source = source_id

func consume_damage_source() -> String:
	var s := _pending_source
	_pending_source = ""
	return s

func commit_damage(effective: float, source_id: String) -> void:
	if effective <= 0.0:
		return
	var src := source_id if source_id != "" else "other"
	damage_by_weapon[src] = float(damage_by_weapon.get(src, 0.0)) + effective

func fmt_compact(v: float) -> String:
	if v >= 1.0e9: return "%.2fB" % (v / 1.0e9)
	if v >= 1.0e6: return "%.2fM" % (v / 1.0e6)
	if v >= 1.0e5: return "%.0fK" % (v / 1.0e3)
	if v >= 1.0e3: return "%.1fK" % (v / 1.0e3)
	return "%.0f" % v

func get_damage_breakdown_text() -> String:
	if damage_by_weapon.is_empty():
		return "DAMAGE BREAKDOWN\nNO DAMAGE RECORDED"
	var entries: Array[Dictionary] = []
	var total: float = 0.0
	for source_id in damage_by_weapon.keys():
		var amount: float = float(damage_by_weapon[source_id])
		if amount <= 0.0:
			continue
		total += amount
		entries.append({"id": str(source_id), "amount": amount})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["amount"]) > float(b["amount"]))
	var lines: Array[String] = []
	for i in range(mini(8, entries.size())):
		var entry: Dictionary = entries[i]
		var label: String = str(DAMAGE_SOURCE_NAMES.get(str(entry["id"]), str(entry["id"]).replace("_", " ").to_upper()))
		var amount: float = float(entry["amount"])
		var pct: float = amount / total * 100.0 if total > 0.0 else 0.0
		lines.append("%-22s %7.0f   %4.1f%%" % [label, amount, pct])
	return "DAMAGE BREAKDOWN\n" + "\n".join(lines)

func get_damage_chart_bbcode() -> String:
	if damage_by_weapon.is_empty():
		return "[font_size=18][b]EFFECTIVE DAMAGE[/b][/font_size]\n[font_size=11][color=#8190a8]No damage recorded.[/color][/font_size]"
	var total: float = 0.0
	for k in damage_by_weapon: total += maxf(0.0, float(damage_by_weapon[k]))
	var secs: float = maxf(1.0, game_time)
	var groups := {"WEAPONS": [], "SUPERWEAPONS": [], "RELICS": [], "SHIP ABILITY": []}
	for source_id in damage_by_weapon.keys():
		var amount: float = float(damage_by_weapon[source_id])
		if amount <= 0.0: continue
		var sid := str(source_id)
		var g := "WEAPONS"
		if WEAPON_SYNERGIES.has(sid): g = "SUPERWEAPONS"
		elif sid in ["orbit_drones", "thorns", "relic"]: g = "RELICS"
		elif sid in ["ship_ability", "ship_signature"]: g = "SHIP ABILITY"
		groups[g].append({"id": sid, "amount": amount})
	var out := "[font_size=20][b]EFFECTIVE DAMAGE[/b][/font_size]\n[font_size=11][color=#8ea0b8]TOTAL  %s   •   %s DPS over %02d:%02d[/color][/font_size]\n" % [fmt_compact(total), fmt_compact(total / secs), int(secs) / 60, int(secs) % 60]
	var colors := {"WEAPONS": "#59d9ff", "SUPERWEAPONS": "#ffbd5a", "RELICS": "#70f0a7", "SHIP ABILITY": "#ff88aa"}
	for g in ["WEAPONS", "SUPERWEAPONS", "RELICS", "SHIP ABILITY"]:
		var entries: Array = groups[g]
		if entries.is_empty(): continue
		entries.sort_custom(func(a, b): return float(a["amount"]) > float(b["amount"]))
		out += "\n[font_size=12][color=%s][b]%s[/b][/color][/font_size]\n" % [colors[g], g]
		for e in entries:
			var name: String = str(DAMAGE_SOURCE_NAMES.get(str(e["id"]), str(e["id"]).replace("_", " ").to_upper()))
			var amount: float = float(e["amount"])
			var pct: float = amount / total * 100.0 if total > 0.0 else 0.0
			var bar: String = "█".repeat(clampi(int(round(pct / 6.0)), 1, 16))
			out += "[font_size=11][b]%s[/b]   [color=%s]%s[/color]  %5.1f%%   %s   [color=#8ea0b8]%s/s[/color][/font_size]\n" % [name, colors[g], bar, pct, fmt_compact(amount), fmt_compact(amount / secs)]
	return out

func roll_upgrade_rarity(minimum: int = 0) -> int:
	# Luck moves weight out of Common into the higher tiers, 0.5 points per Luck,
	# capped at 40 Luck: 70/20/7/2.5/0.5 -> 50/28/13/6/3. Legendary stays rare.
	var luck := clampf(player_luck, 0.0, LUCK_CAP)
	var weights := [RARITY_BASE_WEIGHTS[0] - luck * 0.5, RARITY_BASE_WEIGHTS[1] + luck * 0.2, RARITY_BASE_WEIGHTS[2] + luck * 0.15, RARITY_BASE_WEIGHTS[3] + luck * 0.0875, RARITY_BASE_WEIGHTS[4] + luck * 0.0625]
	var total := 0.0
	for w in weights:
		total += w
	var roll := randf() * total
	var rarity := 0
	for i in range(weights.size()):
		roll -= weights[i]
		if roll <= 0.0:
			rarity = i
			break
	return maxi(rarity, minimum)

func get_run_upgrade_bonus(id: String) -> float:
	return float(run_upgrade_bonuses.get(id, 0.0))

func get_run_upgrade_cap(id: String) -> float:
	return -1.0

func add_run_upgrade_bonus(id: String, requested: float) -> float:
	var gained: float = maxf(0.0, requested)
	run_upgrade_bonuses[id] = get_run_upgrade_bonus(id) + gained
	return gained

func is_run_upgrade_capped(id: String) -> bool:
	return false

func rarity_upgrade_desc(id: String, rarity: int, level: int) -> String:
	if is_weapon_upgrade(id):
		var lv_texts: Array = WEAPON_DEFS[id].get("levels", [])
		var idx: int = clampi(level, 0, lv_texts.size() - 1)
		if lv_texts.size() > 0:
			return "%s  •  %d/%d" % [str(lv_texts[idx]), level + 1, MAX_WEAPON_LEVEL]
		return WEAPON_DEFS[id].name
	if is_system_upgrade(id):
		return "%s  •  TIER %d/%d" % [system_tier_text(id, level), level + 1, MAX_SYSTEM_LEVEL]
	var value: float = get_upgrade_roll_value(id, rarity)
	var max_level: int = core_cap(id)
	var next_text: String = "%d/%d" % [level, max_level]
	var pct: int = int(round(value * 100.0))
	match id:
		"damage": return "+%d%% Damage • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"speed": return "+%d%% Move Speed • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"fire_rate": return "+%d%% Fire Rate • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"projectile_speed": return "+%d%% Projectile Speed • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"max_hp": return "+%d%% Max Hull + repair • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"xp_magnet": return "+%d%% Magnet Range • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"xp_gain": return "+%d%% XP Gain • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"scrap": return "+%d%% Scrap Gain • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"luck": return "+%d Luck • %s • %s" % [int(round(value)), get_rarity_name(rarity), next_text]
		"crit": return "+%d%% Crit Chance • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"proj_size": return "+%d%% Projectile Size • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"aura_size": return "+%d%% Aura / Blast Radius • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"explode_damage": return "+%d%% Explosion Damage • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"extra_projectile": return "+1 Projectile • %s • %s" % [get_rarity_name(rarity), next_text]
		"pierce": return "+1 Pierce • %s • %s" % [get_rarity_name(rarity), next_text]
		"area": return "+%d%% Area • %s • %s" % [pct, get_rarity_name(rarity), next_text]
		"explode_on_hit": return "Enable projectile explosions • %s • %s" % [get_rarity_name(rarity), next_text]
		"slow_field": return "Nearby enemies slowed • %s • %s" % [get_rarity_name(rarity), next_text]
		"lifesteal": return "Recover hull on kills • %s • %s" % [get_rarity_name(rarity), next_text]
	return "%s • %s" % [available_upgrade_name(id), next_text]

func available_upgrade_name(id: String) -> String:
	if WEAPON_DEFS.has(id):
		return str(WEAPON_DEFS[id].name)
	for up in available_upgrades:
		if str(up.get("id", "")) == id:
			return str(up.get("name", id))
	return id

func is_weapon_upgrade(id: String) -> bool:
	return id in WEAPON_UPGRADES

func is_system_upgrade(id: String) -> bool:
	return id in SYSTEM_UPGRADES

func is_modifier_upgrade(id: String) -> bool:
	return id in MODIFIER_UPGRADES

func get_weapon_slot_limit() -> int:
	return mini(MAX_WEAPON_SLOTS, MAX_WEAPON_SLOTS_BASE + int(permanent_upgrades.get("arsenal", 0)))

func weapon_slot_count() -> int:
	var count := 0
	for id in WEAPON_UPGRADES:
		if get_upgrade_level(id) > 0:
			count += 1
	return count

func unique_upgrade_count() -> int:
	var count := 0
	for id in upgrade_levels.keys():
		var sid := str(id)
		if sid.begins_with("oc_"):
			continue
		if not is_modifier_upgrade(sid) and not is_system_upgrade(sid) and not is_weapon_upgrade(sid):
			count += 1
	return count

func _upgrade_max_level(id: String) -> int:
	if id.begins_with("oc_"):
		return 999999
	if is_weapon_upgrade(id):
		return MAX_WEAPON_LEVEL
	if is_system_upgrade(id):
		return MAX_SYSTEM_LEVEL
	if is_modifier_upgrade(id):
		return 1 if id == "lifesteal" else 3
	return core_cap(id)

func system_has_compatible_weapon(id: String) -> bool:
	return is_system_compatible(id)

func can_take_upgrade(id: String) -> bool:
	if id.begins_with("oc_"):
		return true   # overcharge: run-only, uncapped, outside the distinct-core limit
	var lv := get_upgrade_level(id)
	if lv >= _upgrade_max_level(id):
		return false
	if is_weapon_upgrade(id) and lv == 0 and weapon_slot_count() >= get_weapon_slot_limit():
		return false
	if is_system_upgrade(id) and not system_has_compatible_weapon(id):
		return false
	if is_system_upgrade(id) and lv == 0 and distinct_system_count() >= MAX_SYSTEMS_DISTINCT:
		return false
	if is_run_upgrade_capped(id):
		return false
	if lv > 0:
		return true
	if is_weapon_upgrade(id) or is_system_upgrade(id) or is_modifier_upgrade(id):
		return true
	return unique_upgrade_count() < MAX_UNIQUE_UPGRADES

func has_any_available_upgrade() -> bool:
	for up in available_upgrades:
		if can_take_upgrade(str(up.get("id", ""))):
			return true
	return false

func level_up_upgrade(id: String) -> void:
	var lv := get_upgrade_level(id)
	var max_level := _upgrade_max_level(id)
	if lv >= max_level:
		return
	if is_weapon_upgrade(id) and lv == 0 and weapon_slot_count() >= get_weapon_slot_limit():
		return
	if lv == 0 and not is_modifier_upgrade(id) and not is_system_upgrade(id) and not is_weapon_upgrade(id) and unique_upgrade_count() >= MAX_UNIQUE_UPGRADES:
		return
	upgrade_levels[id] = lv + 1
	upgrade_levels_changed.emit()
	_check_evolutions()
	_check_weapon_synergies()

func _check_evolutions() -> void:
	# Weapon evolutions are now handled exclusively by _check_weapon_synergies.
	# This prevents the old stat-only evolution system from competing with true
	# weapon transformations.
	return

func _check_weapon_synergies() -> void:
	for synergy_id in WEAPON_SYNERGIES.keys():
		if synergy_id in active_synergies:
			continue
		var synergy: Dictionary = WEAPON_SYNERGIES[synergy_id]
		var reqs: Array = synergy.get("requires", [])
		if reqs.size() == 2 and get_upgrade_level(str(reqs[0])) >= MAX_WEAPON_LEVEL and get_upgrade_level(str(reqs[1])) >= MAX_WEAPON_LEVEL:
			active_synergies.append(synergy_id)
			active_evolutions.append(synergy_id)
			codex_entries["synergy_" + synergy_id] = true
			_save_progress()
			evolution_unlocked.emit(str(synergy.get("name", synergy_id)))
			synergy_activated.emit(synergy_id)
func gain_relic(relic_id: String) -> void:
	if relic_id == "" or relic_id in active_relics:
		return
	active_relics.append(relic_id)
	for r in available_relics:
		if r.id == relic_id:
			relic_gained.emit(r.name)
			break
	if player and player.has_method("on_relic_gained"):
		player.on_relic_gained(relic_id)

func _roll_mission() -> void:
	var missions = [
		{"text": "Kill 4 elites", "type": "elites", "target": 4},
		{"text": "Reach wave 6", "type": "wave", "target": 6},
		{"text": "Collect 100 scrap", "type": "scrap", "target": 100},
		{"text": "Reach level 12", "type": "level", "target": 12},
	]
	var m = missions[randi() % missions.size()]
	mission_text = m.text
	mission_target = m.target
	mission_progress = 0
	mission_updated.emit(mission_text + "  (0/%d)" % mission_target)

func update_mission(type: String, amount: int = 1) -> void:
	if mission_target <= 0:
		return
	match type:
		"elites":
			if "elite" in mission_text.to_lower():
				mission_progress = mini(mission_progress + amount, mission_target)
		"wave":
			if "wave" in mission_text.to_lower():
				mission_progress = current_wave
		"scrap":
			if "scrap" in mission_text.to_lower():
				mission_progress = scrap
		"level":
			if "level" in mission_text.to_lower() and player:
				mission_progress = player.level
	mission_updated.emit("%s  (%d/%d)" % [mission_text, mission_progress, mission_target])
	if mission_progress >= mission_target and mission_target > 0:
		add_scrap(45)
		add_score(600)
		if player:
			player.add_xp(50)
		mission_text = "Mission Complete!"
		mission_target = 0
		mission_updated.emit(mission_text)

func get_upgrade_category(id: String) -> String:
	if is_weapon_upgrade(id):
		return "WEAPONS"
	if is_system_upgrade(id):
		return "SYSTEMS"
	if is_modifier_upgrade(id):
		return "MODIFIERS"
	return "UPGRADES"

func get_upgrade_description(id: String) -> String:
	if WEAPON_DEFS.has(id):
		return str(WEAPON_DEFS[id].desc)
	var text = {
		"explosive": "Projectiles detonate on impact. Tier 2 widens the blast, tier 3 adds blast damage.",
		"duration": "Beams, coils, mines, fire pools, freezes and phase marks last 25% longer per tier.",
		"homing": "Cannon, broadside and scatter shots curve toward targets; torpedoes steer harder.",
		"incendiary": "Projectile, beam and chain hits ignite enemies with a stacking burn.",
		"cryo_rounds": "Projectile hits build freeze; tier 3 makes frozen enemies take extra projectile damage.",
		"damage":"Increases all weapon damage. Higher rarity gives a larger roll.",
		"speed":"Increases ship movement speed.",
		"fire_rate":"Weapons fire more often.",
		"projectile_speed":"Projectiles travel faster.",
		"max_hp":"Raises maximum hull and restores the same amount.",
		"xp_magnet":"Increases pickup and XP collection radius.",
		"xp_gain":"Improves XP gained from pickups.",
		"scrap":"Increases Scrap earned from pickups and run rewards.",
		"luck":"Raises luck, improving future rarity rolls.",
		"crit":"Raises critical strike chance.",
		"extra_projectile":"Adds one additional projectile to your primary fire.",
		"pierce":"Lets projectiles pass through one additional enemy.",
		"area":"Widens projectile spread and increases the reach of area-based effects.",
		"proj_size":"Makes projectiles larger and slightly increases explosion reach.",
		"radiation":"Damages enemies in an aura around the ship.",
		"aura_size":"Expands radiation, mine and blast radii.",
		"explode_on_hit":"Your projectiles explode when they hit enemies.",
		"explode_damage":"Increases the damage dealt by projectile explosions.",
		"side_guns":"Adds side-mounted shots to your primary fire.",
		"cryo_field":"Creates a persistent cryo field that pulses damage and freezes enemies after enough exposure.",
		"slow_field":"Nearby enemies move more slowly.",
		"lifesteal":"Recover a small amount of hull when enemies die."
	}
	return str(text.get(id, available_upgrade_name(id)))

func _build_upgrade_entry(up: Dictionary, minimum_rarity: int = 0) -> Dictionary:
	var entry: Dictionary = up.duplicate(true)
	var id := str(up.get("id", ""))
	var lv := get_upgrade_level(id)
	var rarity := roll_upgrade_rarity(minimum_rarity)
	entry["rarity"] = 0 if is_weapon_upgrade(id) else rarity
	entry["current_level"] = lv
	entry["category"] = get_upgrade_category(id)
	entry["details"] = get_upgrade_description(id)
	entry["rolled_desc"] = rarity_upgrade_desc(id, rarity, lv)
	return entry

func get_random_upgrades(count: int = 3, category: String = "ALL") -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for up in available_upgrades:
		var id := str(up.get("id", ""))
		if category != "ALL" and get_upgrade_category(id) != category:
			continue
		if is_system_upgrade(id) and not is_system_compatible(id):
			continue
		if not can_take_upgrade(id):
			continue
		var weight := 1.0
		var lv := get_upgrade_level(id)
		if lv > 0:
			weight += 3.0
		else:
			weight += 1.5
		for evo_id in EVOLUTIONS.keys():
			var reqs: Array = EVOLUTIONS[evo_id].requires
			if id == reqs[0] and get_upgrade_level(reqs[1]) >= 1:
				weight += 4.0
			elif id == reqs[1] and get_upgrade_level(reqs[0]) >= 1:
				weight += 4.0
		for i in range(maxi(1, int(weight))):
			candidates.append(up)
	candidates.shuffle()
	var result: Array[Dictionary] = []
	var used_ids: Array[String] = []
	for up in candidates:
		var id := str(up.get("id", ""))
		if id in used_ids:
			continue
		result.append(_build_upgrade_entry(up, 0))
		used_ids.append(id)
		if result.size() >= count:
			break
	return result

# ---------------------------------------------------------------------------
# Level-up composition (3.17). Three cards, built by category so every level-up
# is a real decision: a weapon opportunity, a build-relevant system, and a core
# stat (or a relic / rare blueprint on milestones). Rerolls call the same builder.
# ---------------------------------------------------------------------------
func _entry_for(id: String, min_rarity: int = 0) -> Dictionary:
	for up in available_upgrades:
		if str(up.get("id", "")) == id:
			return _build_upgrade_entry(up, min_rarity)
	return {}

func _weapon_weight(id: String) -> float:
	var lv := get_upgrade_level(id)
	var w := 0.0
	if lv > 0:
		w = 3.0 + lv * 0.4                       # owned weapons keep showing up
	else:
		w = 1.0
	# Synergy encouragement: partner of an owned weapon.
	for sid in WEAPON_SYNERGIES.keys():
		var reqs: Array = WEAPON_SYNERGIES[sid].get("requires", [])
		if id not in reqs:
			continue
		var other := str(reqs[0] if str(reqs[1]) == id else reqs[1])
		var olv := get_upgrade_level(other)
		if olv > 0:
			w += 1.5 + olv * 0.6                 # stronger as the partner levels
	return w

func _pick_weighted(pool: Array, weights: Array) -> Variant:
	var total := 0.0
	for w in weights:
		total += float(w)
	if total <= 0.0:
		return null
	var r := randf() * total
	for i in range(pool.size()):
		r -= float(weights[i])
		if r <= 0.0:
			return pool[i]
	return pool[pool.size() - 1]

func _relic_entry(relic: Dictionary) -> Dictionary:
	return {
		"id": "relic_" + str(relic.get("id", "")), "name": "RELIC: " + str(relic.get("name", "")),
		"desc": str(relic.get("desc", "")), "details": str(relic.get("desc", "")),
		"icon_color": relic.get("color", Color.WHITE), "rarity": 2, "is_relic": true,
		"relic_id": str(relic.get("id", "")), "current_level": 0, "category": "MODIFIERS",
	}

func build_levelup_choices(count: int = LEVELUP_CHOICES, level: int = 1) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var used: Dictionary = {}
	var min_rarity := 2 if is_rare_milestone(level) else 0
	# --- pools ---
	var weapon_new: Array = []
	var weapon_owned: Array = []
	var slot_open := weapon_slot_count() < get_weapon_slot_limit()
	for id in WEAPON_UPGRADES:
		if not can_take_upgrade(id):
			continue
		if get_upgrade_level(id) > 0:
			weapon_owned.append(id)
		elif slot_open:
			weapon_new.append(id)
	var systems: Array = []
	for id in SYSTEM_UPGRADES:
		if can_take_upgrade(id):
			systems.append(id)
	var cores: Array = []
	for id in CORE_DEFS.keys():
		if can_take_upgrade(id):
			cores.append(id)
	var modifiers: Array = []
	for id in MODIFIER_UPGRADES:
		if can_take_upgrade(id):
			modifiers.append(id)

	# --- slot 1: weapon opportunity ---
	var owned_count := weapon_slot_count()
	var weapon_pool: Array = weapon_owned.duplicate()
	# New weapons are guaranteed candidates until the 2nd weapon; after that they
	# compete with upgrades at a rising discount so late slots still fill.
	var new_share := 1.0 if owned_count < 2 else (0.5 if owned_count < 3 else 0.35)
	if slot_open and randf() < new_share and not weapon_new.is_empty():
		weapon_pool = weapon_new.duplicate()
	elif weapon_pool.is_empty():
		weapon_pool = weapon_new.duplicate()
	if not weapon_pool.is_empty():
		var wts: Array = []
		for id in weapon_pool:
			wts.append(_weapon_weight(id))
		var wid = _pick_weighted(weapon_pool, wts)
		if wid != null:
			result.append(_entry_for(str(wid), 0))
			used[str(wid)] = true

	# --- slot 2: build-relevant system (or a second weapon card if none fit) ---
	var sys_candidates: Array = systems.filter(func(x): return not used.has(x))
	if not sys_candidates.is_empty() and randf() < 0.75:
		var wts2: Array = []
		for id in sys_candidates:
			wts2.append(2.5 if get_upgrade_level(id) > 0 else 1.0)
		var sid = _pick_weighted(sys_candidates, wts2)
		result.append(_entry_for(str(sid), 0))
		used[str(sid)] = true
	elif not weapon_owned.is_empty() or not weapon_new.is_empty():
		var alt: Array = (weapon_owned + weapon_new).filter(func(x): return not used.has(x))
		if not alt.is_empty():
			var wts3: Array = []
			for id in alt:
				wts3.append(_weapon_weight(id))
			var aid = _pick_weighted(alt, wts3)
			result.append(_entry_for(str(aid), 0))
			used[str(aid)] = true

	# --- slot 3: relic on milestones, otherwise a core stat / modifier ---
	if is_relic_milestone(level):
		var relics := get_random_relics(1)
		if not relics.is_empty():
			result.append(_relic_entry(relics[0]))
			used["relic"] = true
	if result.size() < count:
		var core_pool: Array = (cores + modifiers).filter(func(x): return not used.has(x))
		if not core_pool.is_empty():
			var wts4: Array = []
			for id in core_pool:
				# Owned stats show a bit more (finish what you started), Luck/econ a bit less.
				var w := 1.0 + (0.8 if get_upgrade_level(id) > 0 else 0.0)
				if id in ["luck", "scrap", "xp_gain"]:
					w *= 0.7
				wts4.append(w)
			var cid = _pick_weighted(core_pool, wts4)
			result.append(_entry_for(str(cid), min_rarity))
			used[str(cid)] = true

	# --- fill any gaps from whatever remains ---
	var everything: Array = (weapon_owned + weapon_new + systems + cores + modifiers).filter(func(x): return not used.has(x))
	everything.shuffle()
	for id in everything:
		if result.size() >= count:
			break
		result.append(_entry_for(str(id), min_rarity if not is_weapon_upgrade(str(id)) and not is_system_upgrade(str(id)) else 0))
		used[str(id)] = true
	# Overcharge fallback: nothing left to offer -> three small run-only bonuses.
	if result.is_empty():
		var ids: Array = OVERCHARGE_DEFS.keys()
		ids.shuffle()
		for k in range(mini(count, ids.size())):
			var oid := str(ids[k])
			var d: Dictionary = OVERCHARGE_DEFS[oid]
			result.append({"id": oid, "name": d.name, "desc": d.desc, "details": "OVERCHARGE  •  " + str(d.desc) + "  •  taken %d times" % overcharge_levels,
				"icon_color": d.color, "rarity": 0, "current_level": overcharge_levels, "category": "OVERCHARGE", "is_overcharge": true})
	return result.slice(0, count)

# ---------------------------------------------------------------------------
# Merchant (3.17): generated per visit, one purchase per offer, one paid refresh.
# ---------------------------------------------------------------------------
var merchant_visit: int = 0
var merchant_offers: Array = []
var merchant_refreshed: bool = false
var merchant_purchases: int = 0
var merchant_reroll_bought: bool = false

func merchant_cost_mult() -> float:
	return (1.0 + 0.45 * float(maxi(0, merchant_visit - 1))) * (1.0 + 0.2 * float(merchant_purchases))

func open_merchant_visit() -> void:
	merchant_visit += 1
	merchant_refreshed = false
	merchant_purchases = 0
	merchant_offers = generate_merchant_offers()

func generate_merchant_offers() -> Array:
	var offers: Array = []
	var m := merchant_cost_mult()
	# 1. Weapon crate: a new weapon if a slot is open, otherwise a level for an owned weapon.
	var slot_open := weapon_slot_count() < get_weapon_slot_limit()
	var wpool: Array = []
	for id in WEAPON_UPGRADES:
		if can_take_upgrade(id) and ((get_upgrade_level(id) == 0 and slot_open) or get_upgrade_level(id) > 0):
			wpool.append(id)
	if not wpool.is_empty():
		var wts: Array = []
		for id in wpool:
			wts.append(_weapon_weight(id))
		var wid := str(_pick_weighted(wpool, wts))
		var lv := get_upgrade_level(wid)
		offers.append({"kind": "weapon", "id": wid, "name": ("WEAPON CRATE: " if lv == 0 else "UPGRADE KIT: ") + str(WEAPON_DEFS[wid].name),
			"desc": (str(WEAPON_DEFS[wid].desc) if lv == 0 else rarity_upgrade_desc(wid, 0, lv)), "cost": int((220 if lv == 0 else 180) * m), "color": WEAPON_DEFS[wid].color})
	# 2. System module.
	var spool: Array = []
	for id in SYSTEM_UPGRADES:
		if can_take_upgrade(id):
			spool.append(id)
	if not spool.is_empty():
		var sid := str(spool[randi() % spool.size()])
		offers.append({"kind": "system", "id": sid, "name": "MODULE: " + available_upgrade_name(sid), "desc": rarity_upgrade_desc(sid, 0, get_upgrade_level(sid)), "cost": int(170 * m), "color": Color(0.5, 0.9, 1.0)})
	# 3-4. Two core stat items, rolled at least Uncommon (they still count against the caps).
	var cpool: Array = []
	for id in CORE_DEFS.keys():
		if can_take_upgrade(id):
			cpool.append(id)
	cpool.shuffle()
	for i in range(mini(2, cpool.size())):
		var cid := str(cpool[i])
		var rarity := roll_upgrade_rarity(1)
		offers.append({"kind": "core", "id": cid, "rarity": rarity, "name": available_upgrade_name(cid), "desc": rarity_upgrade_desc(cid, rarity, get_upgrade_level(cid)), "cost": int(110 * m * RARITY_MULT[rarity] / RARITY_MULT[1]), "color": Color(1.0, 0.85, 0.5)})
	# 5. Utility: repair / barrier / reroll token / magnet.
	var utils: Array = [
		{"kind": "heal", "id": "heal", "name": "HULL REPAIR", "desc": "Restore 40% of max hull", "cost": int(80 * m), "color": Color(1.0, 0.3, 0.35)},
		{"kind": "shield", "id": "shield", "name": "EMERGENCY BARRIER", "desc": "Survive one lethal hit", "cost": int(230 * m), "color": Color(0.5, 0.8, 1.0)},
		{"kind": "magnet", "id": "magnet", "name": "SALVAGE SWEEP", "desc": "Activate a 6s magnet pulse now", "cost": int(60 * m), "color": Color(0.75, 0.45, 1.0)},
	]
	if not merchant_reroll_bought and rerolls_available < MAX_REROLLS_PER_RUN:
		utils.append({"kind": "reroll", "id": "reroll", "name": "REROLL TOKEN", "desc": "+1 level-up reroll (once per run)", "cost": int(160 * m), "color": Color(0.9, 0.9, 1.0)})
	utils.shuffle()
	offers.append(utils[0])
	if is_instance_valid(player) and float(player.current_hp) < float(player.max_hp) * 0.6 and utils[0]["kind"] != "heal":
		offers.append(utils.filter(func(u): return u["kind"] == "heal")[0])
	# 6. Black market relic from the second visit on.
	if merchant_visit >= 2 and randf() < 0.55:
		var rpool: Array = []
		for r in available_relics:
			if str(r.get("id", "")) not in active_relics:
				rpool.append(r)
		if not rpool.is_empty():
			var r: Dictionary = rpool[randi() % rpool.size()]
			offers.append({"kind": "relic", "id": str(r.id), "name": "BLACK MARKET: " + str(r.name), "desc": str(r.desc), "cost": int(380 * m), "color": r.get("color", Color.WHITE)})
	for o in offers:
		o["bought"] = false
	return offers

func merchant_refresh_cost() -> int:
	return int(60 * merchant_cost_mult())

func merchant_refresh() -> bool:
	if merchant_refreshed or not spend_scrap(merchant_refresh_cost()):
		return false
	merchant_refreshed = true
	merchant_offers = generate_merchant_offers()
	return true

func get_random_relics(count: int = 3) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for r in available_relics:
		var rid: String = str(r.get("id", ""))
		if rid == "" or rid in active_relics or rid in relic_offers_seen:
			continue
		candidates.append(r)
	candidates.shuffle()
	var result: Array[Dictionary] = candidates.slice(0, mini(count, candidates.size()))
	for r in result:
		var rid: String = str(r.get("id", ""))
		if rid != "" and rid not in relic_offers_seen:
			relic_offers_seen.append(rid)
	return result

func get_random_cursed_upgrades(count: int = 1) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for c in CURSED_UPGRADES:
		if c.id not in cursed_upgrades:
			candidates.append(c)
	candidates.shuffle()
	return candidates.slice(0, mini(count, candidates.size()))

func get_random_rare_upgrades(count: int = 3, category: String = "ALL") -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for up in available_upgrades:
		var id := str(up.get("id", ""))
		if category != "ALL" and get_upgrade_category(id) != category:
			continue
		if is_system_upgrade(id) and not is_system_compatible(id):
			continue
		if can_take_upgrade(id):
			pool.append(_build_upgrade_entry(up, 2))
	pool.shuffle()
	return pool.slice(0, mini(count, pool.size()))

func get_random_relic() -> Dictionary:
	var candidates: Array[Dictionary] = []
	for r in available_relics:
		if r.id not in active_relics:
			candidates.append(r)
	if candidates.is_empty():
		return {}
	return candidates[randi() % candidates.size()]
