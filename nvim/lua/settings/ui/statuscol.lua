-- defaults verified against statuscol.nvim @887b8a0 (2026-09-13)
--
-- The column beside the text ('statuscolumn') split by sign source, so every
-- sign keeps its place whatever else the line carries:
--
--   [diagnostics, breakpoints, TODO, tests] [line number] [git, coverage]
--
-- Plain 'signcolumn' packs all signs of a line to the left by priority: a git
-- bar would take the diagnostic cell on every line without a diagnostic.
-- setup() turns 'signcolumn' off as soon as sign segments exist; core/options.lua
-- still sets it for the moment before the plugin loads.

local M = {}

-- At startup, not on an event: a window drawn before setup() shows the plain
-- sign column and shifts sideways once the segments take over.
M.lazy = false

function M.opts()
  local builtin = require("statuscol.builtin")

  -- One-cell-per-sign segment with the plugin's defaults spelled out. A sign
  -- goes to the first segment whose pattern matches; the `.*` segment skips
  -- signs another segment names explicitly.
  local function signs(patterns)
    return vim.tbl_extend("error", patterns, {
      maxwidth = 1, -- the highest priority sign of the line wins
      -- Cells per sign: every glyph here is one cell wide (upstream 2 pads
      -- each with a space). The number's own padding separates the columns.
      colwidth = 1,
      auto = false, -- keep the width in buffers without such signs: no text shift
      wrap = false, -- nothing on the wrapped part of a line
      fillchar = " ",
      fillcharhl = nil, -- SignColumn / CursorLineSign
      foldclosed = false,
      align = "left",
    })
  end

  return {
    setopt = true,
    -- builtin.lnumfunc
    thousands = false,
    relculright = false,
    -- Windows that are not code keep Neovim's plain column instead of empty
    -- segments. Side panels, pickers and plugin UIs are `nofile`, but some set
    -- 'buftype' after both checks of `bt_ignore` have run (dbui keeps the
    -- segments), so the panels are listed by filetype as well. Oil is a file
    -- buffer that turns its sign column off (settings/explorer/oil.lua).
    ft_ignore = {
      "neo-tree",
      "trouble",
      "dbui",
      "dap-view",
      "dap-view-term",
      "dap-repl",
      "aerial",
      "oil",
    },
    bt_ignore = { "nofile", "terminal", "help", "prompt", "quickfix" },
    segments = {
      -- Neovim's own fold column ('foldcolumn' is 0 in this config).
      { text = { "%C" }, click = "v:lua.ScFa" },
      -- Everything but git: diagnostics, nvim-dap, todo-comments, neotest.
      { sign = signs({ name = { ".*" }, namespace = { ".*" } }), click = "v:lua.ScSa" },
      {
        text = { builtin.lnumfunc, " " },
        condition = { true, builtin.not_empty },
        click = "v:lua.ScLa",
      },
      -- gitsigns hunks (staged ones included) and nvim-coverage lines, the
      -- one-cell bars of settings/icons.lua, right against the text.
      {
        sign = signs({ namespace = { "^gitsigns_signs_" }, name = { "^coverage_" } }),
        click = "v:lua.ScSa",
      },
    },
    clickmod = "c",
    -- Keys are Lua patterns on the sign name or namespace.
    clickhandlers = {
      -- Upstream: left click toggles a breakpoint, middle yanks the line, right
      -- pastes, double right cuts it. A click on a number only moves the cursor.
      Lnum = false,
      FoldClose = builtin.foldclose_click,
      FoldOpen = builtin.foldopen_click,
      FoldOther = builtin.foldother_click,
      DapBreakpointRejected = builtin.toggle_breakpoint,
      DapBreakpoint = builtin.toggle_breakpoint,
      DapBreakpointCondition = builtin.toggle_breakpoint,
      ["diagnostic.signs"] = builtin.diagnostic_click, -- float on left, code action on middle
      -- Upstream: middle click resets the hunk, right click stages it. Hunks are
      -- handled by the `<leader>gh` keys only.
      gitsigns = false,
    },
  }
end

function M.config(_, opts)
  require("statuscol").setup(opts)

  -- `bt_ignore` misses `:terminal` windows: the buffer turns into a terminal
  -- after its checks, and the window keeps the segments.
  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("settings_statuscol", { clear = true }),
    desc = "Plain status column in terminal windows",
    callback = function()
      vim.opt_local.statuscolumn = ""
    end,
  })
end

return M
