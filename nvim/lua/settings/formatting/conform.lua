local user = require("user.settings")

local M = {}

M.event = { "BufWritePre" }
M.cmd = { "ConformInfo" }

local function prettier()
  return { "prettierd", "prettier", stop_after_first = true }
end

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
    yaml = prettier(),
    html = prettier(),
    css = prettier(),
    scss = prettier(),
    markdown = prettier(),
    graphql = prettier(),
    lua = { "stylua" },
    sql = { "sql_formatter" },
  },
  default_format_opts = {
    lsp_format = "fallback",
    timeout_ms = user.formatting.timeout_ms,
    quiet = false,
    stop_after_first = false,
  },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
      return
    end
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
    return {}
  end,
  formatters = {
    prettierd = { inherit = true },
    stylua = { inherit = true },
    sql_formatter = {
      inherit = true,
      prepend_args = { "--language", user.formatting.sql_dialect },
    },
  },
  notify_on_error = true,
  notify_no_formatters = false,
  log_level = vim.log.levels.WARN,
}

local function toggle_notice(scope, disabled)
  vim.notify(("Format on save (%s): %s"):format(scope, disabled and "off" or "on"))
end

M.keys = {
  {
    "<leader>cf",
    function()
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
