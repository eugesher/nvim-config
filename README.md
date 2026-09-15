# Neovim Configuration — NestJS Backend Development

An IDE-grade Neovim configuration for backend development on NestJS: TypeScript,
RabbitMQ, MySQL/TypeORM and API-gateway services. It bundles LSP, debugging,
tests, database and HTTP clients into a single keyboard-driven workflow.

## Environment requirements

### Required

| Dependency                      | Why                                                                                                                                                                   | Install                                                                                                                          |
| ------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Neovim 0.12+**                | Core editor; the config uses 0.12 APIs throughout                                                                                                                     | `sudo snap install nvim --classic`                                                                                               |
| **Git 2.31+**                   | Plugin management, gitsigns, neogit; diffview.nvim needs 2.31+                                                                                                        | `sudo apt install git`                                                                                                           |
| **Node.js 20+** and npm         | TS/JS language servers, prettierd, js-debug-adapter, tree-sitter-cli                                                                                                  | [nodejs.org](https://nodejs.org), or via `fnm` / `nvm`                                                                           |
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
| **kulala-core**                   | The engine behind the HTTP client: kulala 6.x runs every request through it. Downloaded automatically from GitHub releases on the first request into `~/.local/share/nvim/kulala.nvim/bin` (~100 MB), so a new machine needs network access once. That first request fails while the download runs — repeat it after the "Backend installed successfully" message |
| **jq**                            | Pretty-printing JSON responses in kulala                                                                                                                                                                                                                                                                                                                          |
| **libxml2-utils** (`xmllint`)     | Pretty-printing XML responses in kulala                                                                                                                                                                                                                                                                                                                           |
| **bat**                           | Syntax highlighting in picker previews (ships as `batcat`, needs a `bat` symlink)                                                                                                                                                                                                                                                                                 |
| **git-delta**                     | Syntax highlighting for git diffs in picker previews                                                                                                                                                                                                                                                                                                              |

### Installed automatically via `:Mason`

`vtsls`, `eslint-lsp`, `lua-language-server`, `json-lsp`, `yaml-language-server`,
`docker-language-server`, `dockerfile-language-server`, `codebook`,
`bash-language-server`, `prettierd`, `prettier`, `stylua`, `js-debug-adapter`.

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
| Completion and snippets | blink.cmp, LuaSnip, friendly-snippets                                                                                                                                        |
| Formatting              | conform.nvim with prettierd / prettier and stylua                                                                                                                            |
| Treesitter              | nvim-treesitter (`main`), nvim-treesitter-textobjects, nvim-treesitter-context                                                                                               |
| Picker                  | fzf-lua, also behind `vim.ui.select`                                                                                                                                         |
| Files                   | neo-tree (project tree), oil.nvim (directory as an editable buffer)                                                                                                          |
| Code structure          | aerial (symbol tree), dropbar (breadcrumbs in the winbar), nvim-origami (fold line counts, auto-folded imports and comments)                                                 |
| Git                     | gitsigns, neogit, diffview.nvim, git-conflict.nvim                                                                                                                           |
| Database                | vim-dadbod, vim-dadbod-ui, vim-dadbod-completion                                                                                                                             |
| HTTP client             | kulala.nvim                                                                                                                                                                  |
| Debugging               | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, js-debug-adapter                                                                                                             |
| Tests and coverage      | neotest (jest, vitest adapters), nvim-coverage                                                                                                                               |
| Problems                | trouble.nvim, todo-comments.nvim                                                                                                                                             |
| Refactoring             | inc-rename.nvim, refactoring.nvim, multicursor.nvim                                                                                                                          |
| Sessions                | auto-session                                                                                                                                                                 |
| Spelling                | codebook — a language server                                                                                                                                                 |

## Configuration structure

```
nvim/
├── init.lua              # leaders, version guard, vim.loader, then core and lazy.nvim
├── lazy-lock.json        # exact plugin commits — part of the config
├── stylua.toml           # formatting of every Lua file (2 spaces, width 100)
├── lua/
│   ├── core/             # the editor itself, no plugins: options, keymaps,
│   │                     # autocmds, diagnostics, filetypes, lazy.nvim bootstrap
│   ├── plugins/          # thin lazy.nvim specs, one file per area
│   ├── settings/         # the configuration of every plugin
│   │   ├── init.lua      # settings.spec(): a lazy.nvim spec from a settings module
│   │   ├── icons.lua     # every glyph of the config
│   │   ├── <group>/      # one folder per plugins/<group>.lua, one file per plugin:
│   │   │                 # completion/blink.lua, git/neogit.lua, ui/theme.lua, …
│   │   └── lsp/          # lspconfig.lua (server list), mason.lua, capabilities,
│   │                     # LspAttach keymaps, servers/<name>.lua per language server
│   ├── user/settings.lua # the values meant to be changed (next section)
│   └── myconfig/health.lua  # :checkhealth myconfig
└── after/ftplugin/       # buffer-local keymaps of .http and .sql buffers
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
- **`after/ftplugin/`** holds keymaps that belong to one filetype.

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
| `ui.border`                                                  | border of every floating window (`'winborder'`): `none`, `single`, `double`, `rounded`, `solid`, `shadow`, `bold`                                                                        |
| `ui.panel_height`                                            | height in lines of the bottom panels — Trouble, debugger, test output — which share one split                                                                                            |
| `ui.nerd_font`                                               | the terminal uses a Nerd Font v3; Neovim cannot see the font, so `:checkhealth myconfig` trusts this flag — set `false` without one                                                      |
| `colorscheme.enabled`                                        | `false` drops catppuccin and every color tweak of the config: Neovim's default colorscheme, each plugin with its own colors, the other `colorscheme.*` values ignored                    |
| `colorscheme.flavour`                                        | catppuccin flavor: latte, frappe, macchiato, mocha                                                                                                                                       |
| `colorscheme.transparent`                                    | let the terminal background show through the editor surfaces instead of `window_bg`                                                                                                      |
| `colorscheme.transparent_floats`                             | the same for floating windows: which-key, pickers, hover docs; the completion menu follows `transparent`                                                                                 |
| `colorscheme.window_bg`                                      | base background of windows, panels and floats                                                                                                                                            |
| `treesitter.max_filesize`, `max_line_length`                 | buffers larger than this many bytes, or with a longer line, get no treesitter highlighting or indentation, and no treesitter or LSP folds (manual folds only)                            |
| `folding.auto_fold_kinds`                                    | LSP fold kinds closed when a file is opened: `comment`, `imports`, `region`; `{}` turns auto-folding off                                                                                 |
| `formatting.format_on_save`                                  | format on save; toggle with `<leader>uf` (buffer) / `<leader>uF` (global) or `:FormatDisable[!]` / `:FormatEnable[!]`                                                                    |
| `formatting.timeout_ms`, `max_filesize`                      | milliseconds a formatter may block a save; files larger than `max_filesize` bytes are saved unformatted                                                                                  |
| `explorer.position`, `width`, `min_width`, `hide_gitignored` | neo-tree panel on the `"left"` or `"right"`; `width` is columns or a share of the editor width (`"25%"`) taken at each open, never below `min_width` columns; `H` shows gitignored files |
| `http.default_env`                                           | kulala environment on startup, a key of `http/http-client.env.json` (`<leader>he` switches)                                                                                              |
| `coverage.command`                                           | command that writes `coverage/lcov.info`, run by `:CoverageRun`; the report loads when it finishes                                                                                       |
| `database.position`, `width`                                 | vim-dadbod-ui drawer on the `"left"` or `"right"`, width in columns                                                                                                                      |
| `lsp.inlay_hints`                                            | inlay hints on attach; `<leader>ui` toggles per buffer                                                                                                                                   |
| `lsp.disable_watchers`                                       | stop advertising file watching: less CPU for ESLint and TypeScript servers in huge monorepos, but files changed outside the editor go unnoticed                                          |

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
`~/.config/nvim`, so `install.sh` never touches them.

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
  or one variable per connection, `DB_UI_<NAME>=mysql://…`.
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
  `codebook.toml`) and `Add to global dictionary` (the global one), along with
  the spelling suggestions.
