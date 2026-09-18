local here = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p"))
local common = dofile(here .. "/keymaps-common.lua")
local out = common.out

local LIST = vim.tbl_contains(arg, "--list")

local ALLOWED_DUPLICATES = {
  { lhs = "grn" },
  { lhs = "<leader>cr" },
  { lhs = "<leader>rn" },
  { lhs = "gri", source = "settings/lsp/keymaps.lua" },
  { lhs = "grr", source = "settings/lsp/keymaps.lua" },
  { lhs = "grt", source = "settings/lsp/keymaps.lua" },
  { lhs = "<leader>q" },
  { lhs = "<leader>bd" },
  { lhs = "ih" },
  { lhs = "ah" },
  { lhs = "<C-l>", mode = "n", source = "core/keymaps.lua" },
  { lhs = "[b", mode = "n" },
  { lhs = "]b", mode = "n" },
  { lhs = "[a", mode = "n" },
  { lhs = "]a", mode = "n" },
  { lhs = "[t", mode = "n" },
  { lhs = "]t", mode = "n" },
  { lhs = "<C-j>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<C-n>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<C-k>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<C-p>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<Tab>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<S-Tab>", mode = "i", source = "blink/cmp/keymap" },
  { lhs = "<Tab>", mode = "s", source = "blink/cmp/keymap" },
  { lhs = "<S-Tab>", mode = "s", source = "blink/cmp/keymap" },
}

local ALLOWED_WITHOUT_DESC = {
  { source = "pack/dist/opt/matchit/plugin/matchit.vim" },
  { source = "$VIMRUNTIME/ftplugin/" },
  { lhs = "<MouseMove>", source = "bufferline/hover.lua" },
  { lhs = "<Left>", mode = "i", source = "multicursor-nvim/core.lua" },
  { lhs = "<Right>", mode = "i", source = "multicursor-nvim/core.lua" },
  { lhs = "<Tab>", mode = "x", source = "luasnip/config.lua" },
}

local ALLOWED_PREFIXES = {
  { lhs = "]t", mode = "n" },
  { lhs = "[t", mode = "n" },
}

local function normalize_whitelists()
  for _, list in ipairs({ ALLOWED_DUPLICATES, ALLOWED_WITHOUT_DESC, ALLOWED_PREFIXES }) do
    for _, entry in ipairs(list) do
      entry.key = entry.lhs and common.key(entry.lhs)
    end
  end
end

local function allowed(list, mode, key, source)
  for _, entry in ipairs(list) do
    if
      (entry.mode == nil or entry.mode == mode)
      and (entry.key == nil or entry.key == key)
      and (entry.source == nil or (source or ""):find(entry.source, 1, true) ~= nil)
    then
      entry.used = true
      return true
    end
  end
  return false
end

