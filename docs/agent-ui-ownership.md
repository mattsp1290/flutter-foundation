# Agent UI ownership

`ag_ui_view_state` is pure-Dart, bounded projection state. `ag_ui_widgets`
renders that immutable state under an ordinary Material theme.
`birb_ag_ui_widgets` composes only the two public AG-UI barrels and public Birb
design-system APIs; it has no reducer, transport, codec, or copied host DTO.

Hosts own request identity, transport, credentials, authorization, navigation,
draft and controller/focus-node lifetime, retries, appearance initialization,
and source access. Source identifiers are opaque and every open request is
delegated to the host. A chat stop is a run-stop intent only: it cannot invoke a
host's distinct persistent/global action. The packages never auto-resubmit or
invent a completed run after a callback returns.

The generic fixture is local and deterministic. The Benchy-shaped fixture is a
synthetic consumer contract, not production adoption or hardware proof. None
of the runtime packages owns Eino, Genkit, Rook, Benchy, device behavior, auth,
or application/workspace policy.
