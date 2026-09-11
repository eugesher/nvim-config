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
`docker-language-server`, `codebook`, `bash-language-server`, `prettierd`,
`prettier`, `stylua`, `js-debug-adapter`.

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
| File operations | oil.nvim (directory as an editable buffer) |
| Git | neogit, diffview.nvim, gitsigns |
| Database | vim-dadbod |
| HTTP client | kulala |
| Debugging | nvim-dap |
| Tests | neotest |
| Spelling | codebook |
| Diagnostics panel | trouble.nvim |

Details are intentionally omitted — they will appear as the rewrite progresses.

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

## Repository layout

```
.
├── install.sh   # copies nvim/ → ~/.config/nvim
├── nvim/        # the configuration itself (becomes ~/.config/nvim)
└── http/        # .http request collections, kept outside nvim/ on purpose
```
