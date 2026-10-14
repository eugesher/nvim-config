local M = {}

function M.attached_buffer(client, path)
  for bufnr in pairs(client.attached_buffers) do
    if vim.api.nvim_buf_get_name(bufnr) == path then
      return bufnr
    end
  end
end

function M.open(job, uri, filetype, lines)
  job.client:notify("textDocument/didOpen", {
    textDocument = {
      uri = uri,
      languageId = job.client.get_language_id(0, filetype),
      version = 0,
      text = table.concat(lines, "\n") .. "\n",
    },
  })
  job.opened[uri] = true
end

function M.close(job, uri)
  if job.opened[uri] then
    job.opened[uri] = nil
    job.client:notify("textDocument/didClose", { textDocument = { uri = uri } })
  end
end

function M.request(job, method, params, bufnr, handler)
  local ok, id
  ok, id = job.client:request(method, params, function(err, result)
    job.pending[id] = nil
    if not job.cancelled then
      handler(err, result)
    end
  end, bufnr)
  if not ok then
    job.failed = true
    return false
  end
  job.pending[id] = true
  return true
end

local function new_job(client)
  return { client = client, pending = {}, opened = {} }
end

local function files_in(root, filetypes, ignored, callback)
  vim.system({ "rg", "--files", "--no-require-git" }, { cwd = root, text = true }, function(out)
    vim.schedule(function()
      local files = {}
      for name in vim.gsplit(out.stdout or "", "\n", { trimempty = true }) do
        local path = vim.fs.joinpath(root, name)
        local filetype = vim.filetype.match({ filename = path })
        if filetype and filetypes[filetype] and not ignored(path) then
          files[#files + 1] = { path = path, filetype = filetype }
        end
      end
      table.sort(files, function(a, b)
        return a.path < b.path
      end)
      callback(files, out.code ~= 0 and (out.stderr or "") or nil)
    end)
  end)
end

function M.new(spec)
  local ignored = spec.ignored or function()
    return false
  end
  local parallel = spec.parallel or 1
  local project = { results = nil, totals = {}, filetypes = {}, root = nil, qf_id = nil }
  local scanner = {}

  local function totals()
    local counts = {}
    for path, items in pairs(project.results or {}) do
      if #items > 0 then
        counts[path] = #items
        for parent in vim.fs.parents(path) do
          counts[parent] = (counts[parent] or 0) + #items
          if parent == project.root then
            break
          end
        end
      end
    end
    project.totals = counts
  end

  local function items()
    local paths = vim.tbl_keys(project.results or {})
    table.sort(paths)
    local list = {}
    for _, path in ipairs(paths) do
      vim.list_extend(list, project.results[path])
    end
    return list
  end

  local function redraw_explorer()
    if package.loaded["neo-tree"] then
      require("neo-tree.sources.manager").redraw("filesystem")
    end
  end

  local function publish(open)
    totals()
    local list = items()
    local what = { title = spec.title, items = list }
    if project.qf_id and vim.fn.getqflist({ id = project.qf_id }).id == project.qf_id then
      what.id = project.qf_id
      vim.fn.setqflist({}, "r", what)
    elseif open then
      vim.fn.setqflist({}, " ", what)
      project.qf_id = vim.fn.getqflist({ id = 0 }).id
    end
    redraw_explorer()
    if open and #list > 0 then
      local typing = vim.api.nvim_get_mode().mode:match("^[icrR]") ~= nil
      require("trouble").open({ mode = "qflist", focus = not typing })
    end
  end

  local function progress(job, status, message)
    job.message.status = status
    job.message.percent = math.floor(job.done * 100 / math.max(#job.files, 1))
    job.message.id = vim.api.nvim_echo({ { message } }, status ~= "running", job.message)
  end

  local function stop(job, message)
    job.cancelled = true
    for id in pairs(job.pending) do
      job.client:cancel_request(id)
    end
    for uri in pairs(job.opened) do
      M.close(job, uri)
    end
    project.job = nil
    progress(job, "failed", message)
  end

  function scanner.cancel()
    if project.job then
      stop(project.job, "Cancelled")
    end
  end

  local function finish(job, root, filetypes)
    project.job = nil
    project.root, project.filetypes, project.results = root, filetypes, job.results
    publish(true)
    local found, paths = 0, 0
    for _, list in pairs(job.results) do
      found = found + #list
      paths = paths + (#list > 0 and 1 or 0)
    end
    progress(job, "success", spec.summary(found, paths))
  end

  function scanner.scan()
    if project.job then
      scanner.cancel()
      return
    end
    local client = spec.client(vim.api.nvim_get_current_buf())
    if not client then
      vim.notify(spec.no_client, vim.log.levels.WARN)
      return
    end
    local root = vim.fs.normalize(client.root_dir or vim.fn.getcwd())
    local filetypes = {}
    for _, filetype in ipairs(client.config.filetypes or { vim.bo.filetype }) do
      filetypes[filetype] = true
    end
    local job = new_job(client)
    job.files, job.done, job.started, job.running, job.results = {}, 0, 0, 0, {}
    job.message = { kind = "progress", title = spec.title, source = spec.source }
    project.job = job
    progress(job, "running", "Listing files")
    files_in(root, filetypes, ignored, function(files, err)
      if project.job ~= job then
        return
      end
      if err then
        project.job = nil
        progress(job, "failed", "rg: " .. vim.trim(err))
        return
      end
      job.files = files
      local step
      step = function()
        if project.job ~= job then
          return
        end
        if job.failed then
          stop(job, "The language server stopped")
          return
        end
        if job.done == #files then
          finish(job, root, filetypes)
          return
        end
        while job.running < parallel and job.started < #files do
          job.started = job.started + 1
          job.running = job.running + 1
          local file = files[job.started]
          progress(job, "running", vim.fs.relpath(root, file.path) or file.path)
          spec.scan_file(job, file, function(list)
            if project.job ~= job then
              return
            end
            job.results[file.path] = list
            job.done = job.done + 1
            job.running = job.running - 1
            vim.schedule(step)
          end)
          if project.job ~= job or job.failed then
            break
          end
        end
      end
      step()
    end)
  end

  function scanner.clear()
    scanner.cancel()
    project.results, project.totals, project.root = nil, {}, nil
    if project.qf_id and vim.fn.getqflist({ id = project.qf_id }).id == project.qf_id then
      vim.fn.setqflist({}, "r", { id = project.qf_id, items = {} })
    end
    redraw_explorer()
  end

  function scanner.count(path)
    return project.totals[path]
  end

  function scanner.rescan(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if
      not project.results
      or project.job
      or not vim.startswith(path, project.root .. "/")
      or not project.filetypes[vim.bo[bufnr].filetype]
      or ignored(path)
    then
      return
    end
    local client = spec.client(bufnr)
    if not client then
      return
    end
    local job = new_job(client)
    project.rescans = project.rescans or {}
    project.rescans[path] = job
    spec.scan_file(job, { path = path, filetype = vim.bo[bufnr].filetype }, function(list)
      if project.rescans[path] ~= job or not project.results then
        return
      end
      project.rescans[path] = nil
      project.results[path] = list
      publish(false)
    end)
  end

  return scanner
end

return M
