#!/bin/bash
# Runs the Superweapon Balance Lab for every super in parallel and merges the CSVs.
cd /home/claude/SpaceSurvivors
rm -f /tmp/lab_*.csv
for sid in dreadnought_salvo hellfire_lance storm_grid dimensional_reaper starbreaker frozen_singularity nuclear_broadside; do
  LAB_SUPER=$sid LAB_SECONDS=${1:-15} LAB_OUT=/tmp/lab_$sid.csv timeout 900 /tmp/Godot_v4.5-stable_linux.x86_64 --headless --path . res://tests/SuperLab.tscn > /tmp/lab_$sid.log 2>&1 &
done
wait
head -1 /tmp/lab_starbreaker.csv > /tmp/superlab.csv
for f in /tmp/lab_*.csv; do tail -n +2 $f | grep -v "^#" >> /tmp/superlab.csv; done
wc -l /tmp/superlab.csv
