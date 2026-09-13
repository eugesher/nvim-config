local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.event = { "BufReadPost", "BufNewFile" }

M.keys = {
  {
    "<leader>;",
    function()
      require("dropbar.api").pick()
    end,
    desc = "Pick breadcrumb",
  },
}

local EXCLUDED_FILETYPES = {
  "neo-tree",
  "trouble",
  "dbui",
  "dbout",
  "dap-view",
  "dap-view-term",
  "dap-repl",
  "aerial",
  "aerial-nav",
  "oil",
  "help",
  "qf",
  "lazy",
  "mason",
  "checkhealth",
}

local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

local function center(win, range)
  local view = vim.fn.winsaveview()
  view.topline =
    math.max(1, range.start.line + 1 - math.floor(vim.api.nvim_win_get_height(win) / 2))
  vim.fn.winrestview(view)
end

function M.opts()
  local defaults = require("dropbar.configs").opts
  local default_enable = defaults.bar.enable

  return {
    bar = {
      enable = function(buf, win, info)
        buf = buf or vim.api.nvim_get_current_buf()
        if not vim.api.nvim_buf_is_valid(buf) then
          return false
        end
        local filetype = vim.bo[buf].filetype
        if
          vim.tbl_contains(EXCLUDED_FILETYPES, filetype)
          or filetype:match("^neotest%-")
          or vim.bo[buf].buftype ~= ""
          or vim.api.nvim_buf_get_name(buf) == ""
        then
          return false
        end
        return default_enable(buf, win, info)
      end,
      attach_events = {
        "TermOpen",
        "BufEnter",
        "BufWinEnter",
        "BufWritePost",
        "FileType",
        "LspAttach",
      },
      update_debounce = 32,
      update_events = {
        win = { "CursorMoved", "WinEnter", "WinResized" },
        buf = {
          { event = "OptionSet", pattern = "modified" },
          "FileChangedShellPost",
          "TextChanged",
          "ModeChanged",
        },
        global = { "DirChanged", "VimResized" },
      },
      hover = true,
      sources = function(buf, _)
        local sources = require("dropbar.sources")
        local utils = require("dropbar.utils")
        if vim.bo[buf].filetype == "markdown" then
          return { sources.path, sources.markdown }
        end
        if vim.bo[buf].buftype == "terminal" then
          return { sources.terminal }
        end
        return {
          sources.path,
          utils.source.fallback({ sources.lsp, sources.treesitter }),
        }
      end,
      padding = { left = 1, right = 1 },
      pick = { pivots = "abcdefghijklmnopqrstuvwxyz" },
      truncate = true,
      gc = { interval = 60000 },
    },

    menu = {
      quick_navigation = true,
      entry = { padding = { left = 1, right = 1 } },
      preview = true,
      hover = true,
      keymaps = {
        ["q"] = defaults.menu.keymaps["q"],
        ["<Esc>"] = defaults.menu.keymaps["<Esc>"],
        ["<LeftMouse>"] = defaults.menu.keymaps["<LeftMouse>"],
        ["<CR>"] = defaults.menu.keymaps["<CR>"],
        ["<MouseMove>"] = defaults.menu.keymaps["<MouseMove>"],
        ["i"] = defaults.menu.keymaps["i"],
      },
      scrollbar = { enable = true, background = true },
      win_configs = { border = user.ui.border, style = "minimal" },
    },

    fzf = {
      keymaps = {
        ["<LeftMouse>"] = defaults.fzf.keymaps["<LeftMouse>"],
        ["<MouseMove>"] = defaults.fzf.keymaps["<MouseMove>"],
        ["<Up>"] = defaults.fzf.keymaps["<Up>"],
        ["<Down>"] = defaults.fzf.keymaps["<Down>"],
        ["<C-k>"] = defaults.fzf.keymaps["<C-k>"],
        ["<C-j>"] = defaults.fzf.keymaps["<C-j>"],
        ["<C-p>"] = defaults.fzf.keymaps["<C-p>"],
        ["<C-n>"] = defaults.fzf.keymaps["<C-n>"],
        ["<CR>"] = defaults.fzf.keymaps["<CR>"],
        ["<S-Enter>"] = defaults.fzf.keymaps["<S-Enter>"],
      },
      win_configs = { border = user.ui.border },
      prompt = "%#htmlTag# ",
      char_pattern = "[%w%p]",
      retain_inner_spaces = true,
      fuzzy_find_on_click = true,
    },

    icons = {
      enable = true,
      kinds = {
        dir_icon = defaults.icons.kinds.dir_icon,
        file_icon = defaults.icons.kinds.file_icon,
        symbols = kind_icons(),
      },
      ui = {
        bar = { separator = " " .. icons.ui.chevron_right .. " ", extends = "…" },
        menu = { separator = " ", indicator = icons.ui.chevron_right .. " " },
      },
    },

    symbol = {
      on_click = defaults.symbol.on_click,
      preview = { reorient = center },
      jump = { reorient = center },
    },

    sources = {
      path = {
        max_depth = 16,
        relative_to = function(_, win)
          local ok, cwd = pcall(vim.fn.getcwd, win)
          return ok and cwd or vim.fn.getcwd()
        end,
        filter = function(_)
          return true
        end,
        modified = function(sym)
          return sym:merge({
            name = sym.name .. " " .. icons.ui.dot,
            name_hl = "DiagnosticWarn",
          })
        end,
        preview = true,
        min_widths = {},
      },
      treesitter = {
        max_depth = 4,
        name_regex = [=[[#~!@\*&.]*[[:keyword:]]\+!\?\(\(\(->\)\+\|-\+\|\.\+\|:\+\|\s\+\)\?[#~!@\*&.]*[[:keyword:]]\+!\?\)*]=],
        valid_types = {
          "class_declaration",
          "abstract_class_declaration",
          "interface_declaration",
          "enum_declaration",
          "type_alias_declaration",
          "function_declaration",
          "generator_function_declaration",
          "method_definition",
          "public_field_definition",
          "internal_module",
          "field",
          "pair",
          "block_mapping_pair",
        },
        min_widths = {},
      },
      lsp = {
        max_depth = 4,
        valid_symbols = {
          "File",
          "Module",
          "Namespace",
          "Package",
          "Class",
          "Method",
          "Property",
          "Field",
          "Constructor",
          "Enum",
          "Interface",
          "Function",
          "Variable",
          "Constant",
          "String",
          "Number",
          "Boolean",
          "Array",
          "Object",
          "Keyword",
          "Null",
          "EnumMember",
          "Struct",
          "Event",
          "Operator",
          "TypeParameter",
        },
        request = { ttl_init = 60, interval = 1000 },
        min_widths = {},
      },
      markdown = {
        max_depth = 6,
        parse = { look_ahead = 200 },
        min_widths = {},
      },
      terminal = {
        icon = function(_)
          return require("dropbar.configs").opts.icons.kinds.symbols.Terminal or " "
        end,
        name = vim.api.nvim_buf_get_name,
        show_current = true,
      },
    },
  }
end

return M
