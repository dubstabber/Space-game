# Space game

A 2D space exploration game where players navigate through procedurally generated universes, collect resources, and fend off dangerous encounters.

## Tests

This project uses GUT for GDScript tests. Run the suite from the project root:

```bash
godot --headless --log-file /tmp/space-game-gut.log -d -s --path "$PWD" addons/gut/gut_cmdln.gd
```

The quality gate uses `test/quality/script_size_baselines.json` as a ratchet for existing scripts. Regenerate that baseline only after intentional refactors:

```bash
godot --headless --path . -s res://test/quality/update_script_size_baseline.gd
```
