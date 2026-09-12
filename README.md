# Neovim Configuration — NestJS Backend Development

An IDE-grade Neovim configuration for backend development on NestJS: TypeScript,
RabbitMQ, MySQL/TypeORM and API-gateway services. It bundles LSP, debugging,
tests, database and HTTP clients into a single keyboard-driven workflow.

## Environment requirements

### Required

| Dependency | Why | Install |
| --- | --- | --- |
| **Neovim 0.12+** | Core editor; the config uses 0.12 APIs throughout | `sudo snap install nvim --classic` |
| **Git 2.31+** | Plugin management, gitsigns, neogit; diffview.nvim needs 2.31+ | `sudo apt install git` |
| **Node.js 20+** and npm | TS/JS language servers, prettierd, js-debug-adapter, tree-sitter-cli | [nodejs.org](https://nodejs.org), or via `fnm` / `nvm` |
| **tree-sitter-cli ≥ 0.26.1** | The `main` branch of nvim-treesitter builds parsers with it | `npm install -g tree-sitter-cli` |
| **build-essential** (gcc, make) | Builds LuaSnip's `jsregexp`, treesitter parsers and telescope-fzf-native.nvim — the C fzf library behind the filter in dropbar's menus (telescope itself is not used) | `sudo apt install build-essential` |
| **curl** | Downloads by Mason and by kulala for its backend | `sudo apt install curl` |
| **ripgrep** | Live grep in fzf-lua | `sudo apt install ripgrep` |
| **fd-find** | File traversal in fzf-lua (ships as `fdfind`, needs an `fd` symlink) | `sudo apt install fd-find` |
| **fzf > 0.36** | Picker engine behind fzf-lua | `sudo apt install fzf` |
| **A Nerd Font** (v3) | Icons in the file tree, status line, pickers and breadcrumbs | [nerdfonts.com](https://www.nerdfonts.com/) — select it in your terminal; `ui.nerd_font` in `lua/user/settings.lua` records that |
| **wl-clipboard** or **xclip** | System clipboard integration | `sudo apt install wl-clipboard` |

### Optional — per feature

| Dependency | What it enables |
| --- | --- |
| **inotify-tools** (`inotifywait`) | Fast file watching for language servers (vtsls, ESLint). Without it Neovim on Linux falls back to a slower per-directory watcher |
| **mysql-client** | MySQL database client for vim-dadbod |
| **redis-tools** (`redis-cli`) | One-off `:DB redis://…` commands and interactive Redis work in a separate terminal window |
| **kulala-core** | The engine behind the HTTP client: kulala 6.x runs every request through it. Downloaded automatically from GitHub releases on the first request into `~/.local/share/nvim/kulala.nvim/bin` (~100 MB), so a new machine needs network access once. That first request fails while the download runs — repeat it after the "Backend installed successfully" message |
| **jq** | Pretty-printing JSON responses in kulala |
| **libxml2-utils** (`xmllint`) | Pretty-printing XML responses in kulala |
| **bat** | Syntax highlighting in picker previews (ships as `batcat`, needs a `bat` symlink) |
| **git-delta** | Syntax highlighting for git diffs in picker previews |

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

| Area | Tooling |
| --- | --- |
| Plugin manager | lazy.nvim, versions pinned by `nvim/lazy-lock.json` |
| Colorscheme and UI | catppuccin, lualine, bufferline, which-key, indent-blankline, nvim-web-devicons |
| LSP | Neovim's client with nvim-lspconfig: vtsls, ESLint, lua_ls, jsonls (+ SchemaStore), yamlls, bashls, docker-language-server, dockerls; Mason and mason-lspconfig install them |
| Completion and snippets | blink.cmp, LuaSnip, friendly-snippets |
| Formatting | conform.nvim with prettierd / prettier and stylua |
| Treesitter | nvim-treesitter (`main`), nvim-treesitter-textobjects, nvim-treesitter-context |
| Picker | fzf-lua, also behind `vim.ui.select` |
| Files | neo-tree (project tree), oil.nvim (directory as an editable buffer) |
| Code structure | aerial (symbol tree), dropbar (breadcrumbs in the winbar) |
| Git | gitsigns, neogit, diffview.nvim, git-conflict.nvim |
| Database | vim-dadbod, vim-dadbod-ui, vim-dadbod-completion |
| HTTP client | kulala.nvim |
| Debugging | nvim-dap, nvim-dap-view, nvim-dap-virtual-text, js-debug-adapter |
| Tests and coverage | neotest (jest, vitest adapters), nvim-coverage |
| Problems | trouble.nvim, todo-comments.nvim |
| Refactoring | inc-rename.nvim, refactoring.nvim, multicursor.nvim |
| Sessions | auto-session |
| Spelling | codebook — a language server |

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
│   ├── settings/         # the configuration of every plugin, one file per plugin
│   │   └── lsp/          # servers list, Mason, capabilities, LspAttach keymaps,
│   │                     # servers/<name>.lua per language server
│   ├── user/settings.lua # the values meant to be changed (next section)
│   └── myconfig/health.lua  # :checkhealth myconfig
└── after/ftplugin/       # buffer-local keymaps of .http and .sql buffers
```

The layers never mix:

- **`lua/plugins/`** only says *which* plugin: repository, dependencies, build
  step, branch or version. Each spec is built with
  `require("settings").spec("folke/trouble.nvim", "trouble")`.
- **`lua/settings/<name>.lua`** says *how*: it returns
  `{ event / ft / cmd / keys, opts, init, config, which_key }`, and everything a
  plugin is configured with lives there — options, keymaps with their
  descriptions, highlights are the one exception and sit in `settings/theme.lua`.
  Options are written out in full, defaults included, but only the documented
  ones; the first line of every file names the plugin version they were checked
  against.
- **`lua/core/`** holds what Neovim does without any plugin.
- **`after/ftplugin/`** holds keymaps that belong to one filetype.

## Customization

`nvim/lua/user/settings.lua` is the single place meant for personal values —
plain data the rest of the config reads:

| Setting | Default | Effect |
| --- | --- | --- |
| `editor.indent_width` | `2` | `'shiftwidth'`, `'tabstop'`, `'softtabstop'` |
| `editor.scrolloff` | `8` | lines kept above and below the cursor |
| `editor.relative_number` | `true` | relative line numbers |
| `ui.border` | `"rounded"` | border of every floating window (`'winborder'`) |
| `ui.panel_height` | `12` | height of the bottom panels: Trouble, debugger, test output |
| `ui.nerd_font` | `true` | set to `false` without a Nerd Font; `:checkhealth myconfig` then reminds you |
| `colorscheme.flavour` | `"mocha"` | catppuccin flavour: latte, frappe, macchiato, mocha |
| `colorscheme.transparent` | `false` | let the terminal background show through |
| `colorscheme.window_bg` | `"#000000"` | base background of windows, panels and floats |
| `treesitter.max_filesize`, `max_line_length` | 1.5 MB, 2000 | larger files get no treesitter |
| `formatting.format_on_save` | `true` | toggle with `<leader>uf` (buffer) / `<leader>uF` (global) |
| `formatting.timeout_ms`, `max_filesize` | 3000, 1 MB | how long a formatter may block a save; larger files are not formatted |
| `explorer.position`, `width`, `hide_gitignored` | `"left"`, 34, `true` | neo-tree panel |
| `http.default_env` | `"dev"` | kulala environment on startup |
| `coverage.command` | `npm run test:cov` | what `:CoverageRun` executes |
| `database.position`, `width` | `"left"`, 40 | vim-dadbod-ui drawer |
| `lsp.inlay_hints` | `true` | inlay hints; `<leader>ui` toggles per buffer |
| `lsp.disable_watchers` | `false` | stop file watching to save CPU in huge monorepos |

Edit the file in the repository and run `./install.sh` again — an edit made in
`~/.config/nvim` is lost on the next reinstall.

## Key bindings

`<leader>?` in the editor lists the keys of the current buffer. The tables below
cover the whole configuration, and two scripts keep them and the scheme honest.
Both read the installed config (`~/.config/nvim`), so run `./install.sh` first:

- **`nvim --headless -l scripts/audit-keymaps.lua`** loads every plugin, opens a
  `.ts`, `.lua`, `.sql`, `.http`, `.yml` and `Dockerfile` buffer with their
  language servers attached, and checks every keymap: a key defined twice or
  hiding a global one, two keys sharing one description, a key that is also the
  start of longer ones without being a which-key group, a keymap without a
  description, and the key policy — nothing on Alt but `<A-j>` / `<A-k>`,
  `]n` `[n` `an` `in` `]c` `[c` left to Neovim, `<leader>a` and `<leader>gL`
  kept free, only groups in `settings/whichkey.lua`. Deliberate exceptions sit
  in the whitelist at the top of the script, each with its reason; exit code 1
  means a new problem. `--list` prints every keymap it looked at.
- **`nvim --headless -l scripts/dump-keymaps.lua --readme`** rebuilds the tables
  below from the keymaps that actually exist.

Keys that exist only for a moment are not listed: the multicursor layer
(`<Tab>` / `<S-Tab>` between cursors, `<C-q>`, `<Esc>`) and the keys inside
plugin panels (`?` or `g?` shows them there).

<!-- keymaps:start -->

_Generated by `scripts/dump-keymaps.lua` from the keymaps that exist once every
plugin is loaded — do not edit by hand. Rebuild after `./install.sh` with
`nvim --headless -l scripts/dump-keymaps.lua --readme`. Leader is `Space`,
local leader is `\`. Modes: n normal, x visual, s select, o operator-pending,
i insert, t terminal. "Buffer" lists the filetypes where a key is
buffer-local (LSP keys appear once a language server is attached)._

### General

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<` | x | Indent left, keep selection |  |
| `<Esc>` | n | Clear search highlight |  |
| `<leader>?` | n | Buffer keymaps (which-key) |  |
| `<leader>Q` | n | Quit all |  |
| `<leader>w` | n | Write buffer |  |
| `<M-j>` | n | Move line down |  |
| `<M-j>` | x | Move selection down |  |
| `<M-k>` | n | Move line up |  |
| `<M-k>` | x | Move selection up |  |
| `>` | x | Indent right, keep selection |  |
| `a=` | x o | Around assignment |  |
| `aa` | x o | Around parameter |  |
| `ac` | x o | Around class |  |
| `af` | x o | Around function |  |
| `ai` | x o | Around conditional |  |
| `al` | x o | Around loop |  |
| `i=` | x o | Inside assignment |  |
| `ia` | x o | Inside parameter |  |
| `ic` | x o | Inside class |  |
| `if` | x o | Inside function |  |
| `ii` | x o | Inside conditional |  |
| `il` | x o | Inside loop |  |
| `J` | n | Join lines (keep cursor) |  |
| `p` | x | Paste without overwriting the register |  |

### Navigation

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<C-D>` | n | Half page down (centered) |  |
| `<C-Down>` | n | Decrease window height |  |
| `<C-H>` | n | Go to left window |  |
| `<C-J>` | n | Go to lower window |  |
| `<C-K>` | n | Go to upper window |  |
| `<C-L>` | n | Go to right window |  |
| `<C-Left>` | n | Decrease window width |  |
| `<C-Right>` | n | Increase window width |  |
| `<C-U>` | n | Half page up (centered) |  |
| `<C-Up>` | n | Increase window height |  |
| `<leader>1` | n | Go to buffer 1 |  |
| `<leader>2` | n | Go to buffer 2 |  |
| `<leader>3` | n | Go to buffer 3 |  |
| `<leader>4` | n | Go to buffer 4 |  |
| `<leader>5` | n | Go to buffer 5 |  |
| `<leader>6` | n | Go to buffer 6 |  |
| `<leader>7` | n | Go to buffer 7 |  |
| `<leader>8` | n | Go to buffer 8 |  |
| `<leader>9` | n | Go to buffer 9 |  |
| `<leader>b<` | n | Move buffer left |  |
| `<leader>b>` | n | Move buffer right |  |
| `<leader>bD` | n | Delete buffer (force) |  |
| `<leader>bd` | n | Delete buffer |  |
| `<leader>bo` | n | Delete other buffers |  |
| `<leader>bP` | n | Toggle pin |  |
| `<leader>bp` | n | Pick buffer |  |
| `<leader>q` | n | Delete buffer |  |
| `[a` | n x o | Previous parameter |  |
| `[b` | n | Previous buffer |  |
| `[f` | n x o | Previous function |  |
| `[q` | n | :cprevious |  |
| `]a` | n x o | Next parameter |  |
| `]b` | n | Next buffer |  |
| `]f` | n x o | Next function |  |
| `]q` | n | :cnext |  |
| `N` | n | Previous match (centered) |  |
| `n` | n | Next match (centered) |  |

### LSP / Code

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<C-W>d` | n | Show diagnostics under the cursor |  |
| `<leader>ca` | n x | Code action | every file buffer |
| `<leader>cD` | n | Buffer diagnostics to loclist | every file buffer |
| `<leader>cd` | n | Line diagnostics | every file buffer |
| `<leader>cf` | n x | Format buffer / selection |  |
| `<leader>cL` | n | Toggle code lenses | lua, typescript, yaml.docker-compose |
| `<leader>cl` | n | Run code lens | lua, typescript, yaml.docker-compose |
| `<leader>cM` | n x | Move to file | typescript |
| `<leader>cm` | n | Add missing imports | typescript |
| `<leader>co` | n | Organize imports | typescript |
| `<leader>cr` | n | Rename symbol (live preview) | dockerfile, lua, typescript, yaml.docker-compose |
| `<leader>cs` | n | Source actions | typescript |
| `<leader>cu` | n | Remove unused imports | typescript |
| `[D` | n | Jump to the first diagnostic in the current buffer |  |
| `[d` | n | Jump to the previous diagnostic in the current buffer |  |
| `[e` | n | Previous error |  |
| `]D` | n | Jump to the last diagnostic in the current buffer |  |
| `]d` | n | Jump to the next diagnostic in the current buffer |  |
| `]e` | n | Next error |  |
| `gd` | n | Go to definition | dockerfile, lua, typescript, yaml.docker-compose |
| `gO` | n | vim.lsp.buf.document_symbol() |  |
| `gra` | n x | vim.lsp.buf.code_action() |  |
| `gri` | n | Implementations | lua, typescript |
| `grn` | n | Rename symbol (live preview) | dockerfile, lua, typescript, yaml.docker-compose |
| `grr` | n | References (Trouble) | lua, typescript |
| `grt` | n | Type definition | lua, typescript |
| `grx` | n | vim.lsp.codelens.run() |  |
| `gs` | n | Go to source definition | typescript |
| `K` | n | vim.lsp.buf.hover() | dockerfile, lua, typescript, yaml.docker-compose |

### Find

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>f/` | n | Lines in buffer |  |
| `<leader>fb` | n | Buffers |  |
| `<leader>fc` | n | Commands |  |
| `<leader>fD` | n | Workspace diagnostics |  |
| `<leader>fd` | n | Buffer diagnostics |  |
| `<leader>fF` | n | Files (incl. ignored) |  |
| `<leader>ff` | n | Files |  |
| `<leader>fG` | n | Live grep (rg --glob) |  |
| `<leader>fg` | n | Live grep |  |
| `<leader>fh` | n | Help tags |  |
| `<leader>fk` | n | Keymaps |  |
| `<leader>fo` | n | Outline symbols |  |
| `<leader>fq` | n | Quickfix list |  |
| `<leader>fR` | n | Resume last picker |  |
| `<leader>fr` | n | Recent files |  |
| `<leader>fS` | n | Workspace symbols |  |
| `<leader>fs` | n | Document symbols |  |
| `<leader>fw` | n | Grep word under cursor |  |
| `<leader>fw` | x | Grep selection |  |

### Explorer

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `-` | n | Parent directory (oil) |  |
| `<leader>be` | n | Buffers (explorer) |  |
| `<leader>E` | n | Explorer: reveal file |  |
| `<leader>e` | n | Explorer |  |

### Git

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>gB` | n | Blame (file) | lua |
| `<leader>gb` | n | Git branches |  |
| `<leader>gC` | n | Git commits |  |
| `<leader>gc` | n | Commit |  |
| `<leader>gD` | n | Close diff view |  |
| `<leader>gd` | n | Diff view (all changes) |  |
| `<leader>ge` | n | Git status (explorer) |  |
| `<leader>gF` | n | Repository history |  |
| `<leader>gf` | n | File history |  |
| `<leader>gg` | n | Neogit (status) |  |
| `<leader>ghb` | n | Blame line | lua |
| `<leader>ghD` | n | Diff against last commit | lua |
| `<leader>ghd` | n | Diff against index | lua |
| `<leader>ghi` | n | Preview hunk inline | lua |
| `<leader>ghp` | n | Preview hunk | lua |
| `<leader>ghq` | n | All hunks to quickfix | lua |
| `<leader>ghR` | n | Reset buffer | lua |
| `<leader>ghr` | n | Reset hunk | lua |
| `<leader>ghr` | x s | Reset lines | lua |
| `<leader>ghS` | n | Stage buffer | lua |
| `<leader>ghs` | n | Stage / unstage hunk | lua |
| `<leader>ghs` | x s | Stage / unstage lines | lua |
| `<leader>ghU` | n | Unstage buffer | lua |
| `<leader>gl` | n | Log |  |
| `<leader>gm` | n | Merge tool (conflicts) |  |
| `<leader>gP` | n | Pull |  |
| `<leader>gp` | n | Push |  |
| `<leader>gS` | n | Git stash |  |
| `<leader>gs` | n | Git status |  |
| `<leader>gtb` | n | Toggle line blame | lua |
| `<leader>gtw` | n | Toggle word diff | lua |
| `<leader>gxq` | n | Conflicts to quickfix |  |
| `[h` | n | Previous hunk | lua |
| `]h` | n | Next hunk | lua |
| `ah` | x o | Hunk | lua |
| `ih` | x o | Hunk | lua |

### Database

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>Da` | n | Add connection |  |
| `<leader>Df` | n | Find buffer in drawer |  |
| `<leader>Dq` | n | Last query info |  |
| `<leader>Dr` | n | Rename buffer |  |
| `<leader>Du` | n | Toggle drawer |  |
| `<LocalLeader>e` | n | Edit bind parameters | sql |
| `<LocalLeader>w` | n | Save query | sql |
| `<LocalLeader>X` | n | Execute buffer | sql |
| `<LocalLeader>x` | n | Execute statement under cursor | sql |
| `<LocalLeader>x` | x | Execute selection | sql |

### Debug

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<F10>` | n | Debug: step over |  |
| `<F11>` | n | Debug: step into |  |
| `<F5>` | n | Debug: continue / start |  |
| `<leader>da` | n | Attach to process |  |
| `<leader>dB` | n | Conditional breakpoint |  |
| `<leader>db` | n | Toggle breakpoint |  |
| `<leader>dC` | n | Run to cursor |  |
| `<leader>dc` | n | Continue / start |  |
| `<leader>de` | n x | Evaluate expression |  |
| `<leader>df` | n | Frames |  |
| `<leader>di` | n | Step into |  |
| `<leader>dj` | n | Down the stack |  |
| `<leader>dk` | n | Up the stack |  |
| `<leader>dl` | n | Run last configuration |  |
| `<leader>dO` | n | Step out |  |
| `<leader>do` | n | Step over |  |
| `<leader>dp` | n | Log point |  |
| `<leader>dr` | n | Toggle REPL |  |
| `<leader>ds` | n | Scopes |  |
| `<leader>dt` | n | Terminate session |  |
| `<leader>du` | n | Toggle debugger panel |  |
| `<leader>dv` | n | Toggle inline values |  |
| `<leader>dw` | n x | Watch expression under cursor |  |
| `<leader>dx` | n | Clear all breakpoints |  |
| `<S-F11>` | n | Debug: step out |  |
| `<S-F5>` | n | Debug: terminate session |  |

### Test

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>ta` | n | Run all tests |  |
| `<leader>tcc` | n | Toggle coverage signs |  |
| `<leader>tcl` | n | Load and show coverage |  |
| `<leader>tcr` | n | Run tests with coverage |  |
| `<leader>tcs` | n | Coverage summary |  |
| `<leader>tcx` | n | Clear coverage |  |
| `<leader>td` | n | Debug nearest test |  |
| `<leader>tf` | n | Run tests in file |  |
| `<leader>tl` | n | Run last test |  |
| `<leader>tO` | n | Toggle output panel |  |
| `<leader>to` | n | Show test output |  |
| `<leader>tS` | n | Stop test run |  |
| `<leader>ts` | n | Toggle test tree |  |
| `<leader>tt` | n | Run nearest test |  |
| `<leader>tW` | n | Toggle watch for project |  |
| `<leader>tw` | n | Toggle watch for file |  |
| `[t` | n | Previous failed test |  |
| `]t` | n | Next failed test |  |

### HTTP

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>ha` | n x | Run all requests | http |
| `<leader>hb` | n | Show body | http |
| `<leader>hc` | n | Copy as curl | http |
| `<leader>hE` | n | Export to Postman | http |
| `<leader>he` | n | Select environment | http |
| `<leader>hH` | n | Show headers | http |
| `<leader>hh` | n x | Run request under cursor | http |
| `<leader>hI` | n | OpenAPI explorer | http |
| `<leader>hi` | n | Inspect request (dry run) | http |
| `<leader>hn` | n | Next request | http |
| `<leader>hp` | n | Previous request | http |
| `<leader>hr` | n | Replay last request | http |
| `<leader>hS` | n | Scratchpad | http |
| `<leader>hs` | n | Show headers and body | http |
| `<leader>hX` | n | Clear script variables | http |
| `<leader>hx` | n | Close response window | http |

### Problems

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>xc` | n | Close all Trouble windows |  |
| `<leader>xl` | n | Location list (Trouble) |  |
| `<leader>xq` | n | Quickfix list (Trouble) |  |
| `<leader>xr` | n | LSP references / definitions |  |
| `<leader>xt` | n | Todo comments |  |
| `<leader>xX` | n | Project diagnostics (Trouble) |  |
| `<leader>xx` | n | Buffer diagnostics (Trouble) |  |
| `[td` | n | Previous todo comment |  |
| `]td` | n | Next todo comment |  |

### Refactor

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>rA` | n | Swap parameter with previous |  |
| `<leader>ra` | n | Swap parameter with next |  |
| `<leader>rB` | n | Extract block to file |  |
| `<leader>rb` | n | Extract block as function |  |
| `<leader>rc` | n | Clear debug prints |  |
| `<leader>rE` | x | Extract function to file |  |
| `<leader>re` | x | Extract function |  |
| `<leader>rI` | n | Inline function |  |
| `<leader>ri` | n | Inline variable |  |
| `<leader>rn` | n | Rename symbol (live preview) |  |
| `<leader>rP` | n | Debug print location |  |
| `<leader>rp` | n | Debug print variable |  |
| `<leader>rp` | x | Debug print selection |  |
| `<leader>rr` | n x | Select refactor |  |
| `<leader>rv` | x | Extract variable |  |

### Multicursor

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<C-LeftDrag>` | n | Drag cursor selection |  |
| `<C-LeftMouse>` | n | Add / remove cursor |  |
| `<C-LeftRelease>` | n | Finish cursor selection |  |
| `<leader>m=` | n | Align cursor columns |  |
| `<leader>mA` | x | Cursor on each selected line |  |
| `<leader>ma` | n x | Cursor on every match |  |
| `<leader>mj` | n x | Add cursor below |  |
| `<leader>mk` | n x | Add cursor above |  |
| `<leader>mN` | n x | Add cursor at previous match |  |
| `<leader>mn` | n x | Add cursor at next match |  |
| `<leader>mp` | x | Cursors by pattern in selection |  |
| `<leader>mq` | n | Clear cursors |  |
| `<leader>mr` | n | Restore last cursors |  |
| `<leader>mS` | n x | Skip previous match |  |
| `<leader>ms` | n x | Skip next match |  |
| `<leader>mX` | x | Rotate text backwards |  |
| `<leader>mx` | x | Rotate text between cursors |  |

### Session

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>sD` | n | Delete session |  |
| `<leader>sd` | n | Toggle auto save |  |
| `<leader>sf` | n | Find session |  |
| `<leader>sl` | n | Restore last session |  |
| `<leader>sp` | n | Purge orphaned sessions |  |
| `<leader>ss` | n | Restore session |  |

### Outline

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>;` | n | Pick breadcrumb |  |
| `<leader>O` | n | Outline navigator |  |
| `<leader>o` | n | Outline (symbol tree) |  |
| `{` | n | Previous symbol | dockerfile, lua, sql, typescript, yaml.docker-compose |
| `}` | n | Next symbol | dockerfile, lua, sql, typescript, yaml.docker-compose |

### UI toggles

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>uF` | n | Toggle format on save (global) |  |
| `<leader>uf` | n | Toggle format on save (buffer) |  |
| `<leader>ui` | n | Toggle inlay hints | dockerfile, lua, typescript, yaml.docker-compose |
| `<leader>uk` | n | Toggle sticky context |  |
| `<leader>us` | n | Toggle spell checking |  |

### Tooling

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<leader>lc` | n | Check health |  |
| `<leader>li` | n | LSP clients |  |
| `<leader>ll` | n | Lazy |  |
| `<leader>lm` | n | Mason |  |
| `<leader>lp` | n | Lazy profile |  |
| `<leader>lr` | n | Restart LSP |  |
| `<leader>lu` | n | Lazy update |  |

### Insert mode

| Keys | Mode | Description | Buffer |
| --- | --- | --- | --- |
| `<C-B>` | i | blink.cmp: Scroll Documentation Up | every file buffer |
| `<C-E>` | i | blink.cmp: Hide | every file buffer |
| `<C-F>` | i | blink.cmp: Scroll Documentation Down | every file buffer |
| `<C-J>` | i | blink.cmp: Select Next | every file buffer |
| `<C-K>` | i | blink.cmp: Select Prev | every file buffer |
| `<C-N>` | i | blink.cmp: Select Next | every file buffer |
| `<C-P>` | i | blink.cmp: Select Prev | every file buffer |
| `<C-S>` | i | vim.lsp.buf.signature_help() |  |
| `<C-Space>` | i | blink.cmp: Show, Show Documentation, Hide Documentation | every file buffer |
| `<CR>` | i | blink.cmp: Accept | every file buffer |
| `<S-Tab>` | s i | blink.cmp: Snippet Backward | every file buffer |
| `<Tab>` | s i | blink.cmp: Snippet Forward | every file buffer |

<!-- keymaps:end -->

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
- **The first HTTP request needs the network**: kulala downloads its backend
  (kulala-core, ~100 MB) and that request fails while the download runs.
- **The keymap scripts read the installed copy** in `~/.config/nvim`, not the
  checkout — run `./install.sh` before them.

## Repository layout

```
.
├── install.sh   # checks Neovim, copies nvim/ → ~/.config/nvim, creates codebook.toml
├── CLAUDE.md    # notes for Claude Code: architecture, rules, non-obvious decisions
├── nvim/        # the configuration itself (becomes ~/.config/nvim)
├── scripts/     # maintenance: keymap audit and tables, cspell → codebook migration
└── http/        # .http request collections, kept outside nvim/ on purpose
```
