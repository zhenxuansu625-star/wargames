# WWII Campaign Tactics — Game Design & Build Plan

> Hand this file to Claude Code at the start of the project. Save it in the repo root as `PLAN.md`, and ask Claude Code to create a short `CLAUDE.md` that points to it.

## 1. Pitch

A linked campaign through WWII where every significant battle (plus optional minor ones) is played as a **real-time-with-pause tactical battle**. You command individual **infantry squads, vehicles and guns**. Between battles, a **HOI4-style war economy** (civilian factories, military factories, synthetic refineries) produces the weapons and equipment that fill your stockpiles. Outcomes, losses and veteran units carry forward from battle to battle.

## 2. Locked decisions

| Area | Decision |
|---|---|
| Engine | Godot 4.x, GDScript |
| View | 2D top-down first (3D is a later option; keep sim logic view-independent) |
| Combat | Real-time with pause (Space to pause, orders issued while paused) |
| Unit scale | Squads (4–12 soldiers as one unit), single vehicles, gun teams |
| Structure | Linked campaign: persistent roster, veterancy, casualties |
| Economy | HOI4-style factories and resources feeding equipment stockpiles |
| Navy | Out of scope for now (no dockyards, no naval battles) |
| Accuracy | **Historical mode only for v1** — historical dates, orders of battle, equipment availability and starting economies |
| Variants | Two game variants planned later; architecture must allow a second ruleset without rewriting the historical one |
| Data | Battles, units, weapons, factories and resources defined in data files, not hard-coded |

## 3. Core gameplay loop

1. **Strategic layer** — manage the economy (build factories, assign production lines), move units between regions on the campaign map.
2. **Pick a battle** — major = mandatory, minor = optional rewards/penalties.
3. **Briefing** — objectives, historical context, enemy intel, time limit.
4. **Force selection** — choose from the units **currently in that region**, then assign each to **Frontline** or **Reinforcement**.
5. **Battle (RTwP)** — frontline units deploy at the start; reinforcements are called in with a decision; retreat is available as a decision.
6. **Debrief** — casualties, equipment lost/captured, veterancy gains, men saved by retreat.
7. **Replenish** — surviving units draw replacement men and equipment from national stockpiles.

## 4. Battle force structure

**Force selection**
- Every unit on the campaign map sits in a region. Only units in (or adjacent to, if allowed by the battle data) the battle's region can be chosen.
- Each battle has a **frontline cap** (e.g. max units or command points) based on the historical frontage.
- Any selected unit not on the frontline goes into the **Reinforcement pool**.
- Units not selected stay in the region and are unaffected.

**Reinforcement decision**
- Opens a panel listing the reinforcement pool. Pick which units to send in.
- Each call has a **delay** before arrival (travel time, set per battle/unit type, e.g. infantry 60s, armour 90s) and arrives at a defined **entry point** on the map edge.
- Optional limits: cooldown between calls, max calls per battle, or a command-point cost. Make these data values so they can be tuned.
- Uncalled reinforcements take no losses.

**Retreat decision** (aim: conserve men)
- Can be issued for **selected units** (local withdrawal) or the **whole force** (abandon battle).
- Retreating units move to the nearest friendly map edge/exit, get a speed and morale-break immunity bonus but cannot fire normally, and are vulnerable while in the open.
- Units that reach the exit are saved and return to the region.
- A full retreat ends the battle as a **loss** (objectives forfeited, campaign consequences apply), but survivors are kept.
- Debrief shows **men saved** vs **men lost** so conserving manpower is a visible, rewarded choice.
- Heavy equipment that can't escape (immobilised vehicles, emplaced guns) is lost and may be captured by the enemy.

## 5. Tactical systems (battle layer)

**Units**
- Squad: soldier count, morale, weapon loadout, ammo, stance (move / fast / prone / hold).
- Vehicle: armour per facing (front/side/rear), crew, weapons, hull/turret rotation, fuel optional.
- Gun team: setup/teardown time, firing arc, crew.
- Every soldier and vehicle is backed by **equipment from the stockpile**; casualties remove that equipment.

**Orders**: move, attack-move, attack target, hold fire, retreat, garrison building, use ability (smoke, grenades, artillery call). Queue orders with Shift.

**Combat model (keep simple first, deepen later)**
- Line of sight with fog of war.
- Cover: none / light / heavy / garrisoned, modifies accuracy and damage.
- Accuracy by range band + target stance + moving/still.
- Armour penetration vs armour facing → penetrate / bounce / damage crew/engine.
- Suppression: incoming fire lowers accuracy and speed; pinned squads can't advance.
- Morale: losses and suppression can trigger retreat or surrender.
- Historical weapon stats (rate of fire, effective range, penetration) stored in data files.

