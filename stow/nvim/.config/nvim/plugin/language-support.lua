local mit_scheme_candidates = {
  'mit-scheme',
  'scheme',
  '/usr/local/bin/mit-scheme',
  '/usr/local/bin/scheme',
}

local function find_mit_scheme()
  for _, candidate in ipairs(mit_scheme_candidates) do
    if vim.fn.executable(candidate) == 1 then return candidate end
  end

  return nil
end

local function open_scheme_terminal(command)
  local runtime = find_mit_scheme()
  if not runtime then
    vim.notify('MIT/GNU Scheme is not available in PATH yet. Finish installing it into /usr/local to enable Scheme REPL and run commands.', vim.log.levels.WARN)
    return
  end

  vim.cmd 'belowright split'
  vim.cmd('terminal ' .. command(runtime))
end

vim.filetype.add {
  extension = {
    scm = 'scheme',
    sls = 'scheme',
  },
}

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'scheme',
  callback = function(event)
    local map = function(lhs, rhs, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = event.buf, desc = desc })
    end

    vim.api.nvim_buf_create_user_command(event.buf, 'SchemeRepl', function()
      open_scheme_terminal(function(runtime) return vim.fn.shellescape(runtime) end)
    end, { desc = 'Open a MIT/GNU Scheme REPL in a terminal split' })

    vim.api.nvim_buf_create_user_command(event.buf, 'SchemeRunCurrentFile', function()
      local file = vim.api.nvim_buf_get_name(event.buf)
      if file == '' then
        vim.notify('Save the current buffer before running it with MIT/GNU Scheme.', vim.log.levels.ERROR)
        return
      end

      open_scheme_terminal(function(runtime)
        return string.format('%s --load %s', vim.fn.shellescape(runtime), vim.fn.shellescape(file))
      end)
    end, { desc = 'Run the current Scheme file with MIT/GNU Scheme' })

    map('<leader>rr', '<cmd>SchemeRepl<CR>', 'Open Scheme [R]EPL')
    map('<leader>rf', '<cmd>SchemeRunCurrentFile<CR>', '[R]un current Scheme [F]ile')
  end,
})
