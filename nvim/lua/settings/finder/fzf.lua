local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.cmd = { "FzfLua" }

local fd = vim.fn.executable("fd") == 1 and "fd" or "fdfind"
local excludes = "--exclude .git --exclude node_modules --exclude dist --exclude coverage"

function M.init()
  local native = vim.ui.select
  local function stub(...)
    require("lazy").load({ plugins = { "fzf-lua" } })
    if vim.ui.select == stub then
      vim.ui.select = native
    end
    return vim.ui.select(...)
  end
  vim.ui.select = stub
end

function M.opts()
  local actions = require("fzf-lua.actions")
  return {
    "default-title",
    ui_select = false,
    winopts = {
      height = 0.85,
      width = 0.80,
      row = 0.35,
      col = 0.55,
      border = user.ui.border,
      zindex = 50,
      backdrop = 100,
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
        layout = "flex",
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
      files = {
        ["enter"] = actions.file_edit_or_qf,
        ["ctrl-s"] = actions.file_split,
        ["ctrl-v"] = actions.file_vsplit,
        ["ctrl-t"] = require("trouble.sources.fzf").actions.open,
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
      ["--tiebreak"] = "index",
    },
    previewers = {
      builtin = {
        syntax = true,
        syntax_limit_l = 0,
        syntax_limit_b = 1024 * 1024,
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
      rg_glob = true,
      glob_flag = "--iglob",
      glob_separator = "%s%-%-",
    },
    lsp = {
      async_or_timeout = 5000,
      jump1 = true,
      includeDeclaration = false,
      symbols = {
        locate = false,
        async_or_timeout = true,
        symbol_style = 1,
        symbol_icons = icons.kinds,
      },
    },
    diagnostics = {
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
      cwd_only = true,
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
  { "<leader>gs", pick("git_status"), desc = "Git status" },
  { "<leader>gC", pick("git_commits"), desc = "Git commits" },
  { "<leader>gb", pick("git_branches"), desc = "Git branches" },
  { "<leader>gS", pick("git_stash"), desc = "Git stash" },
}

return M
