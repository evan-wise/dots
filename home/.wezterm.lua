-- Author: Evan Wise
-- Revision Date: 2024-05-05
-- Purpose: Configuration for wezterm terminal emulator

local wezterm = require 'wezterm';

local config = wezterm.config_builder();

config.font = wezterm.font("Fira Code");
config.font_size = 12.0;
config.color_scheme = "Selenized Dark (Gogh)";
config.hide_tab_bar_if_only_one_tab = true;
config.window_padding = {
  left = 4,
  right = 4,
  top = 4,
  bottom = 4,
};
config.keys = {
  {key="x", mods="CTRL", action=wezterm.action{CloseCurrentTab={confirm=true}}},
};

return config;
