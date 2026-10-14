local M = {}

M.ft = { "sql", "mysql", "plsql" }

function M.init()
  local g = vim.g
  g.vim_dadbod_completion_mark = "[DB]"
  g.vim_dadbod_completion_source_limits = vim.empty_dict()
  g.vim_dadbod_completion_lowercase_keywords = 0
  g.vim_dadbod_completion_disable_notifications = 0
end

return M
