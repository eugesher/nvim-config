vim.filetype.add({
  extension = {
    http = "http",
    rest = "http",
  },
  filename = {
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
    ["docker-bake.hcl"] = "hcl.dockerbake",
    ["docker-bake.override.hcl"] = "hcl.dockerbake",
    [".env"] = "env",
  },
  pattern = {
    ["docker%-compose%..+%.ya?ml"] = "yaml.docker-compose",
    ["compose%..+%.ya?ml"] = "yaml.docker-compose",
    ["docker%-bake%..+%.hcl"] = "hcl.dockerbake",
    ["%.env%..+"] = "env",
    [".*%.env%.json"] = { "json", { priority = 10 } },
  },
})
