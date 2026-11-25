podman run --rm localhost/bella:latest sh -c '
KVER=$(ls /usr/lib/modules | head -n 1)
ls -lh "/usr/lib/modules/${KVER}/vmlinuz" "/usr/lib/modules/${KVER}/initramfs.img" 2>/dev/null || true
grep -E "^CONFIG_(BTRFS_FS|ZFS|RUST)=" /usr/src/kernels/${KVER}/.config
'
