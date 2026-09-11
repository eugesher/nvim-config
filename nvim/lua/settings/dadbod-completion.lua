-- defaults verified against vim-dadbod-completion @a8dac0b (2026-09-12)
--
-- Tables, columns and keywords of the active connection in blink.cmp, through
-- the plugin's own blink source (vim_dadbod_completion.blink; blink.compat is
-- not needed). In buffers opened from the drawer the connection comes from
-- vim-dadbod-ui, elsewhere from b:db / g:db / $DATABASE_URL.

local M = {}

-- SQL filetypes: the drawer opens MySQL queries as `mysql`, Oracle ones as
-- `plsql`, the rest as `sql`. The single list for both paired places — this
-- lazy-loading trigger and blink's `sources.per_filetype` (settings/blink.lua
-- builds it from here), so they cannot drift apart.
M.ft = { "sql", "mysql", "plsql" }

function M.init()
  local g = vim.g
  g.vim_dadbod_completion_mark = "[DB]"
  g.vim_dadbod_completion_source_limits = vim.empty_dict() -- 200 per source
  g.vim_dadbod_completion_lowercase_keywords = 0
  g.vim_dadbod_completion_disable_notifications = 0
end

return M
