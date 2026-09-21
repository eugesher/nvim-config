local M = {}

M.config = {
  cmd = { "docker-langserver", "--stdio" },
  filetypes = { "dockerfile" },
  root_markers = { "Dockerfile" },
  settings = {
    docker = {
      languageserver = {
        diagnostics = {
          deprecatedMaintainer = "warning",
          directiveCasing = "warning",
          emptyContinuationLine = "warning",
          instructionCasing = "warning",
          instructionCmdMultiple = "warning",
          instructionEntrypointMultiple = "warning",
          instructionHealthcheckMultiple = "warning",
          instructionJSONInSingleQuotes = "warning",
        },
        formatter = {
          ignoreMultilineInstructions = true,
        },
      },
    },
  },
}

return M
