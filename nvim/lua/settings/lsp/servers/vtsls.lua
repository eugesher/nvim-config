-- defaults verified against vtsls 0.3.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-11)
--
-- TypeScript / JavaScript through vtsls: a wrapper around VSCode's TypeScript
-- extension. Gives what ts_ls lacks — Move to File, import fixes on file
-- rename, organize / remove unused / add missing imports, go to source
-- definition, the full set of inlay hints. Never enable ts_ls next to it.

local M = {}

-- Project root, nearest marker first. nvim-lspconfig ships a `root_dir`
-- (lock files / .git), and `root_dir` always wins over `root_markers` — so the
-- root is resolved here, with these markers.
local root_markers = { "tsconfig.json", "package.json", "jsconfig.json", ".git" }

-- Settings shared by the typescript.* and javascript.* branches.
local function language(extra)
  return vim.tbl_deep_extend("force", {
    updateImportsOnFileMove = { enabled = "always" }, -- fix imports on file rename / move
    suggest = { completeFunctionCalls = true },
    preferences = { importModuleSpecifier = "non-relative" }, -- tsconfig `paths` (NestJS)
    inlayHints = {
      parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
      parameterTypes = { enabled = true },
      variableTypes = { enabled = false, suppressWhenTypeMatchesName = true },
      propertyDeclarationTypes = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
    },
  }, extra or {})
end

--- Runs a vtsls command (workspace/executeCommand) on the current buffer's vtsls client.
---@param command string
---@param arguments any[]
---@param handler? lsp.Handler
local function vtsls_exec(command, arguments, handler)
  local client = vim.lsp.get_clients({ bufnr = 0, name = "vtsls" })[1]
  if not client then
    vim.notify("vtsls is not attached to this buffer", vim.log.levels.WARN)
    return
  end
  client:request(
    "workspace/executeCommand",
    { command = command, arguments = arguments },
    handler,
    0
  )
end

-- Applies the code action of one kind, without a menu when there is only one.
local function code_action(kind, apply)
  return function()
    vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = apply })
  end
end

-- "Move to file" is a two-step dance: the server offers the action with this
-- client-side command; the client asks for the target and sends it back.
local function move_to_file(command, ctx)
  local action, uri, range = unpack(command.arguments)
  local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
  local fname = vim.uri_to_fname(uri)
  local function move(target)
    client:request("workspace/executeCommand", {
      command = command.command,
      arguments = { action, uri, range, target },
    }, nil, ctx.bufnr)
  end
  -- Suggested targets straight from tsserver.
  client:request("workspace/executeCommand", {
    command = "typescript.tsserverRequest",
    arguments = {
      "getMoveToRefactoringFileSuggestions",
      {
        file = fname,
        startLine = range.start.line + 1,
        startOffset = range.start.character + 1,
        endLine = range["end"].line + 1,
        endOffset = range["end"].character + 1,
      },
    },
  }, function(_, result)
    local new_file = "New file…"
    local choices = vim.list_extend({ new_file }, vim.tbl_get(result or {}, "body", "files") or {})
    vim.ui.select(choices, {
      prompt = "Move to file",
      format_item = function(item)
        return item == new_file and item or vim.fn.fnamemodify(item, ":~:.")
      end,
    }, function(choice)
      if choice == new_file then
        vim.ui.input({
          prompt = "Move to: ",
          default = vim.fn.fnamemodify(fname, ":h") .. "/",
          completion = "file",
        }, function(path)
          if path and path ~= "" then
            move(vim.fn.fnamemodify(path, ":p"))
          end
        end)
      elseif choice then
        move(choice)
      end
    end)
  end, ctx.bufnr)
end

M.config = {
  cmd = { "vtsls", "--stdio" },
  -- .mts / .cts are `typescript` in Neovim, .mjs / .cjs `javascript`.
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, root_markers) or vim.fn.getcwd())
  end,
  commands = {
    ["_typescript.moveToFileRefactoring"] = move_to_file,
  },
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true, -- the project's own TypeScript, when installed
      enableMoveToFileCodeAction = true, -- needs the client command above
      experimental = {
        completion = { enableServerSideFuzzyMatch = true },
        maxInlayHintLength = 30,
      },
    },
    -- tsserver-wide settings exist only under typescript.* (they cover JS too).
    typescript = language({
      preferences = { includePackageJsonAutoImports = "auto" }, -- "on" stalls tsserver in monorepos
      tsserver = {
        maxTsServerMemory = 8192,
        experimental = { enableProjectDiagnostics = true },
      },
      inlayHints = { enumMemberValues = { enabled = true } },
    }),
    javascript = language(),
  },
}

-- vtsls-only keymaps, created from the LspAttach in settings/lsp/keymaps.lua.
function M.keymaps(client, _, map)
  local function lang()
    return vim.bo.filetype:find("javascript") and "javascript" or "typescript"
  end
  map("n", "<leader>co", function()
    vtsls_exec("typescript.organizeImports", { vim.api.nvim_buf_get_name(0) })
  end, "Organize imports")
  map("n", "<leader>cu", function()
    vtsls_exec(lang() .. ".removeUnusedImports", { vim.api.nvim_buf_get_name(0) })
  end, "Remove unused imports")
  map("n", "<leader>cm", code_action("source.addMissingImports.ts", true), "Add missing imports")
  map({ "n", "x" }, "<leader>cM", code_action("refactor.move.file", true), "Move to file")
  map("n", "<leader>cs", code_action("source", false), "Source actions")
  map("n", "gs", function()
    local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
    vtsls_exec(
      "typescript.goToSourceDefinition",
      { params.textDocument.uri, params.position },
      function(err, result)
        if err or not result or vim.tbl_isempty(result) then
          vim.notify("No source definition found", vim.log.levels.INFO)
        elseif #result == 1 then
          vim.lsp.util.show_document(result[1], client.offset_encoding, { focus = true })
        else
          vim.fn.setqflist({}, " ", {
            title = "Source definitions",
            items = vim.lsp.util.locations_to_items(result, client.offset_encoding),
          })
          vim.cmd.copen()
        end
      end
    )
  end, "Go to source definition")
end

return M
