#!/usr/bin/env bash
# Author: Evan Wise
# Purpose: Installs system packages

set -o errexit
set -o nounset

# Functions
################################################################################

echoerr() {
    echo "$@" 1>&2
}

# Main Body
################################################################################

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            echo "Usage: $0"
            exit 0
            ;;
        *)
            echoerr "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

echo "Creating directories..."
mkdir -p src

if command -v pacman &> /dev/null; then
  # If installing in arch, this is a dev laptop
  # Install base-devel, git and rust to bootstrap paru
  if ! command -v paru &> /dev/null; then
    echo "Bootstrapping paru..."
    sudo pacman -Sy --noconfirm base-devel git rustup
    rustup default stable
    pushd src
    git clone https://aur.archlinux.org/paru.git
    pushd paru
    makepkg -si
    popd
    popd
  fi
  # Includes UI packages as well since this is a laptop...
  echo "Installing packages..."
  paru -Sy --noconfirm ufw btrfs-progs base-devel git docker docker-compose tmux neovim tree-sitter-cli fnm gcc rustup pyright ripgrep dnsutils viu ttf-fira-code ttf-firacode-nerd ttf-nerd-fonts-symbols ttf-nerd-fonts-symbols-mono nerdfix ttf-font-awesome noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu ttf-liberation ttf-ms-fonts lua-language-server jq greetd hyprland-git hyprpolkitagent-git xdg-desktop-portal-hyprland-git hyprpaper-git hyprlock-git hypridle-git qt5-wayland qt6-wayland brightnessctl waybar wofi dunst gnome-keyring libsecret libappindicator kvantum qt6ct qt5ct nwg-look gruvbox-gtk-theme-git kvantum-theme-gruvbox-git gruvbox-plus-icon-theme-git pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol bluez bluez-utils blueman udisks2 udiskie ntfs-3g exfatprogs wezterm-git thunar tumbler ffmpegthumbnailer poppler-glib libgsf vivaldi flameshot grim slurp yubico-authenticator keepassxc dropbox obsidian discord zoom signal-desktop appflowy-bin libreoffice-fresh vlc qimgv-git wl-clipboard tlp tlp-rdw
  echo ""
  echo "Theme setup — run these GUI tools to finish:"
  echo "  kvantummanager  — select Gruvbox theme, click Apply"
  echo "  qt6ct           — set Style to 'kvantum', apply"
  echo "  qt5ct           — set Style to 'kvantum', apply"
  echo "  nwg-look        — select Gruvbox GTK theme + Gruvbox Plus icon theme, apply"
  echo ""
  echo "Installing Node.js LTS..."
  fnm install --lts
  echo "Setting up ufw..."
  sudo ufw default deny incoming
  sudo ufw default allow outgoing
  sudo ufw enable
  sudo systemctl enable --now ufw
  echo "Setting up greetd..."
  sudo cp ~/.config/greetd/config.toml /etc/greetd/config.toml 
  sudo chown root:root /etc/greetd/config.toml
  sudo chmod 644 /etc/greetd/config.toml
  sudo systemctl enable greetd.service
  echo "Setting up docker..."
  systemctl --enable --now docker.socket
  sudo usermod -aG docker "$USER"
  echo "Setting up pcscd..."
  sudo systemctl enable --now pcscd
  sudo usermod -aG pcscd "$USER"
  echo "Setting up USB automounting..."
  sudo systemctl enable --now udisks2.service
  systemctl --user enable --now udiskie
  echo "Setting up Bluetooth..."
  sudo systemctl enable --now bluetooth.service
  systemctl --user enable --now blueman-applet
  echo "Setting up NetworkManager..."
  sudo systemctl enable --now NetworkManager.service
  sudo systemctl enable --now NetworkManager-dispatcher.service
  echo "Setting up TLP..."
  sudo mkdir -p /etc/tlp.d
  sudo cp ~/.config/tlp/99-custom.conf /etc/tlp.d/99-custom.conf
  sudo chown root:root /etc/tlp.d/99-custom.conf
  sudo chmod 644 /etc/tlp.d/99-custom.conf
  sudo systemctl enable --now tlp.service
  echo "Setting up PipeWire..."
  systemctl --user enable --now pipewire pipewire-pulse wireplumber
  echo "Setting up hyprpolkitagent..."
  systemctl --user enable --now hyprpolkitagent
elif command -v apt &> /dev/null; then
  # If installing in Debian or Ubuntu this is a server or WSL VM
  echo "Installing packages..."
  sudo apt install -y build-essential git tmux neovim nodejs npm gcc rustup pyright ripgrep
  if ! command -v brew &> /dev/null; then
    echoerr "Please install brew manually."
    exit 1
  fi
  echo "Installing brew packages..."
  brew install lua-language-server
else
  echoerr "Unsupported package manager."
  exit 1
fi

if ! command -v npm &> /dev/null; then
  echoerr "Please install npm."
  exit 1
fi
echo "Installing npm packages..."
npm install -g typescript-language-server typescript prettier @astrojs/language-server

if [ ! -d "$HOME"/.tmux/plugins/tpm ]; then
  echo "Cloning tpm..."
  git clone https://github.com/tmux-plugins/tpm "$HOME"/.tmux/plugins/tpm
fi
