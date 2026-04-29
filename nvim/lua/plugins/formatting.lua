-- ~/.config/nvim/lua/plugins/formatting.lua
-- conform.nvim: a lightweight formatter runner. Install Prettier and stylua
-- via :Mason (or configure mason-tool-installer) before using.

local settings = require("config.user-settings")

return {
  "stevearc/conform.nvim",
  event = "BufWritePre", -- Load before the first write
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_fallback = true })
      end,
      mode = { "n", "v" },
      desc = "Format buffer / selection",
    },
  },
  config = function()
    require("conform").setup({
      -- Formatter per filetype
      formatters_by_ft = {
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        markdown = { "prettier" },
        lua = { "stylua" },
      },

      -- Format on save
      format_on_save = {
        timeout_ms = settings.formatting.format_on_save_timeout_ms,
        lsp_fallback = true, -- Fall back to the LSP formatter if none is configured
      },
    })
  end,
}
