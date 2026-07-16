-- .NET / C# / F# tooling.
--
-- Roslyn is the modern C# language server (replaces OmniSharp). It is
-- distributed as the `roslyn` Mason package (Microsoft.CodeAnalysis.LanguageServer)
-- and driven by `seblyng/roslyn.nvim`, which knows how to discover .sln /
-- .csproj roots, attach the server, and surface Roslyn-specific commands.
--
-- F# is handled by `fsautocomplete`, configured in init.lua's `servers` table
-- and installed via mason-lspconfig. F# debugging shares the .NET adapter.
--
-- Debugging uses `mfussenegger/nvim-dap` with `netcoredbg` (installed via
-- Mason in init.lua). `easy-dotnet.nvim` glues the dotnet CLI to nvim:
-- run, test, watch, secrets, package management, solution explorer.

return {
  {
    'seblyng/roslyn.nvim',
    ft = { 'cs', 'fsharp' },
    ---@module 'roslyn.config'
    ---@type RoslynNvimConfig
    opts = {
      -- Pass through to vim.lsp.config for the roslyn client.
      config = {
        settings = {
          ['csharp|inlay_hints'] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
            dotnet_enable_inlay_hints_for_indexer_parameters = true,
            dotnet_enable_inlay_hints_for_literal_parameters = true,
            dotnet_enable_inlay_hints_for_object_creation_parameters = true,
            dotnet_enable_inlay_hints_for_other_parameters = true,
            dotnet_enable_inlay_hints_for_parameters = true,
            dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
            dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
          },
          ['csharp|code_lens'] = {
            dotnet_enable_references_code_lens = true,
            dotnet_enable_tests_code_lens = true,
          },
          ['csharp|background_analysis'] = {
            dotnet_analyzer_diagnostics_scope = 'fullSolution',
            dotnet_compiler_diagnostics_scope = 'fullSolution',
          },
          ['csharp|completion'] = {
            dotnet_show_completion_items_from_unimported_namespaces = true,
            dotnet_show_name_completion_suggestions = true,
          },
        },
      },
    },
  },

  {
    'GustavEikaas/easy-dotnet.nvim',
    ft = { 'cs', 'fsharp' },
    cmd = { 'Dotnet' },
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-telescope/telescope.nvim',
    },
    ---@module 'easy-dotnet'
    opts = {
      test_runner = {
        viewmode = 'split',
        enable_buffer_test_execution = true,
        noBuild = true,
        noRestore = true,
      },
      picker = 'telescope',
    },
    keys = {
      { '<leader>db', '<cmd>Dotnet build<cr>',         desc = '.NET [B]uild' },
      { '<leader>dr', '<cmd>Dotnet run<cr>',           desc = '.NET [R]un' },
      { '<leader>dt', '<cmd>Dotnet testrunner<cr>',    desc = '.NET [T]est runner' },
      { '<leader>ds', '<cmd>Dotnet secrets<cr>',       desc = '.NET [S]ecrets' },
      { '<leader>dp', '<cmd>Dotnet outdated<cr>',      desc = '.NET [P]ackages outdated' },
      { '<leader>dn', '<cmd>Dotnet new<cr>',           desc = '.NET [N]ew project' },
    },
  },

  {
    'mfussenegger/nvim-dap',
    ft = { 'cs', 'fsharp' },
    dependencies = {
      { 'rcarriga/nvim-dap-ui', dependencies = { 'nvim-neotest/nvim-nio' } },
      'theHamsta/nvim-dap-virtual-text',
    },
    config = function()
      local dap = require 'dap'
      local dapui = require 'dapui'

      dapui.setup {}
      require('nvim-dap-virtual-text').setup {}

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      local netcoredbg = vim.fn.exepath 'netcoredbg'
      if netcoredbg == '' then
        local mason_bin = vim.fn.stdpath 'data' .. '/mason/bin/netcoredbg'
        if vim.uv.fs_stat(mason_bin) then netcoredbg = mason_bin end
      end

      dap.adapters.coreclr = {
        type = 'executable',
        command = netcoredbg,
        args = { '--interpreter=vscode' },
      }
      dap.adapters.netcoredbg = dap.adapters.coreclr

      local function dll_picker()
        return coroutine.create(function(co)
          local cwd = vim.fn.getcwd()
          vim.ui.input({
            prompt = 'Path to dll: ',
            default = cwd .. '/bin/Debug/',
            completion = 'file',
          }, function(input) coroutine.resume(co, input) end)
        end)
      end

      dap.configurations.cs = {
        {
          type = 'coreclr',
          name = 'launch - netcoredbg',
          request = 'launch',
          program = dll_picker,
        },
      }
      dap.configurations.fsharp = dap.configurations.cs

      vim.keymap.set('n', '<leader>dC', function() dap.continue() end, { desc = 'DAP [C]ontinue' })
      vim.keymap.set('n', '<leader>dO', function() dap.step_over() end, { desc = 'DAP step [O]ver' })
      vim.keymap.set('n', '<leader>dI', function() dap.step_into() end, { desc = 'DAP step [I]nto' })
      vim.keymap.set('n', '<leader>dU', function() dap.step_out() end, { desc = 'DAP step o[U]t' })
      vim.keymap.set('n', '<leader>dB', function() dap.toggle_breakpoint() end, { desc = 'DAP [B]reakpoint' })
      vim.keymap.set('n', '<leader>dX', function() dap.terminate() end, { desc = 'DAP terminate' })
    end,
  },
}
