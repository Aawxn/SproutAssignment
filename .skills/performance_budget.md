# Performance Budget Skill — Mid-Range Android

Target device: mid-range Android (Snapdragon 680-class, 4GB RAM, Android 11+).
Every widget decision must pass this budget.

## Frame Budget
- Target: 60fps (16.67ms per frame)
- Acceptable: 90% of frames under 16ms
- Red flag: any jank during child interaction (even 1 dropped frame during a tap is noticeable)

## Widget Rebuild Rules
### DO
- Use `const` constructors everywhere the widget tree is static.
- Use `Consumer<T>` tightly — wrap only the rebuilding leaf, not the whole screen.
- Use `RepaintBoundary` around:
  - Camera preview widget
  - Complex `CustomPainter` animations (Bud mascot, confetti)
  - Celebration overlay
  - Any widget that animates on its own timer
- Use `AnimatedBuilder` (scopes rebuild to the builder subtree only).
- Use `ListView.builder` / `GridView.builder` for any list > 5 items.

### DON'T
- ❌ `setState` at the root `Scaffold` or screen-level `StatefulWidget`.
- ❌ Bare `Opacity` widget for animation → use `AnimatedOpacity` or `FadeTransition`.
- ❌ `ClipRRect` inside fast animation loops (triggers layer composition every frame).
- ❌ `Image.network` anywhere — use `AssetImage` or generated assets only.
- ❌ `BoxShadow` on fast-animating widgets — cache or remove during animation.
- ❌ Rebuilding `CustomPainter` on every frame unless `shouldRepaint` returns true correctly.
- ❌ Heavy `Stack` depth (> 5 layers) in frequently rebuilt subtrees.

## CustomPainter Rules
```dart
@override
bool shouldRepaint(MyPainter oldDelegate) {
  return oldDelegate.animValue != animValue; // ALWAYS implement this correctly
}
```
- Never return `true` unconditionally from `shouldRepaint`.
- Cache `Paint()` objects as fields, not local variables in `paint()`.

## Memory
- Dispose every `AnimationController` in `dispose()`.
- Dispose every `AudioPlayer` instance in `dispose()`.
- Use `ImageCache` size limit if loading multiple images: `PaintingBinding.instance.imageCache.maximumSize = 50`.
- Release camera resources when screen is backgrounded (`AppLifecycleListener` or `WidgetsBindingObserver`).

## Asset Sizing
- Max image size: 200KB per asset (use WebP format).
- Sound clips: max 100KB per clip (mono, 22kHz, MP3/OGG).
- Total assets budget: < 2MB.

## Build-Time Checks
```bash
# Run before submitting
flutter analyze --fatal-infos
flutter test
flutter build apk --profile  # check for tree-shake warnings
# In DevTools: open Widget Rebuild Tracker, tap through all activities, verify no root-level rebuilds
```

## Profiling Commands
```bash
# Connect to device/emulator, then:
flutter run --profile
# Open: http://localhost:8888 → DevTools → Performance tab
# Record 5 seconds of activity interaction
# Flag any frame > 16ms as a regression to fix
```

## Known Flutter Performance Traps (especially for animations)
1. `Hero` widget with complex children — avoid for this project.
2. `BackdropFilter` (blur) — very expensive on mid-range. Use solid overlays instead.
3. `LinearGradient` inside `AnimatedBuilder` — cache the gradient object.
4. `TextPainter` in `CustomPainter.paint()` — layout text once, cache the result.
5. Multiple `AnimationController`s on one widget — use `AnimationControllerMixin` or consolidate.
