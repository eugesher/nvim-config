local function bootstrap(t, lock)
  local config = vim.fn.stdpath("config")
  if lock then
    t.write(vim.fs.joinpath(config, "lazy-lock.json"), vim.json.encode(lock))
  end
  local calls = {}
  t.stub(vim.fn, "system", function(cmd)
    calls[#calls + 1] = cmd
    if cmd[2] == "clone" then
      vim.fn.mkdir(cmd[#cmd], "p")
    end
    return ""
  end)
  local setup
  package.loaded.lazy = {
    setup = function(spec)
      setup = spec
    end,
  }
  local rtp = vim.o.runtimepath
  dofile(vim.fs.joinpath(vim.env.TEST_REPO, "nvim/lua/core/bootstrap.lua"))
  vim.o.runtimepath = rtp
  return calls, setup
end

local function install(t, version, setup)
  local home = t.path("home")
  local bin = t.path("bin")
  t.write(vim.fs.joinpath(bin, "nvim"), ("#!/bin/sh\necho 'NVIM v%s'\n"):format(version), "755")
  vim.fn.mkdir(home, "p")
  if setup then
    setup(home)
  end
  local result = vim
    .system({ "bash", vim.fs.joinpath(vim.env.TEST_REPO, "install.sh") }, {
      text = true,
      clear_env = true,
      env = { HOME = home, PATH = bin .. ":/usr/bin:/bin", LANG = "C.UTF-8" },
    })
    :wait(30000)
  return result, home
end

local function mode(path)
  return ("%o"):format(bit.band(vim.uv.fs_stat(path).mode, tonumber("777", 8)))
end

return {
  {
    "RULE-069 a missing lazy.nvim is cloned from stable, then checked out at the lock",
    function(t)
      local calls, setup = bootstrap(t, { ["lazy.nvim"] = { branch = "main", commit = "abc123" } })
      local lazypath = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
      t.eq(calls, {
        {
          "git",
          "clone",
          "--filter=blob:none",
          "--branch=stable",
          "https://github.com/folke/lazy.nvim.git",
          lazypath,
        },
        { "git", "-C", lazypath, "checkout", "--quiet", "abc123" },
      })
      t.eq(setup.lockfile, vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json"))
    end,
  },
  {
    "RULE-069 an installed lazy.nvim is left alone",
    function(t)
      vim.fn.mkdir(vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim"), "p")
      local calls = bootstrap(t, { ["lazy.nvim"] = { commit = "abc123" } })
      t.eq(calls, {})
    end,
  },
  {
    "RULE-069 without a lock entry lazy.nvim stays on stable",
    function(t)
      local calls = bootstrap(t, { ["other.nvim"] = { commit = "x" } })
      t.eq(#calls, 1)
      t.eq(calls[1][2], "clone")
    end,
  },
  {
    "RULE-069 plugins install when missing and never update on their own",
    function(t)
      vim.fn.mkdir(vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim"), "p")
      local _, setup = bootstrap(t)
      t.eq(setup.install.missing, true)
      t.eq(setup.checker.enabled, false)
      t.eq(setup.change_detection.enabled, false)
      t.eq(setup.rocks.enabled, false)
      t.eq(setup.root, vim.fs.joinpath(vim.fn.stdpath("data"), "lazy"))
    end,
  },
  {
    "RULE-070 install backs up the old config, then copies nvim/",
    function(t)
      local result, home = install(t, "0.12.6", function(home)
        t.write(vim.fs.joinpath(home, ".config/nvim/init.lua"), "old")
      end)
      t.eq(result.code, 0, result.stderr)
      local dest = vim.fs.joinpath(home, ".config/nvim")
      t.eq(t.read(vim.fs.joinpath(dest, "init.lua")), t.read(vim.env.TEST_REPO .. "/nvim/init.lua"))
      local backups = vim.fn.glob(dest .. ".backup.*", false, true)
      t.eq(#backups, 1)
      t.eq(t.read(vim.fs.joinpath(backups[1], "init.lua")), "old")
    end,
  },
  {
    "RULE-070 install copies owner-only and never copies http/",
    function(t)
      local result, home = install(t, "0.12.6")
      t.eq(result.code, 0, result.stderr)
      local dest = vim.fs.joinpath(home, ".config/nvim")
      t.eq(mode(dest), "700")
      t.eq(mode(vim.fs.joinpath(dest, "init.lua")), "600")
      t.eq(vim.uv.fs_stat(vim.fs.joinpath(home, ".config/http")), nil)
      t.eq(vim.uv.fs_stat(vim.fs.joinpath(dest, "http")), nil)
    end,
  },
  {
    "RULE-070 the codebook dictionary is created once and then kept",
    function(t)
      local result, home = install(t, "0.12.6")
      t.eq(result.code, 0, result.stderr)
      local dictionary = vim.fs.joinpath(home, ".config/codebook/codebook.toml")
      t.ok(t.read(dictionary):find("dictionaries", 1, true))
      t.write(dictionary, "mine")
      result = install(t, "0.12.6")
      t.eq(result.code, 0, result.stderr)
      t.eq(t.read(dictionary), "mine")
      t.ok(result.stdout:find("Kept existing codebook dictionary", 1, true), result.stdout)
    end,
  },
  {
    "RULE-070 Neovim older than 0.12 stops the install before any change",
    function(t)
      local result, home = install(t, "0.11.4", function(home)
        t.write(vim.fs.joinpath(home, ".config/nvim/init.lua"), "old")
      end)
      t.eq(result.code, 1)
      t.ok(result.stderr:find("needs Neovim 0.12+", 1, true), result.stderr)
      t.eq(t.read(vim.fs.joinpath(home, ".config/nvim/init.lua")), "old")
      t.eq(vim.fn.glob(vim.fs.joinpath(home, ".config/nvim.backup.*")), "")
    end,
  },
  {
    "RULE-070 an unreadable Neovim version stops the install",
    function(t)
      local result, home = install(t, "x")
      t.eq(result.code, 1)
      t.ok(result.stderr:find("could not read the Neovim version", 1, true), result.stderr)
      t.eq(vim.uv.fs_stat(vim.fs.joinpath(home, ".config/nvim")), nil)
    end,
  },
  {
    "RULE-070 Neovim 0.13 and 1.0 pass the version check",
    function(t)
      for _, version in ipairs({ "0.13.0", "1.0.0" }) do
        local result = install(t, version)
        t.eq(result.code, 0, version .. ": " .. result.stderr)
      end
    end,
  },
}