- **`<leader>us`** turns the checker off and on for the session.
- **Dictionaries live outside `~/.config/nvim`**, which `install.sh` replaces
  wholesale: the global one is `~/.config/codebook/codebook.toml`, the project
  one is `codebook.toml` at the project root.
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
- **`<leader>1` … `<leader>9` use `bufferline.go_to(i, true)`**, the absolute
  position shown on the tab; `:BufferLineGoToBuffer` counts only visible tabs.
  Buffers are closed only through `safe_buffer_delete` (bufdelete.nvim), which
  keeps the window layout.
- **lualine escapes `%` in LSP progress text** (`" 45%: Loading"` is E539 in
  `'statusline'`); its nvim-dap and neotest components stay empty until those
  plugins are loaded and never load them.

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
- **The LSP log is off** (`vim.lsp.log.set_level(vim.log.levels.OFF)`): it grows
  to gigabytes. Turn it on only to debug a server.
- **codebook:** `<leader>us` stops the server rather than hiding its
  diagnostics, since a disabled diagnostic namespace is still counted by
  `vim.diagnostic.count()` and the status line would keep showing it.
  `exit_timeout = 500`, because the server never exits on its own.

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
  choices → `<leader>gx…`, `<C-A-d>` → `<localleader>d`. neogit's GUI and Alt
  keys likewise move to the localleader layer, and its `]c` / `[c` to `]o` / `[o`.
