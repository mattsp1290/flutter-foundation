# Birb AG-UI widgets

`birb_ag_ui_widgets` provides `BirbAgentConversation`, a thin, controlled
composition of the public AG-UI widget APIs and Birb design-system tokens.

The host supplies the immutable state, a borrowed text controller and focus
node, and every action callback. It retains ownership of transport, retries,
source authorization, and lifecycle. This package does not publish to pub.dev;
consumers pin an immutable Git commit and use the root workspace lockfile only.
