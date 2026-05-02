-- Definitions-only filter for cspell diagnostics on TypeScript/JavaScript.
--
-- Suppresses spell diagnostics whose token sits at an identifier USAGE site,
-- and keeps them only where a new name is being INTRODUCED (declarations,
-- parameters, class/interface/type/enum names, etc.).
--
-- Rationale: when a misspelled name is introduced at its definition, fixing
-- it there rename-propagates (LSP rename) to every usage. Surfacing the same
-- spell warning at every usage adds noise and can even trick the developer
-- into "fixing" the usage instead of the real source.
--
-- Implementation approach:
--   1. Listen to `DiagnosticChanged`.
--   2. Debounce (per-buffer) — one filter pass per 100ms, since
--      each none-ls source fires its own event.
--   3. For each diagnostic whose `source == "cspell"`, query the Treesitter
--      syntax tree at the diagnostic position:
--        - Non-identifier tokens (inside comments/strings/JSX text) → keep.
--        - Identifier whose parent is a DEFINITION node (see `definition_parent_types`) → keep.
--        - Any other identifier → drop.
--   4. If any diagnostics were dropped, re-publish the surviving set via
--      `vim.diagnostic.set`. The update triggers another `DiagnosticChanged`,
--      but the next pass is a no-op (nothing left to drop) so the loop
--      terminates naturally.
--
-- If Treesitter fails (missing parser, sync error), the filter fails OPEN
-- — i.e. keeps the diagnostic — so spell coverage is never silently lost.

local M = {}

-- Treesitter parent node types where the child identifier is a NAME being
-- defined (rather than referenced). Derived from the TS/TSX/JS grammars.
local definition_parent_types = {
  variable_declarator = true, -- const/let/var x = ...
  function_declaration = true, -- function x() {}
  function_signature = true, -- declare function x(): void
  generator_function_declaration = true,
  method_definition = true, -- class { x() {} }
  method_signature = true, -- interface { x(): void }
  abstract_method_signature = true,
  class_declaration = true, -- class X {}
  abstract_class_declaration = true,
  interface_declaration = true, -- interface X {}
  type_alias_declaration = true, -- type X = ...
  enum_declaration = true, -- enum X {}
  enum_assignment = true, -- enum { X = 1 }
  property_signature = true, -- interface { x: T }
  public_field_definition = true, -- class { x = 1 }
  required_parameter = true, -- function(x)
  optional_parameter = true, -- function(x?)
  rest_pattern = true, -- function(...x)
  shorthand_property_identifier_pattern = true, -- const { x } = ...
  module_declaration = true, -- namespace X {}
  type_parameter = true, -- function<T>()
  pair_pattern = true, -- const { a: b } = ... (b is a new name)
}

local relevant_filetypes = {
  typescript = true,
  typescriptreact = true,
  javascript = true,
  javascriptreact = true,
}

local identifier_node_types = {
  identifier = true,
  property_identifier = true,
  type_identifier = true,
  shorthand_property_identifier = true,
  shorthand_property_identifier_pattern = true,
}

-- Decide whether a cspell diagnostic in `bufnr` sits at a definition site.
local function is_definition_site(bufnr, diagnostic)
  -- `vim.diagnostic` is 0-indexed for both lnum and col.
  local row = diagnostic.lnum
  local col = diagnostic.col

  local ok, node = pcall(vim.treesitter.get_node, {
    bufnr = bufnr,
    pos = { row, col },
  })
  if not ok or not node then
    return true -- fail open: keep the diagnostic if TS can't answer
  end

  -- Not an identifier? Then we're inside a comment / string / template /
  -- JSX text / etc. The definition-vs-usage distinction doesn't apply —
  -- keep all spell warnings on prose-like tokens.
  if not identifier_node_types[node:type()] then
    return true
  end

  local parent = node:parent()
  if not parent then
    return true
  end

  return definition_parent_types[parent:type()] == true
end

-- Split a diagnostic list by source == "cspell" vs the rest.
local function partition_cspell(diagnostics)
  local cspell_diags, other_diags = {}, {}
  for _, d in ipairs(diagnostics) do
    if d.source == "cspell" then
      table.insert(cspell_diags, d)
    else
      table.insert(other_diags, d)
    end
  end
  return cspell_diags, other_diags
end

local function filter_buffer(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if not relevant_filetypes[vim.bo[bufnr].filetype] then
    return
  end

  -- cspell diagnostics live in whichever namespace none-ls uses.
  -- Iterate every namespace and filter by `source` — this is robust to
  -- none-ls version changes in namespace naming.
  for ns_id, _ in pairs(vim.diagnostic.get_namespaces()) do
    local diags = vim.diagnostic.get(bufnr, { namespace = ns_id })
    if #diags > 0 then
      local cspell_diags, other_diags = partition_cspell(diags)
      if #cspell_diags > 0 then
        local kept = vim.tbl_filter(function(d)
          return is_definition_site(bufnr, d)
        end, cspell_diags)

        -- Only re-publish if something was actually removed — otherwise
        -- we'd churn `DiagnosticChanged` events for no reason.
        if #kept ~= #cspell_diags then
          local combined = {}
          vim.list_extend(combined, kept)
          vim.list_extend(combined, other_diags)
          vim.diagnostic.set(ns_id, bufnr, combined, {})
        end
      end
    end
  end
end

local pending_timers = {}

local function schedule_filter(bufnr)
  if pending_timers[bufnr] then
    return
  end
  pending_timers[bufnr] = vim.defer_fn(function()
    pending_timers[bufnr] = nil
    filter_buffer(bufnr)
  end, 100)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("CspellDefinitionsFilter", { clear = true })
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    group = group,
    desc = "Filter cspell diagnostics to TS/JS definition sites only",
    callback = function(args)
      schedule_filter(args.buf)
    end,
  })
end

return M
