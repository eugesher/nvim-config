-- defaults verified against nvim-treesitter main@d4d59cb3 (2026-09-11)
--
-- nvim-treesitter `main`: installs parsers and ships queries — nothing more.
-- Highlighting, folds and indentation are switched on per buffer by the
-- FileType autocmd below; the old `configs.setup{ highlight, indent,
-- incremental_selection }` API does not exist on this branch. Incremental
-- selection is built into Neovim 0.12 (`an` / `in`, `]n` / `[n`) and is left alone.

local user = require("user.settings")

local M = {}

-- The plugin does not support lazy-loading (README).
M.lazy = false

-- Installed on startup; `install()` skips what is already there. Notes:
--   * no `jsonc`: that parser is gone on `main`, and nvim-treesitter maps the
--     `jsonc` filetype to the `json` parser;
--   * `http` is required by kulala.nvim (task 15);
--   * typescript / tsx / javascript are needed by neotest and
--     nvim-dap-virtual-text (tasks 17–18).
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
  "sql",
  "http",
  "graphql",
  "gitcommit",
  "gitignore",
  "git_rebase",
  "git_config",
}

M.opts = {
  install_dir = vim.fn.stdpath("data") .. "/site", -- prepended to 'runtimepath'
}

-- Whether a buffer is too large for treesitter (see user/settings.lua).
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

function M.config(_, opts)
  local ts = require("nvim-treesitter")
  ts.setup(opts)
  ts.install(parsers) -- asynchronous; compiles only the missing ones

  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("settings_treesitter", { clear = true }),
    desc = "Start treesitter highlighting, folds and indentation",
    callback = function(event)
      local buf = event.buf
      -- No parser for this filetype: stay silent (e.g. `.env`).
      local lang = vim.treesitter.language.get_lang(event.match)
      local ok, loaded = pcall(vim.treesitter.language.add, lang or "")
      if not (lang and ok and loaded) then
        return
      end
      local in_window = vim.api.nvim_get_current_buf() == buf
      if too_large(buf) then
        -- The global treesitter 'foldexpr' (core/options.lua) would parse the
        -- buffer anyway; fall back to manual folds here.
        if in_window then
          vim.wo[0][0].foldmethod = "manual"
        end
        return
      end
      if not pcall(vim.treesitter.start, buf, lang) then
        return
      end
      if in_window then
        vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
      end
      vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

return M
