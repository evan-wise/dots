return {
  {
    'nvim-tree/nvim-tree.lua',
    enabled = false, -- Change to true to enable
    version = '*',
    event = 'BufReadPre',
    config = function()
      require('nvim-tree').setup({
        disable_netrw = true,
        sort = {
          sorter = 'case_sensitive',
          folders_first = true,
        },
        view = {
          width = 30,
        },
      })
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>ft', ':NvimTreeToggle<CR>', opts)
    end,
  },
  {
    'nvim-neotest/neotest',
    enabled = true, -- Change to false to disable
    version = '*',
    dependencies = {
      'nvim-neotest/nvim-nio',
      'nvim-lua/plenary.nvim',
      'antoinemadec/FixCursorHold.nvim',
      'nvim-treesitter/nvim-treesitter',
      'nvim-neotest/neotest-python',
      'nvim-neotest/neotest-jest',
      'marilari88/neotest-vitest',
    },
    config = function()
      local neotest = require('neotest')
      -- This line works even though lazydev.nvim complains.
      neotest.setup({
        adapters = {
          require('neotest-python')({}),
          require('neotest-jest')({}),
          require('neotest-vitest')({}),
        },
      })
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>tr', ':Neotest run<CR>', opts)
      vim.keymap.set('n', '<leader>ts', ':Neotest stop<CR>', opts)
      vim.keymap.set('n', '<leader>ta', ':Neotest attach<CR>', opts)
      vim.keymap.set('n', '<leader>tt', ':Neotest summary<CR>', opts)
    end,
  },
}
