# Port plan: <Game> (<engine> <version>) → Roblox

Copy this file to `docs/port-plan.md` and fill it in. Keep it current: it's
the single place that says what's done, what's next and why things were
decided. Status: ✅ done, 🟡 works but something is unverified (say what),
⬜ not started.

## Ground rules of the port

- Original source: `<path>` (read-only; never edited).
- Faithful where it counts: <numbers, feel, story…>. Changed on purpose for
  Roblox: <touch-first UI, shared servers, server authority, monetization…>.
- Every ported behaviour cites its source (`file:line`).
- Generated files and the converters that make them: <list>.

## Decisions taken (and why)

| Decision | Why | Revisit if |
|---|---|---|
| <Rendering: flat parts under a top-down camera> | <benchmark result> | <phones drop below 60 fps> |
| <Server-authoritative economy> | <currency is sold for Robux> | |
| <Players per server: Max N, M reserved for friends> | <measured X ms per player> | |

## Inventory of the original

| Area | Size | Notes |
|---|---|---|
| Code | <lines by folder> | |
| Scenes / prefabs | | |
| Shaders | <count, what each does> | |
| Art | <count, sizes> | |
| Audio | <count, total size, longest file> | |
| Data files | | |
| Languages | | |

## Build order

### Milestone 1: core loop

| # | Original | Roblox | Status |
|---|---|---|---|
| 1.1 | — | Repo from this template; checks and CI pass | ⬜ |
| 1.2 | <data files> | `tools/convert_*.py` → `src/shared/Data/*.luau` | ⬜ |
| 1.3 | <core simulation> | Pure module in `src/shared/`, specced | ⬜ |
| 1.4 | <main scene layout> | Server-built world + client view | ⬜ |
| 1.5 | <input> | Mouse, touch and gamepad; server rate limits | ⬜ |
| 1.6 | <HUD> | Client UI, scaled for phones | ⬜ |
| 1.7 | <save system> | ProfileStore; save/restore round trip | ⬜ |
| 1.8 | — | Rendering benchmark on a phone-sized screen | ⬜ |

### Milestone 2: feel and feedback

| # | Original | Roblox | Status |
|---|---|---|---|

### Milestone 3: progression

| # | Original | Roblox | Status |
|---|---|---|---|

### Milestone 4: <the game's own systems>

| # | Original | Roblox | Status |
|---|---|---|---|

### Milestone 5: story, meta, settings, localization

| # | Original | Roblox | Status |
|---|---|---|---|

### Milestone 6: Roblox-only systems

| System | Notes | Status |
|---|---|---|
| Monetization | `docs/monetization.md`: products, prices, where offers show. Idempotent `ProcessReceipt` | ⬜ |
| Leaderboards | OrderedDataStore; in-server `leaderstats` | ⬜ |
| Social | Friends, gifting, server-wide moments | ⬜ |
| Analytics | `AnalyticsService` funnel (tutorial steps), economy events | ⬜ |
| Live config | `ConfigService` for tuning without a publish | ⬜ |
| Anti-cheat | Rate limits, validation, plausibility checks, flood test | ⬜ |
| AFK | Auto-rejoin and/or offline earnings | ⬜ |
| Players per server | Measured load → Max Players, Server Fill reserve | ⬜ |

## Asset groups

| Group | Source | Conversion | Uploaded |
|---|---|---|---|

## Open questions for the owner

- <question> — <options>
