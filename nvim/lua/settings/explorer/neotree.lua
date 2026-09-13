-- defaults verified against neo-tree.nvim v3.x@1a14083 (2026-09-12)
--
-- Side panel with the project tree (WebStorm's Project view): git statuses and
-- diagnostics right in the tree. Bulk file operations live in oil
-- (settings/explorer/oil.lua). Source `document_symbols` is enabled but has no keymap —
-- the outline is aerial's job (`<leader>o`): `:Neotree document_symbols`.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.cmd = "Neotree"

M.keys = {
  { "<leader>e", "<cmd>Neotree toggle filesystem<cr>", desc = "Explorer" },
  { "<leader>E", "<cmd>Neotree reveal<cr>", desc = "Explorer: reveal file" },
  { "<leader>be", "<cmd>Neotree buffers<cr>", desc = "Buffers (explorer)" },
  { "<leader>ge", "<cmd>Neotree git_status float<cr>", desc = "Git status (explorer)" },
}

-- `nvim .` / `:e src/` before neo-tree is loaded: its own directory hijack
-- (plugin/neo-tree.lua) does not exist yet and netrw is disabled
-- (core/bootstrap.lua), so the directory would open as an empty buffer. Load
-- the plugin on the first directory buffer; from then on neo-tree handles it.
function M.init()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("settings_neotree", { clear = true }),
    desc = "Load neo-tree when a directory is opened",
    callback = function(args)
      if package.loaded["neo-tree"] then
        return true
      end
      local stat = args.file ~= "" and vim.uv.fs_stat(args.file) or nil
      if stat and stat.type == "directory" then
        require("neo-tree")
        return true
      end
    end,
  })
end

-- `popup_border_style` accepts only these styles; for the rest of `ui.border`
-- ("none", "shadow", "bold") pass "" — neo-tree then takes 'winborder' and
-- falls back to "single" on styles it can't draw.
local POPUP_BORDERS = { double = true, rounded = true, single = true, solid = true }

-- `document_symbols` kinds: glyphs from settings/icons, highlight groups as in
-- neo-tree's defaults.
local SYMBOL_HIGHLIGHTS = {
  File = "Tag",
  Module = "Exception",
  Namespace = "Include",
  Package = "Label",
  Class = "Include",
  Method = "Function",
  Property = "@property",
  Field = "@field",
  Constructor = "@constructor",
  Enum = "@number",
  Interface = "Type",
  Function = "Function",
  Variable = "@variable",
  Constant = "Constant",
  String = "String",
  Number = "Number",
  Boolean = "Boolean",
  Array = "Type",
  Object = "Type",
  Key = "",
  Null = "Constant",
  EnumMember = "Number",
  Struct = "Type",
  Event = "Constant",
  Operator = "Operator",
  TypeParameter = "Type",
}

local function symbol_kinds()
  local kinds = {
    Unknown = { icon = "?", hl = "" },
    Root = { icon = icons.ui.folder_open, hl = "NeoTreeRootName" },
  }
  for kind, hl in pairs(SYMBOL_HIGHLIGHTS) do
    kinds[kind] = { icon = icons.kinds[kind], hl = hl }
  end
  return kinds
end

