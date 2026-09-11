-- defaults verified against blink.cmp v1.10.2 (2026-09-11)
--
-- Completion engine. Pinned to 1.x in plugins/completion.lua. Default
-- implementations that are code rather than settings (menu components,
-- documentation `draw`, buffer `get_bufnrs`, …) are left to blink.cmp.

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

M.event = { "InsertEnter", "CmdlineEnter" }

M.opts = {
  -- Default conditions still apply (no prompt buffers, `vim.b.completion ~= false`).
  enabled = function()
    return true
  end,

  -- Every key listed by hand. <Tab> / <S-Tab> only jump through snippet fields,
  -- they never accept a completion. <C-s> stays Neovim's signature help.
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
    keyword = { range = "prefix" }, -- match only the text before the cursor
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
        preselect = true, -- <CR> accepts the first item right away
        auto_insert = false, -- moving through the list does not touch the buffer
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
        treesitter = { "lsp" }, -- highlight LSP labels with treesitter
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
    -- On purpose: no AI plugin in the stack, so nothing else draws ghost text.
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
    -- Rust matcher (prebuilt binary for the pinned tag); falls back to Lua with
    -- a warning. Without network access, set "lua".
    implementation = "prefer_rust_with_warning",
    max_typos = function(keyword)
      return math.floor(#keyword / 4)
    end,
    -- `use_frecency` is the deprecated name of `frecency.enabled`.
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
      -- `force_version` / `force_system_triple` stay unset: inferred from the git tag and jit.os / jit.arch.
      extra_curl_args = {},
      proxy = { from_env = true },
    },
  },

  sources = {
    default = { "lsp", "snippets", "path", "buffer" },
    -- dadbod completion is added buffer-locally for SQL in task 14 — never here,
    -- or SQL suggestions would show up in TypeScript.
    per_filetype = {},
    transform_items = function(_, items)
      return items
    end,
    min_keyword_length = 0,
    providers = {
      lsp = {
        score_offset = 100,
        fallbacks = { "buffer" }, -- buffer words only when the server has nothing
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
          enable_in_ex_commands = false, -- would switch off 'inccommand' previews
        },
      },
    },
  },

  -- LuaSnip expands and jumps (settings/luasnip.lua).
  snippets = { preset = "luasnip", score_offset = -3 },

  cmdline = {
    enabled = true,
    -- In the command line <Tab> completes, as it always has.
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
        -- The menu opens on <Tab>, not while typing (always in the cmdwin).
        auto_show = function(ctx)
          return ctx.mode == "cmdwin"
        end,
      },
      ghost_text = { enabled = true },
    },
  },

  -- No completion inside :terminal buffers.
  term = { enabled = false },
}

return M
