local M = {}

M.config = {
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      diagnostics = { globals = { "vim" } },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          vim.fn.stdpath("data") .. "/lazy/lazy.nvim/lua",
        },
      },
      hint = {
        enable = true,
        paramType = true,
        setType = true,
        paramName = "All",
        await = true,
        arrayIndex = "Enable",
        semicolon = "SameLine",
      },
      codeLens = { enable = true },
      format = { enable = false },
      completion = { callSnippet = "Replace" },
    },
  },
}

return M
