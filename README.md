# Neovim Configuration — Node.js / TypeScript Development

A minimal but fully functional Neovim setup for Node.js / TypeScript development
with LSP, Treesitter, autocompletion, formatting, fuzzy finding, and code-aware
spell checking via `cspell`.

## Prerequisites

### Required

| Dependency                        | Why                                        | Install                                                                                             |
| --------------------------------- | ------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| **Neovim 0.11+**                  | Core editor                                | [neovim.io/install](https://neovim.io/doc/user/installing.html)                                     |
| **Git 2.19+**                     | Plugin management, gitsigns                | `sudo apt install git`                                                                              |
| **Node.js 18+** and **npm**       | TypeScript/JavaScript LSP servers          | [nodejs.org](https://nodejs.org)                                                                    |
| **ripgrep**                       | Telescope `live_grep`                      | `sudo apt install ripgrep`                                                                          |
| **gcc** (or **clang**) + **make** | Compiles `telescope-fzf-native` at install | `sudo apt install build-essential`                                                                  |
| **lazygit**                       | `<leader>gg` Git UI                        | `sudo apt install lazygit` or [see releases](https://github.com/jesseduffield/lazygit#installation) |
| **xclip** (Linux)                 | System clipboard (`"+y`, `"+p`)            | `sudo apt install xclip`                                                                            |
| **A Nerd Font**                   | File-tree and status-line icons            | [nerdfonts.com](https://www.nerdfonts.com/) — set in your terminal                                  |

### Recommended

| Dependency | Why                                                                                  | Install                                                                                                  |
| ---------- | ------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------- |
| **fd**     | Faster file finding in Telescope and snacks picker (falls back to `find` without it) | Download the latest `.deb` from [github.com/sharkdp/fd/releases](https://github.com/sharkdp/fd/releases) |

Install `fd` from GitHub releases (the `apt` package is outdated):

```bash
VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest \
  | grep -oP '"tag_name": "v\K[^"]+')
curl -LO "https://github.com/sharkdp/fd/releases/download/v${VERSION}/fd_${VERSION}_amd64.deb"
sudo dpkg -i "fd_${VERSION}_amd64.deb"
rm "fd_${VERSION}_amd64.deb"
```

### npm global packages

Install after Node.js is set up:

```bash
npm install -g neovim tree-sitter-cli cspell
```

| Package           | Why                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------ |
| `neovim`          | Enables the Neovim Node.js provider (required for some plugins)                      |
| `tree-sitter-cli` | Compiles Treesitter parsers from source when pre-built binaries are unavailable      |
| `cspell`          | Spell-checker CLI invoked by `none-ls` + `cspell.nvim` for code-aware spell checking |

## Installation

Use the provided script for a one-step install:

```bash
./install.sh
```

The script backs up any existing `~/.config/nvim` to `~/.config/nvim.backup.<timestamp>`,
then copies this configuration in its place. It also creates the cspell user
dictionary at `~/.config/cspell/user-words.txt` (outside the nvim config tree
so it survives reinstalls). An existing dictionary is never overwritten.

### Manual installation

1. Back up any existing config:

   ```bash
   mv ~/.config/nvim ~/.config/nvim.backup
   mv ~/.local/share/nvim ~/.local/share/nvim.backup   # optional — clears cached plugins
   ```

2. Clone this repository and copy the `nvim/` directory:

   ```bash
   git clone <repo-url> ~/dev/tools/nvim-config
   cp -r ~/dev/tools/nvim-config/nvim ~/.config/nvim
   ```

3. Launch Neovim:

   ```bash
   nvim
   ```

   On the first launch, `lazy.nvim` bootstraps itself, clones every plugin, and
   `mason-lspconfig` installs the language servers. This takes 1–3 minutes — let it finish.

4. Quit and reopen Neovim, then verify:

   ```vim
   :checkhealth
   ```

## Installing formatters

Prettier and stylua are **not** installed automatically. Install them via Mason:

```vim
:Mason
```

Navigate to `prettier` and `stylua`, press `i` on each.

## Layout

```
nvim/
├── init.lua                      -- Entry point; sets leader key, loads config modules
├── cspell.json                   -- cspell config: language=en, user-words path, ignore patterns
├── lazy-lock.json                -- Pinned plugin versions
└── lua/
    ├── lazy-bootstrap.lua        -- Installs lazy.nvim on first run; loads plugin specs
    ├── config/
    │   ├── options.lua           -- Core editor options (indent, search, clipboard, undo)
    │   ├── keymaps.lua           -- Global keymaps (splits, scroll, save, visual paste)
    │   ├── autocmds.lua          -- Yank highlight, trailing-whitespace trim, cursor restore
    │   └── spell-filter.lua      -- Treesitter filter: cspell hints only on identifier definitions
    └── plugins/
        ├── lsp.lua               -- Mason + nvim-lspconfig (ts_ls, eslint, lua_ls, jsonls, yamlls)
        ├── completion.lua        -- nvim-cmp + LuaSnip + friendly-snippets
        ├── treesitter.lua        -- Syntax highlighting, smart indent, incremental selection
        ├── formatting.lua        -- conform.nvim: Prettier (TS/JS/JSON/YAML/HTML/CSS/MD), stylua
        ├── telescope.lua         -- Fuzzy finder: files, grep, buffers, symbols, help, diagnostics
        ├── spell.lua             -- cspell via none-ls + davidmh/cspell.nvim (code-aware spell check)
        ├── dadbod.lua            -- vim-dadbod + dadbod-ui + dadbod-completion (database client)
        └── ui.lua                -- catppuccin (mocha), lualine statusline, neo-tree file explorer
```

## Key mappings

The leader key is `<Space>`.

### General

| Key               | Action                                         | Description                                                                                                                                      |
| ----------------- | ---------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `<leader>w`       | Save file                                      | Writes the current buffer to disk (`:w`)                                                                                                         |
| `<leader>q`       | Close buffer                                   | Runs `:bdelete` and, if neo-tree is open in the current tab, hands focus to the tree so the editor area never sits on a stray `[No Name]` buffer |
| `<leader>nh`      | Clear search highlight                         | Clears the `hlsearch` highlight after a search                                                                                                   |
| `<C-d>` / `<C-u>` | Half-page scroll, cursor re-centred            | Scrolls half a page and keeps the cursor at the screen centre                                                                                    |
| `<A-j>` / `<A-k>` | Move selected lines down / up (Visual mode)    | Shifts the selected block one line down or up with auto-reindent                                                                                 |
| `p` (Visual)      | Paste without overwriting the unnamed register | Replaces the selection without losing the previously yanked text                                                                                 |

### Window navigation

| Key                             | Action              | Description                                       |
| ------------------------------- | ------------------- | ------------------------------------------------- |
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Move between splits | Focuses the left / down / up / right split window |

### File tree & Telescope

| Key          | Action                          | Description                                                               |
| ------------ | ------------------------------- | ------------------------------------------------------------------------- |
| `<leader>e`  | Toggle file explorer (neo-tree) | Opens or closes the side-panel file tree                                  |
| `<leader>ff` | Find files                      | Fuzzy-searches file names in the project root                             |
| `<leader>fg` | Live grep across project        | Full-text search via ripgrep; results update as you type                  |
| `<leader>fb` | Open buffers                    | Lists and switches between currently open buffers                         |
| `<leader>fs` | Document symbols (LSP)          | Shows all LSP symbols (functions, classes, variables) in the current file |
| `<leader>fd` | Diagnostics list                | Lists all LSP diagnostics (errors, warnings) across the project           |
| `<leader>fh` | Search Neovim help tags         | Fuzzy-searches Neovim's built-in help documentation                       |

### File explorer (neo-tree)

The file tree on the left is [`neo-tree.nvim`](https://github.com/nvim-neo-tree/neo-tree.nvim) (filesystem source). It auto-shows git status, LSP diagnostics, and file-type icons. Inside the tree, press `?` for the full keymap help — the most common defaults:

| Key (inside tree) | Action                                   | Description                                                                                                           |
| ----------------- | ---------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `<CR>`            | Open                                     | Opens the file under the cursor in the previous window                                                                |
| `s`               | Open in vertical split                   |                                                                                                                       |
| `S`               | Open in horizontal split                 |                                                                                                                       |
| `t`               | Open in new tab                          |                                                                                                                       |
| `<Space>`         | Toggle directory                         | Expands or collapses the directory under the cursor                                                                   |
| `a`               | Add file or directory                    | Append `/` to the prompt to create a directory                                                                        |
| `A`               | Add directory                            |                                                                                                                       |
| `d`               | Delete                                   | Confirms before deleting                                                                                              |
| `r`               | Rename                                   |                                                                                                                       |
| `y` / `x` / `p`   | Copy / cut / paste to internal clipboard | Inside-tree clipboard between directories                                                                             |
| `c` / `m`         | Copy-to / move-to                        | Prompts for the destination path                                                                                      |
| `H`               | Toggle hidden files                      | Dotfiles are hidden by default                                                                                        |
| `R`               | Refresh                                  |                                                                                                                       |
| `[g` / `]g`       | Previous / next git-modified file        |                                                                                                                       |
| `o`               | "Order by" submenu                       | Sort by name (`on`), type (`ot`), modified (`om`), size (`os`), git status (`og`), created (`oc`), diagnostics (`od`) |
| `i`               | Show file details                        | Size, mtime, permissions popup                                                                                        |
| `q`               | Close tree window                        |                                                                                                                       |
| `?`               | Show keymap help                         |                                                                                                                       |

Behavior:

- **Hidden files**: dotfiles **and** `.gitignore`-listed files are hidden by default. Toggle with `H` inside the tree.
- **Width**: ~20% of terminal width on startup (clamped to a 30-column minimum — sized once at config time, not auto-resized on `:resize`).
- **Closing files keeps the tree**: `close_if_last_window` is **off**, so `:q` / `:q!` / `ZZ` close the file window and leave the cursor on the tree instead of exiting Neovim. Use `:qa` (or close the tree first) when you actually want to quit.
- **`netrw` replacement**: opening a directory (`:edit src/`) routes to neo-tree instead of netrw.
- **Live FS updates**: external changes (git pulls, codegen) refresh the tree automatically via `libuv` watchers.

> Migrated from `nvim-tree.lua`. The global `<leader>e` toggle is unchanged. In-tree keys now follow neo-tree's defaults (e.g. `s` / `S` for splits instead of `<C-x>` / `<C-v>`); use `?` inside the tree for a complete reference.

### LSP (any file with an attached language server)

| Key          | Action                             | Description                                                             |
| ------------ | ---------------------------------- | ----------------------------------------------------------------------- |
| `gd`         | Go to definition                   | Jumps to where the symbol under the cursor is defined                   |
| `gD`         | Go to declaration                  | Jumps to the declaration of the symbol (e.g. type signatures)           |
| `gr`         | Find all references                | Lists every place the symbol is referenced in the project               |
| `gi`         | Go to implementation               | Jumps to the concrete implementation of an abstract or interface symbol |
| `K`          | Hover documentation                | Shows inline documentation for the symbol under the cursor              |
| `<leader>rn` | Rename symbol                      | Renames the symbol and all its references across the project            |
| `<leader>ca` | Code action                        | Opens a menu of available refactors and quick-fixes from the LSP        |
| `<leader>d`  | Show diagnostic in floating window | Displays the full diagnostic message for the current line in a popup    |
| `[d` / `]d`  | Previous / next diagnostic         | Moves the cursor to the previous or next diagnostic in the file         |

### Completion (Insert mode)

| Key                 | Action                                               | Description                                                             |
| ------------------- | ---------------------------------------------------- | ----------------------------------------------------------------------- |
| `<C-Space>`         | Trigger completion menu manually                     | Opens the completion popup without needing to type more characters      |
| `<C-j>` / `<C-k>`   | Next / previous item                                 | Selects the next or previous entry in the completion list               |
| `<Tab>` / `<S-Tab>` | Next / previous item, or jump through snippet fields | Cycles through items or moves between placeholders in an active snippet |
| `<CR>`              | Confirm selection                                    | Inserts the selected completion item and closes the menu                |
| `<C-e>`             | Close completion menu                                | Dismisses the popup without inserting anything                          |

### Treesitter incremental selection

| Key    | Action                                       | Description                                                                          |
| ------ | -------------------------------------------- | ------------------------------------------------------------------------------------ |
| `<CR>` | Start selection / expand to next syntax node | Begins a visual selection at the cursor or extends it to the surrounding syntax node |
| `<BS>` | Shrink selection to previous node            | Reduces the selection back to the previous (inner) syntax node                       |

### Database client (vim-dadbod)

A SQL client built on [`tpope/vim-dadbod`](https://github.com/tpope/vim-dadbod),
[`vim-dadbod-ui`](https://github.com/kristijanhusak/vim-dadbod-ui) (sidebar +
query buffers + result panes), and
[`vim-dadbod-completion`](https://github.com/kristijanhusak/vim-dadbod-completion)
(schema- and table-aware completion wired into nvim-cmp). Useful for poking at
the databases behind a NestJS / Node.js project without leaving the editor.

Supported drivers (commonly paired with NestJS): **PostgreSQL**, **MySQL /
MariaDB**, **SQLite**. vim-dadbod itself supports many more (Redis, MongoDB,
SQL Server, etc.) via Vim adapters — see the upstream README.

#### Adding a connection for the first time

1. Press `<leader>Du` to open the sidebar.
2. Press `A` (or run `:DBUIAddConnection`) and paste a connection URL:
   - PostgreSQL: `postgresql://user:pass@localhost:5432/dbname`
   - MySQL / MariaDB: `mysql://user:pass@localhost:3306/dbname`
   - SQLite: `sqlite:./dev.db`
3. Give the connection a name. It is saved to disk and re-appears in the
   sidebar on every launch.

For credentials you don't want on disk, export an environment variable and
reference it in the URL field:

```bash
export DATABASE_URL="postgresql://user:pass@localhost:5432/dbname"
```

then save the connection as `$DATABASE_URL`.

#### Persistence and backup

Connections, scratch queries, and bookmarks live under
`vim.fn.stdpath("data") .. "/db_ui"` (typically
`~/.local/share/nvim/db_ui/`). The path is **outside** `~/.config/nvim/` on
purpose — `install.sh` replaces the nvim config directory wholesale on every
run, so storing connections there would destroy them. Back up the `db_ui`
directory if you want to migrate to another machine.

#### Keymaps

Database commands live under the `<leader>D` namespace (capital D) to avoid
the timeout-len conflict with `<leader>d` (LSP "show diagnostic").

| Key          | Action                            | Description                                                |
| ------------ | --------------------------------- | ---------------------------------------------------------- |
| `<leader>Du` | Toggle DBUI sidebar               | Opens / closes the database explorer                       |
| `<leader>Df` | Find query buffer                 | Jump to an existing query buffer                           |
| `<leader>Dr` | Rename current query buffer       | Rename a `*.sql` scratch buffer                            |
| `<leader>Da` | Add a new connection              | Same as pressing `A` inside the sidebar                    |
| `<leader>Dq` | Show last query info              | Run-time, row count, error if any                          |

Inside a query buffer (`*.sql` opened from DBUI):

| Key            | Action                                         |
| -------------- | ---------------------------------------------- |
| `<leader>S`    | Execute the buffer (or visual selection)       |
| `<leader>W`    | Save the query as a named bookmark             |
| `<leader>E`    | Edit a bind variable                           |

These are dadbod-ui's own defaults — see `:help dadbod-ui` for the full list.

#### SQL completion

`vim-dadbod-completion` is registered as a **buffer-local** nvim-cmp source on
the `sql`, `mysql`, and `plsql` filetypes only — it does not appear in the
completion menu in TypeScript / Lua / etc. Triggers are the same as the rest
of nvim-cmp (`<C-Space>`, `<Tab>` / `<S-Tab>`, `<CR>` to confirm). Connect to a
database via the sidebar first; the completion source needs an active
connection to pull schemas and table / column names.

### Spell checking (cspell)

Spell errors are surfaced as **HINT-level** diagnostics, so they never inflate
the error or warning counts in the status line. They are reported by `cspell`
via `none-ls` and reuse the standard diagnostic keymaps:

| Key          | Action                             | Description                                                                                                          |
| ------------ | ---------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `<leader>ca` | Code action                        | Includes "Add word to user dictionary", "Add word to cspell.json", and "Use suggestion: …" entries on a flagged word |
| `[d` / `]d`  | Previous / next diagnostic         | Spell errors are diagnostics, so the standard jumps work                                                             |
| `<leader>d`  | Show diagnostic in floating window | Displays the cspell message for the current line                                                                     |

Highlights:

- **Language**: English only (`"language": "en"` in `nvim/cspell.json`).
- **Identifiers**: cspell natively splits camelCase / PascalCase / snake_case / SCREAMING_SNAKE_CASE before checking, so identifiers are spell-checked without extra parsing.
- **User dictionary**: `~/.config/cspell/user-words.txt` (kept outside `~/.config/nvim/` so `install.sh` cannot wipe it).
- **Project overrides**: a `cspell.json` at the project root (or any parent directory above the current file) takes precedence over the one shipped with this config.
- **Definitions-only filter**: in TypeScript / JavaScript files, spell warnings on identifier _usages_ (call expressions, member accesses, import specifiers, type references) are suppressed; warnings remain at _definition_ sites (declarations, parameters, class/interface/type/enum names, class properties). Fix the name once at its declaration and let LSP rename propagate it.

## Troubleshooting

- **LSP not attaching** — run `:LspInfo`. For `ts_ls`, the file must be inside a project with a `package.json` or `tsconfig.json`.
- **Formatters not running** — install `prettier` and `stylua` via `:Mason`.
- **Plugin errors on startup** — run `:Lazy sync` to reinstall all plugins.
- **Icons show as empty boxes** — your terminal is not using a Nerd Font.
- **ESLint not fixing on save** — verify `eslint` is installed (`:Mason`) and there is a valid ESLint config in the project root.
- **No spell-check diagnostics** — confirm `cspell --version` works in your shell. If not, `npm install -g cspell`. The plugin loads on `BufReadPre` / `BufNewFile`, so a freshly installed `cspell` is picked up after the next file open or `:e!`.
- **`Add to user dictionary` does nothing** — the dictionary file is `~/.config/cspell/user-words.txt`. Re-run `./install.sh` (or `mkdir -p ~/.config/cspell && touch ~/.config/cspell/user-words.txt`) and reopen the buffer.
- **General diagnosis** — `:checkhealth` reports everything Neovim can see.
