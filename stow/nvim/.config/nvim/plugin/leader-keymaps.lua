-- Leader keymaps for discoverability.
--
-- Everything here is a "global" (not buffer-local, not LSP-only) leader mapping.
-- Buffer-local LSP mirrors live next to the existing `gr*` LSP keymaps in
-- `init.lua` under the LspAttach autocmd. Git-hunk mappings live in
-- `lua/kickstart/plugins/gitsigns.lua` under `<leader>h*`.
--
-- Goal: pressing <space> in normal mode should surface a useful menu via
-- which-key.nvim (`delay = 0` in init.lua). Add new leader mappings here
-- rather than scattering them across init.lua.

local map = function(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
end

-- File ops --------------------------------------------------------------------
map('n', '<leader>w', '<cmd>write<CR>', 'Save file ([W]rite)')
map('n', '<leader>W', '<cmd>wall<CR>', 'Save all ([W]rite all)')
map('n', '<leader>Q', '<cmd>qall<CR>', '[Q]uit all')
map('n', '<leader>x', '<cmd>bdelete<CR>', 'Close buffer')
map('n', '<leader>X', '<cmd>bdelete!<CR>', 'Force close buffer')

-- File explorer (neo-tree) ----------------------------------------------------
map('n', '<leader>e', '<cmd>Neotree toggle<CR>', 'File [E]xplorer toggle')
map('n', '<leader>o', '<cmd>Neotree reveal<CR>', 'Reveal current file ([O]pen in tree)')

-- Buffer group (<leader>b*) ---------------------------------------------------
map('n', '<leader>bn', '<cmd>bnext<CR>', '[B]uffer [N]ext')
map('n', '<leader>bp', '<cmd>bprevious<CR>', '[B]uffer [P]revious')
map('n', '<leader>bd', '<cmd>bdelete<CR>', '[B]uffer [D]elete')
map('n', '<leader>bo', '<cmd>%bdelete|edit#|bdelete#<CR>', '[B]uffer [O]nly (close others)')
map('n', '<leader>bl', function() require('telescope.builtin').buffers() end, '[B]uffer [L]ist')

-- Diagnostics: jump with Neovim's built-in `]d` / `[d`. Loclist via <leader>q.
-- (No <leader>d* group here — that prefix is owned by easy-dotnet.nvim.)

-- Clipboard (<leader>y / <leader>p) ------------------------------------------
map({ 'n', 'v' }, '<leader>y', '"+y', '[Y]ank to system clipboard')
map('n', '<leader>Y', '"+Y', '[Y]ank line to system clipboard')
map({ 'n', 'v' }, '<leader>p', '"+p', '[P]aste from system clipboard')
map({ 'n', 'v' }, '<leader>P', '"+P', '[P]aste before from system clipboard')

-- Git group (<leader>g*) ------------------------------------------------------
-- Per-hunk operations are under <leader>h* (gitsigns). These are repo-wide
-- pickers via telescope, plus quick blame/diff aliases.
map('n', '<leader>gs', function() require('telescope.builtin').git_status() end, '[G]it [S]tatus')
map('n', '<leader>gc', function() require('telescope.builtin').git_commits() end, '[G]it [C]ommits')
map('n', '<leader>gC', function() require('telescope.builtin').git_bcommits() end, '[G]it buffer [C]ommits')
map('n', '<leader>gb', function() require('telescope.builtin').git_branches() end, '[G]it [B]ranches')
map('n', '<leader>gB', function() require('gitsigns').blame_line { full = true } end, '[G]it [B]lame line (full)')
map('n', '<leader>gd', function() require('gitsigns').diffthis() end, '[G]it [D]iff against index')

-- Window group (<leader>W* collides with wall; use <leader>-/| for splits) ----
map('n', '<leader>-', '<cmd>split<CR>', 'Horizontal split')
map('n', '<leader>|', '<cmd>vsplit<CR>', 'Vertical split')
