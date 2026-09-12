-- defaults verified against nvim-dap-view v1.2.1-6-ge766b3d (2026-09-12)
--
-- Debugger panel: variables, watches, breakpoints, threads and the REPL in one
-- bottom split, plus the debugee's terminal beside it.
--
-- The panel is opened and closed by the session listeners in settings/dap.lua,
-- not by `auto_toggle`: the bottom split is shared with trouble and the test
-- output.

local user = require("user.settings")

local M = {}

M.cmd = { "DapViewClose", "DapViewHover", "DapViewOpen", "DapViewToggle", "DapViewWatch" }

M.opts = {
  winbar = {
    show = true,
    -- "console" is deliberately absent: the debugee's terminal gets its own
    -- window next to the panel (`windows.terminal`), not a tab in it.
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
    default_section = "scopes", -- what a new session shows first
    show_keymap_hints = true, -- the letter for each section in its label
    separators = nil, -- the plugin's own separators
    -- Labels and their keys inside the panel; the defaults, stated. The
    -- `sessions` and `console` sections are not listed above, so their
    -- entries stay as shipped.
    base_sections = {
      watches = { label = "Watches", keymap = "W" },
      scopes = { label = "Scopes", keymap = "S" },
      exceptions = { label = "Exceptions", keymap = "E" },
      breakpoints = { label = "Breakpoints", keymap = "B" },
      threads = { label = "Threads", keymap = "T" },
      repl = { label = "REPL", keymap = "R" },
    },
    custom_sections = {},
    -- Clickable session controls on the right of the winbar.
    controls = {
      enabled = true,
      position = "right",
      buttons = {
        "play",
        "step_into",
        "step_over",
        "step_out",
        "step_back",
        "run_last",
        "terminate",
        "disconnect",
      },
      custom_buttons = {},
    },
  },

  windows = {
    -- A number below 1 is a fraction of the screen, anything else is lines —
    -- so the shared panel height goes straight in (user/settings.lua).
    size = user.ui.panel_height,
    position = "below",
    terminal = {
      size = 0.5, -- half the width, beside the panel
      position = "left",
      -- The integrated terminal is where a pwa-node debugee prints, so it is
      -- never hidden.
      hide = {},
    },
  },

  -- Keys inside the panel are left as the plugin ships them: they are
  -- buffer-local to its windows and collide with nothing in this config.
  help = { border = user.ui.border },
  hover = { border = user.ui.border },

  -- Rendering of the threads and breakpoints lists: the plugin's own
  -- formatters, no sorting of variables.
  render = {
    sort_variables = nil,
  },

  -- nvim-dap-view ships a minimal virtual-text implementation of its own.
  -- Off: inline values come from nvim-dap-virtual-text
  -- (settings/dap-virtual-text.lua), and two of them would double every value.
  virtual_text = { enabled = false },

  -- Jumping from a breakpoint or a stack frame: reuse a window in this tab,
  -- otherwise open a new tab instead of splitting the debugging layout.
  switchbuf = "usetab,newtab",
  auto_toggle = false, -- the listeners in settings/dap.lua do this
  follow_tab = false, -- the panel stays in the tab where the session started
}

return M
