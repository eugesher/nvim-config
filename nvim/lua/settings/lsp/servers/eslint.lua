local trust = require("core.trust")

local M = {}

local lspconfig_root_dir

local trusted_dirs = {}

local VALIDATING = {
  ["textDocument/didOpen"] = true,
  ["textDocument/didChange"] = true,
  ["textDocument/didSave"] = true,
  ["workspace/didChangeWatchedFiles"] = true,
  ["textDocument/diagnostic"] = true,
  ["textDocument/codeAction"] = true,
  ["textDocument/formatting"] = true,
  ["workspace/executeCommand"] = true,
}

local restarting = false

local function changed(client)
  return not vim.iter(trusted_dirs[client.root_dir] or {}):all(trust.trusted)
end

local function restart()
  if restarting then
    return
  end
  restarting = true
  vim.schedule(function()
    restarting = false
    trusted_dirs = {}
    vim.lsp.enable("eslint", false)
    vim.lsp.enable("eslint")
  end)
end

local ESLINT_PARENTS = vim.list_extend({ "package.json", "node_modules" }, trust.eslint_configs)

local function default_root_dir()
  if lspconfig_root_dir == nil then
    local file = vim.api.nvim_get_runtime_file("lsp/eslint.lua", false)[1]
    lspconfig_root_dir = file and dofile(file).root_dir or false
  end
  return lspconfig_root_dir
end

M.config = {
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_dir = function(bufnr, on_dir)
    local root_dir = default_root_dir()
    if not root_dir then
      return
    end
    root_dir(bufnr, function(root)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end
        local inside = vim.fs.relpath(root, vim.api.nvim_buf_get_name(bufnr)) ~= nil
        local library = vim.fs.joinpath(root, "node_modules", "eslint", "package.json")
        if not inside or not vim.uv.fs_stat(library) then
          return
        end
        local own = trust.root(bufnr)
        local deepest = own and vim.fs.relpath(root, own) and own or root
        local dirs = trust.parents(deepest, ESLINT_PARENTS)
        for _, dir in ipairs({ root, own }) do
          if not vim.list_contains(dirs, dir) then
            dirs[#dirs + 1] = dir
          end
        end
        if vim.iter(dirs):all(trust.allowed) then
          trusted_dirs[root] = trusted_dirs[root] or {}
          for _, dir in ipairs(dirs) do
            if not vim.list_contains(trusted_dirs[root], dir) then
              table.insert(trusted_dirs[root], dir)
            end
          end
          on_dir(root)
        end
      end)
    end)
  end,
  on_init = function(client)
    for _, name in ipairs({ "notify", "request" }) do
      local send = client[name]
      client[name] = function(self, method, ...)
        if VALIDATING[method] and changed(client) then
          restart()
          return false
        end
        return send(self, method, ...)
      end
    end
  end,
  settings = {
    workingDirectory = { mode = "auto" },
    format = false,
    useFlatConfig = true,
    codeActionOnSave = { enable = false, mode = "all" },
    rulesCustomizations = { { rule = "prettier/prettier", severity = "off" } },
    run = "onType",
    problems = { shortenToSingleLine = false },
  },
}

return M
