# Staged elemental spell audio

Update: earth descent/impact and ultimate descent/impact now load from `assets/meteor-audio-v3/`. Their older v2 files are retained as history. Other cues, including the ultimate seal, still use this bank.

26 original mixed WAV files: 13 cues × small/full strength, 48 kHz stereo, 16-bit PCM. `manifest.json` records duration, peak and RMS for each file. The reference game recording was used to study event timing; no audio from that recording is included.

The editable source is `tools/make_spell_audio_v2.py`. It combines original filtered noise, low impacts, pitched tones and decay envelopes with the project's existing Kenney CC0 Foley:

- `art/impact-sources/impact/License.txt`: Impact Sounds, Kenney; mining, heavy body, glass and bell recordings.
- `art/impact-sources/rpg/License.txt`: RPG Audio, Kenney; cloth motion.

Runtime events are controlled by `scripts/combat/spell_system.gd`, through the existing WF Impact mix bus. No city music or player volume preference is changed.

| Skill | Cues |
|---|---|
| Fire | Levels 2–10: fire-ignite → fire at the blast hit. Level 1 now uses one complete short cue in `assets/fire-audio-v5/`, with a shared audio/visual endpoint. |
| Wind | wind onset/bounce + sustained wind-loop; contact now uses the user's L1/L10 recordings in `assets/wind-audio-v4/`; loop pauses with menus and stops on reset |
| Earth | fall during each descent → rock on actual impact |
| Ice | One ice impact at each pillar's maximum height (1.15 s); no early seal/rise or separate settle cue. L1 now uses the distinct 冰1.wav in `assets/ice-audio-v8/`; higher levels retain the ice impact in this bank. |
| Ultimate | ultimate-seal → ultimate-fall → ultimate-impact |

Small files have lighter layering and lower level; full files add weight and density. The runtime also scales cue gain and pitch with skill level. Timed descent/rise cues are fitted to the action duration. Runtime voice limits and sound gates prevent repeated rapid contacts from stacking without bounds.

Verification: 26 non-silent files, valid 48 kHz stereo PCM, no clipped samples, and periodic wind-loop joins checked. Combat regression verifies each spell's cue timing, including no early rock crash, ice stages, continuous wind and all three ultimate events. Technical checks do not replace final artistic listening in gameplay.
