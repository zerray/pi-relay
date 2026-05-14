# Architecture

Pi Relay is a Flutter client for Android, macOS, Windows, and Linux. It talks only to a paired `pi-remote-control` daemon over authenticated HTTP and WebSocket connections.

## Module boundaries

```text
lib/
  app/                 # composition root, routing, theme
  presentation/        # screens and widgets
  application/         # stores, controllers, use cases
  domain/              # daemon-facing models and transcript reducer state
  infrastructure/
    remote_client/     # HTTP/WebSocket daemon client
    secure_store/      # token, base URL, and device metadata persistence
    pairing/           # pi-remote://pair parsing and claim flow
```

## Responsibilities

- `app` wires dependencies, app-wide theme, and navigation.
- `presentation` renders pairing, project/session lists, transcript views, composer state, runtime status, and compact/abort controls.
- `application` owns selected daemon/session state, loading flows, prompt submission state, compact request tracking, and stream lifecycle.
- `domain` defines daemon models, app-only transcript rows, reducer inputs, and merge/de-duplication rules.
- `infrastructure/remote_client` implements daemon HTTP requests and session WebSocket streams.
- `infrastructure/secure_store` persists paired daemon records and bearer tokens.
- `infrastructure/pairing` parses pairing links and claims pair codes against the daemon.

## Runtime flow

1. A user adds a daemon through a `pi-remote://pair?...` link or pasted pairing URL.
2. The pairing flow claims the code with `POST /v1/pair/claim` and stores the returned daemon metadata and bearer token.
3. Project and session screens fetch daemon state through authenticated HTTP endpoints.
4. Opening a session loads a bounded HTTP snapshot, then connects to the session WebSocket.
5. The session store applies stream events through the transcript reducer and updates runtime/session state.
6. Prompt, abort, and compact actions are sent to the daemon. Submitted prompts are not appended locally; user messages appear only from daemon snapshots or stream events.

## Stream handling

The WebSocket is authoritative for live session changes. The client merges `session_state`, transcript lifecycle events, tool events, runtime status, compact results, and session closure into local state. Repeated messages or items are de-duplicated by stable IDs.

## Security boundary

The daemon authenticates remote clients with per-device bearer tokens. Pi Relay stores these tokens through the secure-store layer and sends them only to the paired daemon base URL.
