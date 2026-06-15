# Task 1 — Five-Minute Engagement Loop: "Bud's Shape Safari"

## The Activity

**Shape Safari** is a guided exploration game where children (ages 3–5) help Bud — a friendly animated sprout mascot — find shapes hidden in a colorful meadow. Each round presents a target shape (circle, square, triangle, star, heart) and four large tap targets. The child taps the matching shape; Bud reacts with delight.

A full loop runs **4 rounds** (~75 seconds each), naturally filling 5 minutes with built-in pacing:

| Phase | Duration | What happens |
|-------|----------|-------------|
| **Arrival** | ~10 s | Bud waves, blinks, says "Hi! I'm Bud!" — child already smiling |
| **Prompt** | ~5 s | Bud asks "Can you find the ▲ triangle?" — anticipation builds |
| **Search & Tap** | ~15 s | Child scans 4 shapes, taps one. Wrong → gentle wobble + "Try again!" |
| **Celebration** | ~8 s | Correct → squash-stretch bounce, Bud cheers, progress dot fills |
| **Transition** | ~3 s | Short pause, new shapes shuffle in with stagger animation |
| **Final reward** | ~15 s | After round 4: star-burst particles, "You found all the shapes! 🎉" |

**Total per loop: ~4.5–5.5 minutes** (self-paced — faster kids finish sooner, slower kids never feel rushed).

---

## Why a 3-Year-Old Would Enjoy This

### 1. Bud is a friend, not a teacher
Bud has two dot eyes that blink, a wobbly idle animation, and reacts to *every* tap — correct or wrong. A 3-year-old doesn't distinguish "app" from "character." Bud *is* the experience. When Bud celebrates, the child celebrates. When Bud encourages ("Hmm, try again! 🌱"), there's no failure — just a friend helping.

### 2. The loop matches toddler attention rhythm
Developmental research (Ruff & Capozzoli, 2003) shows 3-year-olds sustain focused attention in **30–90 second bursts**, then need a micro-break. Shape Safari's round length (≈75 s) fits this window precisely. The transition animation between rounds *is* the break — passive, visually interesting, requires no input.

### 3. Predictable structure with variable content
Toddlers crave predictability but bore with repetition. The loop structure never changes (prompt → search → celebrate), but the shapes, colors, and positions shuffle every round. This is the "same but different" pattern that keeps young children engaged — like re-reading a favorite book but with new pictures.

### 4. Every tap produces a response
Zero dead zones. Tap the right shape → Bud jumps + "Yay!" Tap wrong → shapes wobble + "Try again!" Tap Bud himself → he giggles. The app never ignores a child's input, which is critical at an age where cause-and-effect is still magical.

### 5. Difficulty auto-adjusts
Rounds 1–2 use high-contrast, easily distinguishable shapes (circle vs. square). Rounds 3–4 introduce more similar pairs (star vs. heart). No settings menu, no difficulty selector — the progression is invisible to the child.

---

## What Happens When Time Runs Out

**Time doesn't "run out" — the loop completes.** There is no visible timer, no countdown, no urgency cues. This is deliberate:

1. **After round 4**, the celebration overlay triggers: particle burst animation, Bud dancing, three gold stars, and the message "You found all the shapes! 🎉"
2. The overlay auto-dismisses after 3 seconds, revealing a **"Play Again! 🌱"** button
3. Tapping "Play Again" resets the loop with fresh shape combinations — Bud waves again as if greeting a returning friend
4. **If the child walks away**: the app idles on the celebration screen. No nagging, no "come back!" prompts. The session data (4/4 rounds, X correct on first try) is saved locally for a future parent dashboard
5. **If a parent intervenes** (e.g., "time for dinner"): the back button exits cleanly to the home screen. No "are you sure?" dialogs — a 3-year-old can't read them, and they'd frustrate the parent

### Design rationale for no timer:
Visible timers create anxiety in young children and pressure in parents. A 5-minute loop that *feels* like play (not a timed test) is more likely to be repeated voluntarily — which is the real engagement metric for a children's app.

---

## Sketch

```
┌─────────────────────────────┐
│  ←  [back]          ⭐ 2   │  ← score badge
│                             │
│         (◉ ◉)               │  ← Bud (animated eyes)
│          \_/                │
│         /|||\ ← wobble      │
│                             │
│  ┌─ Find the ▲ triangle ─┐ │  ← prompt bubble
│  └────────────────────────┘ │
│                             │
│   ┌────┐      ┌────┐       │
│   │ ●  │      │ ▲  │ ← tap │  ← 2×2 shape grid
│   └────┘      └────┘       │
│   ┌────┐      ┌────┐       │
│   │ ■  │      │ ★  │       │
│   └────┘      └────┘       │
│                             │
│     ●──●──○──○              │  ← progress dots (2/4)
└─────────────────────────────┘
```
