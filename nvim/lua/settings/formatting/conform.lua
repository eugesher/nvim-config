-- defaults verified against conform.nvim v9.1.0-97-g016802d (2026-09-11)
--
-- Formatting on save and on demand. Prettier (through the prettierd daemon)
-- formats the web stack, stylua formats Lua. ESLint only lints: its
-- `prettier/prettier` rule is silenced at the server
-- (settings/lsp/servers/eslint.lua) and it never fixes on save — if a
-- "Delete `␊`" diagnostic shows up, look at `rulesCustomizations` there.
-- After editing .prettierrc run `prettierd restart` (it is a daemon).

local user = require("user.settings")

local M = {}

M.event = { "BufWritePre" }
M.cmd = { "ConformInfo" }

-- Prettier through its daemon; the plain CLI only when prettierd is missing.
local function prettier()
  return { "prettierd", "prettier", stop_after_first = true }
end

-- Commands and the global default exist before conform is loaded.
function M.init()
  vim.g.disable_autoformat = not user.formatting.format_on_save
  vim.api.nvim_create_user_command("FormatDisable", function(args)
    if args.bang then
      vim.b.disable_autoformat = true
    else
      vim.g.disable_autoformat = true
    end
  end, { desc = "Disable format on save (! = this buffer only)", bang = true })
  vim.api.nvim_create_user_command("FormatEnable", function(args)
    vim.b.disable_autoformat = false
    if not args.bang then
      vim.g.disable_autoformat = false
    end
  end, { desc = "Enable format on save (! = this buffer only)", bang = true })
end

M.opts = {
  formatters_by_ft = {
    typescript = prettier(),
    typescriptreact = prettier(),
    javascript = prettier(),
    javascriptreact = prettier(),
    json = prettier(),
    jsonc = prettier(),
    yaml = prettier(), -- also yaml.docker-compose: conform tries each part of a compound filetype
    html = prettier(),
    css = prettier(),
    scss = prettier(),
    markdown = prettier(),
    graphql = prettier(),
    lua = { "stylua" },
    -- sh: no formatter — shfmt is not installed (and defaults to tabs without
    -- an .editorconfig). Add { "shfmt" } plus the Mason package to opt in.
  },
  default_format_opts = {
    lsp_format = "fallback", -- no formatter configured → ask the language server
    timeout_ms = user.formatting.timeout_ms,
    quiet = false,
    stop_after_first = false, -- per filetype, see `prettier()` above
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
    -- Real files only: no help, terminal or plugin panel buffers.
    if vim.bo[bufnr].buftype ~= "" then
      return
    end
    if vim.api.nvim_buf_get_name(bufnr):find("/node_modules/", 1, true) then
      return
    end
    local size = vim.api.nvim_buf_get_offset(bufnr, vim.api.nvim_buf_line_count(bufnr))
    if size > user.formatting.max_filesize then
      return
    end
    return {} -- everything else from `default_format_opts`
  end,
  -- `format_after_save` stays unset: formatting is synchronous, before the write.
  -- The built-in definitions already do the right thing: prettierd runs in the
  -- project root and picks up its Prettier and .prettierrc; stylua searches for
  -- stylua.toml from the file upwards (nvim/stylua.toml for this config).
  formatters = {
    prettierd = { inherit = true },
    stylua = { inherit = true },
  },
  notify_on_error = true,
  notify_no_formatters = false, -- plain text files have none, that is fine
  log_level = vim.log.levels.WARN,
}

local function toggle_notice(scope, disabled)
  vim.notify(("Format on save (%s): %s"):format(scope, disabled and "off" or "on"))
end

M.keys = {
  {
    "<leader>cf",
    function()
      -- In visual mode conform formats just the selection.
      require("conform").format()
    end,
    mode = { "n", "x" },
    desc = "Format buffer / selection",
  },
  {
    "<leader>uf",
    function()
      vim.b.disable_autoformat = not vim.b.disable_autoformat
      toggle_notice("buffer", vim.b.disable_autoformat)
    end,
    desc = "Toggle format on save (buffer)",
  },
  {
    "<leader>uF",
    function()
      vim.g.disable_autoformat = not vim.g.disable_autoformat
      toggle_notice("global", vim.g.disable_autoformat)
    end,
    desc = "Toggle format on save (global)",
  },
}

return M