- **neogit creates its buffer keys without descriptions**, so which-key showed
  them blank or with Vim's own meaning (`l` as "Right"). A `FileType` autocmd in
  `settings/git/neogit.lua` waits until neogit has mapped a buffer and describes
  every key that `mappings` binds to an action, through `maparg()` / `mapset()`
  with the mapping itself unchanged. The status buffer gets all status actions;
  the commit, log, reflog, refs and stash views only those they take from it
  (close, open, peek, scroll, yank, fold, refresh), because keys such as `o` and
  `x` mean something else there. Popup buffers are left alone: they print their
  keys themselves. Keys neogit maps outside the documented `mappings` (`R`, `V`,
  `+`, `<Esc>`, `o` in the log and commit views) stay without a description, and
  `zc` / `zC` / `zO` keep which-key's fold descriptions.
- **neo-tree** loads on the first directory buffer (with netrw off, `nvim .`
  would otherwise open an empty buffer), sends `workspace/didRenameFiles` so vtsls
  fixes imports after a rename, and takes its width from a function: neo-tree
  also does arithmetic on the raw value, which a `"25%"` string breaks.
  **oil's `default_file_explorer` stays `false`**, or `nvim .` opens oil instead
  of the tree.
- **fzf-lua's key tables replace the defaults** rather than extend them: the
  defaults bind Alt combinations. `vim.ui.select` is a stub that loads fzf-lua on
  the first call.
- **dropbar** narrows treesitter `valid_types` to declarations: the defaults also
  match `class_body`, `property_identifier` and statements, which push the class
  and the method out of `max_depth`. Its preview recenters through
  `winrestview()`, because `:normal` closes the fuzzy prompt. The filter in its
  menus needs the C library of telescope-fzf-native.nvim.
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
  diagnostics and git changes on a closed fold (hidden in neogit buffers),
  auto-folded comments and imports, and folds paused while searching — it removes
  `search` from `'foldopen'` and keeps only the fold under the cursor open once
  the search is over. Its `h` / `l` / `^` / `$` keymaps stay off. Auto-folding
  works through LSP folds only and does not reach the file Neovim starts with;
  files opened later are folded.
- **Trouble:** `<leader>xX` leaves out diagnostics from TypeScript's library
  sources (lib.dom.d.ts alone brings some eighty hints); the LSP lists report an
  empty result, so `grr` on an unreferenced symbol is not silent.
- **refactoring.nvim** keys are operators (`expr` mappings), except the menu of
  all refactors: opening a window while an `expr` mapping is evaluated fails
  with E565.
- **vim-dadbod-ui** notifications use its own floats, not `vim.notify`: with
  Neovim's handler an error becomes a Vimscript trace inside the plugin. MySQL
  table helpers use `{dbname}`, because `{schema}` is empty when the URL names a
  database, and the hidden system schemas are anchored regexes.
- **kulala**'s `pathresolver` keeps its documented default although 6.x never
  calls it: kulala-core resolves request variables itself.
- **blink.cmp** uses the prebuilt Rust matcher of the pinned tag; without network
  access set its implementation to `"lua"`. `<Tab>` / `<S-Tab>` only jump through
  snippet fields and never accept a completion, and the dadbod source is enabled
  for SQL filetypes only.

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
- **The first HTTP request needs the network**: kulala downloads its backend (kulala-core, ~100 MB) and that request
  fails while the download runs.
- **The keymap scripts read the installed copy** in `~/.config/nvim`, not the
  checkout — run `./install.sh` before them.

## Repository layout

```
.
├── install.sh     # checks Neovim, copies nvim/ → ~/.config/nvim, creates codebook.toml
├── CLAUDE.md      # notes for Claude Code: architecture, rules, non-obvious decisions
├── KEYMAP.md      # every key binding, generated by scripts/dump-keymaps.lua
├── codebook.toml  # spelling dictionary of this repository: its terms and identifiers
├── nvim/          # the configuration itself (becomes ~/.config/nvim)
├── scripts/       # maintenance: keymap audit and tables, cspell → codebook migration
└── http/          # .http request collections, kept outside nvim/ on purpose
```
