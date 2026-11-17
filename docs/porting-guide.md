# Porting a game to Roblox

What carries over from another engine (Godot, Unity, GameMaker, a web game…),
what has to be rebuilt, and the decisions that matter most. Written from a
real port of a 2D Godot incremental game (about 45k lines of GDScript, 15
shaders, 30 languages), checked against Roblox's docs in November 2026.
Roblox changes fast, so recheck anything about limits, policy or prices.

## What carries over

| Part | How well | How |
|---|---|---|
| Design, balance numbers, data tables | Very well | Write converters in `tools/` that turn the original's data files (JSON, CSV, `.tres`, ScriptableObjects…) into Luau modules. Never hand-copy numbers. Luau numbers are doubles, so values up to about 1e308 need no big-number library. |
| Game logic | Good, as a rewrite | There's no converter: rewrite in strict Luau. Logic translates fairly directly (GDScript, C# and JS all map well), but engine APIs don't: nodes and scenes become instances, signals become events, tweens become `TweenService`, physics queries become your own maths or `workspace` queries. |
| 2D art | Good | UI images keep pixel art crisp with `ResampleMode = Pixelated`. **3D textures are always filtered**, so upscale pixel art 8× with nearest-neighbour before using it on parts. |
| 3D models | Good | See the Blender section of `workflows.md`. 20k triangles and one material per mesh. |
| Audio | Good | mp3, ogg, wav and flac under 20 MB and 7 minutes. Each upload gets a copyright check; a licensed sound can still be flagged, and you can appeal. Layered music plays as separate `Sound`s started together, which may drift slightly. |
| Shaders | Poor | Roblox has **no custom shaders**. See below. |
| Fonts | Unclear | Custom font uploads weren't confirmed when this was written. Use Roblox's font families, or draw text from a sprite sheet. Roblox's fonts already cover CJK and Arabic. |
| Localization | Good | `tools/convert_po.py` turns gettext `.po` files into a LocalizationTable CSV (Godot's BBCode becomes RichText). Other formats need a similar converter. |
| Saves | Good | ProfileStore (Wally) on top of DataStores, with session locking. Validate on load: never save NaN or infinity, and refuse saves from a newer version. |
| Achievements | Good | Badges. A few per day are free per experience; more cost Robux. |
| In-app purchases | Good | Game passes (permanent), developer products (consumables) and subscriptions. |
| Controller support | Good | `GuiService`'s virtual cursor and `ContextActionService`. |
| Desktop-only input | Needs work | Most Roblox players are on phones: add touch controls and a phone layout early. |
| Debug and dev tools | Rebuild | Cheat consoles become Studio-only server commands. |

## How to run a port

1. **Inventory the original.** Count code by area, list every system
   (autoloads, managers, scenes), shader, asset folder and data file. This
   becomes the left column of `docs/port-plan.md`.
2. **Write the plan** from [port-plan-template.md](port-plan-template.md):
   every system, its Roblox counterpart, the decisions taken and why, and
   milestones in build order. Put the **core loop first**, playable in
   Studio, with saving.
3. **Spec, then build.** For each large system, read the original's code
   and write `docs/<system>-spec.md`: the exact behaviour, numbers and edge
   cases, with source file and line references. Build from the spec. Agents
   can research specs in parallel and build systems in parallel when they
   own separate files.
4. **Keep logic pure and specced.** Put simulation, economy and rules in
   modules that don't touch instances, and spec them headless with Lune
   (`tools/test.cmd`). Playtest rendering, input and UI through the Studio
   MCP. A large port can carry thousands of spec checks that run in seconds.
5. **Prototype the riskiest part early,** usually rendering or server load
   (below), and measure it on a phone-sized device before building on it.
6. **Port feel, not just function.** Hit flashes, screen shake, popups,
   transitions and sound make the original feel like itself; schedule a
   milestone for them.
7. **Add the Roblox-only systems last:** shop, leaderboards, social,
   analytics, live config, AFK handling.

## Decisions that matter

### Rendering lots of sprites

`ScreenGui` `ImageLabel`s are fine for UI, but thousands of moving sprites
get heavy on phones. Flat parts on a 3D surface, seen by a top-down camera
with a narrow field of view (nearly orthographic), render much faster
because Roblox instances identical parts. Benchmark both in your first
milestone with the MicroProfiler (Ctrl+F6) and Studio's device emulator,
then check on a real phone. Cap the number of live objects and pool them,
as most 2D engines' ports already do.

### Replacing shaders

| Shader does | Roblox replacement |
|---|---|
| Dissolve, tear, burn, damage stages | Render the original shader offline into sprite-sheet frames (run the original engine headless and capture each step) and flip through them. A few noise variants hide repetition. |
| Shine, sweep, progress fill | `UIGradient` with an animated `Offset` or `Rotation` |
| Tint, flash | `ImageColor3`, a white overlay frame with tweened transparency |
| Vignette, CRT, scanlines | Overlay images |
| Glow, bloom | Pre-rendered glow sprites, or `Lighting` effects in 3D |
| Screen-space distortion (shockwave, heat haze) | No equivalent: drop it or fake it with scaling sprites |

### The server owns anything of value

As soon as anything is sold for Robux or ranked, the client can't be
trusted. Run the economy on the server (or validate it there), send the
client only what it needs to draw, and:

- rate-limit every remote (`src/server/RateLimit.luau`) and validate every
  argument;
- make `ProcessReceipt` idempotent: record each purchase ID in the
  session-locked save before granting it;
- check plausibility, such as income per second against the player's
  upgrades;
- isolate errors, so one player's failure doesn't stop everyone's frame;
- copy live state into the save right before saving, and save on leave and
  on shutdown (`game:BindToClose`).

A flood test helps: fire each remote hundreds of times from a test client
and check the server stays fast and grants nothing extra.

### Players per server

A Roblox server always hosts several players, even for a single-player
game. Options:

- **Solo servers** (Max Players 1): simplest, but friends can't join each
  other, and "join a friend" is one of Roblox's main growth channels.
- **Shared servers without fixed slots (recommended):** every player's game
  runs on the server, but each client draws only its own. Don't build one
  physical spot per player, which ties the player cap to a map layout.
- **Set Max Players from measured load, not a guess.** Bound each player's
  worst-case server cost (cap every source of work), measure it with
  `src/server/ServerLoad.luau`, and leave headroom under the 16.7 ms frame.
- **Reserve slots for friends:** in the place settings, set Server Fill to
  Customize and reserve a few slots. Matchmaking leaves them free, so friends
  can still join. A join to a completely full server is refused by Roblox
  itself, before any game code runs, so a game can't catch it.

### Idle and AFK

Roblox disconnects a player after 20 minutes without input. Idle games
need one or both of these:

- **Auto-rejoin:** shortly before the kick, save and teleport the player
  back into the game (`TeleportService`). It costs a few seconds of loading,
  and they may land in another server.
- **Offline earnings:** pay a capped share of the idle income when the
  player returns. It works even if they closed the game.

### Reskins and variants

If you might ship themed versions later, keep everything theme-specific in
one module from the start: asset IDs, currency symbol and name, character
names, colours, and text in the string tables. A variant then becomes new
art plus a theme choice, built from the same code. Roblox lowers the reach
of games that closely resemble existing ones, your own included, so each
variant needs its own title, thumbnails and real in-game differences
([publishing.md](publishing.md)).

### Smaller things that bite

- Turn off `Players.CharacterAutoLoads` if the game has no avatar.
- Keep UI clear of Roblox's top bar: use `ScreenGui.ScreenInsets` or
  `GuiService:GetGuiInset()`.
- Studio's device emulator still reports a mouse, so touch-only code paths
  only run on a real phone. Test there before release.
- Minimised Studio stops 3D rendering, so a playtest screenshot can come
  back blank.
- A `wally install` while `rojo serve` is running can crash Rojo. The check
  scripts only install when no package folder exists.

## Monetization within Roblox's rules

- **Products:** game passes for permanent perks (2× income, auto-collect,
  VIP), developer products for consumables (premium currency packs, boosts),
  a starter bundle, cosmetics, and possibly an experience subscription.
- **Show odds** for any paid random item, and check
  `PolicyService:GetPolicyInfoForPlayerAsync` (`ArePaidRandomItemsRestricted`)
  so they're hidden where the law requires.
- **No fake urgency:** time limits must be real (for example "first 3 days
  of play"), and discounts must be real.
- **Don't theme the game around Robux.** A game where you earn "Robux"
  reads like a free-Robux game, which Roblox treats as a scam, and the Robux
  name and icon are Roblox's trademarks. Use your own currency.
- **Put the shop where players are:** a shop button on the main screen and
  offers next to what they boost, not buried in a menu.
- Retention features matter for discovery too: daily rewards, a group join
  reward, friend boosts, playtime rewards and events.

## Before release

Read [publishing.md](publishing.md): account and group requirements, the
content questionnaire, the extra steps for all-ages audiences, discovery
rules and ad costs.
