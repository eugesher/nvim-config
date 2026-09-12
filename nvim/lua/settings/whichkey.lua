-- defaults verified against which-key.nvim v3.17.0-8-g3aab214 (2026-09-11)
--
-- Popup with the available keys after a prefix, and the one place where the
-- keymap namespaces of the leader map are declared.
--
-- Разделение ответственности:
--   * `desc` конкретных кеймапов пишутся в settings/<плагин>.lua, рядом с самим
--     кеймапом: `desc` в поле `keys`, а для кеймапов, которые создаёт сам
--     плагин, — поле `which_key` модуля (собирается `settings.which_key()`).
--   * Этот файл содержит ТОЛЬКО группы, их иконки и порядок. Отдельные кеймапы
--     сюда не дописываются — иначе появится второй источник правды.
--
-- which-key v3: only `require("which-key").add()`; v2's `register()` is gone.
-- A group without mappings is not drawn: each namespace shows up in the popup
-- once its first keymap exists.

local user = require("user.settings")
local glyphs = require("settings.icons").keymap_groups

local M = {}

M.event = "VeryLazy"

-- Namespaces of the leader map, in display-independent declaration order.
-- n + x: code actions, refactors, hunks and multicursor also act on selections.
local groups = {
  { "<leader>b", group = "buffers", icon = { icon = glyphs.buffers, color = "cyan" } },
  { "<leader>c", group = "code", icon = { icon = glyphs.code, color = "orange" } },
  { "<leader>d", group = "debug", icon = { icon = glyphs.debug, color = "red" } },
  { "<leader>D", group = "database", icon = { icon = glyphs.database, color = "azure" } },
  { "<leader>f", group = "find", icon = { icon = glyphs.find, color = "green" } },
  { "<leader>g", group = "git", icon = { icon = glyphs.git, color = "orange" } },
  { "<leader>gh", group = "hunks", icon = { icon = glyphs.hunks, color = "yellow" } },
  { "<leader>gt", group = "git toggles", icon = { icon = glyphs.git_toggles, color = "yellow" } },
  { "<leader>gx", group = "conflicts", icon = { icon = glyphs.conflicts, color = "red" } },
  { "<leader>l", group = "lsp / tooling", icon = { icon = glyphs.lsp, color = "blue" } },
  { "<leader>m", group = "multicursor", icon = { icon = glyphs.multicursor, color = "purple" } },
  { "<leader>r", group = "refactor", icon = { icon = glyphs.refactor, color = "cyan" } },
  { "<leader>s", group = "session", icon = { icon = glyphs.session, color = "azure" } },
  { "<leader>t", group = "test", icon = { icon = glyphs.test, color = "green" } },
  { "<leader>tc", group = "coverage", icon = { icon = glyphs.coverage, color = "green" } },
  { "<leader>u", group = "ui toggles", icon = { icon = glyphs.ui, color = "cyan" } },
  { "<leader>x", group = "problems", icon = { icon = glyphs.problems, color = "green" } },
  { "]", group = "next", icon = { icon = glyphs.next, color = "grey" } },
  { "[", group = "prev", icon = { icon = glyphs.prev, color = "grey" } },
}
for _, spec in ipairs(groups) do
  spec.mode = { "n", "x" }
end
-- HTTP: normal mode only; its keymaps are buffer-local in .http buffers (task 15),
-- so globally the group stays empty and hidden.
groups[#groups + 1] =
  { "<leader>h", group = "http", mode = "n", icon = { icon = glyphs.http, color = "blue" } }

M.opts = {
  preset = "modern",
  -- 200 ms: well under 'timeoutlen' (400, core/options.lua), so the popup is up
  -- before an ambiguous key times out; plugin popups (marks, registers) at once.
  delay = function(ctx)
    return ctx.plugin and 0 or 200
  end,
  filter = function()
    return true -- show every mapping, described or not
  end,
  spec = {}, -- groups are added in `config`, see above
  notify = true, -- warn about problems in the mappings
  triggers = {
    { "<auto>", mode = "nxso" },
  },
  -- Visual line/block modes start hidden until the next key.
  defer = function(ctx)
    return ctx.mode == "V" or ctx.mode == "<C-V>"
  end,
  plugins = {
    marks = true,
    registers = true,
    spelling = { enabled = true, suggestions = 20 },
    presets = {
      operators = true,
      motions = true,
      text_objects = true,
      windows = true,
      nav = true,
      z = true,
      g = true,
    },
  },
  win = {
    no_overlap = true, -- never cover the cursor
    -- Geometry of the "modern" preset, stated explicitly: bottom, 90% wide.
    width = 0.9,
    height = { min = 4, max = 25 },
    col = 0.5,
    row = -1,
    border = user.ui.border,
    padding = { 1, 2 }, -- [top/bottom, right/left]
    title = true,
    title_pos = "center",
    zindex = 1000,
    bo = {},
    wo = { winblend = 0 },
  },
  -- v3 has no `layout.align` (a v2 option).
  layout = {
    width = { min = 20 },
    spacing = 3,
  },
  keys = {
    scroll_down = "<c-d>",
    scroll_up = "<c-u>",
  },
  sort = { "local", "order", "group", "alphanum", "mod" },
  expand = 0, -- never inline a group's items into the parent list
  replace = {
    key = {
      function(key)
        return require("which-key.view").format(key)
      end,
    },
    desc = {
      { "<Plug>%(?(.*)%)?", "%1" },
      { "^%+", "" },
      { "<[cC]md>", "" },
      { "<[cC][rR]>", "" },
      { "<[sS]ilent>", "" },
      { "^lua%s+", "" },
      { "^call%s+", "" },
      { "^:%s*", "" },
    },
  },
  icons = {
    breadcrumb = "»",
    separator = "➜",
    group = "+",
    ellipsis = "…",
    mappings = true,
    rules = {}, -- which-key's built-in rules only
    colors = true,
    keys = {
      Up = " ",
      Down = " ",
      Left = " ",
      Right = " ",
      C = "󰘴 ",
      M = "󰘵 ",
      D = "󰘳 ",
      S = "󰘶 ",
      CR = "󰌑 ",
      Esc = "󱊷 ",
      ScrollWheelDown = "󱕐 ",
      ScrollWheelUp = "󱕑 ",
      NL = "󰌑 ",
      BS = "󰁮",
      Space = "󱁐 ",
      Tab = "󰌒 ",
      F1 = "󱊫",
      F2 = "󱊬",
      F3 = "󱊭",
      F4 = "󱊮",
      F5 = "󱊯",
      F6 = "󱊰",
      F7 = "󱊱",
      F8 = "󱊲",
      F9 = "󱊳",
      F10 = "󱊴",
      F11 = "󱊵",
      F12 = "󱊶",
    },
  },
  show_help = true,
  show_keys = true,
  disable = {
    ft = { "neo-tree", "dbui", "dap-view", "trouble", "aerial" },
    bt = { "terminal" },
  },
  debug = false,
}

function M.config(_, opts)
  local wk = require("which-key")
  wk.setup(opts)
  wk.add(groups)
  -- Descriptions of plugin-created keymaps, declared next to their plugin.
  wk.add(require("settings").which_key())
end

M.keys = {
  {
    "<leader>?",
    function()
      require("which-key").show({ global = false })
    end,
    desc = "Buffer keymaps (which-key)",
  },
}

return M
