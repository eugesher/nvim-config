-- Telescope: extensible fuzzy finder for files, text, buffers, symbols, etc.
-- Requires `ripgrep` on the system for live_grep to work.

return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required utility library
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make", -- Native fzf sorter (compiled for speed)
    },
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        -- Paths to ignore when searching
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/", "coverage/" },
      },
    })

    -- Load the native fzf extension
    telescope.load_extension("fzf")

    -- nvim-treesitter removed the old configs/parsers API; replace ts_highlighter
    -- with one that uses Neovim's built-in treesitter directly
    local putils = require("telescope.previewers.utils")
    putils.ts_highlighter = function(bufnr, ft)
      if type(ft) ~= "string" or ft == "" then
        return false
      end
      local lang = vim.treesitter.language.get_lang(ft)
      if not lang then
        return false
      end
      return pcall(vim.treesitter.start, bufnr, lang)
    end

    -- Keymaps
    local keymap = vim.keymap.set
    keymap("n", "<leader>ff", builtin.find_files, { desc = "Find file" })
    keymap("n", "<leader>fg", builtin.live_grep, { desc = "Grep across project" })
    keymap("n", "<leader>fb", builtin.buffers, { desc = "Open buffers" })
    keymap("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
    keymap("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics (errors/warnings)" })
    keymap("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
  end,
}
