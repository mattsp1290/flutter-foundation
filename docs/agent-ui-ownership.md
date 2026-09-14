# Agent UI ownership

`ag_ui_view_state` is pure Dart projection state; `ag_ui_widgets` renders that
bounded state with Material; `birb_ag_ui_widgets` composes only their public
APIs with Birb tokens. Hosts own transport, credentials, authorization,
navigation, controller/focus-node lifetime, drafts, retries, and source access.
Source identifiers are opaque and each open request is delegated back to the
host. None of these packages owns Eino, Genkit, Rook, Benchy, device behavior,
or provider/workspace policy.
