# dots

Another exceptionally unremarkable dotfile repository.

This basically just exists for my own sanity, but if you see anything useful
feel free to steal it. I stole most of this stuff. Also, if you see anything
obviously or obscurely stupid, please let me know. Use at your own risk.

## Installation

### Before Installing

Make sure your environment at least has a POSIX compatible shell and git.

### Scripted Install

You can run the bootstrap script using the following command, but beware, it
will overwrite local versions of the dotfiles so back these up beforehand.

```bash
curl -s https://raw.githubusercontent.com/evan-wise/dots/main/.local/bin/bootstrap.sh | bash
```

After creating the local copy of the repo with the bootstrap script, you can
interact with it using the `.git` alias. This setup using an alias and a bare
repo with a work tree in a different location is based on
(this article)[https://www.atlassian.com/git/tutorials/dotfiles].

To attempt to install system packages you can now run the install script by
typing `sudo install.sh`. This script requires elevated permissions to install
packages using your operating system's package manager. It only supports Arch
and Ubuntu currently.

## Contents

The files and directories to be copied to the user's home directory are stored
in the `home` directory. Copying files and directories is accomplished using
`rsync`. This provides a simple way to manage both the dotfiles and standard
working directories without having to directly update the setup script every
time a new file is added.

### Dotfiles

- `.bashrc`: config file for bash shell.

- `.tmux.confg`: config file for tmux terminal multiplexer.

- `.config/nvim/init.lua`: config file for NeoVim text editor.

- `.wezterm.lua`: config file for WezTerm terminal emulator.
  - Key features: Highly configurable, many built-in color schemes, ligature support.

### Directories

- `.tmux/plugins`: directory for storing tmux plugins.

- `src`: directory for storing user authored source code and local copies of public repos.

### tmux plugins

- [`tpm`][tpm]: plugin manager for tmux, manages other plugins below.
- [`tmux-sensible`][tmux-sensible]: sensible defaults for tmux.
- [`tmux-resurrect`][tmux-resurrect]: allows saving and restoring tmux sessions.
- [`tmux-autoreload`][tmux-autoreload]: automatically reloads `.tmux.conf`.

### NeoVim plugins

- [`lazy.nvim`][lazy.nvim]: plugin manager for NeoVim, manages other plugins below.
- [`folke/tokyonight.nvim`][tokyonight.nvim]: Tokyo Night colorscheme for NeoVim.
- [`folke/lazydev.nvim`][lazydev.nvim]: types and completions for NeoVim config files.
- [`Bilal2453/luvit-meta`][luvit-meta]: types for `vim.uv`
- [`telescope.nvim`][telescope.nvim]: fuzzy file finder.
- [`telescope-fzf-native`][telescope-fzf-native]: fast C implementation of
  fzf.
- [`nvim-tree`][nvim-tree]: filesystem tree viewer.
- [`nvim-treesitter`][nvim-treesitter]: parser based syntax highlighting.
- [`LuaSnip`][LuaSnip]: snippet engine, used by `nvim-cmp` and required for some LSPs.
- [`nvim-cmp`][nvim-cmp]: completion plugin for NeoVim.
- [`nvim-lspconfig`][nvim-lspconfig]: common configurations for LSPs.
- [`cmp-nvim-lsp`][cmp-nvim-lsp]: `nvim-cmp` source for LSPs.
- [`copilot.lua`][copilot.lua]: GitHub copilot integration.
- [`nvim-surround`][nvim-surround]: insert / modify / delete surrounding characters and tags.
- [`Comments.nvim`][Comments.nvim]: easily add and remove line and block comments.

### Other

- `setup.sh`: bash setup script for this repository.

- `LICENSE.txt`: License for this repository.

- `README.md`: this file.

## Installation

I suspect you can guess the first step, clone the github repository.

    git clone https://github.com/evan-wise/dots

### Linux

On GNU/Linux systems, you should be able to run the included script, `setup.sh`.
It accepts a command line option `-i` which will cause it to attempt to install
system dependencies.

### Other Operation Systems

I haven't tested this on any other operating systems.

## Removal

This is manual. If I am exactly the right amount of lazy I will add options to
the setup scripts to do this automatically.

## TODO

- Allow system specific overrides for environment variables.

<!-- References -->

[tpm]: https://github.com/tmux-plugins/tpm
[tmux-sensible]: https://github.com/tmux-plugins/tmux-sensible
[tmux-resurrect]: https://github.com/tmux-plugins/tmux-resurrect
[tmux-autoreload]: https://github.com/b0o/tmux-autoreload
[lazy.nvim]: https://github.com/folke/lazy.nvim
[lazydev.nvim]: https://github.com/folke/lazydev.nvim
[tokyonight.nvim]: https://github.com/folke/tokyonight.nvim
[luvit-meta]: https://github.com/Bilal2453/luvit-meta
[solarized.nvim]: https://github.com/maxmx03/solarized.nvim
[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[telescope-fzf-native]: https://github.com/nvim-telescope/telescope-fzf-native.nvim
[nvim-tree]: https://github.com/nvim-tree/nvim-tree.lua
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[LuaSnip]: https://github.com/L3MON4D3/LuaSnip
[nvim-cmp]: https://github.com/hrsh7th/nvim-cmp
[nvim-lspconfig]: https://github.com/neovim/nvim-lspconfig
[cmp-nvim-lsp]: https://github.com/hrsh7th/cmp-nvim-lsp
[copilot.lua]: https://github.com/zbirenbaum/copilot.lua
[nvim-surround]: https://github.com/kylechui/nvim-surround
[Comments.nvim]: https://github.com/numToStr/Comment.nvim

