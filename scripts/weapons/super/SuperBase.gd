class_name SuperWeaponBase
extends WeaponBase
## Base for superweapons: holds references to the two absorbed weapons.
var part_a: WeaponBase = null
var part_b: WeaponBase = null

func bind_parts(a: WeaponBase, b: WeaponBase) -> void:
	part_a = a
	part_b = b

func on_activated() -> void:
	pass

func super_color() -> Color:
	return GameManager.WEAPON_SYNERGIES.get(id, {}).get("color", Color.WHITE)

func color() -> Color:
	return super_color()

## Superweapons absorb two maxed weapons, so they carry a flat damage premium.
func dmg(mult: float) -> float:
	return player.damage * mult * 1.3
