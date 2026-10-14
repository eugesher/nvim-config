local M = {}

local filetypes = {
  javascript = true,
  javascriptreact = true,
  typescript = true,
  typescriptreact = true,
}

local clauses = {
  "^%s*import%s+[^'\"]-%S%s+$",
  "^%s*export%s+[^'\"]*[%*}][^'\"]-%s+$",
}

local KEYWORD = "from"

function M.expects_from(context)
  if not filetypes[vim.bo[context.bufnr].filetype] then
    return false
  end
  local before = context.line:sub(1, context.bounds.start_col - 1)
  if before:find("%f[%w]" .. KEYWORD .. "%f[%W]") then
    return false
  end
  for _, clause in ipairs(clauses) do
    if before:match(clause) then
      return true
    end
  end
  return false
end

function M.without_from(context, items)
  if not M.expects_from(context) then
    return items
  end
  return vim.tbl_filter(function(item)
    return item.label ~= KEYWORD or item.kind ~= vim.lsp.protocol.CompletionItemKind.Keyword
  end, items)
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:enabled()
  return filetypes[vim.bo.filetype] == true
end

function M:get_completions(context, callback)
  local items = {}
  if M.expects_from(context) then
    items[1] = {
      label = KEYWORD,
      kind = vim.lsp.protocol.CompletionItemKind.Keyword,
      insertText = KEYWORD,
    }
  end
  callback({ items = items, is_incomplete_forward = false, is_incomplete_backward = false })
  return function() end
end

return M
