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
}
