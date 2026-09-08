# Character performance and combat feel

Implemented 2026-09-06 in the playable city/instance game. City layout, quests, gear and skill balance remain under their existing systems. The review modes never load or save the player's profile.

## Character

The current character pipeline, frame counts, shared city camera, upright long staff, and static NPC behavior are documented in [Character Production](Character%20Production.md). The following character paragraphs retain the earlier v2 revision history; the contact-response and audio sections still describe the underlying combat systems.

The player now uses the rebuilt mesh in `mage_sculpt.gd`, integrated through `expressive_rig.gd`; see [Mage Model v2](Mage%20Model%20v2.md) for the model revision and actual before/after. The articulated skeleton retains gaze changes, asymmetric posture and cloth follow-through. Casting uses anticipation, release at frame 3/7, overshoot and recovery. The released projectile follows this same 180 ms marker for a 420 ms basic attack. Elemental casting speed shortens both the performance and release delay.

The mage has eight-direction idle, walk, attack, seal, hurt, death, combat-ready, moving cast, start, stop and dodge atlases. Start is a prepared clip; runtime locomotion currently enters the walk cycle directly. Moving cast is a dedicated combined clip, not a full independent upper/lower-body skeletal blend. Goblin and mentor have six eight-direction actions. The studio now loads the same new assets as gameplay.

23 active sheets contain 1,472 frames. Regular cells are 256 px with ground origin (128,218); mage attack and moving cast use 320 px cells and (160,250) for the wand's reach; death cells are 384 px with ground origin (192,282). All retain the same pixels per model unit. No character is horizontally mirrored. `actor.gd` has a virtual clip loader so the new actor does not also load the previous generation of atlases.

## Contact response

| Hit | Victim-only hitstop | Normal enemy hitstun | Recoil distance |
|---|---:|---:|---:|
| Basic bolt | 38 ms | 100 ms | 6 units |
| Fire | 52 ms | 160 ms | 10 units |
| Wind | 25 ms | 65 ms | 4 units |
| Earth | 75 ms | 260 ms | 18 units |
| Ice | 42 ms | 140 ms | 5 units |
| Rage meteor | 110 ms | 420 ms | 28 units |

Critical hits increase the pause, recoil, contact flash and number punch. Enemy movement and windup are blocked during true hitstun; spell freeze remains a separate state. A recovery grace period prevents repeated hits from indefinitely restarting the reaction. Bosses accumulate poise damage to 100, then stagger for 280 ms with a 1.45 s grace period. Their recoil is reduced to 12%. Elite normal enemies retain shorter reactions.

Recoil uses exponential velocity integration and the game's existing collision substeps. Local hitstop does not change Engine.time_scale or pause the player's ranged movement. Multiple simultaneous victims merge into the strongest camera impulse rather than adding global freezes. A 120 ms basic-attack buffer accepts input near the end of cooldown. Dodging cancels an unreleased cast; entering town cancels all pending casts.

The impact star is drawn at the target's body height, synchronized with actual damage, sound, pose and number. Corpses fall and settle before fading. The damage pipeline, rage rules and expedition skill damage formulas remain intact.

## Audio

36 mixed stereo effects: three distinct variants each for physical, fire, wind, earth, ice, critical, meteor, death, launch, dodge, stone steps and grass steps. Kenney's CC0 Impact Sounds and RPG Audio provide the contact/cloth/stone material; original synthesized textures provide the elemental and low-frequency layers. Source licenses are in `art/impact-sources`.

- https://kenney.nl/assets/impact-sounds
- https://kenney.nl/assets/rpg-audio

Files are 48 kHz PCM with attack and tail shaping, DC removal and headroom. Runtime uses 16 spatial voices, non-repeating variants, a 65 ms gate for dense identical hits, priority-based voice replacement and a dedicated limiter. Crits and the rage meteor briefly lower the current ambience by 3 dB. Existing city music and elemental casting sound libraries remain separate.

## Verification and preview

- `--wf-feel-test`: real projectile release, damage contact, walking cast, hitstop, hitstun, collision-safe recoil, boss poise/grace, dense audio/impulse limits, death and city isolation.
- `--wf-combat-test`: existing element, expedition, cards, damage, rage, profile and boss regressions; includes the new release delay.
- `tools/verify.py`: existing city/quest/teleport/save smoke checks.
- `tools/verify_performance.py`: every frame has a complete transparent silhouette; all eight walk frames differ; all sound files have an onset, distinct PCM and headroom.
- `--wf-feel-review`: reproducible in-engine performance/impact demonstration, with real sound. Delivered video: `preview/combat-feel.mp4`.

Latest model revision verification: all 29 feel checks and the elemental/expedition regression passed, including actual player/portrait atlas paths and moving-cast origin. A previous independent whole-scene smoke run reported three city navigation checks: the route to the garden and clear arrivals at the garden/gate waystones. City layout is being edited separately and is outside this change; those results are not a current city certification. The review recording logs resource cleanup warnings at process exit; no script errors occurred in the final combat checks. See the saved verification logs rather than treating the whole scene as fully green.

Current character rebuilds use `tools/bake_world_characters.gd` with the shared Forward+ renderer, followed by reimport. `bake_performance.gd` is the older v2 exporter and does not produce the currently loaded world-motion assets.
