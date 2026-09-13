-- defaults verified against nvim-dap-virtual-text @fbdb48c (2026-09-12)
--
-- Values of variables next to the code while a debug session is stopped, like
-- WebStorm's inline values. Loaded together with nvim-dap (plugins/dap.lua):
-- it registers its own dap listeners at setup.
--
-- Variables are found through the treesitter `locals.scm` queries, which
-- nvim-treesitter ships for typescript and javascript. Without the
-- parser and those queries there is simply no virtual text.
--
-- nvim-dap-view has a virtual-text implementation of its own; it stays off
-- (settings/dap/dap-view.lua), otherwise every value would be shown twice.

local M = {}

-- Values longer than this are cut: a long JSON object turns the line of code
-- into mush otherwise.
local MAX_VALUE = 60

M.opts = {
  enabled = true,
  -- :DapVirtualTextEnable / Disable / Toggle / ForceRefresh. <leader>dv uses
  -- Toggle. The README calls this `enabled_commands`, the code reads
  -- `enable_commands` — the latter is what actually works.
  enable_commands = true,
  highlight_changed_variables = true, -- changed values get NvimDapVirtualTextChanged
  -- With js-debug this is what actually colors the values. The plugin looks
  -- up previous values by `stackframe.id`, and js-debug hands out a new id on
  -- every stop, so the cache is never hit and nothing is ever "changed". With
  -- this on, every inline value gets the NvimDapVirtualTextChanged highlight —
  -- read it as "here is a value", not as "this value changed".
  highlight_new_as_changed = true,
  show_stop_reason = true, -- the exception that stopped the debugger
  commented = false, -- no comment prefix: the values are not code
  only_first_definition = true,
  all_references = false,
  clear_on_continue = false, -- keep the values while stepping, no flicker

  ---@param variable table  dap.Variable
  ---@param options table   the options above
  display_callback = function(variable, _buf, _stackframe, _node, options)
    local value = tostring(variable.value):gsub("%s+", " ")
    if #value > MAX_VALUE then
      value = value:sub(1, MAX_VALUE - 1) .. "…"
    end
    if options.virt_text_pos == "inline" then
      return " = " .. value
    end
    return variable.name .. " = " .. value
  end,

  -- End of line, not inline: inline values shift the code sideways while
  -- stepping, and this config keeps the sign segments (settings/ui/statuscol.lua)
  -- and diagnostics from doing that too.
  virt_text_pos = "eol",

  -- Experimental upstream, off on purpose: `all_frames` walks the whole stack
  -- on every step (slow on deep NestJS stacks), `virt_lines` flickers.
  all_frames = false,
  virt_lines = false,
  virt_text_win_col = nil, -- nil: right after the code, not a fixed column
}

return M
