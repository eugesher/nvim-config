-- defaults verified against lualine.nvim 221ce6b (2026-09-11)
--
-- Status line: a single global bar (`laststatus = 3`, core/options.lua).
-- Components for plugins that arrive in later tasks (gitsigns, nvim-dap,
-- neotest) check `package.loaded` / `pcall` first and stay empty until then.
-- `winbar` stays empty on purpose: dropbar owns it (task 26).

local icons = require("settings.icons")

local M = {}

M.event = "VeryLazy"

-- Side panels. With a global status line, focusing one keeps the bar on the
-- last code window instead of blanking or describing the panel.
local panels = { "neo-tree", "trouble", "dbui", "dap-view", "dap-view-term", "dap-repl", "aerial" }

-- Components ------------------------------------------------------------------

local function macro_recording()
  local reg = vim.fn.reg_recording()
  return reg == "" and "" or ("recording @" .. reg)
end

-- Latest LSP progress text. Filled by the LspProgress autocmd in `config`:
-- `vim.lsp.status()` consumes the messages, so it is read once per event.
local lsp_message = ""
local function lsp_progress()
  return lsp_message
end

-- nvim-dap (task 16): only while a debug session exists.
local function dap_active()
  return package.loaded["dap"] ~= nil and require("dap").session() ~= nil
end
local function dap_status()
  return icons.dap.stopped .. " " .. require("dap").status()
end

-- neotest (task 18): running / failed / passed counts for the current buffer.
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

-- Diff counts from gitsigns (task 12); empty until gitsigns is installed.
local function gitsigns_diff()
  local status = vim.b.gitsigns_status_dict
  if status then
    return { added = status.added, modified = status.changed, removed = status.removed }
  end
end

-- Options ---------------------------------------------------------------------

-- A function: the theme needs catppuccin, which is loaded by the time lualine is.
function M.opts()
  return {
    options = {
      icons_enabled = true,
      -- Catppuccin theme with the `b`/`c` sections on the base black (settings/theme.lua).
      theme = require("settings.theme").lualine_theme(),
      component_separators = { left = "│", right = "│" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { statusline = {}, winbar = {} },
      ignore_focus = panels,
      always_divide_middle = true,
      always_show_tabline = true,
      globalstatus = true, -- required with 'laststatus' = 3, or the bar doubles up
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
          path = 1, -- relative to the working directory
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
      -- The autocmd pattern is the progress kind: begin / report / end.
      lsp_message = event.match == "end" and "" or vim.lsp.status()
      lualine.refresh()
    end,
  })
  vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
    group = group,
    desc = "Show macro recording in the status line",
    callback = function()
      -- During RecordingLeave the register is still reported: refresh after it.
      vim.schedule(function()
        lualine.refresh()
      end)
    end,
  })
end

return M
