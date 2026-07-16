-- TypeScript / React quality-of-life plugins.
-- LSP servers, formatters, and treesitter parsers for the TS stack are
-- configured in `init.lua`. This file only adds plugins that aren't covered
-- by those subsystems.

---@module 'lazy'
---@type LazySpec
return {
  {
    -- Auto-close and auto-rename JSX/TSX/HTML tags.
    'windwp/nvim-ts-autotag',
    event = { 'BufReadPre', 'BufNewFile' },
    ft = {
      'html',
      'javascript',
      'javascriptreact',
      'typescript',
      'typescriptreact',
      'xml',
      'markdown',
    },
    opts = {},
  },

  {
    -- Translate cryptic TypeScript compiler errors into plain English in
    -- diagnostics. Read the docs for `:TSToolsRenameFile` style commands.
    'dmmulroy/ts-error-translator.nvim',
    ft = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    opts = {},
  },
}
