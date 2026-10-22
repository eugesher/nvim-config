# Neovim Configuration — NestJS Backend Development

An IDE-grade Neovim configuration for backend development on NestJS: TypeScript,
RabbitMQ, MySQL/TypeORM and API-gateway services. It bundles LSP, debugging,
tests, database and HTTP clients into a single keyboard-driven workflow.

## Environment requirements

### Required

| Dependency                      | Why                                                                                                                                                                   | Install                                                                                                                          |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Neovim 0.12+**                | Core editor; the config uses 0.12 APIs throughout                                                                                                                     | `sudo snap install nvim --classic`                                                                                               |
| **Git 2.36+**                   | Plugin management, gitsigns, lazygit; `git worktree list -z` (lazygit's config check) needs 2.36+                                                                     | `sudo apt install git`                                                                                                           |
| **lazygit**                     | The git interface behind `<leader>gg`, in a float of this config                                                                                                      | `sudo apt install lazygit`                                                                                                       |
| **Node.js 20+** and npm         | TS/JS language servers, prettierd, sql-formatter, js-debug-adapter, tree-sitter-cli                                                                                   | [nodejs.org](https://nodejs.org), or via `fnm` / `nvm`                                                                           |
| **tree-sitter-cli ≥ 0.26.1**    | The `main` branch of nvim-treesitter builds parsers with it                                                                                                           | `npm install -g tree-sitter-cli`                                                                                                 |
| **build-essential** (gcc, make) | Builds LuaSnip's `jsregexp`, treesitter parsers and telescope-fzf-native.nvim — the C fzf library behind the filter in dropbar's menus (telescope itself is not used) | `sudo apt install build-essential`                                                                                               |
| **curl**                        | Downloads by Mason and by kulala for its backend                                                                                                                      | `sudo apt install curl`                                                                                                          |
| **ripgrep**                     | Live grep in fzf-lua                                                                                                                                                  | `sudo apt install ripgrep`                                                                                                       |
| **fd-find**                     | File traversal in fzf-lua (ships as `fdfind`, needs an `fd` symlink)                                                                                                  | `sudo apt install fd-find`                                                                                                       |
| **fzf > 0.36**                  | Picker engine behind fzf-lua                                                                                                                                          | `sudo apt install fzf`                                                                                                           |
| **A Nerd Font** (v3)            | Icons in the file tree, status line, pickers and breadcrumbs                                                                                                          | [nerdfonts.com](https://www.nerdfonts.com/) — select it in your terminal; `ui.nerd_font` in `lua/user/settings.lua` records that |
| **wl-clipboard** or **xclip**   | System clipboard integration                                                                                                                                          | `sudo apt install wl-clipboard`                                                                                                  |

### Optional — per feature

| Dependency                        | What it enables                                                                                                                                                                                                                                                                                                                                                   |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **inotify-tools** (`inotifywait`) | Fast file watching for language servers (vtsls, ESLint). Without it Neovim on Linux falls back to a slower per-directory watcher                                                                                                                                                                                                                                  |
| **mysql-client**                  | MySQL database client for vim-dadbod                                                                                                                                                                                                                                                                                                                              |
| **redis-tools** (`redis-cli`)     | One-off `:DB redis://…` commands and interactive Redis work in a separate terminal window                                                                                                                                                                                                                                                                         |
| **kulala-core**                   | The engine behind the HTTP client: kulala 6.x runs every request through it. kulala downloads it into `~/.local/share/nvim/kulala.nvim/bin` (~100 MB) only while `http.kulala_core_sha256` is `nil`; with the pin set, only a binary with that SHA-256 runs                                                                                                       |
| **jq**                            | Pretty-printing JSON responses in kulala                                                                                                                                                                                                                                                                                                                          |
| **libxml2-utils** (`xmllint`)     | Pretty-printing XML responses in kulala                                                                                                                                                                                                                                                                                                                           |
| **bat**                           | Syntax highlighting in picker previews (ships as `batcat`, needs a `bat` symlink)                                                                                                                                                                                                                                                                                 |
| **git-delta**                     | Syntax highlighting for git diffs in picker previews                                                                                                                                                                                                                                                                                                              |

### Installed automatically via `:Mason`

`vtsls`, `eslint-lsp`, `lua-language-server`, `json-lsp`, `yaml-language-server`,
`docker-language-server`, `dockerfile-language-server`, `codebook`,
`bash-language-server`, `prettierd`, `prettier`, `stylua`, `js-debug-adapter`,
`sql-formatter`.

## Installation

1. **Prepare the environment.** Install the required dependencies above. On
   Debian/Ubuntu `fd` and `bat` are installed under different binary names, so
   create the symlinks the config expects, and install the Tree-sitter CLI:

   ```bash
   mkdir -p ~/.local/bin
   ln -s "$(command -v fdfind)" ~/.local/bin/fd
   ln -s "$(command -v batcat)" ~/.local/bin/bat
   npm install -g tree-sitter-cli
   ```

2. **Install the configuration.** The script checks for Neovim 0.12+, backs an
   existing `~/.config/nvim` up to `~/.config/nvim.backup.<timestamp>`, copies
   `nvim/` into its place and creates `~/.config/codebook/codebook.toml` unless it
   already exists:

   ```bash
   ./install.sh
   ```

3. **Start Neovim once.** lazy.nvim installs the plugins at the commits pinned in
   `nvim/lazy-lock.json`, nvim-treesitter builds the parsers, and Mason installs
   the language servers and tools in the background. Wait until `:Mason` lists
   every package as installed.

   ```bash
   nvim
   ```

4. **Check the result** with `:checkhealth myconfig`. It covers Neovim itself,
   the required and optional tools (with their versions), Mason packages,
   treesitter parsers, the files kept across reinstalls, the font and the debug
   adapter. A missing optional tool is a warning with its install command; an
   error is something the config cannot work without.

Running `./install.sh` again replaces `~/.config/nvim` and nothing else. What
has to survive lives outside it: the codebook dictionary in
`~/.config/codebook/`, vim-dadbod-ui connections and saved queries in
`~/.local/share/nvim/db_ui/`, sessions in `~/.local/state/nvim/sessions/`, and
the `http/` collections in this repository.

## What's inside

| Area                    | Tooling                                                                                                                                                                      |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Plugin manager          | lazy.nvim, versions pinned by `nvim/lazy-lock.json`                                                                                                                          |
| Colorscheme and UI      | catppuccin, lualine, bufferline, which-key, indent-blankline, nvim-web-devicons, statuscol.nvim (diagnostics and git signs on either side of the line numbers)               |
| LSP                     | Neovim's client with nvim-lspconfig: vtsls, ESLint, lua_ls, jsonls (+ SchemaStore), yamlls, bashls, docker-language-server, dockerls; Mason and mason-lspconfig install them |
| Completion and snippets | blink.cmp, LuaSnip, friendly-snippets, nvim-autopairs                                                                                                                        |
| Formatting              | conform.nvim with prettierd / prettier, stylua and sql-formatter                                                                                                             |
| Treesitter              | nvim-treesitter (`main`), nvim-treesitter-textobjects, nvim-treesitter-context                                                                                               |
| Picker                  | fzf-lua, also behind `vim.ui.select`                                                                                                                                         |
| Files                   | neo-tree (project tree), oil.nvim (directory as an editable buffer)                                                                                                          |
| Code structure          | aerial (symbol tree), dropbar (breadcrumbs in the status line), nvim-origami (fold line counts, auto-folded imports and comments)                                            |
| Git                     | gitsigns, lazygit (in a float of its own), diffview.nvim, git-conflict.nvim                                                                                                  |
| Database                | vim-dadbod, vim-dadbod-ui, vim-dadbod-completion                                                                                                                             |
| HTTP client             | kulala.nvim                                                                                                                                                                  |
| Debugging               | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, js-debug-adapter                                                                                                             |
| Tests and coverage      | neotest (jest, vitest adapters), nvim-coverage                                                                                                                               |
| Problems                | trouble.nvim, todo-comments.nvim                                                                                                                                             |
| Refactoring             | inc-rename.nvim, refactoring.nvim, multicursor.nvim                                                                                                                          |
| Sessions                | auto-session                                                                                                                                                                 |
| Spelling                | codebook — a language server                                                                                                                                                 |
| Markdown                | render-markdown.nvim (headings, tables, callouts drawn in the buffer)                                                                                                        |

## Configuration structure

```
nvim/
├── init.lua              # leaders, version guard, vim.loader, then core and lazy.nvim
├── lazy-lock.json        # exact plugin commits — part of the config
├── stylua.toml           # formatting of every Lua file (2 spaces, width 100)
├── lazygit.yml           # lazygit settings added on top of your own
├── lua/
│   ├── core/             # the editor itself, no plugins: options, keymaps,
│   │                     # autocmds, diagnostics, filetypes, lazy.nvim
│   │                     # bootstrap, the lazygit float, project trust
│   ├── plugins/          # thin lazy.nvim specs, one file per area
│   ├── settings/         # the configuration of every plugin
│   │   ├── init.lua      # settings.spec(): a lazy.nvim spec from a settings module
│   │   ├── icons.lua     # every glyph of the config
│   │   ├── <group>/      # one folder per plugins/<group>.lua, one file per plugin:
│   │   │                 # completion/blink.lua, dap/dap.lua, ui/theme.lua, …
│   │   └── lsp/          # lspconfig.lua (server list), mason.lua, capabilities,
│   │                     # LspAttach keymaps, servers/<name>.lua per language server
│   ├── user/settings.lua # the values meant to be changed (next section)
│   └── myconfig/health.lua  # :checkhealth myconfig
└── after/ftplugin/       # buffer-local keymaps and options per filetype
```

The layers never mix:

- **`lua/plugins/`** only says _which_ plugin: repository, dependencies, build
  step, branch or version. Each spec is built with
  `require("settings").spec("folke/trouble.nvim", "problems.trouble")`, where
  `problems` is the name of the plugins file the spec sits in.
- **`lua/settings/<group>/<name>.lua`** says _how_: it returns any of `enabled`,
  `cond`, `event`, `ft`, `cmd`, `keys`, `opts`, `init`, `config`, `priority`,
  `lazy` and `which_key`. `settings.spec()` hands those to lazy.nvim and ignores
  everything else, so a module may also export helpers. Everything a plugin is
  configured with lives there — options, keymaps with their descriptions;
  highlights are the one exception and sit in `settings/ui/theme.lua`. Options
  are written out in full, defaults included, but only the documented ones.
  `which_key` describes keymaps a plugin creates itself, or Neovim commands that
  belong to it (the fold `z` keys in `structure/origami.lua`); which-key groups
  are declared only in `settings/whichkey/whichkey.lua`.
- **`lua/core/`** holds what Neovim does without any plugin.
- **`after/ftplugin/`** holds keymaps and options that belong to one filetype.

Code files carry no explanatory comments — only tool directives and
commented-out code kept for later. What would otherwise be explained next to the
code is collected in [Implementation notes](#implementation-notes).

## Customization

`nvim/lua/user/settings.lua` is the single place meant for personal values —
plain data the rest of the config reads:

| Setting                                                      | Effect                                                                                                                                                                                   |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `editor.indent_width`                                        | width of one indent step: `'shiftwidth'`, `'tabstop'`, `'softtabstop'`                                                                                                                   |
| `editor.scrolloff`                                           | lines kept above and below the cursor                                                                                                                                                    |
| `editor.relative_number`                                     | `true`: numbers relative to the cursor (the current line keeps its absolute number); `false`: absolute numbers                                                                           |
| `editor.readonly_dirs`                                       | files inside a directory with one of these names, at any depth, open with `'readonly'` and `'nomodifiable'`: no edits, no saves; `{}` turns it off                                       |
| `ui.border`                                                  | border of every floating window (`'winborder'`): `none`, `single`, `double`, `rounded`, `solid`, `shadow`, `bold`                                                                        |
| `ui.panel_height`                                            | height in lines of the bottom panels — Trouble, debugger, test output — which share one split                                                                                            |
| `ui.nerd_font`                                               | the terminal uses a Nerd Font v3; Neovim cannot see the font, so `:checkhealth myconfig` trusts this flag — set `false` without one                                                      |
| `ui.title`                                                   | text in the terminal's window and tab title (`'titlestring'`); `%{}` holds a Vim expression, and `fnamemodify(getcwd(), ':t')` is the name of the current directory                      |
| `colorscheme.enabled`                                        | `false` drops catppuccin and every color tweak of the config: Neovim's default colorscheme, each plugin with its own colors, the other `colorscheme.*` values ignored                    |
| `colorscheme.flavour`                                        | catppuccin flavor: latte, frappe, macchiato, mocha                                                                                                                                       |
| `colorscheme.transparent`                                    | let the terminal background show through the editor surfaces instead of `window_bg`                                                                                                      |
| `colorscheme.transparent_floats`                             | the same for floating windows: which-key, pickers, hover docs; the completion menu follows `transparent`                                                                                 |
| `colorscheme.window_bg`                                      | base background of windows, panels and floats                                                                                                                                            |
| `treesitter.max_filesize`, `max_line_length`                 | buffers larger than this many bytes, or with a longer line, get no treesitter highlighting or indentation, and no treesitter or LSP folds (manual folds only)                            |
| `folding.auto_fold_kinds`                                    | LSP fold kinds closed when a file is opened: `comment`, `imports`, `region`; `{}` turns auto-folding off                                                                                 |
| `formatting.format_on_save`                                  | format on save; toggle with `<leader>uf` (buffer) / `<leader>uF` (global) or `:FormatDisable[!]` / `:FormatEnable[!]`                                                                    |
| `formatting.timeout_ms`, `max_filesize`                      | milliseconds a formatter may block a save; files larger than `max_filesize` bytes are saved unformatted                                                                                  |
| `formatting.sql_dialect`                                     | `sql-formatter` dialect for `.sql` buffers and MySQL queries in dadbod: `mysql`, `mariadb`, `postgresql`, `sqlite`, `tsql`, `plsql` and more; a `.sql-formatter.json` in the project wins over it                    |
| `explorer.position`, `width`, `min_width`, `hide_gitignored` | neo-tree panel on the `"left"` or `"right"`; `width` is columns or a share of the editor width (`"25%"`) taken at each open, never below `min_width` columns; `.` shows gitignored files |
| `explorer.group_empty_dirs`                                  | `true` merges a folder whose only child is a folder into one row (`src/app/modules`), so the first `l` on it merges instead of expanding; `false` keeps every folder on its own line     |
| `git.lazygit_scale`                                          | size of the lazygit window, a fraction of the editor: `1` fills the screen without a border, `0.9` leaves a margin and keeps `ui.border`                                                 |
| `finder.fullscreen`                                          | fzf-lua pickers (`<leader>f…`, `<leader>g…`, `vim.ui.select`) fill the whole editor; `false` gives them a centered float of 80 % × 85 %; `<F2>` toggles it inside a picker               |
| `http.default_env`                                           | kulala environment on startup, a key of `http/http-client.env.json` (`<leader>he` switches)                                                                                              |
| `http.kulala_core_sha256`                                    | SHA-256 of the kulala-core binary allowed to run; `nil` lets kulala download a new one (then `sha256sum` it and pin again)                                                               |
| `trust.git_timeout_ms`                                       | milliseconds the project trust check gives git; when git is slower, project code stays off and a notice names this setting                                                               |
| `mason.registry`                                             | release tag of the Mason registry the packages are resolved from (`github:mason-org/mason-registry@<tag>`); `nil` follows the latest                                                     |
| `mason.servers`, `tools`                                     | the Mason version of every language server and tool, installed as `name@version`; `:checkhealth myconfig` warns on a different one                                                       |
| `spelling.project_dictionary`                                | path of the project dictionary, relative to the project root; `<leader>cw` and `Add to dictionary` write it, `""` leaves codebook to find `codebook.toml` itself                         |
| `spelling.check_paths`                                       | check the words of a string that holds a path (`src/usr/x`) — codebook skips such a string whole; `false` leaves spelling to the server alone                                            |
| `spelling.scan_timeout`                                      | milliseconds `<leader>xs` waits for codebook to answer one file before it moves on without it                                                                                            |
| `spelling.scan_parallel`                                     | files `<leader>xs` keeps open in codebook at once                                                                                                                                        |
| `coverage.command`                                           | command that writes `coverage/lcov.info`, run by `:CoverageRun` from a trusted directory holding a `package.json` (see the trust section); shows only a rewritten report                 |
| `database.position`, `width`                                 | vim-dadbod-ui drawer on the `"left"` or `"right"`, width in columns                                                                                                                      |
| `lsp.inlay_hints`                                            | inlay hints on attach; `<leader>ui` toggles per buffer                                                                                                                                   |
| `lsp.disable_watchers`                                       | stop advertising file watching: less CPU for ESLint and TypeScript servers in huge monorepos, but files changed outside the editor go unnoticed                                          |
| `lsp.import_style`                                           | auto-import paths (`importModuleSpecifier`): `shortest` takes a `tsconfig.json` path alias only where it is shorter; `relative`, `non-relative`, `project-relative` force one form       |
| `lsp.unused_symbols`                                         | write `Unused symbol '…'.` behind the line of a declaration nothing references in the project and `○` left of its number; `<leader>uu` hides the markers in the current buffer           |
| `lsp.unused_skip`                                            | globs of the places where a declaration is never counted: `fields` for class fields (`*`, every file), `methods` for controller methods, `paths` for whole files (node_modules)          |
| `lsp.diagnostics_summary`                                    | `sources` maps a diagnostic `source` to the `label` and `hint` of its block above the first line; `width` wraps the word list, `0` never wraps; `sources = {}` turns it off              |

Edit the file in the repository and run `./install.sh` again — an edit made in
`~/.config/nvim` is lost on the next reinstall.

## Key bindings

`<leader>?` in the editor lists the keys of the current buffer and `<leader>K`
all of them, Neovim's own commands included. Every key of the configuration,
with the scripts that keep the scheme consistent, is listed in
[KEYMAP.md](KEYMAP.md).

## Databases

**No credentials live in this repository.** Connections added with
`:DBUIAddConnection` (`<leader>Da`) and saved queries are stored in
`~/.local/share/nvim/db_ui/` — outside the repository and outside
`~/.config/nvim`, so `install.sh` never touches them. `<leader>Du` opens the
drawer in a tab of its own; the key or `q` in the drawer closes that tab again,
and `<leader>Df` finds the current buffer in its drawer. `<C-j>` in the drawer
goes to the query results.

- **MySQL passwords go to `~/.my.cnf`, not into the URL.** A password in the URL
  ends up in plain text in `connections.json`, and the MySQL 8+ client prints
  "Using a password on the command line interface can be insecure" into every
  result. Keep it in the client option file (`chmod 600 ~/.my.cnf`):

  ```ini
  [client]
  user=app
  password=secret
  ```

  and add the connection without it: `mysql://app@127.0.0.1:3306/app_db`.

- **`127.0.0.1`, not `localhost`**, for a server in Docker: with `localhost` the
  MySQL client ignores the port and connects to the local Unix socket.
- Connections can also come from the environment: `DBUI_URL` (+ `DBUI_NAME`),
  or one variable per connection, `DB_UI_<NAME>=mysql://…`. A connection is
  keyed by its name and its source, and the sources are not deduplicated: one
  left in both `connections.json` and `DBUI_URL` shows up twice in the drawer,
  so the file becomes `[]` when a connection moves to the environment. Without
  `DBUI_NAME` the name is the last segment of the URL, and saved queries live
  in `<save location>/<name>`, so a renamed connection stops finding them.
- **A Redis password goes to `REDISCLI_AUTH`, not into the URL.** dadbod hands a
  password from the URL to `redis-cli` as `-a`, which warns "Using a password on
  the command line interface may not be safe" into every result. Export the
  variable instead and leave the URL bare.
- **Redis** has no browser in the drawer. One-off commands go through `:DB`, and
  the result opens in a buffer: `:DB redis://127.0.0.1:6379 KEYS user:*`,
  `:DB redis://127.0.0.1:6379 TTL session:abc`. Interactive work happens in
  `redis-cli` in a separate terminal window.

## HTTP client

Request collections live in `http/` at the repository root, outside `nvim/`, so
`install.sh` never overwrites them. Public values (`baseUrl`, usernames) go to
`http-client.env.json`; secrets belong in `http-client.private.env.json`, which
`http/.gitignore` keeps out of the repository.

- **Chaining requests goes through a post-request script.** `client.global.set`
  stores a value that later requests use as `{{VAR}}` — see `http/example.http`.
  The documented `{{request.response.body.$.field}}` syntax does not work in
  kulala 6.x: requests are executed by the kulala-core binary, and its store for
  those values stays empty. The scripts need no Node.js — kulala-core runs them.
- **kulala-core keeps a local history.** `~/.local/share/kulala-core/kulala.db`
  (SQLite) stores request history with headers and response bodies, plus the
  variables set from scripts — tokens included, in plain text, surviving restarts.
  Clear the variables with `<leader>hX` in an `.http` buffer; delete the file to
  drop the history.

## Spell checking

Spelling is checked by **codebook**, a language server — not a plugin. It splits
`camelCase`, `PascalCase`, `snake_case` and `SCREAMING_SNAKE_CASE` itself and
suggests fixes in the original case, and it knows identifiers from strings and
comments. Mason installs it automatically.

- **Diagnostics are hints, never errors** (`diagnosticSeverity = "hint"`), so
  spelling never inflates the error counters in the status line, the buffer tabs
  or the problems panel.
- **`<leader>ca` on a flagged word** offers `Add to dictionary` (the project's
  `.codebook/words.toml`) and `Add to global dictionary` (the global one), along
  with the spelling suggestions.
- **`<leader>cw` adds every unknown word of the buffer in one request.** The
  words come from codebook's own diagnostics and from the path check below,
  taken from the buffer text the diagnostic covers, so a sub-word of a
  `camelCase` identifier is added as the checker flagged it.
- **`<leader>xs` checks the whole project.** Every file codebook handles goes
  into the quickfix list "Spelling issues", opened in Trouble with the cursor in
  it, and neo-tree shows `󰓆 N` behind every file and every collapsed folder
  holding some; the path check below applies too. Saving a file rechecks it,
  pressing the key again during a scan cancels it, `<leader>xS` clears the list
  and the tree.
- **Words reach a dictionary in lower case**, whichever of the three adds them.
  codebook compares words without regard to case, so `nestjs` also accepts
  `NestJS` and `NESTJS`, and one word never sits in a dictionary twice.
- **A string that holds a path is checked word by word**
  (`spelling.check_paths`). codebook skips such a string whole, so
  `'user/leagcy-auth'` is silently correct for it, and so is the path of an
  `import` or an `export`. The config sends the server a copy of the buffer in
  which the slashes inside strings are spaces and keeps the words only that copy
  flags; the hints read like codebook's own and `<leader>cw` adds them as well.
- **The messages are collected above the first line of the buffer**
  (`lsp.diagnostics_summary`): a count, the words, and how to add them all.

  ```
  ● Possible spelling issues (3):
  qwe, asd, zxc.
  <leader>cw adds all of them to the dictionary
  ```

  The word keeps its underline and its sign in the status column, so where it
  sits is still visible.
- **`<leader>us`** turns the checker off and on for the session.
- **English and Russian** (`dictionaries = ["en_us", "ru"]`): a word passes when
  either dictionary knows it. codebook downloads a dictionary from GitHub the
  first time it starts with it (`ru` is 3.4 MB) and keeps it in
  `~/.local/share/codebook/cache`. A word mixing both scripts (`barrel'ы`) is
  still flagged.
- **Dictionaries live outside `~/.config/nvim`**, which `install.sh` replaces
  wholesale: the global one is `~/.config/codebook/codebook.toml`, the project
  one is `.codebook/words.toml` in the project root, written on the first word
  added and meant to be committed with the project.
- **`ignore_paths` takes glob patterns.** A bare `"node_modules"` matches only a
  file with that exact name — use `"**/node_modules/**"`. The server rewrites the
  file whenever a word is added and drops keys that hold their default value.
- **Migrating from cspell:** `scripts/cspell-to-codebook.sh` merges
  `~/.config/cspell/user-words.txt` into the `words` array of the global config,
  leaving every other setting alone. Running it twice changes nothing.

`install.sh` creates `~/.config/codebook/codebook.toml` with these defaults when
the file does not exist, and leaves an existing one alone.

## Implementation notes

Settings that look like mistakes but are deliberate, and workarounds that break
when "cleaned up".

### Structure and colors

- **Highlights go only through `custom_highlights` in `settings/ui/theme.lua`,
  never `color_overrides`.** Palette-level overrides tie `CursorLine` to
  `Normal`, and the cursor line can no longer be told apart. Other modules take
  colors from the helpers there — `palette()`, `lualine_theme()`,
  `bufferline_highlights()`, `neo_tree_handlers()` — which return the plugin's
  own defaults when `colorscheme.enabled` is `false`. catppuccin is switched off
  with `cond` (it stays installed and locked), and lazy.nvim raises an error on a
  `require` of such a plugin, so nothing else requires catppuccin.
- **`user/settings.lua` is pure data** — no `vim.*` calls, no functions — so any
  module can require it at any time.
- **A new panel filetype goes into every exclusion list:** `PANELS` in
  `settings/session/autosession.lua` (a restored empty tree or a dead debugger
  panel is worse than no session), `EXCLUDED_FILETYPES` in
  `settings/structure/dropbar.lua`, `disable.ft` in
  `settings/whichkey/whichkey.lua`, `panels` in `settings/ui/lualine.lua`,
  `ft_ignore` in `settings/ui/statuscol.lua`, and the lists in
  `settings/treesitter/treesitter-context.lua` and `settings/ui/indent.lua`.
- **`:checkhealth myconfig` lives in `lua/myconfig/`:** checkhealth looks for
  `lua/<name>/health.lua`, and a `core/health.lua` would add a second
  `:checkhealth core` report. Its lists of servers, tools, the debug adapter and
  the sessions directory come from the settings that use them.

### Editor

- **Leaders are set first in `init.lua`:** a keymap created before that binds to
  the old leader, and plugin specs read the leader at import time.
- **Visual-mode keymaps use mode `x`, not `v`:** `v` also covers Select mode,
  where typed text must replace a snippet placeholder.
- **The terminal's window and tab title names the current directory.** Neovim
  writes a title only with `'title'` on; without it a kitty tab keeps the name
  of the program kitty started, `bash`. `ui.title` is the `'titlestring'`, and
  the `getcwd()` in it follows the root of neo-tree: the tree's `cwd_target`
  points the tab's directory at the root it shows, so `.` on a folder renames
  the tab as well.
- **Only `x` / `X` put deleted text on the clipboard.** `'clipboard'` is
  `unnamedplus`, so every delete would otherwise replace the system clipboard.
  `d`, `D`, `c`, `C`, `s` and `S` (Normal and Visual mode) write to the black
  hole register instead; `y` copies and `x` / `X` cut: `x` on a selection cuts
  it, `Vx` cuts a line, and `xp` still swaps two characters. The keymaps are
  `expr` mappings that add `"_` only when no register was given, so `"add` still
  fills register `a`; an explicit `"+` or `"*` looks the same as no register and
  goes to the black hole too. In oil a file is moved with `Vx` and `p`: after
  `dd`, `p` would paste the clipboard as a new file name.
- **`<leader>w` writes every named buffer.** `:wall` writes them as well, but it
  ends with `E141: No file name for buffer N` as soon as a buffer that was never
  saved is open. `write_all()` in `core/keymaps.lua` walks the buffer list
  instead and takes the modified buffers that have a name and an empty
  `'buftype'`; each is written with `:silent write`, so the per-file reports do
  not add up to a hit-enter prompt, and one message gives the number written. A
  write that fails or is declined — a read-only file asks first, the same way
  `:w` does — is reported and stays out of that number. The writes go through
  `BufWritePre`, so format on save runs for a buffer in the background too.
- **A file buffer takes the place of the empty `[No Name]` buffer.** Neovim
  starts with an unnamed buffer, and opening the first file from neo-tree or a
  picker leaves it behind in the buffer list and in bufferline. The
  `replace_empty_buffer` autocmd in `core/autocmds.lua` removes it as soon as a
  file buffer is shown in a window, and only if it is really empty: listed,
  without a name, without a `'buftype'`, unmodified and a single empty line, and
  no window showing it. A scratch buffer that has text in it stays, and so does
  an empty one that is still on screen in a split. While a session is being
  restored the autocmd steps aside (`g:SessionLoad`): the session script itself
  wipes the unnamed buffer it started from, and finding it already gone ends the
  restore with `E517: No buffers were wiped out`, which makes auto-session turn
  off its automatic saving for the rest of that session.
- **`<leader>a` restarts Neovim with `:restart!`, not `:restart`.** Neovim 0.12
  starts a new server with the same arguments and reattaches the terminal UI, so
  the configuration is read again without leaving the shell, and `'confirm'`
  turns an unsaved buffer into a "Save changes?" prompt rather than a silent
  exit. The bang skips the `mksession` round trip `:restart` does on its own and
  leaves the session to auto-session, which saves it on exit and restores it on
  the next start, breakpoints (`save_extra_data`) and the git branch tag
  included. Started as `nvim <file>`, the new instance opens that file again and
  restores no session: auto-session saves none for a start with file arguments
  (`args_allow_files_auto_save = false`). Neovim's own `ZR` is `:restart`; the
  key does what `1ZR` does.
- **`'inccommand'` stays `nosplit`**, which inc-rename's live preview needs, and
  `'sessionoptions'` includes `localoptions`, without which auto-session loses
  filetype options and buffer-local keymaps on restore.
- **`'timeoutlen'` is 400 ms**, and which-key opens after 200 ms, before an
  ambiguous key times out. TODO jumps are `]td` / `[td` because `]t` / `[t`
  belong to neotest.
- **The status column is split by source** (statuscol.nvim):
  `[diagnostics, breakpoints, TODO, tests] [line number] [git, coverage]`. A plain
  sign column packs a line's signs to the left, so a git bar would take the
  diagnostic cell. The plugin loads at startup, or windows shift sideways once it
  takes over. `:terminal` windows are reset on `TermOpen` and panels are listed
  by filetype, because statuscol's `bt_ignore` misses buffers whose `buftype` is
  set late (dbui). Coverage signs (priority 5) sit below gitsigns (6) in the
  shared one-cell git segment, and line numbers take the git color, not the
  diagnostic one.
- **Annotations are drawn at the end of their line** (`core/annotations.lua`):
  every diagnostic and every `Unused symbol` marker, each opened by `●` in the
  color of its severity — in `UnusedSymbol` for a diagnostic tagged
  `Unnecessary` — four columns behind the code, the gap Neovim leaves in front
  of its own virtual text. That handler exists because Neovim's `virtual_text`
  has no room for a mark the config raises itself and `virtual_lines` draws
  below the line with no switch for it — `vim.diagnostic.Opts.VirtualLines`
  knows `severity`, `current_line` and `format` and nothing else — so the config
  registers `myconfig/annotations` and turns both off. Every annotation of a
  line lives in one extmark, which fixes their order: errors, then the warnings
  and the unused marks together, then hints and information, one chain behind
  the code. Diagnostics also arrive for buffers that are not loaded, since vtsls
  reports the whole project, and the handler drops those instead of drawing into
  nothing.
- **An `Unused symbol` marker also puts `○` left of the line number.** The
  extmark that carries the annotations of the line carries the sign as well, in
  `UnusedSign`, which links to `DiagnosticSignWarn`. Its priority is 11: above a
  hint, below a warning and an error, so the diagnostic of the same line keeps
  the single cell of the status column while a spelling hint — summarized above
  the buffer anyway — gives it up. Only what `settings/lsp/unused.lua` counts
  gets the sign; what the compiler proves unused is a diagnostic and carries a
  diagnostic sign already.
- **A source named in `lsp.diagnostics_summary` gets one block above the first
  line instead** — codebook does. Spelling is the one check that fires on almost
  every second line, and a message per word buries the compiler between them.
  The block is the `label` with the number of distinct words, the words, and
  the `hint`, which is italic `AnnotationHint`. Words are read from the buffer
  text each diagnostic covers, not from its message, so a sub-word of a
  `camelCase` identifier is listed the way the checker found it; they are
  compared in lower case and shown in the spelling of their first occurrence,
  which keeps `Dto` and `DTO` one entry. The word list wraps at `width` columns
  counted from the left edge of the buffer, never inside a word. The key of the
  setting is the `source` a server puts on its diagnostics (`Codebook`), which
  is what the diagnostic float shows. The block is the one annotation still
  drawn in virtual lines, and a virtual line above the first line of a buffer
  stays invisible until the window is given filler lines
  ([#16166](https://github.com/neovim/neovim/issues/16166)), so the renderer
  sets `topfill` itself while the window sits at the top — without it the whole
  block would be hidden.
- **`<leader>1` … `<leader>9` use `bufferline.go_to(i, true)`**, the absolute
  position shown on the tab; `:BufferLineGoToBuffer` counts only visible tabs.
  Buffers are closed only through `safe_buffer_delete` (bufdelete.nvim), which
  keeps the window layout.
- **A buffer a session restored is deleted without bufdelete.nvim.** A session
  file lists its buffers with `badd`, so they are listed but not loaded until
  they are opened, and bufdelete skips a buffer that is not loaded: after a
  restore `<leader>bo` and `<leader>bd` left every untouched buffer in the
  tabline. `safe_buffer_delete` in `settings/ui/bufferline.lua` deletes that
  buffer itself with `nvim_buf_delete`, which is what `:bdelete` does to it —
  no window shows it and it cannot be modified, so there is no window layout to
  keep and nothing to ask about.
- **The number on a tab is its position, not bufferline's `ordinal`.** The
  plugin writes that number into the tab while it builds the components, before
  it sorts them and before the pinned group moves to the front, so
  `numbers = "ordinal"` showed the place a buffer holds in the buffer list:
  pinning one tab was enough to leave the tabline reading 3, 1, 2, 4, 5 while
  `<leader>3` still went to the third tab. The `numbers` function in
  `settings/ui/bufferline.lua` numbers a tab by the position of its element in
  bufferline's rendered component list, the list `go_to(i, true)` indexes, so
  the label and the key always name the same buffer. That list is one render
  behind whenever the order changes, so the function compares it, after the
  render, with the order it numbered from and asks for one more
  `redrawtabline` when the two differ; on a settled tabline it schedules
  nothing.
- **`<leader>bo` keeps the pinned buffers.** `:BufferLineCloseOthers` walks the
  whole tab list and closes everything but the current buffer, pins included.
  The key runs `delete_others()` in `settings/ui/bufferline.lua` instead: it
  reads bufferline's own components, leaves out the current buffer and every
  buffer of the `pinned` group, and deletes the rest through
  `safe_buffer_delete`. Pressed where the current buffer has no tab of its
  own — in neo-tree, in a panel — it does nothing, the same as the command.
- **`<leader>ba` keeps the pinned buffers and otherwise ends on one empty
  buffer.** `delete_all()` in `settings/ui/bufferline.lua` hands every listed
  buffer outside bufferline's `pinned` group to bufdelete.nvim in one call. A
  window that held one of them switches to a pinned buffer; with no pins, the
  plugin finds nothing left to switch to and opens a fresh `[No Name]` buffer
  in each window that held one — the state `<leader>q` leaves when it closes
  the last buffer. The window layout stays, panels keep
  their own buffers, and a modified buffer still asks whether to save it.
  Deleting the buffers one by one would instead walk the windows through the
  remaining files first.
- **lualine tracks LSP progress per work-done token** from the `LspProgress`
  event data and drops a task on its `end`. Neither `ev.match` (the kind
  expanded to a path, `/cwd/end`) nor `vim.lsp.status()` (everything the ring
  buffer collected, finished tasks' titles included) can tell that a task is
  over: built on them, the status line kept "Analyzing '…' and its
  dependencies" long after vtsls had loaded the project. Progress text escapes
  `%` (`" 45%: Loading"` is E539 in `'statusline'`); the nvim-dap and neotest
  components stay empty until those plugins are loaded and never load them.
- **Files under `node_modules` open `'readonly'` and `'nomodifiable'`**
  (`editor.readonly_dirs`): `'readonly'` alone still takes a change and lets
  `:w!` write it. A `BufReadPost` autocmd sets both however the file is opened —
  go to definition, a picker, a restored session — at any depth, a pnpm
  store in `node_modules/.pnpm/…` included. An LSP edit into such a file fails with
  "Buffer is not 'modifiable'", which vtsls does not send for library code
  anyway; `:setlocal modifiable noreadonly` unlocks one buffer.

### LSP

- **Never enable ts_ls next to vtsls:** every diagnostic would appear twice.
  vtsls resolves its root from its own markers, because nvim-lspconfig's
  `root_dir` always wins over `root_markers`.
- **LSP keymaps exist only for methods the server supports.** The single
  LspAttach (`settings/lsp/keymaps.lua`) creates them buffer-locally, and
  LspDetach removes a key once the last client that registered it has left. The
  pass repeats on dynamic capability registration: docker-language-server
  registers rename about three seconds after attaching.
- **`grn`, `<leader>cr` and `<leader>rn` are one rename** with inc-rename's
  preview; `gd`, `gri` and `grt` open fzf-lua pickers, while `grr` opens Trouble —
  a list that stays open is easier to walk through than a picker.
- **`<leader>ca` and `gra` leave out disabled code actions.** Neovim lists them
  when the menu is invoked by hand, marked `(disabled)`, and choosing one only
  shows the reason. fzf-lua's preview sends `codeAction/resolve` for each action
  it shows, and tsserver 4.8 answers that for a disabled refactor with a
  `Debug Failure` stack trace.
- **Auto-imports follow `lsp.import_style`, `shortest` by default.** In a NestJS
  monorepo with a single `tsconfig.json` at the root, `non-relative` writes every
  import without a path alias as a path from `baseUrl`
  (`apps/admin/src/modules/login/presentation/controllers/login.controller`), and
  that is what `<leader>cm` inserts. `shortest` compares both forms: an alias
  wins where one exists (`@app/config` is shorter than the relative path into
  another top-level directory), and a file of the same module arrives as
  `./presentation/controllers/login.controller`. `project-relative` does not help
  here, as it treats the directory of the `tsconfig.json` as the project and
  drops the aliases of `libs/` with it. The value reaches completion,
  `<leader>cM` and the import rewrite on a file move as well.
- **Docker files get two servers.** docker-language-server lints Dockerfiles
  through BuildKit but answers completion and hover with nothing, so dockerls
  supplies those; `removeOverlappingIssues` keeps their diagnostics from
  doubling. Compose and Bake files get compound filetypes (`yaml.docker-compose`,
  `hcl.dockerbake`, in `core/filetypes.lua`) so the server is not handed every
  `.hcl` file, and Bake buffers go out with the `dockerbake` language id — with
  `hcl` the server parses them as Dockerfiles.
- **yamlls** drops nvim-lspconfig's `yaml.gitlab` / `yaml.helm-values`, filetypes
  Neovim never produces, and hides rename in compose buffers: its empty
  `prepareRename` ended every service rename with "Nothing to rename".
- **ESLint only lints.** Its `prettier/prettier` rule is silenced at the server
  because Prettier already formats on save, and nothing is fixed on save. A
  "Delete `␊`" diagnostic means `rulesCustomizations` in
  `settings/lsp/servers/eslint.lua` needs a look; after editing `.prettierrc` run
  `prettierd restart`.
- **SQL is formatted by sql-formatter**, which Mason installs with the other
  tools. The `--language` conform passes (`formatting.sql_dialect`) is a default
  only: sql-formatter looks for a `.sql-formatter.json` from Neovim's working
  directory upwards and that file wins over the flag, so a project pins its own
  dialect, indent and keyword case. `=` is no substitute — the treesitter SQL
  indents align the lines a query already has and never re-wrap it. Query buffers
  of vim-dadbod-ui are ordinary files and are formatted on save as well.
- **Unused code is found in two ways and drawn as one.** What TypeScript can
  prove unused — imports, locals, parameters, private members, and whatever
  ESLint tags the same way — arrives as a hint carrying the LSP `Unnecessary`
  tag, and Neovim paints the code itself with `DiagnosticUnnecessary`:
  `overlay0`, dimmer than a comment's `overlay2` and without its italics. An
  exported class, a public method, a field, a type or a constant is valid code
  with nobody calling it, so no compiler diagnostic describes it:
  `settings/lsp/unused.lua` counts the references of every such declaration and
  writes `Unused symbol 'name'.` behind its line, through the same renderer the
  diagnostics use. Both report the same thing, so both are shown as one. A
  tagged diagnostic becomes a warning before Neovim stores it:
  `core/diagnostics.lua` wraps the two handlers a server answers diagnostics
  with — `textDocument/publishDiagnostics` and the pull variant
  `textDocument/diagnostic`, its related documents included — and rewrites the
  severity of everything tagged `Unnecessary`, so the sign, the counters of the
  status line and trouble say the same thing the annotation behind the code
  does; a
  hint would otherwise rank below every other annotation and count for nothing.
  Only a hint or an information is raised, never an error a server means as one,
  and the tag itself is left alone, so the code keeps its
  `DiagnosticUnnecessary` dimming. Above the line such a diagnostic is drawn in
  `UnusedSymbol` rather than in the color of its severity, and `UnusedSymbol`
  links to `DiagnosticVirtualTextWarn`: one group colors both marks. That
  warning group is replaced whole in `custom_highlights`, so the faint
  background catppuccin puts behind virtual text —
  `darken(peach, 0.095, base)`, `NONE` while `colorscheme.transparent` is on —
  is repeated there, and the italics of `lsp_styles.virtual_text` with it. The
  marker yields to the compiler: where a diagnostic of that line already carries
  the LSP
  `Unnecessary` tag (`user_data.lsp.tags`) over the same columns — an unused
  local, a private field, a class nobody imports — the renderer drops the
  `Unused symbol` mark, its sign with it, and leaves the diagnostic alone.
- **The reference count is a module of the config, not a plugin.**
  symbol-usage.nvim did the same counting, but it draws virtual text of its own,
  a second row of marks beside the diagnostics, and never removes a marker once
  a symbol gains a reference — "unused" then hangs over code that is used. The
  module requests `textDocument/documentSymbol`, keeps that tree until the
  buffer changes, and sends one `textDocument/references` per declaration
  visible in the window, counting again after an edit, after a scroll and on
  `BufEnter`, since a usage may have been deleted in another buffer. Counted are
  classes, interfaces, enums, functions, the methods and fields of a class, and
  the constants, types and arrow functions of a module; a local inside a
  function body is left to the compiler, which grays it out anyway. What carries
  no name a reference could point at is skipped: a function handed to a call,
  which tsserver names after that call (`setTimeout() callback`, and
  `register("plain") callback` when the call has arguments of its own), and an
  anonymous declaration, which it names `<class>` or `<function>` — the `class`
  a factory returns among them. Each of those counts zero references forever and
  would carry a marker for good. A member of an object literal is left out as
  well — the `useFactory` of a Nest module, the handler of a route table,
  `parse` in a bag of helpers: a count finds the calls that go through the
  object, but never the ones a framework makes by convention, and the marker was
  noise more often than not. A member is therefore counted in a class only,
  which is also where `lsp.unused_skip` applies. The body of an interface is
  left out for a reason of the same kind: an interface describes a shape that
  crosses a boundary (a request body, a configuration file, the row of a query),
  and its fields and methods are filled, read and implemented there without the
  code naming them, so a count of zero says nothing about the shape. The
  interface itself still carries the count. The members of an enum are skipped
  for the same reason: a value of one travels through a database column, a
  payload or a migration, where nothing points at the name, and the enum itself
  carries the count. tsserver reports a member as a variable whose parent is the
  enum, which is how they are told apart from the constants of a module.
- **`lsp.unused_skip` lists where a count is meaningless.** The fields of a
  class are skipped in every file (`fields = { "*" }`): a DTO is filled by the
  framework through the validation decorators, an entity by the ORM through the
  column decorators, a provider's fields by injection, and a count of zero says
  nothing about any of them. The methods of a `*.controller.ts` are routes
  nothing calls from the code, so they are skipped too. `fields` and `methods`
  are globs (`vim.glob`, the LSP syntax with `*`, `?` and `{}`) matched against
  the name of the file, not its path; they reach the members of a class, the
  only ones counted at all, and everything else in those files is still counted
  — the class itself among them. `paths` matches the whole
  path instead and takes the file out entirely — `**/node_modules/**`, where
  every declaration belongs to a dependency, most of them are meant for other
  projects and each open file would cost a request per symbol. Nothing counts
  there until `<leader>uu` asks for the markers by hand. A method reached only
  through a decorator somewhere else — a lifecycle hook, a queue handler — is
  marked as well: the count is honest, the framework is not part of it.
- **`<leader>xu` runs the same count over the whole project.** The markers
  count only what a window shows; the project scan takes every file under the
  `root_dir` of the buffer's server whose filetype that server handles, listed
  by `rg --files --no-require-git` (so `.gitignore` applies outside a git
  repository too), minus `lsp.unused_skip.paths`, and applies the same rules to
  each. vtsls answers `textDocument/documentSymbol` for an open document only —
  an empty list otherwise — so a file without a buffer is opened for the server
  alone with `textDocument/didOpen` and closed again with `didClose`, while a
  file that has a buffer is read from it, unsaved edits included. Files go one
  at a time, one `textDocument/references` per declaration: 1395 files took
  about three and a half minutes, and the editor's own requests wait behind
  that queue meanwhile. The progress is a `progress-message` (`nvim_echo` with
  `kind = "progress"`); pressing the key again cancels the outstanding requests
  and closes the open document. The result becomes the quickfix list
  "Unused symbols", opened in Trouble with the cursor in it, as `grr` does —
  unless the scan ends while you type in insert or command-line mode, where a
  jump would take the keys — and neo-tree's filesystem shows `○ N` in
  `UnusedSign` behind every file and every collapsed folder holding some. That
  is the `unused` component of `settings/explorer/neotree.lua`; neo-tree takes a
  custom component only through the renderers, so the filesystem source repeats
  neo-tree's default `file` and `directory` renderers with it added, and the
  tree is redrawn with `require("neo-tree.sources.manager").redraw`. Saving a
  file recounts that file alone and updates the list and the tree; a usage
  removed elsewhere shows up with the next scan. `<leader>xU` clears both.
  The scan itself lives in `settings/lsp/project.lua`, which `<leader>xs`
  shares.
- **vtsls' reference code lens stays off.** It answers a `codeLens/resolve` with
  the unresolved lens whenever the symbol has no references, because the command
  VS Code puts behind "0 references" has an empty id. Neovim keeps such a lens
  unresolved, draws an empty virtual line above the declaration and asks again on
  the next redraw of that row: one file with a handful of unused declarations
  sent about 15000 `codeLens/resolve` requests in 20 seconds. The counts come
  from `settings/lsp/unused.lua` instead, and `<leader>cl` / `<leader>cL` keep
  working for the code lenses of other servers.
- **The LSP log is off** (`vim.lsp.log.set_level(vim.log.levels.OFF)`): it grows
  to gigabytes. Turn it on only to debug a server.
- **codebook:** `<leader>us` stops the server rather than hiding its
  diagnostics, since a disabled diagnostic namespace is still counted by
  `vim.diagnostic.count()` and the status line would keep showing it.
  `exit_timeout = 500`, because the server never exits on its own.
- **The project dictionary reaches codebook as an absolute path.** The server
  takes it in `initializationOptions.configPath`, and 0.3.42 resolves a relative
  value against its own working directory instead of the project root, so the
  dictionary would follow `:cd` rather than the project. `before_init` joins
  `spelling.project_dictionary` onto the resolved `root_dir` and writes the
  result into `params.initializationOptions`: `config.init_options` has already
  been copied into the initialize request by then, and a change made there
  arrives nowhere. `.codebook` is a root marker as well, so a project whose only
  mark is its dictionary is still recognized. Without `configPath` a project
  without a `codebook.toml` loses every added word without a message: the server
  has no file to save to.
- **Added words are lowered on the client.** codebook 0.3.42 stores a word in
  the case the command hands it, so `NVI` and `nvi` could both end up in the
  file. The client config maps `codebook.addWord` and `codebook.addWordGlobal`
  to a local command (`commands`), which `Client:exec_cmd` prefers over the
  server's: it lowers every argument and sends `workspace/executeCommand`
  itself. The code actions and `<leader>cw` both go through it.
- **The words inside a path string are checked through a second, invisible
  document.** codebook reports nothing inside a string literal that contains a
  `/` — a route, a URL, a path — while the same word in a comment or in a plain
  string is flagged. `settings/lsp/spelling.lua` sends the server a shadow
  document instead: the buffer with every `/` inside a string literal replaced
  by a space, under a URI of its own (`.<name>.spelling.<ext>`, which is no
  file on disk). One byte for one byte, so every diagnostic comes back on a
  position of the real buffer; a per-client `textDocument/publishDiagnostics`
  handler recognizes that URI, keeps the hints that fall inside a rewritten
  string and publishes them into the `myconfig.spelling` namespace under
  codebook's own `source`, which puts them in the summary block and in
  `<leader>cw`. The path of an `import`, an `export` or a `require` goes through
  that copy like any other string, so a package name (`@nestjs/common`) is read
  word by word, the way codebook itself reads a name without a slash
  (`nestjs-pino`). Template strings are the exception: codebook reads those on
  its own, slashes and all. A hint the server already sent for the real
  document is dropped, whichever of the two publishes arrives first. The shadow
  document is re-sent, debounced, on `TextChanged` and `InsertLeave`, and closed
  when codebook leaves the buffer.
- **`<leader>xs` is `<leader>xu`'s scan with codebook in place of vtsls.** Both
  run through `settings/lsp/project.lua`: the file list, the progress message,
  the quickfix list, Trouble, the neo-tree counter (the `spelling` component, in
  `SpellingSign`, which links to `DiagnosticSignHint`), the recheck on save and
  the cancel. codebook pushes its diagnostics rather than answering a request,
  so a file without a buffer is opened with `didOpen`, and the scan waits for
  the `textDocument/publishDiagnostics` of that URI; the server sends one for
  every opened document, an empty list for a clean one, and another empty list
  after `didClose`. The client handler takes both for the scan: Neovim's own
  handler would create a buffer for every file of the project. A URI stays
  claimed until that last empty list arrives, and a shadow URI an open buffer
  owns is checked before any claim: a buffer opened after the scan sends its
  shadow document under the same URI the scan used, and losing that answer would
  drop the buffer's path hints. A file that has a buffer is read from its
  diagnostics instead, the path check's included. For a file without one, the
  shadow document is built from the file text with
  `vim.treesitter.get_string_parser` and sent beside it. Eight files are in
  flight at once (`spelling.scan_parallel`), and a file the server never answers
  is given up after five seconds (`spelling.scan_timeout`): 1913 files took
  about 19 seconds, none of them timed out.

### Plugins

- **neotest discovery is off:** it walks the whole workspace and freezes the
  editor in a NestJS monorepo, so the tree is built from the files opened and
  run. The Jest command has no trailing `--`: the adapter appends its own flags,
  and after `--` Jest takes them as path patterns, never writes the results file
  and reports every test as failed. Jest and Vitest run from the package root of
  a monorepo.
- **Coverage** is loaded with `:Coverage`, not `:CoverageLoad`, which reads the
  report without placing the signs.
- **Debugger:** attaching to a local `nest start --debug` has no
  `localRoot` / `remoteRoot` — with them js-debug treats the process as remote and
  breakpoints stay provisional — while the container configuration needs the
  pair. ts-node launches load `tsconfig-paths/register` for `@app/…` aliases. The
  session listeners that open the panel must not be keyed `dap-view`, the name
  the plugin uses for its own, and `terminal_win_cmd` stays unset, or a second
  terminal window is left behind. nvim-dap-virtual-text reads `enable_commands`
  (its README says `enabled_commands`); with js-debug every value gets the
  "changed" highlight, because js-debug hands out a new frame id on every stop.
  nvim-dap-view's own virtual text stays off, so values don't show twice.
- **git-conflict's `disable_diagnostics` is off:** it calls
  `vim.diagnostic.disable()`, which Neovim 0.12 no longer has, so the config
  switches diagnostics off itself. Its highlights need a background color, or
  the plugin falls back to its own.
- **diffview** turns diagnostics off in every view (conflict markers and old file
  versions flood with errors) and moves keys that would shadow global groups:
  `<leader>e` / `<leader>b` → `<localleader>e` / `<localleader>b`, conflict
  choices → `<leader>gx…`, `<C-A-d>` → `<localleader>d`.
- **render-markdown.nvim draws `.md` buffers** and wraps a table wider than
  the window inside its cells (`pipe_table.wrap`): it hides the table's lines
  and draws the wrapped table in virtual lines, so it works with `'wrap'` off.
  The raw text comes back on the line under the cursor. Every documented option
  is written out at its default except `latex.enabled`, which is off: neither
  the latex parser nor `utftex` / `latex2text` is installed, and the health
  check would warn about them. Its glyphs sit in `icons.markdown`; the border
  characters of tables, headings and code blocks stay in the settings file.
  `<leader>um` switches the rendering off and on. Markdown text wraps at word
  boundaries: `after/ftplugin/markdown.lua` turns `'wrap'` and `'linebreak'` on
  for the window showing the buffer, while every other filetype keeps the
  global `wrap = false`.
- **lazygit runs in a floating terminal of `core/lazygit.lua`**, not in
  lazygit.nvim: that plugin builds a shell command from the path of the
  current file on every start, so a file reached through a symlink whose
  target holds `$(…)` ran that command; its `:LazyGit*` commands went with it.
  `open()` starts lazygit with `jobstart()` and an argument list, in the
  working directory, with two config files when they exist: your own
  `~/.config/lazygit/config.yml`, then `lazygit.yml` from this config on top of
  it, which sets the editor commands only; `git.autoFetch` is off there, so
  lazygit fetches only when asked. A repository can make lazygit's git run
  commands in several ways, and `open()` collects every file that does so
  before lazygit starts:
  - `lazygit.yml` in the common git directory (the main `.git`, even in a
    linked worktree) and `.lazygit.yml` in every parent directory of the main
    worktree, which lazygit merges over the config above;
  - when any repository-scope setting runs commands (`filter.*`, `diff.*`,
    `difftool.*`, `mergetool.*`, `gpg.*`, `include*`, `trailer.*`,
    `submodule.*.update`, `core.pager`, `core.sshCommand`,
    `core.alternateRefsCommand`, `core.hooksPath`, `remote.*.vcs` and the
    like), every file those settings come from: git lists them with
    `config --includes --show-scope --show-origin -z`, run in the work tree's
    top directory because it prints the origins relative to it, so
    `.git/config`, `.git/config.worktree` and included files at any depth all
    count, whatever their names hold, from any directory Neovim was started
    in; an origin that does not exist keeps lazygit from starting;
  - every executable hook in the hooks directory git uses
    (`rev-parse --git-path hooks`, which follows `core.hooksPath`), `.sample`
    files aside.

  Each must be a regular file of at most 64 MB, and the whole set goes through
  the same Allow / Deny / Ignore prompt as a project root, keyed
  `lazygit:<main worktree>` in `trust.json`: one question per repository, asked
  again when any of those files changes, and `:ProjectTrust` lists, forgets
  and denies it. When git cannot describe the repository, lazygit does not
  start. A repository opened from lazygit's own repository menu skips the
  check, and so do the scripts a hook manager's stubs call (husky, lefthook):
  the stubs are in the set, the tracked scripts behind them are not. A second
  `<leader>gg` while the
  float is open goes back to it instead of starting another lazygit. The float
  takes its size from `git.lazygit_scale`, and its filetype is `lazygit`, the
  name the panel lists use; closing it by hand ends lazygit with it. `e` on a
  file, or on a line of the
  staging view, calls `edit_hex()` of `core/lazygit.lua` through
  `nvim --server "$NVIM" --remote-expr`. The path travels as hex digits
  (`od -tx1`), never as text inside the expression: a file name holding `"`
  would otherwise close the string and run the rest as a Vimscript expression.
  `edit_hex()` decodes it, keeps the first name when several files are
  selected, and hands it to `edit()`, which remembers the path, sends `q` to
  lazygit and opens the file in the window lazygit was started from once the
  float has closed. Opened at once, the file would land in the float, which
  closes as lazygit exits. `editInTerminal` is off, or lazygit waits for Enter
  after every such call; the one command that has to
  wait for the editor (`editAtLineAndWait`) runs a nested Neovim in the float
  instead. neovim-remote (`nvr`) is not needed.
- **neo-tree** loads on the first directory buffer (with netrw off, `nvim .`
  would otherwise open an empty buffer), sends `workspace/didRenameFiles` so
  vtsls fixes imports after a rename, and takes its width from a function:
  neo-tree also does arithmetic on the raw value, which a `"25%"` string
  breaks. **oil's `default_file_explorer` stays `false`**, or `nvim .` opens
  oil instead of the tree. Inside the tree the keys follow `h` / `l`: `l`
  opens a node (a folder expands, a file opens), `h` closes it together with
  every node opened inside it (`close_all_subnodes`, not `close_node`, so a
  folder always reopens collapsed and `z` stays the way to fold the whole
  tree), `.` toggles hidden files, `H` toggles the preview, `J` / `K` scroll
  it and `L` focuses it. `d` moves a node to the trash and `D` removes it for
  good: the key that can be taken back is the lower-case one, and `u` (which
  undoes a trash and nothing else) and `U` (restore from the trash) follow
  `d`. On Linux the trash is `gio trash` or, without it, neo-tree's own
  freedesktop implementation. neo-tree's own `T` for the trash is gone, since
  the buffers source implements it as a plain delete, and the directory search
  moved from `D` to `F`, beside `/` and `f`. `D` is a no-op in the symbol
  list, where the tree holds no files. `<cr>` opens a file and sets the root
  on a folder — one key for both, so it is a function rather than a command
  name — and it is declared per source rather than globally, because
  `set_root` exists in filesystem and buffers only and a global one would
  leave `<cr>` unmapped in git_status; `toggle_hidden` is filesystem's alone
  for the same reason. A key that has to go is mapped to `"none"` (`P`, `C`,
  `T`, `<C-f>` / `<C-b>`, and `.` in buffers): leaving the line out instead
  brings neo-tree's own default for it back, since a source inherits the
  global table and the defaults underneath it.
- **Deleting a path closes the buffers under it.** A folder is where both
  explorers leave them open: neo-tree removes the directory with `rm -Rf` and
  clears buffers only in the libuv fallback it never reaches, oil clears none
  at all, not even for a single file. The buffers of the deleted files stayed
  in the tabline, and `auto_mkdir` recreates a parent directory on write, so
  `:w` in one of them brought the whole tree back. neo-tree's `file_deleted`
  event and oil's `User OilActionsPost` hand the path to
  `delete_buffers_under` in `settings/ui/bufferline.lua`, which closes the
  buffer of that path and of every path below it through `safe_buffer_delete`,
  forced, the way neo-tree closes the buffer of a file it deleted on its own.
  The oil handler answers for the `oil://` adapter only and for a path that is
  really gone, so a failed action or a remote adapter leaves its buffers
  alone.
- **A rename reaches the buffers a session only listed.** neo-tree renames the
  buffers under a moved path itself, but it walks the loaded ones only, and a
  restored session lists its buffers without loading them until they are
  opened: after a restart the tabline kept the old paths, and the tab led to a
  file that was no longer there. `rename_buffers_under` in
  `settings/ui/bufferline.lua` runs from the same `file_renamed` and
  `file_moved` handler that notifies the servers, after neo-tree has done its
  own part, and replaces every buffer it left behind with one under the new
  path, listed or not the way it was.
- **oil drops an unloaded buffer instead of moving it.** For a folder it walks
  the buffer list and renames every buffer under the old path, but for a file
  it hands its `rename_buffer` a name rather than a buffer number, and that
  function deletes a buffer it finds unloaded instead of renaming it: a file
  moved to another folder, or renamed, took its tab with it whenever the buffer
  came from a restored session. The `OilActionsPre` handler in
  `settings/explorer/oil.lua` loads the listed buffers under the source of
  every `move` action first, through `load_buffers_under`, and oil renames them
  itself — loading them is what it does to them in the folder case anyway.
- **A file deleted outside Neovim closes its buffer.** A file renamed or removed
  by git or a shell left its buffer open, and the next `documentHighlight` made
  tsserver answer with a stack trace (`Could not find source file`) and a
  hit-enter prompt. `settings/ui/bufferline.lua` marks a buffer read from disk
  or written to it, and on `BufEnter` and `CursorHold` (every loaded buffer on
  `FocusGained`) closes a marked one whose file is gone. Its `CursorHold` is
  defined at startup, before any `LspAttach` one, so it runs first and the
  request is never sent. A buffer with unsaved changes stays, and so does a
  new file not written yet: it was never on disk.
- **fzf-lua's key tables replace the defaults** rather than extend them: the
  defaults bind Alt combinations. `vim.ui.select` is a stub that loads fzf-lua on
  the first call.
- **dropbar** narrows treesitter `valid_types` to declarations: the defaults also
  match `class_body`, `property_identifier` and statements, which push the class
  and the method out of `max_depth`. Its preview recenters through
  `winrestview()`, because `:normal` closes the fuzzy prompt. The filter in its
  menus needs the C library of telescope-fzf-native.nvim.
- **The breadcrumbs sit at the bottom, in lualine's left section.** Neovim
  attaches exactly two lines to a window: `'winbar'` above it and `'statusline'`
  below, so the bottom is the status line and nothing else. lualine keeps
  `globalstatus`, and its left section renders `M.statusline()` of
  `settings/structure/dropbar.lua` — the very string dropbar would put in the
  winbar, so the highlights, the click regions and `<leader>;` all keep working,
  and the file name component is gone, because the breadcrumbs end in it.
  dropbar itself never attaches: `bar.enable` is `false` and `attach_events` is
  empty, and the window-level exclusions moved into that function, which asks
  dropbar's own default for everything else. The git and diagnostic counters
  moved to the right half of the line, so the breadcrumbs have the left one to
  themselves. `bar.hover` is off, since the hover highlight is computed for row
  1 of a window, which the status line never is.
- **The drop-down menu is raised to the bottom of the window.** dropbar anchors
  it at row 0 of the window it belongs to, which is where the winbar used to be;
  a menu of the breadcrumbs now has to open at the other end. `symbol.on_click`
  wraps dropbar's own handler and moves the window it opened, so the mouse and
  `<leader>;` end up in the same place: a bordered float is positioned by its
  border box, so the row is the window height less the menu's height and its two
  border lines, and the bottom border lands on the last line of the window. Only
  the first menu is moved, since a submenu is anchored to the menu it came from,
  and the column dropbar computed is kept, which is the clicked component in
  the window, not in the status line.
- **aerial** loads on `BufReadPost` with the LSP backend first: its TypeScript
  query has no properties or fields (NestJS injections), and with a key-only load
  `{` / `}` would stay paragraph motions until the tree is opened once. Anonymous
  callbacks that vtsls reports as symbols are filtered out.
- **Folds come from the LSP when an attached server provides them**, from
  treesitter otherwise, and stay manual in a file above `treesitter.max_filesize`:
  `update_folds()` in `settings/treesitter/treesitter.lua` decides on `FileType`
  and whenever a server attaches or detaches. nvim-origami's own switch to LSP
  folds is off, because it ignores that limit, and `vim.lsp.foldexpr()` freezes
  Neovim on such a file for minutes. origami keeps the rest: line counts with
  diagnostics and git changes on a closed fold, auto-folded comments and
  imports, and folds paused while searching — it removes `search` from
  `'foldopen'` and keeps only the fold under the cursor open once
  the search is over. Its `h` / `l` / `^` / `$` keymaps stay off. Auto-folding
  works through LSP folds only and does not reach the file Neovim starts with;
  files opened later are folded.
- **Trouble:** `<leader>xX` leaves out diagnostics from TypeScript's library
  sources (lib.dom.d.ts alone brings some eighty hints); the LSP lists report an
  empty result, so `grr` on an unreferenced symbol is not silent. `grr` opens
  the references folded to one line per file (`zo` / `zR` unfold them): it calls
  trouble's `fold_close_all` and `fold_reduce`, which wait for the first render,
  since trouble overrides a `foldlevel` given in `win.wo` with its own `99`. The
  list does not refresh by itself (`auto_refresh = false` for `lsp_references`):
  trouble would query the symbol under the cursor again after every jump, drop
  the reference just opened and add files unfolded. `r` still refreshes it by
  hand, and the files that brings in arrive unfolded.
- **refactoring.nvim** keys are operators (`expr` mappings), except the menu of
  all refactors: opening a window while an `expr` mapping is evaluated fails
  with E565.
- **vim-dadbod-ui** notifications use its own floats, not `vim.notify`: with
  Neovim's handler an error becomes a Vimscript trace inside the plugin. MySQL
  table helpers use `{dbname}`, because `{schema}` is empty when the URL names
  a database, and the hidden system schemas are anchored regexes. A helper
  opens its query without running it (`db_ui_auto_execute_table_helpers = 0`):
  a table name is pasted into the SQL as it is, and a hostile name in a shared
  database would otherwise run as the developer. Its `config`
  re-sources `plugin/dadbod.vim` when `:DB` has gone missing: the command
  belongs to vim-dadbod, but it is listed among this plugin's lazy triggers,
  and lazy deletes a trigger by name once the plugin loads — which removes the
  real command whenever vim-dadbod was loaded first. Opening a `.sql` buffer
  does exactly that through vim-dadbod-completion, and without the command
  both `<localleader>x` and a one-off `:DB` fail with E464. Re-sourcing is
  idempotent: the file clears its own augroup and keeps existing globals.
- **`<leader>Du` opens the database in a tab of its own**:
  `:tabnew`, then a plain `:DBUI`, not the documented `:tab DBUI`. With `<mods>`
  the drawer fills the whole tab and shrinks to `database.width` only when the
  tab held a single window as the first query opened, and dadbod-ui's
  notification floats count as windows there. The empty buffer `:tabnew` leaves
  is wiped once hidden. The key jumps to the tab from any other one and closes
  it from inside, and so does `q` in the drawer (`after/ftplugin/dbui.lua`
  maps it over dadbod-ui's own); in the last tab left both close the drawer
  alone. `<C-j>` in the drawer jumps to the query results: the drawer spans
  the whole tab, so `<C-w>j` has no window below it, and dadbod-ui's own
  `<C-j>` (last sibling) is replaced; `J` / `K` still move between siblings.
  `<leader>Df` follows the tab too: `:DBUIFindBuffer` opens the drawer in the
  current tab, so the buffer is first shown in the database tab — in its query
  window, or a split beside the drawer, which then gets `database.width` back —
  and the command runs there.
- **kulala**'s `pathresolver` keeps its documented default although 6.x never
  calls it: kulala-core resolves request variables itself.
- **blink.cmp** uses the prebuilt Rust matcher of the pinned tag; without network
  access set its implementation to `"lua"`. `<Tab>` / `<S-Tab>` move the
  selection while the menu is open and jump through snippet fields when it is
  closed: inside a snippet an open menu takes the key, and `<C-e>` hides the
  menu to free it for the next field. Neither key accepts a completion — `<CR>`
  does — and the dadbod source is enabled for SQL filetypes only. `cancel` sits
  on `<C-CR>`: it closes the menu and stays in insert mode, and it reports back
  that it did nothing while the menu is closed, so the key keeps its normal
  meaning everywhere else. The terminal has to send Ctrl and Enter as one key of
  its own for that — Neovim asks for the "CSI u" encoding at startup
  (`:help tui-csiu`), and a terminal that supports neither it nor
  modifyOtherKeys sends a plain `<CR>`, which accepts the selection instead.
  `<Esc>` is left unmapped, so it leaves insert mode at once and the menu goes
  with it.
- **The `from` of an import or export comes from a source of its own.** After an
  unfinished `import x ` or `export * ` the only word that may follow is
  `from`, but a tsserver older than 5.0 answers that position with every
  identifier it knows, auto-imports included, and no `from` among them —
  `autoUseWorkspaceTsdk` hands vtsls the TypeScript of a trusted project, so
  the version that answers is the project's.
  `settings/completion/imports.lua` is a blink.cmp source that offers the
  keyword there itself, with a score offset above every other source, and the
  `transform_items` of the `lsp` provider drops the `from` a newer TypeScript
  sends for the same position, so the word is never offered twice. The clause
  is read from the line in front of the cursor, which keeps
  `export const x = ` and `export default ` out of it.
- **Four tools run a project's code only in a trusted root.** They would run
  JavaScript the repository ships: vtsls the `tsserver.js` under
  `node_modules/typescript`, eslint its `eslint.config.*` and the eslint under
  `node_modules`, prettier its config files and plugins, `:CoverageRun` the
  project's `test:cov` script. `core/trust.lua` holds the check, `allowed()` on
  the directory whose code would run, and `root()`, the `.git` directory above a
  buffer or else a `package.json` / `tsconfig.json` / `jsconfig.json` one, or a
  nested directory inside it that holds a config of its own (below). A buffer in
  neither has no root and is never trusted, so a stray directory such as `$HOME`
  is never asked about on its behalf.
  - vtsls: `before_init` turns `autoUseWorkspaceTsdk` on only when
    `<root>/node_modules/typescript/lib/tsserver.js` exists and its root, the
    one vtsls runs in, is trusted; otherwise vtsls uses the TypeScript it
    bundles.
  - eslint: `root_dir` runs nvim-lspconfig's own and calls `on_dir` only when
    the root that function found holds the buffer and is trusted. That root is
    where lspconfig looks for `node_modules/.bin/vscode-eslint-language-server`,
    so the directory asked about is the one whose code runs; lspconfig's
    fallback to the working directory never reaches a file outside it. The
    server also loads `eslint` and a flat config from parent directories, so
    every parent of the deeper of that root and the buffer's own root, below the
    home directory (or below `/` outside it), that holds an eslint config,
    `package.json` or `node_modules` must be trusted too, outermost first.
  - prettier: format on save and `<leader>cf` skip a buffer in an untrusted root
    (or none) when conform would run prettierd or prettier for it, Compose files
    included; the key says so in a notification. prettier looks for its config
    and plugins above the root as well, so every parent below the home directory
    (or below `/` outside it) that holds a prettier config, `package.json`,
    `package.yaml` or `node_modules` must be trusted too, outermost first.
    Buffers formatted by stylua or sql-formatter are not affected.
  - `:CoverageRun`: runs only from a working directory that holds a
    `package.json`. npm also reads the `.npmrc` and `node_modules/.bin` of
    parent directories, so every parent below the home directory (or below `/`
    outside it) that holds a `package.json`, `.npmrc` or `node_modules` must be
    trusted too, outermost first. The report loads only when the run rewrote it,
    no signal killed it and the working directory is unchanged; a failed run
    that wrote one loads it with a warning.
  - Not covered: neotest, nvim-dap (including a project's `.vscode/launch.json`)
    and kulala's request scripts run project code when their keys are pressed,
    without this check.

  The first time one of these tools needs a root, `trust.lua` asks: the
  prompt names the directory, says whether it is new or changed since it was
  allowed, and offers Allow, Deny and Ignore (the default). The answer is kept
  in `stdpath("state")/myconfig/trust.json` (directory 700, file 600):
  - Allow holds while the root's fingerprint (below) stays the same; any
    change asks again.
  - Deny holds whatever changes, until it is removed.
  - Ignore is not written down; the same root is not asked again in that
    session while the fingerprint stays the same.

  `:ProjectTrust` lists the decisions, `:ProjectTrust forget [dir]` removes
  one, and `:ProjectTrust deny [dir]` denies a directory without waiting for a
  prompt; `[dir]` defaults to the `.git` root of the current buffer (eslint
  may use a nested lockfile root instead: `list` shows the exact keys), else
  the working directory. The store is written to a temporary file and
  renamed over the old one, so two instances never leave it half-written. An
  answer
  reaches a server that is already running at its next start or
  `:lsp restart`. A headless run never asks and trusts nothing. Neovim's own
  `:trust` database is not used for project roots.

  The fingerprint covers what decides the code that runs:
  - the files at the root: `package.json`, `tsconfig.json`, `jsconfig.json`, the
    lockfiles, every eslint and prettier config file name (prettier also reads
    `package.yaml`), and the entry points started from `node_modules`
    (`typescript/lib/tsserver.js`, `_tsserver.js` and `typescript.js`,
    `.bin/vscode-eslint-language-server`, `.bin/prettier`, `.bin/prettierd`, the
    `package.json` of `eslint` and `prettier`), each by real path and SHA-256.
    Only a regular file inside the root, up to 64 MB, is read; a symlink out of
    the root, a FIFO or a device counts by its type and target alone, so a
    repository cannot make the check hang;
  - in a git repository, the index entries (`git ls-files --stage`) of every
    tracked `package.json`, `package.yaml`, `tsconfig*.json`, `jsconfig*.json`,
    eslint and prettier config and every tracked file under a `node_modules`
    directory, at any depth. A pull request that adds a nested config, a
    TypeScript plugin in `compilerOptions.plugins` of one of those files, or a
    commit into `node_modules` changes them, while an ordinary commit does not.
    A file a `tsconfig.json` reaches through `extends` under another name is not
    covered.

  So such a pull request, `npm install` replacing one of the entry points, or
  another repository cloned to an allowed path all ask again, while a fresh
  clone of the same content does not. File hashes are cached by size and
  times and the index listing by the index file, so a check after nothing
  changed costs a few dozen `stat` calls. Not covered: code a config imports
  (a local eslint rule, a prettier plugin kept in the repository), anything
  deeper in an installed `node_modules`, and a server that is already
  running, which re-reads its config without asking until its next start.
- **Git never runs a repository's `core.fsmonitor`.** That setting in
  `.git/config` names a program git runs on `git status`, `git diff` and
  `git ls-files`, which gitsigns calls as soon as a file opens. `core/env.lua`,
  loaded before anything else, adds `core.fsmonitor=false` to the environment
  (`GIT_CONFIG_COUNT` / `GIT_CONFIG_KEY_<n>` / `GIT_CONFIG_VALUE_<n>`), after
  any pairs already there, so every git started from Neovim, lazygit and
  terminal shells included, ignores it, unless a plugin replaces the whole
  environment of its process. Your own fsmonitor (watchman, git's built-in
  daemon) is off there too, so `git status` in a very large repository is
  slower. A restart finds the pair and does not add it twice. Other commands a
  `.git/config` can name, such as a `filter.<driver>.clean` that a committed
  `.gitattributes` assigns, still run: the fix covers `core.fsmonitor` only.
- **auto-session asks git for the branch through `vim.system`.** Its own lookup
  builds `git -C <directory>` as a shell string, so a directory named
  `x;cmd;y` ran `cmd` at startup. `git_use_branch_name` is a function that
  passes the directory as an argument instead and gives git two seconds, so a
  `.git/HEAD` that never answers cannot hang Neovim at start or exit; the
  session name keeps the branch, and a directory outside a repository gets
  none. auto-session's automatic save is skipped while a buffer name or a
  global, tab or window working directory holds a control character:
  `:mksession` writes a newline in a name as is, so a file named
  `a<newline>so.x` would turn into a `:source` of `.x` on the next restore. A
  save by hand (`:AutoSession save`, `:mksession`) is not checked.
- **Smaller hardening, one line each.**
  - Mason installs every server and tool at the version in `mason.servers` /
    `mason.tools` (`name@version`); `:checkhealth myconfig` shows the installed
    versions and warns on a different one. Updating is editing the pin and
    `:MasonInstall name@version`. The registry those versions are resolved
    from is pinned too: `registries` names
    `github:mason-org/mason-registry@<mason.registry>`, a release tag, so a new
    registry release changes nothing until the tag is bumped (edit the tag,
    then `:MasonUpdate`). The tag decides which registry is used; nothing
    verifies its content beyond the HTTPS download. The `@<tag>` form
    is read from Mason's source (`mason-registry/sources/init.lua`), not from
    its documentation: the one exception to the rule of documented options.
    npm packages still resolve their own dependencies without a lockfile.
  - kulala gets an explicit `kulala_core.path` that always exists: the binary
    when its SHA-256 matches `http.kulala_core_sha256`, else the `false`
    command, so requests fail with an error and kulala never downloads by
    itself (it downloads only when the configured path is missing). kulala loads
    on every `VimLeavePre` for its session hooks, so the check is cached in
    `stdpath("state")/myconfig/kulala-core.json` by the file's inode, size and
    times and hashes again only after the binary changed; it stays silent on
    exit. The kulala cache and kulala-core data directories, and `db_ui`, are
    made mode 700.
  - The lazy.nvim bootstrap checks out the commit `lazy-lock.json` names right
    after cloning `stable`. `npx --no` runs jest, vitest and ts-node, so a
    missing package is refused instead of fetched.
  - The DAP status in lualine escapes `%`: a launch configuration's name is
    project text, and lualine would evaluate a `%{…}` in it.
  - The rename keys (`grn`, `<leader>cr`, `<leader>rn`) put `<cword>` on the
    `:IncRename` line only when it is an identifier, with
    `replace_keycodes = false`: a word made of `<CR>` and `:!` cannot become
    keys.
  - The project scans skip files above `treesitter.max_filesize`
    (`rg --max-filesize`).
  - conform runs `node_modules/.bin/prettierd` or `prettier` only from the
    trusted root itself, whose fingerprint covers both, else the Mason binary.
    prettierd loads the `prettier` that Node resolves from the file, so it runs
    only when the root has its own `node_modules/prettier` and no
    `node_modules/prettier` (or `prettier.js`, `.json`, `.node`) lies between
    the file and the root; otherwise the `prettier` CLI, which uses its own
    copy, formats the file.
  - `trust.lua` sets Neovim's own `trust` file (still used for the lazygit
    configs) to mode 600 when it finds it readable by others, writes its store
    through a temporary file only when the write succeeded, and treats a
    directory inside a repository as a root of its own, asked about separately,
    when it holds a `package.json`, `package.yaml`, `tsconfig.json`,
    `jsconfig.json` or eslint or prettier config that git does not track (an
    archive unpacked into `tmp/`, or a `prettier.config.cjs` dropped next to a
    tracked `package.json`). Every directory from the file's up to the
    repository root is checked, and the deepest such directory becomes the root,
    so a config dropped a few levels above the file counts too; each check is
    cached by the directory's modification time, so a file added later is
    noticed. A buffer whose name is not an absolute path (`oil://`,
    `diffview://`, `term://`) keeps the repository root. Outside a repository
    nothing is tracked, so the deepest directory between the file and its
    `package.json` / `tsconfig.json` / `jsconfig.json` root that holds any of
    the files above becomes the root: a config added to an allowed tree later is
    asked about. eslint then needs both its root and that one. vtsls starts in
    it as well. A directory under `node_modules` stays part of the root above
    it, so following a definition into a dependency starts no new server and
    asks nothing. A git command slower than `trust.git_timeout_ms` keeps project
    code off without a prompt and says so once per session.
  - gitsigns and diffview run git without lazygit's check, so a hostile
    `.git` directory (from an archive, not a clone) can still run a
    `filter.*` or `diff.*` command when a file opens.
  - `edit_hex()` turns the path into an absolute one and refuses a name that
    starts like a URL scheme (`term:`, `zipfile:`).
- **nvim-autopairs** writes the closing bracket or quote to the right of the
  cursor, and `<BS>` on the opening one takes both away while the pair is still
  empty. It holds back where a closing character would be in the way: none is
  added in front of a word or of `%`, `'`, `[`, `"`, `.`, `` ` `` or `$`
  (`ignored_next_char`), typing the closing character over the one it added
  moves the cursor past it instead of doubling it, and nothing is paired while a
  macro is recorded or replayed, so a recorded `(` stays a single `(`. `<CR>`
  between the two halves opens an indented line between them: blink.cmp keeps
  the key for accepting a completion and falls back to nvim-autopairs whenever
  the menu is closed. `check_ts` stays off — its own rules already cover the
  quotes and brackets of these filetypes, and the treesitter check needs a list
  of node types per language — and `disable_filetype` names neo-tree's popup
  input, the one prompt here that takes insert-mode keys. `<C-w>` and `<C-h>`
  stay Vim's own (`map_c_w`, `map_c_h`).

## Known limitations

- **blink.cmp is pinned to 1.x** (`version = "1.*"`): v2 is still under heavy
  development, breaks this config and needs the separate blink.lib package.
- **nvim-treesitter follows the `main` branch**, a rewrite of the old `master`:
  it only installs parsers and queries, built locally with tree-sitter-cli, and
  the config switches highlighting, folds and indentation on per buffer.
- **No AI integration**, on purpose: no AI completion source, chat or ghost text.
- **Redis has no browser**: one-off commands go through `:DB redis://…`, and
  interactive work happens in `redis-cli` outside the editor.
- **Trouble, the debugger panel and the test output share one bottom split.**
  Starting a debug session closes Trouble, the panels take each other's place
  instead of stacking, and all of them use `ui.panel_height`.
- **kulala-core is pinned**: with `http.kulala_core_sha256` set, a missing or
  different binary turns HTTP requests off with an error; set the pin to `nil`
  for one start to let kulala download its backend (~100 MB, the first request
  fails while that runs), then pin the new hash.
- **The keymap scripts read the installed copy** in `~/.config/nvim`, not the
  checkout — run `./install.sh` before them.

## Repository layout

```
.
├── install.sh     # checks Neovim, copies nvim/ → ~/.config/nvim, creates codebook.toml
├── CLAUDE.md      # notes for Claude Code: architecture, rules, non-obvious decisions
├── KEYMAP.md      # every key binding, generated by scripts/dump-keymaps.lua
├── .codebook/     # spelling dictionary of this repository: its terms and identifiers
├── nvim/          # the configuration itself (becomes ~/.config/nvim)
├── scripts/       # maintenance: keymap audit and tables, cspell → codebook migration
└── http/          # .http request collections, kept outside nvim/ on purpose
```
