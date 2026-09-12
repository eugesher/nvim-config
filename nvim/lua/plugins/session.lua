-- Sessions: window layout and buffers restored per project directory.
-- Not persistence.nvim: no automatic restore, no session picker, no hooks for
-- the side panels.

local spec = require("settings").spec

return {
  spec("rmagatti/auto-session", "session.autosession"),
}
