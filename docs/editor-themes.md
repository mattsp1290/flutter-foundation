# Editor theme provenance

Editor presets are reusable public API in birb_design_system. They affect only
the editor and are independent of Material light/dark mode. Source is never
rewritten by a theme change. Foundation uses the ambient semantic palette.

Dracula colors come from the official MIT-licensed
[VS Code theme](https://github.com/dracula/visual-studio-code/blob/master/src/dracula.yml).
The selected core colors are background 282a36, foreground f8f8f2, keywords
ff79c6, strings f1fa8c and numbers bd93f9. For readable small text, comments and
gutter use the upstream purple bd93f9 instead of its lower-contrast 6272a4.
Selection uses upstream dark surface 343746 to keep highlighted tokens readable.
This is an accessibility adaptation of Dracula, not exact VS Code rendering.

GitHub Light/Dark use classic source colors from the official MIT-licensed
[GitHub VS Code theme](https://github.com/primer/github-vscode-theme), its
[src/theme.js](https://github.com/primer/github-vscode-theme/blob/main/src/theme.js)
and Primer primitives. These are small editor-only palettes, not a complete
workbench-theme port. Syntax classifications are the shared editor's Go lexer.

Full upstream notices are retained in [Dracula license](licenses/dracula.txt)
and [GitHub theme license](licenses/github-vscode-theme.txt). Values were
verified on 2026-09-27. DESIGN.md section 11 scopes the audit exception to the
single private birb_code_palette.dart file. Other runtime color construction
remains forbidden.
