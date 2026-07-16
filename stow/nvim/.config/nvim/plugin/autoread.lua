-- Reload buffers when the underlying file changes on disk (e.g. after a
-- `git checkout` from lazygit, the terminal, or another editor).
--
-- Neovim only re-reads the file if `autoread` is set AND something triggers a
-- check. `:checktime` is the explicit trigger; we run it on focus / buffer
-- enter / idle so disk changes are picked up promptly.
--
-- See `:help 'autoread'`, `:help :checktime`, `:help FileChangedShellPost`.

vim.o.autoread = true

vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = vim.api.nvim_create_augroup('user-autoread-checktime', { clear = true }),
  desc = 'Check for external file changes (autoread trigger)',
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.bo.buftype == '' then vim.cmd 'checktime' end
  end,
})

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = vim.api.nvim_create_augroup('user-autoread-notify', { clear = true }),
  desc = 'Notify when a buffer is reloaded due to external changes',
  callback = function() vim.notify('File changed on disk; buffer reloaded.', vim.log.levels.INFO) end,
})
