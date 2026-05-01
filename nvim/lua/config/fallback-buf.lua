-- ~/.config/nvim/lua/config/fallback-buf.lua
--
-- Auto-open a fallback document buffer (e.g. TODO.md / README.md) instead of
-- leaving the user on the throwaway [No Name] buffer Neovim creates by
-- default. Triggered in three scenarios:
--
--   A. Startup with a directory argument:        nvim .
--   B. Toggling neo-tree from a fresh session:   nvim → :Neotree toggle
--   C. Deleting the last listed buffer:          <leader>bd / tab "x" icon
--
-- The candidate filenames and their order live in `config.user-settings`
-- under `editor.fallback_files`. The first file that exists in the current
-- working directory wins; if none exist, [No Name] is left alone.

local settings = require("config.user-settings")

local M = {}

-- Pick the window the fallback file should land in. Prefer the *current*
-- window when it isn't a neo-tree panel — that way a `<leader>bd` issued
-- inside the right-hand split of a `:vsplit` doesn't surprise the user by
-- dropping the file into the left split. Fall back to any other non-neo-tree
-- window in the tabpage when the current one is neo-tree (e.g. focus has
-- moved to the sidebar).
local function find_editing_window()
  local current = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current)
  if vim.bo[current_buf].filetype ~= "neo-tree" then
    return current
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if win ~= current and vim.api.nvim_win_is_valid(win) then
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].filetype ~= "neo-tree" then
        return win
      end
    end
  end
  return nil
end

-- Resolve the first fallback filename (from `settings.editor.fallback_files`)
-- that exists on disk under the current working directory. Returns the
-- absolute path on success, or nil when no candidate is readable.
local function resolve_fallback_path()
  local cwd = vim.fn.getcwd()
  for _, name in ipairs(settings.editor.fallback_files) do
    local path = cwd .. "/" .. name
    if vim.fn.filereadable(path) == 1 then
      return vim.fn.fnamemodify(path, ":p")
    end
  end
  return nil
end

function M.open_fallback_file()
  local target = resolve_fallback_path()
  if not target then return end

  local win = find_editing_window()
  if not win then return end

  -- Idempotent: if the editing window is already showing the resolved file,
  -- don't reload it (would lose cursor / undo history for a no-op).
  local current_buf = vim.api.nvim_win_get_buf(win)
  if vim.api.nvim_buf_get_name(current_buf) == target then return end

  -- nvim_win_call switches the active window for the duration of the
  -- callback, then restores it. Using it (instead of a bare `vim.cmd.edit`)
  -- means the file lands in the editing window even when focus is currently
  -- on the neo-tree sidebar — without permanently moving the cursor.
  vim.api.nvim_win_call(win, function()
    vim.cmd.edit(vim.fn.fnameescape(target))
  end)
end

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

local group = augroup("FallbackBuf", { clear = true })

-- Scenario A: `nvim <directory>`.
-- After neo-tree hijacks netrw, the editing window is left holding [No Name];
-- swap it for the configured fallback file before the user ever sees it.
autocmd("VimEnter", {
  group = group,
  desc = "Open fallback file when nvim starts with a directory argument",
  callback = function()
    if vim.fn.argc() ~= 1 then return end
    if vim.fn.isdirectory(vim.fn.argv(0)) ~= 1 then return end
    if vim.api.nvim_buf_get_name(0) ~= "" then return end
    M.open_fallback_file()
  end,
})

-- Scenario B: `:Neotree toggle` (or `:Neotree focus`) from a fresh `nvim`
-- session. Subscribe at VimEnter rather than at module-load time because
-- `config.fallback-buf` is required from `init.lua` *before* lazy.nvim
-- bootstraps the plugin runtime path — `require("neo-tree.events")` would
-- fail there. By VimEnter, lazy.nvim has finished loading non-lazy plugins.
autocmd("VimEnter", {
  group = group,
  once = true,
  desc = "Subscribe to neo-tree's window-open event for the fallback file",
  callback = function()
    local ok, events = pcall(require, "neo-tree.events")
    if not ok then return end

    -- Newer neo-tree versions expose NEO_TREE_WINDOW_AFTER_OPEN as a constant;
    -- older releases only have AFTER_OPEN. Fall through both before falling
    -- back to the literal string, which is what neo-tree dispatches under.
    local event_name = events.NEO_TREE_WINDOW_AFTER_OPEN
      or events.AFTER_OPEN
      or "neo_tree_window_after_open"

    events.subscribe({
      event = event_name,
      handler = function()
        -- Defer one tick: when the event fires the window/buffer layout is
        -- still in flux, and querying it immediately can race the sidebar's
        -- final placement. `vim.schedule` runs after the current event loop
        -- iteration, by which point everything has settled.
        vim.schedule(function()
          local win = find_editing_window()
          if not win then return end
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.api.nvim_buf_get_name(buf) == "" then
            M.open_fallback_file()
          end
        end)
      end,
    })
  end,
})

return M
