# Progress

## Milestone 2: Selection & movement (done)

**What's in place**
- **Battle sim (`battle/sim/`, pure logic, tested):**
  - `SimUnit` holds a unit's state (id, side, soldiers, speed, position, facing, path) and is built from a `data/units` template. Speeds and sizes are converted from metres using the map's `pixels_per_meter`.
  - `Movement.step()` walks a unit along its waypoints at constant speed, carrying leftover distance round corners.
  - `Formation.grid_offsets()` spreads a group move into a grid facing the direction of travel.
  - `Selection` holds the selected unit ids and does the click / box hit-testing (own side only).
  - `BattleSim` owns the units, steps them each fixed tick and handles `order_move()`. Pathfinding is plugged in as a `path_finder` callable, so tests use straight lines and the game uses the navigation map. Units keep their left-to-right order in a group move so paths don't cross.
  - `BattleClock.interpolation_alpha()` lets views draw smoothly between 20 Hz ticks.
- **Map (`battle/map/battle_map.gd`):** builds the ground and obstacles from the battle data, bakes a navigation polygon (`NavigationServer2D`, agent radius from data) and answers `find_path()`. Region updates are asynchronous in Godot 4.7, so it reports `is_navigation_ready()` / `navigation_ready` once the map is really serving the baked polygon.
- **Units (`battle/units/squad.tscn`):** a placeholder squad view with a side-coloured circle, one dot per soldier, a facing tick, a name label, a selection ring and the remaining path line while selected.
- **UI (`battle/ui/`):** `BattleCamera` pans with WASD/arrows or middle-mouse drag, zooms with the wheel toward the cursor (0.4×–2.5×) and stays inside the map. `SelectionController` handles click select, drag box select, Shift to add, click on empty ground to deselect, and right-click move. `MoveMarker` shows a ring where you ordered a move.
- **Data:** `data/units/us_rifle_squad.json` (12 men, sources noted) and `data/battles/sandbox.json` (3200×2400 px test map at 8 px/m, three buildings / a pond, three US rifle squads, `formation_spacing_m`).
- `core/data_loader.gd` (`DataLoader`) reads JSON data files; `CampaignManager` now uses it.
- New input actions in `project.godot`: `camera_pan_*`, `camera_zoom_in/out`, `select` (LMB), `command` (RMB), `selection_add` (Shift).
- Main menu: Quick Battle now opens the sandbox map.

**Controls:** LMB select / drag a box, Shift+LMB add to selection, RMB move, WASD/arrows or middle-mouse drag to pan, mouse wheel to zoom, Esc back to menu.

**Verified**
- `./run_tests.sh`: 27/27 passing (6 suites), including an integration test that paths go round an obstacle on a real baked navigation map.
- Scripted run of the real battle scene under a virtual display: wheel zoom, click select, click-empty deselect, box select of all three squads, right-click move to the far side of a building. All three paths went round it, every squad arrived at a separate formation slot (≥64 px apart), no squad was ever inside an obstacle, keyboard pan moved the camera, and Esc returned to the menu.

**Known issues / notes**
- No unit-to-unit avoidance yet: squads moving as a group share the same corner of a path and can overlap while moving. They separate at the destination.
- A right-click in the first couple of physics frames after the battle loads does nothing (navigation not ready yet).
- Squads walk at 5 m/s, which is faster than real infantry (noted in the data file); tune for feel.
- Shift is used for "add to selection" now; Milestone 3's Shift-queue applies to right-click orders, so they don't clash.

## Milestone 1: Skeleton (done)

**What's in place**
- Godot 4.7 project (`project.godot`) using the Compatibility renderer, a 1280×720 window with `canvas_items` stretch, and `menus/main_menu.tscn` as the main scene.
- The folder structure from PLAN.md section 10, plus `menus/`. Empty folders hold a `.gitkeep`.
- Core autoloads in `core/`:
  - `EventBus` declares every cross-system signal (kills, objectives, morale, reinforcements, retreats, production, save/load, scene changes).
  - `Ruleset` holds the active `GameRuleset`. `HistoricalRuleset` is the only one so far and gates equipment on its intro date.
  - `GameState` holds the current date and pending battle id, provides scene-flow helpers (`go_to_main_menu`, `start_battle`) and `to_dict`/`from_dict`.
  - `CampaignManager` is a stub. It loads `data/campaigns/<id>.json` and tracks completed battles.
  - `SaveSystem` saves and loads JSON in `user://saves/<slot>.json`, with a version check.
- The main menu has Quick Battle (opens the empty battle), Campaign (disabled until M16) and Quit.
- `battle/battle.tscn` is the empty battlefield: a placeholder ground, a camera, and a HUD showing battle time. Esc returns to the menu. It is driven by `BattleClock` (`battle/sim/battle_clock.gd`), the fixed-tick clock (20 ticks/s, pause and speed multiplier), which is pure logic.
- gdUnit4 6.2.3 is vendored in `addons/gdUnit4` (its own internal test folder is left out) and the editor plugin is enabled. `run_tests.sh` runs the suite headless.
- Example test: `tests/battle/sim/test_battle_clock.gd` (4 cases, all passing).

**CI**
- `.github/workflows/tests.yml` runs the gdUnit4 suite through `godot-gdunit-labs/gdUnit4-action@v1.4.2` (formerly `MikeSchulze/gdUnit4-action`) on Godot 4.7.2, using the vendored gdUnit4 6.2.3. It runs on pushes to `main`, on PRs and on manual dispatch. The test report is published as a check run; this is skipped for fork PRs, which can't write checks.

**Verified**
- `./run_tests.sh` reports 4/4 passing with Godot 4.7.2.
- Headless smoke run: all 5 autoloads present, menu → Quick Battle → battle ticking → Esc → menu, and save/load round-trip of `GameState` all work with no script errors.

**Known issues / notes**
- Headless gdUnit4 needs `--ignoreHeadlessMode`, which `run_tests.sh` passes. UI-input tests won't work headless.
- gdUnit4's runner prints a harmless "Unable to connect to host 127.0.0.1:0" error on start. This is intentional on its side, to disable the interactive debugger.
- The pause input (Space) and game-speed controls are not wired yet. They come in Milestone 3. `BattleClock` already supports both.
- Opening the project in the editor for the first time may add gdUnit4 settings to `project.godot`. Commit those.

## Next step
**Milestone 3: Pause & orders.** Space pauses the `BattleClock` (with an on-screen pause overlay in `battle/ui/`), orders can be issued while paused, an order queue per unit in `battle/orders/` (Shift+right-click appends), and game-speed controls. `BattleSim.order_move()` should become one order type in that queue.
