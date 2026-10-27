for _, key in ipairs({ "path", "cpath" }) do
  package[key] = table.concat(
    vim.tbl_filter(function(entry)
      return entry:sub(1, 1) == "/"
    end, vim.split(package[key], ";", { plain = true })),
    ";"
  )
end

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify(
    ("This config requires Neovim 0.12+, found %s. Plugins were not loaded."):format(
      tostring(vim.version())
    ),
    vim.log.levels.ERROR
  )
  return
end

vim.loader.enable()

require("core")

require("core.bootstrap")
