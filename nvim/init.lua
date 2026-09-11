-- Entry point. The order below matters — see comments.

-- 1. Leaders first: any mapping created before this line would bind to the
--    old leader, and plugin specs read it at import time.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- 2. Version guard. The config relies on 0.12 APIs (winborder, vim.hl,
--    diagnostic on_jump, …); bail out before loading anything else.
if vim.fn.has("nvim-0.12") == 0 then
  vim.notify(
    ("This config requires Neovim 0.12+, found %s. Plugins were not loaded."):format(
      tostring(vim.version())
    ),
    vim.log.levels.ERROR
  )
  return
end

-- 3. Lua bytecode cache.
vim.loader.enable()

-- 4. Editor settings that do not depend on plugins.
require("core")

-- 5. Plugin manager.
require("core.bootstrap")
