---@module 'lazy'
---@type LazySpec
return {
  {
    'Olical/conjure',
    ft = { 'scheme' },
    init = function()
      local mit_scheme_candidates = {
        '/usr/local/bin/mit-scheme',
        '/usr/local/bin/scheme',
        'mit-scheme',
        'scheme',
      }

      local repl = 'mit-scheme'
      for _, candidate in ipairs(mit_scheme_candidates) do
        if vim.fn.executable(candidate) == 1 then
          repl = candidate
          break
        end
      end

      vim.g['conjure#client#scheme#stdio#command'] = repl
    end,
  },
}
