# Arch Linux Configuration

## Services to enable after install

### As root

```shell
sudo systemctl enable --now keyd.service
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now reflector.service
sudo systemctl enable --now sddm.service
sudo systemctl enable --now seatd.service
```

### As user

```shell
systemctl enable --user --now docker.service
systemctl enable --user --now hypridle.service
systemctl enable --user --now hyprpaper.service
systemctl enable --user --now pipewire.service
systemctl enable --user --now waybar.service
systemctl enable --user --now wireplumber.service
```
