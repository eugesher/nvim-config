local annotations = require("core.annotations")
local user = require("user.settings")

local kinds = vim.lsp.protocol.SymbolKind

local M = {}

local SOURCE = "unused"
local HIGHLIGHT = "UnusedSymbol"

local script_filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local script_kinds = {
  [kinds.Class] = true,
  [kinds.Enum] = true,
  [kinds.Function] = true,
  [kinds.Interface] = true,
  [kinds.Method] = true,
  [kinds.Property] = true,
  [kinds.Variable] = true,
}

local default_kinds = {
  [kinds.Function] = true,
  [kinds.Method] = true,
}

local globs = {}

local function ignored_file(bufnr, patterns)
  local name = vim.fs.basename(vim.api.nvim_buf_get_name(bufnr))
  for _, pattern in ipairs(patterns) do
    if not globs[pattern] then
      globs[pattern] = vim.glob.to_lpeg(pattern)
    end
    if globs[pattern]:match(name) then
      return true
    end
  end
  return false
end

local function tracked(bufnr, symbol, parent_kind, script)
  local allowed = script and script_kinds or default_kinds
  if not allowed[symbol.kind] then
    return false
  end
  if symbol.name:find("() callback", 1, true) then
    return false
  end
  if symbol.kind == kinds.Variable or symbol.kind == kinds.Constant then
    return parent_kind ~= kinds.Function
      and parent_kind ~= kinds.Method
      and parent_kind ~= kinds.Constructor
  end
  if symbol.kind == kinds.Property then
    return (parent_kind == kinds.Class or parent_kind == kinds.Interface)
      and not ignored_file(bufnr, user.lsp.unused_skip.fields)
  end
  if symbol.kind == kinds.Method then
    return not ignored_file(bufnr, user.lsp.unused_skip.methods)
  end
  return true
end

local function collect(bufnr, result, script)
  local symbols = {}
  local function walk(items, parent_kind)
    for _, item in ipairs(items or {}) do
      local range = item.selectionRange or (item.location and item.location.range)
      if range and tracked(bufnr, item, parent_kind, script) then
        symbols[#symbols + 1] = {
          id = ("%d:%s:%d"):format(item.kind, item.name, range.start.line),
          name = (item.name:gsub("^%(%a+%) ", "")),
          lnum = range.start.line,
          position = range.start,
        }
      end
      walk(item.children, item.kind)
    end
  end
  walk(result, nil)
  return symbols
end

local state = {}

local function viewport(bufnr)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(win) == bufnr then
      local info = vim.fn.getwininfo(win)[1]
      return info.topline - 1, info.botline - 1
    end
  end
end

local function client_for(bufnr)
  for _, client in
    ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/documentSymbol" }))
  do
    if client:supports_method("textDocument/references", bufnr) then
      return client
    end
  end
end

local function byte_col(bufnr, position, encoding)
  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1] or ""
  local ok, col = pcall(vim.str_byteindex, line, encoding, position.character, false)
  return ok and col or position.character
end

local function label(symbol)
  if symbol.name == "" then
    return "Unused symbol."
  end
  return ("Unused symbol '%s'."):format(symbol.name)
end

local function publish(bufnr, buffer, symbols, encoding)
  local items = {}
  for _, symbol in ipairs(symbols) do
    if buffer.counts[symbol.id] == 0 then
      items[#items + 1] = {
        lnum = symbol.lnum,
        col = byte_col(bufnr, symbol.position, encoding),
        rank = annotations.ranks.unused,
        hl = HIGHLIGHT,
        text = label(symbol),
      }
    end
  end
  annotations.set(bufnr, SOURCE, items)
end

