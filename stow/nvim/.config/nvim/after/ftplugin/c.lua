local function start_termdebug()
  vim.cmd.packadd 'termdebug'

  local default_path = vim.fn.getcwd() .. '/'
  local executable = vim.fn.input('Path to executable: ', default_path, 'file')
  if executable == '' then
    vim.notify('Termdebug launch cancelled.', vim.log.levels.INFO)
    return
  end

  vim.cmd('Termdebug ' .. vim.fn.fnameescape(executable))
end

vim.api.nvim_buf_create_user_command(0, 'CDebug', start_termdebug, {
  desc = 'Debug a C executable with built-in termdebug',
})

vim.keymap.set('n', '<leader>dd', start_termdebug, {
  buffer = true,
  desc = '[D]ebug executable with term[d]ebug',
})
