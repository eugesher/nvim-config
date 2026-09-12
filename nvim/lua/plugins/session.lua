-- Sessions: window layout and buffers restored per project directory.
-- persistence.nvim was considered and rejected — no automatic restore, no
-- session picker, no hooks for the side panels (decision recorded in task 23).

local spec = require("settings").spec

return {
  spec("rmagatti/auto-session", "autosession"),
}
