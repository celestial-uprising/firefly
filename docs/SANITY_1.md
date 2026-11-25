podman run --rm localhost/bella:latest sh -c '
bins=(niri waybar rofi kitty mpv ffmpeg zathura btop git nvim fd eza gdu dive skopeo crun zpool zfs)
for b in "${bins[@]}"; do
  p="$(command -v "$b" 2>/dev/null || true)"
  [ -n "$p" ] && [ -x "$p" ] && printf "OK   \%-14s -> \%s\n" "$b" "$p" \vert{}\vert{} printf "MISS \%-14s\n" "$b"
done
'
