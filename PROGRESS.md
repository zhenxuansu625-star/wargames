# Progress

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
**Milestone 2: Selection & movement.** One squad scene in `battle/units/`, box select (`battle/ui/`), right-click move with NavigationServer2D pathfinding (`battle/map/`), and camera pan/zoom on the battle scene's `Camera2D`. Movement logic should step from `Battle._sim_tick()`.
