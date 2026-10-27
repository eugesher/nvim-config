local M = {}

local SCHEMASTORE_HOSTS = { "json.schemastore.org", "www.schemastore.org" }

local catalog
local contents = {}

local function allowed(uri)
  if not catalog then
    catalog = {}
    local schemastore = require("schemastore")
    for _, schema in ipairs(schemastore.json.schemas()) do
      catalog[schema.url] = true
    end
    for url in pairs(schemastore.yaml.schemas()) do
      catalog[url] = true
    end
  end
  local host = uri:match("^https://([^/:?#]+)[/?#]")
  return catalog[uri] or vim.list_contains(SCHEMASTORE_HOSTS, host)
end

local function fetch(uri)
  local cmd = {
    "curl",
    "--fail",
    "--silent",
    "--show-error",
    "--location",
    "--max-time",
    "15",
    "--proto",
    "=https",
    "--proto-redir",
    "=https",
    "--",
    uri,
  }
  local co, main = coroutine.running()
  if not co or main then
    return vim.system(cmd, { text = true }):wait(20000)
  end
  vim.system(cmd, { text = true }, function(result)
    vim.schedule(function()
      coroutine.resume(co, result)
    end)
  end)
  return coroutine.yield()
end

function M.content(_, params)
  local uri = type(params) == "table" and params[1] or params
  local function failure(message)
    return nil, vim.lsp.rpc_response_error(vim.lsp.protocol.ErrorCodes.InternalError, message)
  end
  if type(uri) ~= "string" or not allowed(uri) then
    return failure(("schema not loaded, it is not in the SchemaStore catalog: %s"):format(uri))
  end
  if not contents[uri] then
    local result = fetch(uri)
    if result.code ~= 0 then
      return failure(("schema download failed: %s %s"):format(uri, vim.trim(result.stderr or "")))
    end
    contents[uri] = result.stdout
  end
  return contents[uri]
end

return M
