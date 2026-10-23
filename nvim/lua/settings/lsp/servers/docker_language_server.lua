local M = {}

M.config = {
  cmd = { "docker-language-server", "start", "--stdio" },
  filetypes = { "dockerfile", "yaml.docker-compose", "hcl.dockerbake" },
  get_language_id = function(_, filetype)
    if filetype == "hcl.dockerbake" then
      return "dockerbake"
    elseif filetype == "yaml.docker-compose" or filetype:lower():find("ya?ml") then
      return "dockercompose"
    end
    return filetype
  end,
  root_markers = {
    "Dockerfile",
    "docker-compose.yaml",
    "docker-compose.yml",
    "compose.yaml",
    "compose.yml",
    "docker-bake.json",
    "docker-bake.hcl",
    "docker-bake.override.json",
    "docker-bake.override.hcl",
  },
  cmd_env = {
    DOCKER_LANGUAGE_SERVER_TELEMETRY = "false",
    HTTPS_PROXY = "http://127.0.0.1:9",
    HTTP_PROXY = "http://127.0.0.1:9",
    https_proxy = "http://127.0.0.1:9",
    http_proxy = "http://127.0.0.1:9",
    NO_PROXY = "",
    no_proxy = "",
  },
  init_options = {
    telemetry = "off",
    dockercomposeExperimental = { composeSupport = true },
    dockerfileExperimental = { removeOverlappingIssues = true },
  },
}

return M
