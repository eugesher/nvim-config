-- Markdown tables of the keymaps this config defines, grouped by namespace —
-- the "Key bindings" section of README.md is this script's output.
--
--   nvim --headless -l scripts/dump-keymaps.lua            # print the tables
--   nvim --headless -l scripts/dump-keymaps.lua --readme   # rewrite README.md
--
-- Like audit-keymaps.lua it reads the installed config (`~/.config/nvim`) with
-- every plugin loaded and sample buffers open, so run install.sh first.

local here = vim.fs.dirname(vim.fn.fnamemodify(arg[0], ":p"))
local common = dofile(here .. "/keymaps-common.lua")

local README = common.repo_root .. "/README.md"
local START = "<!-- keymaps:start -->"
local FINISH = "<!-- keymaps:end -->"

-- Neovim's own keys that are part of the scheme although nothing redefines
-- them: the native LSP keys stay (rule 6), diagnostics and quickfix jumps are
-- the ones the config builds on.
local NATIVE = {
  n = { "gra", "gO", "grx", "]d", "[d", "]D", "[D", "<C-W>d", "]q", "[q" },
  x = { "gra" },
  i = { "<C-S>" },
}

-- Groups in README order.
local ORDER = {
  "General",
  "Navigation",
  "LSP / Code",
  "Find",
  "Explorer",
  "Git",
  "Database",
  "Debug",
  "Test",
  "HTTP",
  "Problems",
  "Refactor",
  "Multicursor",
  "Session",
  "Outline",
  "UI toggles",
  "Tooling",
  "Insert mode",
}

-- The first rule whose pattern matches the key wins.
local RULES = {
  { "Debug", { "^<Space>d", "^<F%d+>$", "^<S%-F%d+>$" } },
  { "Database", { "^<Space>D", "^\\" } },
  { "HTTP", { "^<Space>h" } },
  { "Test", { "^<Space>t", "^%]t$", "^%[t$" } },
  { "Problems", { "^<Space>x", "^%]td$", "^%[td$" } },
  { "Refactor", { "^<Space>r" } },
  { "Multicursor", { "^<Space>m", "^<C%-Left[A-Za-z]+>$" } },
  { "Session", { "^<Space>s" } },
  { "Outline", { "^<Space>o$", "^<Space>O$", "^{$", "^}$", "^<Space>;$" } },
  { "Explorer", { "^<Space>e$", "^<Space>E$", "^<Space>be$", "^%-$" } },
  { "Git", { "^<Space>g", "^%]h$", "^%[h$", "^%]H$", "^%[H$", "^ih$", "^ah$" } },
  { "Find", { "^<Space>f" } },
  { "UI toggles", { "^<Space>u" } },
  { "Tooling", { "^<Space>l" } },
  {
    "LSP / Code",
    { "^<Space>c", "^gr", "^gd$", "^gD$", "^K$", "^gO$", "^%][dDe]$", "^%[[dDe]$", "^<C%-W>d$" },
  },
  {
    "Navigation",
    {
      "^<C%-[hjklHJKL]>$",
      "^<C%-Up>$",
      "^<C%-Down>$",
      "^<C%-Left>$",
      "^<C%-Right>$",
      "^<C%-[dDuU]>$",
      "^%]",
      "^%[",
      "^<Space>%d$",
      "^<Space>b",
      "^<Space>q$",
      "^n$",
      "^N$",
    },
  },
}

local function group_of(row)
  -- Insert mode, and select mode where it only continues a snippet.
  if row.modes.i and not (row.modes.n or row.modes.x or row.modes.o or row.modes.t) then
    return "Insert mode"
  end
  for _, rule in ipairs(RULES) do
    for _, pattern in ipairs(rule[2]) do
      if row.key:find(pattern) then
        return rule[1]
      end
    end
  end
  -- Buffer-local LSP keys outside the namespaces (`gs` of vtsls).
  if row.source:find("settings/lsp/", 1, true) then
    return "LSP / Code"
  end
  return "General"
end

-- Keys as the config writes them: `<leader>` for the Space leader,
-- `<LocalLeader>` for `\` in the buffers where it is one.
local function readable(map)
  local key = map.key
  if key:sub(1, #"<Space>") == "<Space>" and #key > #"<Space>" then
    key = "<leader>" .. key:sub(#"<Space>" + 1)
  elseif map.buffer and key:sub(1, 1) == "\\" and #key > 1 then
    key = "<LocalLeader>" .. key:sub(2)
  end
  return (key:gsub("<lt>", "<"))
end

local function code(text)
  return text:find("`", 1, true) and ("`` " .. text .. " ``") or ("`" .. text .. "`")
