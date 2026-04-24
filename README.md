# Neovim Configuration — Node.js / TypeScript Development

A minimal but fully functional Neovim setup for Node.js / TypeScript development
with LSP, Treesitter, autocompletion, formatting, and fuzzy finding.

## Prerequisites

### Required

| Dependency | Why | Install |
|------------|-----|---------|
| **Neovim 0.11+** | Core editor | [neovim.io/install](https://neovim.io/doc/user/installing.html) |
| **Git 2.19+** | Plugin management, gitsigns | `sudo apt install git` |
| **Node.js 18+** and **npm** | TypeScript/JavaScript LSP servers | [nodejs.org](https://nodejs.org) |
| **ripgrep** | Telescope `live_grep` | `sudo apt install ripgrep` |
| **gcc** (or **clang**) + **make** | Compiles `telescope-fzf-native` at install | `sudo apt install build-essential` |
| **lazygit** | `<leader>gg` Git UI | `sudo apt install lazygit` or [see releases](https://github.com/jesseduffield/lazygit#installation) |
| **xclip** (Linux) | System clipboard (`"+y`, `"+p`) | `sudo apt install xclip` |
| **A Nerd Font** | File-tree and status-line icons | [nerdfonts.com](https://www.nerdfonts.com/) — set in your terminal |

### Recommended

| Dependency | Why | Install |
|------------|-----|---------|
| **fd** | Faster file finding in Telescope and snacks picker (falls back to `find` without it) | Download the latest `.deb` from [github.com/sharkdp/fd/releases](https://github.com/sharkdp/fd/releases) |

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
npm install -g neovim tree-sitter-cli
```

| Package | Why |
|---------|-----|
| `neovim` | Enables the Neovim Node.js provider (required for some plugins) |
| `tree-sitter-cli` | Compiles Treesitter parsers from source when pre-built binaries are unavailable |

## Installation

Use the provided script for a one-step install:

```bash
./install.sh
```

The script backs up any existing `~/.config/nvim` to `~/.config/nvim.backup.<timestamp>`,
then copies this configuration in its place.

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
├── lazy-lock.json                -- Pinned plugin versions
└── lua/
    ├── lazy-bootstrap.lua        -- Installs lazy.nvim on first run; loads plugin specs
    ├── config/
    │   ├── options.lua           -- Core editor options (indent, search, clipboard, undo)
    │   ├── keymaps.lua           -- Global keymaps (splits, scroll, save, visual paste)
    │   └── autocmds.lua          -- Yank highlight, trailing-whitespace trim, cursor restore
    └── plugins/
        ├── lsp.lua               -- Mason + nvim-lspconfig (ts_ls, eslint, lua_ls, jsonls, yamlls)
        ├── completion.lua        -- nvim-cmp + LuaSnip + friendly-snippets
        ├── treesitter.lua        -- Syntax highlighting, smart indent, incremental selection
        ├── formatting.lua        -- conform.nvim: Prettier (TS/JS/JSON/YAML/HTML/CSS/MD), stylua
        ├── telescope.lua         -- Fuzzy finder: files, grep, buffers, symbols, help, diagnostics
        └── ui.lua                -- catppuccin (mocha), lualine statusline, nvim-tree file explorer
```

## Key mappings

The leader key is `<Space>`.

### General

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>w` | Save file | Writes the current buffer to disk (`:w`) |
| `<leader>q` | Close buffer | Removes the current buffer from the buffer list (`:bd`) |
| `<leader>nh` | Clear search highlight | Clears the `hlsearch` highlight after a search |
| `<C-d>` / `<C-u>` | Half-page scroll, cursor re-centred | Scrolls half a page and keeps the cursor at the screen centre |
| `<A-j>` / `<A-k>` | Move selected lines down / up (Visual mode) | Shifts the selected block one line down or up with auto-reindent |
| `p` (Visual) | Paste without overwriting the unnamed register | Replaces the selection without losing the previously yanked text |

### Window navigation

| Key | Action | Description |
|-----|--------|-------------|
| `<C-h>` `<C-j>` `<C-k>` `<C-l>` | Move between splits | Focuses the left / down / up / right split window |

### File tree & Telescope

| Key | Action | Description |
|-----|--------|-------------|
| `<leader>e` | Toggle file explorer (nvim-tree) | Opens or closes the side-panel file tree |
| `<leader>ff` | Find files | Fuzzy-searches file names in the project root |
| `<leader>fg` | Live grep across project | Full-text search via ripgrep; results update as you type |
| `<leader>fb` | Open buffers | Lists and switches between currently open buffers |
| `<leader>fs` | Document symbols (LSP) | Shows all LSP symbols (functions, classes, variables) in the current file |
| `<leader>fd` | Diagnostics list | Lists all LSP diagnostics (errors, warnings) across the project |
| `<leader>fh` | Search Neovim help tags | Fuzzy-searches Neovim's built-in help documentation |

### LSP (any file with an attached language server)

| Key | Action | Description |
|-----|--------|-------------|
| `gd` | Go to definition | Jumps to where the symbol under the cursor is defined |
| `gD` | Go to declaration | Jumps to the declaration of the symbol (e.g. type signatures) |
| `gr` | Find all references | Lists every place the symbol is referenced in the project |
| `gi` | Go to implementation | Jumps to the concrete implementation of an abstract or interface symbol |
| `K` | Hover documentation | Shows inline documentation for the symbol under the cursor |
| `<leader>rn` | Rename symbol | Renames the symbol and all its references across the project |
| `<leader>ca` | Code action | Opens a menu of available refactors and quick-fixes from the LSP |
| `<leader>d` | Show diagnostic in floating window | Displays the full diagnostic message for the current line in a popup |
| `[d` / `]d` | Previous / next diagnostic | Moves the cursor to the previous or next diagnostic in the file |

### Completion (Insert mode)

| Key | Action | Description |
|-----|--------|-------------|
| `<C-Space>` | Trigger completion menu manually | Opens the completion popup without needing to type more characters |
| `<C-j>` / `<C-k>` | Next / previous item | Selects the next or previous entry in the completion list |
| `<Tab>` / `<S-Tab>` | Next / previous item, or jump through snippet fields | Cycles through items or moves between placeholders in an active snippet |
| `<CR>` | Confirm selection | Inserts the selected completion item and closes the menu |
| `<C-e>` | Close completion menu | Dismisses the popup without inserting anything |

### Treesitter incremental selection

| Key | Action | Description |
|-----|--------|-------------|
| `<CR>` | Start selection / expand to next syntax node | Begins a visual selection at the cursor or extends it to the surrounding syntax node |
| `<BS>` | Shrink selection to previous node | Reduces the selection back to the previous (inner) syntax node |

## Troubleshooting

- **LSP not attaching** — run `:LspInfo`. For `ts_ls`, the file must be inside a project with a `package.json` or `tsconfig.json`.
- **Formatters not running** — install `prettier` and `stylua` via `:Mason`.
- **Plugin errors on startup** — run `:Lazy sync` to reinstall all plugins.
- **Icons show as empty boxes** — your terminal is not using a Nerd Font.
- **ESLint not fixing on save** — verify `eslint` is installed (`:Mason`) and there is a valid ESLint config in the project root.
- **General diagnosis** — `:checkhealth` reports everything Neovim can see.