local function count(bufnr, client, symbols, alive)
  local buffer = alive()
  if not buffer then
    return
  end
  local waiting = 0
  for _, symbol in ipairs(symbols) do
    if buffer.counts[symbol.id] == nil then
      waiting = waiting + 1
      client:request("textDocument/references", {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = symbol.position,
        context = { includeDeclaration = false },
      }, function(err, references)
        if not alive() then
          return
        end
        buffer.counts[symbol.id] = err and 1 or #(references or {})
        waiting = waiting - 1
        if waiting == 0 then
          publish(bufnr, buffer, symbols, client.offset_encoding)
        end
      end, bufnr)
    end
  end
  if waiting == 0 then
    publish(bufnr, buffer, symbols, client.offset_encoding)
  end
end

local function visible(symbols, top, bot)
  return vim.tbl_filter(function(symbol)
    return symbol.lnum >= top and symbol.lnum <= bot
  end, symbols)
end

local function refresh(bufnr)
  local entry = state[bufnr]
  if not entry or entry.disabled or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local client = client_for(bufnr)
  local top, bot = viewport(bufnr)
  if not client or not top then
    return
  end
  local changedtick = vim.b[bufnr].changedtick
  if entry.changedtick ~= changedtick then
    entry.changedtick, entry.counts, entry.symbols = changedtick, {}, nil
  end
  entry.generation = entry.generation + 1
  local generation = entry.generation

  local function alive()
    local buffer = state[bufnr]
    if
      buffer
      and buffer.generation == generation
      and buffer.changedtick == vim.b[bufnr].changedtick
    then
      return buffer
    end
  end

  if entry.symbols then
    count(bufnr, client, visible(entry.symbols, top, bot), alive)
    return
  end

  local script = script_filetypes[vim.bo[bufnr].filetype] == true
  client:request("textDocument/documentSymbol", {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
  }, function(err, result)
    local buffer = alive()
    if err or not result or not buffer then
      return
    end
    buffer.symbols = collect(bufnr, result, script)
    count(bufnr, client, visible(buffer.symbols, top, bot), alive)
  end, bufnr)
end

local function schedule(bufnr, delay)
  local entry = state[bufnr]
  if not entry then
    return
  end
  if entry.timer then
    entry.timer:stop()
  end
  entry.timer = vim.defer_fn(function()
    entry.timer = nil
    refresh(bufnr)
  end, delay)
end

local function augroup(bufnr)
  return "myconfig_unused_" .. bufnr
end

local function attach(bufnr)
  if state[bufnr] then
    schedule(bufnr, 100)
    return
  end
  state[bufnr] = { generation = 0, counts = {} }
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave", "WinScrolled", "BufEnter" }, {
    group = vim.api.nvim_create_augroup(augroup(bufnr), { clear = true }),
    buffer = bufnr,
    desc = "Count references for the unused markers",
    callback = function()
      schedule(bufnr, 300)
    end,
  })
  schedule(bufnr, 100)
end

local function detach(bufnr)
  if not state[bufnr] then
    return
  end
  if state[bufnr].timer then
    state[bufnr].timer:stop()
  end
  state[bufnr] = nil
  pcall(vim.api.nvim_del_augroup_by_name, augroup(bufnr))
  annotations.clear(bufnr, SOURCE)
end

function M.toggle()
  local bufnr = vim.api.nvim_get_current_buf()
  local entry = state[bufnr]
  if not entry then
    attach(bufnr)
    return
  end
  entry.disabled = not entry.disabled
  if entry.disabled then
    annotations.clear(bufnr, SOURCE)
  else
    refresh(bufnr)
  end
end

function M.setup()
  if not user.lsp.unused_symbols then
    return
  end
  vim.api.nvim_set_hl(0, HIGHLIGHT, { link = "DiagnosticVirtualTextHint", default = true })
  local group = vim.api.nvim_create_augroup("myconfig_unused", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Mark declarations nothing references",
    callback = function(event)
      if client_for(event.buf) then
        attach(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    desc = "Stop marking declarations once the last client leaves",
    callback = function(event)
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(event.buf) and not client_for(event.buf) then
          detach(event.buf)
        end
      end)
    end,
  })
  vim.keymap.set("n", "<leader>uu", M.toggle, { desc = "Toggle unused markers" })
end

return M
