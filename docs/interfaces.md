# Interfaces

Pi Relay integrates with `pi-remote-control` only. All endpoints except pair claim require:

```http
Authorization: Bearer <device-token>
```

## Pairing

- Input: `pi-remote://pair?...` pairing link.
- Claim: `POST /v1/pair/claim`.
- Output: daemon metadata and a device bearer token stored by the secure-store layer.

## HTTP API

- `GET /v1/health` — daemon health check.
- `GET /v1/projects` — visible projects.
- `GET /v1/projects/{projectId}/sessions` — sessions for a project.
- `GET /v1/sessions/{sessionId}?messageLimit={limit}` — bounded session snapshot.
- `GET /v1/sessions/{sessionId}/messages?before={cursor}&limit={limit}` — older transcript page.
- `POST /v1/sessions/{sessionId}/prompt` — submit a prompt.
- `POST /v1/sessions/{sessionId}/abort` — abort the active turn.
- `POST /v1/sessions/{sessionId}/compact` — request compaction and return `{ accepted, requestId }`.

Prompt submission does not create an optimistic transcript row. The composer may show local submitting state while waiting for the daemon response and later stream/snapshot updates.

## WebSocket API

- `GET /v1/sessions/{sessionId}/stream` — live session stream.

Known event types:

- `session_state`
- `turn_start`
- `turn_end`
- `transcript_message_start`
- `transcript_message_patch`
- `transcript_message_end`
- `tool_execution_start`
- `tool_execution_update`
- `tool_execution_end`
- `runtime_status`
- `remote_compact_result`
- `session_closed`
- `error`

The initial WebSocket `session_state` contains at most recent messages and can include truncated previews for oversized payloads. HTTP snapshot and pagination endpoints are used for fuller history loading.