-- Mappings shared by every source window (`:h neo-tree-mappings`).
-- "none" removes a default mapping.
local window_mappings = {
  -- Leader is <Space>: a tree-local <Space> would shadow `<leader>…` here.
  ["<space>"] = "none",
  -- quick_jump sits on the GUI combo <C-s>, which this config does not use.
  ["<C-s>"] = "none",
  -- Needs nvim-window-picker, which is not installed.
  ["w"] = "none",
  ["<Tab>"] = "select",
  ["<C-S-i>"] = "invert_selection",
  ["<C-;>"] = "clear_selection",
  ["<2-LeftMouse>"] = "open",
  ["<cr>"] = "open",
  ["<esc>"] = "cancel",
  ["P"] = {
    "toggle_preview",
    -- snacks.nvim / image.nvim are not installed.
    config = { use_float = true, use_snacks_image = false, use_image_nvim = false },
  },
  ["<C-f>"] = { "scroll_preview", config = { direction = -10 } },
  ["<C-b>"] = { "scroll_preview", config = { direction = 10 } },
  ["l"] = "focus_preview",
  ["S"] = "open_split",
  ["s"] = "open_vsplit",
  ["t"] = "open_tabnew",
  ["C"] = "close_node",
  ["z"] = "close_all_nodes",
  ["R"] = "refresh",
  ["a"] = { "add", config = { show_path = "none" } },
  ["A"] = "add_directory",
  ["d"] = "delete",
  ["T"] = "trash",
  ["u"] = "undo",
  ["U"] = "restore_from_trash",
  ["r"] = "rename",
  ["y"] = "copy_to_clipboard",
  ["x"] = "cut_to_clipboard",
  ["p"] = "paste_from_clipboard",
  ["<C-r>"] = "clear_clipboard",
  ["c"] = "copy",
  ["m"] = "move",
  ["e"] = "toggle_auto_expand_width",
  ["q"] = "close_window",
  ["?"] = "show_help",
  ["<"] = "prev_source",
  [">"] = "next_source",
}

-- neo-tree renames and moves files itself and tells language servers nothing.
-- Send them `workspace/didRenameFiles`, as oil does (`lsp_file_methods`): vtsls
-- answers with an edit that fixes the imports (`updateImportsOnFileMove`).
local function matches_filters(filters, path)
  local is_dir = vim.fn.isdirectory(path) == 1
  for _, filter in ipairs(filters) do
    local pattern = filter.pattern
    local ignore_case = pattern.options and pattern.options.ignoreCase
    local glob = ignore_case and pattern.glob:lower() or pattern.glob
    if
      (filter.scheme == nil or filter.scheme == "file")
      and (pattern.matches == nil or (pattern.matches == "folder") == is_dir)
      and vim.glob.to_lpeg(glob):match(ignore_case and path:lower() or path)
    then
      return true
    end
  end
  return false
end

local function did_rename_files(args)
  local method = "workspace/didRenameFiles"
  local params = {
    files = {
      { oldUri = vim.uri_from_fname(args.source), newUri = vim.uri_from_fname(args.destination) },
    },
  }
  for _, client in ipairs(vim.lsp.get_clients({ method = method })) do
    local filters =
      vim.tbl_get(client.server_capabilities, "workspace", "fileOperations", "didRename", "filters")
    if filters and matches_filters(filters, args.destination) then
      client:notify(method, params)
    end
  end
end

-- "Order by" menu: `o` shows the help popup, the second key picks the order.
local function order_mappings(extra)
  local mappings = {
    ["o"] = { "show_help", nowait = false, config = { title = "Order by", prefix_key = "o" } },
    ["oc"] = { "order_by_created", nowait = false },
    ["od"] = { "order_by_diagnostics", nowait = false },
    ["om"] = { "order_by_modified", nowait = false },
    ["on"] = { "order_by_name", nowait = false },
    ["os"] = { "order_by_size", nowait = false },
    ["ot"] = { "order_by_type", nowait = false },
  }
  return vim.tbl_extend("force", mappings, extra)
end

