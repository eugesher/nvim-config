-- ~/.config/nvim/lua/plugins/lsp.lua
-- Language Server Protocol setup for Neovim 0.11+.
--
-- Uses the native `vim.lsp.config()` and `vim.lsp.enable()` API introduced in
-- Neovim 0.11. The legacy `require('lspconfig').server.setup{}` pattern is
-- deprecated and will be removed in nvim-lspconfig v3.0.0.
--
-- nvim-lspconfig still ships `lsp/*.lua` defaults (cmd, filetypes, root_dir)
-- for each server; we only provide overrides/extensions via `vim.lsp.config()`.
-- mason-lspconfig v2 automatically calls `vim.lsp.enable()` on installed
-- servers, so we don't need to enable them by hand.

return {
  -- Mason: installs and manages LSP servers, linters, formatters, DAP adapters
  {
    "mason-org/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },

  -- nvim-lspconfig: provides the default server configs (cmd, filetypes, etc.)
  -- that `vim.lsp.config()` merges with our overrides. We also register the
  -- LspAttach autocommand here so our keymaps are set up regardless of which
  -- server actually attaches.
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- Buffer-local LSP keymaps, registered whenever a client attaches.
      -- This replaces the legacy per-server `on_attach` pattern.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
        desc = "LSP buffer-local keymaps",
        callback = function(args)
          local bufnr = args.buf
          local opts = { buffer = bufnr, noremap = true, silent = true }
          local keymap = vim.keymap.set

          -- Code navigation
          keymap(
            "n",
            "gd",
            vim.lsp.buf.definition,
            vim.tbl_extend("force", opts, { desc = "Go to definition" })
          )
          keymap(
            "n",
            "gD",
            vim.lsp.buf.declaration,
            vim.tbl_extend("force", opts, { desc = "Go to declaration" })
          )
          keymap(
            "n",
            "gr",
            vim.lsp.buf.references,
            vim.tbl_extend("force", opts, { desc = "Find all references" })
          )
          keymap(
            "n",
            "gi",
            vim.lsp.buf.implementation,
            vim.tbl_extend("force", opts, { desc = "Go to implementation" })
          )
          keymap(
            "n",
            "K",
            vim.lsp.buf.hover,
            vim.tbl_extend("force", opts, { desc = "Show hover documentation" })
          )

          -- Refactoring
          keymap(
            "n",
            "<leader>rn",
            vim.lsp.buf.rename,
            vim.tbl_extend("force", opts, { desc = "Rename symbol" })
          )
          keymap(
            "n",
            "<leader>ca",
            vim.lsp.buf.code_action,
            vim.tbl_extend("force", opts, { desc = "Code action" })
          )

          -- Diagnostics.
          -- vim.diagnostic.goto_prev/goto_next were deprecated in Neovim 0.11
          -- in favor of vim.diagnostic.jump({ count = ... }).
          keymap("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
          keymap("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
          keymap(
            "n",
            "<leader>d",
            vim.diagnostic.open_float,
            vim.tbl_extend("force", opts, { desc = "Show diagnostic in floating window" })
          )
        end,
      })
    end,
  },

  -- Bridge between Mason and Neovim's LSP: auto-installs servers and calls
  -- vim.lsp.enable() on each installed server.
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      -- Per-server overrides. Each `vim.lsp.config()` call merges our settings
      -- with the defaults shipped in nvim-lspconfig's lsp/*.lua.

      -- eslint — silence the `prettier/prettier` rule at the server level.
      -- conform.nvim already runs Prettier on save, so the ESLint rule is a
      -- duplicate source of truth. In workspace mode (nvim .) the server also
      -- fails to clear these diagnostics after formatting, which surfaces as
      -- a persistent "Delete `␊`" error.
      vim.lsp.config(
        "eslint",
        {
          settings = {
            rulesCustomizations = { { rule = "prettier/prettier", severity = "off" } },
          },
        }
      )

      -- ts_ls — TypeScript / JavaScript language server
      vim.lsp.config("ts_ls", {
        settings = {
          typescript = {
            inlayHints = {
              -- Inline type / parameter hints (Neovim 0.10+)
              includeInlayParameterNameHints = "all",
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
            },
          },
        },
      })

      -- JSON — enable schema validation
      vim.lsp.config("jsonls", { settings = { json = { validate = { enable = true } } } })

      -- YAML — drop nvim-lspconfig's default compound filetypes
      -- (yaml.docker-compose, yaml.gitlab, yaml.helm-values). Without dedicated
      -- ftdetect plugins Neovim never produces these filetypes, and listing
      -- them triggers "Unknown filetype" warnings in :checkhealth.
      vim.lsp.config("yamlls", { filetypes = { "yaml" } })

      -- Lua — teach the server about the global `vim` table and skip
      -- third-party workspace scanning for faster startup.
      vim.lsp.config(
        "lua_ls",
        {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = { checkThirdParty = false },
            },
          },
        }
      )

      -- mason-lspconfig: install these servers and auto-enable them
      -- via vim.lsp.enable() (the default behavior in v2+).
      require("mason-lspconfig").setup({
        ensure_installed = { "ts_ls", "eslint", "lua_ls", "jsonls", "yamlls" },
        -- automatic_enable is true by default; it calls vim.lsp.enable()
        -- on each installed server. Leaving the default in place.
      })
    end,
  },
}
