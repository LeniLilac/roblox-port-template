# Asset sources

Where to get models, textures, sounds, music, animations and icons that may
ship in this game, and what each needs. Researched 2026-11-16 against each
site's own licence page; re-check a licence before relying on it.

## The rules

- **Default to CC0.** It needs no credit and fits Roblox's upload terms
  (Terms of Use §3.2: you grant Roblox a sublicensable licence to anything
  you upload, "including to other Users").
- **CC-BY is fine with credit.** Add the file to `THIRD_PARTY_NOTICES.md` and
  to the in-game credits.
- **Paid packs** (Synty, Unity Asset Store, Fab) and **SFX libraries**
  (Sonniss, ZapSplat, Pixabay) allow use inside your game but forbid
  handing out the raw files. Keep these uploads private: never Open Use,
  never on the Creator Store. Use paid files only when the user owns the
  licence.
- **Never:** anything NonCommercial (a monetised game counts as commercial
  use), NoDerivatives, GPL, ShareAlike (BY-SA), Sketchfab Editorial, Fab
  Reference-Only or UEFN-only assets, Freesound's legacy Sampling+, fan-made
  copies of real franchises (the licence on them isn't valid), and FreePD
  "mirrors" (FreePD closed in 2025).
- **Record every third-party file** in `THIRD_PARTY_NOTICES.md`: source,
  licence, author if credit is needed.
- **Asset Privacy.** Roblox makes new images, decals and meshes **Open Use**
  (any game may use them) unless the uploading account or group has opted
  out, and Open Use can't be undone (the setting isn't retroactive). Turn it
  on for your community or account **before the first upload**: Creator
  Dashboard → Settings → Advanced → Asset Privacy, "Opt-in to restrict
  assets on creation". Restricted uploads then load only in your own
  experiences.

★ = widely used by Roblox developers.

## 3D models

