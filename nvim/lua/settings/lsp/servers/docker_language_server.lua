-- defaults verified against docker-language-server v0.20.1 and nvim-lspconfig v2.11.0-84-gac9d2f7c (2026-09-12)
--
-- Docker's own language server: Dockerfile, Compose and Bake in one process —
-- BuildKit lint, Docker Scout image advice, Compose completion, navigation,
-- inlay hints and rename of service / network / volume references.
--
-- It is not alone on those files, because it does less than its feature list
-- suggests (all measured against v0.20.1):
--   * Dockerfile: no completion and no hover of its own → dockerls covers them
--     (settings/lsp/servers/dockerls.lua);
--   * Compose: diagnostics are YAML syntax errors only, no schema validation →
--     yamlls with the SchemaStore Compose Specification covers that.
-- `docker_compose_language_service` stays out: archived upstream.

local M = {}

M.config = {
  cmd = { "docker-language-server", "start", "--stdio" },
  -- The two compound filetypes come from core/filetypes.lua; without them
  -- compose and bake files would be plain `yaml` / `hcl` and this server would
  -- either miss them or, worse, read every .hcl file in the project as a
  -- Dockerfile.
  filetypes = { "dockerfile", "yaml.docker-compose", "hcl.dockerbake" },
  -- The language id decides which of the three parsers the server uses, and
  -- nvim-lspconfig only maps the compose one. Sending `hcl` for a Bake file
  -- makes the server parse it as a Dockerfile: "unknown instruction: group"
  -- (verified against v0.20.1).
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
  init_options = {
    telemetry = "off", -- "all" | "error" | "off"; the server's default is "all"
    dockercomposeExperimental = { composeSupport = true },
    -- Insurance against a second Dockerfile server: it drops this server's own
    -- issues where another one already reported. With only this server running
    -- it changes nothing — both values give the same diagnostics (measured).
    dockerfileExperimental = { removeOverlappingIssues = true },
  },
}

return M
