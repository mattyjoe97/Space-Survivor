class_name PullSafety
extends RefCounted

## Shared rule for every enemy-pulling effect (Graviton Mines, Frozen Singularity, rifts...).
##  - enemies are pulled toward `center` at `strength` px/s
##  - they are never dragged through the player's collision space: inside SAFE_RADIUS
##    of the ship the pull is deflected to slide around the ship instead of crossing it
##  - elites and bosses are pulled at reduced strength so the effect stays useful but
##    can't hold them in place

const SAFE_RADIUS := 56.0
const ELITE_FACTOR := 0.35

static func pull(e: Node2D, center: Vector2, strength: float, delta: float, falloff: float = 1.0) -> void:
	if not is_instance_valid(e) or not (e is CharacterBody2D):
		return
	if e.is_in_group("elites") or e.is_in_group("boss"):
		strength *= ELITE_FACTOR
	var rel: Vector2 = center - e.global_position
	var d := rel.length()
	if d <= 6.0:
		return
	var step: Vector2 = rel.normalized() * strength * delta * falloff
	var target: Vector2 = e.global_position + step
	var p = GameManager.player
	if is_instance_valid(p):
		var to_ship: Vector2 = target - p.global_position
		if to_ship.length() < SAFE_RADIUS:
			# Deflect: keep the enemy on the safety circle and let it slide tangentially.
			var from_ship: Vector2 = e.global_position - p.global_position
			if from_ship.length() < 1.0:
				from_ship = Vector2.RIGHT
			var tangent := Vector2(-from_ship.y, from_ship.x).normalized()
			var slide := tangent * step.dot(tangent) * 0.5
			target = p.global_position + from_ship.normalized() * SAFE_RADIUS + slide
	e.global_position = target