| Source | Has | Licence | Credit | Login | Scriptable |
|---|---|---|---|---|---|
| [Kenney](https://kenney.nl/assets) ★ | Low-poly kits, UI, audio | CC0 | No | No | Zip per pack |
| [Quaternius](https://quaternius.com) ★ | Low-poly packs, rigged characters | CC0 | No | No | Zip; mirrored on Poly Pizza |
| [KayKit](https://kaylousberg.itch.io) ★ | Themed low-poly packs | CC0 1.0 | No | No | Manual (itch.io) |
| [Poly Haven](https://polyhaven.com/models) ★ | Realistic models | CC0 | No | No | [API](https://api.polyhaven.com), no key; send a unique User-Agent |
| [Poly Pizza](https://poly.pizza) | 10k+ low-poly models | Per model: CC0 or CC-BY | CC-BY: yes | — | API with a key |
| [Sketchfab](https://sketchfab.com/search?features=downloadable&type=models) | 700k+ models | Per model: CC0, CC-BY, Standard, Editorial | CC: yes | Yes | Download API (OAuth) |
| [OpenGameArt](https://opengameart.org) | Community 2D/3D/audio | Per file | Unless CC0 | No | Direct file URLs |
| [Smithsonian 3D](https://3d.si.edu) | Museum scans | CC0 | No | No | API key (api.data.gov); scans need cutting to 20k triangles |

Paid, often used on Roblox: [Synty](https://syntystore.com) (EULA allows
Roblox while the assets "remain under your direct control"),
[Unity Asset Store](https://assetstore.unity.com) (other engines allowed;
players must not be able to extract raw files),
[Fab](https://fab.com) (not limited to Unreal; no standalone
redistribution).

Sketchfab: filter by licence; Standard licence bans standalone files, and
some models carry NoAI tags (Roblox's terms keep a right to use content for
AI training, so avoid those).

## Textures, materials, skies

| Source | Has | Licence | Credit | Scriptable |
|---|---|---|---|---|
| [Poly Haven](https://polyhaven.com) ★ | PBR textures, HDRIs | CC0 | No | API |
| [ambientCG](https://ambientcg.com) ★ | PBR materials, HDRIs | CC0 1.0 | No | [API v3](https://docs.ambientcg.com/api/) |
| [ShareTextures](https://sharetextures.com) | Textures, models | "Custom CC0" | No | **No:** its licence bans automated downloads |

- PBR maps go on a `SurfaceAppearance` (ColorMap, NormalMap, RoughnessMap,
  MetalnessMap) or a `MaterialVariant` for terrain and parts.
- Since January 2026 Roblox renders textures up to 4096 px (uploads up to
  8000 px are stored). Use 1024 for most things; bigger costs memory on
  phones.
- A Roblox sky is six cube-face images (`Sky.SkyboxBk/Dn/Ft/Lf/Rt/Up`): an
  HDRI has to be converted to a normal (non-HDR) cubemap first.

## Sound effects

| Source | Has | Licence | Credit | Login | Notes |
|---|---|---|---|---|---|
| [Kenney audio](https://kenney.nl/assets?q=audio) ★ | UI, impact, RPG, voice | CC0 | No | No | Zip |
| [Freesound](https://freesound.org) ★ | Huge library | Per sound: CC0, CC-BY 4.0, CC-BY-NC | BY: yes | Yes | Skip NC and Sampling+. API: a token for search and previews, OAuth for originals |
| [Sonniss GDC bundles](https://sonniss.com/gameaudiogdc) ★ | Multi-GB yearly bundles | Sonniss royalty-free | No | No | Private uploads only; you may not "supply the sound effects as sound effects" |
| [ZapSplat](https://zapsplat.com) | 160k+ sounds | ZapSplat Standard | Free tier: "ZapSplat" | Yes | Private uploads only; no redistribution |
| [Pixabay](https://pixabay.com/sound-effects/) | SFX | Pixabay Content License | No | — | Private uploads only; no mass downloading; AI content mixed in (labelled) |

## Music

| Source | Licence | Credit | Notes |
|---|---|---|---|
| Roblox Creator Store audio ★ (APM, Monstercat and others) | Roblox Licensed Music (ToU §7.1) | No | Free, on Roblox only. At most 250 distinct tracks per game. No in-game music library, no charging per track. Insert by ID; nothing to upload |
| [Incompetech](https://incompetech.com/music/royalty-free/) ★ (Kevin MacLeod) | CC-BY 4.0 | Title, "Kevin MacLeod (incompetech.com)", licence and URL on a credits screen | Streamers may get claims; the FAQ asks you to email so he can whitelist the game |
| [Pixabay music](https://pixabay.com/music/) | Pixabay Content License | No | Some tracks are in YouTube Content ID, so players' videos can be claimed |
| [OpenGameArt](https://opengameart.org/art-search-advanced) | Per file | Usually | Check each file |

## Animations and rigs

| Source | Licence | Notes |
|---|---|---|
| [Mixamo](https://www.mixamo.com) ★ | Adobe terms, royalty-free in games | Adobe ID. Don't distribute the raw files: private uploads only. Retarget to R15 |
| [Quaternius Universal Animation Library](https://quaternius.itch.io/universal-animation-library) | CC0 1.0 | 45 free, more paid; humanoid rig, needs retargeting |
| [KayKit Character Animations](https://kaylousberg.itch.io/kaykit-character-animations) | CC0 1.0 | 150+, made for KayKit rigs |
| Roblox's own animation packs | Roblox ToU | On Roblox only |

Animations upload as `.rbxm` only: import the FBX in Studio's Animation
Editor (or the 3D Importer for a rig) first.

## Fonts and icons

- **Fonts can't be uploaded.** Pick from Roblox's 80+ Creator Store fonts
  with `TextLabel.FontFace` / `Font.fromId`, or bake text into an image.
- **Icons** upload as images:

| Source | Licence | Credit |
|---|---|---|
| [Kenney UI](https://kenney.nl/assets?q=ui) ★ | CC0 | No |
| [Material Symbols](https://github.com/google/material-design-icons) | Apache-2.0 | Not required |
| [Lucide](https://lucide.dev) | ISC | Keep its notice (credits screen) |
| [game-icons.net](https://game-icons.net) | CC-BY 3.0 | "Icons made by {author}. Available on https://game-icons.net" |

## Roblox's own

- **Creator Store models, decals, audio:** free to use in Roblox games under
  the Creator Store terms, no credit needed. Stolen re-uploads are common
  and the risk is yours: prefer assets by known creators.
- **Free models can carry backdoors.** Insert with scripts disabled, then
  search the model for `require(`, `loadstring`, `getfenv`, `setfenv`,
  `InsertService`, `HttpService` and obfuscated strings before enabling
  anything. Keep `ServerScriptService.LoadStringEnabled` off. Prefer meshes
  and images over scripted models.
- **AI generation** (Studio Assistant, `generate_*` MCP tools, Cube
  text-to-3D, Material Generator): Roblox claims no ownership of outputs and
  sets no commercial ban (ToU §5.3), but outputs may not be unique.
  Procedural model generation is capped at 50 per 24 hours.

## Roblox upload limits

| Asset | Limit |
|---|---|
| Audio | mp3, ogg, wav, flac; under 20 MB and 7 minutes; up to 48 kHz. Monthly quota depends on ID verification; Roblox's docs disagree on the numbers (2,000 vs 100), so read the API's error if one fails |
| Images | Under 8000×8000; png, jpeg, bmp, tga |
| Meshes and models | fbx, gltf, glb, rbxm; 20 MB per upload; 20,000 triangles per mesh; up to 4 bone influences per vertex; one animation per FBX |
| Video | mp4, mov; up to 5 minutes and 4096×2160; 20 per day; ID-verified 13+ only |

Every upload is moderated (Asphalt waits for the result); audio also gets a
copyright check.

## Not fully verified (2026-11-16)

Pages that blocked automated reading or load only with JavaScript:
Smithsonian, Mixamo's own FAQ (quoted from Adobe's forum), Mixkit,
Textures.com, Poly Pizza's API docs. Roblox's audio quota figures conflict
between its own pages.
