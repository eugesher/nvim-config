-- defaults verified against vim-dadbod-ui @afd0781 (2026-09-12)
--
-- Connections drawer, saved queries and result buffers on top of vim-dadbod.
-- The plugin is configured only through global variables, all set in `init`
-- (before it loads). The target is MySQL. Redis is used only through one-off
-- `:DB redis://host:port COMMAND`: the drawer builds no key tree for it, and
-- interactive work happens in redis-cli outside the editor (no keymaps or
-- terminals for it, on purpose).
--
-- Credentials never reach this repository: connections added with
-- :DBUIAddConnection are stored in stdpath("data")/db_ui/connections.json, and
-- MySQL passwords belong in ~/.my.cnf, not in the URL (README).

local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

-- `DB` too: a one-off `:DB <url> <query>` works before the drawer was opened.
M.cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer", "DB" }

M.keys = {
  { "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "Toggle drawer" },
  { "<leader>Df", "<cmd>DBUIFindBuffer<cr>", desc = "Find buffer in drawer" },
  { "<leader>Dr", "<cmd>DBUIRenameBuffer<cr>", desc = "Rename buffer" },
  { "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "Add connection" },
  { "<leader>Dq", "<cmd>DBUILastQueryInfo<cr>", desc = "Last query info" },
}

local function sql(...)
  return table.concat({ ... }, "\n")
end

-- Table helpers of MySQL connections (drawer: table → helper). `{dbname}` is
-- the table's database: the schema node, or the database of the URL. Not
-- `{schema}`: it is empty when the URL names a database (the usual case, the
-- drawer then lists tables without schemas), which is also why dbui's own
-- Foreign Keys / Primary Keys are replaced here. `{optional_schema}` is the
-- `db.` prefix (empty in that case), `{last_query}` the query run last.
local MYSQL_HELPERS = {
  List = "SELECT * FROM {optional_schema}`{table}` LIMIT 200",
  Columns = sql(
    "SELECT column_name, column_type, is_nullable, column_key, column_default, extra",
    "FROM information_schema.columns",
    "WHERE table_schema = '{dbname}' AND table_name = '{table}'",
    "ORDER BY ordinal_position"
  ),
  Indexes = sql(
    "SELECT index_name, seq_in_index, column_name, non_unique, index_type, cardinality",
    "FROM information_schema.statistics",
    "WHERE table_schema = '{dbname}' AND table_name = '{table}'",
    "ORDER BY index_name, seq_in_index"
  ),
  ["Primary Keys"] = sql(
    "SELECT column_name, ordinal_position",
    "FROM information_schema.key_column_usage",
    "WHERE table_schema = '{dbname}' AND table_name = '{table}'",
    "  AND constraint_name = 'PRIMARY'",
    "ORDER BY ordinal_position"
  ),
  ["Foreign Keys"] = sql(
    "SELECT kcu.constraint_name, kcu.column_name, kcu.referenced_table_name,",
    "  kcu.referenced_column_name, rc.update_rule, rc.delete_rule",
    "FROM information_schema.key_column_usage kcu",
    "JOIN information_schema.referential_constraints rc",
    "  ON rc.constraint_schema = kcu.constraint_schema",
    "  AND rc.constraint_name = kcu.constraint_name",
    "WHERE kcu.table_schema = '{dbname}' AND kcu.table_name = '{table}'",
    "ORDER BY kcu.constraint_name, kcu.ordinal_position"
  ),
  Explain = "EXPLAIN {last_query}", -- plan of the query run last (none yet: an error)
  Count = "SELECT COUNT(*) AS total FROM {optional_schema}`{table}`",
  ["Create Statement"] = "SHOW CREATE TABLE {optional_schema}`{table}`",
}

-- Drawer nodes that expand and collapse.
local TREE_NODES = { "db", "buffers", "saved_queries", "schemas", "schema", "tables", "table" }

-- Drawer icons. Tree nodes: chevron + glyph; entries: two spaces (the
-- chevron's width) + glyph.
local function drawer_icons()
  local glyphs = icons.database
  local function nodes(chevron)
    local result = {}
    for _, node in ipairs(TREE_NODES) do
      result[node] = chevron .. " " .. glyphs[node]
    end
    return result
  end
  return {
    expanded = nodes(icons.ui.chevron_down),
    collapsed = nodes(icons.ui.chevron_right),
    saved_query = "  " .. glyphs.saved_query,
    new_query = "  " .. glyphs.new_query,
    tables = "  " .. glyphs.helper, -- table helpers (List, Columns, …)
    buffers = "  " .. glyphs.buffer, -- open query buffers
    add_connection = "  " .. glyphs.add_connection,
    connection_ok = glyphs.connection_ok,
    connection_error = glyphs.connection_error,
  }
end

function M.init()
  local g = vim.g

  -- Storage: connections.json and saved queries. Not inside ~/.config/nvim,
  -- which install.sh replaces wholesale.
  g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
  g.db_ui_tmp_query_location = "" -- new queries live in tempname() files
  -- Never run a query on :w — the classic way to execute the wrong file
  -- against production. Query buffers run only with <localleader>x / X.
  g.db_ui_execute_on_save = 0
  g.db_ui_table_helpers = { mysql = MYSQL_HELPERS }
  -- Opening a table (or any other helper) runs it at once; all helpers only
  -- read. With execute_on_save off, dbui executes it directly, not via :w.
  g.db_ui_auto_execute_table_helpers = 1
  g.db_ui_bind_param_pattern = [[:\w\+]]

  -- Connections from the environment: $DBUI_URL (+ $DBUI_NAME), and one
  -- connection per DB_UI_<NAME> variable.
  g.db_ui_env_variable_url = "DBUI_URL"
  g.db_ui_env_variable_name = "DBUI_NAME"
  g.db_ui_dotenv_variable_prefix = "DB_UI_"

  -- Drawer.
  g.db_ui_win_position = user.database.position
  g.db_ui_winwidth = user.database.width
  g.db_ui_drawer_sections = { "new_query", "buffers", "saved_queries", "schemas" }
  g.db_ui_show_help = 1
  g.db_ui_use_nerd_fonts = 1
  g.db_ui_show_database_icon = 1
  g.db_ui_icons = drawer_icons()
  -- MySQL system schemas. Anchored: each item is a regex searched with
  -- match(), so a bare "sys" would also hide e.g. "analytics_sys".
  g.db_ui_hide_schemas = { "^information_schema$", "^performance_schema$", "^sys$" }
  g.db_ui_use_postgres_views = 1
  g.db_ui_dbout_list_sort = "asc"
  g.Db_ui_buffer_name_generator = 0 -- dbui's own buffer names
  g.Db_ui_table_name_sorter = 0 -- tables in the order the server returns them

  -- Notifications: dbui's own floats (bottom corner on the drawer's side,
  -- hidden after 7 s). Not vim.notify: with Neovim's built-in handler an error
  -- becomes :echoerr inside dbui's Vimscript — a "Error in function …" trace,
  -- or an exception inside the plugin's own try blocks. Switch to 1 once a
  -- notification UI replaces vim.notify.
  g.db_ui_use_nvim_notify = 0
  g.db_ui_force_echo_notifications = 0
  g.db_ui_disable_info_notifications = 0
  g.db_ui_notification_width = 40
  g.db_ui_disable_progress_bar = 0

  -- Mappings: the drawer and result buffers keep dbui's defaults; SQL buffers
  -- get ours instead of <Leader>S / <Leader>W / <Leader>E (after/ftplugin/sql.lua).
  g.db_ui_disable_mappings = 0
  g.db_ui_disable_mappings_dbui = 0
  g.db_ui_disable_mappings_dbout = 0
  g.db_ui_disable_mappings_sql = 1
  g.db_ui_disable_mappings_javascript = 0

  g.db_ui_debug = 0

  -- Not dbui: Neovim's ftplugin/sql.vim (also used for mysql) maps insert-mode
  -- <C-C>a, <C-C>k, … for sqlcomplete, so <C-c> waits in SQL buffers. Its
  -- completion is replaced by blink.cmp + vim-dadbod-completion anyway.
  g.omni_sql_no_default_maps = 1
end

-- Query buffers (keymaps in after/ftplugin/sql.lua) ---------------------------
--
-- Buffers opened from the drawer run through dbui's <Plug>(DBUI_ExecuteQuery):
-- result window, bind parameters, :DBUILastQueryInfo. Any other SQL buffer
-- falls back to vim-dadbod's :DB, which takes b:db / g:db / $DATABASE_URL.

local EXECUTE = "<Plug>(DBUI_ExecuteQuery)"

local function from_drawer(mode)
  return vim.fn.maparg(EXECUTE, mode) ~= ""
end

local function feed(keys, mode)
  vim.api.nvim_feedkeys(vim.keycode(keys), mode, false)
end

-- Statement under the cursor as 0-based start row / col and end row / col
-- (exclusive), without the closing `;`. Treesitter `statement` nodes — the sql
-- parser reads mysql / plsql buffers too — tell apart statements that share a
-- line or have no blank line between them. Where the parser finds none (no
-- parser, syntax it does not know), the paragraph around the cursor.
local function statement_range()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "sql")
  if ok and parser then
    local last
    for node in parser:parse()[1]:root():iter_children() do
      local sr, sc, er, ec = node:range()
      if node:type() == "statement" and sr <= row and row <= er then
        if er > row or ec >= col then
          return sr, sc, er, ec
        end
        last = { sr, sc, er, ec } -- ends before the cursor on its line
      end
    end
    if last then
      return unpack(last)
    end
  end
  if vim.fn.getline(row + 1):match("^%s*$") then
    return nil
  end
  local blank_above = vim.fn.search([[^\s*$]], "bnW") -- 0 when there is none
  local blank_below = vim.fn.search([[^\s*$]], "nW")
  local last_line = blank_below == 0 and vim.fn.line("$") or blank_below - 1
  return blank_above, 0, last_line - 1, #vim.fn.getline(last_line)
end

function M.execute_statement()
  local sr, sc, er, ec = statement_range()
  if not sr then
    return vim.notify("No SQL statement under the cursor", vim.log.levels.WARN)
  end
  if not from_drawer("x") then
    return vim.cmd(("%d,%dDB"):format(sr + 1, er + 1))
  end
  -- Select exactly the statement (`go` jumps to a byte offset, so tabs and
  -- multibyte text do not matter), then dbui's visual-mode execute.
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  feed(("v%dgo"):format(vim.fn.line2byte(er + 1) + ec - 1), "n")
  feed(EXECUTE, "m")
end

function M.execute_selection()
  if from_drawer("x") then
    feed(EXECUTE, "m")
  else
    feed(":DB<CR>", "n") -- `:` in Visual mode inserts the '<,'> range
  end
end

function M.execute_buffer()
  if from_drawer("n") then
    feed(EXECUTE, "m")
  else
    vim.cmd("%DB")
  end
end

-- dbui creates these only in query buffers opened from the drawer (saving:
-- only in new, not yet saved ones).
local function drawer_action(plug, unavailable)
  return function()
    if vim.fn.maparg(plug, "n") == "" then
      return vim.notify(unavailable, vim.log.levels.WARN)
    end
    feed(plug, "m")
  end
end

M.save_query =
  drawer_action("<Plug>(DBUI_SaveQuery)", "Only a new query opened from the drawer can be saved")
M.edit_bind_parameters = drawer_action(
  "<Plug>(DBUI_EditBindParameters)",
  "Bind parameters exist only in query buffers opened from the drawer"
)

return M
