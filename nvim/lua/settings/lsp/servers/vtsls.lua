local user = require("user.settings")

local M = {}

local root_markers = { "tsconfig.json", "package.json", "jsconfig.json" }

local function language(extra)
  return vim.tbl_deep_extend("force", {
    updateImportsOnFileMove = { enabled = "always" },
    suggest = { completeFunctionCalls = true },
    preferences = { importModuleSpecifier = user.lsp.import_style },
    inlayHints = {
      parameterNames = { enabled = "literals", suppressWhenArgumentMatchesName = true },
      parameterTypes = { enabled = true },
      variableTypes = { enabled = false, suppressWhenTypeMatchesName = true },
      propertyDeclarationTypes = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
    },
  }, extra or {})
end

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

local function code_action(kind, apply)
  return function()
    vim.lsp.buf.code_action({ context = { only = { kind }, diagnostics = {} }, apply = apply })
  end
end

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
  filetypes = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
  root_dir = function(bufnr, on_dir)
    on_dir(vim.fs.root(bufnr, ".git") or vim.fs.root(bufnr, root_markers) or vim.fn.getcwd())
  end,
  commands = {
    ["_typescript.moveToFileRefactoring"] = move_to_file,
  },
  settings = {
    vtsls = {
      autoUseWorkspaceTsdk = true,
      enableMoveToFileCodeAction = true,
      experimental = {
        completion = { enableServerSideFuzzyMatch = true },
        maxInlayHintLength = 30,
      },
    },
    typescript = language({
      preferences = { includePackageJsonAutoImports = "auto" },
      tsserver = {
        maxTsServerMemory = 8192,
        experimental = { enableProjectDiagnostics = true },
      },
      inlayHints = { enumMemberValues = { enabled = true } },
    }),
    javascript = language(),
  },
}

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
