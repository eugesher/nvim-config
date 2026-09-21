# CLAUDE.md

Guidance for Claude Code in this repository: the source of a Neovim 0.12
configuration for NestJS backend work. `nvim/` is the configuration itself;
`install.sh` copies it to `~/.config/nvim`. README.md explains usage — this file
explains how the code is organized and which decisions must not be "fixed".

## Commands

```bash
./install.sh                                          # back up ~/.config/nvim, copy nvim/ there, create codebook.toml
nvim                                                  # first start: lazy.nvim installs plugins, Mason installs servers
stylua --check nvim/                                  # or: npx --yes @johnnymorganz/stylua-bin --check nvim/
nvim --headless -l scripts/audit-keymaps.lua          # keymap audit, must exit 0
nvim --headless -l scripts/dump-keymaps.lua --write   # regenerate the key tables in KEYMAP.md
nvim --headless -c 'lua print(vim.inspect(require("lazy").stats()))' -c qa
```

Inside Neovim: `:Lazy` (`:Lazy sync` updates plugins), `:Mason`,
`:checkhealth myconfig`, `:messages`.

- `:Lazy sync` rewrites `~/.config/nvim/lazy-lock.json`, the installed copy.
  Copy the file back to `nvim/lazy-lock.json` when an update is meant to stay.
- Both keymap scripts read the installed config (`stdpath("config")`), not the
  checkout: run `./install.sh` first.
- `mason-lspconfig`'s `ensure_installed` does nothing in `--headless` runs; a
  server installation can only be observed in a real (or pty) session.

## Ground rules

- Git is the user's job: never create branches, commit, push or tag.
- `install.sh` changes only when a task asks for it. `http/` lives outside
  `nvim/` on purpose and is never copied.
- Target Neovim 0.12+ APIs; no compatibility code for older versions.
- Format Lua with stylua (`nvim/stylua.toml`: 2 spaces, width 100).
- `nvim/lazy-lock.json` is part of the config: never delete it or ignore it.

## Architecture

| Path | Holds |
| --- | --- |
| `lua/core/` | Neovim itself without plugins: options, keymaps, autocmds, diagnostics, the annotations drawn above a line, filetypes, the lazy.nvim bootstrap |
| `lua/plugins/*.lua` | **Thin** lazy.nvim specs: repository, `dependencies`, `build`, `version` / `branch` / `commit`. Never `opts` or `keys` |
| `lua/settings/<group>/<name>.lua` | **Everything** a plugin is configured with, one file per plugin; `<group>` is the `lua/plugins/<group>.lua` file that declares it. Only `init.lua` (the spec glue) and `icons.lua` (glyphs) sit at the top of `lua/settings/` |
| `lua/settings/lsp/` | `lspconfig.lua` (server list, `<leader>l` keys), `mason.lua`, `capabilities.lua`, `keymaps.lua` (the only LspAttach), `unused.lua` (reference counts behind the unused markers), `servers/<name>.lua` |
| `lua/user/settings.lua` | The single source of user-tunable values — pure data, no `vim.*` calls |
| `lua/myconfig/health.lua` | `:checkhealth myconfig` |
| `after/ftplugin/*.lua` | Buffer-local keymaps and filetype specifics (http, sql) |

A spec is built with `require("settings").spec(repo, name, extra)`, where `name`
is `"<group>.<name>"` (`"ui.theme"`). The settings module
`settings/<group>/<name>.lua` returns any of `enabled`, `cond`, `event`, `ft`,
`cmd`, `keys`, `opts`, `init`, `config`, `priority`, `lazy`, `which_key`; those
fields go into the lazy.nvim spec, anything else is ignored. Modules use that to
export helpers other code reads (`M.groups` in whichkey/whichkey,
`M.server_path` in dap/dap, `M.servers` in lsp/lspconfig, `M.extra_tools` in
lsp/mason).

`:checkhealth myconfig` lives under `lua/myconfig/` because checkhealth finds
`lua/<name>/health.lua`; a `core/health.lua` would add a second, duplicate
`:checkhealth core` report.

### Writing settings

