local M = {}

local SPEC_FIELDS = {
  "enabled",
  "cond",
  "event",
  "ft",
  "cmd",
  "keys",
  "opts",
  "init",
  "config",
  "priority",
  "lazy",
}

function M.load(name)
  local modname = "settings." .. name
  local ok, mod = pcall(require, modname)
  if not ok then
    error(("settings: cannot load `%s`\n%s"):format(modname, mod), 0)
  end
  if type(mod) ~= "table" then
    error(("settings: `%s` must return a table, got %s"):format(modname, type(mod)), 0)
  end
  return mod
end

local loaded = {}

function M.spec(repo, name, extra)
  local spec = { repo }
  if name then
    local mod = M.load(name)
    loaded[name] = true
    for _, field in ipairs(SPEC_FIELDS) do
      spec[field] = mod[field]
    end
  end
  return vim.tbl_deep_extend("force", spec, extra or {})
end

local function is_enabled(mod)
  for _, field in ipairs({ "enabled", "cond" }) do
    local value = mod[field]
    if type(value) == "function" then
      value = value()
    end
    if value == false then
      return false
    end
  end
  return true
end

function M.which_key()
  local names = vim.tbl_keys(loaded)
  table.sort(names)

  local specs = {}
  for _, name in ipairs(names) do
    local mod = M.load(name)
    if mod.which_key and is_enabled(mod) then
      vim.list_extend(specs, mod.which_key)
    end
  end
  return specs
end

return M