**Map**: tile- or navmesh-based terrain types (road, field, forest, urban, water, hedgerow), destructible buildings later.

**AI**: per-unit behaviour (take cover, return fire, retreat) + a simple battle commander that assigns units to objectives and uses its own reinforcements. Script hooks per battle (historical reinforcement waves, timed events).

## 6. Economy (HOI4-style, no navy)

The economy's purpose is to **produce weapons and equipment into stockpiles**, which supply the units you fight with.

**Factories**
- **Civilian factories (CIC)** — build new factories and refineries (construction queue), and some are reserved for consumer goods (a percentage set by the economy law). Optionally trade for missing resources later.
- **Military factories (MIC)** — assigned to **production lines**. Each line produces one equipment type (e.g. M1 Garand rifles, M4 Sherman, 57mm AT gun). Output per day = factories × base output × production efficiency.
- **Synthetic refineries** — produce synthetic oil (fuel) and rubber, reducing dependence on imported/raw resources (historically vital for Germany).

**Production efficiency**
- New lines start low (e.g. 10%) and ramp toward a cap over time.
- Switching a line to a different equipment loses efficiency (less if it's a variant of the same family, e.g. Panzer IV F → G).

**Resources**
- Steel, oil, rubber, aluminium, tungsten, chromium.
- Each equipment type has a resource cost per unit; shortages slow production.
- Each region provides fixed historical resource amounts; synthetic refineries add oil/rubber.
- Fuel stockpile is consumed by vehicles in battles and campaign movement.

**Stockpiles**
- National stockpile per equipment type (rifles, MGs, mortars, AT guns, artillery, tanks by model, trucks, etc.) plus manpower and fuel.
- Units have equipment requirements; after battles they automatically draw replacements from the stockpile. If the stockpile is short, units stay understrength.
- Equipment lost in battle is removed; captured enemy equipment can be added (usable with penalties).

**Time**
- Strategic layer runs on days. Time passes between battles according to the historical date of the next battle, so the economy produces in the gaps.

**Historical setup**
- Each nation starts with historically based factory counts, resources, laws and equipment available on that date.
- Equipment unlocks follow historical introduction dates (no research tree in historical mode, or a fixed historical one).

**Not included for now**: dockyards, naval production, convoys, air production (air support can be an off-map ability).

## 7. Campaign systems

- **Campaign map**: regions holding units, resources and factories; battles are tied to regions and historical dates.
- **Roster**: persistent units with names, veterancy (Green → Regular → Veteran → Elite), kill counts, current strength vs required equipment.
- **Manpower**: national pool used to refill losses; retreating instead of fighting to the last man directly protects it.
- **Branching**: winning/losing, retreating, or skipping minor battles changes starting conditions of later battles (e.g. losing a minor battle damages factories in that region, or reduces enemy forces at the next major battle).
- **Faction**: start with one faction (recommend US/Commonwealth Western Front); add others as separate campaigns later.
- **Save/load**: full campaign and economy state serialised to JSON.

## 8. Historical accuracy (v1 focus)

- Battles occur on historical dates with historical objectives and starting positions.
- Orders of battle based on real formations (which divisions/regiments were present).
- Equipment only available after its real introduction date.
- Starting economies (factory counts, resource access, synthetic capacity) based on historical estimates — keep sources/notes in the data files.
- **Ruleset abstraction**: put anything mode-specific (fixed history vs free choices) behind a `Ruleset` resource so a second variant can be added later without breaking historical mode.

## 9. Battle list (first campaign — Western Front example)

Major (mandatory) | Optional minor examples
---|---
D-Day: Omaha Beach (1944) | Pointe du Hoc, Merville Battery
Hedgerow fighting / Carentan | Brécourt Manor, Saint-Lô outskirts
Operation Cobra | Mortain counterattack
Falaise Pocket | Hill 262
Market Garden: Arnhem / Nijmegen | Son bridge, Best
Hürtgen Forest | Schmidt
Battle of the Bulge: Bastogne | Foy, Noville, St. Vith
Rhine crossing: Remagen | Operation Varsity drop zones

Later campaigns: North Africa (Gazala, El Alamein, Kasserine), Eastern Front (Moscow, Stalingrad, Kursk, Berlin), Pacific (Guadalcanal, Tarawa, Iwo Jima, Okinawa), early war (Poland, France 1940, Dunkirk).

Scale target: one battle = 15–40 minutes, 8–20 frontline units plus reinforcements.

## 10. Project architecture (Godot)

```
res://
  core/            # autoloads: GameState, CampaignManager, SaveSystem, EventBus, Ruleset
  battle/
    sim/           # pure logic: combat resolution, LOS, morale (no rendering)
    units/         # Unit scenes: Squad.tscn, Vehicle.tscn, GunTeam.tscn
    orders/        # order types + command queue
    decisions/     # reinforcement call, retreat (battle-level decisions)
    ai/            # unit behaviours, battle commander
    map/           # terrain, cover, pathfinding (NavigationServer2D)
    ui/            # selection box, order panel, decisions panel, minimap, pause overlay
  economy/
    sim/           # pure logic: factories, construction, production lines, efficiency, resources
    ui/            # production screen, construction screen, stockpile view
  campaign/        # campaign map, regions, briefing, force selection, debrief, roster screens
  data/
    units/         # unit templates + equipment requirements
    equipment/     # weapon/vehicle stats, resource costs, intro dates
    nations/       # starting factories, resources, laws (historical)
    regions/
    battles/       # map, frontline cap, entry points, reinforcement delays, objectives, enemy waves, script events
    campaigns/     # battle order, dates, branches, unlocks
  tests/           # GUT or gdUnit4 tests for battle and economy sim
```

Key rules:
- **Sim separated from visuals** for both battle and economy, so the math is testable and a 3D view can be swapped in later.
- **Fixed-tick battle simulation** (10–20 ticks/sec); pause stops ticks. Economy ticks per in-game day.
- **Data-driven**: adding a battle, weapon or nation means adding data files, not new code.
- **EventBus** signals for kills, objective changes, morale breaks, reinforcements arriving, retreats, equipment produced.

## 11. Milestones (build in this order)

Each milestone should be playable before moving on.

1. **Skeleton** — Godot project, folder structure, autoloads, main menu → empty battle scene. Git repo.
2. **Selection & movement** — one squad, box select, right-click move, pathfinding, camera pan/zoom.
3. **Pause & orders** — Space pauses, orders issued while paused, order queue, game speed controls.
4. **Shooting** — two opposing squads, range, accuracy, casualties.
5. **Cover, LOS, fog of war** — terrain types, cover bonuses, vision.
6. **Suppression & morale** — pinned/retreating states, UI indicators.
7. **Vehicles** — a tank with armour facings, penetration, turret rotation, AT guns.
8. **Enemy AI** — unit behaviours + basic commander attacking/defending objectives.
9. **Objectives & win/lose** — capture points, timers, victory screen.
10. **Reinforcement & retreat decisions** — reinforcement pool, call-in panel with delays and entry points, unit and full-force retreat, men-saved tracking.
11. **Force selection screen** — pick units from a region, assign Frontline/Reinforcement, enforce frontline cap.
12. **First real battle** — one fully data-driven historical battle (suggest Carentan: compact, mixed infantry/armour).
13. **Economy core** — civilian and military factories, production lines with efficiency, resources, equipment stockpiles (tested sim, simple UI).
14. **Construction & synthetics** — civilian factories building factories/refineries, synthetic oil and rubber, consumer goods.
15. **Economy ↔ battle link** — units require equipment, battle losses deplete stockpiles, replenishment after battles, fuel use.
16. **Campaign layer** — regions, unit movement, dates and time passing, roster, debrief, save/load, linking 2–3 battles.
17. **Historical data pass** — starting economies, OOBs, equipment intro dates for the first campaign.
18. **Optional battles & branching** — minor battles that alter later ones.
19. **Content pass** — remaining battles of the first campaign.
20. **Polish** — sound, VFX, artillery/air support abilities, tutorials, balancing.

## 12. Working with Claude Code

- Give it this plan, then one milestone per session: *"Implement Milestone 10 per PLAN.md. Keep sim logic in battle/sim and add tests."*
- Ask it to update a `PROGRESS.md` at the end of each milestone (what's done, known bugs, next step).
- Commit after each working milestone so you can roll back.
- Keep placeholder art (coloured shapes/icons) until Milestone 12+.
- Keep all tuning numbers (delays, efficiency rates, resource costs) in data files.
- For historical data, ask Claude Code to note sources in comments so figures can be checked later.

## 13. Open questions to decide later

- What the second game variant will be (alternate history, sandbox, etc.).
- Can the player lose a mandatory battle and continue (alternate outcome), or must they retry? (Affects how strict historical mode is.)
- Reinforcement limits: delay only, or also cooldowns / command-point costs?
- Does the player control production for one nation only, or also see enemy production?
- Trade and lend-lease (big for US/UK/USSR) — v1 or later?
- Artillery/air support: off-map abilities only, or controllable units?
- Art style: clean top-down military icons vs. small detailed sprites.
