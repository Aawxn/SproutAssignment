# Child UX Checklist Skill (Ages 3–8)

Apply ALL of the following non-negotiables to every screen, widget, and interaction.
These are not suggestions — they are the evaluation bar.

## 1. ONE CHARACTER / MASCOT — "Bud"
- Every screen shows **Bud** (the animated green sprout creature).
- Bud has 5 named reaction states: `idle | happy | thinking | celebrating | encouraging`
- Bud reacts to EVERY meaningful child action (tap, correct, incorrect, completion).
- Bud blinks on a looping timer (every 2–4 seconds) even when idle.
- Bud's expression change must be animated (never a hard swap) — use crossfade or tween.

## 2. ANTICIPATION + PAYOFF
- Before any reward animation: add a 150–300ms "build-up" (squash, wiggle, pitch rise).
- Use `TweenSequence` pattern:
  ```dart
  TweenSequence([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 30), // squash
    TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.2), weight: 40), // overshoot
    TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 30),  // settle
  ])
  ```
- The payoff (confetti, star burst, Bud dance) must be visually larger than the build-up.
- Never skip anticipation for "correct answer" moments — even in wrong-answer recovery.

## 3. FORGIVING INTERACTIONS
- **No dead-ends.** A wrong tap ALWAYS produces SOME positive output.
- Wrong tap response: gentle "boing" sound + target wobbles + Bud says "Hmm, try again! 🌱"
- Never show a red X or a harsh "WRONG" label.
- "Try again!" text appears in a friendly rounded bubble, bounces in with `elasticOut`.
- After 2 wrong attempts on same item, Bud gives a visual hint (points at the correct answer).

## 4. SOUND DESIGN
- **Silence = broken** to a 3-year-old. Every state change has audio.
- Required sounds:
  - `tap_ack`: immediate (< 50ms latency), short pop (plays on every valid tap)
  - `correct`: two-note ascending ding (plays before celebration animation)
  - `try_again`: soft descending boing (NOT a buzzer — keep it gentle)
  - `celebrate`: 4-note ascending melody
  - `idle_bud`: occasional gentle chirp from Bud every ~10s
- Use `AudioService` singleton with pre-loaded players (no latency on first play).
- Volume default: 0.7 (not max — respect family environments).

## 5. MOTOR-SKILL REALISM
- **Minimum tap target: 80×80dp** (spec says 64dp; use 80dp to exceed spec).
- Use `GestureDetector` wrapping `SizedBox(width: 80, height: 80, ...)` at minimum.
- For drag tasks: use `onPanUpdate` NOT `onPanStart` → child can start dragging anywhere.
- **Zero double-taps anywhere** in the app.
- **Zero drag-to-select** gestures — use single tap for all selection tasks.
- Spacing between tap targets: minimum 16dp gap.

## 6. PARENTAL GATE (Task 4 only)
- Trigger: before ANY camera access.
- Frame it as: "Ask a grown-up to help open the camera! 🌱"
- Adult task options (pick one):
  - Tap 3 shapes in exact displayed order (e.g., star → square → circle)
  - Hold a button for 5 continuous seconds (progress bar shows)
- Child cannot pass: the motor/cognitive pattern is designed for adults.
- On pass: camera opens with a short celebration (Bud cheers).
- On fail: gentle reset, Bud says "Let's ask a grown-up!" — no penalty.

## 7. ANALYTICS STUBS
Add these COMMENTED hooks at exact trigger points:
```dart
// analytics.logEvent('activity_started', {'activity': activityName});
// analytics.logEvent('item_tapped', {'correct': isCorrect, 'attempt': attemptCount});
// analytics.logEvent('activity_completed', {'duration_seconds': elapsed, 'score': score});
// analytics.logEvent('reward_shown', {'activity': activityName});
// analytics.logEvent('parental_gate_passed');
// analytics.logEvent('parental_gate_shown');
```

## Checklist (verify before shipping each screen)
- [ ] Bud is visible and reacting
- [ ] All tap targets ≥ 80dp
- [ ] Wrong answer gives positive feedback (never silence/X)
- [ ] At least one anticipation moment before reward
- [ ] Sound plays on every key interaction
- [ ] No double-taps, no complex drag gestures
- [ ] Analytics stubs commented at: start, tap, complete, reward
