-- debug.lua
--
-- Shows how to use the DAP plugin to debug your code.
--
-- Primarily focused on configuring the debugger for Go, but can
-- be extended to other languages as well. That's why it's called
-- kickstart.nvim and not kitchen-sink.nvim ;)

return {
  -- NOTE: Yes, you can install new plugins here!
  'mfussenegger/nvim-dap',
  -- NOTE: And you can specify dependencies as well
  dependencies = {
    -- Creates a beautiful debugger UI
    'rcarriga/nvim-dap-ui',

    -- Required dependency for nvim-dap-ui
    'nvim-neotest/nvim-nio',

    -- Installs the debug adapters for you
    'williamboman/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',

    -- Add your own debuggers here
    'leoluz/nvim-dap-go',
    'mfussenegger/nvim-dap-python', -- Optional adapter for Python

    -- Remember nvim-dap breakpoints between sessions, ``:PBToggleBreakpoint``
    {
      'Weissle/persistent-breakpoints.nvim',
      config = function()
        require('persistent-breakpoints').setup {
          load_breakpoints_event = { 'BufReadPost' },
        }

        vim.keymap.set('n', '<leader>dpb', ':PBToggleBreakpoint<CR>')
      end,
    },
    {
      'theHamsta/nvim-dap-virtual-text',
      dependencies = {
        'mfussenegger/nvim-dap',
        'nvim-treesitter/nvim-treesitter',
      },
    },
    {
      'nvim-neotest/neotest',
      dependencies = {
        'nvim-neotest/nvim-nio',
        'nvim-lua/plenary.nvim',
        'antoinemadec/FixCursorHold.nvim',
        'nvim-treesitter/nvim-treesitter',
      },
    },
    {
      'pocco81/dap-buddy.nvim',
      dependencies = {
        'mfussenegger/nvim-dap',
      },
    },
  },
  keys = function(_, keys)
    local dap = require 'dap'
    local dapui = require 'dapui'
    local dapuw = require 'dap.ui.widgets'
    local persist = require 'persistent-breakpoints.api'
    return {
      -- Basic debugging keymaps, feel free to change to your liking!
      { '<leader>dc', dap.continue, desc = '[d]ebug: Start/Continue' },
      { '<leader>dj', dap.step_into, desc = '[d]ebug: Step Into' },
      { '<leader>dl', dap.step_over, desc = '[d]ebug: Step Over' },
      { '<leader>dk', dap.step_out, desc = '[d]ebug: Step Out' },
      { '<leader>dh', dap.step_back, desc = '[d]ebug: Step back' },
      { '<leader>b', persist.toggle_breakpoint, desc = 'Debug: Toggle [b]reakpoint' },
      { '<leader>B', persist.set_conditional_breakpoint, desc = 'Debug: Set conditional [B]reakpoint' },
      -- {
      --   '<leader>B',
      --   function()
      --     persist.set_conditional_breakpoint(vim.fn.input '[B]reakpoint condition: ')
      --   end,
      --   desc = 'Debug: Set Breakpoint',
      -- },
      -- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
      { '<leader>dlr', dapui.toggle, desc = '[d]ebug: See [l]ast session [r]esult.' },
      { '<leader>dt', dap.set_log_level 'Trace', desc = '[d]ebug: See [t]race.' },
      { '<leader>duh', dapuw.hover, desc = '[d]ebug: [u]I [h]over.' },
      { '<leader>dup', dapuw.preview, desc = '[d]ebug: [u]I [p]review.' },
      {
        '<leader>duf',
        function()
          dapuw.centered_float(dapuw.frames)
        end,
        desc = '[d]ebug: [u]I float [f]rames.',
      },
      {
        '<leader>dus',
        function()
          dapuw.centered_float(dapuw.scopes)
        end,
        desc = '[d]ebug: [u]I float [s]copes.',
      },
      { '<leader>d-', dap.restart, desc = '[d]ebug: Restart' },
      {
        '<leader>d_',
        function()
          dap.terminate()
          dapui.close()
        end,
        desc = '[d]ebug: Close',
      },
      unpack(keys),
    }
  end,
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      -- Makes a best effort to setup the various debuggers with
      -- reasonable debug configurations
      automatic_installation = true,

      -- You can provide additional configuration to the handlers,
      -- see mason-nvim-dap README for more information
      handlers = {},

      -- You'll need to check that you have the required things installed
      -- online, please don't ask me how to install them :)
      ensure_installed = {
        -- Update this to ensure that you have the debuggers for the langs you want
        'delve',
        'pydebug',
      },
    }

    -- Dap UI setup
    -- For more information, see |:help nvim-dap-ui|
    dapui.setup {
      -- Set icons to characters that are more likely to work in every terminal.
      --    Feel free to remove or use ones that you like more! :)
      --    Don't feel like these are good choices.
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    -- Configure icons for breakpoint and stopped point
    vim.fn.sign_define('DapBreakpoint', { text = '🛑', texthl = '', linehl = '', numhl = '' })
    vim.fn.sign_define('DapStopped', { text = '▶️', texthl = '', linehl = '', numhl = '' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- Install golang specific config
    require('dap-go').setup {
      delve = {
        -- On Windows delve must be run attached or it crashes.
        -- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
        detached = vim.fn.has 'win32' == 0,
      },
    }
    require('dap-python').setup '/usr/bin/python3'
    -- If using the above, then `python3 -m debugpy --version`
    -- must work in the shell
  end,
}
