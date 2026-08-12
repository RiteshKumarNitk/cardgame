# Audio

All game audio is **manifest-driven** — the game reads `manifest.json` at
startup, so you can swap in professional sound files **without touching any
code**. There are three ways to change audio:

## 1. Replace a file in place (simplest)

Every sound maps to a file by name. Just overwrite the file and rebuild:

| Sound          | File                          | Played when                                |
| -------------- | ----------------------------- | ------------------------------------------ |
| Tap            | `sfx/tap.wav`                 | Button presses                             |
| Piece snap     | `sfx/piece_snap.wav`          | A tile locks into place                    |
| Victory        | `sfx/victory.wav`             | A puzzle is solved (duck)                  |
| Chapter done   | `sfx/chapter_complete.wav`    | A chapter/section completes (duck)         |
| Coins          | `sfx/coins.wav`               | Coin rewards & shop buys (duck)            |
| Hover          | `sfx/hover.wav`               | Button hover                               |
| Level start    | `sfx/level_start.wav`         | A puzzle starts (duck)                     |
| Tick           | `sfx/tick.wav`                | Coin-flight ticks                          |
| Error          | `sfx/error.wav`               | Invalid actions                            |

## 2. Add a per-screen music track (drop-in convention)

Music is split into **scenes** — each screen has a scene, and the game looks
for a matching track automatically. Currently every scene uses the same
`music/bgm_loop.wav`. To give a screen its own ambience, drop a file named
after the scene into `music/` and **rebuild** — no code or manifest edits:

| Scene          | Auto-picked file                        | Screen(s)                    |
| -------------- | --------------------------------------- | ---------------------------- |
| `home`         | `music/home.wav`                        | Home hub                     |
| `levels`       | `music/levels.wav`                      | Journey map, collections     |
| `puzzle`       | `music/puzzle.wav`                      | Level + photo + daily puzzles|
| `shop`         | `music/shop.wav`                        | Shop, cosmetics              |
| `gallery`      | `music/gallery.wav`                     | Gallery                      |
| `victory`      | `music/victory.wav`                     | Victory & chapter screens    |
| `default`      | `music/bgm_loop.wav`                    | Fallback everywhere          |

Tracks are WAV (or MP3/OGG — audioplayers supports them). The game fades
between tracks when you move between scenes.

## 3. Manifest overrides (explicit control)

`manifest.json` lets you point any sound or scene at any asset path — useful
if you keep master files in a different folder. Edit the JSON, rebuild, done.

```json
{
  "sfx": { "tap": "audio/sfx/tap.wav" },
  "music": { "home": "audio/music/home_loop.wav" },
  "duck": { "enabled": true, "level": 0.25, "recoveryMs": 400 }
}
```

## Ducking

Music automatically **ducks** (drops to `duck.level` × its volume) for
`duck.recoveryMs` when a big sound plays (victory, coins, level start,
chapter complete) so SFX never gets buried, then fades back. Tune it in
`manifest.json`, or set `enabled` to `false` to turn it off.

## Volume mixing

Players control three volume channels in Settings: **Master**, **Sound
Effects**, and **Music** (0–100% each). Effective volumes are multiplied
together (`SFX = master × sfx`, `Music = master × music`), and all live
adjustments apply instantly to whatever is playing.
