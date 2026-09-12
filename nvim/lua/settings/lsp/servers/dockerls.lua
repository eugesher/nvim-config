-- defaults verified against dockerfile-language-server 0.15.0 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-12)
--
-- The other half of the Dockerfile experience. docker-language-server (task 22)
-- only lints through BuildKit and shows Docker Scout data on hover; it answers
-- `textDocument/completion` and `textDocument/hover` for Dockerfiles with
-- nothing at all (measured against v0.20.1). This server supplies exactly that:
-- instruction completion, hover documentation, signature help and formatting.
--
-- The pair does not double up on diagnostics: docker-language-server drops its
-- own issues where this one already reported (`removeOverlappingIssues`), which
-- takes the duplicated "unknown instruction" error out of the list.

local M = {}

M.config = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
  settings = {
    docker = {
      languageserver = {
        -- The server documents the keys and their allowed values
        -- ("ignore" | "warning" | "error") but not its own defaults, so every
        -- check is stated here instead of being guessed at.
        diagnostics = {
          deprecatedMaintainer = "warning", -- MAINTAINER, replaced by LABEL
          directiveCasing = "warning", -- `# SYNTAX=` instead of `# syntax=`
          emptyContinuationLine = "warning",
          instructionCasing = "warning", -- `run` instead of `RUN`
          instructionCmdMultiple = "warning", -- only the last CMD survives
          instructionEntrypointMultiple = "warning",
          instructionHealthcheckMultiple = "warning",
          instructionJSONInSingleQuotes = "warning", -- CMD ['a'] is not JSON
        },
        formatter = {
          -- Leave `RUN foo \` chains alone: their indentation is written by
          -- hand and the formatter would collapse it.
          ignoreMultilineInstructions = true,
        },
      },
    },
  },
}

return M
