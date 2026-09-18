# Weapon power-curve analysis — v3.17.4 (no balance changes made)

Method: tests/WeaponLab.tscn. Each weapon alone (primary cannons disabled), Viper, at five
snapshots matched to a normal run: 1:00 L1 / 3:00 L2 +1 dmg / 5:00 L3 +2 dmg +1 FR /
7:00 L4 +3 dmg +2 FR / 10:00 L5 +4 dmg +3 FR, against rushing swarms sized and HP'd for that
minute (8x59 HP ... 26x470 HP), stationary AND moving (200 px circle), plus elite and boss
encounters at the 10:00 snapshot. 168 runs, 12 s each. Raw table: weapon_curves_v3_17_4.md.
"Index" = a weapon's DPS divided by the 14-weapon average at that minute.

LAB CAVEATS (read before trusting a number)
- Deployables that need setup time (Graviton Mines, Tesla Coil, Torpedo Bay) under-read in a
  12 s window and against enemies that rush the ship instead of standing in the field.
- Void Blades orbit at 60-93 px; a swarm pressed against the hull sits INSIDE the orbit and is
  barely touched. That is a real design weakness, not only a lab artifact.
- Boss DPS is capped by the 2.5%/hit rule and shields; elite TTK >12 s everywhere at 12 s runs.
- "dmg taken" is the best available control/survival measure: same swarm, how much reached the hull.

## Curve classes

| Class | Weapons |
|---|---|
| DOMINANT early+late | Hunter Missiles (idx 2.1 -> 4.0), Photon Scattergun (2.5 -> 2.2) |
| EARLY-focused | Railgun (2.3 -> 0.5), Radiation Field (1.4 -> 0.4), Cryo Field (1.1 -> 0.4) |
| BALANCED | Plasma Lance (1.2 -> 1.2), Plasma Flamethrower (1.1 -> 0.8), Arc Coil (0.8 -> 0.1 — fading) |
| LATE scaling | Side Batteries (0.4 -> 1.4), Phase Disruptor (0.1 -> 2.2; entirely its L5 rifts) |
| Under-performing (raw DPS) | Graviton Mines*, Torpedo Bay, Tesla Coil, Void Blades |
*Mines: lowest damage taken of any damage weapon (107 vs 300-580) — see below.

## Answers
- Strongest early: Photon Scattergun, Railgun, Hunter Missiles, Radiation Field.
- Strongest mid (5:00): Hunter Missiles (idx 5.0!), Scattergun, Plasma Lance, Side Batteries.
- Best late (10:00): Hunter Missiles, Phase Disruptor, Scattergun, Side Batteries.
- Weak throughout: Void Blades, Tesla Coil, Torpedo Bay (and Arc Coil after 3:00).
- Dominate both ends: Hunter Missiles and Photon Scattergun — the two weapons that never miss
  (homing / ricochet) scale with every multiplier and with swarm density.
- Healthy curve: Plasma Lance (flat ~1.2 index, reliable), Side Batteries (real trade: weak until
  L3, then a top-4 late weapon), Flamethrower (strong while moving: 3.2x its stationary DPS).
- Best while moving: Phase Disruptor, Torpedo Bay, Flamethrower, Void Blades. Worst: Side
  Batteries (0.02x — perpendicular fire misses when the ship turns), Missiles (0.15x), Scattergun.
- Control value (dmg taken @10:00): Cryo Field 0, Graviton Mines 107, Phase Disruptor 288,
  Railgun 320 ... Scattergun 584.

## The Mines vs Missiles tradeoff (your example)
It exists, and it is the healthiest tradeoff in the roster: Missiles = 6.2x the DPS of Mines
at 10:00 (6592 vs 666) but let 4x the damage through (440 vs 107). Mines buy safety and
positioning; Missiles buy kills. The problem is not the shape of the trade, it is the price:
Missiles ALSO dominate early (idx 2.1 at 1:00) so there is no minute where Mines' DPS is
competitive, and Missiles are the Viper signature, i.e. the default ship starts with the
best weapon in the game.

## Ship signature weapons — does the system create healthy differences?
Viper: Missiles (dominant)      Nova: Lance (balanced)      Destroyer: Railgun (early)
Aegis: Mines (control)          Tempest: Arc Coil (fading)  Dreadnought: Side Batteries (late)
Bulwark: Radiation (early)      Singularity: Cryo (control) Voidrunner: Void Blades (weakest)
Verdict: the mapping produces real differences in *feel* (control ships vs damage ships,
early vs late), which is good — but the spread is too wide at the ends. Viper starts with an
idx-2.1 weapon that becomes idx-4.0; Voidrunner starts with an idx-0.14 weapon that becomes
idx-0.05 and has a +move-speed trait that does nothing for blades. Tempest's Arc Coil fades to
0.1 by 10:00 while its trait (+fire rate) is the stat Arc Coil benefits least from. The
signature system is healthy in concept and unhealthy at three ships: Viper (too strong),
Voidrunner and Tempest (too weak).

## Recommendations (NOT implemented)
BUFF
- Void Blades: hit enemies inside the orbit (sweep the disc, not just the band) and/or orbit
  closer; this is the only weapon that fails at its own job (protecting the hull).
- Tesla Coil: coils should follow the fight — spawn nearer the current target or re-deploy
  when out of range; damage per zap +30%.
- Torpedo Bay: shorter arm/accel so it lands inside 12 s; cluster bomblets at L3 instead of L5.
- Arc Coil late game: chain damage falloff 0.88 -> 0.94 and +1 jump at L5, or scale jumps with
  fire rate (Tempest's trait).
- Graviton Mines: leave DPS alone (control is the identity) but let mines arm 0.2 s faster and
  make the pull radius scale with Area so Aegis' trait matters.
NERF
- Hunter Missiles: L5 split micro-seekers currently double effective volley; cap splits to
  one per missile or reduce split damage 0.45 -> 0.3; early damage 0.85 -> 0.7 at L1-2.
- Photon Scattergun: fine late; trim early (L1 6 pellets -> 5) so it is not also the best
  1:00 weapon.
- Phase Disruptor L5 rifts: 3 pulses -> 2 (its entire late index comes from rifts).
LEAVE ALONE
- Plasma Lance, Plasma Flamethrower, Side Batteries (its low moving reliability is the
  intended broadside skill check), Cryo Field, Radiation Field, Railgun (early/precision by design).
SHIPS
- Move Viper to a balanced signature (Plasma Lance or Side Batteries) or start Missiles at
  70% early damage; give Voidrunner a trait that touches blades (+blade reach or spin); give
  Tempest +chain jumps per level instead of +fire rate.
