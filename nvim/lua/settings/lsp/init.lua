-- defaults verified against nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- LSP foundation; the servers themselves come in task 07. nvim-lspconfig only
-- contributes its catalogue of `lsp/<server>.lua` defaults on 'runtimepath':
-- configuration goes through Neovim's own vim.lsp.config() / vim.lsp.enable().
-- The old `require("lspconfig").<server>.setup{}` pattern is not used anywhere.

local M = {}

M.event = { "BufReadPre", "BufNewFile" }

-- Servers to enable. Empty until task 07. mason-lspconfig (`automatic_enable`,
-- settings/lsp/mason.lua) already enables every server installed through
-- Mason — only servers installed some other way belong here, otherwise they
-- would be enabled twice.
M.servers = {}

function M.config()
  -- The LSP log grows without bound (gigabytes over time): off unless debugging.
  vim.lsp.log.set_level(vim.log.levels.OFF)
  vim.lsp.config("*", {
    capabilities = require("settings.lsp.capabilities").get(),
    root_markers = { ".git" },
  })
  if #M.servers > 0 then
    vim.lsp.enable(M.servers)
  end
  require("settings.lsp.keymaps").setup()
end

-- `<leader>l`: LSP / tooling meta.
M.keys = {
  { "<leader>ll", "<cmd>Lazy<CR>", desc = "Lazy" },
  { "<leader>lm", "<cmd>Mason<CR>", desc = "Mason" },
  -- `:lsp` needs a subcommand in 0.12; client info is `:checkhealth vim.lsp`.
  { "<leader>li", "<cmd>checkhealth vim.lsp<CR>", desc = "LSP clients" },
  { "<leader>lr", "<cmd>lsp restart<CR>", desc = "Restart LSP" },
  { "<leader>lc", "<cmd>checkhealth<CR>", desc = "Check health" },
  { "<leader>lp", "<cmd>Lazy profile<CR>", desc = "Lazy profile" },
  { "<leader>lu", "<cmd>Lazy update<CR>", desc = "Lazy update" },
}

return M
