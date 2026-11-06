local repo = vim.fs.dirname(vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(arg[0], ":p"))))
local sandbox = vim.env.TEST_SANDBOX

local function abort(message)
  io.stderr:write(message .. "\n")
  os.exit(2)
end

if not sandbox or sandbox == "" then
  abort("TEST_SANDBOX is not set: run tests/run.sh")
end
for _, kind in ipairs({ "config", "data", "state", "cache" }) do
  local dir = vim.fn.stdpath(kind)
  if not vim.fs.relpath(sandbox, dir) then
    abort(("stdpath(%q) is %s, outside the sandbox"):format(kind, dir))
  end
end

local home = vim.fs.joinpath(sandbox, "home")
vim.env.TEST_REPO = repo
vim.uv.os_homedir = function()
  return home
end

package.path = table.concat({
  repo .. "/nvim/lua/?.lua",
  repo .. "/nvim/lua/?/init.lua",
  repo .. "/tests/?.lua",
  package.path,
}, ";")

local out_path
local patterns = {}
local i = 1
while i <= #arg do
  if arg[i] == "--out" then
    out_path = arg[i + 1]
    i = i + 2
  else
    patterns[#patterns + 1] = arg[i]
    i = i + 1
  end
end

local function selected(name)
  if #patterns == 0 then
    return true
  end
  return vim.iter(patterns):any(function(pattern)
    return name:find(pattern, 1, true) ~= nil
  end)
end

local specs = {}
for name, kind in vim.fs.dir(repo .. "/tests") do
  if kind == "file" and name:match("_spec%.lua$") then
    specs[#specs + 1] = name
  end
end
table.sort(specs)

local helpers = require("helpers")
local results = {}
local counter = 0

for _, spec in ipairs(specs) do
  local cases = dofile(vim.fs.joinpath(repo, "tests", spec))
  for _, case in ipairs(cases) do
    local name, fn = case[1], case[2]
    if selected(name) then
      counter = counter + 1
      local work = vim.fs.joinpath(home, "work", tostring(counter))
      vim.fn.mkdir(work, "p")
      helpers.reset(work)
      local ok, err = xpcall(fn, debug.traceback, helpers)
      helpers.restore()
      results[#results + 1] = { name = name, ok = ok, err = ok and "" or tostring(err) }
      io.write(("%s %s\n"):format(ok and "PASS" or "FAIL", name))
      if not ok then
        io.write("  " .. tostring(err):gsub("\n", "\n  ") .. "\n")
      end
    end
  end
end

local failed = #vim.tbl_filter(function(result)
  return not result.ok
end, results)
io.write(
  ("tests executed: %d, passed: %d, failed: %d\n"):format(#results, #results - failed, failed)
)

if out_path then
  local lines = {}
  for _, result in ipairs(results) do
    local message = result.err:match("^[^\n]*") or ""
    lines[#lines + 1] = table.concat({ result.ok and "PASS" or "FAIL", result.name, message }, "\t")
  end
  local file = assert(io.open(out_path, "w"))
  file:write(table.concat(lines, "\n") .. "\n")
  file:close()
end

os.exit((failed > 0 or #results == 0) and 1 or 0)
