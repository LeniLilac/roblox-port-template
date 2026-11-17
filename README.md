# roblox-port-template

A starter for **porting an existing game to Roblox with an AI coding agent**
(Claude Code, Codex, Cursor or any agent that reads `AGENTS.md`). Luau code
lives in files synced by [Rojo](https://rojo.space), and the agent playtests,
inspects and builds in Studio through the
[Roblox Studio MCP server](https://create.roblox.com/docs/studio/mcp). It
was made while porting a 45k-line Godot game, and keeps what worked.

**What you get:**
- **Tooling pinned with Rokit:** Rojo, StyLua, selene, strict luau-lsp,
  Wally, Asphalt and Lune.
- **One check command, mirrored in GitHub Actions CI:** format, lint, types,
  build and specs.
- **Headless specs with Lune:** game logic tested in under a second, no
  Studio needed.
- **Asset uploads through Asphalt and Open Cloud:** files in `assets/` become
  typed IDs in code, and nothing uploads as your personal account.
- **Porting guides:** what carries over from other engines, replacing
  shaders, server authority, players per server, AFK, monetization rules,
  and publishing and discovery.
- **Starter code:** server rate limits, a server-load meter, number
  formatting, and a `.po` → LocalizationTable converter.
- **Agent rules** in [AGENTS.md](AGENTS.md); `CLAUDE.md` imports them.

| Doc | What's in it |
|---|---|
| [docs/porting-guide.md](docs/porting-guide.md) | What carries over, how to run a port, the decisions that matter |
| [docs/port-plan-template.md](docs/port-plan-template.md) | The plan to fill in for your game |
| [docs/workflows.md](docs/workflows.md) | Tooling: checks, packages, tests, environments, Blender, MCP servers |
| [docs/asset-sources.md](docs/asset-sources.md) | Free models, textures, sounds, music and icons, and their licences |
| [docs/publishing.md](docs/publishing.md) | Accounts and groups, going public, all-ages audiences, discovery, ads |

## One-time setup

1. Make a repo from this template (**Use this template** on GitHub), clone
   it, and install [Rokit](https://github.com/rojo-rbx/rokit). Then:

   ```bash
   rokit install
   rojo plugin install
   ```

2. In Roblox Studio, open **Assistant → … → Manage MCP Servers** and turn on
   **Enable Studio as MCP server**.
   - **Windows:** `.mcp.json` starts it through `tools/studio-mcp.cmd`, which
     always finds the newest Studio version. Studio's own `mcp.bat`
     hardcodes one version and breaks when Studio updates.
   - **macOS:** change the `Roblox_Studio` entry in `.mcp.json` to
     `"command": "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"`
     with no args, and remove the `Blender` entry unless you set it up.
3. Build the working place once, then open it in Studio:

   ```bash
   rojo build -o place.rbxlx
   ```

   After this, only open and save that file in Studio. Rebuilding over it
   erases anything made in Studio.
4. **For uploads:**
   - In `asphalt.toml`, set `[creator]` to your group (recommended) or user.
   - Copy `.env.example` to `.env` and put an Open Cloud API key with
     **assets** read and write in `ASPHALT_API_KEY`. A key owned by a separate
     uploader account keeps moderation away from your own account
     ([publishing.md](docs/publishing.md#accounts-and-a-group)).
   - Run `tools/check-key.cmd` (or `.sh`) to see the key's owner and
     permissions.
   - Turn on Asset Privacy before the first upload
     ([asset-sources.md](docs/asset-sources.md#the-rules)).
5. **Optional, for 3D models:** install Blender 5.1+, add the extensions
   repository `https://lab.blender.org/` in its preferences and enable the
   **MCP** add-on, then install the server:

   ```bash
   uv tool install "git+https://projects.blender.org/lab/blender_mcp.git@v1.0.3#subdirectory=mcp"
   ```

   On Windows, start Blender with `tools\blender.cmd` before asking the
   agent to use it.
6. Rename things: `name` in `default.project.json` and `wally.toml`, and the
   copyright holder in `LICENSE` if you keep it.

## Each session

1. Open `place.rbxlx` in Studio.
2. Run `rojo serve` in a terminal and click **Connect** in the Rojo plugin.
3. Start your agent in this folder and approve the `Roblox_Studio` MCP server
   the first time it asks.
4. **First session of a port:** point the agent at the original game's
   folder and ask it to read `docs/porting-guide.md` and write
   `docs/port-plan.md` from the template.

## Commands

Windows uses `tools\x.cmd`; macOS and Linux use `tools/x.sh`.

| Command | Does |
|---|---|
| `tools/check` | Format check, lint, strict types, build, specs: the same as CI |
| `tools/check fix` | Format `src/` and `tests/` in place, then check |
| `tools/test [words]` | Only the specs (optionally only those whose names contain the words) |
| `tools/assets` | Upload new or changed files in `assets/`, regenerate `src/shared/assets.luau` |
| `tools/assets cloud --dry-run` | List what would upload |
| `tools/check-key` | Show the Open Cloud key's owner and permissions, never the key |
| `wally install` | Install the packages in `wally.toml` |
| `python tools/convert_po.py <dir>` | gettext `.po` files → `src/localization/GameStrings.csv` |

## What lives where

- **Git:** code (`src/`), specs (`tests/`), the Rojo project, tool and agent
  config, docs.
- **Place file (gitignored):** world content built in Studio. Publish the
  place to Roblox or back it up yourself. `rojo syncback` brings world
  content into files if you need it.
- **Never in Git:** `.env` and any key. Uploaded asset IDs are fine
  (`src/shared/assets.luau` and `asphalt.lock.toml` are committed).

## Licence

MIT, see [LICENSE](LICENSE). Downloaded tools and packages keep their own
licences; the Blender MCP server is GPL-3.0 and isn't included here.
