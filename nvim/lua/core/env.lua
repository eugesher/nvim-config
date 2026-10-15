local count = tonumber(vim.env.GIT_CONFIG_COUNT) or 0

for i = 0, count - 1 do
  if
    vim.env["GIT_CONFIG_KEY_" .. i] == "core.fsmonitor"
    and vim.env["GIT_CONFIG_VALUE_" .. i] == "false"
  then
    return
  end
end

vim.env["GIT_CONFIG_KEY_" .. count] = "core.fsmonitor"
vim.env["GIT_CONFIG_VALUE_" .. count] = "false"
vim.env.GIT_CONFIG_COUNT = tostring(count + 1)
