# WEAPON POWER-CURVE LAB — report
source: /tmp/weaponlab.csv  runs: 168

## DPS by minute (stationary / moving) — index = weapon DPS / field average at that minute
| Weapon | 1:00 | 3:00 | 5:00 | 7:00 | 10:00 | idx 1 | idx 3 | idx 5 | idx 7 | idx 10 | moving/still @7 | kills/s @10 | dmg taken @10 | uptime @10 | elite TTK | boss TTK |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Arc Coil | 34 | 67 | 104 | 212 | 605 | 0.96 | 0.72 | 0.38 | 0.38 | 0.27 | 1.09 | 0.20 | 332 | 0.06 | >12 | >12 |
| Cryo Field | 33 | 72 | 189 | 373 | 779 | 0.92 | 0.78 | 0.69 | 0.66 | 0.35 | 0.41 | 0.00 | 0 | 0.05 | >12 | >12 |
| Plasma Flamethrower | 37 | 49 | 206 | 254 | 1920 | 1.05 | 0.53 | 0.75 | 0.45 | 0.87 | 2.70 | 2.30 | 508 | 0.62 | >12 | >12 |
| Graviton Mines | 7 | 20 | 132 | 202 | 800 | 0.19 | 0.22 | 0.48 | 0.36 | 0.36 | 1.10 | 0.00 | 99 | 0.01 | >12 | >12 |
| Hunter Missiles | 55 | 130 | 712 | 1909 | 8746 | 1.55 | 1.41 | 2.60 | 3.38 | 3.94 | 0.10 | 12.20 | 528 | 0.09 | >12 | >12 |
| Phase Disruptor | 5 | 5 | 8 | 23 | 1894 | 0.15 | 0.05 | 0.03 | 0.04 | 0.85 | 7.76 | 2.20 | 348 | 0.03 | >12 | >12 |
| Plasma Lance | 38 | 94 | 374 | 676 | 2234 | 1.06 | 1.02 | 1.37 | 1.20 | 1.01 | 0.54 | 2.70 | 476 | 0.50 | >12 | >12 |
| Radiation Field | 38 | 80 | 197 | 394 | 896 | 1.06 | 0.87 | 0.72 | 0.70 | 0.40 | 0.94 | 0.00 | 396 | 0.21 | >12 | >12 |
| Railgun | 52 | 124 | 305 | 425 | 1149 | 1.47 | 1.35 | 1.12 | 0.75 | 0.52 | 0.47 | 1.10 | 304 | 0.01 | 2.7 | >12 |
| Photon Scattergun | 55 | 190 | 336 | 712 | 3980 | 1.55 | 2.06 | 1.23 | 1.26 | 1.79 | 0.23 | 6.60 | 780 | 0.22 | >12 | >12 |
| Side Batteries | 11 | 35 | 363 | 672 | 2866 | 0.30 | 0.38 | 1.32 | 1.19 | 1.29 | 0.04 | 4.80 | 412 | 0.15 | >12 | >12 |
| Tesla Coil | 27 | 96 | 256 | 780 | 2447 | 0.77 | 1.04 | 0.93 | 1.38 | 1.10 | 0.90 | 3.40 | 316 | 0.14 | 7.8 | >12 |
| Torpedo Bay | 52 | 148 | 258 | 522 | 1198 | 1.48 | 1.61 | 0.94 | 0.92 | 0.54 | 1.14 | 1.40 | 348 | 0.02 | >12 | >12 |
| Void Blades | 53 | 180 | 394 | 747 | 1558 | 1.50 | 1.95 | 1.44 | 1.32 | 0.70 | 0.33 | 2.20 | 364 | 0.17 | >12 | >12 |

## Elite / boss encounter DPS at 10:00 (L5, 4 dmg, 3 fr)
| Weapon | elite DPS | boss DPS |
|---|---|---|
| Tesla Coil | 412 | 144 |
| Hunter Missiles | 402 | 118 |
| Railgun | 368 | 172 |
| Arc Coil | 366 | 79 |
| Side Batteries | 352 | 82 |
| Photon Scattergun | 333 | 197 |
| Void Blades | 270 | 22 |
| Plasma Flamethrower | 193 | 84 |
| Graviton Mines | 160 | 18 |
| Plasma Lance | 142 | 48 |
| Torpedo Bay | 138 | 63 |
| Radiation Field | 122 | 20 |
| Cryo Field | 100 | 10 |
| Phase Disruptor | 13 | 13 |

## Classification (early = avg index at 1:00/3:00, late = avg index at 7:00/10:00)
| Weapon | early | late | growth 1:00->10:00 | class |
|---|---|---|---|---|
| Arc Coil | 0.84 | 0.32 | x17.8 | BALANCED |
| Cryo Field | 0.85 | 0.51 | x23.8 | BALANCED |
| Plasma Flamethrower | 0.79 | 0.66 | x51.8 | BALANCED |
| Graviton Mines | 0.20 | 0.36 | x121.2 | UNDERPERFORMING |
| Hunter Missiles | 1.48 | 3.66 | x159.6 | DOMINANT (early+late) |
| Phase Disruptor | 0.10 | 0.45 | x357.3 | UNDERPERFORMING |
| Plasma Lance | 1.04 | 1.10 | x59.6 | MID-GAME FOCUSED |
| Radiation Field | 0.96 | 0.55 | x23.8 | BALANCED |
| Railgun | 1.41 | 0.64 | x22.0 | EARLY-GAME FOCUSED |
| Photon Scattergun | 1.81 | 1.53 | x72.5 | DOMINANT (early+late) |
| Side Batteries | 0.34 | 1.24 | x265.3 | LATE-GAME SCALING |
| Tesla Coil | 0.90 | 1.24 | x89.6 | LATE-GAME SCALING |
| Torpedo Bay | 1.54 | 0.73 | x22.9 | EARLY-GAME FOCUSED |
| Void Blades | 1.73 | 1.01 | x29.3 | EARLY-GAME FOCUSED |

**Strongest early (index @1:00):** Photon Scattergun (1.55), Hunter Missiles (1.55), Void Blades (1.50), Torpedo Bay (1.48)
**Strongest mid (index @5:00):** Hunter Missiles (2.60), Void Blades (1.44), Plasma Lance (1.37), Side Batteries (1.32)
**Best late scaling (index @10:00):** Hunter Missiles (3.94), Photon Scattergun (1.79), Side Batteries (1.29), Tesla Coil (1.10)
**Largest growth 1:00->10:00:** Phase Disruptor (x357.3), Side Batteries (x265.3), Hunter Missiles (x159.6), Graviton Mines (x121.2)
**Weak throughout:** Graviton Mines, Phase Disruptor
**Best while moving (moving/still @7:00):** Phase Disruptor (7.76), Plasma Flamethrower (2.70), Torpedo Bay (1.14), Graviton Mines (1.10)
**Best control (least dmg taken @10:00):** Cryo Field (0), Graviton Mines (99), Railgun (304), Tesla Coil (316)
**Best swarm clearing (kills/s @10:00):** Hunter Missiles (12.20), Photon Scattergun (6.60), Side Batteries (4.80), Tesla Coil (3.40)