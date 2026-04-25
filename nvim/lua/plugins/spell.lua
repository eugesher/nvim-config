-- ~/.config/nvim/lua/plugins/spell.lua
-- Code-aware spell checking for TypeScript / Node.js / NestJS, via `cspell`.
--
-- Choice of integration: `none-ls.nvim` + `davidmh/cspell.nvim`.
-- Reasons:
--   * cspell.nvim is purpose-built as a none-ls source and ships the
--     "Add word to user dictionary", "Add word to cspell.json", and
--     "Use suggestion" code actions out of the box — a standalone
--     `cspell-lsp` would require re-implementing that plumbing by hand.
--   * none-ls exposes `diagnostics_postprocess`, so we can force every
--     cspell diagnostic to severity HINT (requirement §3).
--   * cspell natively splits camelCase / PascalCase / snake_case /
--     SCREAMING_SNAKE_CASE, so identifiers are checked without extra parsing.
--
-- Prerequisite: `cspell` CLI on PATH. Install once:
--     npm install -g cspell
-- (Not shipped via Mason because cspell.nvim invokes the `cspell` binary
-- directly; keeping a single installation path avoids version skew.)

return {
  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "davidmh/cspell.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      local cspell = require("cspell")

      -- The user dictionary deliberately lives OUTSIDE ~/.config/nvim/:
      -- install.sh replaces that directory wholesale on every run, which
      -- would destroy a dictionary stored inside it. Keep it at
      -- ~/.config/cspell/user-words.txt so it survives reinstalls.
      local user_dict_dir = vim.fn.expand("~/.config/cspell")
      local user_dict_file = user_dict_dir .. "/user-words.txt"

      -- Belt-and-suspenders: install.sh also creates this file, but we
      -- re-create it on every nvim start so a hand-copied config works
      -- too (no-op when the file already exists — we never overwrite).
      vim.fn.mkdir(user_dict_dir, "p")
      if vim.fn.filereadable(user_dict_file) == 0 then
        local handle = io.open(user_dict_file, "w")
        if handle then
          handle:close()
        end
      end

      local cspell_config = {
        -- Prefer a project-level cspell.json (walk upward from cwd),
        -- fall back to the one shipped with this nvim config.
        find_json = function(cwd)
          local project = vim.fs.find("cspell.json", {
            upward = true,
            path = cwd,
            stop = vim.env.HOME,
          })[1]
          return project or vim.fn.expand("~/.config/nvim/cspell.json")
        end,
        read_config_synchronously = true,
      }

      null_ls.setup({
        sources = {
          cspell.diagnostics.with({
            config = cspell_config,
            -- Requirement §3: spell errors must not inflate real-issue
            -- counts in the status line or diagnostic list. Force HINT
            -- severity and stamp a stable `source` tag so the filter in
            -- config/spell-filter.lua can identify our diagnostics.
            diagnostics_postprocess = function(diagnostic)
              diagnostic.severity = vim.diagnostic.severity.HINT
              diagnostic.source = "cspell"
            end,
          }),
          cspell.code_actions.with({
            config = cspell_config,
          }),
        },
      })

      -- Requirement §6 (stretch): hide spell warnings on identifier
      -- USAGES, keep them on DEFINITIONS. See that module for the
      -- Treesitter details and fail-open behaviour.
      require("config.spell-filter").setup()
    end,
  },
}
