local user = require("user.settings")

local M = {}

M.ft = { "http", "rest" }

local function ui(method)
  return function()
    require("kulala.ui")[method]()
  end
end

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
  ["Previous tab"] = false,
  ["Next tab"] = false,
}

local function formatter(cmd)
  return vim.fn.executable(cmd[1]) == 1 and cmd or nil
end

M.opts = {
  kulala_core = {
    path = nil,
    timeout = 60000,
    data_dir = nil,
    download_url = "https://github.com/mistweaverco/kulala-core/releases/download/%s/%s",
    download_tool = "curl",
  },

  session = { restore = true },

  treesitter = { enable = true, cli_path = "tree-sitter" },

  default_env = user.http.default_env,
  environment_scope = "b",
  vscode_rest_client_environmentvars = false,

  response_format = { indent = 2, expand_tabs = true, sort_keys = false },
  urlencode = "always",
  halt_on_error = true,

  contenttypes = {
    ["application/json"] = { ft = "json", formatter = formatter({ "jq", "." }) },
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
    display_mode = "split",
    split_direction = "vertical",
    win_opts = { bo = {}, wo = {} },
    default_view = "body",
    winbar = true,
    default_winbar_panes = { "body", "headers", "headers_body", "script_output", "stats" },
    winbar_labels_keymaps = true,
    show_variable_info_text = false,
    show_icons = "on_request",
    show_request_summary = true,
    show_images = true,
    max_response_size = 32768,
    max_request_size = 2048,
    report = {
      show_script_output = true,
      show_asserts_output = true,
      show_summary = true,
    },
  },

  lsp = {
    enable = true,
    filetypes = { "http", "rest", "javascript", "typescript", "lua" },
    enforce_external_script_naming_convention = true,
    keymaps = false,
    on_attach = nil,
  },

  debug = 3,
  generate_bug_report = false,
  script_console_notify = true,

  global_keymaps = false,
  global_keymaps_prefix = "",
  kulala_keymaps = RESULT_KEYMAPS,
  kulala_keymaps_prefix = "",

  openapi_panel_keymaps = true,
  openapi_panel = {
    split = "right",
    signs = { folded = ">", expanded = "v" },
  },
}

return M
