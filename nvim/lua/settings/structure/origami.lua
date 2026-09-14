local user = require("user.settings")

local M = {}

M.event = "VeryLazy"

M.opts = {
  useLspFoldsWithTreesitterFallback = {
    enabled = false,
    foldmethodIfNeitherIsAvailable = "indent",
  },
  pauseFoldsOnSearch = true,
  foldtext = {
    enabled = true,
    padding = {
      character = " ",
      width = 3,
      hlgroup = nil,
    },
    lineCount = {
      template = "%d lines",
      hlgroup = "Comment",
    },
    diagnosticsCount = true,
    gitsignsCount = true,
    disableOnFt = {
      "NeogitStatus",
      "NeogitCommitView",
      "NeogitCommitSelectView",
      "NeogitDiffView",
      "NeogitLogView",
      "NeogitReflogView",
      "NeogitRefsView",
      "NeogitStashView",
      "NeogitGitCommandHistory",
    },
  },
  autoFold = {
    enabled = #user.folding.auto_fold_kinds > 0,
    kinds = user.folding.auto_fold_kinds,
  },
  foldKeymaps = {
    setup = false,
    closeOnlyOnFirstColumn = false,
    scrollLeftOnCaret = false,
  },
}

return M
