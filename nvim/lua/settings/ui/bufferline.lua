local icons = require("settings.icons")

local M = {}

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
  vim.o.mousemoveevent = true
end

M.opts = {
  options = {
    mode = "buffers",
    themable = true,
    numbers = "ordinal",
    close_command = close,
    right_mouse_command = close,
    left_mouse_command = "buffer %d",
    indicator = { style = "underline" },
    buffer_close_icon = icons.ui.close,
    modified_icon = icons.ui.dot,
    close_icon = icons.ui.close,
    left_trunc_marker = icons.ui.arrow_left,
    right_trunc_marker = icons.ui.arrow_right,
    max_name_length = 24,
    max_prefix_length = 18,
    truncate_names = true,
    tab_size = 24,
    diagnostics = "nvim_lsp",
    diagnostics_update_in_insert = false,
    diagnostics_update_on_event = true,
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
        filetype = "neo-tree",
        text = "Explorer",
        text_align = "left",
        highlight = "Directory",
        separator = true,
      },
    },
    color_icons = true,
    show_buffer_icons = true,
    show_buffer_close_icons = true,
    show_close_icon = false,
    show_tab_indicators = true,
    show_duplicate_prefix = true,
    duplicates_across_groups = true,
    persist_buffer_sort = true,
    move_wraps_at_ends = false,
    separator_style = "thick",
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
  opts.highlights = require("settings.ui.theme").bufferline_highlights()
  bufferline.setup(opts)
end

local function delete_current()
  M.safe_buffer_delete(0, false)
end

local function delete_others()
  local groups = require("bufferline.groups")
  local elements = require("bufferline.state").components
  local current = vim.api.nvim_get_current_buf()
  local shown = vim.iter(elements):any(function(element)
    return element.id == current
  end)
  if not shown then
    return
  end
  for _, element in ipairs(elements) do
    if element.id ~= current and not groups._is_pinned(element) then
      M.safe_buffer_delete(element.id, false)
    end
  end
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
  { "<leader>bo", delete_others, desc = "Delete other buffers (keep pinned)" },
  { "<leader>bp", "<cmd>BufferLinePick<CR>", desc = "Pick buffer" },
  { "<leader>bP", "<cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
  { "<leader>b>", "<cmd>BufferLineMoveNext<CR>", desc = "Move buffer right" },
  { "<leader>b<lt>", "<cmd>BufferLineMovePrev<CR>", desc = "Move buffer left" },
  { "<leader>q", delete_current, desc = "Delete buffer" },
}
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
