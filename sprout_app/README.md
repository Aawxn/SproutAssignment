# Sprout — A Learning App for Little Explorers 🌱

A Flutter submission for the Sprout developer evaluation. This single-project implementation covers **Task 2** (five screen-only learning activities) and **Task 4** (camera-based object exploration with on-device ML).

---

## What It Does

Six activities for children ages 3–8, all anchored by **Bud** — a round green sprout mascot who blinks, waves, and reacts to everything a child does:

| Activity | Concept | Task |
|---|---|---|
| **Shapes** | Match a prompted shape from 4 options | Task 2 |
| **Count** | Tap floating objects, then pick the right number | Task 2 |
| **Colors** | Identify which circle matches Bud's balloon | Task 2 |
| **ABC 123** | Tap numbered dots in sequence to trace letters | Task 2 |
| **Animals** | Explore 6 animals and hear their sounds (all taps correct) | Task 2 |
| **Explorer** | Point the camera at objects, ML Kit names them | Task 4 |

---

## Design Choices for Ages 3–5

**Tap targets are 80–100dp minimum** — exceeding the standard 48dp guideline. Toddlers' motor control is imprecise; a 64dp target still fails too often.

**No wrong-answer dead-ends.** Every incorrect tap produces a gentle "boing" + Bud says "Try again!" with a bounce animation. Silence or a harsh buzzer reads as broken to a 3-year-old.

**Anticipation before every reward.** Correct answers trigger a squash-and-stretch on Bud (TweenSequence with easeOutBack) before the confetti. This micro-pause creates the emotional payoff that makes children want to repeat the action.

**TTS over pre-recorded clips** (`flutter_tts` at 0.45× speech rate) — slower delivery matches how adults speak to toddlers, and requires zero asset files.

**Pure-exploration mode** (Animal Sounds) — for the youngest users (18m–3yr) who can't yet match or count. Every tap is rewarded, building confidence before structured activities.

---

## Performance on Mid-Range Android (Snapdragon 680-class)

- `RepaintBoundary` wraps the camera preview and Bud mascot so their independent animation loops don't trigger full-tree rebuilds
- `AnimationController` + `AnimatedBuilder` scope rebuilds to only the animated subtree — `setState` is never called at screen root level
- `CustomPainter.shouldRepaint` correctly returns false when values haven't changed
- Camera resolution set to `ResolutionPreset.medium` (640×480) — sufficient for ML Kit inference while keeping frame processing fast
- `const` constructors used throughout static widget subtrees

---

## Privacy & Parental Gate

The Explorer (camera) activity requires an adult-level task before the camera opens — either tapping 3 shapes in exact sequence or holding a button for 5 continuous seconds. Toddlers cannot pass either task reliably. The gate is framed as "Ask a grown-up!" not as friction. All ML inference runs fully on-device via `google_mlkit_image_labeling` — no images or labels leave the device.

---

## If I Had More Time

Next I'd add haptic feedback via `HapticFeedback.lightImpact()` on correct answers (especially valuable for children with hearing impairments), and persist progress and unlock state via `shared_preferences` so Bud "remembers" returning learners and celebrates streaks.
