local M = {}

local MAX_VALUE = 60

M.opts = {
  enabled = true,
  enable_commands = true,
  highlight_changed_variables = true,
  highlight_new_as_changed = true,
  show_stop_reason = true,
  commented = false,
  only_first_definition = true,
  all_references = false,
  clear_on_continue = false,

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

  virt_text_pos = "eol",

  all_frames = false,
  virt_lines = false,
  virt_text_win_col = nil,
}

return M
