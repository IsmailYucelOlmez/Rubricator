# Dev run with compile-time env (same as VS Code launch.json).
# Plain `flutter run` does NOT load assets/.env — Env uses dart-defines only.
flutter run --dart-define-from-file=env.development.json @args
