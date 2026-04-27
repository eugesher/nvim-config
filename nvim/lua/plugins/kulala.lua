-- ~/.config/nvim/lua/plugins/kulala.lua
-- HTTP client: kulala.nvim. Run REST requests written in `.http` / `.rest`
-- files (JetBrains-style) directly from a Neovim buffer, with response
-- rendering, environment switching, and chained requests.
--
-- Why kulala over alternatives (rest.nvim, vim-rest-console):
--   * Active maintenance and a rich feature set (named requests, env files,
--     response references, scratchpad).
--   * Reuses Treesitter `http` for parsing and highlighting — no bespoke
--     regex parser to drift from the spec.
--   * Mirrors JetBrains' `.http` syntax, so files written in IDEA / WebStorm
--     work without translation.
--
-- Layout:
--   * Plugin loads only on the `http` / `rest` filetypes (`ft = ...`).
--   * `global_keymaps = false` — every keymap below is registered manually
--     via a buffer-local FileType autocmd, mirroring the dadbod pattern.
--     Keeps `<leader>h*` from polluting non-HTTP buffers.
--   * `nvim-treesitter` is listed as a dependency: kulala parses requests
--     via the `http` grammar (added to ensure_installed in treesitter.lua).
--   * Optional system tools `jq` and `xmllint` are wired up as response
--     formatters — they are graceful no-ops if the binary is missing.

return {
  "mistweaverco/kulala.nvim",
  version = "*", -- Pin to the latest stable release tag
  ft = { "http", "rest" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    -- We define every keymap manually below so the prefix is consistent
    -- with the rest of the config and never leaks into non-HTTP buffers.
    global_keymaps = false,
    split_direction = "horizontal",
    display_mode = "split",
    default_view = "body",
    default_env = "dev",
    icons = {
      inlay = {
        loading = "⏳",
        done = "✅",
        error = "❌",
      },
    },
    -- Pretty-print responses by content type. Both binaries are optional —
    -- kulala falls back to the raw payload if either is absent.
    formatters = {
      json = { "jq", "." },
      xml = { "xmllint", "--format", "-" },
    },
  },
  config = function(_, opts)
    require("kulala").setup(opts)

    -- Buffer-local keymaps for `http` / `rest` buffers. Registered via a
    -- FileType autocmd so they attach to every matching buffer (including
    -- ones opened after kulala has already been loaded) without leaking
    -- the `<leader>h*` prefix into TS / Lua / etc.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("KulalaKeymaps", { clear = true }),
      pattern = { "http", "rest" },
      desc = "Register buffer-local kulala.nvim keymaps",
      callback = function(args)
        local kulala = require("kulala")
        local map = function(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, { buffer = args.buf, desc = desc })
        end

        map("<leader>hh", kulala.run, "HTTP: run request under cursor")
        map("<leader>ha", kulala.run_all, "HTTP: run all requests in file")
        map("<leader>hn", kulala.jump_next, "HTTP: jump to next request")
        map("<leader>hp", kulala.jump_prev, "HTTP: jump to previous request")
        map("<leader>he", kulala.set_selected_env, "HTTP: select environment")
        map("<leader>hc", kulala.copy, "HTTP: copy request as curl")
        map("<leader>hb", kulala.show_body, "HTTP: show response body")
        map("<leader>hH", kulala.show_headers, "HTTP: show response headers")
        map("<leader>hs", kulala.show_headers_body, "HTTP: show headers + body")
        map("<leader>hx", kulala.close, "HTTP: close response window")
        map("<leader>hi", kulala.inspect, "HTTP: inspect request (dry-run)")
        map("<leader>hS", kulala.scratchpad, "HTTP: open scratchpad buffer")
      end,
    })
  end,
}
