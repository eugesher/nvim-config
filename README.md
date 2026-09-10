# Neovim Configuration — NestJS Backend Development

An IDE-grade Neovim configuration for backend development on NestJS: TypeScript,
RabbitMQ, MySQL/TypeORM and API-gateway services. It bundles LSP, debugging,
tests, database and HTTP clients into a single keyboard-driven workflow.

## Status

⚠️ **The configuration is being rewritten from scratch.** The repository is in the
middle of that rewrite: the old config has been removed and the new one is landing
task by task, so on any given commit parts of the stack described below may not
exist yet. Task descriptions live outside the repository for now; a `tasks/`
directory will be linked here if it is added.

## Environment requirements

### Required

| Dependency | Why | Install |
| --- | --- | --- |
| **Neovim 0.12+** | Core editor; required by refactoring.nvim, kulala, nvim-dap | `sudo snap install nvim --classic` |
| **Git 2.31+** | Plugin management, gitsigns, diffview.nvim | `sudo apt install git` |
| **Node.js 20+** and npm | TS/JS language servers, tree-sitter-cli | [nodejs.org](https://nodejs.org), or via `fnm` / `nvm` |
| **tree-sitter-cli ≥ 0.26.1** | Required by the `main` branch of nvim-treesitter | `npm install -g tree-sitter-cli` |
| **build-essential** (gcc, make) | Builds `jsregexp` for LuaSnip | `sudo apt install build-essential` |
| **ripgrep** | Live grep in fzf-lua | `sudo apt install ripgrep` |
| **fd-find** | File traversal in fzf-lua (ships as `fdfind`, needs an `fd` symlink) | `sudo apt install fd-find` |
| **fzf > 0.36** | Picker engine behind fzf-lua | `sudo apt install fzf` |
| **A Nerd Font** | Icons in the file tree, status line and picker | [nerdfonts.com](https://www.nerdfonts.com/) — then select it in your terminal |
| **wl-clipboard** or **xclip** | System clipboard integration | `sudo apt install wl-clipboard` |

### Optional — per feature

| Dependency | What it enables |
| --- | --- |
| **mysql-client** | MySQL database client for vim-dadbod |
| **redis-tools** (`redis-cli`) | One-off `:DB redis://…` commands and interactive Redis work in a separate terminal window |
| **jq** | Pretty-printing JSON responses in kulala |
| **libxml2-utils** (`xmllint`) | Pretty-printing XML responses in kulala |
| **bat** | Syntax highlighting in picker previews (ships as `batcat`, needs a `bat` symlink) |
| **git-delta** | Syntax highlighting for git diffs in picker previews |

### Installed automatically via `:Mason`

`vtsls`, `eslint-lsp`, `lua-language-server`, `json-lsp`, `yaml-language-server`,
`docker-language-server`, `codebook`, `bash-language-server`, `prettierd`,
`stylua`, `js-debug-adapter`.

## Installation

On Debian/Ubuntu `fd` and `bat` are installed under different binary names, so
create the symlinks the config expects:

```bash
mkdir -p ~/.local/bin
ln -s "$(command -v fdfind)" ~/.local/bin/fd
ln -s "$(command -v batcat)" ~/.local/bin/bat
```

Install the Tree-sitter CLI (needed by the `main` branch of nvim-treesitter):

```bash
npm install -g tree-sitter-cli
```

Install the configuration into `~/.config/nvim` (the existing config is backed up
to `~/.config/nvim.backup.<timestamp>`):

```bash
./install.sh
```

Then launch the editor and let the plugin manager bootstrap itself:

```bash
nvim
```

## What's inside

| Area | Tooling |
| --- | --- |
| Plugin manager | lazy.nvim |
| LSP | vtsls (TypeScript), servers managed by Mason |
| Completion | blink.cmp |
| Picker | fzf-lua |
| File tree | neo-tree |
| Git | neogit, diffview.nvim, gitsigns |
| Database | vim-dadbod |
| HTTP client | kulala |
| Debugging | nvim-dap |
| Tests | neotest |
| Spelling | codebook |
| Diagnostics panel | trouble.nvim |

Details are intentionally omitted — they will appear as the rewrite progresses.

## Repository layout

```
.
├── install.sh   # copies nvim/ → ~/.config/nvim
├── nvim/        # the configuration itself (becomes ~/.config/nvim)
└── http/        # .http request collections, kept outside nvim/ on purpose
```
