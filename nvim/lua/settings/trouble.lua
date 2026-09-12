-- defaults verified against trouble.nvim v3.7.1-15-gbd67efe (2026-09-12)
--
-- Problems panel: diagnostics, LSP references, quickfix / loclist and TODOs in
-- one list, with the preview shown in the main editor window. v3 is a full
-- rewrite of v2 — none of its options or API carry over, so pre-2024 recipes
-- do not apply here.
--
-- The bottom split is shared with dap-view (task 17) and the neotest output
-- panel (task 18). All three take their height from `user.ui.panel_height`, and
-- a starting debug session closes trouble first (settings/dap.lua).
--
-- The `symbols` mode is deliberately left alone: the structure view is aerial's
-- job (task 26), and two symbol trees would only duplicate each other.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.cmd = { "Trouble" }

-- Symbol glyphs are stored without padding (settings/icons.lua); trouble puts
-- the icon straight in front of the name, so each one gets a trailing space.
local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

-- Sorting and formatting are section fields, not global ones: every mode that
-- defines its own (diagnostics does) would override a top-level value, so they
-- are set on our own modes instead, where they actually take effect.
local DIAGNOSTICS = {
  sort = { "severity", "filename", "pos", "message" },
  format = "{severity_icon} {message:md} {item.source} {code}",
}

-- `Trouble close` closes one view, and several can be open at once (a
-- diagnostics list plus an lsp list, say); the bounded loop closes the lot.
local function close_all()
  local trouble = require("trouble")
  for _ = 1, 10 do
    if not trouble.is_open() then
      return
    end
    trouble.close()
  end
end

M.keys = {
  { "<leader>xx", "<cmd>Trouble diagnostics_buffer toggle<cr>", desc = "Buffer diagnostics" },
  { "<leader>xX", "<cmd>Trouble project_diagnostics toggle<cr>", desc = "Project diagnostics" },
  { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list" },
  { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list" },
  { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references / definitions" },
  { "<leader>xc", close_all, desc = "Close all Trouble windows" },
}

M.opts = {
  auto_close = false, -- an empty list stays open
  auto_open = false, -- the panel only ever opens on request
  auto_preview = true,
  auto_refresh = true,
  auto_jump = false, -- a single result still goes through the list
  focus = false, -- opening keeps the cursor in the code
  restore = true, -- reopening returns to the last position in the list
  follow = true,
  indent_guides = true,
  max_items = 200, -- per section
  multiline = true,
  pinned = false, -- the list follows the current buffer, it is not bound to one
  warn_no_results = false, -- "no results" is not worth a message
  open_no_results = false,
  -- A bottom split, like every other panel. `border` is not set: it belongs to
  -- `trouble.Window.float`, and a split silently ignores it.
  win = {
    type = "split",
    relative = "editor",
    position = "bottom",
    size = user.ui.panel_height,
  },
  -- The preview lands in the main window; unloaded files are shown in a scratch
  -- buffer, so browsing a long list does not load half the project.
  preview = {
    type = "main",
    scratch = true,
  },
  throttle = {
    refresh = 20, -- fetches new data when needed
    update = 10, -- updates the window
    render = 10, -- renders the window
    follow = 100, -- follows the current item
    preview = { ms = 100, debounce = true },
  },
  -- Window-local keys of the list. `<c-s>` / `<c-v>` open a split the same way
  -- they do in the fzf-lua window (task 10) — inside a list they are actions,
  -- not the editor-wide save / paste of a GUI.
  keys = {
    ["?"] = "help",
    ["<esc>"] = "cancel", -- closes the preview, back to the main window
    ["<cr>"] = "jump",
    ["<2-leftmouse>"] = "jump",
    ["<c-s>"] = "jump_split",
    ["<c-v>"] = "jump_vsplit",
    q = "close",
    o = "jump_close",
    r = "refresh",
    R = "toggle_refresh",
    p = "preview",
    P = "toggle_preview",
    i = "inspect",
    dd = "delete",
    d = { action = "delete", mode = "v" },
    ["}"] = "next",
    ["]]"] = "next",
    ["{"] = "prev",
    ["[["] = "prev",
    zo = "fold_open",
    zO = "fold_open_recursive",
    zc = "fold_close",
    zC = "fold_close_recursive",
    za = "fold_toggle",
    zA = "fold_toggle_recursive",
    zm = "fold_more",
    zM = "fold_close_all",
    zr = "fold_reduce",
    zR = "fold_open_all",
    zx = "fold_update",
    zX = "fold_update_all",
    zn = "fold_disable",
    zN = "fold_enable",
    zi = "fold_toggle_enable",
    -- The two filter toggles of the default key map, kept as they are: a
    -- deep merge would leave them in place anyway.
    gb = {
      action = function(view)
        view:filter({ buf = 0 }, { toggle = true })
      end,
      desc = "Toggle Current Buffer Filter",
    },
    s = {
      action = function(view)
        local f = view:get_filter("severity")
        local severity = ((f and f.filter.severity or 0) + 1) % 5
        view:filter({ severity = severity }, {
          id = "severity",
          template = "{hl:Title}Filter:{hl} {severity}",
          del = severity == 0,
        })
      end,
      desc = "Toggle Severity Filter",
    },
  },
  modes = {
    -- The LSP lists are the exception to `warn_no_results = false`: an empty
    -- diagnostics list is good news and needs no message, but `grr` on a symbol
    -- nothing references would otherwise do nothing at all, with no way to tell
    -- that apart from a slow server.
    lsp = { warn_no_results = true },
    lsp_references = { warn_no_results = true },
    -- <leader>xx: this buffer, every severity.
    diagnostics_buffer = vim.tbl_extend("error", {
      mode = "diagnostics",
      filter = { buf = 0 },
    }, DIAGNOSTICS),
    -- <leader>xX: every buffer, every severity. No severity filter on purpose —
    -- a language server only reports diagnostics for files that are open, so the
    -- list is short enough as it is, and hiding warnings would only lose them.
    project_diagnostics = vim.tbl_extend("error", {
      mode = "diagnostics",
    }, DIAGNOSTICS),
  },
  icons = {
    -- Same tree glyphs as the file explorer (settings/neotree.lua).
    indent = {
      top = "│ ",
      middle = "├╴",
      last = "└╴",
      fold_open = icons.ui.chevron_down .. " ",
      fold_closed = icons.ui.chevron_right .. " ",
      ws = "  ",
    },
    folder_closed = icons.ui.folder_closed .. " ",
    folder_open = icons.ui.folder_open .. " ",
    kinds = kind_icons(),
  },
}

return M
