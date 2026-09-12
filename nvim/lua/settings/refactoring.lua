-- defaults verified against refactoring.nvim @64e10d7 (2026-09-12)
--
-- Extract / inline and debug prints, driven by tree-sitter. The 2026 rewrite
-- turned every refactor into an |operator|: the functions below return an
-- expression that is combined with a motion or a text object (and repeats with
-- `.`). Hence `expr = true` on every key — the old
-- `require("refactoring").refactor("Extract Function")` API is gone, and with it
-- the `prompt_func_*` / `*_statements` options that used to configure it.
--
-- In visual mode the selection is the range; in normal mode the key carries its
-- own text object (`iB` for the surrounding block, `iw` for the word).

local M = {}

-- The operators. `require` inside the callback: the key itself loads the plugin.
local function refactor(name, motion)
  return function()
    local operator = require("refactoring")[name]()
    return motion and (operator .. motion) or operator
  end
end

local function debug_print(name, opts, motion)
  return function()
    local operator = require("refactoring.debug")[name](opts)
    return motion and (operator .. motion) or operator
  end
end

local nx = { "n", "x" }

M.keys = {
  -- Extract. In normal mode `iB` is the innards of the surrounding { } block,
  -- which is what "extract this block" means in a TypeScript body.
  { "<leader>re", refactor("extract_func"), mode = "x", expr = true, desc = "Extract function" },
  {
    "<leader>rE",
    refactor("extract_func_to_file"),
    mode = "x",
    expr = true,
    desc = "Extract function to file",
  },
  { "<leader>rv", refactor("extract_var"), mode = "x", expr = true, desc = "Extract variable" },
  {
    "<leader>rb",
    refactor("extract_func", "iB"),
    expr = true,
    desc = "Extract block as function",
  },
  {
    "<leader>rB",
    refactor("extract_func_to_file", "iB"),
    expr = true,
    desc = "Extract block to file",
  },

  -- Inline. Both act on the symbol under the cursor, so they carry `iw`.
  { "<leader>ri", refactor("inline_var", "iw"), expr = true, desc = "Inline variable" },
  { "<leader>rI", refactor("inline_func", "iw"), expr = true, desc = "Inline function" },

  -- The menu of everything the plugin can do here; `vim.ui.select` is fzf-lua
  -- (settings/fzf.lua), so it opens as a picker. Not an `expr` mapping, unlike
  -- the rest: this one is not an operator — it opens the picker itself and then
  -- feeds the keys of whatever was chosen. As an `expr` mapping the picker would
  -- try to open a window while Neovim is evaluating the mapping, which fails
  -- with E565.
  {
    "<leader>rr",
    function()
      require("refactoring").select_refactor()
    end,
    mode = nx,
    desc = "Select refactor",
  },

  -- Debug prints. `rp` prints the variable under the cursor, `rP` prints where
  -- execution is (`function#if#for`), `rc` removes every such line in the file.
  {
    "<leader>rp",
    debug_print("print_var", { output_location = "below" }, "iw"),
    expr = true,
    desc = "Debug print variable",
  },
  {
    "<leader>rp",
    debug_print("print_var", { output_location = "below" }),
    mode = "x",
    expr = true,
    desc = "Debug print selection",
  },
  {
    "<leader>rP",
    debug_print("print_loc", { output_location = "below" }),
    expr = true,
    desc = "Debug print location",
  },
  -- `gg` … `G` turns the operator into "the whole buffer"; `restore_view` puts
  -- the cursor back where it was.
  {
    "<leader>rc",
    function()
      return "gg" .. require("refactoring.debug").cleanup({ restore_view = true }) .. "G"
    end,
    expr = true,
    remap = true,
    desc = "Clear debug prints",
  },
}

M.opts = {
  -- "Extracted function" and friends, in the message area.
  show_success_message = true,
  refactor = {
    -- `code_generation` holds one function per language that emits the actual
    -- code (`const x = …;` for TypeScript). The defaults already cover
    -- TypeScript, JavaScript, tsx and Lua; they are left alone rather than
    -- copied — each is a table of functions, not a format string.
    extract_func = {},
    extract_var = {},
    inline_func = {},
    inline_var = {},
  },
  debug = {
    -- The markers are comments the plugin puts around generated lines; they are
    -- what `<leader>rc` looks for, so they must stay in sync with the ones in
    -- already-printed code.
    markers = {
      print_var = { start = "__PRINT_VAR_START", ["end"] = "__PRINT_VAR_END" },
      print_exp = { start = "__PRINT_EXP_START", ["end"] = "__PRINT_EXP_END" },
      print_loc = { start = "__PRINT_LOC_START", ["end"] = "__PRINT_LOC_END" },
    },
    print_var = { output_location = "below" },
    print_loc = { output_location = "below" },
    print_exp = { output_location = "below" },
    cleanup = {
      types = { "print_var", "print_loc", "print_exp" },
      restore_view = true, -- the cursor stays where it was after a buffer-wide clean
    },
  },
}

return M
