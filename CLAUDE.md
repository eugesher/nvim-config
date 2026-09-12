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
nvim --headless -l scripts/dump-keymaps.lua --readme  # regenerate the key tables in README.md
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
| `lua/core/` | Neovim itself without plugins: options, keymaps, autocmds, diagnostics, filetypes, the lazy.nvim bootstrap |
| `lua/plugins/*.lua` | **Thin** lazy.nvim specs: repository, `dependencies`, `build`, `version` / `branch` / `commit`. Never `opts` or `keys` |
| `lua/settings/<name>.lua` | **Everything** a plugin is configured with, one file per plugin or domain |
| `lua/settings/lsp/` | `init.lua` (server list, `<leader>l` keys), `mason.lua`, `capabilities.lua`, `keymaps.lua` (the only LspAttach), `servers/<name>.lua` |
| `lua/user/settings.lua` | The single source of user-tunable values — pure data, no `vim.*` calls |
| `lua/myconfig/health.lua` | `:checkhealth myconfig` |
| `after/ftplugin/*.lua` | Buffer-local keymaps and filetype specifics (http, sql) |

A spec is built with `require("settings").spec(repo, name, extra)`. The settings
module `settings/<name>.lua` returns any of `enabled`, `cond`, `event`, `ft`,
`cmd`, `keys`, `opts`, `init`, `config`, `priority`, `lazy`, `which_key`; those
fields go into the lazy.nvim spec, anything else is ignored. Modules use that to
export helpers other code reads (`M.groups` in whichkey, `M.server_path` in dap,
`M.extra_tools` in lsp/mason).

`:checkhealth myconfig` lives under `lua/myconfig/` because checkhealth finds
`lua/<name>/health.lua`; a `core/health.lua` would add a second, duplicate
`:checkhealth core` report.

### Writing settings

- **Options explicitly, defaults included — but only documented ones** (README,
  `:help`, or the config file the plugin's docs name as the reference). Never dig
  out undocumented internal fields.
- The first line of every `settings/*.lua`:
  `-- defaults verified against <plugin> vX.Y.Z (YYYY-MM-DD)` (or `@<commit>`).
- Values a user may want to change go into `lua/user/settings.lua` and are read
  from there, never hard-coded in a settings file.
- Highlights go into `custom_highlights` in `settings/theme.lua` (never
  `color_overrides`), colors from the catppuccin palette.
- Glyphs come from `settings/icons.lua` only (Nerd Fonts v3, no padding).
- A new panel filetype has to be added to every exclusion list: `PANELS` in
  `settings/autosession.lua`, `EXCLUDED_FILETYPES` in `settings/dropbar.lua`,
  `disable.ft` in `settings/whichkey.lua`, `panels` in `settings/lualine.lua`,
  and the lists in `treesitter-context.lua` and `indent.lua`. Bottom panels use
  `user.ui.panel_height`.

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
  `which_key` field). `settings/whichkey.lua` declares groups only.
- After changing keys run `scripts/audit-keymaps.lua`. A deliberate duplicate or
  collision goes into its whitelist with the reason; then regenerate the README
  tables.

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
| `<leader>a` | **free** | `<leader>gL` | **free** |

## Non-obvious decisions

These look like mistakes or omissions and are not. Change them only on request.

- **The database is on `<leader>D`, not `<leader>db`.** `<leader>d` is the
  debugger group and `<leader>db` toggles a breakpoint; database keys under it
  would make that key wait for 'timeoutlen' and mix two groups in which-key.
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
  does not exist; `settings/treesitter.lua` starts highlighting, folds and indent
  per buffer, and incremental selection is Neovim's own.

Further decisions recorded in the code, each with its measurement:

- aerial loads on `BufReadPost` with LSP first, so `{` / `}` jump by symbol and
  class fields show up.
- dropbar's treesitter `valid_types` is narrowed to declarations. Its preview
  `reorient` uses `winrestview`, because `:normal` breaks the fuzzy prompt.
- `grr` opens Trouble, not a picker.
- trouble's `symbols` mode is unused: aerial owns the structure view.
- codebook has `exit_timeout = 500`, since it never exits on its own.
- `<leader>fp` and `<leader>cR` were removed as duplicates of `<leader>li` and
  `<leader>lr`.
