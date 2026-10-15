local trust = require("core.trust")

local M = {}

local lspconfig_root_dir

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
        if not inside or not trust.allowed(root) then
          return
        end
        local own = trust.root(bufnr)
        if own and own ~= root and not trust.allowed(own) then
          return
        end
        on_dir(root)
      end)
    end)
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
