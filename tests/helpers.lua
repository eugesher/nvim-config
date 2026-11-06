local M = {}

local stubs = {}
local notes = {}
local work
local cwd

local FRESH = { "^core%.", "^settings%.", "^kulala", "^lazy$", "^conform$" }

local function store_path()
  return vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", "trust.json")
end

function M.stub(target, key, value)
  stubs[#stubs + 1] = { target = target, key = key, value = rawget(target, key) }
  rawset(target, key, value)
  return value
end

function M.setenv(key, value)
  stubs[#stubs + 1] = { env = key, value = vim.env[key] }
  vim.env[key] = value
end

function M.reset(dir)
  work = dir
  cwd = vim.uv.cwd()
  for name in pairs(package.loaded) do
    for _, pattern in ipairs(FRESH) do
      if name:match(pattern) then
        package.loaded[name] = nil
      end
    end
  end
  for _, kind in ipairs({ "config", "data", "state", "cache" }) do
    local dir = vim.fn.stdpath(kind)
    if vim.fs.relpath(vim.env.TEST_SANDBOX, dir) then
      vim.fn.delete(dir, "rf")
      vim.fn.mkdir(dir, "p")
    end
  end
  notes = {}
  M.stub(vim, "notify", function(message, level)
    notes[#notes + 1] = { message = message, level = level }
  end)
end

function M.restore()
  for i = #stubs, 1, -1 do
    local stub = stubs[i]
    if stub.env then
      vim.env[stub.env] = stub.value
    else
      rawset(stub.target, stub.key, stub.value)
    end
  end
  stubs = {}
  vim.fn.chdir(cwd)
  vim.cmd("silent! %bwipeout!")
end

function M.notes()
  return vim.tbl_map(function(note)
    return note.message
  end, notes)
end

function M.noted(pattern)
  return vim.iter(notes):any(function(note)
    return tostring(note.message):find(pattern) ~= nil
  end)
end

function M.path(...)
  return vim.fs.joinpath(work, ...)
end

function M.write(path, content, mode)
  vim.fn.mkdir(vim.fs.dirname(path), "p")
  local file = assert(io.open(path, "w"))
  file:write(content or "")
  file:close()
  if mode then
    vim.uv.fs_chmod(path, tonumber(mode, 8))
  end
  return path
end

function M.read(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local data = file:read("*a")
  file:close()
  return data
end

function M.buffer(path)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf()
end

function M.wait(fn, ms)
  return vim.wait(ms or 2000, fn, 10)
end

function M.project(name, files)
  local root = M.path(name)
  vim.fn.mkdir(root, "p")
  for file, content in pairs(files or {}) do
    M.write(vim.fs.joinpath(root, file), content)
  end
  return root
end

function M.run(cmd)
  local result = vim.system(cmd, { text = true }):wait(10000)
  if result.code ~= 0 then
    error(("%s failed (%s): %s"):format(table.concat(cmd, " "), result.code, result.stderr), 2)
  end
  return result.stdout
end

function M.git(dir, ...)
  return M.run(vim.list_extend({ "git", "-C", dir }, { ... }))
end

function M.store()
  local file = io.open(store_path(), "r")
  if not file then
    return {}
  end
  local store = vim.json.decode(file:read("*a"))
  file:close()
  return store
end

local function answer(choice)
  if type(choice) == "table" then
    return table.remove(choice, 1) or 3
  end
  return choice
end

function M.ui(choice)
  local asked = {}
  M.stub(vim.api, "nvim_list_uis", function()
    return { {} }
  end)
  M.stub(vim.fn, "confirm", function(message)
    asked[#asked + 1] = message
    return answer(choice)
  end)
  return asked
end

function M.with_ui(choice, fn)
  local asked = {}
  local saved = { list_uis = rawget(vim.api, "nvim_list_uis"), confirm = rawget(vim.fn, "confirm") }
  vim.api.nvim_list_uis = function()
    return { {} }
  end
  vim.fn.confirm = function(message)
    asked[#asked + 1] = message
    return answer(choice)
  end
  local ok, result = pcall(fn)
  rawset(vim.api, "nvim_list_uis", saved.list_uis)
  rawset(vim.fn, "confirm", saved.confirm)
  if not ok then
    error(result, 0)
  end
  return result, asked
end

function M.fingerprint(root)
  local trust = require("core.trust")
  os.remove(store_path())
  M.with_ui(1, function()
    return trust.allowed(root)
  end)
  local entry = M.store()[vim.uv.fs_realpath(root)]
  M.ok(type(entry) == "table" and entry.fingerprint, "no fingerprint stored for " .. root)
  return entry.fingerprint
end

function M.ok(value, message)
  if not value then
    error(message or "expected a true value", 2)
  end
  return value
end

function M.eq(actual, expected, message)
  if not vim.deep_equal(actual, expected) then
    error(
      ("%s\n  expected: %s\n  actual:   %s"):format(
        message or "values differ",
        vim.inspect(expected),
        vim.inspect(actual)
      ),
      2
    )
  end
end

function M.neq(actual, unexpected, message)
  if vim.deep_equal(actual, unexpected) then
    error(("%s\n  both: %s"):format(message or "values are equal", vim.inspect(actual)), 2)
  end
end

return M
