# Sprout — A Learning App for Little Explorers 🌱

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter&style=flat-rounded)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-green?style=flat-rounded)](#)
[![Privacy](https://img.shields.io/badge/Privacy-COPPA%20%26%20GDPR--K%20Compliant-brightgreen?style=flat-rounded)](#)
[![Tests](https://img.shields.io/badge/Tests-Passing-success?style=flat-rounded)](test/activity_provider_test.dart)

A premium, interactive learning app prototype for toddlers (**ages 3–5**), built as a developer submission for Sprout. This repository is structured as a **root-level Flutter project** featuring high-quality animations, custom sound effects, on-device machine learning, haptic feedback, and a dedicated parental gate.

---

## 🎨 Interactive Micro-Games (Task 2 & 4)

Sprout features **six micro-games** focused on toddler cognitive development. Every activity is guided by **Bud**, a friendly animated sprout mascot who blinks, reacts, and celebrates alongside the child.

| Activity | Developmental Goal | Interaction Style | Task Reference |
|---|---|---|---|
| **Shapes** | Spatial & shape recognition | Tap matching shape from 4 options | Task 2 |
| **Count** | Early counting & math | Tap floating fruits to count, pick correct number | Task 2 |
| **Colors** | Color matching & visual sorting | Identify matching circle color for Bud's balloon | Task 2 |
| **ABC 123** | Motor skills & symbol familiarity | Tap sequence of numbered dots to trace letters | Task 2 |
| **Animals** | Audio-visual association | Tap animals to hear custom sounds (all taps correct) | Task 2 (Youngest) |
| **Explorer** | Curiosity & real-world connection | Camera exploration; ML Kit labels objects | Task 4 |

---

## 🧸 Toddler-First UX Checklist (Ages 3–5)

To transition this from a "tech demo" into a beloved product, we implemented the following toddler-centric design choices:

### 1. Zero "Dead Zones" & Forgiving Feedback
* Every tap on the screen produces a response. Tapping Bud triggers a wiggle and giggle.
* No red X's or harsh buzzers. Wrong answers trigger a soft, cartoonish "boing" sound and Bud encourages with a gentle wiggle and a spoken *"Hmm, try again! 🌱"*.

### 2. High-Quality Sound Library (New Asset Synthesis)
* Replaced raw sine-wave synthesis with a custom-synthesized sound library saved directly in the asset bundle.
* Sounds (pop, chime, soft slide, fanfare) were designed mathematically to be warm, acoustic, and child-appropriate.

### 3. Tactile Haptic Feedback
* Centralized haptics inside [audio_service.dart](lib/services/audio_service.dart) synchronized with game sounds:
  * **Standard taps:** Gentle `HapticFeedback.lightImpact()` (immediate tactile response).
  * **Correct matches / Gate success:** `HapticFeedback.mediumImpact()`.
  * **Incorrect taps:** A soft double haptic nudge to guide the child.
  * **Completion celebration:** A cascading haptic sequence mirroring the melody notes.

### 4. Continuous Mascot Animation (Bud Mascot)
* Bud is animated using multiple synced controllers inside [bud_mascot.dart](lib/widgets/mascot/bud_mascot.dart):
  * **Blink Loop:** Blinks periodically every 2–4 seconds.
  * **Idle Breathing & Sway:** A slow (2.8s) loop that sways Bud side-to-side and performs an area-preserving breathing scale, ensuring he feels "alive" even when the child pauses.
  * **Reactions:** Wiggles, jumps, and waves on correct, incorrect, and thinking states.

### 5. Adaptive Voice Assistance (Hesitation Nudges)
* Integrated a 7-second hesitation detector inside the activities.
* If a child stops interacting or feels lost for more than 7 seconds, Bud automatically speaks a helpful, slow-paced hint (e.g. *"Can you find the star?"* or *"Tap each apple to count them!"*) to guide them back to play.

---

## 🔒 Safety by Design (COPPA & GDPR-K)

### Double Parental Gate
Before the camera or the Parent Zone dashboard can activate, the app presents a safety gate in [parental_gate_screen.dart](lib/screens/task4/parental_gate_screen.dart):
1. **Sequence Task:** Tapping 3 shapes in a specific randomized order.
2. **Hold Task:** Holding a designated button for 5 continuous seconds.
*Toddlers cannot sustain 5-second presses or follow precise sequence cards, preventing accidental settings tweaks or camera activations.*

### On-Device Machine Learning (Task 4)
The **Explorer Activity** uses the device camera to identify real-world objects.
* **100% Offline:** Inference is processed fully on-device via `google_mlkit_image_labeling`. No images, audio, or labels ever leave the device.
* **Child-Friendly Filtering:** In [ml_label_service.dart](lib/services/ml_label_service.dart), we filter ML Kit categories using a strict whitelist (`dog`, `cat`, `flower`, `book`, `hand`, `face`, `cup`, `chair`). Boring developer/office objects (keyboards, laptops, cables) are ignored.

### 📊 Grown-Ups Dashboard (Parent Zone)
Accessible via the Parental Gate from the home screen, the **Grown-Ups Dashboard** ([parent_dashboard_screen.dart](lib/screens/parent_dashboard_screen.dart)) enables parents to:
* **Track progress metrics:** View total stars earned and completion status for all 6 learning micro-games.
* **Customize accessibility preferences:** Toggle Voice Narration/Sound Effects and Tactile Haptics dynamically (linked to `AudioService` settings checks).
* **Usability Testing Notes (JD A.2 / C.2):** Enter and save real-time observational notes during play sessions with their child, supporting fast iteration loops.
* **Danger Zone:** Reset all stored progress and feedback logs cleanly via `StorageService.instance.clearAll()`.

---

## 🛠️ Technical Implementation & Clean Architecture

### Performance Optimization
* **Repaint Boundaries:** Wrapped the camera preview and Bud Mascot in `RepaintBoundary` nodes. This scopes layout and paint passes so mascot/preview animations do not trigger expensive full-tree rebuilds.
* **Pre-warmed Player Pool:** Spawns and pre-allocates 4 `AudioPlayer` instances on startup to ensure sound effects fire in under 50ms (zero-latency target).
* **Responsive Layouts:** Handled UI scaling using `LayoutBuilder` constraints and clamping logic (e.g., in [counting_screen.dart](lib/screens/task2/counting_screen.dart#L335-L373) button sizes are restricted to `(width / 4).clamp(64, 100)`). The app is completely overflow-proof on small devices (e.g., iPhone SE) and scales beautifully to tablets.

### Reliable Testing (JD Requirement B.4)
* Integrated standard widget smoke tests at `test/widget_test.dart`.
* Created dedicated unit tests at `test/activity_provider_test.dart` to cover the provider state management (score tracking, attempt progression, and time calculations).
* **Analysis:** Passes `flutter analyze` with `0 issues`.

---

## 📊 Drop-Off Problem Diagnosis (Task 3 Summary)

For a detailed look at our response to: *"Kids leave after 2 minutes. What do we do?"*, read [task3_dropoff_diagnosis.md](docs/task3_dropoff_diagnosis.md).

* **Investigate:** Cohort tracking (screen entries, average taps, audio latency) and usability tests with 5 children.
* **Build / Test:** Add surprise elements (background color shifts, Bud doing a flip) at the 90-second mark to combat attention decay, or reduce grid sizes from 4 to 2 items if children disengage due to difficulty.
* **Measure:** Primary target is moving median session length from 2m → 4m within one release cycle.

---

## 🚀 Getting Started

### Prerequisites
* Flutter SDK (3.0.0+)
* Android SDK (API 24+) or iOS SDK (12.0+)

### Running the App
1. Clone this repository:
   ```bash
   git clone https://github.com/Aawxn/SproutAssignment.git
   cd SproutAssignment
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on your connected device/emulator:
   ```bash
   flutter run
   ```
4. Run tests:
   ```bash
   flutter test
   ```

---

*Designed and prototyped by pair programming with Antigravity.*
