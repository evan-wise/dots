# dots

Another exceptionally unremarkable dotfile repository.

This basically just exists for my own sanity, but if you see anything useful
feel free to steal it. I stole most of this stuff. Also, if you see anything
obviously or obscurely stupid, please let me know. Use at your own risk.

## Installation

Before installing, make sure your environment at least has a POSIX compatible
shell and git.

### Scripted Install

You can run the bootstrap script using the following command, but beware, it
will overwrite local versions of your dotfiles so back these up beforehand.

```bash
curl -s https://raw.githubusercontent.com/evan-wise/dots/main/bin/bootstrap.sh | bash
```

After creating the local copy of the repo with the bootstrap script, you can
interact with it using the `.git` alias.

To attempt to install system packages you can now run the install script by
typing `install.sh`. This script requires elevated permissions to install
packages using your operating system's package manager. It only supports Arch
and Ubuntu currently.

### Other Operation Systems

I haven't tested this on any other operating systems. Have fun!

## Contents

The repo stores the exact layout of the dotfiles which will go in the user's
`$HOME` directory. This greatly simplifies management and allows new files to
be added seamlessly. This setup using an alias and a bare repo with a work tree
in a different location is based on [this article](https://www.atlassian.com/git/tutorials/dotfiles).

### Dotfiles

- `.bash_profile`: login profile for bash shell.
- `.bashrc`: config file for bash shell.
- `.zprofile`: login profile for zsh shell.
- `.zshrc`: config file for zsh shell.
- `.gitconfig-common`: shared git configuration, included by `.gitconfig`.
- `.gitignore`: global git ignore rules.
- `.tmux.conf`: config file for tmux terminal multiplexer.
- `.wezterm.lua`: config file for WezTerm terminal emulator.
- `.config/nvim/init.lua`: entry point for NeoVim configuration.
- `.config/nvim/lua/plugins/`: split plugin configs loaded by `lazy.nvim`.
  - `core.lua`: colorscheme, treesitter, telescope, and editing plugins.
  - `completions.lua`: LSP, snippets, and completion plugins.
  - `experimental.lua`: optional/disabled plugins (e.g. nvim-tree, neotest).
- `.config/hypr/hyprland.conf`: Hyprland compositor configuration.
- `.config/hypr/hyprpaper.conf`: wallpaper configuration for hyprpaper.
- `.config/hypr/hyprlock.conf`: lock screen configuration for hyprlock.
- `.config/hypr/hypridle.conf`: idle daemon configuration for hypridle.
- `.config/waybar/config.jsonc`: waybar status bar layout and modules.
- `.config/waybar/style.css`: waybar status bar styling.
- `.config/wofi/config`: wofi launcher configuration.
- `.config/wofi/style.css`: wofi launcher styling.
- `.config/dunst/dunstrc`: dunst notification daemon configuration.
- `.config/greetd/config.toml`: greetd login manager configuration.
- `.config/systemd/user/`: user systemd service and socket units for
  PipeWire, Bluetooth, Dropbox, dunst, flameshot, hyprpaper, hypridle,
  waybar, and hyprpolkitagent.
- `.claude/settings.json`: Claude Code settings.
- `.claude/statusline-command.sh`: script for Claude Code status line.

### Directories

- `.tmux/plugins`: directory for storing tmux plugins.
- `src`: directory for storing user authored source code and local copies of public repos.

### Scripts

- `bin/bootstrap.sh`: clones the bare repo and checks out dotfiles into `$HOME`.
- `bin/install.sh`: installs system packages via `pacman`/`paru` (Arch) or `apt` (Debian/Ubuntu).
- `bin/backup.sh`: backs up KeePass and Logs from Dropbox to `~/backup`.

### tmux plugins

- [`tpm`][tpm]: plugin manager for tmux, manages other plugins below.
- [`tmux-sensible`][tmux-sensible]: sensible defaults for tmux.
- [`tmux-resurrect`][tmux-resurrect]: allows saving and restoring tmux sessions.

### NeoVim plugins

- [`lazy.nvim`][lazy.nvim]: plugin manager for NeoVim, manages other plugins below.
- [`ellisonleao/gruvbox.nvim`][gruvbox.nvim]: Gruvbox colorscheme for NeoVim.
- [`folke/lazydev.nvim`][lazydev.nvim]: types and completions for NeoVim config files.
- [`Bilal2453/luvit-meta`][luvit-meta]: types for `vim.uv`.
- [`telescope.nvim`][telescope.nvim]: fuzzy file finder.
- [`telescope-fzf-native`][telescope-fzf-native]: fast C implementation of fzf.
- [`nvim-treesitter`][nvim-treesitter]: parser based syntax highlighting.
- [`LuaSnip`][LuaSnip]: snippet engine, used by `nvim-cmp` and required for some LSPs.
- [`nvim-cmp`][nvim-cmp]: completion plugin for NeoVim.
- [`nvim-lspconfig`][nvim-lspconfig]: common configurations for LSPs.
- [`cmp-nvim-lsp`][cmp-nvim-lsp]: `nvim-cmp` source for LSPs.
- [`copilot.lua`][copilot.lua]: GitHub Copilot integration.
- [`nvim-surround`][nvim-surround]: insert / modify / delete surrounding characters and tags.
- [`Comment.nvim`][Comments.nvim]: easily add and remove line and block comments.
- [`nvim-highlight-colors`][nvim-highlight-colors]: inline color previews in the editor.
- [`neotest`][neotest]: test runner framework with adapters for Python, Jest, and Vitest.

The following plugins are configured in `experimental.lua` and disabled by default:

- [`nvim-tree`][nvim-tree]: filesystem tree viewer.

### Other

- `LICENSE.txt`: License for this repository.

- `README.md`: this file.

## Removal

This is manual. If I am exactly the right amount of lazy I will add options to
the setup scripts to do this automatically.

## TODO

- [ ] Consider scripts to manage theming.
- [ ] Make a prompt that detects non graphical environments (symbols look bad)

<!-- References -->

[tpm]: https://github.com/tmux-plugins/tpm
[tmux-sensible]: https://github.com/tmux-plugins/tmux-sensible
[tmux-resurrect]: https://github.com/tmux-plugins/tmux-resurrect
[lazy.nvim]: https://github.com/folke/lazy.nvim
[gruvbox.nvim]: https://github.com/ellisonleao/gruvbox.nvim
[lazydev.nvim]: https://github.com/folke/lazydev.nvim
[luvit-meta]: https://github.com/Bilal2453/luvit-meta
[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[telescope-fzf-native]: https://github.com/nvim-telescope/telescope-fzf-native.nvim
[nvim-treesitter]: https://github.com/nvim-treesitter/nvim-treesitter
[LuaSnip]: https://github.com/L3MON4D3/LuaSnip
[nvim-cmp]: https://github.com/hrsh7th/nvim-cmp
[nvim-lspconfig]: https://github.com/neovim/nvim-lspconfig
[cmp-nvim-lsp]: https://github.com/hrsh7th/cmp-nvim-lsp
[copilot.lua]: https://github.com/zbirenbaum/copilot.lua
[nvim-surround]: https://github.com/kylechui/nvim-surround
[Comments.nvim]: https://github.com/numToStr/Comment.nvim
[nvim-highlight-colors]: https://github.com/brenoprata10/nvim-highlight-colors
[neotest]: https://github.com/nvim-neotest/neotest
[nvim-tree]: https://github.com/nvim-tree/nvim-tree.lua

