-- ~/.config/nvim/lua/plugins/lazygit.lua
-- Lazygit integration via snacks.nvim.
-- Automatically derives the lazygit colorscheme from the active Neovim theme.
-- Requires lazygit to be installed: https://github.com/jesseduffield/lazygit

return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    lazygit = {
      enabled = true,
      -- Mirror Neovim's `CursorLine` (already `bg = crust` in `ui.lua`) so
      -- the lazygit cursor row tracks the editor's cursor row.
      theme = {
        selectedLineBgColor = { bg = "TelescopeSelection" },
      },
    },
  },
  keys = {
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Open LazyGit",
    },
  },
}
