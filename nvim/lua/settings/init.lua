-- Glue between thin plugin specs (lua/plugins/*) and plugin settings
-- (lua/settings/*).
--
-- Contract of a settings module `lua/settings/<name>.lua` — it returns a table
-- with any of these fields, all optional:
--
--   enabled, cond      boolean|fun(): boolean — same as in a lazy.nvim spec
--   event, ft, cmd,    lazy-loading triggers, passed to lazy.nvim as is
--   keys
--   opts, init,        plugin setup, passed to lazy.nvim as is
--   config
--   priority, lazy     load order / eager loading, passed to lazy.nvim as is
--   which_key          list of which-key specs describing keymaps the plugin
--                      creates itself (so there is no `keys` entry to carry a
--                      `desc`); collected by M.which_key(), never passed to
--                      lazy.nvim. Groups are NOT declared here — they live
--                      only in settings/whichkey.lua.
--
-- Anything else in the module (helpers, exported functions) is ignored here.
-- Repository-level fields (`dependencies`, `build`, `version`, `commit`) belong
-- in the plugin spec and arrive through `extra`.

local M = {}

-- Fields copied from a settings module into the lazy.nvim spec.
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

--- Loads `settings.<name>`, failing with an error that names the module.
---@param name string
---@return table
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

--- Builds a lazy.nvim spec for `repo` from settings module `name`.
---@param repo string plugin repository, e.g. "folke/which-key.nvim"
---@param name? string settings module name ("whichkey" → settings.whichkey); nil for none
---@param extra? table spec fields merged on top (dependencies, build, version, …)
---@return table
function M.spec(repo, name, extra)
  local spec = { repo }
  if name then
    local mod = M.load(name)
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

--- Collects the `which_key` fields of all enabled settings modules of this
--- config (in module-name order) into one flat list of which-key specs.
---@return table[]
function M.which_key()
  local dir = vim.fn.stdpath("config") .. "/lua/settings"
  local names = {}
  for file, kind in vim.fs.dir(dir) do
    local name = file:match("^(.+)%.lua$")
    if kind == "file" and name and name ~= "init" then
      names[#names + 1] = name
    end
  end
  table.sort(names)

  local specs = {}
  for _, name in ipairs(names) do
    local ok, mod = pcall(M.load, name)
    if not ok then
      vim.notify(mod, vim.log.levels.ERROR)
    elseif mod.which_key and is_enabled(mod) then
      vim.list_extend(specs, mod.which_key)
    end
  end
  return specs
end

return M
