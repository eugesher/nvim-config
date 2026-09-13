local spec = require("settings").spec

return {
  spec("saghen/blink.cmp", "completion.blink", {
    version = "1.*",
    dependencies = { "L3MON4D3/LuaSnip" },
  }),
  spec("L3MON4D3/LuaSnip", "completion.luasnip", {
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
  }),
  spec("rafamadriz/friendly-snippets"),
}