- **Options explicitly, defaults included — but only documented ones** (README,
  `:help`, or the config file the plugin's docs name as the reference). Never dig
  out undocumented internal fields.
- No explanatory comments in code: Lua, shell scripts and the scripts in `.http`
  files. An explanation that matters goes to README.md ("Implementation notes");
  the reason for a keymap audit exception goes to KEYMAP.md ("Audit exceptions").
  Two kinds of comments stay: tool directives (`---@diagnostic` for lua_ls) and
  commented-out code the user keeps (`settings/ui/theme.lua`).
- Values a user may want to change go into `lua/user/settings.lua` and are read
  from there, never hard-coded in a settings file.
- Highlights go into `custom_highlights` in `settings/ui/theme.lua` (never
  `color_overrides`), colors from the catppuccin palette.
- `user.colorscheme.enabled = false` must leave Neovim's default colorscheme and
  every plugin's own colors. Color code outside `settings/ui/theme.lua` goes
  through its helpers (`palette()`, `lualine_theme()`, `bufferline_highlights()`,
  `neo_tree_handlers()`), which return the plugin default in that case. Never
  `require("catppuccin…")` elsewhere: the spec switches with `cond` (the plugin
  stays installed and locked), and lazy.nvim errors on requiring a plugin whose
  `cond` is false.
- Glyphs come from `settings/icons.lua` only (Nerd Fonts v3, no padding).
- A new panel filetype has to be added to every exclusion list: `PANELS` in
  `settings/session/autosession.lua`, `EXCLUDED_FILETYPES` in
  `settings/structure/dropbar.lua`, `disable.ft` in `settings/whichkey/whichkey.lua`,
  `panels` in `settings/ui/lualine.lua`, `ft_ignore` in `settings/ui/statuscol.lua`,
  and the lists in
  `settings/treesitter/treesitter-context.lua` and `settings/ui/indent.lua`.
  Bottom panels use `user.ui.panel_height`.

## Keymaps

- `leader` is `<Space>`, `localleader` is `\`. Classic Vim: no GUI combos
  (`<C-c>` / `<C-v>` / `<C-s>` as copy / paste / save), nothing on Alt except
  `<A-j>` / `<A-k>` (move lines).
- Neovim's LSP keys stay (`K`, `grn`, `gra`, `grr`, `gri`, `grt`, `gO`, `<C-s>`
  in insert); ours are aliases. `grn`, `gri`, `grr`, `grt` are deliberately
  repointed on LspAttach (inc-rename, fzf-lua pickers, Trouble).
- Never map `]n` / `[n`, `an` / `in` (Neovim 0.12 treesitter selection) or
  `]c` / `[c` (diff mode).
- Every keymap has a `desc`, written next to its plugin (`keys` or the module's
  `which_key` field). `settings/whichkey/whichkey.lua` declares groups only.
  Neovim's fold commands are no keymaps: their extra which-key descriptions sit
  in the `which_key` field of `settings/structure/origami.lua`, and KEYMAP.md
  lists them by hand under "Folds" — keep both in step. neogit's buffer keys
  get their descriptions from `settings/git/neogit.lua`, keyed by the action
  names of its `opts.mappings`: a new action there needs one.
- After changing keys run `scripts/audit-keymaps.lua`. A deliberate duplicate or
  collision goes into its whitelist, with the reason under "Audit exceptions" in
  KEYMAP.md; then regenerate the tables there (`dump-keymaps.lua --write`).

| Prefix | Group | Prefix | Group |
| --- | --- | --- | --- |
| `<leader>b` | Buffers | `<leader>o` / `O` | Outline (aerial) |
| `<leader>c` | Code (LSP) | `<leader>q` / `Q` | Close buffer / quit all |
| `<leader>d` | Debug (DAP) | `<leader>r` | Refactor |
| `<leader>D` | Database | `<leader>s` | Session |
| `<leader>e` / `E` | Explorer | `<leader>t` | Test (`tc` coverage) |
| `<leader>f` | Find (fzf-lua) | `<leader>u` | UI toggles |
| `<leader>g` | Git (`gh` hunks, `gt` toggles, `gx` conflicts) | `<leader>w` | Write |
| `<leader>h` | HTTP (only in .http / .rest buffers) | `<leader>x` | Problems (trouble) |
| `<leader>l` | LSP / tooling meta | `<leader>1..9` | bufferline buffers |
| `<leader>m` | Multicursor | `<leader>;` | dropbar pick |
| `<leader>a` | Restart Neovim | `<leader>gL` | **free** |

## Non-obvious decisions

These look like mistakes or omissions and are not. Change them only on request.

- **The database is on `<leader>D`, not `<leader>db`.** `<leader>d` is the
  debugger group and `<leader>db` toggles a breakpoint; database keys under it
  would make that key wait for 'timeoutlen' and mix two groups in which-key.
- **`<leader>a` is `:restart!`, with the bang.** Plain `:restart` saves and
  restores a session of its own, beside the one auto-session writes on exit and
  restores on start; the bang leaves sessions to auto-session alone.
- **`g:db_ui_execute_on_save = 0`.** Saving a query buffer must never run it —
  `:w` in the wrong buffer is the classic way to execute a query against
  production. Queries run with `<localleader>x` / `<localleader>X` only.
- **`db_ui`, sessions and `codebook.toml` live outside `~/.config/nvim`.**
  `install.sh` replaces that directory wholesale. Connections and saved queries
  are in `stdpath("data")/db_ui`, sessions in `stdpath("state")/sessions`, the
  dictionary in `~/.config/codebook/codebook.toml` (created by `install.sh` only
  when missing). `:checkhealth myconfig` reports an error if one of them ends up
  inside `stdpath("config")`.
- **yamlls is limited to `yaml` and `yaml.docker-compose`.** nvim-lspconfig's
  default list adds `yaml.gitlab` / `yaml.helm-values`, filetypes Neovim never
  produces, which `:checkhealth vim.lsp` flags. Compose files keep yamlls: it is
  the only server validating them against the Compose schema, since
  docker-language-server reports YAML syntax errors only. In compose buffers
  yamlls' rename is hidden, so `<leader>cr` reaches docker-language-server.
- **kulala `global_keymaps = false`.** HTTP keys are buffer-local in `.http` /
  `.rest` buffers (`after/ftplugin/http.lua`), so the `<leader>h` group stays
  empty and hidden everywhere else.
- **neotest `discovery = { enabled = false }`.** Automatic discovery walks the
  whole workspace and freezes the editor in a NestJS monorepo; the test tree is
  built from the files opened and the tests run.
- **No telescope, lazygit, AI plugins or cspell.**
  - fzf-lua is the only picker and also serves `vim.ui.select`.
    `telescope-fzf-native.nvim` is installed solely as the C fzf library dropbar's
    menu filter needs; telescope itself is not.
  - Git works inside the editor through neogit, diffview.nvim and gitsigns
    (lazygit, vim-fugitive and snacks.nvim were rejected; `<leader>gL` stays free).
  - AI integration is left out by design, so nothing else draws ghost text.
  - Spelling is codebook, a language server; cspell.nvim is archived and
    cspell-lsp deprecated. `scripts/cspell-to-codebook.sh` migrates an old word
    list.
- **blink.cmp is pinned to `1.*`.** v2 is under heavy development, breaks the
  config and needs the separate blink.lib package; the tag also selects the
  prebuilt fuzzy-matcher binary.
- **diffview `disable_diagnostics = true` in every view.** LSP floods conflict
  markers and historical file versions with errors.
- **nvim-treesitter is on the `main` branch** (textobjects too). It is a
  different plugin from the old `master`: it installs parsers and queries (built
  with tree-sitter-cli) and nothing more. `configs.setup{ highlight, indent }`
  does not exist; `settings/treesitter/treesitter.lua` starts highlighting, folds
  and indent per buffer, and incremental selection is Neovim's own.

Further decisions, explained in README.md ("Implementation notes"):

- aerial loads on `BufReadPost` with LSP first, so `{` / `}` jump by symbol and
  class fields show up.
- dropbar's treesitter `valid_types` is narrowed to declarations. Its preview
  `reorient` uses `winrestview`, because `:normal` breaks the fuzzy prompt. The
  breadcrumbs are drawn at the bottom, by lualine's left section, not in the
  winbar: `bar.enable` is `false` and `M.statusline()` in
  `settings/structure/dropbar.lua` hands lualine dropbar's own string, while the
  git and diagnostic counters sit in `lualine_x`. Its `symbol.on_click` wraps
  the default one to raise the first menu to the bottom of the window.
- `<leader>w` writes every named buffer in a loop, not with `:wall`, which
  errors on a buffer that has no file name.
- nvim-autopairs keeps its `<CR>` mapping: blink.cmp owns the key and falls
  back to it while the completion menu is closed.
- bufferline's tab numbers come from a `numbers` function counting the
  rendered order; its own `ordinal` is the position in the buffer list.
- neo-tree's tree keys are `h` / `l` based (`l` open, `h` close, `.` hidden
  files, `H` / `J` / `K` / `L` preview). `<cr>` (a function: open a file, set
  the root on a folder) and `.` (toggle_hidden) sit in the source tables, not
  the global one: those commands do not exist in every source. A key is
  removed with `"none"`, never by dropping its line.
- `safe_buffer_delete` in `settings/ui/bufferline.lua` deletes a buffer a
  session restored (listed, not loaded) with `nvim_buf_delete`: bufdelete.nvim
  skips an unloaded buffer. `<leader>ba` deletes every listed buffer in one
  bufdelete call, which leaves the empty buffer `<leader>q` leaves last.
- deleting a path in an explorer closes the buffers under it: neither neo-tree
  nor oil does that for a directory, so `delete_buffers_under` in
  `settings/ui/bufferline.lua` is called from neo-tree's `file_deleted` event
  and from oil's `User OilActionsPost`. `rename_buffers_under`, on neo-tree's
  `file_renamed` and `file_moved`, does the same for the buffers a rename left
  behind: neo-tree renames the loaded ones only. oil deletes an unloaded buffer
  instead of renaming it when a file moves, so `OilActionsPre` loads those
  first (`load_buffers_under`) and lets oil rename them.
- every diagnostic and every `Unused symbol` marker is drawn at the end of its
  line by `core/annotations.lua` (`virt_text_pos = "eol"`, four columns behind
  the code), one extmark per line so the order holds (errors first, the marker
  last); an `Unused symbol` marker adds `○` left of the line number through that
  same extmark, in `UnusedSign` and with priority 11, above a hint and below a
  warning, so a diagnostic sign keeps the one cell statuscol gives it;
  `core/diagnostics.lua` enables the renderer as the `myconfig/annotations`
  handler and keeps `virtual_text` and `virtual_lines` off. A diagnostic source
  listed in `lsp.diagnostics_summary.sources` is the exception: its messages
  become one block above the first line of the buffer, the only annotation still
  drawn in virtual lines — `label` with the number of distinct words, the words
  themselves wrapped at `width` columns, then `hint` in
  `AnnotationHint`. Words are compared in lower case and shown as first met.
  The key of the setting is the `source` field of the diagnostic, not the
  server name.
- unused code carries two different marks: `DiagnosticUnnecessary` for what the
  compiler proves unused, `settings/lsp/unused.lua`'s `Unused symbol '…'.` for a
  declaration no code references (`lsp.unused_skip`: `fields` keeps DTO and
  entity fields out, `methods` controller methods, `paths` whole files —
  node_modules). Both are warnings: `core/diagnostics.lua` wraps the two
  diagnostic handlers and raises a hint tagged `Unnecessary` to a warning
  before Neovim stores it, `core/annotations.lua` draws it in `UnusedSymbol`,
  and `UnusedSymbol` links to `DiagnosticVirtualTextWarn`. A symbol with no name
  to reference is not counted: what tsserver names `…) callback`, `<class>` or
  `<function>`. A method counts in a class or an interface only, never in an
  object literal, and an enum member never counts, only the enum itself. The
  marker never doubles such a diagnostic: `core/annotations.lua` drops it, and
  its sign, for those columns. vtsls' reference code lens is off — Neovim
  re-requests a lens vtsls leaves unresolved, which it does for every symbol
  with no references.
- codebook's project dictionary is `.codebook/words.toml`
  (`spelling.project_dictionary`), handed to the server as an absolute path in
  `params.initializationOptions.configPath` from `before_init` — a relative one
  follows the working directory, and `config.init_options` is copied into the
  request before the callback runs. `<leader>cw` adds every unknown word of the
  buffer in one `codebook.addWord`, and codebook's messages are summarized in
  that block rather than drawn over the code. `settings/lsp/spelling.lua` covers
  what the server skips (`spelling.check_paths`): a string literal holding a `/`
  is never checked, so it sends codebook a shadow document — the buffer with
  those slashes turned into spaces, under a URI of its own — and republishes the
  hints only that copy produced into the `myconfig.spelling` namespace, with
  codebook's `source`, so they join the same block.
- `grr` opens Trouble, not a picker.
- `d` / `D` / `c` / `C` / `s` / `S` delete into the black hole register (`expr`
  keymaps in `core/keymaps.lua` that keep an explicit named register); only
  `x` / `X` cut to the clipboard.
- `<Tab>` / `<S-Tab>` in blink.cmp move through the completion menu first and
  jump through snippet fields only while the menu is closed; `<Esc>` closes the
  menu before it leaves insert mode.
- trouble's `symbols` mode is unused: aerial owns the structure view.
- codebook has `exit_timeout = 500`, since it never exits on its own.
- lualine's LSP progress follows work-done tokens from `LspProgress` event data;
  `ev.match` and `vim.lsp.status()` left finished tasks in the status line.
- nvim-origami's `useLspFoldsWithTreesitterFallback` is off: `update_folds()` in
  `settings/treesitter/treesitter.lua` picks LSP or treesitter folds, so a file
  above `treesitter.max_filesize` never gets `vim.lsp.foldexpr()`, which freezes
  Neovim there.
- `<leader>fp` and `<leader>cR` were removed as duplicates of `<leader>li` and
  `<leader>lr`.
