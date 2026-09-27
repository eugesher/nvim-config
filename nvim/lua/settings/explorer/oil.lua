local user = require("user.settings")

local M = {}

M.cmd = "Oil"

M.keys = {
  {
    "-",
    function()
      require("oil").open()
    end,
    desc = "Parent directory (oil)",
  },
}

function M.init()
  local group = vim.api.nvim_create_augroup("settings_oil", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OilActionsPre",
    desc = "Load the buffers oil would drop instead of renaming them",
    callback = function(event)
      for _, action in ipairs(event.data.actions or {}) do
        local path = action.type == "move" and action.src_url:match("^oil://(.*)$")
        if path then
          require("settings.ui.bufferline").load_buffers_under(path)
        end
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "OilActionsPost",
    desc = "Close the buffers of the files oil deleted",
    callback = function(event)
      for _, action in ipairs(event.data.actions or {}) do
        local path = action.type == "delete" and action.url:match("^oil://(.*)$")
        if path and not vim.uv.fs_lstat(path) then
          require("settings.ui.bufferline").delete_buffers_under(path)
        end
      end
    end,
  })
end

local ALWAYS_HIDDEN = { [".git"] = true, ["node_modules"] = true }

M.opts = {
  default_file_explorer = false,
  columns = { "icon" },
  buf_options = {
    buflisted = false,
    bufhidden = "hide",
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  delete_to_trash = true,
  skip_confirm_for_simple_edits = false,
  prompt_save_on_select_new_entry = true,
  cleanup_delay_ms = 2000,
  lsp_file_methods = {
    enabled = true,
    timeout_ms = 1000,
    autosave_changes = true,
  },
  constrain_cursor = "editable",
  watch_for_changes = true,
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<localleader>v"] = { "actions.select", opts = { vertical = true }, mode = "n" },
    ["<localleader>s"] = { "actions.select", opts = { horizontal = true }, mode = "n" },
    ["<localleader>t"] = { "actions.select", opts = { tab = true }, mode = "n" },
    ["<C-p>"] = "actions.preview",
    ["gq"] = { "actions.close", mode = "n" },
    ["gR"] = { "actions.refresh", mode = "n" },
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["g~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
  use_default_keymaps = false,
  view_options = {
    show_hidden = true,
    is_hidden_file = function(name)
      return vim.startswith(name, ".")
    end,
    is_always_hidden = function(name)
      return ALWAYS_HIDDEN[name] == true
    end,
    natural_order = "fast",
    case_insensitive = true,
    sort = {
      { "type", "asc" },
      { "name", "asc" },
    },
    highlight_filename = function()
      return nil
    end,
  },
  extra_scp_args = {},
  extra_s3_args = {},
  git = {
    add = function()
      return false
    end,
    mv = function()
      return false
    end,
    rm = function()
      return false
    end,
  },
  float = {
    padding = 2,
    max_width = 0,
    max_height = 0,
    border = user.ui.border,
    win_options = { winblend = 0 },
    preview_split = "auto",
    override = function(conf)
      return conf
    end,
  },
  preview_win = {
    update_on_cursor_moved = true,
    preview_method = "fast_scratch",
    disable_preview = function()
      return false
    end,
    win_options = {},
  },
  confirmation = {
    max_width = 0.9,
    min_width = { 40, 0.4 },
    max_height = 0.9,
    min_height = { 5, 0.1 },
    border = user.ui.border,
    win_options = { winblend = 0 },
  },
  progress = {
    max_width = 0.9,
    min_width = { 40, 0.4 },
    max_height = { 10, 0.9 },
    min_height = { 5, 0.1 },
    border = user.ui.border,
    minimized_border = "none",
    win_options = { winblend = 0 },
  },
  ssh = { border = user.ui.border },
  keymaps_help = { border = user.ui.border },
}

return M