function M.opts()
  return {
    sources = { "filesystem", "buffers", "git_status", "document_symbols" },
    default_source = "filesystem",
    add_blank_line_at_top = false,
    -- settings/session/autosession.lua keeps the tree out of sessions.
    auto_clean_after_session_restore = false,
    clipboard = { sync = "none" },
    close_if_last_window = true,
    enable_diagnostics = true,
    enable_git_status = true,
    enable_modified_markers = true,
    enable_opened_markers = true,
    -- Only used without `use_libuv_file_watcher` (enabled for filesystem below).
    enable_refresh_on_write = true,
    enable_cursor_hijack = false,
    git_status_async = true,
    git_status_async_options = {
      batch_size = 1000,
      batch_delay = 10,
      max_lines = 10000,
    },
    git_status_scope_to_path = false,
    hide_root_node = false,
    retain_hidden_root_indent = false,
    keep_altfile = false,
    log_level = vim.log.levels.INFO,
    log_to_file = false,
    open_files_in_last_window = true,
    -- Windows a file opened from the tree never replaces.
    open_files_do_not_replace_types = { "terminal", "trouble", "qf" },
    open_files_using_relative_paths = false,
    popup_border_style = POPUP_BORDERS[user.ui.border] and user.ui.border or "",
    resize_timer_interval = 500,
    sort_case_insensitive = true,
    use_popups_for_input = true,
    use_default_mappings = true,
    -- Tabs would take the winbar, which belongs to dropbar.
    source_selector = { winbar = false, statusline = false },

    default_component_configs = {
      container = {
        enable_character_fade = true,
        width = "100%",
        right_padding = 0,
      },
      indent = {
        indent_size = 2,
        padding = 1,
        with_markers = true,
        indent_marker = "│",
        last_indent_marker = "└",
        highlight = "NeoTreeIndentMarker",
        with_expanders = true,
        expander_collapsed = icons.ui.chevron_right,
        expander_expanded = icons.ui.chevron_down,
        expander_highlight = "NeoTreeExpander",
      },
      icon = {
        folder_closed = icons.ui.folder_closed,
        folder_open = icons.ui.folder_open,
        folder_empty = icons.ui.folder_empty,
        folder_empty_open = icons.ui.folder_empty_open,
        -- Fallback only: file icons come from nvim-web-devicons.
        default = icons.ui.file,
        highlight = "NeoTreeFileIcon",
        use_filtered_colors = true,
      },
      modified = {
        symbol = icons.ui.dot,
        highlight = "NeoTreeModified",
      },
      name = {
        trailing_slash = false,
        highlight_opened_files = false,
        use_filtered_colors = true,
        use_git_status_colors = true,
        highlight = "NeoTreeFileName",
      },
      git_status = {
        symbols = {
          -- Change type
          added = icons.git.added,
          deleted = icons.git.removed,
          modified = icons.git.modified,
          renamed = icons.git.renamed,
          -- Status type
          untracked = icons.git.untracked,
          ignored = icons.git.ignored,
          unstaged = icons.git.unstaged,
          staged = icons.git.staged,
          conflict = icons.git.conflict,
        },
        align = "right",
      },
      diagnostics = {
        symbols = {
          hint = icons.diagnostics.Hint,
          info = icons.diagnostics.Info,
          warn = icons.diagnostics.Warn,
          error = icons.diagnostics.Error,
        },
        highlights = {
          hint = "DiagnosticSignHint",
          info = "DiagnosticSignInfo",
          warn = "DiagnosticSignWarn",
          error = "DiagnosticSignError",
        },
      },
      file_size = { enabled = false },
      type = { enabled = false },
      last_modified = { enabled = false },
      created = { enabled = false },
      symlink_target = { enabled = false },
    },

    window = {
      position = user.explorer.position,
      width = user.explorer.width,
      height = 15, -- top/bottom positions only
      auto_expand_width = false,
      popup = { -- position = "float" only
        size = { height = "80%", width = "50%" },
        position = "50%",
      },
      insert_as = "child",
      mapping_options = { noremap = true, nowait = true },
      mappings = window_mappings,
    },

    filesystem = {
      window = {
        mappings = order_mappings({
          ["H"] = "toggle_hidden",
          ["/"] = "fuzzy_finder",
          ["D"] = "fuzzy_finder_directory",
          ["#"] = "fuzzy_sorter",
          ["f"] = "filter_on_submit",
          ["<C-x>"] = "clear_filter",
          ["<bs>"] = "navigate_up",
          ["."] = "set_root",
          ["[g"] = "prev_git_modified",
          ["]g"] = "next_git_modified",
          ["i"] = "show_file_details",
          ["b"] = "rename_basename",
          ["og"] = { "order_by_git_status", nowait = false },
        }),
      },
      async_directory_scan = "auto",
      -- "deep" would pre-scan directories so empty ones group before expanding.
      scan_mode = "shallow",
      bind_to_cwd = true,
      cwd_target = { sidebar = "tab", current = "window" },
      check_gitignore_in_search = true,
      filtered_items = {
        visible = false, -- `H` toggles hidden items on
        force_visible_in_empty_folder = false,
        children_inherit_highlights = true,
        show_hidden_count = true,
        hide_dotfiles = false,
        hide_gitignored = user.explorer.hide_gitignored,
        hide_ignored = true,
        ignore_files = { ".neotreeignore", ".ignore" },
        hide_hidden = false, -- Windows-only attribute
        hide_by_name = { "node_modules", ".git", "dist", "coverage", ".turbo" },
        hide_by_pattern = {},
        always_show = {},
        always_show_by_pattern = {},
        never_show = { ".DS_Store", "thumbs.db" },
        never_show_by_pattern = {},
      },
      find_by_full_path_words = false,
      group_empty_dirs = true,
      search_limit = 50,
      follow_current_file = { enabled = true, leave_dirs_open = false },
      -- Directories go to neo-tree in its side window; oil (`-`) is separate.
      hijack_netrw_behavior = "open_default",
      use_libuv_file_watcher = true,
    },

    buffers = {
      bind_to_cwd = true,
      follow_current_file = { enabled = true, leave_dirs_open = false },
      group_empty_dirs = true,
      show_unloaded = true,
      terminals_first = false,
      window = {
        mappings = order_mappings({
          ["<bs>"] = "navigate_up",
          ["."] = "set_root",
          ["d"] = "buffer_delete",
          ["bd"] = "buffer_delete",
          ["i"] = "show_file_details",
          ["b"] = "rename_basename",
        }),
      },
    },

    git_status = {
      window = {
        position = "float",
        mappings = order_mappings({
          ["A"] = "git_add_all",
          ["gu"] = "git_unstage_file",
          ["gU"] = "git_undo_last_commit",
          ["ga"] = "git_add_file",
          ["gt"] = "git_toggle_file_stage",
          ["gr"] = "git_revert_file",
          ["gc"] = "git_commit",
          ["gp"] = "git_push",
          ["gl"] = "git_pull",
          ["gg"] = "git_commit_and_push",
          ["i"] = "show_file_details",
          ["b"] = "rename_basename",
        }),
      },
    },

    document_symbols = {
      follow_cursor = true,
      follow_tree_cursor = false,
      client_filters = "first",
      ignore_symbols = {},
      kinds = symbol_kinds(),
      window = {
        mappings = {
          ["<cr>"] = "jump_to_symbol",
          ["o"] = "jump_to_symbol",
          ["A"] = "noop",
          ["d"] = "noop",
          ["y"] = "noop",
          ["x"] = "noop",
          ["p"] = "noop",
          ["c"] = "noop",
          ["m"] = "noop",
          ["a"] = "noop",
          ["T"] = "noop",
          ["<C-r>"] = "noop",
          ["u"] = "noop",
          ["U"] = "noop",
          ["/"] = "filter",
          ["f"] = "filter_on_submit",
        },
      },
    },

    -- The tree stays open after a file is opened. To close it instead, add a
    -- `file_opened` handler calling
    -- `require("neo-tree.command").execute({ action = "close" })`.
    event_handlers = vim.list_extend(require("settings.ui.theme").neo_tree_handlers(), {
      { event = "file_renamed", handler = did_rename_files },
      { event = "file_moved", handler = did_rename_files },
    }),
  }
end

return M
