-- Author: Evan Wise
-- Revision Date: 2024-09-20
-- Purpose: Configuration file for neovim text editor

local util = require('util')

-- Globals

vim.g.netrw_liststyle = 3    -- Use tree style for netrw
vim.g.netrw_banner = 0       -- Do not show banner for netrw
vim.g.netrw_browse_split = 4 -- Open netrw in a vertical split
vim.g.netrw_winsize = 25     -- Set netrw split width to 25
vim.g.netrw_altv = 1         -- Open netrw in a vertical split

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

-- Use [b and ]b to navigate buffers
vim.keymap.set('n', '[b', ':bp<CR>', { silent = true })
vim.keymap.set('n', ']b', ':bn<CR>', { silent = true })

-- Commands

-- Format file with prettier
vim.api.nvim_create_user_command('Prettier',
  function(opts)
    local pos = vim.api.nvim_win_get_cursor(0)
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local cmd = 'npx prettier --stdin-filepath ' .. vim.fn.expand('%')

    local exit_code, result, error = util.run_command(cmd, table.concat(lines, '\n'))
    if exit_code ~= 0 then
      print("Command '" .. cmd .. "' failed with exit code: " .. exit_code)
      print("Error: " .. error)
      return
    end

    local end_index = vim.api.nvim_buf_line_count(0)
    if result ~= '' then
      local new_lines = vim.split(vim.trim(result), '\n')
      vim.api.nvim_buf_set_lines(0, 0, end_index, false, new_lines)
      vim.api.nvim_buf_set_lines(0, end_index, end_index, false, { '' })
    end

    local row, col = pos[1], pos[2]
    row = math.min(row, vim.api.nvim_buf_line_count(0))
    vim.api.nvim_win_set_cursor(0, { row, col })
  end,
  { nargs = 0, range = true }
);

-- Open project drawer
vim.api.nvim_create_user_command('Drawer', 'Vexplore  .', { nargs = 0 });

-- Autocommands

-- Format *.js, *.ts, *.jsx, *.tsx, *.json, *.html, *.css, *.md files with
-- prettier on save.
vim.api.nvim_create_augroup('PrettierOnSave', {});
vim.api.nvim_create_autocmd({
  'BufWritePre',
}, {
  pattern = { '*.js', '*.ts', '*.jsx', '*.tsx', '*.json', '*.html', '*.css', '*.md' },
  group = 'PrettierOnSave',
  callback = function()
    vim.cmd('Prettier')
  end,
});

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

