local user = require("user.settings")
local icons = require("settings.icons")

local M = {}

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
  Explain = "EXPLAIN {last_query}",
  Count = "SELECT COUNT(*) AS total FROM {optional_schema}`{table}`",
  ["Create Statement"] = "SHOW CREATE TABLE {optional_schema}`{table}`",
}

local TREE_NODES = { "db", "buffers", "saved_queries", "schemas", "schema", "tables", "table" }

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
    tables = "  " .. glyphs.helper,
    buffers = "  " .. glyphs.buffer,
    add_connection = "  " .. glyphs.add_connection,
    connection_ok = glyphs.connection_ok,
    connection_error = glyphs.connection_error,
  }
end

function M.init()
  local g = vim.g

  g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
  g.db_ui_tmp_query_location = ""
  g.db_ui_execute_on_save = 0
  g.db_ui_table_helpers = { mysql = MYSQL_HELPERS }
  g.db_ui_auto_execute_table_helpers = 1
  g.db_ui_bind_param_pattern = [[:\w\+]]

  g.db_ui_env_variable_url = "DBUI_URL"
  g.db_ui_env_variable_name = "DBUI_NAME"
  g.db_ui_dotenv_variable_prefix = "DB_UI_"

  g.db_ui_win_position = user.database.position
  g.db_ui_winwidth = user.database.width
  g.db_ui_drawer_sections = { "new_query", "buffers", "saved_queries", "schemas" }
  g.db_ui_show_help = 1
  g.db_ui_use_nerd_fonts = 1
  g.db_ui_show_database_icon = 1
  g.db_ui_icons = drawer_icons()
  g.db_ui_hide_schemas = { "^information_schema$", "^performance_schema$", "^sys$" }
  g.db_ui_use_postgres_views = 1
  g.db_ui_dbout_list_sort = "asc"
  g.Db_ui_buffer_name_generator = 0
  g.Db_ui_table_name_sorter = 0

  g.db_ui_use_nvim_notify = 0
  g.db_ui_force_echo_notifications = 0
  g.db_ui_disable_info_notifications = 0
  g.db_ui_notification_width = 40
  g.db_ui_disable_progress_bar = 0

  g.db_ui_disable_mappings = 0
  g.db_ui_disable_mappings_dbui = 0
  g.db_ui_disable_mappings_dbout = 0
  g.db_ui_disable_mappings_sql = 1
  g.db_ui_disable_mappings_javascript = 0

  g.db_ui_debug = 0

  g.omni_sql_no_default_maps = 1
end

local EXECUTE = "<Plug>(DBUI_ExecuteQuery)"

local function from_drawer(mode)
  return vim.fn.maparg(EXECUTE, mode) ~= ""
end

local function feed(keys, mode)
  vim.api.nvim_feedkeys(vim.keycode(keys), mode, false)
end

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
        last = { sr, sc, er, ec }
      end
    end
    if last then
      return unpack(last)
    end
  end
  if vim.fn.getline(row + 1):match("^%s*$") then
    return nil
  end
  local blank_above = vim.fn.search([[^\s*$]], "bnW")
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
  vim.api.nvim_win_set_cursor(0, { sr + 1, sc })
  feed(("v%dgo"):format(vim.fn.line2byte(er + 1) + ec - 1), "n")
  feed(EXECUTE, "m")
end

function M.execute_selection()
  if from_drawer("x") then
    feed(EXECUTE, "m")
  else
    feed(":DB<CR>", "n")
  end
end

function M.execute_buffer()
  if from_drawer("n") then
    feed(EXECUTE, "m")
  else
    vim.cmd("%DB")
  end
end

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
