local user = require("user.settings")

local M = {}

M.lazy = false

local parsers = {
  "typescript",
  "tsx",
  "javascript",
  "jsdoc",
  "json",
  "yaml",
  "toml",
  "html",
  "css",
  "scss",
  "lua",
  "luadoc",
  "vim",
  "vimdoc",
  "query",
  "bash",
  "regex",
  "diff",
  "printf",
  "xml",
  "markdown",
  "markdown_inline",
  "dockerfile",
  "hcl",
  "sql",
  "http",
  "graphql",
  "gitcommit",
  "gitignore",
  "git_rebase",
  "git_config",
}

M.opts = {
  install_dir = vim.fn.stdpath("data") .. "/site",
}

local function too_large(buf)
  local limits = user.treesitter
  if vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) > limits.max_filesize then
    return true
  end
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if #line > limits.max_line_length then
      return true
    end
  end
  return false
end

function M.update_folds(buf, detaching_client_id)
  if too_large(buf) then
    return
  end
  local clients = vim.lsp.get_clients({ bufnr = buf, method = "textDocument/foldingRange" })
  local lsp = vim.iter(clients):any(function(client)
    return client.id ~= detaching_client_id
  end)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.wo[win][0].foldexpr = lsp and "v:lua.vim.lsp.foldexpr()"
      or "v:lua.vim.treesitter.foldexpr()"
  end
end

function M.config(_, opts)
  local ts = require("nvim-treesitter")
  ts.setup(opts)
  ts.install(parsers)

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("settings_treesitter", { clear = true }),
    desc = "Start treesitter highlighting, folds and indentation",
    callback = function(event)
      local buf = event.buf
      local lang = vim.treesitter.language.get_lang(event.match)
      local ok, loaded = pcall(vim.treesitter.language.add, lang or "")
      if not (lang and ok and loaded) then
        return
      end
      local in_window = vim.api.nvim_get_current_buf() == buf
      if too_large(buf) then
        if in_window then
          vim.wo[0][0].foldmethod = "manual"
        end
        return
      end
      if not pcall(vim.treesitter.start, buf, lang) then
        return
      end
      M.update_folds(buf)
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return M
