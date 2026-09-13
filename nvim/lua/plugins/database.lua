local spec = require("settings").spec

return {
  spec("kristijanhusak/vim-dadbod-ui", "database.dadbod", {
    dependencies = {
      "tpope/vim-dadbod",
      "kristijanhusak/vim-dadbod-completion",
    },
  }),
  spec("tpope/vim-dadbod"),
  spec("kristijanhusak/vim-dadbod-completion", "database.dadbod-completion", {
    dependencies = { "tpope/vim-dadbod" },
  }),
}
