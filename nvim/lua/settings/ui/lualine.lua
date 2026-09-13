local icons = require("settings.icons")

local M = {}

M.event = "VeryLazy"

local panels = { "neo-tree", "trouble", "dbui", "dap-view", "dap-view-term", "dap-repl", "aerial" }

local function macro_recording()
  local reg = vim.fn.reg_recording()
  return reg == "" and "" or ("recording @" .. reg)
end

local lsp_message = ""
local function lsp_progress()
  return (lsp_message:gsub("%%", "%%%%"))
end

local function dap_active()
  return package.loaded["dap"] ~= nil and require("dap").session() ~= nil
end
local function dap_status()
  return icons.dap.stopped .. " " .. require("dap").status()
end

local function neotest_status()
  if not package.loaded["neotest"] then
    return ""
  end
  local ok, text = pcall(function()
    local state = require("neotest").state
    local total = { running = 0, failed = 0, passed = 0 }
    local buf = vim.api.nvim_get_current_buf()
    for _, id in ipairs(state.adapter_ids()) do
      local counts = state.status_counts(id, { buffer = buf }) or {}
      for key in pairs(total) do
        total[key] = total[key] + (counts[key] or 0)
      end
    end
    local parts = {}
    for _, key in ipairs({ "running", "failed", "passed" }) do
      if total[key] > 0 then
        parts[#parts + 1] = icons.test[key] .. " " .. total[key]
      end
    end
    return table.concat(parts, " ")
  end)
  return ok and text or ""
end

local function gitsigns_diff()
  local status = vim.b.gitsigns_status_dict
  if status then
    return { added = status.added, modified = status.changed, removed = status.removed }
  end
end

function M.opts()
  return {
    options = {
      icons_enabled = true,
      theme = require("settings.ui.theme").lualine_theme(),
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = {}, winbar = {} },
      ignore_focus = panels,
      always_divide_middle = true,
      always_show_tabline = true,
      globalstatus = true,
      refresh = {
        statusline = 1000,
        tabline = 1000,
        winbar = 1000,
        refresh_time = 16,
        events = {
          "WinEnter",
          "BufEnter",
          "BufWritePost",
          "SessionLoadPost",
          "FileChangedShellPost",
          "VimResized",
          "Filetype",
          "CursorMoved",
          "CursorMovedI",
          "ModeChanged",
        },
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = {
        "branch",
        {
          "diff",
          colored = true,
          symbols = {
            added = icons.git.added .. " ",
            modified = icons.git.modified .. " ",
            removed = icons.git.removed .. " ",
          },
          source = gitsigns_diff,
        },
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          sections = { "error", "warn", "info", "hint" },
          symbols = {
            error = icons.diagnostics.Error .. " ",
            warn = icons.diagnostics.Warn .. " ",
            info = icons.diagnostics.Info .. " ",
            hint = icons.diagnostics.Hint .. " ",
          },
          colored = true,
          update_in_insert = false,
          always_visible = false,
        },
      },
      lualine_c = {
        {
          "filename",
          file_status = true,
          newfile_status = true,
          path = 1,
          shorting_target = 40,
          symbols = {
            modified = icons.ui.dot,
            readonly = icons.ui.lock,
            unnamed = "[No Name]",
            newfile = "[New]",
          },
        },
      },
      lualine_x = {
        macro_recording,
        lsp_progress,
        { dap_status, cond = dap_active },
        neotest_status,
        "filetype",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
    inactive_sections = {
      lualine_a = {},
      lualine_b = {},
      lualine_c = { "filename" },
      lualine_x = { "location" },
      lualine_y = {},
      lualine_z = {},
    },
    tabline = {},
    winbar = {},
    inactive_winbar = {},
    extensions = { "lazy", "mason", "quickfix" },
  }
end

function M.config(_, opts)
  local lualine = require("lualine")
  lualine.setup(opts)

  local group = vim.api.nvim_create_augroup("settings_lualine", { clear = true })
  vim.api.nvim_create_autocmd("LspProgress", {
    group = group,
    desc = "Show LSP progress in the status line",
    callback = function(event)
      lsp_message = event.match == "end" and "" or vim.lsp.status()
      lualine.refresh()
    end,
  })
  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = group,
    desc = "Show macro recording in the status line",
    callback = function()
      vim.schedule(function()
        lualine.refresh()
      end)
    end,
  })
end

return M
