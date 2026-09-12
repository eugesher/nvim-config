-- defaults verified against Neovim v0.12.5 (2026-09-11)
--
-- The only LspAttach autocmd of the config. Every LSP keymap is created here,
-- buffer-local, and only for methods the attached server supports: a key that
-- silently does nothing is worse than no key. LspDetach undoes all of it once
-- the last client has left the buffer, so no LSP keymap outlives its server.
--
-- Neovim's own LSP maps stay as they are: K, gra, grr, gri, grt, gO and <C-s>
-- in insert mode. Ours are added on top as aliases. The one exception is `grn`,
-- which is pointed at inc-rename below — same rename, with a live preview.
--
-- Server-specific keymaps live next to their server: a `keymaps(client, buf, map)`
-- function in settings/lsp/servers/<name>.lua is called from here for that client.
-- Every keymap remembers which clients registered it and disappears when the
-- last of them detaches (e.g. vtsls' keys go with vtsls, eslint may stay).
-- gd / gri / grt open fzf-lua pickers (settings/fzf.lua); a single result jumps
-- straight to it. Neovim's own functions serve as the fallback. References are
-- the exception — they go to trouble (task 20), see `grr` below.

local user = require("user.settings")

local M = {}

-- owners[buf]["<mode> <lhs>"] = set of client ids that registered the keymap.
---@type table<integer, table<string, table<integer, true>>>
local owners = {}

local function map(buf, client_id, modes, lhs, rhs, desc, opts)
  opts = vim.tbl_extend("force", { buffer = buf, desc = desc }, opts or {})
  vim.keymap.set(modes, lhs, rhs, opts)
  owners[buf] = owners[buf] or {}
  for _, mode in ipairs(type(modes) == "table" and modes or { modes }) do
    local key = mode .. " " .. lhs
    owners[buf][key] = owners[buf][key] or {}
    owners[buf][key][client_id] = true
  end
end

-- An fzf-lua LSP picker, or Neovim's own function when fzf-lua is unavailable.
local function picker(name, fallback)
  return function()
    local ok, fzf = pcall(require, "fzf-lua")
    if ok then
      fzf[name]()
    else
      fallback()
    end
  end
end

local function highlight_group(buf)
  return "settings_lsp_highlight_" .. buf
end

local function on_attach(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end
  local buf = event.buf
  local function supports(method)
    return client:supports_method(method, buf)
  end
  local function bmap(mode, lhs, rhs, desc, opts)
    map(buf, client.id, mode, lhs, rhs, desc, opts)
  end

  if supports("textDocument/definition") then
    bmap("n", "gd", picker("lsp_definitions", vim.lsp.buf.definition), "Go to definition")
  end
  if supports("textDocument/references") then
    -- Trouble instead of the picker (task 20): a symbol with dozens of uses is
    -- easier to walk through in a list that stays open and previews every hit.
    -- Decided deliberately — gd / gri / grt keep their fzf-lua pickers.
    bmap("n", "grr", "<cmd>Trouble lsp_references toggle focus=true<cr>", "References (Trouble)")
  end
  if supports("textDocument/implementation") then
    bmap("n", "gri", picker("lsp_implementations", vim.lsp.buf.implementation), "Implementations")
  end
  if supports("textDocument/typeDefinition") then
    bmap("n", "grt", picker("lsp_typedefs", vim.lsp.buf.type_definition), "Type definition")
  end
  if supports("textDocument/declaration") then
    bmap("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  end
  if supports("textDocument/codeAction") then
    bmap({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
  end
  if supports("textDocument/rename") then
    -- Renaming goes through inc-rename: the same LSP rename, but every
    -- occurrence in the project updates live while the new name is typed
    -- (settings/inc-rename.lua). `grn` keeps Neovim's own meaning and only gains
    -- the preview; `<leader>cr` is its alias in the code namespace and
    -- `<leader>rn` the one in the refactor namespace — a deliberate duplicate
    -- (task 24), not an oversight to be cleaned up.
    local function rename()
      return ":IncRename " .. vim.fn.expand("<cword>")
    end
    bmap("n", "grn", rename, "Rename symbol (live preview)", { expr = true })
    bmap("n", "<leader>cr", rename, "Rename symbol (live preview)", { expr = true })
  end
  bmap("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
  bmap("n", "<leader>cD", vim.diagnostic.setloclist, "Buffer diagnostics to loclist")
  if supports("textDocument/codeLens") then
    -- 0.12: code lenses refresh themselves once enabled (`codelens.refresh()` is deprecated).
    vim.lsp.codelens.enable(true, { bufnr = buf })
    bmap("n", "<leader>cl", vim.lsp.codelens.run, "Run code lens")
    bmap("n", "<leader>cL", function()
      vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle code lenses")
  end
  bmap("n", "<leader>cR", "<cmd>lsp restart<CR>", "Restart LSP")
  if supports("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(user.lsp.inlay_hints, { bufnr = buf })
    bmap("n", "<leader>ui", function()
      vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = buf }), { bufnr = buf })
    end, "Toggle inlay hints")
  end
  if supports("textDocument/documentColor") then
    vim.lsp.document_color.enable(true, { bufnr = buf })
  end
  if supports("textDocument/documentHighlight") then
    -- Highlight other occurrences of the symbol under the cursor after 'updatetime'.
    local group = vim.api.nvim_create_augroup(highlight_group(buf), { clear = true })
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      group = group,
      buffer = buf,
      desc = "Highlight references of the symbol under the cursor",
      callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
      group = group,
      buffer = buf,
      desc = "Clear reference highlights",
      callback = vim.lsp.buf.clear_references,
    })
  end

  -- Server-specific keymaps (settings/lsp/servers/<name>.lua, field `keymaps`).
  local ok, server = pcall(require, "settings.lsp.servers." .. client.name)
  if ok and type(server) == "table" and type(server.keymaps) == "function" then
    server.keymaps(client, buf, bmap)
  end
end

local function on_detach(event)
  local buf = event.buf
  if not vim.api.nvim_buf_is_valid(buf) then
    owners[buf] = nil
    return
  end
  -- The detaching client is still listed during LspDetach.
  local others = vim.tbl_filter(function(c)
    return c.id ~= event.data.client_id
  end, vim.lsp.get_clients({ bufnr = buf }))

  local highlight_left = vim.iter(others):any(function(c)
    return c:supports_method("textDocument/documentHighlight", buf)
  end)
  if not highlight_left then
    pcall(vim.api.nvim_del_augroup_by_name, highlight_group(buf))
    vim.lsp.util.buf_clear_references(buf)
  end

  -- Keymaps no remaining client registered go away with the detaching one.
  for key, clients in pairs(owners[buf] or {}) do
    clients[event.data.client_id] = nil
    if next(clients) == nil then
      local mode, lhs = key:match("^(%S+) (.+)$")
      pcall(vim.keymap.del, mode, lhs, { buffer = buf })
      owners[buf][key] = nil
    end
  end

  if #others == 0 then
    vim.lsp.inlay_hint.enable(false, { bufnr = buf })
    owners[buf] = nil
  end
end

function M.setup()
  -- Capabilities can arrive long after a client has attached: the Neovim help
  -- (`:help LspAttach`) suggests exactly this wrapper for it, and
  -- docker-language-server needs it — it registers `textDocument/rename` some
  -- three seconds in, when the keymap pass below has long finished, so
  -- `<leader>cr` would never appear in a compose buffer (task 22). Repeating the
  -- pass is safe: every keymap it creates overwrites its own earlier version.
  vim.lsp.handlers["client/registerCapability"] = (function(overridden)
    return function(err, res, ctx)
      local result = overridden(err, res, ctx)
      local client = vim.lsp.get_client_by_id(ctx.client_id)
      if not client then
        return result
      end
      for buf in pairs(client.attached_buffers) do
        if vim.api.nvim_buf_is_valid(buf) then
          on_attach({ buf = buf, data = { client_id = client.id } })
        end
      end
      return result
    end
  end)(vim.lsp.handlers["client/registerCapability"])

  local group = vim.api.nvim_create_augroup("settings_lsp_attach", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    desc = "LSP keymaps and buffer features",
    callback = on_attach,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    group = group,
    desc = "Undo LspAttach once the last client leaves the buffer",
    callback = on_detach,
  })
end

return M
