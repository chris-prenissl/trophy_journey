---
name: verify
description: Build, launch and drive this Flutter app on macOS to verify changes at the UI surface, using the marionette CLI against the debug VM service.
---

# Verifying changes in the FF Trophy Guide app

The app embeds `marionette_flutter` (initialized in debug builds in `main.dart`),
so a running debug build can be driven from the shell with the `marionette` CLI.

## Launch

```bash
# one-time: install the CLI
dart pub global activate marionette_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

# run the app in the background and grab the VM service URI from the log
flutter run -d macos > /tmp/flutter_run.log 2>&1 &
grep -o 'ws://127.0.0.1:[0-9]*/[A-Za-z0-9_=-]*/ws' /tmp/flutter_run.log | head -1
```

## Drive

All commands take `--uri "$URI"`:

```bash
marionette --uri "$URI" take-screenshots --output shot.png --no-open
marionette --uri "$URI" get-interactive-elements     # widget tree with bounds
marionette --uri "$URI" tap --text "Final Fantasy X HD"
marionette --uri "$URI" tap --x 744 --y 590          # for icon buttons, from bounds
marionette --uri "$URI" scroll-to --text "..."       # only finds *built* widgets
marionette --uri "$URI" swipe --type ListView --direction up --distance 300
marionette --uri "$URI" press-back-button
```

## Gotchas

- `tap`/`scroll-to` by text return `Error: Server error` when the target is not
  in the (lazy) widget tree — e.g. rows below the fold of a `ListView.builder`
  or tasks inside a collapsed `ExpansionTile`. Swipe/expand first.
- FFX's list title is "Final Fantasy X HD", not "Final Fantasy X".
- Trophy checkboxes / bookmark IconButtons are tapped by coordinates from
  `get-interactive-elements` bounds (center = x+w/2, y+h/2).
- `get-logs` is not wired up in this app (no LogCollector) — it errors; use
  the flutter run log file for exceptions instead.
- Clean up test state before quitting: progress persists in sqflite
  (`trophy_progress.db`, `journey_progress.db`); undo toggles via the UI.

## Flows worth driving

- Game list → game → trophy checkbox toggle → back (game list progress updates).
- FFX only: Journey FAB → step expansion, task toggle (auto-marks covered
  trophies in the trophy list on pop), bookmark toggle → reopen auto-scrolls
  to the bookmarked step.
