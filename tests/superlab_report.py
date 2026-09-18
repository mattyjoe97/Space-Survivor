#!/usr/bin/env python3
"""Superweapon Balance Lab report. Usage: python3 tests/superlab_report.py /tmp/superlab.csv [out.md]
Reads the CSV written by tests/SuperLab.tscn and prints leaderboards + parent->super jumps."""
import csv, sys, collections
path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/superlab.csv"
rows = [r for r in csv.DictReader(open(path)) if not r["super"].startswith("#")]
def get(sid, cfg, sc): 
    for r in rows:
        if r["super"]==sid and r["config"]==cfg and r["scenario"]==sc: return r
    return None
supers = sorted(set(r["super"] for r in rows))
NAMES = {"dreadnought_salvo":"Dreadnought Salvo","hellfire_lance":"Hellfire Lance","storm_grid":"Storm Grid","dimensional_reaper":"Dimensional Reaper","starbreaker":"Starbreaker","frozen_singularity":"Frozen Singularity","nuclear_broadside":"Nuclear Broadside"}
def f(x): return float(x)
out=[]
def P(s=""): out.append(s)
P("# SUPERWEAPON BALANCE LAB — report"); P(f"source: {path}  runs: {len(rows)}"); P()
P("## Per superweapon (DPS = damage per second over the run)")
P("| Super | cfg | standard DPS | dense DPS | elite DPS | elite TTK | boss DPS | boss TTK | swarm kills/s (dense) | dmg taken (dense) | uptime |")
P("|---|---|---|---|---|---|---|---|---|---|---|")
summary={}
for sid in supers:
    for cfg in ["A","B","AB","SUPER"]:
        st,de,el,bo=[get(sid,cfg,s) for s in ["standard","dense","elite","boss"]]
        if not all([st,de,el,bo]): continue
        ttk_e = el["elite_ttk"] if f(el["elite_ttk"])>0 else ">"+el["seconds"]
        ttk_b = bo["boss_ttk"] if f(bo["boss_ttk"])>0 else ">"+bo["seconds"]
        P(f"| {NAMES.get(sid,sid)} | {cfg} | {f(st['dps']):.0f} | {f(de['dps']):.0f} | {f(el['dps']):.0f} | {ttk_e} | {f(bo['dps']):.0f} | {ttk_b} | {f(de['kills_per_s']):.2f} | {f(de['dmg_taken']):.0f} | {f(de['active_uptime']):.2f} |")
        summary[(sid,cfg)] = dict(dmg=(f(st["dps"])+f(de["dps"]))/2, boss=f(bo["dps"]), swarm=f(de["kills_per_s"]), taken=f(de["dmg_taken"])+f(st["dmg_taken"]), elite=f(el["dps"]), ttk_b=f(bo["boss_ttk"]), ttk_e=f(el["elite_ttk"]))
P()
def board(title, key, reverse=True, fmt="{:.0f}"):
    P(f"## {title}")
    items=[(NAMES.get(s,s), summary[(s,"SUPER")][key]) for s in supers if (s,"SUPER") in summary]
    items.sort(key=lambda x:x[1], reverse=reverse)
    for i,(n,v) in enumerate(items,1): P(f"{i}. {n} — {fmt.format(v)}")
    P()
board("TOP SUPERWEAPONS BY DAMAGE (avg DPS, standard+dense)","dmg")
board("TOP SUPERWEAPONS BY BOSS DAMAGE (DPS vs Titan)","boss")
board("TOP SUPERWEAPONS BY SWARM CLEARING (kills/s, dense)","swarm",fmt="{:.2f}")
board("TOP SUPERWEAPONS BY SURVIVABILITY (least damage taken, standard+dense)","taken",reverse=False)
P("## PARENT BUILD -> SUPERWEAPON power jump (avg DPS)")
P("| Super | A | B | A+B unevolved | SUPER | jump vs A+B | jump vs best parent |"); P("|---|---|---|---|---|---|---|")
jumps=[]
for s in supers:
    a,b,ab,su=[summary.get((s,c),{}).get("dmg",0) for c in ["A","B","AB","SUPER"]]
    j=su/max(1,ab); jb=su/max(1,max(a,b)); jumps.append((NAMES.get(s,s),j,jb))
    P(f"| {NAMES.get(s,s)} | {a:.0f} | {b:.0f} | {ab:.0f} | {su:.0f} | x{j:.2f} | x{jb:.2f} |")
P()
supers_d=[(NAMES.get(s,s),summary[(s,'SUPER')]['dmg']) for s in supers]
supers_d.sort(key=lambda x:x[1])
P(f"BIGGEST OVERPERFORMER: {supers_d[-1][0]} ({supers_d[-1][1]:.0f} DPS)")
P(f"BIGGEST UNDERPERFORMER: {supers_d[0][0]} ({supers_d[0][1]:.0f} DPS)")
jumps.sort(key=lambda x:x[1])
P(f"LARGEST PARENT->SUPER JUMP: {jumps[-1][0]} (x{jumps[-1][1]:.2f} vs A+B)")
P(f"SMALLEST PARENT->SUPER JUMP: {jumps[0][0]} (x{jumps[0][1]:.2f} vs A+B)")
text="\n".join(out); print(text)
if len(sys.argv)>2: open(sys.argv[2],"w").write(text)
