-- Completion (blink.cmp) and snippets (LuaSnip + friendly-snippets).

local spec = require("settings").spec

return {
  -- Pinned to 1.x: v2 is under heavy development, breaks the config and needs
  -- the separate blink.lib package. The tag also selects the prebuilt fuzzy binary.
  spec("saghen/blink.cmp", "blink", {
    version = "1.*",
    dependencies = { "L3MON4D3/LuaSnip" },
  }),
  -- jsregexp is required by LSP snippets with transformations; without it they
  -- break silently. Needs gcc / make (build-essential).
  spec("L3MON4D3/LuaSnip", "luasnip", {
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
  }),
  spec("rafamadriz/friendly-snippets"),
}
