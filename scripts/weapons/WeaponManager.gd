class_name WeaponManager
extends Node2D

## Owns all weapon modules and superweapons. Player calls setup(), tick(),
## set_level() and activate_super().

const REGISTRY := {
	"missile_system": "res://scripts/weapons/HunterMissiles.gd",
	"plasma_lance": "res://scripts/weapons/PlasmaLance.gd",
	"arc_coil": "res://scripts/weapons/ArcCoil.gd",
	"void_blades": "res://scripts/weapons/VoidBlades.gd",
	"railgun": "res://scripts/weapons/Railgun.gd",
	"graviton_mines": "res://scripts/weapons/GravitonMines.gd",
	"radiation": "res://scripts/weapons/RadiationField.gd",
	"cryo_field": "res://scripts/weapons/CryoField.gd",
	"side_guns": "res://scripts/weapons/SideBatteries.gd",
	"tesla_coil": "res://scripts/weapons/TeslaCoil.gd",
	"flamethrower": "res://scripts/weapons/Flamethrower.gd",
	"torpedo_bay": "res://scripts/weapons/TorpedoBay.gd",
	"scattergun": "res://scripts/weapons/Scattergun.gd",
	"phase_disruptor": "res://scripts/weapons/PhaseDisruptor.gd",
}
const SUPER_REGISTRY := {
	"dreadnought_salvo": "res://scripts/weapons/super/DreadnoughtSalvo.gd",
	"hellfire_lance": "res://scripts/weapons/super/HellfireLance.gd",
	"storm_grid": "res://scripts/weapons/super/StormGrid.gd",
	"dimensional_reaper": "res://scripts/weapons/super/DimensionalReaper.gd",
	"starbreaker": "res://scripts/weapons/super/Starbreaker.gd",
	"frozen_singularity": "res://scripts/weapons/super/FrozenSingularity.gd",
	"nuclear_broadside": "res://scripts/weapons/super/NuclearBroadside.gd",
}

var player: CharacterBody2D = null
var weapons: Dictionary = {}      # id -> WeaponBase
var supers: Dictionary = {}       # super id -> WeaponBase

func setup(p: CharacterBody2D) -> void:
	player = p
	for wid in REGISTRY.keys():
		if ResourceLoader.exists(REGISTRY[wid]):
			var w: WeaponBase = load(REGISTRY[wid]).new()
			w.setup(p, self, wid)
			add_child(w)
			weapons[wid] = w
	sync_levels()

func get_weapon(wid: String) -> WeaponBase:
	return weapons.get(wid)

func sync_levels() -> void:
	for wid in weapons.keys():
		var lv := GameManager.get_upgrade_level(wid)
		if weapons[wid].level != lv:
			weapons[wid].set_level(lv)
	_mirror()
	for sid in GameManager.active_synergies:
		if not supers.has(sid):
			activate_super(sid, false)

func set_level(wid: String, lv: int) -> void:
	if weapons.has(wid):
		weapons[wid].set_level(lv)
	_mirror()

## Keep the hull-hardware drawing (ShipWeaponVFX) informed.
func _mirror() -> void:
	player.missile_level = weapons["missile_system"].level if weapons.has("missile_system") else 0
	player.laser_level = weapons["plasma_lance"].level if weapons.has("plasma_lance") else 0
	player.arc_level = weapons["arc_coil"].level if weapons.has("arc_coil") else 0
	player.side_guns = weapons["side_guns"].level if weapons.has("side_guns") else 0
	if player.has_method("_refresh_weapon_modules"):
		player._refresh_weapon_modules()

func tick(delta: float) -> void:
	for w in weapons.values():
		w.tick(delta)
	for s in supers.values():
		s.tick(delta)

func activate_super(sid: String, announce: bool = true) -> void:
	if supers.has(sid) or not SUPER_REGISTRY.has(sid):
		return
	if not ResourceLoader.exists(SUPER_REGISTRY[sid]):
		return
	var data: Dictionary = GameManager.WEAPON_SYNERGIES.get(sid, {})
	var reqs: Array = data.get("requires", [])
	for r in reqs:
		if weapons.has(r):
			weapons[r].suppressed = true
			weapons[r].on_suppressed(true)
	var s: WeaponBase = load(SUPER_REGISTRY[sid]).new()
	s.setup(player, self, sid)
	s.level = GameManager.MAX_WEAPON_LEVEL
	if s.has_method("bind_parts"):
		s.bind_parts(weapons.get(reqs[0]) if reqs.size() > 0 else null, weapons.get(reqs[1]) if reqs.size() > 1 else null)
	add_child(s)
	supers[sid] = s
	if announce and s.has_method("on_activated"):
		s.on_activated()
	_mirror()

func has_super_for(wid: String) -> String:
	for sid in supers.keys():
		var reqs: Array = GameManager.WEAPON_SYNERGIES[sid].get("requires", [])
		if wid in reqs:
			return sid
	return ""

## Removes every active superweapon and un-suppresses its parents (used by the balance lab).
func deactivate_all_supers() -> void:
	for sid in supers.keys():
		var s: Node = supers[sid]
		if is_instance_valid(s):
			s.queue_free()
	supers.clear()
	for w in weapons.values():
		if w.suppressed:
			w.suppressed = false
			w.on_suppressed(false)
	_mirror()