end

-- Collect ----------------------------------------------------------------------

common.start_recording()
common.bootstrap()
local samples = common.open_samples(20000)

local native = {}
for mode, keys in pairs(NATIVE) do
  for _, lhs in ipairs(keys) do
    native[mode .. "\0" .. common.key(lhs)] = true
  end
end

local rows, by_id = {}, {}
local function add(map, label)
  if map.desc == "" or common.is_internal(map.key, map.desc) then
    return
  end
  if map.default and not native[map.mode .. "\0" .. map.key] then
    return
  end
  local key = readable(map)
  local id = key .. "\0" .. map.desc
  local row = by_id[id]
  if not row then
    row =
      { key = map.key, shown = key, desc = map.desc, source = map.source, modes = {}, where = {} }
    by_id[id] = row
    rows[#rows + 1] = row
  end
  row.modes[map.mode] = true
  if label then
    row.where[label] = true
  end
  row.global = row.global or label == nil
end

for _, map in ipairs(common.collect(nil)) do
  add(map, nil)
end
for _, sample in ipairs(samples) do
  for _, map in ipairs(common.collect(sample.buf)) do
    add(map, sample.filetype)
  end
end

-- Render ------------------------------------------------------------------------

local MODE_ORDER = { "n", "x", "s", "o", "i", "t" }
local function modes(row)
  local list = {}
  for _, mode in ipairs(MODE_ORDER) do
    if row.modes[mode] then
      list[#list + 1] = mode
    end
  end
  return table.concat(list, " ")
end

local function where(row)
  if row.global then
    return ""
  end
  local labels = vim.tbl_keys(row.where)
  if #labels == #samples then
    return "every file buffer"
  end
  table.sort(labels)
  return table.concat(labels, ", ")
end

local grouped = {}
for _, row in ipairs(rows) do
  local group = group_of(row)
  grouped[group] = grouped[group] or {}
  table.insert(grouped[group], row)
end

local lines = {
  START,
  "",
  "_Generated by `scripts/dump-keymaps.lua` from the keymaps that exist once every",
  "plugin is loaded — do not edit by hand. Rebuild after `./install.sh` with",
  "`nvim --headless -l scripts/dump-keymaps.lua --readme`. Leader is `Space`,",
  "local leader is `\\`. Modes: n normal, x visual, s select, o operator-pending,",
  'i insert, t terminal. "Buffer" lists the filetypes where a key is',
  "buffer-local (LSP keys appear once a language server is attached)._",
}
for _, name in ipairs(ORDER) do
  local list = grouped[name]
  if list then
    table.sort(list, function(a, b)
      if a.shown:lower() ~= b.shown:lower() then
        return a.shown:lower() < b.shown:lower()
      end
      return a.shown < b.shown
    end)
    vim.list_extend(lines, { "", "### " .. name, "", "| Keys | Mode | Description | Buffer |" })
    lines[#lines + 1] = "| --- | --- | --- | --- |"
    for _, row in ipairs(list) do
      lines[#lines + 1] = ("| %s | %s | %s | %s |"):format(
        code(row.shown),
        modes(row),
        (row.desc:gsub("|", "\\|")),
        where(row)
      )
    end
  end
end
vim.list_extend(lines, { "", FINISH })

if not vim.tbl_contains(arg, "--readme") then
  for _, line in ipairs(lines) do
    common.out(line)
  end
  os.exit(0)
end

local readme = vim.fn.readfile(README)
local first, last
for i, line in ipairs(readme) do
  if line == START then
    first = i
  elseif line == FINISH then
    last = i
  end
end
if not first or not last or last < first then
  common.out(("error: %s has no %s … %s block"):format(README, START, FINISH))
  os.exit(1)
end
local updated = vim.list_slice(readme, 1, first - 1)
vim.list_extend(updated, lines)
vim.list_extend(updated, vim.list_slice(readme, last + 1))
vim.fn.writefile(updated, README)
common.out(("README.md: %d keymaps in %d groups"):format(#rows, vim.tbl_count(grouped)))
os.exit(0)
