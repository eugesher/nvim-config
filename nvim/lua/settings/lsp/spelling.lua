local user = require("user.settings")

local M = {}

M.namespace = vim.api.nvim_create_namespace("myconfig.spelling")

local SERVER = "codebook"
local SHADOW = ".spelling"

local state = {}
local owners = {}

local function client_for(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr, name = SERVER })[1]
end

local function shadow_uri(bufnr)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" then
    return nil
  end
  local base = vim.fs.basename(name)
  local stem, extension = base:match("^(.+)(%.[^.]+)$")
  if not stem then
    stem, extension = base, ""
  end
  return vim.uri_from_fname(
    vim.fs.joinpath(vim.fs.dirname(name), "." .. stem .. SHADOW .. extension)
  )
end

local function templated(node)
  local parent = node:parent()
  return parent ~= nil and parent:type():find("template") ~= nil
end

local function string_ranges(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
  if not parser then
    return {}
  end
  parser:parse()
  local ranges = {}
  local function walk(node)
    for child in node:iter_children() do
      if child:named() then
        if child:type():find("string") and child:named_child_count() == 0 then
          if not templated(child) then
            ranges[#ranges + 1] = { child:range() }
          end
        else
          walk(child)
        end
      end
    end
  end
  parser:for_each_tree(function(tree)
    walk(tree:root())
  end)
  return ranges
end

local function shadow_lines(bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local spans = {}
  for _, range in ipairs(string_ranges(bufnr)) do
    for row = range[1], range[3] do
      local line = lines[row + 1]
      if line then
        local from = row == range[1] and range[2] or 0
        local to = math.min(row == range[3] and range[4] or #line, #line)
        local chunk = line:sub(from + 1, to)
        if chunk:find("/", 1, true) then
          lines[row + 1] = line:sub(1, from) .. chunk:gsub("/", " ") .. line:sub(to + 1)
          spans[row] = spans[row] or {}
          table.insert(spans[row], { from, to })
        end
      end
    end
  end
  return lines, spans
end

local function inside(spans, lnum, col)
  for _, span in ipairs(spans and spans[lnum] or {}) do
    if col >= span[1] and col < span[2] then
      return true
    end
  end
  return false
end

local function byte_col(bufnr, position, encoding)
  local line = vim.api.nvim_buf_get_lines(bufnr, position.line, position.line + 1, false)[1] or ""
  local ok, col = pcall(vim.str_byteindex, line, encoding, position.character, false)
  return ok and col or position.character
end

local function reported(bufnr, client, item)
  local namespace = vim.lsp.diagnostic.get_namespace(client.id)
  for _, diagnostic in
    ipairs(vim.diagnostic.get(bufnr, { namespace = namespace, lnum = item.lnum }))
  do
    if diagnostic.col == item.col then
      return true
    end
  end
  return false
end

local function show(bufnr, client, items)
  state[bufnr].items = items
  vim.diagnostic.set(
    M.namespace,
    bufnr,
    vim.tbl_filter(function(item)
      return not reported(bufnr, client, item)
    end, items)
  )
end

local function publish(bufnr, client, diagnostics)
  local entry = state[bufnr]
  if not entry or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local items = {}
  for _, diagnostic in ipairs(diagnostics or {}) do
    local lnum = diagnostic.range.start.line
    local col = byte_col(bufnr, diagnostic.range.start, client.offset_encoding)
    if inside(entry.spans, lnum, col) then
      items[#items + 1] = {
        lnum = lnum,
        col = col,
        end_lnum = diagnostic.range["end"].line,
        end_col = byte_col(bufnr, diagnostic.range["end"], client.offset_encoding),
        severity = diagnostic.severity or vim.diagnostic.severity.HINT,
        source = diagnostic.source,
        message = diagnostic.message,
      }
    end
  end
  show(bufnr, client, items)
end

local function close(bufnr)
  local entry = state[bufnr]
  if not entry or not entry.opened then
    return
  end
  entry.opened = false
  local client = vim.api.nvim_buf_is_valid(bufnr) and client_for(bufnr)
  if client then
    client:notify("textDocument/didClose", { textDocument = { uri = entry.uri } })
  end
end

local function sync(bufnr)
  local entry = state[bufnr]
  local client = entry and client_for(bufnr)
  if not client or not vim.api.nvim_buf_is_loaded(bufnr) then
    return
  end
  local lines, spans = shadow_lines(bufnr)
  entry.spans = spans
  if not next(spans) then
    close(bufnr)
    vim.diagnostic.reset(M.namespace, bufnr)
    return
  end
  entry.version = entry.version + 1
  if entry.opened then
    client:notify("textDocument/didClose", { textDocument = { uri = entry.uri } })
  end
  entry.opened = client:notify("textDocument/didOpen", {
    textDocument = {
      uri = entry.uri,
      languageId = vim.bo[bufnr].filetype,
      version = entry.version,
      text = table.concat(lines, "\n") .. "\n",
    },
  })
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
    sync(bufnr)
  end, delay)
end

local function augroup(bufnr)
  return "myconfig_spelling_" .. bufnr
end

local function attach(bufnr)
  if state[bufnr] or vim.bo[bufnr].buftype ~= "" then
    return
  end
  local uri = shadow_uri(bufnr)
  if not uri then
    return
  end
  state[bufnr] = { uri = uri, version = 0, spans = {}, items = {} }
  owners[uri] = bufnr
  vim.api.nvim_create_autocmd({ "TextChanged", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup(augroup(bufnr), { clear = true }),
    buffer = bufnr,
    desc = "Spell-check the path strings codebook skips",
    callback = function()
      schedule(bufnr, 500)
    end,
  })
  schedule(bufnr, 100)
end

local function detach(bufnr)
  local entry = state[bufnr]
  if not entry then
    return
  end
  if entry.timer then
    entry.timer:stop()
  end
  close(bufnr)
  owners[entry.uri] = nil
  state[bufnr] = nil
  pcall(vim.api.nvim_del_augroup_by_name, augroup(bufnr))
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.diagnostic.reset(M.namespace, bufnr)
  end
end

function M.handler(err, result, ctx, config)
  local client = result and vim.lsp.get_client_by_id(ctx.client_id)
  local shadow = client and owners[result.uri]
  if shadow then
    publish(shadow, client, result.diagnostics)
    return
  end
  local handled = vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
  local bufnr = client and vim.fn.bufnr(vim.uri_to_fname(result.uri))
  if bufnr and bufnr ~= -1 and state[bufnr] and state[bufnr].items then
    show(bufnr, client, state[bufnr].items)
  end
  return handled
end

function M.setup()
  if not user.spelling.check_paths then
    return
  end
  local group = vim.api.nvim_create_augroup("myconfig_spelling", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "Spell-check the path strings codebook skips",
    callback = function(event)
      if client_for(event.buf) then
        attach(event.buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    desc = "Stop spell-checking path strings once codebook leaves",
    callback = function(event)
      vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(event.buf) or not client_for(event.buf) then
          detach(event.buf)
        end
      end)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
    group = group,
    desc = "Drop the path strings of a deleted buffer",
    callback = function(event)
      detach(event.buf)
    end,
  })
end

return M
