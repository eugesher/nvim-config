local M = {}

M.lazy = false

function M.opts()
  local builtin = require("statuscol.builtin")

  local function signs(patterns)
    return vim.tbl_extend("error", patterns, {
      maxwidth = 1,
      colwidth = 1,
      auto = false,
      wrap = false,
      fillchar = " ",
      fillcharhl = nil,
      foldclosed = false,
      align = "left",
    })
  end

  return {
    setopt = true,
    thousands = false,
    relculright = false,
    ft_ignore = {
      "neo-tree",
      "trouble",
      "dbui",
      "dap-view",
      "dap-view-term",
      "dap-repl",
      "aerial",
      "oil",
    },
    bt_ignore = { "nofile", "terminal", "help", "prompt", "quickfix" },
    segments = {
      { text = { "%C" }, click = "v:lua.ScFa" },
      { sign = signs({ name = { ".*" }, namespace = { ".*" } }), click = "v:lua.ScSa" },
      {
        text = { builtin.lnumfunc, " " },
        condition = { true, builtin.not_empty },
        click = "v:lua.ScLa",
      },
      {
        sign = signs({ namespace = { "^gitsigns_signs_" }, name = { "^coverage_" } }),
        click = "v:lua.ScSa",
      },
    },
    clickmod = "c",
    clickhandlers = {
      Lnum = false,
      FoldClose = builtin.foldclose_click,
      FoldOpen = builtin.foldopen_click,
      FoldOther = builtin.foldother_click,
      DapBreakpointRejected = builtin.toggle_breakpoint,
      DapBreakpoint = builtin.toggle_breakpoint,
      DapBreakpointCondition = builtin.toggle_breakpoint,
      ["diagnostic.signs"] = builtin.diagnostic_click,
      gitsigns = false,
    },
  }
end

function M.config(_, opts)
  require("statuscol").setup(opts)

  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("settings_statuscol", { clear = true }),
    desc = "Plain status column in terminal windows",
    callback = function()
      vim.opt_local.statuscolumn = ""
    end,
  })
end

return M
