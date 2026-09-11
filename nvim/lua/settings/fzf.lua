-- defaults verified against fzf-lua @05e44d3 (2026-09-11)
--
-- One picker for files, text, symbols, diagnostics and git; it also serves
-- vim.ui.select (code actions, DAP configurations, sessions). Telescope is not
-- part of this config in any form.
--
-- fzf-lua's default key tables bind Alt combinations (hide, toggle-all, first /
-- last, preview line scroll, ignore / hidden toggles). The tables below replace
-- them (no leading `true`), because this config does not use the Alt layer.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.cmd = { "FzfLua" }

-- Ubuntu ships fd as `fdfind`; the README asks for an `fd` symlink.
local fd = vim.fn.executable("fd") == 1 and "fd" or "fdfind"
-- NestJS monorepos: never list or search build output and dependencies.
local excludes = "--exclude .git --exclude node_modules --exclude dist --exclude coverage"

-- vim.ui.select goes through fzf-lua from the very first call: this stub loads
-- the plugin, whose `config` registers the real implementation.
function M.init()
  local native = vim.ui.select
  local function stub(...)
    require("lazy").load({ plugins = { "fzf-lua" } })
    if vim.ui.select == stub then
      vim.ui.select = native -- registration failed: never recurse
    end
    return vim.ui.select(...)
  end
  vim.ui.select = stub
end

-- A function: the actions come from fzf-lua itself, loaded by then.
function M.opts()
  local actions = require("fzf-lua.actions")
  return {
    "default-title", -- profile: picker name in the border title
    ui_select = false, -- registered in `config` instead
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.55,
      border = user.ui.border,
      zindex = 50,
      backdrop = 100, -- no dimming, like the lazy.nvim and Mason windows
      fullscreen = false,
      title_pos = "center",
      treesitter = {
        enabled = true,
        fzf_colors = { ["hl"] = "-1:reverse", ["hl+"] = "-1:reverse" },
      },
      preview = {
        default = "builtin",
        border = user.ui.border,
        wrap = false,
        hidden = false,
        vertical = "down:45%",
        horizontal = "right:55%",
        layout = "flex", -- side by side on wide screens, stacked on narrow ones
        flip_columns = 100,
        title = true,
        title_pos = "center",
        scrollbar = "float",
        scrolloff = -1,
        delay = 20,
        winopts = {
          number = true,
          relativenumber = false,
          cursorline = true,
          cursorlineopt = "both",
          cursorcolumn = false,
          signcolumn = "no",
          list = false,
          foldenable = false,
          foldmethod = "manual",
          scrolloff = 0,
        },
      },
    },
    keymap = {
      -- :tmap keys of the fzf window
      builtin = {
        ["<F1>"] = "toggle-help",
        ["<F2>"] = "toggle-fullscreen",
        ["<F3>"] = "toggle-preview-wrap",
        ["<F4>"] = "toggle-preview",
        ["<F5>"] = "toggle-preview-cw",
        ["<F6>"] = "toggle-preview-behavior",
        ["<F7>"] = "toggle-preview-ts-ctx",
        ["<F8>"] = "preview-ts-ctx-dec",
        ["<F9>"] = "preview-ts-ctx-inc",
        ["<S-Left>"] = "preview-reset",
        ["<S-down>"] = "preview-page-down",
        ["<S-up>"] = "preview-page-up",
      },
      -- fzf --bind keys
      fzf = {
        ["ctrl-z"] = "abort",
        ["ctrl-u"] = "unix-line-discard",
        ["ctrl-f"] = "half-page-down",
        ["ctrl-b"] = "half-page-up",
        ["ctrl-a"] = "beginning-of-line",
        ["ctrl-e"] = "end-of-line",
        ["f3"] = "toggle-preview-wrap",
        ["f4"] = "toggle-preview",
        ["shift-down"] = "preview-page-down",
        ["shift-up"] = "preview-page-up",
      },
    },
    actions = {
      -- Inherited by files, grep, lsp, buffers, oldfiles, quickfix, git_status, …
      files = {
        ["enter"] = actions.file_edit_or_qf, -- one entry opens, several go to quickfix
        ["ctrl-s"] = actions.file_split,
        ["ctrl-v"] = actions.file_vsplit,
        -- TODO(задача 20): отправлять в Trouble; до тех пор — в quickfix.
        ["ctrl-t"] = actions.file_sel_to_qf,
        ["ctrl-q"] = actions.file_sel_to_qf,
      },
    },
    fzf_opts = {
      ["--ansi"] = true,
      ["--info"] = "inline-right",
      ["--height"] = "100%",
      ["--layout"] = "reverse",
      ["--border"] = "none",
      ["--highlight-line"] = true,
      ["--tiebreak"] = "index", -- equal scores keep the source order
    },
    previewers = {
      builtin = {
        syntax = true,
        syntax_limit_l = 0,
        syntax_limit_b = 1024 * 1024, -- no syntax highlighting above 1 MB
        limit_b = 1024 * 1024 * 10,
        treesitter = {
          enabled = true,
          disabled = {},
          context = { max_lines = 1, trim_scope = "inner" },
        },
        toggle_behavior = "default",
      },
      bat = {
        cmd = vim.fn.executable("batcat") == 1 and "batcat" or "bat",
        args = "--color=always --style=numbers,changes",
      },
    },
    files = {
      cmd = fd .. " --type f --hidden --follow " .. excludes,
      git_icons = true,
      file_icons = true,
      color_icons = true,
      cwd_prompt = false,
    },
    grep = {
      rg_opts = "--column --line-number --no-heading --color=always --smart-case "
        .. "--max-columns=4096 -g '!node_modules' -g '!dist' -g '!coverage' -e",
      rg_glob = true, -- `foo -- *.ts` narrows live_grep with a glob
      glob_flag = "--iglob",
      glob_separator = "%s%-%-",
    },
    lsp = {
      async_or_timeout = 5000,
      jump1 = true, -- a single result opens directly (gd)
      includeDeclaration = false, -- references without the declaration itself
      symbols = {
        locate = false,
        async_or_timeout = true,
        symbol_style = 1, -- icon + kind
        symbol_icons = icons.kinds,
      },
    },
    diagnostics = {
      -- `severity_limit` stays unset: every severity is listed.
      file_icons = false,
      color_headings = true,
      diag_icons = true,
      diag_source = true,
      diag_code = true,
      icon_padding = " ",
      multiline = 2,
    },
    git = {
      status = {
        actions = {
          ["right"] = { fn = actions.git_unstage, reload = true },
          ["left"] = { fn = actions.git_stage, reload = true },
          ["ctrl-x"] = { fn = actions.git_reset, reload = true },
        },
      },
      -- git-delta, when installed, is picked up as the preview pager.
      commits = { preview = "git show --color {1}" },
      branches = { remotes = "local" },
      stash = { preview = "git --no-pager stash show --patch --color {1}" },
    },
    buffers = {
      sort_lastused = true,
      show_unloaded = true,
      cwd_only = false,
    },
    oldfiles = {
      include_current_session = true,
      cwd_only = true, -- recent files of this project only
      stat_file = true,
      ignore_current_buffer = true,
    },
  }
