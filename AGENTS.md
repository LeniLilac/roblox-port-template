# Agent rules

Roblox place where **code lives in files** (synced into Studio by Rojo) and
**Studio is driven through the Roblox Studio MCP server** (`Roblox_Studio`,
configured in `.mcp.json`) for playtesting, inspection and world building.
Models can be made in Blender through Blender Lab's MCP server (`Blender`).

This template is for **porting an existing game to Roblox**. Read
[docs/porting-guide.md](docs/porting-guide.md) before planning a port, and
keep the port's plan in `docs/port-plan.md` (start from
[docs/port-plan-template.md](docs/port-plan-template.md)). Tooling:
[docs/workflows.md](docs/workflows.md). Allowed asset sources and licences:
[docs/asset-sources.md](docs/asset-sources.md). Going public:
[docs/publishing.md](docs/publishing.md).

Commands below are written for Windows (`tools\x.cmd`); on macOS and Linux
use `tools/x.sh`.

## Layout

| Folder         | Studio location                                | Notes                          |
| -------------- | ---------------------------------------------- | ------------------------------ |
| `src/shared/`  | `ReplicatedStorage.Shared`                     | ModuleScripts used by both sides |
| `src/server/`  | `ServerScriptService.Server`                   | server code                    |
| `src/client/`  | `StarterPlayer.StarterPlayerScripts.Client`    | client code                    |
| `tests/`       | `ServerStorage.Tests`                          | `*Spec.luau` specs, run headless by Lune |
| `Packages/`    | `ReplicatedStorage.Packages`                   | Wally packages (generated)     |
| `ServerPackages/` | `ServerScriptService.ServerPackages`        | Wally server packages (generated) |

`default.project.json` is the Rojo tree. File naming: `Foo.luau` →
ModuleScript, `Foo.server.luau` → Script, `Foo.client.luau` → LocalScript,
`init.*.luau` turns the containing folder into that script.

## Rules

1. **Edit code as files, never through MCP.** Change `.luau` files under
   `src/` with normal file tools; Rojo pushes them into Studio. Do not use the
   MCP `multi_edit` tool (or `execute_luau` setting `.Source`) on anything
   under a Rojo-managed path. Rojo overwrites those edits and they never
   reach git.
2. **Studio owns the world.** Parts, models, terrain, lighting tweaks and UI
   built with `execute_luau`, `insert_asset` or the `generate_*` tools go
   outside the Rojo-managed folders above (for example directly under
   `Workspace`). Anything Rojo manages gets replaced on sync.
3. **Instances listed in `default.project.json`** (`Workspace.Baseplate`,
   `Lighting` and `SoundService` properties) are Rojo-managed. Change them in
   the project file, not in Studio.
4. **Never `rojo build` over the working place file** (`place.rbxlx`): that
   wipes everything built in Studio. To check that the project builds, write
   to the gitignored `check.rbxl`: `rojo build -o check.rbxl`.
5. Save Studio-side work with the MCP `save_place` tool after building or
   changing world content.
6. Don't start `rojo serve` yourself; the user keeps it running in their own
   terminal. If edits aren't showing up in Studio, ask them to check that
   `rojo serve` is running and the Rojo plugin is connected.
7. **Upload through `tools\assets.cmd` only.** It uploads everything new or
   changed in `assets/` with the Open Cloud key in `ASPHALT_API_KEY`, as the
   creator set in `asphalt.toml`. Never use `insert_asset`, `upload_image` or
   Studio's Asset Manager for the project's own files: those upload as
   whoever is signed in to Studio. Studio's 3D Importer does too, so ask
   before using it (it's only needed for rigs and skinned meshes).
   `src/shared/assets.luau` and `asphalt.lock.toml` are generated: don't edit
   them by hand, and commit them with the change that uses the new assets.
   If the user hasn't said uploads are fine without asking, ask first.
8. **Never read or print secrets.** Don't open `.env`, don't print
   environment variables, and never put a key on a command line. Use
   `tools\check-key.cmd` to check a key: it prints only the key's owner and
   permissions.
9. **Only licensed assets.** Every file in `assets/` is the user's own, CC0,
   or under a licence `docs/asset-sources.md` allows. CC-BY needs credit;
   never NonCommercial, NoDerivatives, ShareAlike or GPL. Record each
   third-party file in `THIRD_PARTY_NOTICES.md` when adding it. Download
   packs into `downloads/` (gitignored) and copy only the files used into
   `assets/`. Free Creator Store models: insert with scripts disabled and vet
   them as that doc says.
10. **Run `tools\check.cmd` before committing** and fix what it reports
    (StyLua format, selene lint, strict luau-lsp types, Rojo build, specs).
    CI runs the same checks on every push.
11. **Packages come from Wally.** Add them to `wally.toml` and run
    `wally install`; never edit `Packages/` or `ServerPackages/`.
12. **Look Roblox APIs up rather than guessing:** any
    `create.roblox.com/docs/...` page is available as Markdown by appending
    `.md`; the index is `https://create.roblox.com/docs/llms.txt`.

## Porting rules

13. **The original game is read-only.** Read its source and assets from
    their own folder; never edit them. Converters in `tools/` read the
    original and write generated files here; rerun them instead of editing
    their output.
14. **Cite the original.** Comments and specs name the source file and line
    a behaviour comes from (`player.gd:120`), so a mismatch can be checked.
15. **Plan first, then build in order.** Keep `docs/port-plan.md` current:
    every system of the original, its Roblox counterpart, and its status.
    Write a spec (`docs/<system>-spec.md`) from the original's code before
    porting a large system.
16. **Logic in pure modules, specced headless.** Simulation, economy and
    rules go in modules under `src/shared/` (or `src/server/`) that don't
    touch instances, with `tests/*Spec.luau` specs. Rendering, input and UI
    are checked by playtesting through the Studio MCP.
17. **The server owns anything of value.** Currency, progress, purchases and
    rankings are decided on the server. Every remote is rate-limited
    (`src/server/RateLimit.luau`) and validates its arguments.
18. **Ask before anything on Roblox's side:** creating or publishing an
    experience, changing its settings (audience, Max Players, Server Fill),
    or creating game passes, developer products, badges or subscriptions.

## Dev loop

1. Edit files in `src/`.
2. `start_stop_play` to start a playtest.
3. Observe: `get_console_output`, `screen_capture`, `inspect_instance`,
   `search_game_tree`, `execute_luau` (Server/Client context while playing).
   Drive the player with `character_navigation`, `user_keyboard_input`,
   `user_mouse_input`.
4. `start_stop_play` to stop, fix files, repeat.

If several Studio windows are open, call `list_roblox_studios` and pass the
right `studio_id`. Use `execute_luau` in the Edit context for one-off queries
about the place; don't leave stray instances behind.

## Commands

```bash
rokit install                      # install pinned tools (rokit.toml)
rojo serve                         # live sync (the user runs this)
tools\check.cmd                    # format, lint, types, build, specs (as CI)
tools\check.cmd fix                # format src\ and tests\ in place, then check
tools\test.cmd                     # specs only; tools\test.cmd Save runs matching ones
wally install                      # install packages from wally.toml
tools\assets.cmd                   # upload new or changed assets
tools\assets.cmd cloud --dry-run   # list what would upload
tools\check-key.cmd                # show the key's owner and permissions
python tools\convert_po.py <dir>   # gettext .po files -> LocalizationTable CSV
tools\blender.cmd                  # start Blender for the Blender MCP
tools\blender.cmd -b x.blend -P y.py   # run a Blender script headless
```
