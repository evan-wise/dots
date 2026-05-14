#!/bin/bash
w=$(tmux list-windows -a -F "#{window_bell_flag} #{window_id}" | awk '/^1/{print $2; exit}')
[ -n "$w" ] && tmux select-window -t "$w"
