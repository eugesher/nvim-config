local user = require("user.settings")
local icons = require("settings.icons")
local sql_filetypes = require("settings.database.dadbod-completion").ft

local M = {}

local function per_filetype()
  local sources = {}
  for _, filetype in ipairs(sql_filetypes) do
    sources[filetype] = { inherit_defaults = true, "dadbod" }
  end
  return sources
end

M.event = { "InsertEnter", "CmdlineEnter" }

M.opts = {
  enabled = function()
    return true
  end,

  keymap = {
    preset = "none",
    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-j>"] = { "select_next", "fallback" },
    ["<C-k>"] = { "select_prev", "fallback" },
    ["<C-n>"] = { "select_next", "fallback" },
    ["<C-p>"] = { "select_prev", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<C-e>"] = { "hide", "fallback" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<Tab>"] = { "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "snippet_backward", "fallback" },
  },

  appearance = {
    highlight_ns = vim.api.nvim_create_namespace("blink_cmp"),
    use_nvim_cmp_as_default = false,
    nerd_font_variant = "mono",
    kind_icons = icons.kinds,
  },

  completion = {
    keyword = { range = "prefix" },
    trigger = {
      prefetch_on_insert = true,
      show_in_snippet = true,
      show_on_backspace = false,
      show_on_backspace_in_keyword = false,
      show_on_backspace_after_accept = true,
      show_on_backspace_after_insert_enter = true,
      show_on_keyword = true,
      show_on_trigger_character = true,
      show_on_insert = false,
      show_on_blocked_trigger_characters = { " ", "\n", "\t" },
      show_on_accept_on_trigger_character = true,
      show_on_insert_on_trigger_character = true,
      show_on_x_blocked_trigger_characters = { "'", '"', "(" },
    },
    list = {
      max_items = 200,
      selection = {
        preselect = true,
        auto_insert = false,
      },
      cycle = { from_bottom = true, from_top = true },
    },
    accept = {
      dot_repeat = true,
      create_undo_point = true,
      resolve_timeout_ms = 100,
      auto_brackets = {
        enabled = true,
        default_brackets = { "(", ")" },
        override_brackets_for_filetypes = {},
        kind_resolution = {
          enabled = true,
          blocked_filetypes = { "typescriptreact", "javascriptreact", "vue" },
        },
        semantic_token_resolution = {
          enabled = true,
          blocked_filetypes = { "java" },
          timeout_ms = 400,
        },
      },
    },
    menu = {
      enabled = true,
      min_width = 15,
      max_height = 10,
      border = user.ui.border,
      winblend = 0,
      winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
      scrolloff = 2,
      scrollbar = false,
      direction_priority = { "s", "n" },
      auto_show = true,
      auto_show_delay_ms = 0,
      draw = {
        align_to = "label",
        padding = 1,
        gap = 1,
        cursorline_priority = 10000,
        snippet_indicator = "~",
        treesitter = { "lsp" },
        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 }, { "kind" } },
      },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
      update_delay_ms = 50,
      treesitter_highlighting = true,
      window = {
        min_width = 10,
        max_width = 80,
        max_height = 20,
        border = user.ui.border,
        winblend = 0,
        winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
        scrollbar = true,
        direction_priority = {
          menu_north = { "e", "w", "n", "s" },
          menu_south = { "e", "w", "s", "n" },
        },
      },
    },
    ghost_text = {
      enabled = true,
      show_with_selection = true,
      show_without_selection = false,
      show_with_menu = true,
      show_without_menu = true,
    },
  },

  signature = {
    enabled = true,
    trigger = {
      enabled = true,
      show_on_keyword = false,
      blocked_trigger_characters = {},
      blocked_retrigger_characters = {},
      show_on_trigger_character = true,
      show_on_insert = false,
      show_on_insert_on_trigger_character = true,
    },
    window = {
      min_width = 1,
      max_width = 100,
      max_height = 10,
      border = user.ui.border,
      winblend = 0,
      winhighlight = "Normal:BlinkCmpSignatureHelp,FloatBorder:BlinkCmpSignatureHelpBorder",
      scrollbar = false,
      direction_priority = { "n", "s" },
      treesitter_highlighting = true,
      show_documentation = true,
    },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
    max_typos = function(keyword)
      return math.floor(#keyword / 4)
    end,
    frecency = {
      enabled = true,
      path = vim.fn.stdpath("state") .. "/blink/cmp/frecency.dat",
      unsafe_no_lock = false,
    },
    use_proximity = true,
    sorts = { "score", "sort_text" },
    prebuilt_binaries = {
      download = true,
      ignore_version_mismatch = false,
      extra_curl_args = {},
      proxy = { from_env = true },
    },
  },

  sources = {
    default = { "lsp", "snippets", "path", "buffer" },
    per_filetype = per_filetype(),
    transform_items = function(_, items)
      return items
    end,
    min_keyword_length = 0,
    providers = {
      lsp = {
        score_offset = 100,
        fallbacks = { "buffer" },
      },
      snippets = {
        score_offset = 80,
        opts = {
          use_show_condition = true,
          show_autosnippets = true,
          prefer_doc_trig = false,
          use_label_description = false,
        },
      },
      path = {
        score_offset = 60,
        fallbacks = { "buffer" },
        opts = {
          trailing_slash = true,
          label_trailing_slash = true,
          show_hidden_files_by_default = false,
          ignore_root_slash = false,
          max_entries = 10000,
        },
      },
      buffer = {
        score_offset = 20,
        opts = {
          max_sync_buffer_size = 20000,
          max_async_buffer_size = 200000,
          max_total_buffer_size = 500000,
          retention_order = { "focused", "visible", "recency", "largest" },
          use_cache = true,
          enable_in_ex_commands = false,
        },
      },
      dadbod = {
        name = "Dadbod",
        module = "vim_dadbod_completion.blink",
        score_offset = 90,
      },
    },
  },

  snippets = { preset = "luasnip", score_offset = -3 },

  cmdline = {
    enabled = true,
    keymap = {
      preset = "none",
      ["<Tab>"] = { "show_and_insert_or_accept_single", "select_next" },
      ["<S-Tab>"] = { "show_and_insert_or_accept_single", "select_prev" },
      ["<C-space>"] = { "show", "fallback" },
      ["<C-n>"] = { "select_next", "fallback" },
      ["<C-p>"] = { "select_prev", "fallback" },
      ["<Right>"] = { "select_next", "fallback" },
      ["<Left>"] = { "select_prev", "fallback" },
      ["<C-y>"] = { "select_and_accept", "fallback" },
      ["<C-e>"] = { "cancel", "fallback" },
    },
    sources = { "buffer", "cmdline" },
    completion = {
      trigger = {
        show_on_blocked_trigger_characters = {},
        show_on_x_blocked_trigger_characters = {},
      },
      list = { selection = { preselect = true, auto_insert = true } },
      menu = {
        auto_show = function(ctx)
          return ctx.mode == "cmdwin"
        end,
      },
      ghost_text = { enabled = true },
    },
  },

  term = { enabled = false },
}

return M
