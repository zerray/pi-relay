# Data model

## Paired daemon

A paired daemon record contains:

- stable daemon/client pairing identifier
- display name or host label
- daemon base URL
- device bearer token reference stored through secure storage
- selected/current daemon marker

Bearer token values are not kept in presentation state longer than needed for requests.

## Projects and sessions

A project is a daemon-visible workspace. A session belongs to a project and represents one remotely shared Pi TUI session.

Session state includes:

- session ID and project ID
- visibility/closed status
- active turn state
- runtime status
- recent transcript items
- pagination cursor for older messages

Only sessions explicitly activated in the Pi TUI extension are expected to appear remotely.

## Daemon transcript message

The daemon transcript shape is `TranscriptMessage`. It is used by HTTP snapshots, HTTP pages, and WebSocket transcript lifecycle events.

Important fields:

- stable message ID
- role/source
- creation/update timing when provided
- `content` as structured blocks
- `toolCallId`, `toolName`, and `isError` for tool-result messages when provided

Structured content block kinds:

- `text`
- `thinking`
- `toolCall`
- `image`

## UI transcript item

The app normalizes daemon transcript messages into UI-only items optimized for rendering. UI items keep stable IDs derived from daemon message/item IDs and preserve enough daemon metadata to merge stream patches.

UI item kinds include:

- user text
- assistant text
- collapsed thinking
- tool call/status/result
- image
- system/runtime/error notice

Tool calls, tool updates, and tool results are linked by `toolCallId` when available.

## Runtime status

Runtime status is delivered through the session state and `runtime_status` stream events. It can include:

- model
- thinking level
- token usage
- cost
- context usage

The session store treats the newest daemon runtime status as authoritative.

## Compact request state

A compact request starts with `POST /v1/sessions/{sessionId}/compact`, which returns `{ accepted, requestId }`. Completion or failure arrives later as `remote_compact_result` on the session stream and is correlated by `requestId`.

## Transcript state flow

1. Load the session snapshot with a bounded message limit.
2. Normalize snapshot messages into UI items.
3. Connect the session stream.
4. Merge stream events by stable message/item IDs.
5. Prepend older pages from `/messages` when requested.
6. De-duplicate messages/items already present from snapshots, pages, or stream events.

Prompt submissions do not create local optimistic transcript messages.
