-- defaults verified against bufferline.nvim v4.9.1 (2026-09-11)
--
-- Buffer tab line, plus `safe_buffer_delete` — the only way this config closes
-- buffers. It goes through bufdelete.nvim, which keeps the window layout.

local icons = require("settings.icons")

local M = {}

--- Closes a buffer without closing the windows that show it. Used by the tab
--- close icon, right click, `<leader>bd` / `<leader>bD` and `<leader>q`; the
--- config never calls `:bdelete` directly.
---@param bufnr? integer buffer to close (nil or 0: the current one)
---@param force? boolean discard unsaved changes instead of prompting
function M.safe_buffer_delete(bufnr, force)
  if bufnr == nil or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  require("bufdelete").bufdelete(bufnr, force == true)
end

local function close(bufnr)
  M.safe_buffer_delete(bufnr, false)
end

M.event = "VeryLazy"

function M.init()
  -- `options.hover` needs mouse-move events to reveal the close icon.
  vim.o.mousemoveevent = true
end

M.opts = {
  options = {
    mode = "buffers",
    -- `style_preset` is set in `config`: it needs the loaded module.
    themable = true,
    numbers = "ordinal", -- `<leader>1..9` jump by this number
    close_command = close,
    right_mouse_command = close,
    left_mouse_command = "buffer %d",
    -- `middle_mouse_command` stays unset (no action), as upstream.
    indicator = { style = "underline" },
    buffer_close_icon = icons.ui.close,
    modified_icon = icons.ui.dot,
    close_icon = icons.ui.close,
    left_trunc_marker = icons.ui.arrow_left,
    right_trunc_marker = icons.ui.arrow_right,
    -- `name_formatter`, `custom_filter`, `get_element_icon` stay unset:
    -- plain file names, every listed buffer, icons from nvim-web-devicons.
    max_name_length = 18,
    max_prefix_length = 15, -- prefix shown when two buffers share a name
    truncate_names = true,
    tab_size = 18,
    diagnostics = "nvim_lsp",
    diagnostics_update_in_insert = false,
    diagnostics_update_on_event = true,
    -- Errors and warnings only; hints/info would crowd every tab.
    diagnostics_indicator = function(_, _, counts)
      local parts = {}
      if counts.error then
        parts[#parts + 1] = icons.diagnostics.Error .. " " .. counts.error
      end
      if counts.warning then
        parts[#parts + 1] = icons.diagnostics.Warn .. " " .. counts.warning
      end
      return table.concat(parts, " ")
    end,
    offsets = {
      {
        filetype = "neo-tree", -- задача 11
        text = "Explorer",
        text_align = "left",
        highlight = "Directory",
        separator = true,
      },
      {
        filetype = "trouble", -- задача 20
        text = "Problems",
        text_align = "left",
        highlight = "Directory",
        separator = true,
      },
    },
    color_icons = true,
    show_buffer_icons = true,
    show_buffer_close_icons = true,
    show_close_icon = false, -- per-tab icons and `<leader>bo` cover it
    show_tab_indicators = true,
    show_duplicate_prefix = true,
    duplicates_across_groups = true,
    persist_buffer_sort = true,
    move_wraps_at_ends = false,
    separator_style = "slant",
    enforce_regular_tabs = false,
    always_show_bufferline = true,
    auto_toggle_bufferline = true,
    hover = { enabled = true, delay = 200, reveal = { "close" } },
    sort_by = "insert_after_current",
    pick = { alphabet = "abcdefghijklmopqrstuvwxyzABCDEFGHIJKLMOPQRSTUVWXYZ1234567890" },
    groups = { items = {}, options = { toggle_hidden_on_enter = true } },
  },
}

function M.config(_, opts)
  local bufferline = require("bufferline")
  opts.options.style_preset = bufferline.style_preset.default
  -- Built here, not at import time: needs catppuccin's options, and catppuccin
  -- is loaded first (`lazy = false`, `priority = 1000`). No italics on the
  -- selected tab — carried over from the old config.
  opts.highlights = require("catppuccin.special.bufferline").get_theme({ styles = { "bold" } })
  bufferline.setup(opts)
end

local function delete_current()
  M.safe_buffer_delete(0, false)
end

M.keys = {
  { "]b", "<cmd>BufferLineCycleNext<CR>", desc = "Next buffer" },
  { "[b", "<cmd>BufferLineCyclePrev<CR>", desc = "Previous buffer" },
  { "<leader>bd", delete_current, desc = "Delete buffer" },
  {
    "<leader>bD",
    function()
      M.safe_buffer_delete(0, true)
    end,
    desc = "Delete buffer (force)",
  },
  { "<leader>bo", "<cmd>BufferLineCloseOthers<CR>", desc = "Delete other buffers" },
  { "<leader>bp", "<cmd>BufferLinePick<CR>", desc = "Pick buffer" },
  { "<leader>bP", "<cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
  { "<leader>b>", "<cmd>BufferLineMoveNext<CR>", desc = "Move buffer right" },
  { "<leader>b<lt>", "<cmd>BufferLineMovePrev<CR>", desc = "Move buffer left" },
  { "<leader>q", delete_current, desc = "Delete buffer" },
}
-- `go_to(i, true)`: the absolute position, i.e. the ordinal shown on the tab.
-- `:BufferLineGoToBuffer i` counts only visible tabs, so once the line is
-- truncated the key and the label would disagree.
for i = 1, 9 do
  M.keys[#M.keys + 1] = {
    "<leader>" .. i,
    function()
      require("bufferline").go_to(i, true)
    end,
    desc = "Go to buffer " .. i,
  }
end

return M
