local user = require("user.settings")

local M = {}

local function project_dictionary(root)
  local path = user.spelling.project_dictionary
  if type(path) ~= "string" or path == "" then
    return nil
  end
  if vim.startswith(path, "/") or vim.startswith(path, "~") then
    return vim.fs.normalize(path)
  end
  if not root then
    return nil
  end
  return vim.fs.joinpath(root, path)
end

M.config = {
  cmd = { "codebook-lsp", "serve" },
  filetypes = {
    "typescript",
    "typescriptreact",
    "javascript",
    "javascriptreact",
    "lua",
    "markdown",
    "json",
    "jsonc",
    "yaml",
    "html",
    "css",
    "sql",
    "http",
    "gitcommit",
  },
  root_markers = { ".codebook", "codebook.toml", ".codebook.toml", ".git" },
  exit_timeout = 500,
  init_options = {
    logLevel = "info",
    checkWhileTyping = true,
    diagnosticSeverity = "hint",
  },
  before_init = function(params, config)
    local path = project_dictionary(config.root_dir)
    if path then
      params.initializationOptions =
        vim.tbl_deep_extend("force", params.initializationOptions or {}, { configPath = path })
    end
  end,
}

local enabled = true

function M.toggle()
  enabled = not enabled
  vim.lsp.enable("codebook", enabled)
  vim.notify("codebook: spelling " .. (enabled and "enabled" or "disabled"))
end

local function unknown_words(bufnr, client)
  local namespace = vim.lsp.diagnostic.get_namespace(client.id)
  local seen, words = {}, {}
  for _, diagnostic in ipairs(vim.diagnostic.get(bufnr, { namespace = namespace })) do
    local ok, lines = pcall(
      vim.api.nvim_buf_get_text,
      bufnr,
      diagnostic.lnum,
      diagnostic.col,
      diagnostic.end_lnum,
      diagnostic.end_col,
      {}
    )
    local word = ok and table.concat(lines) or ""
    if word ~= "" and not seen[word] then
      seen[word] = true
      words[#words + 1] = word
    end
  end
  table.sort(words)
  return words
end

function M.add_buffer_words()
  local bufnr = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "codebook" })[1]
  if not client then
    vim.notify("codebook: not attached to this buffer", vim.log.levels.WARN)
    return
  end
  local words = unknown_words(bufnr, client)
  if #words == 0 then
    vim.notify("codebook: no unknown words in this buffer")
    return
  end
  client:exec_cmd({
    title = "Add unknown words to dictionary",
    command = "codebook.addWord",
    arguments = words,
  }, { bufnr = bufnr })
  vim.notify("codebook: added " .. #words .. " word(s) to the project dictionary")
end

function M.keymaps(_, _, map)
  map("n", "<leader>cw", M.add_buffer_words, "Add unknown words to dictionary")
end

return M
