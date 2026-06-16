# Task 3 — Diagnosing a Drop-Off Problem

> "Kids leave after 2 minutes." No data, no designer, one week.

## Investigate First (Day 1–2)

- **Session-record 5 real kids** (screen + face cam, with parental consent). Watch *where* they disengage — is it a specific screen, a loading gap, a confusing prompt, or plain boredom after the novelty wears off?
- **Instrument the build**: add lightweight event logging (screen_enter, tap, scroll, back_pressed, app_backgrounded) with timestamps. Ship to 50 internal/beta testers. Plot a **survival curve** — does the drop happen at a consistent timestamp (e.g., 90 s) or a consistent *screen*?
- **Check the audio path**: on slow devices, TTS init can block for 2–3 s. If the mascot goes silent mid-activity, kids assume the app is "done." Verify audio fires within 300 ms of every interaction.

## Build or Test (Day 3–5)

- **If drop is at a specific screen**: redesign that screen's feedback loop — add anticipation animation before the reward, shorten dead time between rounds, ensure *every* tap produces a response (zero ignored inputs).
- **If drop is time-based** (always ~2 min regardless of screen): the likely cause is **escalation failure** — the experience doesn't get more interesting. A/B test adding a "surprise" mechanic at the 90-second mark (new character appears, background changes color, a mini-celebration triggers).
- **If drop correlates with wrong answers**: the difficulty curve is too steep. Reduce options from 4 to 2 for the first 3 rounds; add progressive hints (correct answer subtly pulses after 5 s of inaction).

## Measure Success

- **Primary metric**: median session duration moves from 2 min → 4 min within one release cycle.
- **Secondary**: % of sessions completing at least one full activity loop (currently likely <30%, target >60%).
- **Qualitative**: in follow-up recordings, kids *ask to play again* unprompted.
