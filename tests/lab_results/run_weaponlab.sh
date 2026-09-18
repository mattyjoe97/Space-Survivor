#!/bin/bash
cd /home/claude/SpaceSurvivors
rm -f /tmp/wlab_*.csv
i=0
for pair in "missile_system,plasma_lance" "arc_coil,void_blades" "railgun,graviton_mines" "radiation,cryo_field" "side_guns,tesla_coil" "flamethrower,torpedo_bay" "scattergun,phase_disruptor"; do
  i=$((i+1))
  LAB_WEAPONS=$pair LAB_SECONDS=${1:-12} LAB_OUT=/tmp/wlab_$i.csv timeout 1200 /tmp/Godot_v4.5-stable_linux.x86_64 --headless --path . res://tests/WeaponLab.tscn > /tmp/wlab_$i.log 2>&1 &
done
wait
head -1 /tmp/wlab_1.csv > /tmp/weaponlab.csv
for f in /tmp/wlab_*.csv; do tail -n +2 $f | grep -v "^#" >> /tmp/weaponlab.csv; done
wc -l /tmp/weaponlab.csv
