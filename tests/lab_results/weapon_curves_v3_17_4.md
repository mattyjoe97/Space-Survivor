# WEAPON POWER-CURVE LAB — report
source: /tmp/weaponlab.csv  runs: 168

## DPS by minute (stationary / moving) — index = weapon DPS / field average at that minute
| Weapon | 1:00 | 3:00 | 5:00 | 7:00 | 10:00 | idx 1 | idx 3 | idx 5 | idx 7 | idx 10 | moving/still @7 | kills/s @10 | dmg taken @10 | uptime @10 | elite TTK | boss TTK |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Arc Coil | 20 | 28 | 46 | 77 | 167 | 0.78 | 0.47 | 0.21 | 0.16 | 0.10 | 0.89 | 0.00 | 344 | 0.03 | >12 | >12 |
| Cryo Field | 30 | 60 | 165 | 311 | 693 | 1.14 | 1.03 | 0.75 | 0.65 | 0.42 | 0.45 | 0.00 | 0 | 0.05 | >12 | >12 |
| Plasma Flamethrower | 28 | 39 | 198 | 214 | 1317 | 1.09 | 0.67 | 0.90 | 0.44 | 0.79 | 3.19 | 1.75 | 468 | 0.52 | >12 | >12 |
| Graviton Mines | 6 | 10 | 26 | 301 | 666 | 0.21 | 0.18 | 0.12 | 0.63 | 0.40 | 0.49 | 0.00 | 107 | 0.01 | >12 | >12 |
| Hunter Missiles | 54 | 162 | 1090 | 2556 | 6592 | 2.09 | 2.78 | 4.98 | 5.32 | 3.97 | 0.15 | 8.58 | 440 | 0.09 | >12 | >12 |
| Phase Disruptor | 4 | 4 | 6 | 18 | 3635 | 0.17 | 0.07 | 0.03 | 0.04 | 2.19 | 10.76 | 4.33 | 288 | 0.04 | >12 | >12 |
| Plasma Lance | 32 | 77 | 319 | 581 | 1980 | 1.24 | 1.32 | 1.45 | 1.21 | 1.19 | 0.62 | 2.58 | 476 | 0.50 | >12 | >12 |
| Radiation Field | 36 | 64 | 190 | 357 | 732 | 1.41 | 1.09 | 0.87 | 0.74 | 0.44 | 0.55 | 0.00 | 384 | 0.16 | >12 | >12 |
| Railgun | 60 | 88 | 181 | 377 | 857 | 2.32 | 1.51 | 0.83 | 0.78 | 0.52 | 0.56 | 0.92 | 320 | 0.01 | >12 | >12 |
| Photon Scattergun | 64 | 187 | 376 | 890 | 3590 | 2.48 | 3.22 | 1.72 | 1.85 | 2.16 | 0.20 | 6.17 | 584 | 0.24 | >12 | >12 |
| Side Batteries | 10 | 22 | 312 | 698 | 2386 | 0.37 | 0.39 | 1.42 | 1.45 | 1.44 | 0.02 | 4.00 | 408 | 0.14 | >12 | >12 |
| Tesla Coil | 12 | 19 | 50 | 164 | 241 | 0.45 | 0.33 | 0.23 | 0.34 | 0.15 | 0.93 | 0.25 | 328 | 0.07 | >12 | >12 |
| Torpedo Bay | 3 | 44 | 82 | 127 | 293 | 0.11 | 0.75 | 0.37 | 0.27 | 0.18 | 3.95 | 0.00 | 360 | 0.01 | >12 | >12 |
| Void Blades | 4 | 12 | 25 | 58 | 91 | 0.14 | 0.21 | 0.12 | 0.12 | 0.05 | 1.98 | 0.00 | 324 | 0.02 | >12 | >12 |

## Elite / boss encounter DPS at 10:00 (L5, 4 dmg, 3 fr)
| Weapon | elite DPS | boss DPS |
|---|---|---|
| Hunter Missiles | 354 | 144 |
| Photon Scattergun | 331 | 242 |
| Side Batteries | 244 | 43 |
| Tesla Coil | 209 | 62 |
| Railgun | 190 | 85 |
| Plasma Flamethrower | 148 | 80 |
| Graviton Mines | 138 | 20 |
| Arc Coil | 125 | 32 |
| Plasma Lance | 125 | 45 |
| Radiation Field | 121 | 17 |
| Cryo Field | 84 | 9 |
| Torpedo Bay | 70 | 49 |
| Void Blades | 46 | 32 |
| Phase Disruptor | 11 | 12 |

## Classification (early = avg index at 1:00/3:00, late = avg index at 7:00/10:00)
| Weapon | early | late | growth 1:00->10:00 | class |
|---|---|---|---|---|
| Arc Coil | 0.63 | 0.13 | x8.3 | BALANCED |
| Cryo Field | 1.09 | 0.53 | x23.4 | EARLY-GAME FOCUSED |
| Plasma Flamethrower | 0.88 | 0.62 | x46.9 | BALANCED |
| Graviton Mines | 0.20 | 0.51 | x121.2 | UNDERPERFORMING |
| Hunter Missiles | 2.44 | 4.64 | x121.6 | DOMINANT (early+late) |
| Phase Disruptor | 0.12 | 1.11 | x826.2 | LATE-GAME SCALING |
| Plasma Lance | 1.28 | 1.20 | x61.9 | BALANCED |
| Radiation Field | 1.25 | 0.59 | x20.1 | EARLY-GAME FOCUSED |
| Railgun | 1.92 | 0.65 | x14.3 | EARLY-GAME FOCUSED |
| Photon Scattergun | 2.85 | 2.01 | x56.0 | DOMINANT (early+late) |
| Side Batteries | 0.38 | 1.44 | x246.0 | LATE-GAME SCALING |
| Tesla Coil | 0.39 | 0.24 | x20.8 | UNDERPERFORMING |
| Torpedo Bay | 0.43 | 0.22 | x101.1 | UNDERPERFORMING |
| Void Blades | 0.18 | 0.09 | x24.7 | UNDERPERFORMING |

**Strongest early (index @1:00):** Photon Scattergun (2.48), Railgun (2.32), Hunter Missiles (2.09), Radiation Field (1.41)
**Strongest mid (index @5:00):** Hunter Missiles (4.98), Photon Scattergun (1.72), Plasma Lance (1.45), Side Batteries (1.42)
**Best late scaling (index @10:00):** Hunter Missiles (3.97), Phase Disruptor (2.19), Photon Scattergun (2.16), Side Batteries (1.44)
**Largest growth 1:00->10:00:** Phase Disruptor (x826.2), Side Batteries (x246.0), Hunter Missiles (x121.6), Graviton Mines (x121.2)
**Weak throughout:** Graviton Mines, Tesla Coil, Torpedo Bay, Void Blades
**Best while moving (moving/still @7:00):** Phase Disruptor (10.76), Torpedo Bay (3.95), Plasma Flamethrower (3.19), Void Blades (1.98)
**Best control (least dmg taken @10:00):** Cryo Field (0), Graviton Mines (107), Phase Disruptor (288), Railgun (320)
**Best swarm clearing (kills/s @10:00):** Hunter Missiles (8.58), Photon Scattergun (6.17), Phase Disruptor (4.33), Side Batteries (4.00)