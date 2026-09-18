local M = {}

M.event = { "BufReadPre", "BufNewFile" }

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

local function load_server_configs()
  local dir = vim.fn.stdpath("config") .. "/lua/settings/lsp/servers"
  for file, kind in vim.fs.dir(dir) do
    local name = file:match("^(.+)%.lua$")
    if kind == "file" and name then
      vim.lsp.config(name, require("settings.lsp.servers." .. name).config or {})
    end
  end
end

function M.init()
  require("settings.lsp.keymaps").setup()
end

function M.config()
  vim.lsp.log.set_level(vim.log.levels.OFF)
  vim.lsp.config("*", {
    capabilities = require("settings.lsp.capabilities").get(),
    root_markers = { ".git" },
  })
  load_server_configs()
  vim.lsp.enable(M.servers)
end

M.keys = {
  { "<leader>ll", "<cmd>Lazy<CR>", desc = "Lazy" },
  { "<leader>lm", "<cmd>Mason<CR>", desc = "Mason" },
  { "<leader>li", "<cmd>checkhealth vim.lsp<CR>", desc = "LSP clients" },
  { "<leader>lr", "<cmd>lsp restart<CR>", desc = "Restart LSP" },
  { "<leader>lc", "<cmd>checkhealth<CR>", desc = "Check health" },
  { "<leader>lp", "<cmd>Lazy profile<CR>", desc = "Lazy profile" },
  { "<leader>lu", "<cmd>Lazy update<CR>", desc = "Lazy update" },
  {
    "<leader>us",
    function()
      require("settings.lsp.servers.codebook").toggle()
    end,
    desc = "Toggle spell checking",
  },
}

return M
