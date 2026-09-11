-- Filetype detection additions. Patterns are Lua patterns, anchored by
-- `vim.filetype.add` itself; without a `/` they match the file name only.

vim.filetype.add({
  extension = {
    http = "http", -- kulala request collections
    rest = "http",
  },
  filename = {
    -- `yaml.docker-compose` is what docker-language-server and yamlls expect.
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
    [".env"] = "env",
  },
  pattern = {
    -- Override files: docker-compose.dev.yml, compose.override.yaml, …
    ["docker%-compose%..+%.ya?ml"] = "yaml.docker-compose",
    ["compose%..+%.ya?ml"] = "yaml.docker-compose",
    -- .env.local, .env.production, .env.example, …
    ["%.env%..+"] = "env",
    -- kulala environment files (http-client.env.json, .env.json). Higher
    -- priority, otherwise `.env.json` would be caught by the pattern above.
    [".*%.env%.json"] = { "json", { priority = 10 } },
  },
})
