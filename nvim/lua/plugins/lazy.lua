-- lazy.nvim manages itself. Pinned to the latest stable release, matching the
-- `--branch=stable` clone in core/bootstrap.lua; its options live there too.
--
-- This spec also keeps `{ import = "plugins" }` valid: lazy.nvim reports
-- "No specs found for module plugins" when the directory has no modules.
return require("settings").spec("folke/lazy.nvim", nil, { version = "*" })
