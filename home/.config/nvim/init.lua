-- Author: Evan Wise
-- Revision Date: 2024-05-05
-- Purpose: Configuration file for neovim text editor

-- Install lazy.nvim if not already done.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configure Plugins
require("lazy").setup({
  {
    "maxmx03/solarized.nvim",
    version = "*",
    lazy = false,
    config = function ()
      require('solarized').setup({
        palette = 'selenized',
      })
      vim.opt.termguicolors = true
      vim.opt.background = 'dark'
      vim.cmd.colorscheme('solarized')
    end
  },
  {
    'nvim-telescope/telescope.nvim',
    version = "*",
    event = "BufReadPre",
    dependencies = { 'nvim-lua/plenary.nvim',  },
    config = function()
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
      vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
      vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
      vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
    end,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    version = "*",
    event = "BufReadPre",
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'typescript', 'lua' },
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        additional_vim_regex_highlighting = false,
        indent = false,
      })
    end,
  },
  {
    "L3MON4D3/LuaSnip",
    version = "*",
  },
  {
    'hrsh7th/nvim-cmp',
    version = "*",
    Event = "InsertEnter",
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      local copilot = require('copilot.suggestion')

      cmp.setup({
        snippet = {
          expand = function(args)
            if not luasnip then
              return
            end
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<Tab>'] = cmp.mapping(function(fallback)
            if copilot.is_visible() and not cmp.visible() then
              copilot.accept()
            elseif cmp.visible() and not copilot.is_visible() then
              local entry = cmp.get_selected_entry()
              if not entry then
                cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
              end
              cmp.confirm()
            elseif cmp.visible() and copilot.is_visible() then
              local entry = cmp.get_selected_entry()
              if entry then
                cmp.confirm()
              else
                copilot.accept()
              end
            else
              fallback()
            end
          end, {'i', 's'}),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', keyword_length=1 },
          { name = 'buffer',   keyword_length=2 },
          { name = 'path',     keyword_length=3 },
        }),
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    version = "*",
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local on_attach = function(_, bufnr)
        local bufopts = { noremap=true, silent=true, buffer=bufnr }
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', 'K'    , vim.lsp.buf.hover         , bufopts)
      end

      lspconfig.tsserver.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
        settings = {
          Lua = {
            diagnostics = {
              -- Get the language server to recognize the `vim` global
              globals = { 'vim' },
            },
          }
        }
      })
    end,
    ft = { 'typescript', 'javasript', 'lua' }
  },
  {
    "zbirenbaum/copilot.lua",
    version = "*",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { auto_trigger = true },
        panel = { enabled = false },
      })
    end,
  },
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require('nvim-surround').setup({})
    end,
  },
  {
    'numToStr/Comment.nvim',
    version = "*",
    event = "VeryLazy",
    config = function()
      require('Comment').setup({})
    end,
  },
})

-- Options

-- Indent
vim.opt.tabstop = 2           -- TAB is visually represented by 4 spaces
vim.opt.expandtab = true      -- Pressing TAB inserts spaces
vim.opt.softtabstop = 2       -- Number of spaces to insert when pressing TAB
vim.opt.shiftwidth = 2        -- Number up spaces inserted when indenting
vim.opt.smartindent = true    -- Automatically indent on new lines

-- Misc
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers, together gives hybrid line numbers

-- Keymaps

-- Make j and k sane with line wrapping
vim.keymap.set('n', 'j', 'gj', { silent=true })
vim.keymap.set('n', 'k', 'gk', { silent=true })

