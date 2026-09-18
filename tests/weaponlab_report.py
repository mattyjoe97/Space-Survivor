#!/usr/bin/env python3
"""Weapon power-curve report. Usage: python3 tests/weaponlab_report.py /tmp/weaponlab.csv [out.md]"""
import csv, sys, statistics as st
path = sys.argv[1] if len(sys.argv)>1 else "/tmp/weaponlab.csv"
rows=[r for r in csv.DictReader(open(path)) if not r["weapon"].startswith("#")]
W=sorted(set(r["weapon"] for r in rows))
N={"missile_system":"Hunter Missiles","plasma_lance":"Plasma Lance","arc_coil":"Arc Coil","void_blades":"Void Blades","railgun":"Railgun","graviton_mines":"Graviton Mines","radiation":"Radiation Field","cryo_field":"Cryo Field","side_guns":"Side Batteries","tesla_coil":"Tesla Coil","flamethrower":"Plasma Flamethrower","torpedo_bay":"Torpedo Bay","scattergun":"Photon Scattergun","phase_disruptor":"Phase Disruptor"}
MIN=[1,3,5,7,10]
def g(w,m,sc,mv):
    for r in rows:
        if r["weapon"]==w and int(r["minute"])==m and r["scenario"]==sc and r["move"]==mv: return r
def F(r,k): return float(r[k]) if r else 0.0
out=[]
def P(s=""): out.append(s)
P("# WEAPON POWER-CURVE LAB — report"); P(f"source: {path}  runs: {len(rows)}"); P()
# per-minute field means for normalisation
mean={m:st.mean(F(g(w,m,"swarm","still"),"dps") for w in W) for m in MIN}
P("## DPS by minute (stationary / moving) — index = weapon DPS / field average at that minute")
P("| Weapon | 1:00 | 3:00 | 5:00 | 7:00 | 10:00 | idx 1 | idx 3 | idx 5 | idx 7 | idx 10 | moving/still @7 | kills/s @10 | dmg taken @10 | uptime @10 | elite TTK | boss TTK |")
P("|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|")
D={}
for w in W:
    d=[F(g(w,m,"swarm","still"),"dps") for m in MIN]; mv=[F(g(w,m,"swarm","moving"),"dps") for m in MIN]
    idx=[d[i]/max(1,mean[MIN[i]]) for i in range(5)]
    r10=g(w,10,"swarm","still"); el=g(w,10,"elite","still"); bo=g(w,10,"boss","still")
    ttk_e=F(el,"elite_ttk"); ttk_b=F(bo,"boss_ttk")
    D[w]=dict(d=d,mv=mv,idx=idx,kps=F(r10,"kills_per_s"),taken=F(r10,"dmg_taken"),up=F(r10,"uptime"),ttk_e=ttk_e,ttk_b=ttk_b,el=F(el,"dps"),bo=F(bo,"dps"),ratio=(mv[3]/max(1,d[3])))
    P(f"| {N[w]} | "+" | ".join(f"{x:.0f}" for x in d)+" | "+" | ".join(f"{x:.2f}" for x in idx)+f" | {D[w]['ratio']:.2f} | {D[w]['kps']:.2f} | {D[w]['taken']:.0f} | {D[w]['up']:.2f} | {('%.1f'%ttk_e) if ttk_e>0 else '>12'} | {('%.1f'%ttk_b) if ttk_b>0 else '>12'} |")
P()
P("## Elite / boss encounter DPS at 10:00 (L5, 4 dmg, 3 fr)")
P("| Weapon | elite DPS | boss DPS |"); P("|---|---|---|")
for w in sorted(W,key=lambda x:-D[x]["el"]): P(f"| {N[w]} | {D[w]['el']:.0f} | {D[w]['bo']:.0f} |")
P()
def cls(w):
    i=D[w]["idx"]; early=st.mean(i[:2]); late=st.mean(i[3:])
    if early<0.6 and late<0.6: return "UNDERPERFORMING"
    if early>=1.3 and late>=1.3: return "DOMINANT (early+late)"
    if late>=early*1.35 and late>=1.0: return "LATE-GAME SCALING"
    if early>=late*1.35 and early>=1.0: return "EARLY-GAME FOCUSED"
    if i[2]>=max(early,late)*1.2: return "MID-GAME FOCUSED"
    return "BALANCED"
P("## Classification (early = avg index at 1:00/3:00, late = avg index at 7:00/10:00)")
P("| Weapon | early | late | growth 1:00->10:00 | class |"); P("|---|---|---|---|---|")
for w in W:
    i=D[w]["idx"]; P(f"| {N[w]} | {st.mean(i[:2]):.2f} | {st.mean(i[3:]):.2f} | x{D[w]['d'][4]/max(1,D[w]['d'][0]):.1f} | {cls(w)} |")
P()
def top(title,key,rev=True,n=4):
    P(f"**{title}:** "+", ".join(f"{N[w]} ({D[w][key] if not isinstance(D[w][key],list) else 0:.2f})" if not isinstance(D[w][key],list) else N[w] for w in sorted(W,key=lambda x:(-1 if rev else 1)*(D[x][key] if not isinstance(D[x][key],list) else 0))[:n]))
P("**Strongest early (index @1:00):** "+", ".join(f"{N[w]} ({D[w]['idx'][0]:.2f})" for w in sorted(W,key=lambda x:-D[x]['idx'][0])[:4]))
P("**Strongest mid (index @5:00):** "+", ".join(f"{N[w]} ({D[w]['idx'][2]:.2f})" for w in sorted(W,key=lambda x:-D[x]['idx'][2])[:4]))
P("**Best late scaling (index @10:00):** "+", ".join(f"{N[w]} ({D[w]['idx'][4]:.2f})" for w in sorted(W,key=lambda x:-D[x]['idx'][4])[:4]))
P("**Largest growth 1:00->10:00:** "+", ".join(f"{N[w]} (x{D[w]['d'][4]/max(1,D[w]['d'][0]):.1f})" for w in sorted(W,key=lambda x:-D[x]['d'][4]/max(1,D[x]['d'][0]))[:4]))
P("**Weak throughout:** "+", ".join(N[w] for w in W if cls(w)=="UNDERPERFORMING"))
P("**Best while moving (moving/still @7:00):** "+", ".join(f"{N[w]} ({D[w]['ratio']:.2f})" for w in sorted(W,key=lambda x:-D[x]['ratio'])[:4]))
P("**Best control (least dmg taken @10:00):** "+", ".join(f"{N[w]} ({D[w]['taken']:.0f})" for w in sorted(W,key=lambda x:D[x]['taken'])[:4]))
P("**Best swarm clearing (kills/s @10:00):** "+", ".join(f"{N[w]} ({D[w]['kps']:.2f})" for w in sorted(W,key=lambda x:-D[x]['kps'])[:4]))
text="\n".join(out); print(text)
if len(sys.argv)>2: open(sys.argv[2],"w").write(text)
