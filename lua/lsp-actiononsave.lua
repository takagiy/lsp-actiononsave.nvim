if vim.g.lsp_actiononsave ~= nil then
  return
end
vim.g.lsp_actiononsave = true

local M = {}
local l = {}

function l.format_sync(bufnr, client)
  if l.verbose then
    vim.notify("[lsp-actiononsave] (" .. client.name .. ") Formatting…")
  end

  vim.lsp.buf.format({
    async = false,
    bufnr = bufnr,
    id = client.id,
  })
end

function l.execute_code_action_sync(bufnr, client, action_name)
  if l.verbose then
    vim.notify("[lsp-actiononsave] (" .. client.name .. ') Executing "codeAction/' .. action_name .. '"…')
  end
  local params = vim.lsp.util.make_range_params()
  params.context = { only = { action_name }, diagnostics = {} }
  local timeout_ms = 1000
  local res = client.request_sync("textDocument/codeAction", params, timeout_ms, bufnr)
  for _, result in pairs(res and res.result or {}) do
    if result.edit then
      vim.lsp.util.apply_workspace_edit(result.edit, client.offset_encoding or "utf-16")
    end
    if result.command then
      client.exec_cmd(result.command, { bufnr = bufnr })
    end
  end
end

function l.process_action(action, bufnr, client)
  if action == "format" then
    l.format_sync(bufnr, client)
  end
  if string.match(action, "^codeAction/") then
    local action_name = string.gsub(action, "^codeAction/", "")
    l.execute_code_action_sync(bufnr, client, action_name)
  end
end

function l.for_each_server_options(server_options, bufnr, callback)
  local active_clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in pairs(active_clients) do
    local actions = server_options[client.name] or {}
    if type(actions) == "function" then
      local ft = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
      actions = actions(ft)
    end

    callback(actions, client)
  end
end

function l.create_filter(server_options, bufnr)
  local skip = {}

  l.for_each_server_options(server_options, bufnr, function(actions)
    if type(actions.skip) == "string" then
      skip[actions.skip] = true
    elseif type(actions.skip) == "table" then
      for _, name in pairs(actions.skip) do
        skip[name] = true
      end
    end
  end)

  return skip
end

function l.process_actions_by_clients(server_options, bufnr, skip)
  l.for_each_server_options(server_options, bufnr, function(actions, client)
    if skip[client.name] then
      return
    end

    for key, action in pairs(actions) do
      if key ~= "skip" then
        l.process_action(action, bufnr, client)
      end
    end
  end)
end

function M.setup(opts)
  opts = vim.tbl_extend("force", {
    verbose = false,
    servers = {},
  }, opts or {})

  if opts.verbose then
    l.verbose = true
  end

  vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(ev)
      local bufnr = ev.buf
      local skip = l.create_filter(opts.servers, bufnr)
      l.process_actions_by_clients(opts.servers, bufnr, skip)
    end,
  })
end

return M
