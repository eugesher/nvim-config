-- ~/.config/nvim/lua/plugins/completion.lua
-- Autocompletion engine (nvim-cmp) plus snippet support (LuaSnip).

return {
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter", -- Load only when entering Insert mode
    dependencies = {
      "hrsh7th/cmp-nvim-lsp", -- Source: LSP
      "hrsh7th/cmp-buffer", -- Source: words from open buffers
      "hrsh7th/cmp-path", -- Source: filesystem paths
      "L3MON4D3/LuaSnip", -- Snippet engine
      "saadparwaiz1/cmp_luasnip", -- LuaSnip <-> nvim-cmp integration
      "rafamadriz/friendly-snippets", -- Pre-built snippet library
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Load snippets from friendly-snippets (VS Code format)
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          -- Tell nvim-cmp how to expand a snippet body
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-Space>"] = cmp.mapping.complete(), -- Trigger the menu manually
          ["<C-e>"] = cmp.mapping.abort(), -- Close the menu
          ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept the selection
          ["<C-j>"] = cmp.mapping.select_next_item(), -- Next item
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- Previous item

          -- Tab: expand a snippet or jump to the next snippet field
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback() -- Regular Tab
            end
          end, { "i", "s" }),

          -- Shift+Tab: previous item, or previous snippet field
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        -- Completion sources, in priority order
        sources = cmp.config.sources({
          { name = "nvim_lsp" }, -- LSP — highest priority
          { name = "luasnip" }, -- Snippets
          { name = "buffer" }, -- Words from buffers
          { name = "path" }, -- File paths
        }),

        -- Menu appearance
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })
    end,
  },
}
