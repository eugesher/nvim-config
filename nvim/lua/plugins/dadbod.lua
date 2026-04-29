-- ~/.config/nvim/lua/plugins/dadbod.lua
-- Database client: tpope/vim-dadbod (core) + vim-dadbod-ui (sidebar / query
-- buffers) + vim-dadbod-completion (SQL completion source for nvim-cmp).
--
-- Layout:
--   * vim-dadbod is loaded lazily as a dependency — it's a pure command
--     provider with no setup of its own.
--   * vim-dadbod-ui owns the user-facing entry point. It's loaded on the DBUI*
--     commands and on the keymaps below.
--   * vim-dadbod-completion is loaded on the SQL filetypes only. The cmp
--     source is registered via a buffer-local FileType autocmd so the source
--     never appears in non-SQL buffers (keeps the menu in TS / JS / Lua clean).
--
-- Defining a connection:
--   * Inside DBUI press `A` to add a saved connection. Format examples:
--       postgresql://user:pass@localhost:5432/mydb
--       mysql://user:pass@localhost:3306/mydb
--       sqlite:./dev.db
--   * Or set an environment variable read by vim-dadbod (recommended for
--     credentials you don't want on disk):
--       export DATABASE_URL="postgresql://user:pass@localhost:5432/mydb"
--     then add it via DBUI as `$DATABASE_URL`.
--   * Saved connections persist to `g:db_ui_save_location` (see below) so they
--     survive across Neovim restarts and live outside this repo.

local settings = require("config.user-settings")

return {
  {
    "kristijanhusak/vim-dadbod-ui",
    dependencies = {
      { "tpope/vim-dadbod", lazy = true },
      {
        "kristijanhusak/vim-dadbod-completion",
        ft = { "sql", "mysql", "plsql" },
        lazy = true,
      },
    },
    cmd = {
      "DBUI",
      "DBUIToggle",
      "DBUIAddConnection",
      "DBUIFindBuffer",
      "DBUIRenameBuffer",
      "DBUILastQueryInfo",
    },
    keys = {
      { "<leader>dbu", "<cmd>DBUIToggle<CR>",        desc = "Database: toggle UI" },
      { "<leader>dbf", "<cmd>DBUIFindBuffer<CR>",    desc = "Database: find query buffer" },
      { "<leader>dbr", "<cmd>DBUIRenameBuffer<CR>",  desc = "Database: rename query buffer" },
      { "<leader>dba", "<cmd>DBUIAddConnection<CR>", desc = "Database: add connection" },
      { "<leader>dbq", "<cmd>DBUILastQueryInfo<CR>", desc = "Database: last query info" },
    },
    init = function()
      -- Persist saved connections / scratch queries / bookmarks under
      -- stdpath("data") so they live with the user's nvim state, not in
      -- this repo (install.sh wipes ~/.config/nvim wholesale).
      vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"

      -- Nerd Font is a documented prerequisite (see README), so the icon set
      -- is safe to enable. Falls back to ASCII automatically if the font
      -- can't render the glyphs.
      vim.g.db_ui_use_nerd_icons = 1

      -- Don't auto-execute the whole buffer on save — running the wrong file
      -- against prod is exactly the kind of foot-gun we'd rather opt into.
      -- Use <Leader>S inside a query buffer (dadbod-ui default) to execute.
      vim.g.db_ui_execute_on_save = 0

      -- Show row count in the result panel header.
      vim.g.db_ui_show_database_icon = 1
      vim.g.db_ui_force_echo_notifications = 0
      vim.g.db_ui_win_position = settings.dadbod.win_position
      vim.g.db_ui_winwidth = settings.dadbod.winwidth
    end,
  },

  -- Register vim-dadbod-completion as a buffer-local cmp source on SQL
  -- filetypes only. Doing it here (rather than in completion.lua) keeps the
  -- dadbod feature self-contained and prevents the source from leaking into
  -- the menu in TypeScript / Lua / etc. dbout buffers don't take input, so
  -- they're omitted from the pattern.
  {
    "kristijanhusak/vim-dadbod-completion",
    ft = { "sql", "mysql", "plsql" },
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DadbodCmpSource", { clear = true }),
        pattern = { "sql", "mysql", "plsql" },
        desc = "Register vim-dadbod-completion as a buffer-local cmp source",
        callback = function()
          local ok, cmp = pcall(require, "cmp")
          if not ok then
            return
          end
          cmp.setup.buffer({
            sources = cmp.config.sources({
              { name = "vim-dadbod-completion" },
              { name = "luasnip" },
              { name = "buffer" },
            }),
          })
        end,
      })
    end,
  },
}
