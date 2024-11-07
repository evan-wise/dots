return {
  {
    'folke/tokyonight.nvim',
    version = '*',
    lazy = false,
    config = function()
      vim.opt.termguicolors = true
      vim.opt.background = 'dark'
      vim.cmd.colorscheme('tokyonight-storm')
    end
  },
  {
    'folke/lazydev.nvim',
    version = '*',
    ft = 'lua',
    opts = {
      library = {
        -- Only load if `vim.uv` is found
        { path = "luvit-meta/library", words = { "vim%.uv" } },
      },
    },
  },
  { "Bilal2453/luvit-meta", lazy = true }, -- optional `vim.uv` typings
  {
    'nvim-treesitter/nvim-treesitter',
    version = '*',
    event = 'BufReadPre',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'typescript', 'tsx', 'lua', 'python', 'json', 'html', 'css', 'markdown', 'astro', 'rust' },
        sync_install = false,
        auto_install = true,
        ignore_install = {},
        modules = {},
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = true,
        },
        indent = false,
      })
    end,
  },
  {
    'nvim-telescope/telescope.nvim',
    version = '*',
    event = 'BufReadPre',
    dependencies = { 'nvim-lua/plenary.nvim', },
    config = function()
      local telescope = require('telescope')
      local builtin = require('telescope.builtin')
      local opts = { noremap = true, silent = true }
      vim.keymap.set('n', '<leader>ff', builtin.find_files, opts)
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, opts)
      vim.keymap.set('n', '<leader>fb', builtin.buffers, opts)
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, opts)

      telescope.setup({
        pickers = {
          find_files = {
            find_command = { 'rg', '--files', '--hidden', '--follow', '--glob', '!.git' },
          },
        },
        extensions = {
          fzf = {
            -- fuzzy = true,
            -- override_generic_sorter = true,
            -- override_file_sorter = true,
            -- case_mode = 'smart_case',
          },
        },
      })
    end,
  },
  {
    'nvim-telescope/telescope-fzf-native.nvim',
    build = 'make'
  },
  {
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('nvim-surround').setup()
    end,
  },
  {
    'numToStr/Comment.nvim',
    version = '*',
    event = 'VeryLazy',
    config = function()
      require('Comment').setup()
    end,
  },
}
