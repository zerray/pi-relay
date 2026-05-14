# Pi Relay

Pi Relay is a Flutter client for remotely viewing and controlling explicitly shared Pi coding-agent sessions through `pi-remote-control`.

## Run

Requires Flutter. Generate platform shells when needed, then run the app:

```sh
flutter create --platforms android,macos,windows,linux --project-name pi_relay .
flutter pub get
flutter run
```

Run checks:

```sh
flutter analyze
flutter test
```

## Directory overview

- `lib/` — Flutter application source.
- `test/` — Flutter widget tests.
- `docs/architecture.md` — application architecture and module boundaries.
- `docs/interfaces.md` — daemon API and integration contracts.
- `docs/data-model.md` — core client data structures and state flows.
- `docs/adr/` — accepted architecture decision records.
