local M = {}

local function cache_path(name)
  return vim.fs.joinpath(vim.fn.stdpath("state"), "myconfig", name .. ".json")
end

local function cached(name, key, pin)
  local file = io.open(cache_path(name), "r")
  if not file then
    return false
  end
  local ok, data = pcall(vim.json.decode, file:read("*a") or "")
  file:close()
  return ok and type(data) == "table" and data.key == key and data.sha256 == pin
end

local function remember(name, key, pin)
  local path = cache_path(name)
  vim.fn.mkdir(vim.fs.dirname(path), "p", tonumber("700", 8))
  local fd = vim.uv.fs_open(path, "w", tonumber("600", 8))
  if fd then
    vim.uv.fs_write(fd, vim.json.encode({ key = key, sha256 = pin }))
    vim.uv.fs_close(fd)
  end
end

function M.matches(path, pin, name)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return false
  end
  local key =
    table.concat({ stat.ino, stat.size, stat.mtime.sec, stat.mtime.nsec, stat.ctime.sec }, ":")
  if cached(name, key, pin) then
    return true
  end
  local ok, job = pcall(vim.system, { "sha256sum", "--", path }, { text = true })
  local result = ok and job:wait(10000) or nil
  if result and result.code == 0 and result.stdout:match("^%x+") == pin then
    remember(name, key, pin)
    return true
  end
  return false
end

return M
