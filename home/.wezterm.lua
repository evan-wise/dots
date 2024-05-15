-- Author: Evan Wise
-- Revision Date: 2024-05-14
-- Purpose: Configuration for wezterm terminal emulator

local wezterm = require('wezterm')

local config = wezterm.config_builder()

config.font = wezterm.font("Fira Code")
config.font_size = 14.0
config.color_scheme = "Tokyo Night Storm"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 4,
  right = 4,
  top = 4,
  bottom = 4,
}

-- Windows specific overrides
if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.default_prog = {"wsl", "-u", "evan"};
end


return config
