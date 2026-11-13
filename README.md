# Arch Linux Configuration

Dotfiles live in `home/` and are linked into `~` with GNU Stow. The package list is `pkglist.txt`.

## Restore a machine

### 1. Install packages

`pkglist.txt` holds repo and AUR packages, so use `paru`, not `pacman`.

```shell
paru -S --needed - < pkglist.txt
```

The list comes from the desktop. Remove desktop-only entries first on other machines. Examples: `openrazer-daemon`, `polychromatic`, and the AMD or Intel driver packages that do not match the GPU.

The `pkglist.hook` pacman hook rewrites `pkglist.txt` after each install or removal. Review `git diff pkglist.txt` before you commit it.

### 2. Link the dotfiles

```shell
stow -d /myspace/workspace/archlinux-install -t ~ home
```

Stow stops on a conflict when `~/.config/<name>` or a dotfile already exists as a real file. Move the existing file aside, then run Stow again.

### 3. Enable services

#### As root

```shell
sudo systemctl enable --now keyd.service
sudo systemctl enable --now bluetooth.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now NetworkManager-dispatcher.service
sudo systemctl enable --now reflector.service
sudo systemctl enable --now tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable --now fstrim.timer
```

Desktop only: enable the GPU clock fix. See [Desktop fixes](#desktop-fixes).

#### As user

```shell
systemctl enable --user --now docker.service
systemctl enable --user --now elephant.service
systemctl enable --user --now hypridle.service
systemctl enable --user --now mako.service
systemctl enable --user --now openrazer-daemon.service
systemctl enable --user --now pipewire.socket pipewire-pulse.socket
systemctl enable --user --now wireplumber.service
systemctl enable --user --now gnome-keyring-daemon.socket
```

Do not enable `waybar` or `wpaperd` as services. `hyprland.lua` starts them. Do not enable `hyprpaper`. The config uses `wpaperd`.

`elephant.service` is the backend for `walker`. Create it with `elephant service enable`. The unit lands in `~/.config/systemd/user/`, outside this repo.

### 4. Log in without a display manager

There is no display manager. Log in on a text console. `~/.zprofile` then starts a session:

- tty1 starts Hyprland.
- tty2 starts sway. Press Ctrl+Alt+F2.

```shell
sudo systemctl disable lightdm.service
sudo systemctl set-default multi-user.target
```

Hyprland needs the second command. Without it the machine waits for a display manager. To go back, run `sudo systemctl enable lightdm.service` and `sudo systemctl set-default graphical.target`.

## Desktop fixes

These fixes apply to the desktop with the Radeon PRO WX 2100 (Polaris) and two 2560x1440 monitors.

### Screen bands (GPU memory clock)

Symptom: a horizontal band flashes across the screen for a second at random. It happens on sway and Hyprland. The kernel log shows no error.

Cause: the card switches its memory clock between 300, 625 and 1500 MHz. Forcing the highest clocks stops the bands. The cost is higher idle power and about 48 C.

Fix: force the high performance level at boot with a systemd service. A `udev` rule does not work, because the driver is not ready when the rule runs.

```shell
sudo tee /etc/systemd/system/amdgpu-high.service <<'EOF'
[Unit]
Description=Force amdgpu high performance level

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo high > /sys/bus/pci/devices/0000:07:00.0/power_dpm_force_performance_level'

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable --now amdgpu-high.service
```

The PCI address `0000:07:00.0` is this GPU. Check it with `lspci -nn | grep VGA`. Verify with `cat /sys/class/drm/card1/device/power_dpm_force_performance_level`. It must print `high`.

Do not apply this on the laptop. It is a desktop-only fix.

### Keyboard dead after login from LightDM

Symptom: Hyprland started from LightDM did not accept keyboard input. The same session worked when started from a text console.

Fix: remove LightDM and log in on a text console. See [Log in without a display manager](#4-log-in-without-a-display-manager).

### Hyprland config format

Hyprland 0.57 reads only Lua. The config is `home/.config/hypr/hyprland.lua`. A `.conf` file is ignored.

Check a change without a session:

```shell
timeout -s KILL 15 Hyprland --verify-config
```

It must print `config ok`. Bind arguments are checked only at runtime. Use `hyprctl eval '<lua>'` to test a setting in a running session.

### Launcher

`Super+D` runs `walker`. It needs the `elephant` service and the `elephant-*-bin` plugin packages. `Super+Ctrl+C` opens clipboard history in `walker`.

### Window rules

- Chrome picture-in-picture and the Google Meet popup float in the bottom-right corner. The rule matches the window title. If the popup still tiles, find its title with `swaymsg -t get_tree` or `hyprctl clients`.
- The OpenWhispr overlay (class `open-whispr`) has no border, shadow, blur, rounding or opacity. Without this rule, the shadow and blur draw a box around the icon.
- A floating window is centered.

### Wallpapers

`wpaperd` rotates the images in `home/.config/wpaperd/wallpapers/` every 10 minutes. The SVG sources are in `home/.config/wpaperd/wallpapers-svg/`. Render one with `rsvg-convert -w 3840 NAME.svg -o NAME.png`.

`gowall convert IMAGE -t catppuccin` recolors an image to the Catppuccin palette.

### Image viewer

`swayimg .` opens a folder. `h` and `Left` show the previous image. `l` and `Right` show the next image. A horizontal two-finger swipe also switches images.

## Other machines

Check these before you use the Hyprland config on the laptop:

- `hyprland.lua` sets `LIBVA_DRIVER_NAME` and `VDPAU_DRIVER` to `radeonsi`. This is correct for AMD only. Remove both lines on an Intel GPU.
- The monitor rules name `DP-2` and `DP-3`. The built-in screen uses the catch-all rule. Set a scale for a high-DPI panel.
