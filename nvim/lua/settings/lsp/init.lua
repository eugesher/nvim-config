-- defaults verified against nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- LSP foundation (servers: settings/lsp/servers/). nvim-lspconfig only
-- contributes its catalogue of `lsp/<server>.lua` defaults on 'runtimepath':
-- configuration goes through Neovim's own vim.lsp.config() / vim.lsp.enable().
-- The old `require("lspconfig").<server>.setup{}` pattern is not used anywhere.

local M = {}

M.event = { "BufReadPre", "BufNewFile" }

-- Servers enabled by this config; each has settings/lsp/servers/<name>.lua.
-- mason-lspconfig's `automatic_enable` enables installed servers as well —
-- harmless, vim.lsp.enable() is idempotent. Never add ts_ls next to vtsls
-- (double diagnostics).
M.servers = {
  "vtsls",
  "eslint",
  "lua_ls",
  "jsonls",
  "yamlls",
  "bashls",
  "codebook",
  "docker_language_server",
  "dockerls",
}

-- Feeds every settings/lsp/servers/<name>.lua into vim.lsp.config(<name>, …),
-- so a new server is a new file (plus its name above and in ensure_installed).
-- Each file returns `{ config = <vim.lsp.Config>, keymaps? = fun(client, buf, map) }`.
local function load_server_configs()
  local dir = vim.fn.stdpath("config") .. "/lua/settings/lsp/servers"
  for file, kind in vim.fs.dir(dir) do
    local name = file:match("^(.+)%.lua$")
    if kind == "file" and name then
      vim.lsp.config(name, require("settings.lsp.servers." .. name).config or {})
    end
  end
end

-- At startup, so LspAttach / LspDetach exist before any client can attach
-- (mason-lspconfig enables servers before this plugin's `config` runs).
function M.init()
  require("settings.lsp.keymaps").setup()
end

function M.config()
  -- The LSP log grows without bound (gigabytes over time): off unless debugging.
  vim.lsp.log.set_level(vim.log.levels.OFF)
  vim.lsp.config("*", {
    capabilities = require("settings.lsp.capabilities").get(),
    root_markers = { ".git" },
  })
  load_server_configs()
  vim.lsp.enable(M.servers)
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
  -- `<leader>u`: UI toggles. Global, not buffer-local like the LspAttach keys —
  -- the spell checker is toggled for the whole session (settings/lsp/servers/codebook.lua).
  {
    "<leader>us",
    function()
      require("settings.lsp.servers.codebook").toggle()
    end,
    desc = "Toggle spell checking",
  },
}

return M
