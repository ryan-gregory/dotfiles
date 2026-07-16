-- Automatic import management, VSCode-style.
--
-- Two pieces of "auto-import" behavior people expect from VSCode:
--
--   1. Adding imports when you accept a completion for an unimported symbol.
--      This is done by the LSP via `additionalTextEdits` on completion items,
--      and blink.cmp resolves + applies those on accept. No config needed
--      here; if it's not happening for a given language, it's an LSP-level
--      issue (e.g. server settings need `includeCompletionsForModuleExports`
--      enabled, like ts_ls does by default).
--
--   2. Organizing / removing unused imports on save. That's this file.
--
-- We run the LSP `source.organizeImports` code action on `BufWritePre` for a
-- configured set of filetypes. The action is requested synchronously with a
-- short timeout, then any returned workspace edits / commands are applied
-- before the buffer hits disk.
--
-- Toggle globally with `:lua vim.g.auto_organize_imports = false` (or true).

vim.g.auto_organize_imports = vim.g.auto_organize_imports ~= false

-- Filetypes whose LSPs reliably implement `source.organizeImports`.
-- Add new entries here as new servers come online.
local enabled_filetypes = {
  typescript = true,
  typescriptreact = true,
  javascript = true,
  javascriptreact = true,
  go = true,
  python = true,
  rust = true,
  cs = true,
  fsharp = true,
}

--- Run `source.organizeImports` on the current buffer, synchronously.
--- @param bufnr integer
--- @param timeout_ms integer
local function organize_imports(bufnr, timeout_ms)
  local clients = vim.lsp.get_clients { bufnr = bufnr }
  if #clients == 0 then return end

  -- Use the first client's offset encoding for range params; all attached
  -- clients on a buffer share an encoding in practice.
  local encoding = clients[1].offset_encoding or 'utf-16'

  local params = vim.lsp.util.make_range_params(0, encoding)
  ---@diagnostic disable-next-line: inject-field
  params.context = {
    only = { 'source.organizeImports' },
    diagnostics = vim.diagnostic.get(bufnr)
      and vim.tbl_map(
        function(d)
          return {
            range = {
              start = { line = d.lnum, character = d.col },
              ['end'] = { line = d.end_lnum or d.lnum, character = d.end_col or d.col },
            },
            severity = d.severity,
            message = d.message,
            source = d.source,
            code = d.code,
          }
        end,
        vim.diagnostic.get(bufnr)
      )
      or {},
  }

  local results = vim.lsp.buf_request_sync(bufnr, 'textDocument/codeAction', params, timeout_ms)
  if not results then return end

  for client_id, res in pairs(results) do
    for _, action in ipairs(res.result or {}) do
      if action.edit then
        vim.lsp.util.apply_workspace_edit(action.edit, encoding)
      elseif type(action.command) == 'table' then
        local client = vim.lsp.get_client_by_id(client_id)
        if client then client:exec_cmd(action.command, { bufnr = bufnr }) end
      end
    end
  end
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('auto-organize-imports', { clear = true }),
  callback = function(args)
    if not vim.g.auto_organize_imports then return end
    if not enabled_filetypes[vim.bo[args.buf].filetype] then return end
    organize_imports(args.buf, 1000)
  end,
})

-- Manual trigger, also surfaced under <leader>c (Code) in which-key.
vim.keymap.set('n', '<leader>co', function() organize_imports(0, 2000) end, { desc = '[C]ode [O]rganize imports' })
vim.keymap.set('n', '<leader>tI', function()
  vim.g.auto_organize_imports = not vim.g.auto_organize_imports
  vim.notify('auto-organize imports: ' .. tostring(vim.g.auto_organize_imports))
end, { desc = '[T]oggle auto-organize [I]mports' })
