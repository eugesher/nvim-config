local M = {}

local OVERRIDE = vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", "lua_ls.json")

local OVERRIDE_JSON = table.concat({
  "{",
  '"runtime.plugin": [],',
  '"runtime.meta": "${version} ${language} ${encoding}",',
  '"workspace.checkThirdParty": "Disable",',
  '"workspace.userThirdParty": []',
  "}",
}, " ")

local function write_override()
  vim.fn.mkdir(vim.fs.dirname(OVERRIDE), "p", tonumber("700", 8))
  local temp = ("%s.%d.tmp"):format(OVERRIDE, vim.uv.os_getpid())
  local fd = vim.uv.fs_open(temp, "w", tonumber("600", 8))
  if not fd then
    return false
  end
  local written = vim.uv.fs_write(fd, OVERRIDE_JSON)
  local closed = vim.uv.fs_close(fd)
  if written ~= #OVERRIDE_JSON or not closed or not vim.uv.fs_rename(temp, OVERRIDE) then
    vim.uv.fs_unlink(temp)
    return false
  end
  return true
end

M.config = {
  cmd = function(dispatchers, config)
    if not write_override() then
      error("lua_ls not started: cannot write " .. OVERRIDE)
    end
    return vim.lsp.rpc.start(
      { "lua-language-server", "--configpath=" .. OVERRIDE },
      dispatchers,
      { cwd = config.cmd_cwd, env = config.cmd_env, detached = config.detached }
    )
  end,
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
