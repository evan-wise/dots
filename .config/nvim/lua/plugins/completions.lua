return {
  {
    'L3MON4D3/LuaSnip',
    version = false,
  },
  {
    'hrsh7th/nvim-cmp',
    version = false,
    Event = 'InsertEnter',
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
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp', keyword_length = 1 },
          { name = 'buffer',   keyword_length = 2 },
          { name = 'path',     keyword_length = 3 },
          { name = 'lazydev',  group_index = 0 },
        }),
      })
    end,
  },
  {
    'neovim/nvim-lspconfig',
    version = false,
    dependencies = { 'hrsh7th/cmp-nvim-lsp' },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities()
      local on_attach = function(_, bufnr)
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
        vim.keymap.set('n', 'gI', vim.lsp.buf.implementation, bufopts)         -- Remaps a default binding I don't use
        vim.keymap.set('n', 'gt', vim.lsp.buf.type_definition, bufopts)
        vim.keymap.set('n', '<leader>s', vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set('n', '<leader>r', vim.lsp.buf.rename, bufopts)
        vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, bufopts)
        vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, bufopts)
      end

      lspconfig.ts_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.pyright.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.astro.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })

      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end,
    ft = { 'typescript', 'javasript', 'python', 'lua', 'astro', 'rust' },
  },
  {
    'zbirenbaum/copilot.lua',
    version = '*',
    cmd = 'Copilot',
    event = 'InsertEnter',
    config = function()
      require('copilot').setup({
        suggestion = { auto_trigger = true },
        panel = { enabled = false },
        filetypes = {
          javascript = true,
          typescript = true,
          ["*"] = false,
        },
      })
    end,
  },
}
