if vim.g.lsp_actiononsave ~= nil then
  return
end
vim.g.lsp_actiononsave = true

local M = {}
local l = {}

function l.format_sync(bufnr, client)
  if not client:supports_method("textDocument/formatting", bufnr) then
    return
  end
  if l.verbose then
    print("[lsp-actiononsave] (" .. client.name .. ") Formatting…")
  end

  vim.lsp.buf.format({
    async = false,
    bufnr = bufnr,
    id = client.id,
  })
end

function l.execute_code_action_sync(bufnr, client, action_name)
  if l.verbose then
    print("[lsp-actiononsave] (" .. client.name .. ") Executing \"codeAction/" .. action_name .. "\"…")
  end
  local params = vim.lsp.util.make_range_params()
  params.context = { only = { action_name }, diagnostics = {} }
  local timeout_ms = 1000
  local res = client.request_sync("textDocument/codeAction", params, timeout_ms, bufnr)
  for _, result in pairs(res and res.result or {}) do
    if result.edit then
      vim.lsp.util.apply_workspace_edit(result.edit, client.offset_encoding or "utf-16")
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

function M.setup(opts)
  if opts == nil then
    opts = {}
  end
  if opts.servers == nil then
    opts.servers = {}
  end

  if opts.verbose then
    l.verbose = true
  end

  vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(ev)
      local bufnr = ev.buf
      for _, client in pairs(vim.lsp.get_clients({ bufnr = bufnr })) do
        local actions = opts.servers[client.name] or {}
        for _, action in pairs(actions) do
          l.process_action(action, bufnr, client)
        end
      end
    end,
  })
end

return M
