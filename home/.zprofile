# Display-manager-free login: tty1 starts Hyprland, tty2 starts sway.
SWAY_TTY=2
HYPRLAND_TTY=1

if [[ -z "$WAYLAND_DISPLAY" && -z "$DISPLAY" ]]; then
  export XDG_SESSION_TYPE=wayland
  export GDK_SCALE=1
  export GDK_DPI_SCALE=1
  export QT_AUTO_SCREEN_SCALE_FACTOR=1
  export QT_ENABLE_HIGHDPI_SCALING=1

  case "$XDG_VTNR" in
    $SWAY_TTY)     export XDG_CURRENT_DESKTOP=sway;     exec sway ;;
    $HYPRLAND_TTY) export XDG_CURRENT_DESKTOP=Hyprland; exec start-hyprland ;;
  esac
fi
