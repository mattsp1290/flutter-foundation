# Agent UI provenance

The F1/F2 transfer baseline is
`eino-session-client-flutter@85edce9de577b7864c9bab58a57b5eb2403561fe`.
Transferred paths are `packages/ag_ui_view_state`, `packages/ag_ui_widgets`,
and `examples/generic_ag_ui`. Package metadata was normalized for this Pub
workspace: member lockfiles and sibling paths were not transferred. The Go
fixture route was deliberately replaced with `tool/generic_fixture_server.dart`;
Foundation owns only this generic Dart POST/SSE verifier.

`birb_ag_ui_widgets` and `examples/benchy_contract` are Foundation-authored
thin composition/consumer fixtures. The transfer retains the source license
material in each transferred package and preserves the initial public barrels.
The boundary audit rejects private cross-package imports, local paths,
overrides, member lockfiles, and runtime host-name leakage.

Static fixtures remain byte-for-byte copies: `generic.sse`
SHA-256 `6008c2207c68ee3f750a5e9db67b548f2ea03335148d4eb724b6ff1938796dc3`;
`privacy.sse` SHA-256
`ee7c141ba29d8cc49cd86c5e64d7e812ecb58ba25ea73faf38f93d5934638371`.
`tool/verify_agent_fixtures.dart` verifies this closed inventory and its hashes.
