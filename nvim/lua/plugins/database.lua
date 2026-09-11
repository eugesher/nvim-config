-- Database client: vim-dadbod (the :DB command and adapters for mysql, redis,
-- postgres, …), vim-dadbod-ui (connections drawer, saved queries, result
-- buffers) and vim-dadbod-completion (tables and columns of the active
-- connection). nvim-dbee is not used (decision recorded in task 14).

local spec = require("settings").spec

return {
  spec("kristijanhusak/vim-dadbod-ui", "dadbod", {
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
  }),
  spec("tpope/vim-dadbod"),
  -- Also loads by itself in SQL buffers not opened from the drawer; it calls
  -- vim-dadbod's functions, hence the dependency.
  spec("kristijanhusak/vim-dadbod-completion", "dadbod-completion", {
    dependencies = { "tpope/vim-dadbod" },
  }),
}
