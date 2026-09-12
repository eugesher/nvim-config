-- defaults verified against dropbar.nvim v14.2.1-12-g808ba31 (2026-09-13)
--
-- Breadcrumbs in the winbar: the file path and the class / method under the
-- cursor. Every component opens a menu of its siblings with a preview — by
-- mouse or with `<leader>;`. The only winbar plugin of this config: lualine's
-- `winbar` stays empty (settings/lualine.lua).
--
-- Option tables are deep-merged into the defaults of lua/dropbar/configs.lua —
-- the file the README names as the reference. Where a default is a function
-- (menu keys, click handler, file icons), the plugin's own function is taken
-- from there instead of being copied.

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

-- Panels and auxiliary buffers never get breadcrumbs. Most are `nofile`
-- buffers and fail the `buftype` check below as well; the list keeps them out
-- even if a plugin changes that.
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

-- Glyphs with the trailing space dropbar expects after an icon.
local function kind_icons()
  local padded = {}
  for kind, glyph in pairs(icons.kinds) do
    padded[kind] = glyph .. " "
  end
  return padded
end

-- `reorient` runs inside the source window, after the cursor is already on the
-- symbol: centering is all that is left to do. Through the view, not
-- `:normal! zz` — the preview also runs while `i` opens the fuzzy prompt, and a
-- `:normal` at that moment takes the focus off the prompt, which then closes
-- at once (measured in task 26).
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
          -- Terminals, quickfix, help and every `nofile` panel.
          or vim.bo[buf].buftype ~= ""
          -- The empty buffer on startup has neither a path nor symbols.
          or vim.api.nvim_buf_get_name(buf) == ""
        then
          return false
        end
        -- The plugin's own checks: normal window, no winbar of its own, files
        -- under 1 MB, a treesitter parser or an LSP with document symbols.
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
      hover = true, -- 'mousemoveevent' is on (settings/bufferline.lua)
      -- The path, then the symbols: LSP when it answers, treesitter until then
      -- — the crumbs are there the moment the file opens, before vtsls starts.
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
        ["i"] = defaults.menu.keymaps["i"], -- filter the menu with fzf
      },
      scrollbar = { enable = true, background = true },
      -- Position and size stay the plugin's functions (merged in).
      win_configs = { border = user.ui.border, style = "minimal" },
    },

    -- The fuzzy filter opened with `i` inside a menu. It matches with `fzf_lib`
    -- from telescope-fzf-native.nvim (a dependency, plugins/structure.lua);
    -- without it `i` only reports "fzf-lib is not installed".
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
        file_icon = defaults.icons.kinds.file_icon, -- nvim-web-devicons
        -- Merged over dropbar's set, which also covers treesitter node types
        -- (IfStatement, Pair, …) that have no LSP kind.
        symbols = kind_icons(),
      },
      ui = {
        bar = { separator = " " .. icons.ui.chevron_right .. " ", extends = "…" },
        menu = { separator = " ", indicator = icons.ui.chevron_right .. " " },
      },
    },

    symbol = {
      on_click = defaults.symbol.on_click, -- open the menu of siblings
      -- Previewed and jumped-to symbols land in the middle of the window, as
      -- after a jump from aerial (`post_jump_cmd`, settings/aerial.lua).
      preview = { reorient = center },
      jump = { reorient = center },
    },

    sources = {
      path = {
        max_depth = 16,
        relative_to = function(_, win)
          -- Works around E5002 for a window that is already gone.
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
        -- Declarations only, not the plugin's ~50 defaults. A node counts when its
        -- type STARTS with an entry, so the defaults also catch `class_body`
        -- (named after its first line: `private readonly cacheTtl`),
        -- `property_identifier` (every method twice) and Lua's `table_constructor`,
        -- and statements such as `return` or `call` push the class and the method
        -- out of `max_depth`. Measured in task 26, inside a method of a service:
        --   defaults: private readonly cacheTtl › findOne › return this.findAll › …
        --   this list: class UsersService › findOne
        -- LSP symbols replace these as soon as the server answers.
        valid_types = {
          -- TypeScript / JavaScript
          "class_declaration",
          "abstract_class_declaration",
          "interface_declaration",
          "enum_declaration",
          "type_alias_declaration",
          "function_declaration", -- also Lua's named functions
          "generator_function_declaration",
          "method_definition",
          "public_field_definition",
          "internal_module", -- `namespace Foo {}`
          -- Lua tables
          "field",
          -- JSON / YAML / TOML keys
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
      -- Terminal buffers are excluded in `bar.enable`; stated for completeness.
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
