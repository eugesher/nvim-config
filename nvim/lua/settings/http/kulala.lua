local pin = require("core.pin")
local trust = require("core.trust")
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

local function private_dirs()
  local data = vim.env.XDG_DATA_HOME or vim.fs.normalize("~/.local/share")
  for _, dir in ipairs({ vim.fn.stdpath("cache") .. "/kulala", data .. "/kulala-core" }) do
    vim.fn.mkdir(dir, "p", tonumber("700", 8))
    vim.uv.fs_chmod(dir, tonumber("700", 8))
  end
end

local function core_path()
  local sha256 = user.http.kulala_core_sha256
  if not sha256 then
    return nil
  end
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "kulala.nvim", "bin", "kulala-core")
  if pin.matches(path, sha256, "kulala-core") then
    return path
  end
  if vim.v.exiting == vim.NIL then
    vim.notify(
      ("kulala-core is missing or does not match http.kulala_core_sha256, requests fail: %s"):format(
        path
      ),
      vim.log.levels.ERROR
    )
  end
  local refuse = vim.fn.exepath("false")
  return refuse ~= "" and refuse or "/bin/false"
end

local opts = {
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
    ["text/html"] = { ft = "html", formatter = nil, pathresolver = nil },
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

local function allowed()
  local file = vim.api.nvim_buf_get_name(0)
  local dir = vim.uv.fs_realpath(file:find("^/") and vim.fs.dirname(file) or vim.fn.getcwd())
  if not dir then
    return false
  end
  local files = {}
  for name, type in vim.fs.dir(dir) do
    if
      (type == "file" or type == "link")
      and (name:match("%.http$") or name:match("%.rest$") or name == "http-client.env.json")
    then
      files[#files + 1] = vim.fs.joinpath(dir, name)
    end
  end
  return trust.approve(
    "kulala:" .. dir,
    files,
    "HTTP requests in " .. dir,
    "may run the pre- and post-request scripts its .http files hold."
  )
end

function M.config(_, options)
  local ui = require("kulala.ui")
  for _, method in ipairs({ "open", "open_all", "replay" }) do
    local run = ui[method]
    ui[method] = function(...)
      if allowed() then
        return run(...)
      end
      vim.notify(
        "kulala: not run, this directory is not trusted (:ProjectTrust)",
        vim.log.levels.WARN
      )
    end
  end
  require("kulala").setup(options)
end

function M.opts()
  private_dirs()
  opts.kulala_core.path = core_path()
  return opts
end

return M
