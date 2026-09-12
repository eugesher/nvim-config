-- defaults verified against nvim-web-devicons v0.100-121-g5f032a8 (2026-09-11)
--
-- File-type icons for the status line, buffer tabs, file tree and pickers.

local M = {}

M.opts = {
  override = {},
  color_icons = true, -- per-icon colors
  default = true, -- unknown files get a generic icon (upstream default: false)
  strict = true, -- match by file name first, then by extension (upstream default: false)
  -- `variant` stays unset: light/dark icon colors follow 'background'.
  -- `blend` stays unset: icons follow 'pumblend'.
  override_by_filename = {},
  override_by_extension = {},
  override_by_operating_system = {},
}

return M
