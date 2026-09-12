-- Glue between thin plugin specs (lua/plugins/*) and plugin settings
-- (lua/settings/*).
--
-- Settings modules live in `lua/settings/<group>/<name>.lua`, where <group> is
-- the file in lua/plugins/ that declares the plugin; the spec names the module
-- as "<group>.<name>". A module returns a table with any of these fields, all
-- optional:
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
--                      only in settings/whichkey/whichkey.lua.
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

-- Names of the settings modules behind the plugin specs, filled by M.spec().
local loaded = {}

--- Builds a lazy.nvim spec for `repo` from settings module `name`.
---@param repo string plugin repository, e.g. "folke/which-key.nvim"
---@param name? string settings module name ("ui.theme" → settings/ui/theme.lua); nil for none
---@param extra? table spec fields merged on top (dependencies, build, version, …)
---@return table
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

--- Collects the `which_key` fields of the enabled settings modules behind the
--- plugin specs (in module-name order) into one flat list of which-key specs.
--- Helper modules nothing builds a spec from (icons, lsp/keymaps, …) are skipped.
---@return table[]
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
