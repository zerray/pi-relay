# Title

Use pi-remote-control as the only remote-control boundary

# Status

Accepted

# Context

Remote clients must control Pi sessions without embedding Pi SDK or RPC behavior. The host-side `pi-remote-control` package already owns pairing, authentication, session registry, TUI integration, and the allowlisted remote operations.

# Decision

Pi Relay communicates only with the `pi-remote-control` daemon over its authenticated HTTP and WebSocket API. It does not talk directly to Pi SDK, Pi RPC internals, or terminal sessions.

# Consequences

The daemon remains the trust, pairing, and session-control boundary. Pi Relay stores daemon connection metadata and bearer tokens, renders daemon-provided session state, and sends only daemon-supported remote operations.
