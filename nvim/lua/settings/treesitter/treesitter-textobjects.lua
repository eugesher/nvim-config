local M = {}

local function select(query)
  return function()
    require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
  end
end

local function move(fn, query)
  return function()
    require("nvim-treesitter-textobjects.move")[fn](query, "textobjects")
  end
end

local function swap(fn, query)
  return function()
    require("nvim-treesitter-textobjects.swap")[fn](query)
  end
end

M.opts = {
  select = {
    lookahead = true,
    selection_modes = {
      ["@function.outer"] = "V",
      ["@class.outer"] = "V",
    },
    include_surrounding_whitespace = false,
  },
  move = {
    set_jumps = true,
  },
}

local xo, nxo = { "x", "o" }, { "n", "x", "o" }

M.keys = {
  { "af", select("@function.outer"), mode = xo, desc = "Around function" },
  { "if", select("@function.inner"), mode = xo, desc = "Inside function" },
  { "ac", select("@class.outer"), mode = xo, desc = "Around class" },
  { "ic", select("@class.inner"), mode = xo, desc = "Inside class" },
  { "aa", select("@parameter.outer"), mode = xo, desc = "Around parameter" },
  { "ia", select("@parameter.inner"), mode = xo, desc = "Inside parameter" },
  { "ai", select("@conditional.outer"), mode = xo, desc = "Around conditional" },
  { "ii", select("@conditional.inner"), mode = xo, desc = "Inside conditional" },
  { "al", select("@loop.outer"), mode = xo, desc = "Around loop" },
  { "il", select("@loop.inner"), mode = xo, desc = "Inside loop" },
  { "a=", select("@assignment.outer"), mode = xo, desc = "Around assignment" },
  { "i=", select("@assignment.inner"), mode = xo, desc = "Inside assignment" },
  { "]f", move("goto_next_start", "@function.outer"), mode = nxo, desc = "Next function" },
  { "[f", move("goto_previous_start", "@function.outer"), mode = nxo, desc = "Previous function" },
  { "]a", move("goto_next_start", "@parameter.inner"), mode = nxo, desc = "Next parameter" },
  {
    "[a",
    move("goto_previous_start", "@parameter.inner"),
    mode = nxo,
    desc = "Previous parameter",
  },
  { "<leader>ra", swap("swap_next", "@parameter.inner"), desc = "Swap parameter with next" },
  {
    "<leader>rA",
    swap("swap_previous", "@parameter.inner"),
    desc = "Swap parameter with previous",
  },
}

return M
