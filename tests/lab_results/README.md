SUPERWEAPON BALANCE LAB
=======================
Reusable, headless. Runs every superweapon through 4 configurations x 4 scenarios in one
process per super, writes CSV, and a Python script builds the leaderboards.

  configs    A = parent A at 5/5   B = parent B at 5/5   AB = both 5/5, evolution undone
             SUPER = evolved. Every config also gets 3 Damage + 2 Fire Rate cores (same ship: Viper).
  scenarios  standard: ring of 12 rushing enemies (600 HP), topped up
             dense:    30 rushing enemies (350 HP), topped up
             elite:    Rammer + Spitter elite + 6 escorts
             boss:     the Titan, 300 px away (run ends on kill or at the time limit)
  metrics    total damage, DPS, kills, kills/s (swarm clearing), avg enemies alive,
             damage taken by the player (survival contribution), active uptime (fraction of
             frames in which damage was recorded), elite/boss damage and TTK, damage by source.

RUN (from the project root, Godot binary on PATH or edit the script):
  bash tests/lab_results/run_superlab.sh 15          # 15 s per run, all 7 supers in parallel (~4 min)
  python3 tests/superlab_report.py /tmp/superlab.csv tests/lab_results/superlab_<version>.md
Single super:  LAB_SUPER=storm_grid LAB_SECONDS=15 LAB_OUT=/tmp/x.csv godot --headless --path . res://tests/SuperLab.tscn

Caveats: the boss scenario under-reads every weapon (boss starts 300 px out, has the 2.5%
per-hit burst cap and phase shields); use it for relative ranking only. Time-to-evolve is
not measured here — from the progression sims a committed pair reaches 5/5 + 5/5 at level
12-14 (~5-6 minutes).

WEAPON POWER-CURVE LAB
  bash /tmp/wlab_run.sh 12    (copied here as run_weaponlab.sh)   -> /tmp/weaponlab.csv
  python3 tests/weaponlab_report.py /tmp/weaponlab.csv tests/lab_results/weapon_curves_<ver>.md
  Analysis with caveats: weapon_curves_v3_17_4_analysis.md
