-- Author: Evan Wise
-- Revision Date: 2024-08-11
-- Purpose: Configuration file for neovim text editor

local util = require('util')

-- Options

-- Indent
vim.opt.tabstop = 2        -- TAB is visually represented by 4 spaces
vim.opt.expandtab = true   -- Pressing TAB inserts spaces
vim.opt.softtabstop = 2    -- Number of spaces to insert when pressing TAB
vim.opt.shiftwidth = 2     -- Number up spaces inserted when indenting
vim.opt.smartindent = true -- Automatically indent on new lines

-- Misc
vim.opt.number = true         -- Show line numbers
vim.opt.relativenumber = true -- Show relative line numbers, together gives hybrid line numbers
vim.opt.textwidth = 80        -- Wrap text at 80 characters
vim.opt.colorcolumn = '80'    -- Highlight column 80

-- Keymaps

-- Make j and k sane with line wrapping
vim.keymap.set('n', 'j', 'gj', { silent = true })
vim.keymap.set('n', 'k', 'gk', { silent = true })

-- Use Q for formatting, I do not use Ex mode
-- NOTE: using gw instead of gq since gq uses LSP formatting by default, see
-- this PR: https://github.com/neovim/neovim/pull/19677
vim.keymap.set('n', 'Q', 'gw', { silent = true })
vim.keymap.set('n', 'QQ', 'gww', { silent = true })

-- Commands

-- Format file with prettier
vim.api.nvim_create_user_command('Prettier',
  function(opts)
    local pos = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
    local cmd = 'npx prettier --stdin-filepath ' .. vim.fn.expand('%')

    local exit_code, result, error = util.run_command(cmd, table.concat(lines, '\n'))
    if exit_code ~= 0 then
      print("Command '" .. cmd .. "' failed with exit code: " .. exit_code)
      print("Error: " .. error)
      return
    end
    local at_end = opts.line2 == vim.api.nvim_buf_line_count(0)
    if result ~= '' then
      local new_lines = vim.split(vim.trim(result), '\n')
      vim.api.nvim_buf_set_lines(0, opts.line1 - 1, opts.line2, false, new_lines)
      if at_end then
        local end_index = vim.api.nvim_buf_line_count(0)
        vim.api.nvim_buf_set_lines(0, end_index, end_index, false, { '' })
      end
    end
    local row, col = pos[1], pos[2]
    row = math.min(row, vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(0, { row, col })
  end,
  { nargs = 0, range = true }
);

-- Autocommands

-- Turn off relative line numbers in command line and insert mode, turn back on
-- for normal mode where they are most useful.
vim.api.nvim_create_augroup('NumberToggle', {});
vim.api.nvim_create_autocmd({
  'InsertEnter', 'CmdlineEnter'
}, {
  group = 'NumberToggle',
  callback = function(args)
    vim.opt.relativenumber = false
    if args.event == 'CmdlineEnter' then
      vim.cmd('redraw')
    end
  end,
});
vim.api.nvim_create_autocmd({
  'InsertLeave', 'CmdlineLeave'
}, {
  group = 'NumberToggle',
  callback = function()
    vim.opt.relativenumber = true
  end,
});

-- Format *.js, *.ts, *.jsx, *.tsx, *.json, *.html, *.css, *.md files with
-- prettier on save.
-- vim.api.nvim_create_augroup('PrettierOnSave', {});
-- vim.api.nvim_create_autocmd({
--   'BufWritePre',
-- }, {
--   pattern = { '*.js', '*.ts', '*.jsx', '*.tsx', '*.json', '*.html', '*.css', '*.md' },
--   group = 'PrettierOnSave',
--   callback = function()
--     vim.cmd('%Prettier')
--   end,
-- });

-- Install lazy.nvim if not already done.
util.bootstrap_lazy()

-- Configure Plugins

require('lazy').setup({
  -- Automagic plugin import from lua/plugins spec files
  spec = {
    { import = 'plugins' },
  },
  -- Check for updates
  checker = { enabled = true },
})

