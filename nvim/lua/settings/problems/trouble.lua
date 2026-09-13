local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.cmd = { "Trouble" }

local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

local DIAGNOSTICS = {
  sort = { "severity", "filename", "pos", "message" },
  format = "{severity_icon} {message:md} {item.source} {code}",
}

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
  {
    "<leader>xx",
    "<cmd>Trouble diagnostics_buffer toggle<cr>",
    desc = "Buffer diagnostics (Trouble)",
  },
  {
    "<leader>xX",
    "<cmd>Trouble project_diagnostics toggle<cr>",
    desc = "Project diagnostics (Trouble)",
  },
  { "<leader>xq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix list (Trouble)" },
  { "<leader>xl", "<cmd>Trouble loclist toggle<cr>", desc = "Location list (Trouble)" },
  { "<leader>xr", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references / definitions" },
  { "<leader>xc", close_all, desc = "Close all Trouble windows" },
}

M.opts = {
  auto_close = false,
  auto_open = false,
  auto_preview = true,
  auto_refresh = true,
  auto_jump = false,
  focus = false,
  restore = true,
  follow = true,
  indent_guides = true,
  max_items = 200,
  multiline = true,
  pinned = false,
  warn_no_results = false,
  open_no_results = false,
  win = {
    type = "split",
    relative = "editor",
    position = "bottom",
    size = user.ui.panel_height,
  },
  preview = {
    type = "main",
    scratch = true,
  },
  throttle = {
    refresh = 20,
    update = 10,
    render = 10,
    follow = 100,
    preview = { ms = 100, debounce = true },
  },
  keys = {
    ["?"] = "help",
    ["<esc>"] = "cancel",
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
    lsp = { warn_no_results = true },
    lsp_references = { warn_no_results = true },
    diagnostics_buffer = vim.tbl_extend("error", {
      mode = "diagnostics",
      filter = { buf = 0 },
    }, DIAGNOSTICS),
    project_diagnostics = vim.tbl_extend("error", {
      mode = "diagnostics",
      filter = function(items)
        local root = vim.uv.cwd()
        return vim.tbl_filter(function(item)
          return item.filename ~= nil and item.filename:find(root, 1, true) == 1
        end, items)
      end,
    }, DIAGNOSTICS),
  },
  icons = {
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
