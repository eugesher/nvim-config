-- defaults verified against lua-language-server 3.19.1 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- Lua, tuned for Neovim configs and plugins. nvim/.luarc.json repeats the
-- basics for editors that read it directly.

local M = {}

M.config = {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        checkThirdParty = false, -- no "configure your environment?" prompts
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua", -- lazy.nvim types for plugin specs
        },
      },
      -- Every kind of inlay hint.
      hint = {
        enable = true,
        paramType = true,
        setType = true,
        paramName = "All",
        await = true,
        arrayIndex = "Enable",
        semicolon = "SameLine", -- only where a statement shares its line
      },
      codeLens = { enable = true },
      format = { enable = false }, -- stylua formats Lua
      completion = { callSnippet = "Replace" },
      -- No `telemetry`: lua-language-server 3.19 has no such setting any more.
    },
  },
}

return M
