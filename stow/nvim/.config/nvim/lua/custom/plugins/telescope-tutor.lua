---@module 'lazy'
---@type LazySpec
return {
  {
    dir = vim.fn.stdpath('config') .. '/telescope-tutor',
    name = 'telescope-tutor',
    dependencies = { 'nvim-telescope/telescope.nvim' },
    config = function()
      require('telescope-tutor').setup()
    end,
    keys = {
      { '<leader>tt', '<cmd>TelescopeTutor<cr>', desc = '[T]elescope [T]utor' },
    },
  },
}
