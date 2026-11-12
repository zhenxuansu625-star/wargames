# CLAUDE.md

**Read `PLAN.md` first.** It is the design and build plan (locked decisions, systems, architecture, milestone order). **`PROGRESS.md`** records what's done, known issues and the next step. Update it at the end of every milestone.

## Quick facts
- Godot **4.7** with GDScript. `res://` is the repo root. Main scene: `res://menus/main_menu.tscn`.
- Autoloads (in `core/`, in this load order): `EventBus`, `Ruleset`, `GameState`, `CampaignManager`, `SaveSystem`.
- Folder layout follows PLAN.md section 10. There is one addition: `menus/` holds front-end screens (main menu) that don't belong to battle, economy or campaign.
- Tests use **gdUnit4 6.2.3**, vendored in `addons/gdUnit4/`. Test suites go under `tests/` and mirror the source path, e.g. `tests/battle/sim/test_battle_clock.gd`.

## Commands
```bash
# Run all tests headless (imports the project first)
GODOT_BIN=/path/to/godot ./run_tests.sh
# Run one suite
GODOT_BIN=/path/to/godot ./run_tests.sh -a res://tests/battle/sim/test_battle_clock.gd
# Run the game
/path/to/godot --path .
```

## Rules (from PLAN.md, summarized)
- Work one milestone per session, in the order given in PLAN.md section 11. Each milestone must be playable.
- Keep sim logic (`battle/sim`, `economy/sim`) free of rendering and nodes. Prefer `RefCounted` classes so the logic is testable. Add tests for sim code.
- The battle sim runs on fixed ticks (`BattleClock`, 20 ticks/s). Pausing stops ticks.
- Keep it data-driven: tuning numbers, battles, units, equipment and nations belong in `data/`, not in code. Note historical sources in the data files.
- Mode-specific rules go behind `GameRuleset` (`core/rules/`), reached via `Ruleset.active`.
- Cross-system communication goes through `EventBus` signals, using StringName ids rather than node references.
- Use placeholder art (coloured shapes) until Milestone 12+.
- Dates are ISO strings in the form `"YYYY-MM-DD"`, which compare correctly as plain strings.
- Commit `.uid` files. Don't commit `.godot/` or `reports/`.
