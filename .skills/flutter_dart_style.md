# Flutter / Dart Style Skill

## State Management
- Use **Provider** exclusively for this project. No Riverpod, no Bloc.
- Each screen has one `ChangeNotifier` in `providers/`. Keep it thin — only state, no UI logic.
- `Consumer<T>` wraps only the smallest subtree that needs rebuilding — never the whole screen.
- Use `context.read<T>()` for one-shot calls (button taps), `context.watch<T>()` only inside `Consumer`.

## Animation
- Always use `AnimationController` + `CurvedAnimation`. Never use `Future.delayed` as a substitute.
- Preferred curves: `easeOutBack`, `elasticOut` for bouncy feedback; `easeInOut` for transitions.
- Every `AnimationController` is disposed in `dispose()` — no exceptions.
- Use `AnimatedBuilder` to scope rebuilds to the animated widget only.
- Prefer `TweenSequence` for multi-step animations (anticipation → payoff).
- Use `vsync: this` only when the widget mixes in `SingleTickerProviderStateMixin` or `TickerProviderStateMixin`.

## Widget Conventions
- `const` constructors everywhere possible — lint with `prefer_const_constructors`.
- Named parameters only for widgets with > 2 params.
- `RepaintBoundary` wraps: camera preview, complex CustomPainter animations, celebration overlays.
- Never use bare `Opacity` widget for animation — use `AnimatedOpacity` or `FadeTransition`.
- Avoid `setState` at the screen root level. Push state into Provider or a local `StatefulWidget` leaf.

## File Structure
```
lib/
  main.dart               # MaterialApp + routes + Provider setup
  theme/
    sprout_theme.dart     # ThemeData, color constants, text styles
  widgets/
    mascot/bud_mascot.dart
    reward/celebration_overlay.dart
    common/sprout_button.dart
  providers/
    activity_provider.dart
  screens/
    task2/
    task4/
  services/
    audio_service.dart
    ml_label_service.dart
assets/
  sounds/
  images/
```

## Naming
- Files: `snake_case.dart`
- Classes: `PascalCase`
- Private variables: `_camelCase`
- Constants: `kCamelCase` (e.g., `kSproutGreen`)

## pubspec.yaml rules
- Always pin major versions: `provider: ^6.0.0`
- Declare all asset folders explicitly (not `assets/` as a catch-all)
- Add `uses-material-design: true`
