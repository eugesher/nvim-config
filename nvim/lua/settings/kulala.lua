-- defaults verified against kulala.nvim v6.29.0 (2026-09-12)
--
-- REST client for .http collections: environments, chained requests, response
-- views. The collections live in http/ at the repository root, outside nvim/,
-- which install.sh replaces wholesale.
--
-- kulala 6.x runs every request through the external kulala-core binary and
-- downloads it from GitHub releases into stdpath("data")/kulala.nvim/bin on the
-- first request (README). The curl options of 5.x (additional_curl_options,
-- certificates, request_timeout) are gone: per-request `# @curl-<flag>`
-- metadata and `kulala_core.timeout` replace them.
--
-- Keymaps of .http buffers live in after/ftplugin/http.lua; this file holds
-- only the keys of the result window.

local user = require("user.settings")

local M = {}

M.ft = { "http", "rest" }

local function ui(method)
  return function()
    require("kulala.ui")[method]()
  end
end

-- Result window keys, buffer-local to it. The plugin's defaults, except window
-- navigation: <C-h> / <C-l> are ours (core/keymaps.lua) and the response tabs
-- are reachable with ] and [ anyway.
local RESULT_KEYMAPS = {
  ["Show body"] = { "B", ui("show_body") },
  ["Show headers"] = { "H", ui("show_headers") },
  ["Show headers and body"] = { "A", ui("show_headers_body") },
  ["Show verbose"] = { "V", ui("show_verbose") },
  ["Show script output"] = { "O", ui("show_script_output") },
  ["Show stats"] = { "S", ui("show_stats") },
  ["Show report"] = { "R", ui("show_report") },
  ["Show filter"] = { "F", ui("toggle_filter") },
  ["Next response"] = { "]", ui("show_next"), prefix = false },
  ["Previous response"] = { "[", ui("show_previous"), prefix = false },
  ["Jump to response"] = { "<CR>", ui("keymap_enter"), mode = { "n", "v" }, prefix = false },
  ["Clear responses history"] = { "X", ui("clear_responses_history") },
  -- <C-c> keeps its classic meaning here: interrupt the running request.
  ["Interrupt requests"] = { "<C-c>", ui("interrupt_requests"), prefix = false },
  ["Show help"] = { "?", ui("show_help"), prefix = false },
  ["Show news"] = { "g?", ui("show_news"), prefix = false },
  ["Toggle split/float"] = { "|", ui("toggle_display_mode"), prefix = false },
  ["Close"] = { "q", ui("close_kulala_buffer"), prefix = false },
  ["Send WS message"] = {
    "<S-CR>",
    function()
      require("kulala.ui.ws_input").on_send_keymap()
    end,
    mode = { "n", "v", "i" },
    prefix = false,
  },
  -- Window navigation stays ours.
  ["Previous tab"] = false,
  ["Next tab"] = false,
}

-- Response bodies are formatted by external tools; kulala-core itself only
-- pretty-prints JSON (`response_format`). Each one is optional, hence the
-- executable checks from the plugin's documentation.
local function formatter(cmd)
  return vim.fn.executable(cmd[1]) == 1 and cmd or nil
end

M.opts = {
  -- The engine. `path` points at a binary of your own; nil downloads one.
  kulala_core = {
    path = nil,
    timeout = 60000, -- ms, 0 disables the timeout
    data_dir = nil, -- cookies, OAuth and prompts; nil = ~/.local/share/kulala-core
    download_url = "https://github.com/mistweaverco/kulala-core/releases/download/%s/%s",
    download_tool = "curl",
  },

  -- Restores request history with a session; needs `sessionoptions+=globals`.
  session = { restore = true },

  -- kulala fetches its own kulala_http grammar and builds it with the
  -- tree-sitter CLI (README). Without the parser there is no highlighting in
  -- .http buffers and its LSP (completion of headers, variables) stays off.
  treesitter = { enable = true, cli_path = "tree-sitter" },

  -- Environments come from http/http-client.env.json, searched upwards from
  -- the buffer's directory; secrets from http-client.private.env.json next to it.
  default_env = user.http.default_env,
  environment_scope = "b", -- request variables stay in the buffer
  vscode_rest_client_environmentvars = false,

  response_format = { indent = 2, expand_tabs = true, sort_keys = false },
  urlencode = "always",
  halt_on_error = true, -- a failed request stops the rest of the run

  contenttypes = {
    ["application/json"] = { ft = "json", formatter = formatter({ "jq", "." }) },
    -- `pathresolver` feeds only the Lua resolution of request variables
    -- ({{name.response.body.…}}), and kulala 6.x never calls it: requests are
    -- executed by kulala-core, which resolves variables itself. Kept as the
    -- plugin's documented default; chaining goes through a post-request script
    -- instead (http/example.http, README).
    ["application/xml"] = {
      ft = "xml",
      formatter = formatter({ "xmllint", "--format", "-" }),
      pathresolver = formatter({ "xmllint", "--xpath", "{{path}}", "-" }),
    },
    ["text/xml"] = "application/xml",
    ["text/html"] = {
      ft = "html",
      formatter = formatter({ "prettier", "--stdin-filepath", "file.html" }),
      pathresolver = nil,
    },
    ["application/graphql-response+json"] = "application/json",
  },

  ui = {
    display_mode = "split", -- or "float"
    split_direction = "vertical", -- alias of "right"
    win_opts = { bo = {}, wo = {} },
    default_view = "body",
    winbar = true,
    default_winbar_panes = { "body", "headers", "headers_body", "script_output", "stats" },
    winbar_labels_keymaps = true,
    show_variable_info_text = false, -- "float" shows a variable's value on hover
    show_icons = "on_request", -- request status as virtual text
    show_request_summary = true,
    show_images = true, -- inline images, where the terminal supports it
    max_response_size = 32768, -- bytes; larger responses are not shown
    max_request_size = 2048, -- bytes; "Copy as curl" inlines bodies up to this
    report = {
      show_script_output = true,
      show_asserts_output = true,
      show_summary = true,
    },
  },

  -- kulala's own LSP: completion, hover and code actions in .http buffers.
  -- The script filetypes only attach in *.http.js / *.http.ts / *.http.lua
  -- files, so ordinary TypeScript buffers are left alone.
  lsp = {
    enable = true,
    filetypes = { "http", "rest", "javascript", "typescript", "lua" },
    enforce_external_script_naming_convention = true,
    keymaps = false, -- Neovim's native LSP keymaps are enough
    on_attach = nil,
  },

  debug = 3, -- log level: 0 silent, 1 error, 2 +warn, 3 +info, 4 debug
  generate_bug_report = false,
  script_console_notify = true, -- console.log from scripts through vim.notify

  -- No global keymaps: the <leader>h group is buffer-local to .http buffers
  -- (after/ftplugin/http.lua), so it stays empty everywhere else.
  global_keymaps = false,
  global_keymaps_prefix = "",
  kulala_keymaps = RESULT_KEYMAPS,
  kulala_keymaps_prefix = "",

  openapi_panel_keymaps = true, -- <Tab>, e, f, Y, R, <CR>, q in the explorer
  openapi_panel = {
    split = "right",
    signs = { folded = ">", expanded = "v" },
  },
}

return M
