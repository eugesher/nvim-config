local icons = require("settings.icons")

local M = {}

local ns = vim.api.nvim_create_namespace("myconfig.annotations")

local severity = vim.diagnostic.severity

local bullet = icons.ui.dot .. " "

local unnecessary = vim.lsp.protocol.DiagnosticTag.Unnecessary

local highlights = {
  [severity.ERROR] = "DiagnosticVirtualTextError",
  [severity.WARN] = "DiagnosticVirtualTextWarn",
  [severity.INFO] = "DiagnosticVirtualTextInfo",
  [severity.HINT] = "DiagnosticVirtualTextHint",
}

M.ranks = {
  [severity.ERROR] = 1,
  [severity.WARN] = 2,
  [severity.INFO] = 3,
  [severity.HINT] = 4,
  unused = 5,
}

local state = {}
local scheduled = {}
local top_lines = {}

local function indent(bufnr, lnum)
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum, lnum + 1, false)[1] or ""
  return line:match("^%s*")
end

local function fill_top(bufnr, count)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      vim.api.nvim_win_call(win, function()
        local view = vim.fn.winsaveview()
        if view.topline == 1 and view.topfill < count then
          vim.fn.winrestview({ topfill = count })
        end
      end)
    end
  end
end

local function reports_unused(item, lnum)
  if not item.unnecessary then
    return false
  end
  return function(col)
    return col >= item.col and (item.end_lnum ~= lnum or col < item.end_col)
  end
end

local function without_reported_unused(items, lnum)
  local reported = {}
  for _, item in ipairs(items) do
    local covers = reports_unused(item, lnum)
    if covers then
      reported[#reported + 1] = covers
    end
  end
  if #reported == 0 then
    return items
  end
  return vim.tbl_filter(function(item)
    if item.rank ~= M.ranks.unused then
      return true
    end
    for _, covers in ipairs(reported) do
      if covers(item.col or 0) then
        return false
      end
    end
    return true
  end, items)
end

local function render(bufnr)
  if not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  top_lines[bufnr] = nil
  local last = vim.api.nvim_buf_line_count(bufnr) - 1
  local lines = {}
  for _, items in pairs(state[bufnr] or {}) do
    for _, item in ipairs(items) do
      local lnum = math.max(0, math.min(item.lnum, last))
      lines[lnum] = lines[lnum] or {}
      table.insert(lines[lnum], item)
    end
  end
  for lnum, items in pairs(lines) do
    items = without_reported_unused(items, lnum)
    table.sort(items, function(a, b)
      if a.rank ~= b.rank then
        return a.rank < b.rank
      end
      return (a.col or 0) < (b.col or 0)
    end)
    local prefix = indent(bufnr, lnum)
    local virt_lines = {}
    for _, item in ipairs(items) do
      virt_lines[#virt_lines + 1] = {
        { prefix, "NonText" },
        { bullet .. item.text, item.hl },
      }
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns, lnum, 0, {
      virt_lines = virt_lines,
      virt_lines_above = true,
      virt_lines_overflow = "scroll",
    })
    if lnum == 0 then
      top_lines[bufnr] = #virt_lines
      fill_top(bufnr, #virt_lines)
    end
  end
end

local function schedule(bufnr)
  if scheduled[bufnr] then
    return
  end
  scheduled[bufnr] = true
  vim.schedule(function()
    scheduled[bufnr] = nil
    render(bufnr)
  end)
end

function M.set(bufnr, source, items)
  state[bufnr] = state[bufnr] or {}
  state[bufnr][source] = items
  schedule(bufnr)
end

function M.clear(bufnr, source)
  if state[bufnr] then
    state[bufnr][source] = nil
    schedule(bufnr)
  end
end

local function diagnostic_items(diagnostics)
  local items = {}
  for _, diagnostic in ipairs(diagnostics) do
    local tags = vim.tbl_get(diagnostic, "user_data", "lsp", "tags") or {}
    items[#items + 1] = {
      lnum = diagnostic.lnum,
      col = diagnostic.col,
      end_lnum = diagnostic.end_lnum,
      end_col = diagnostic.end_col,
      unnecessary = vim.tbl_contains(tags, unnecessary),
      rank = M.ranks[diagnostic.severity],
      hl = highlights[diagnostic.severity],
      text = (diagnostic.message:gsub("%s*\n%s*", " ")),
    }
  end
  return items
end

function M.setup()
  vim.diagnostic.handlers["myconfig/above"] = {
    show = function(namespace, bufnr, diagnostics, _)
      M.set(bufnr, "diagnostic:" .. namespace, diagnostic_items(diagnostics))
    end,
    hide = function(namespace, bufnr)
      M.clear(bufnr, "diagnostic:" .. namespace)
    end,
  }
  local group = vim.api.nvim_create_augroup("myconfig_annotations", { clear = true })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    desc = "Drop the annotations of a deleted buffer",
    callback = function(event)
      state[event.buf] = nil
      top_lines[event.buf] = nil
    end,
  })
  vim.api.nvim_create_autocmd({ "WinScrolled", "WinEnter" }, {
    group = group,
    desc = "Keep the annotations of the first line visible",
    callback = function(event)
      if top_lines[event.buf] then
        fill_top(event.buf, top_lines[event.buf])
      end
    end,
  })
end

return M
