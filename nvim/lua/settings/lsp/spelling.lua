local project = require("settings.lsp.project")
local user = require("user.settings")

local M = {}

M.namespace = vim.api.nvim_create_namespace("myconfig.spelling")

local SERVER = "codebook"
local SHADOW = ".spelling"
local SIGN_HIGHLIGHT = "SpellingSign"

M.sign_highlight = SIGN_HIGHLIGHT

local state = {}
local owners = {}
local claimed = {}
local waiters = {}

local function client_for(bufnr)
  return vim.lsp.get_clients({ bufnr = bufnr, name = SERVER })[1]
end

local function shadow_uri(name)
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

local function string_ranges(parser)
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

local function shadow_lines(lines, parser)
  lines = vim.list_extend({}, lines)
  local spans = {}
  for _, range in ipairs(string_ranges(parser)) do
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
  local lines, spans = shadow_lines(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    vim.treesitter.get_parser(bufnr, nil, { error = false })
  )
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
  local uri = shadow_uri(vim.api.nvim_buf_get_name(bufnr))
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
  local claim = client and claimed[result.uri]
  if claim and not project.attached_buffer(client, vim.uri_to_fname(result.uri)) then
    local waiter = waiters[result.uri]
    if waiter then
      waiters[result.uri] = nil
      waiter(result.diagnostics or {})
    elseif claim == "closing" then
      claimed[result.uri] = nil
    end
    return
  end
  local handled = vim.lsp.handlers["textDocument/publishDiagnostics"](err, result, ctx, config)
  local bufnr = client and vim.fn.bufnr(vim.uri_to_fname(result.uri))
  if bufnr and bufnr ~= -1 and state[bufnr] and state[bufnr].items then
    show(bufnr, client, state[bufnr].items)
  end
  return handled
end

local function line_col(lines, position, encoding)
  local line = lines[position.line + 1] or ""
  local ok, col = pcall(vim.str_byteindex, line, encoding, position.character, false)
  return ok and col or position.character
end

local function quickfix_item(path, lnum, col, message)
  return { filename = path, lnum = lnum + 1, col = col + 1, text = message, type = "N" }
end

local function sorted(items)
  table.sort(items, function(a, b)
    return a.lnum < b.lnum or (a.lnum == b.lnum and a.col < b.col)
  end)
  return items
end

local function buffer_items(bufnr, client, path)
  local items = {}
  for _, namespace in ipairs({ vim.lsp.diagnostic.get_namespace(client.id), M.namespace }) do
    for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespace })) do
      items[#items + 1] = quickfix_item(path, diagnostic.lnum, diagnostic.col, diagnostic.message)
    end
  end
  return sorted(items)
end

local function file_parser(lines, filetype)
  local lang = vim.treesitter.language.get_lang(filetype)
  if not lang then
    return nil
  end
  local ok, parser = pcall(vim.treesitter.get_string_parser, table.concat(lines, "\n"), lang)
  return ok and parser or nil
end

local function scan_file(job, file, done)
  local client = job.client
  local bufnr = project.attached_buffer(client, file.path)
  if bufnr then
    done(buffer_items(bufnr, client, file.path))
    return
  end
  local ok, lines = pcall(vim.fn.readfile, file.path)
  if not ok then
    done({})
    return
  end
  local documents = { { uri = vim.uri_from_fname(file.path), lines = lines } }
  if user.spelling.check_paths then
    local shadow, spans = shadow_lines(lines, file_parser(lines, file.filetype))
    if next(spans) then
      documents[2] = { uri = shadow_uri(file.path), lines = shadow, spans = spans }
    end
  end

  local waiting, finished, timer = #documents, false, nil
  local function finish()
    if finished then
      return
    end
    finished = true
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    local items, seen = {}, {}
    for _, document in ipairs(documents) do
      waiters[document.uri] = nil
      project.close(job, document.uri)
      claimed[document.uri] = "closing"
      for _, diagnostic in ipairs(document.diagnostics or {}) do
        local lnum = diagnostic.range.start.line
        local col = line_col(lines, diagnostic.range.start, client.offset_encoding)
        local key = lnum .. ":" .. col
        if not seen[key] and (not document.spans or inside(document.spans, lnum, col)) then
          seen[key] = true
          items[#items + 1] = quickfix_item(file.path, lnum, col, diagnostic.message)
        end
      end
    end
    done(sorted(items))
  end

  for _, document in ipairs(documents) do
    claimed[document.uri] = "open"
    waiters[document.uri] = function(diagnostics)
      document.diagnostics = diagnostics
      waiting = waiting - 1
      if waiting == 0 then
        finish()
      end
    end
    project.open(job, document.uri, file.filetype, document.lines)
  end
  timer = vim.defer_fn(finish, user.spelling.scan_timeout)
end

local function scan_client(bufnr)
  local client = client_for(bufnr)
  if client then
    return client
  end
  local cwd = vim.fs.normalize(vim.fn.getcwd())
  for _, candidate in ipairs(vim.lsp.get_clients({ name = SERVER })) do
    local root = candidate.root_dir and vim.fs.normalize(candidate.root_dir)
    if root and (cwd == root or vim.startswith(cwd, root .. "/")) then
      return candidate
    end
  end
end

local scanner = project.new({
  title = "Spelling issues",
  source = "myconfig.spelling",
  no_client = "codebook is not running for this project",
  client = scan_client,
  scan_file = scan_file,
  parallel = user.spelling.scan_parallel,
  summary = function(found, paths)
    return ("%d spelling issues in %d files"):format(found, paths)
  end,
})

M.scan_project = scanner.scan
M.cancel_project = scanner.cancel
M.clear_project = scanner.clear
M.project_count = scanner.count

function M.setup()
  vim.api.nvim_set_hl(0, SIGN_HIGHLIGHT, { link = "DiagnosticSignHint", default = true })
  local group = vim.api.nvim_create_augroup("myconfig_spelling", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    desc = "Recheck the spelling of a saved file in the project list",
    callback = function(event)
      scanner.rescan(event.buf)
    end,
  })
  vim.keymap.set("n", "<leader>xs", M.scan_project, { desc = "Spelling issues (project)" })
  vim.keymap.set("n", "<leader>xS", M.clear_project, { desc = "Clear spelling issues (project)" })
  if not user.spelling.check_paths then
    return
  end
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
