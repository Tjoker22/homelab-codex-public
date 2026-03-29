# Thoth — Complete Debian 13 Build Guide

**Hostname:** thoth  
**Hardware:** HP Intel Core i5-7200U, Intel HD 620, 8GB RAM, 1TB SSD  
**OS:** Debian 13 "Trixie" (netinstall)  
**Goal:** Minimal server base built into a terminal-first i3 environment

---

## Table of Contents

1. [Pre-Install Checklist](#1-pre-install-checklist)
2. [Debian Install](#2-debian-install)
3. [Phase 1 — Base System](#3-phase-1--base-system)
4. [Phase 2 — Desktop Foundation](#4-phase-2--desktop-foundation)
5. [Phase 3 — Terminal Environment](#5-phase-3--terminal-environment)
6. [Phase 4 — Audio and Bluetooth](#6-phase-4--audio-and-bluetooth)
7. [Phase 5 — Applications](#7-phase-5--applications)
8. [Phase 6 — Development Environment](#8-phase-6--development-environment)
9. [Phase 7 — Polish](#9-phase-7--polish)
10. [i3 Config Reference](#10-i3-config-reference)
11. [Dotfiles and Portfolio Strategy](#11-dotfiles-and-portfolio-strategy)
12. [Troubleshooting](#12-troubleshooting)

---

## 1. Pre-Install Checklist

- [X] USB drive (8GB+) flashed with `debian-13.4.0-amd64-netinst.iso` using Balena Etcher
  - Download from: `https://cdimage.debian.org/cdimage/release/current/amd64/iso-cd/`
- [X] Ethernet adapter plugged in and connected to router
- [X] Wi-Fi password written down
- [X] Second device nearby to reference these steps
- [X] Power adapter plugged in — do not install on battery

---

## 2. Debian Install

### Stage 1 — BIOS Boot

1. Insert USB drive
2. Power on and **immediately press `Esc`** — opens HP startup menu
3. Press **`F9`** for boot device menu
4. Select USB drive and hit `Enter`
5. Debian boot menu — select **`Install`** (plain text, not Graphical Install)

### Stage 2 — Language and Locale

| Prompt | Selection |
|--------|-----------|
| Language | English |
| Location | United States |
| Keyboard | American English |

### Stage 3 — Network Setup

1. Select ethernet interface when prompted — DHCP configures automatically
2. **Hostname:** `thoth`
3. **Domain name:** leave blank

### Stage 4 — Users and Passwords

- Set a strong **root password** and write it down
- Create your **regular user account** — short lowercase username, this appears in your prompt constantly

### Stage 5 — Partitioning

Select **Manual** partitioning. Create a new empty partition table on your SSD, then build four partitions:

| Partition | Size | Type | Use As | Mount Point |
|-----------|------|------|--------|-------------|
| EFI | 512MB | Primary | EFI System Partition | — |
| Root | 40GB | Primary | ext4 | `/` |
| Home | 700GB | Primary | ext4 | `/home` |
| Swap | 8GB | Primary | swap area | — |

Select **Finish partitioning and write changes to disk** — confirm Yes.

> This is the point of no return for the SSD. The separate `/home` partition means you can reinstall the OS later without losing your files.

### Stage 6 — Base System Install

Copies base system from USB automatically. Wait a few minutes.

### Stage 7 — Package Manager / Mirror

| Prompt | Selection |
|--------|-----------|
| Scan another CD/DVD | No |
| Country for mirror | United States |
| Mirror | `deb.debian.org` |
| HTTP proxy | Leave blank |

### Stage 8 — Software Selection (tasksel)

**Critical screen.** Use spacebar to toggle. Target state:

- ✅ `SSH server`
- ✅ `standard system utilities`
- ❌ `Debian desktop environment` — deselect
- ❌ `GNOME` — deselect
- ❌ Everything else

Tab to **Continue**. Downloads and installs — 5 to 15 minutes.

### Stage 9 — GRUB Bootloader

1. Install GRUB to primary drive — Yes
2. Select your SSD as target — `/dev/sda` or similar

### Stage 10 — Finish Installation

1. Select **Continue** — system reboots
2. **Remove the USB drive** as it reboots

### Stage 11 — First Boot

You will see:
```
thoth login: _
```
Log in as your regular user. You should see:
```
yourname@thoth:~$
```

---

## 3. Phase 1 — Base System

Work through every step in order without skipping.

### Step 1 — Install sudo and add yourself to the sudo group

Sudo is not installed by default. Log in as root:

```bash
su -
```

Install sudo and add your user:

```bash
apt update
apt install -y sudo
usermod -aG sudo yourname
exit
```

Log out and back in for the group change to take effect:

```bash
exit
# log back in as your regular user
```

### Step 2 — Verify sudo works

```bash
sudo apt update
```

No permission error means sudo is working.

### Step 3 — Enable non-free repositories

```bash
sudo nano /etc/apt/sources.list
```

Replace the contents with:

```
deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware

deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware

deb http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
```

Save with `Ctrl+O`, `Enter`, `Ctrl+X`.

```bash
sudo apt update
```

### Step 4 — Full system update

```bash
sudo apt upgrade -y
```

### Step 5 — Install kernel headers and build tools

```bash
sudo apt install -y build-essential dkms linux-headers-$(uname -r)
```

### Step 6 — Install NetworkManager

```bash
sudo apt install -y network-manager
```

Verify `/etc/network/interfaces` only contains the loopback — remove anything else:

```bash
cat /etc/network/interfaces
```

Should only show:
```
auto lo
iface lo inet loopback
```

Enable and restart NetworkManager:

```bash
sudo systemctl enable NetworkManager
sudo systemctl restart NetworkManager
```

### Step 7 — Reboot

```bash
sudo reboot
```

### Step 8 — Connect to Wi-Fi

```bash
nmtui
```

1. Select **Activate a connection**
2. Select your network, hit `Enter`, enter password
3. Asterisk `*` next to network name confirms connection
4. `Esc` to exit

Confirm:

```bash
ping -c 3 google.com
```

Three replies means Wi-Fi is working. Unplug ethernet adapter.

### Step 9 — Install Phase 1 essentials

```bash
sudo apt install -y \
    ufw \
    openssh-client openssh-server \
    gnupg \
    git \
    stow \
    curl wget \
    libnotify-bin
```

### Step 10 — Enable firewall

```bash
sudo ufw enable
sudo ufw allow ssh
sudo ufw status
```

### Step 11 — Configure git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
git config --global init.defaultBranch main
```

### Step 12 — Initialize dotfiles repo

```bash
mkdir ~/dotfiles
cd ~/dotfiles
git init
nano README.md
```

Add `# dotfiles` as the first line, save and exit:

```bash
git add .
git commit -m "init: base debian 13 install complete"
```

**Phase 1 complete checkpoint:**
- ✅ Debian 13 installed and updated
- ✅ Non-free repos enabled
- ✅ Wi-Fi working
- ✅ SSH server running
- ✅ Firewall active
- ✅ Git configured
- ✅ Dotfiles repo initialized

---

## 4. Phase 2 — Desktop Foundation

### Install Xorg and i3 stack

```bash
sudo apt install -y \
    xorg \
    i3 i3status \
    picom \
    rofi \
    dunst \
    feh \
    alacritty \
    brightnessctl \
    fontconfig fonts-noto \
    xclip \
    maim
```

### Install Nerd Fonts

Download JetBrains Mono Nerd Font for terminal icons:

```bash
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "JetBrainsMono.zip" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip
unzip JetBrainsMono.zip
rm JetBrainsMono.zip
fc-cache -fv
```

### Create .xinitrc

This file tells `startx` what to launch:

```bash
nano ~/.xinitrc
```

```bash
#!/bin/bash
picom --daemon &
dunst &
feh --bg-scale ~/wallpapers/wallpaper.jpg &
exec i3
```

Create the wallpapers directory:

```bash
mkdir ~/wallpapers
mkdir ~/screenshots
```

### Auto-launch i3 on login

Add to the end of `~/.bash_profile`:

```bash
nano ~/.bash_profile
```

```bash
#!/bin/bash
# ~/.bash_profile
# Sourced on login shell startup

# Source .bashrc if it exists — keeps login and interactive shell configs unified
if [ -f "$HOME/.bashrc" ]; then
    . "$HOME/.bashrc"
fi

# Auto-launch i3 on login from tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
```

### Stow .bash_profile and .bashrc config

```bash
mkdir -p ~/dotfiles/bash
mv ~/.bash_profile ~/dotfiles/bash/.bash_profile
mv ~/.bashrc ~/dotfiles/bash/.bashrc
cd ~/dotfiles && stow bash
git add .
git commit -m "feat: add bash_profile with startx auto-launch and bashrc"
```

### Set up i3 config

```bash
mkdir -p ~/.config/i3
nano ~/.config/i3/config
```

Paste the full i3 config from the [i3 Config Reference](#10-i3-config-reference) section below.

### Stow i3 config into dotfiles

```bash
mkdir -p ~/dotfiles/i3/.config/i3
mv ~/.config/i3/config ~/dotfiles/i3/.config/i3/config
cd ~/dotfiles
stow i3
git add .
git commit -m "feat: add i3 base config with workspace strategy"
```

### Test the desktop

```bash
startx
```

You should land in a bare i3 environment. Press `$mod+Return` (Super+Enter) to open a terminal.

**Phase 2 complete checkpoint:**
- ✅ Xorg installed
- ✅ i3 launching via startx
- ✅ Alacritty opening on keybind
- ✅ i3 config in dotfiles repo

---

## 5. Phase 3 — Terminal Environment

### Install terminal stack

```bash
sudo apt install -y \
    tmux \
    neovim \
    ranger \
    htop \
    ncdu
```

### Install Starship prompt

```bash
curl -sS https://starship.rs/install.sh | sh
```

Add to the end of `~/.bashrc`:

```bash
nano ~/.bashrc
```

```bash
# Better history
HISTSIZE=10000
HISTFILESIZE=20000
shopt -s histappend

# Starship prompt
eval "$(starship init bash)"
```

### Configure Starship

```bash
mkdir -p ~/.config
nano ~/.config/starship.toml
```

```toml
[character]
success_symbol = "[❯](green)"
error_symbol = "[❯](red)"

[git_branch]
symbol = " "

[git_status]
ahead = "⇡${count}"
behind = "⇣${count}"
modified = "!"
untracked = "?"

[nodejs]
symbol = " "

[directory]
truncation_length = 3
truncate_to_repo = true
```

### Configure tmux

```bash
nano ~/.tmux.conf
```

```bash
# Set prefix to Ctrl+a (easier than Ctrl+b)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Split panes with | and -
bind | split-window -h
bind - split-window -v

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Enable mouse
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# 256 color support
set -g default-terminal "screen-256color"

# Increase scrollback buffer
set -g history-limit 10000
```

### Configure Neovim

```bash
mkdir -p ~/.config/nvim
nano ~/.config/nvim/init.vim
```

```vim
" Basic settings
set number relativenumber
set tabstop=4 shiftwidth=4 expandtab
set hlsearch incsearch
set clipboard=unnamedplus
set wrap linebreak
set scrolloff=8

" Use system clipboard
set clipboard+=unnamedplus

" Better splits
set splitbelow splitright

" Key mappings
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>e :Explore<CR>

" Navigate splits with Ctrl+hjkl
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
```

### Stow terminal configs into dotfiles

```bash
# Bash
mkdir -p ~/dotfiles/bash
cp ~/.bashrc ~/dotfiles/bash/.bashrc
# Remove original and stow
rm ~/.bashrc
cd ~/dotfiles && stow bash

# Starship
mkdir -p ~/dotfiles/starship/.config
mv ~/.config/starship.toml ~/dotfiles/starship/.config/starship.toml
stow starship

# tmux
mkdir -p ~/dotfiles/tmux
mv ~/.tmux.conf ~/dotfiles/tmux/.tmux.conf
stow tmux

# Neovim
mkdir -p ~/dotfiles/neovim/.config/nvim
mv ~/.config/nvim/init.vim ~/dotfiles/neovim/.config/nvim/init.vim
stow neovim

git add .
git commit -m "feat: add terminal stack — bash, starship, tmux, neovim, ranger"
```

**Phase 3 complete checkpoint:**
- ✅ tmux installed and configured
- ✅ Neovim configured with vim keybindings
- ✅ Ranger available as terminal file manager
- ✅ Starship prompt active
- ✅ All configs in dotfiles repo

---

## 6. Phase 4 — Audio and Bluetooth

### Install PipeWire audio stack

```bash
sudo apt install -y \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    pavucontrol
```

Enable PipeWire for your user:

```bash
systemctl --user enable pipewire pipewire-pulse wireplumber
systemctl --user start pipewire pipewire-pulse wireplumber
```

Verify audio is working:

```bash
pactl info
```

Should return PipeWire server info.

### Install Bluetooth

```bash
sudo apt install -y bluez blueman
sudo systemctl enable bluetooth
sudo systemctl start bluetooth
```

Connect devices via CLI:

```bash
bluetoothctl
# Inside bluetoothctl:
power on
scan on
# Note the MAC address of your device
pair XX:XX:XX:XX:XX:XX
connect XX:XX:XX:XX:XX:XX
trust XX:XX:XX:XX:XX:XX
exit
```

**Phase 4 complete checkpoint:**
- ✅ PipeWire audio working
- ✅ Volume keys functional in i3
- ✅ Bluetooth stack installed

---

## 7. Phase 5 — Applications

### Firefox

```bash
sudo apt install -y firefox-esr
```

### Sublime Text

Add the official Sublime repo:

```bash
wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg \
    | gpg --dearmor \
    | sudo tee /etc/apt/trusted.gpg.d/sublimehq-archive.gpg > /dev/null

echo "deb https://download.sublimetext.com/ apt/stable/" \
    | sudo tee /etc/apt/sources.list.d/sublime-text.list

sudo apt update
sudo apt install -y sublime-text
```

### VSCode

Add the official Microsoft repo:

```bash
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /etc/apt/trusted.gpg.d/packages.microsoft.gpg > /dev/null

echo "deb [arch=amd64] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list

sudo apt update
sudo apt install -y code
```

### GitHub CLI

```bash
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
    https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list

sudo apt update
sudo apt install -y gh
```

Authenticate:

```bash
gh auth login
```

Push your dotfiles repo to GitHub:

```bash
cd ~/dotfiles
gh repo create dotfiles --public --source=. --push
```

### Remaining applications

```bash
sudo apt install -y \
    thunar \
    mpv \
    zathura zathura-pdf-poppler
```

### Fastfetch

```bash
sudo apt install -y fastfetch
```

If not found in repos, install from GitHub releases:

```bash
curl -fsSL https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb \
    -o /tmp/fastfetch.deb
sudo dpkg -i /tmp/fastfetch.deb
```

Configure fastfetch:

```bash
mkdir -p ~/.config/fastfetch
fastfetch --gen-config
nano ~/.config/fastfetch/config.jsonc
```

Add fastfetch to `~/.bashrc` so it fires on every terminal open:

```bash
echo 'fastfetch' >> ~/.bashrc
```

Stow fastfetch config:

```bash
mkdir -p ~/dotfiles/fastfetch/.config/fastfetch
mv ~/.config/fastfetch/config.jsonc \
    ~/dotfiles/fastfetch/.config/fastfetch/config.jsonc
cd ~/dotfiles && stow fastfetch
git add .
git commit -m "feat: add applications layer — firefox, sublime, vscode, fastfetch"
```

**Phase 5 complete checkpoint:**
- ✅ Firefox installed
- ✅ Sublime Text installed
- ✅ VSCode installed
- ✅ GitHub CLI authenticated
- ✅ Dotfiles repo pushed to GitHub
- ✅ Fastfetch configured

---

## 8. Phase 6 — Development Environment

### Install nvm and Node

Do not use apt for Node — nvm gives you version control:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

nvm install --lts
nvm use --lts

# Verify
node --version
npm --version
```

### Install Claude Code

```bash
npm install -g @anthropic/claude-code
```

Authenticate on first run — have Firefox ready as it will open a browser window:

```bash
claude
```

### Set up GPG for signed commits

```bash
gpg --full-generate-key
# Choose RSA 4096, no expiry, enter your name and email

# List your key to get the ID
gpg --list-secret-keys --keyid-format=long

# Configure git to use it — replace KEYID with your key ID
git config --global user.signingkey KEYID
git config --global commit.gpgsign true

# Export public key to add to GitHub
gpg --armor --export KEYID
# Copy the output and add it to GitHub Settings → SSH and GPG keys
```

### Set up SSH key for GitHub

```bash
ssh-keygen -t ed25519 -C "your@email.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Copy public key and add to GitHub Settings → SSH keys
cat ~/.ssh/id_ed25519.pub
```

Update your dotfiles remote to use SSH:

```bash
cd ~/dotfiles
git remote set-url origin git@github.com:yourusername/dotfiles.git
```

**Phase 6 complete checkpoint:**
- ✅ Node LTS installed via nvm
- ✅ Claude Code installed and authenticated
- ✅ GPG signing configured
- ✅ SSH key added to GitHub
- ✅ Dotfiles repo using SSH remote

---

## 9. Phase 7 — Polish

### Install Polybar

```bash
sudo apt install -y polybar
```

Create polybar config:

```bash
mkdir -p ~/.config/polybar
nano ~/.config/polybar/config.ini
```

Basic config to start with:

```ini
[bar/main]
width = 100%
height = 24
background = #222222
foreground = #ffffff
font-0 = JetBrainsMono Nerd Font:size=10
modules-left = i3
modules-center = date
modules-right = pulseaudio battery

[module/i3]
type = internal/i3
format = <label-state> <label-mode>

[module/date]
type = internal/date
interval = 1
date = %Y-%m-%d %H:%M

[module/pulseaudio]
type = internal/pulseaudio
format-volume = VOL <bar-volume>

[module/battery]
type = internal/battery
battery = BAT0
adapter = AC
```

Update your i3 config to launch polybar instead of i3status — replace the `bar { }` block with:

```bash
exec_always --no-startup-id $HOME/.config/polybar/launch.sh
```

Create launch script:

```bash
nano ~/.config/polybar/launch.sh
```

```bash
#!/bin/bash
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done
polybar main &
```

```bash
chmod +x ~/.config/polybar/launch.sh
```

### Install picom config

```bash
mkdir -p ~/.config/picom
nano ~/.config/picom/picom.conf
```

```conf
# Basic transparency and shadows
shadow = true
shadow-radius = 10
shadow-opacity = 0.4

# Transparency
inactive-opacity = 0.95
active-opacity = 1.0

# Rounded corners
corner-radius = 8

# Fade
fading = true
fade-in-step = 0.03
fade-out-step = 0.03

# Backend
backend = "glx"
vsync = true
```

### Install GTK theme tools

```bash
sudo apt install -y lxappearance
```

Download and install Papirus icon theme:

```bash
sudo apt install -y papirus-icon-theme
```

Launch `lxappearance` from rofi to set your GTK theme and icons visually.

### Install screen recording for README gifs

```bash
sudo apt install -y peek
```

Or use ffmpeg for more control:

```bash
sudo apt install -y ffmpeg

# Record screen to gif
ffmpeg -video_size 1920x1080 -framerate 15 \
    -f x11grab -i :0.0 \
    -vf "fps=15,scale=1280:-1:flags=lanczos" \
    output.gif
```

### Stow remaining configs

```bash
# Polybar
mkdir -p ~/dotfiles/polybar/.config/polybar
mv ~/.config/polybar/* ~/dotfiles/polybar/.config/polybar/
cd ~/dotfiles && stow polybar

# Picom
mkdir -p ~/dotfiles/picom/.config/picom
mv ~/.config/picom/picom.conf ~/dotfiles/picom/.config/picom/picom.conf
stow picom

# Fastfetch (if not already done)
mkdir -p ~/dotfiles/fastfetch/.config/fastfetch
stow fastfetch

git add .
git commit -m "feat: polish layer — polybar, picom, gtk theme, icons"
```

**Phase 7 complete — build finished.**

---

## 10. i3 Config Reference

Full i3 config for `~/.config/i3/config`:

```bash
# ─── MODIFIER KEY ─────────────────────────────────────────────
set $mod Mod4

# ─── FONT ─────────────────────────────────────────────────────
font pango:JetBrainsMono Nerd Font 10

# ─── TERMINAL ─────────────────────────────────────────────────
set $term alacritty

# ─── WORKSPACE NAMES ──────────────────────────────────────────
set $ws1  "1: term"
set $ws2  "2: web"
set $ws3  "3: code"
set $ws4  "4: files"
set $ws5  "5: comms"
set $ws6  "6: media"
set $ws7  "7: claude"
set $ws8  "8: monitor"
set $ws9  "9: scratch"
set $ws10 "10: config"

# ─── LAUNCH KEYBINDS ──────────────────────────────────────────
bindsym $mod+Return       exec $term
bindsym $mod+d            exec rofi -show drun
bindsym $mod+shift+d      exec rofi -show run

# ─── WORKSPACE SWITCHING ──────────────────────────────────────
bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9
bindsym $mod+0 workspace $ws10

# ─── MOVE WINDOW TO WORKSPACE ─────────────────────────────────
bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9
bindsym $mod+Shift+0 move container to workspace $ws10

# ─── ASSIGN APPS TO WORKSPACES ────────────────────────────────
assign [class="Firefox"]          $ws2
assign [class="Code"]             $ws3
assign [class="Sublime_text"]     $ws3
assign [class="Thunar"]           $ws4
assign [class="mpv"]              $ws6

# ─── WINDOW NAVIGATION ────────────────────────────────────────
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# ─── LAYOUT CONTROLS ──────────────────────────────────────────
bindsym $mod+e layout toggle split
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+f fullscreen toggle
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle
bindsym $mod+b split h
bindsym $mod+v split v

# ─── WINDOW MANAGEMENT ────────────────────────────────────────
bindsym $mod+Shift+q kill
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart

# ─── RESIZE MODE ──────────────────────────────────────────────
mode "resize" {
    bindsym h resize shrink width  10 px or 10 ppt
    bindsym j resize grow   height 10 px or 10 ppt
    bindsym k resize shrink height 10 px or 10 ppt
    bindsym l resize grow   width  10 px or 10 ppt
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+r mode "resize"

# ─── BRIGHTNESS ───────────────────────────────────────────────
bindsym XF86MonBrightnessUp   exec brightnessctl set +10%
bindsym XF86MonBrightnessDown exec brightnessctl set 10%-

# ─── AUDIO ────────────────────────────────────────────────────
bindsym XF86AudioRaiseVolume  exec pactl set-sink-volume @DEFAULT_SINK@ +5%
bindsym XF86AudioLowerVolume  exec pactl set-sink-volume @DEFAULT_SINK@ -5%
bindsym XF86AudioMute         exec pactl set-sink-mute   @DEFAULT_SINK@ toggle

# ─── SCREENSHOTS ──────────────────────────────────────────────
bindsym Print       exec maim ~/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png
bindsym $mod+Print  exec maim -s ~/screenshots/$(date +%Y-%m-%d_%H-%M-%S).png

# ─── GAPS ─────────────────────────────────────────────────────
gaps inner 8
gaps outer 4
smart_gaps on

# ─── WINDOW BORDERS ───────────────────────────────────────────
default_border pixel 2
smart_borders on

# ─── COLORS ───────────────────────────────────────────────────
client.focused          #4c7899 #285577 #ffffff #2e9ef4
client.unfocused        #222222 #222222 #888888 #292d2e
client.urgent           #2f343a #900000 #ffffff #900000

# ─── STATUS BAR ───────────────────────────────────────────────
bar {
    status_command i3status
    position top
    colors {
        background #222222
        statusline #ffffff
        focused_workspace  #4c7899 #285577 #ffffff
        inactive_workspace #222222 #222222 #888888
    }
}

# ─── AUTOSTART ────────────────────────────────────────────────
exec --no-startup-id nm-applet
exec --no-startup-id dunst
exec --no-startup-id picom --daemon
exec_always --no-startup-id feh --bg-scale ~/wallpapers/wallpaper.jpg
```

### Workspace Reference

| Workspace | Key | Purpose | Primary App |
|-----------|-----|---------|-------------|
| 1 | `$mod+1` | Terminal / General | Alacritty + tmux |
| 2 | `$mod+2` | Browser | Firefox |
| 3 | `$mod+3` | Editor | VSCode or Neovim |
| 4 | `$mod+4` | File Management | Ranger or Thunar |
| 5 | `$mod+5` | Communication | Email, chat |
| 6 | `$mod+6` | Media | mpv, zathura |
| 7 | `$mod+7` | Dev / Claude Code | Alacritty dedicated |
| 8 | `$mod+8` | Monitoring | htop, system tools |
| 9 | `$mod+9` | Scratch / Misc | Overflow |
| 10 | `$mod+0` | Settings / Config | Config file editing |

### Essential Keybinds Reference

| Keybind | Action |
|---------|--------|
| `$mod+Return` | Open terminal |
| `$mod+d` | App launcher (rofi) |
| `$mod+Shift+q` | Close window |
| `$mod+h/j/k/l` | Focus left/down/up/right |
| `$mod+Shift+h/j/k/l` | Move window |
| `$mod+f` | Fullscreen toggle |
| `$mod+b` | Split horizontal |
| `$mod+v` | Split vertical |
| `$mod+r` | Resize mode |
| `$mod+Shift+c` | Reload i3 config |
| `$mod+Shift+r` | Restart i3 |
| `Print` | Screenshot |
| `$mod+Print` | Screenshot selection |

---

## 11. Dotfiles and Portfolio Strategy

### Repo Structure

```
dotfiles/
├── README.md
├── install.sh
├── bash/
│   └── .bashrc
├── starship/
│   └── .config/
│       └── starship.toml
├── i3/
│   └── .config/
│       └── i3/
│           └── config
├── alacritty/
│   └── .config/
│       └── alacritty/
│           └── alacritty.toml
├── neovim/
│   └── .config/
│       └── nvim/
│           └── init.vim
├── tmux/
│   └── .tmux.conf
├── polybar/
│   └── .config/
│       └── polybar/
├── picom/
│   └── .config/
│       └── picom/
│           └── picom.conf
├── fastfetch/
│   └── .config/
│       └── fastfetch/
│           └── config.jsonc
└── docs/
    ├── setup-guide.md
    ├── keybindings.md
    ├── package-list.md
    └── screenshots/
```

### Commit Message Convention

```bash
feat: add i3 base config with workspace strategy
fix: blacklist conflicting network modules
feat: configure starship prompt with git status
docs: add screenshot of neovim + ranger split
refactor: consolidate alacritty colors into theme file
```

### install.sh Bootstrap Script

Build this out progressively as you complete each phase:

```bash
#!/bin/bash
set -e

echo "Installing base packages..."
sudo apt update && sudo apt install -y \
    git stow curl wget \
    i3 i3status rofi dunst picom \
    alacritty tmux neovim ranger \
    firefox-esr thunar \
    htop ncdu zathura feh \
    network-manager \
    libnotify-bin brightnessctl \
    xclip maim \
    pipewire pipewire-pulse wireplumber \
    bluez blueman \
    ufw \
    fastfetch

echo "Setting up dotfiles..."
cd ~/dotfiles
stow bash starship i3 alacritty neovim tmux polybar picom fastfetch

echo "Installing nvm + Node..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install --lts

echo "Installing Claude Code..."
npm install -g @anthropic/claude-code

echo "Installing Starship..."
curl -sS https://starship.rs/install.sh | sh

echo "Done."
```

### README.md Must-Haves

- Screenshot or GIF at the very top showing i3 with tmux, neovim, and ranger tiled
- Hardware context — "built on an HP i5-7200U"
- Package list with one-line purpose for each entry
- Keybinding reference
- Link to bootstrap `install.sh`

GitHub tags to add to the repo: `dotfiles`, `i3`, `debian`, `linux`, `ricing`, `tiling-window-manager`

---

## 12. Troubleshooting

### Install Issues

| Problem | Fix |
|---------|-----|
| Boot picker never appears | Press `Esc` from the very first moment of power on |
| USB not in boot device menu | Re-flash with Balena Etcher, try different USB port |
| No ethernet during install | Try a different USB ethernet adapter |
| apt update fails after sources.list edit | Check spacing and spelling — one typo breaks it |

### Network Issues

| Problem | Fix |
|---------|-----|
| NetworkManager service not found | Case sensitive — use `NetworkManager` not `network-manager` |
| NetworkManager fails to start | Check `/etc/network/interfaces` for conflicting entries |
| Wi-Fi not showing in nmtui | `sudo systemctl restart NetworkManager` then retry |
| ping fails after Wi-Fi connect | `ip addr` — confirm interface has an IP assigned |

### System Issues

| Problem | Fix |
|---------|-----|
| sudo not working after usermod | Log out and back in — group changes need fresh login |
| startx fails | Check `~/.xinitrc` exists and is executable — `chmod +x ~/.xinitrc` |
| i3 not launching | Check Xorg is installed — `sudo apt install -y xorg` |
| No sound | `systemctl --user status pipewire` — restart if not running |
| Brightness keys not working | `sudo apt install -y brightnessctl` and check i3 keybinds |
| Fonts look broken | Run `fc-cache -fv` after installing Nerd Fonts |

---

*Hostname: thoth — HP i5-7200U — Intel HD 620 — 8GB RAM — 1TB SSD*  
*OS: Debian 13 Trixie*  
*Build: terminal-first i3 environment*  
*Created as part of custom Linux build project*