end

function M.config(_, opts)
  local fzf = require("fzf-lua")
  fzf.setup(opts)
  fzf.register_ui_select()
end

local function pick(name, opts)
  return function()
    require("fzf-lua")[name](opts)
  end
end

M.keys = {
  { "<leader>ff", pick("files"), desc = "Files" },
  {
    "<leader>fF",
    pick("files", { cmd = fd .. " --type f --hidden --no-ignore --follow --exclude .git" }),
    desc = "Files (incl. ignored)",
  },
  { "<leader>fg", pick("live_grep"), desc = "Live grep" },
  { "<leader>fG", pick("live_grep_glob"), desc = "Live grep (rg --glob)" },
  { "<leader>fw", pick("grep_cword"), desc = "Grep word under cursor" },
  { "<leader>fw", pick("grep_visual"), mode = "x", desc = "Grep selection" },
  { "<leader>fb", pick("buffers"), desc = "Buffers" },
  { "<leader>fr", pick("oldfiles"), desc = "Recent files" },
  { "<leader>f/", pick("blines"), desc = "Lines in buffer" },
  { "<leader>fs", pick("lsp_document_symbols"), desc = "Document symbols" },
  { "<leader>fS", pick("lsp_live_workspace_symbols"), desc = "Workspace symbols" },
  { "<leader>fd", pick("diagnostics_document"), desc = "Buffer diagnostics" },
  { "<leader>fD", pick("diagnostics_workspace"), desc = "Workspace diagnostics" },
  { "<leader>fh", pick("helptags"), desc = "Help tags" },
  { "<leader>fk", pick("keymaps"), desc = "Keymaps" },
  { "<leader>fc", pick("commands"), desc = "Commands" },
  { "<leader>fq", pick("quickfix"), desc = "Quickfix list" },
  { "<leader>fR", pick("resume"), desc = "Resume last picker" },
  -- Not a picker: `:lsp` needs a subcommand in 0.12, client info is here.
  { "<leader>fp", "<cmd>checkhealth vim.lsp<CR>", desc = "LSP clients" },
  { "<leader>gs", pick("git_status"), desc = "Git status" },
  { "<leader>gC", pick("git_commits"), desc = "Git commits" },
  { "<leader>gb", pick("git_branches"), desc = "Git branches" },
  { "<leader>gS", pick("git_stash"), desc = "Git stash" },
}

return M
