local M = {}

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

  { "<leader>ri", refactor("inline_var", "iw"), expr = true, desc = "Inline variable" },
  { "<leader>rI", refactor("inline_func", "iw"), expr = true, desc = "Inline function" },

  {
    "<leader>rr",
    function()
      require("refactoring").select_refactor()
    end,
    mode = nx,
    desc = "Select refactor",
  },

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
  show_success_message = true,
  refactor = {
    extract_func = {},
    extract_var = {},
    inline_func = {},
    inline_var = {},
  },
  debug = {
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
      restore_view = true,
    },
  },
}

return M
