local user = require("user.settings")

local M = {}

M.cmd = { "DapViewClose", "DapViewHover", "DapViewOpen", "DapViewToggle", "DapViewWatch" }

M.opts = {
  winbar = {
    show = true,
    sections = { "watches", "scopes", "exceptions", "breakpoints", "threads", "repl" },
    default_section = "scopes",
    show_keymap_hints = true,
    separators = nil,
    base_sections = {
      watches = { label = "Watches", keymap = "W" },
      scopes = { label = "Scopes", keymap = "S" },
      exceptions = { label = "Exceptions", keymap = "E" },
      breakpoints = { label = "Breakpoints", keymap = "B" },
      threads = { label = "Threads", keymap = "T" },
      repl = { label = "REPL", keymap = "R" },
    },
    custom_sections = {},
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
    size = user.ui.panel_height,
    position = "below",
    terminal = {
      size = 0.5,
      position = "left",
      hide = {},
    },
  },

  help = { border = user.ui.border },
  hover = { border = user.ui.border },

  render = {
    sort_variables = nil,
  },

  virtual_text = { enabled = false },

  switchbuf = "usetab,newtab",
  auto_toggle = false,
  follow_tab = false,
}

return M