local problems, warnings = 0, 0
local function section(title, items, fail)
  table.sort(items)
  items = vim.fn.uniq(items)
  out("")
  out(("== %s: %d"):format(title, #items))
  for _, item in ipairs(items) do
    out("  " .. item)
  end
  if fail then
    problems = problems + #items
  else
    warnings = warnings + #items
  end
end

local recording = common.start_recording()
common.bootstrap()
normalize_whitelists()
local samples = common.open_samples(20000)

out("Keymap audit of " .. common.config_dir)
for _, sample in ipairs(samples) do
  local missing = vim.tbl_filter(function(name)
    return not vim.tbl_contains(sample.attached, name)
  end, sample.servers)
  out(
    ("  %-12s %-22s LSP: %s%s"):format(
      sample.file,
      sample.filetype,
      #sample.attached > 0 and table.concat(sample.attached, ", ") or "none",
      #missing > 0 and ("  (did not attach: " .. table.concat(missing, ", ") .. ")") or ""
    )
  )
end

local global = common.collect(nil)
local buffers = {}
for _, sample in ipairs(samples) do
  buffers[#buffers + 1] = { label = sample.filetype, maps = common.collect(sample.buf) }
end

if LIST then
  for _, scope in ipairs({ { label = "global", maps = global }, unpack(buffers) }) do
    out("")
    out("-- " .. scope.label)
    for _, map in ipairs(scope.maps) do
      out(("  %s %-24s %-44s %s"):format(map.mode, map.key, map.desc, map.source))
    end
  end
end

local function effective(buffer_maps)
  local seen, maps = {}, {}
  for _, map in ipairs(buffer_maps) do
    seen[map.mode .. "\0" .. map.key] = true
    maps[#maps + 1] = map
  end
  for _, map in ipairs(global) do
    if not seen[map.mode .. "\0" .. map.key] then
      maps[#maps + 1] = map
    end
  end
  return maps
end

local duplicates = {}

for _, r in ipairs(recording.redefinitions) do
  local internal = common.is_internal(r.key, r.first.desc)
    or common.is_internal(r.key, r.second.desc)
  local refresh = r.first.source == r.second.source and r.first.desc == r.second.desc
  if
    not internal
    and not refresh
    and not allowed(ALLOWED_DUPLICATES, r.mode, r.key, r.second.source)
  then
    duplicates[#duplicates + 1] = ("%s %-16s [%s] %s, then %s"):format(
      r.mode,
      r.key,
      common.label(r.scope),
      common.pretty(r.first.source, r.mode, r.key),
      common.pretty(r.second.source, r.mode, r.key)
    )
  end
end

local global_index = {}
for _, map in ipairs(global) do
  global_index[map.mode .. "\0" .. map.key] = map
end
for _, buffer in ipairs(buffers) do
  for _, map in ipairs(buffer.maps) do
    local hidden = global_index[map.mode .. "\0" .. map.key]
    if
      hidden
      and not common.is_internal(map.key, map.desc)
      and not common.is_internal(hidden.key, hidden.desc)
      and not allowed(ALLOWED_DUPLICATES, map.mode, map.key, map.source)
    then
      duplicates[#duplicates + 1] = ("%s %-16s [%s] %s hides the global %s"):format(
        map.mode,
        map.key,
        buffer.label,
        map.source,
        hidden.source
      )
    end
  end
end

local function aliases(maps, label, buffer_only)
  local by_desc = {}
  for _, map in ipairs(maps) do
    if map.desc ~= "" and not common.is_internal(map.key, map.desc) then
      local id = map.mode .. "\0" .. map.desc
      by_desc[id] = by_desc[id] or {}
      table.insert(by_desc[id], map)
    end
  end
  for _, group in pairs(by_desc) do
    local has_buffer, all_default = false, true
    for _, map in ipairs(group) do
      has_buffer = has_buffer or map.buffer ~= nil
      all_default = all_default and map.default
    end
    if #group > 1 and (has_buffer or not buffer_only) and not all_default then
      local keys, ok = {}, true
      for _, map in ipairs(group) do
        keys[#keys + 1] = map.key
        ok = allowed(ALLOWED_DUPLICATES, map.mode, map.key, map.source) and ok
      end
      table.sort(keys)
      if not ok then
        duplicates[#duplicates + 1] = ("%s %s [%s] share the description %q"):format(
          group[1].mode,
          table.concat(keys, " = "),
          label,
          group[1].desc
        )
      end
    end
  end
end
aliases(global, "global", false)
for _, buffer in ipairs(buffers) do
  aliases(effective(buffer.maps), buffer.label, true)
end
section("Duplicates", duplicates, true)

local groups = {}
for _, group in ipairs(require("settings.whichkey.whichkey").groups) do
  groups[common.key(group[1])] = true
end
local collisions = {}
local function prefixes(maps, label, buffer_only)
  local by_mode = {}
  for _, map in ipairs(maps) do
    if not common.is_internal(map.key, map.desc) then
      by_mode[map.mode] = by_mode[map.mode] or {}
      table.insert(by_mode[map.mode], map)
    end
  end
  for mode, list in pairs(by_mode) do
    for _, short in ipairs(list) do
      if not groups[short.key] then
        for _, long in ipairs(list) do
          if
            common.is_prefix(short.tokens, long.tokens)
            and not (short.default and long.default)
            and (not buffer_only or short.buffer ~= nil or long.buffer ~= nil)
            and not allowed(ALLOWED_PREFIXES, mode, short.key, short.source)
          then
            collisions[#collisions + 1] = ("%s %-10s is a prefix of %-14s [%s]"):format(
              mode,
              short.key,
              long.key,
              label
            )
          end
        end
      end
    end
  end
end
prefixes(global, "global", false)
for _, buffer in ipairs(buffers) do
  prefixes(effective(buffer.maps), buffer.label, true)
end
section("Prefix collisions (not failing)", collisions, false)

local undescribed = {}
for _, scope in ipairs({ { label = "global", maps = global }, unpack(buffers) }) do
  for _, map in ipairs(scope.maps) do
    if
      map.desc == ""
      and not map.key:find("^<Plug>")
      and not map.key:find("^<SNR>")
      and not allowed(ALLOWED_WITHOUT_DESC, map.mode, map.key, map.source)
    then
      undescribed[#undescribed + 1] = ("%s %-16s [%s] %s"):format(
        map.mode,
        map.key,
        scope.label,
        map.source
      )
    end
  end
end
section("Keymaps without desc", undescribed, true)

local policy = {}
local function each_map(fn)
  for _, scope in ipairs({ { label = "global", maps = global }, unpack(buffers) }) do
    for _, map in ipairs(scope.maps) do
      fn(map, scope.label)
    end
  end
end
local function describe(map, label)
  return ("%s %s [%s] %s"):format(map.mode, map.key, label, map.source)
end
local reserved = {}
for _, lhs in ipairs({ "]n", "[n", "an", "in", "]c", "[c" }) do
  reserved[common.key(lhs)] = true
end
local free = vim.tbl_map(common.key, { "<leader>gL" })
local alt_allowed = { ["<M-j>"] = true, ["<M-k>"] = true }
each_map(function(map, label)
  if map.key:find("<M%-") and not alt_allowed[map.key] then
    policy[#policy + 1] = "Alt layer (only <A-j> / <A-k>): " .. describe(map, label)
  end
  if reserved[map.key] and not map.default then
    policy[#policy + 1] = "reserved for Neovim: " .. describe(map, label)
  end
  for _, key in ipairs(free) do
    if map.key == key or common.is_prefix(key, map.key) then
      policy[#policy + 1] = key .. " must stay free: " .. describe(map, label)
    end
  end
end)
for _, group in ipairs(require("settings.whichkey.whichkey").groups) do
  if not group.group or not group.icon or group[2] ~= nil or group.desc ~= nil then
    policy[#policy + 1] = "settings/whichkey/whichkey.lua declares a keymap, not a group: "
      .. group[1]
  end
end
section("Policy violations", policy, true)

local stale = {}
for name, list in pairs({
  duplicates = ALLOWED_DUPLICATES,
  without_desc = ALLOWED_WITHOUT_DESC,
  prefixes = ALLOWED_PREFIXES,
}) do
  for _, entry in ipairs(list) do
    if not entry.used then
      stale[#stale + 1] = ("%s: %s %s %s"):format(
        name,
        entry.mode or "*",
        entry.lhs or "*",
        entry.source or ""
      )
    end
  end
end
section("Unused whitelist entries (not failing)", stale, false)

out("")
out(("Result: %d problem(s), %d warning(s)"):format(problems, warnings))
os.exit(problems > 0 and 1 or 0)
