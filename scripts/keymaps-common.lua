local M = {}

M.MODES = { "n", "x", "s", "o", "i", "t" }

M.config_dir = vim.fn.stdpath("config")
M.repo_root =
  vim.fs.dirname(vim.fs.dirname(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p")))

M.labels = {}

function M.out(line)
  io.stdout:write(line, "\n")
end

function M.key(lhs)
  return M.key_of_raw(vim.api.nvim_replace_termcodes(lhs, true, true, true))
end

function M.key_of_raw(raw)
  return (vim.fn.keytrans(raw):gsub("<NL>", "<C-J>"))
end

function M.tokens(key)
  local tokens, i = {}, 1
  while i <= #key do
    local close = key:sub(i, i) == "<" and key:find(">", i + 1, true)
    local last = close or (i + vim.str_utf_end(key, i))
    tokens[#tokens + 1] = key:sub(i, last)
    i = last + 1
  end
  return tokens
end

function M.is_prefix(short, long)
  local a = type(short) == "table" and short or M.tokens(short)
  local b = type(long) == "table" and long or M.tokens(long)
  if #a >= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

function M.is_internal(key, desc)
  return key:find("^<Plug>") ~= nil
    or key:find("^<SNR>") ~= nil
    or key == "<MouseMove>"
    or (desc or ""):find("^which%-key%-trigger") ~= nil
end

local function expand_modes(mode)
  if mode == "" or mode == " " then
    return { "n", "x", "s", "o" }
  elseif mode == "v" then
    return { "x", "s" }
  elseif mode == "!" then
    return { "i", "c" }
  end
  return { mode }
end

function M.scope_id(buf)
  return (buf == nil or buf == 0) and "global" or ("buffer " .. buf)
end

function M.label(scope)
  local buf = tonumber(scope:match("^buffer (%d+)$"))
  return buf and (M.labels[buf] or scope) or scope
end

function M.short(path)
  path = vim.fs.normalize(path)
  local prefixes = {
    { M.config_dir .. "/", "config/" },
    { vim.fn.stdpath("data") .. "/lazy/", "" },
    { vim.fs.normalize(vim.env.VIMRUNTIME) .. "/", "$VIMRUNTIME/" },
  }
  for _, p in ipairs(prefixes) do
    if path:sub(1, #p[1]) == p[1] then
      return p[2] .. path:sub(#p[1] + 1)
    end
  end
  return path
end

local LAZY_KEYS = "lazy.nvim keys"
local PASS_THROUGH = { "vim/keymap.lua", "keymaps-common.lua", "lazy/core/util.lua" }

local function caller()
  for level = 3, 40 do
    local info = debug.getinfo(level, "Sl")
    if not info then
      break
    end
    if info.source:sub(1, 1) == "@" then
      local path = info.source:sub(2)
      if path:find("lazy/core/handler/keys.lua", 1, true) then
        return LAZY_KEYS
      end
      local skip = false
      for _, pattern in ipairs(PASS_THROUGH) do
        skip = skip or path:find(pattern, 1, true) ~= nil
      end
      if not skip then
        return M.short(path) .. ":" .. info.currentline
      end
    end
  end
  return "?"
end

local lazy_owners
local function lazy_owner(mode, key)
  if not lazy_owners then
    lazy_owners = {}
    pcall(function()
      local Plugin = require("lazy.core.plugin")
      local Keys = require("lazy.core.handler.keys")
      for name, plugin in pairs(require("lazy.core.config").plugins) do
        for _, keys in pairs(Keys.resolve(Plugin.values(plugin, "keys", true))) do
          local modes = type(keys.mode) == "table" and keys.mode or { keys.mode or "n" }
          for _, spec_mode in ipairs(modes) do
            for _, m in ipairs(expand_modes(spec_mode)) do
              lazy_owners[m .. "\0" .. M.key(keys.lhs)] = name
            end
          end
        end
      end
    end)
  end
  return lazy_owners[mode .. "\0" .. key]
end

function M.pretty(source, mode, key)
  if source == LAZY_KEYS then
    local owner = lazy_owner(mode, key)
    return owner and ("keys of " .. owner) or source
  end
  return source
end

function M.start_recording()
  local state = { active = {}, redefinitions = {}, defaults = {} }
  M.recording = state
  for _, mode in ipairs(M.MODES) do
    for _, map in ipairs(vim.api.nvim_get_keymap(mode)) do
      local key = M.key_of_raw(map.lhsraw)
      state.defaults[mode .. "\0" .. key] = map
      state.active["global\0" .. mode .. "\0" .. key] =
        { source = "Neovim default", desc = map.desc, default = true }
    end
  end

  local api = vim.api
  local set, buf_set = api.nvim_set_keymap, api.nvim_buf_set_keymap
  local del, buf_del = api.nvim_del_keymap, api.nvim_buf_del_keymap

  local function record(scope, mode, lhs, opts)
    local source = caller()
    local key = M.key(lhs)
    for _, m in ipairs(expand_modes(mode)) do
      local id = scope .. "\0" .. m .. "\0" .. key
      local entry = { source = source, desc = opts and opts.desc }
      if state.active[id] then
        table.insert(state.redefinitions, {
          scope = scope,
          mode = m,
          key = key,
          first = state.active[id],
          second = entry,
        })
      end
      state.active[id] = entry
    end
  end
  local function forget(scope, mode, lhs)
    for _, m in ipairs(expand_modes(mode)) do
      state.active[scope .. "\0" .. m .. "\0" .. M.key(lhs)] = nil
    end
  end
  local function buffer_scope(buf)
    return M.scope_id(buf == 0 and api.nvim_get_current_buf() or buf)
  end

  api.nvim_set_keymap = function(mode, lhs, rhs, opts)
    set(mode, lhs, rhs, opts)
    record("global", mode, lhs, opts)
  end
  api.nvim_buf_set_keymap = function(buf, mode, lhs, rhs, opts)
    buf_set(buf, mode, lhs, rhs, opts)
    record(buffer_scope(buf), mode, lhs, opts)
  end
  api.nvim_del_keymap = function(mode, lhs)
    del(mode, lhs)
    forget("global", mode, lhs)
  end
  api.nvim_buf_del_keymap = function(buf, mode, lhs)
    buf_del(buf, mode, lhs)
    forget(buffer_scope(buf), mode, lhs)
  end
  return state
end

function M.bootstrap()
  vim.o.loadplugins = true
  dofile(M.config_dir .. "/init.lua")
  vim.cmd("filetype plugin indent on")
  vim.api.nvim_exec_autocmds("UIEnter", {})
  vim.wait(2000, function()
    return vim.g.did_very_lazy == true
  end)
  local plugins = vim.tbl_keys(require("lazy.core.config").plugins)
  table.sort(plugins)
  local ok, err = pcall(require("lazy").load, { plugins = plugins })
  if not ok then
    M.out("warning: loading plugins failed: " .. tostring(err))
  end
  vim.wait(500)
end

local SAMPLES = {
  {
    file = "service.ts",
    lines = {
      "export class UsersService {",
      "  findAll(): string[] {",
      "    return [];",
      "  }",
      "}",
    },
  },
  { file = "sample.lua", lines = { "local M = {}", "return M" }, repo_file = "nvim/init.lua" },
  { file = "query.sql", lines = { "SELECT 1;" } },
  { file = "api.http", lines = { "GET https://example.com", "" } },
  { file = "compose.yml", lines = { "services:", "  api:", "    image: node:22" } },
  { file = "Dockerfile", lines = { "FROM node:22", "WORKDIR /app" } },
}

local function expected_servers(filetype)
  local ok, lsp = pcall(require, "settings.lsp")
  local names = {}
  for _, name in ipairs(ok and lsp.servers or {}) do
    local config = vim.lsp.config[name]
    local cmd = config and type(config.cmd) == "table" and config.cmd[1]
    if
      config
      and vim.tbl_contains(config.filetypes or {}, filetype)
      and cmd
      and vim.fn.executable(cmd) == 1
    then
      names[#names + 1] = name
    end
  end
  return names
end

function M.open_samples(timeout_ms)
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  local opened = {}
  for _, sample in ipairs(SAMPLES) do
    local path = dir .. "/" .. sample.file
    local repo_path = sample.repo_file and (M.repo_root .. "/" .. sample.repo_file)
    local in_repo = repo_path
      and vim.uv.fs_stat(repo_path) ~= nil
      and vim.uv.fs_stat(M.repo_root .. "/.git") ~= nil
    if in_repo then
      path = repo_path
    else
      vim.fn.writefile(sample.lines, path)
    end
    vim.cmd.edit(vim.fn.fnameescape(path))
    local buf = vim.api.nvim_get_current_buf()
    local filetype = vim.bo[buf].filetype
    M.labels[buf] = filetype
    local servers = expected_servers(filetype)
    vim.wait(timeout_ms, function()
      for _, name in ipairs(servers) do
        if #vim.lsp.get_clients({ bufnr = buf, name = name }) == 0 then
          return false
        end
      end
      return true
    end, 200)
    vim.wait(2500, function()
      return not in_repo or vim.b[buf].gitsigns_head ~= nil
    end, 200)
    vim.api.nvim_exec_autocmds("InsertEnter", { buffer = buf })
    vim.wait(1000)
    local attached = vim.tbl_map(function(client)
      return client.name
    end, vim.lsp.get_clients({ bufnr = buf }))
    table.sort(attached)
    opened[#opened + 1] =
      { buf = buf, filetype = filetype, file = sample.file, servers = servers, attached = attached }
  end
  return opened
end

function M.collect(buf)
  local scope = M.scope_id(buf)
  local maps = {}
  for _, mode in ipairs(M.MODES) do
    local list = buf and vim.api.nvim_buf_get_keymap(buf, mode) or vim.api.nvim_get_keymap(mode)
    for _, raw in ipairs(list) do
      local key = M.key_of_raw(raw.lhsraw)
      local recorded = M.recording and M.recording.active[scope .. "\0" .. mode .. "\0" .. key]
      local source = recorded and M.pretty(recorded.source, mode, key)
      if not source and raw.sid and raw.sid > 0 then
        local info = vim.fn.getscriptinfo({ sid = raw.sid })[1]
        source = info and (M.short(info.name) .. ":" .. (raw.lnum or 0))
      end
      local original = M.recording and M.recording.defaults[mode .. "\0" .. key]
      maps[#maps + 1] = {
        mode = mode,
        key = key,
        tokens = M.tokens(key),
        desc = raw.desc or "",
        scope = scope,
        buffer = buf,
        default = scope == "global"
          and original ~= nil
          and original.rhs == raw.rhs
          and original.callback == raw.callback,
        source = source or "?",
      }
    end
  end
  return maps
end

return M
