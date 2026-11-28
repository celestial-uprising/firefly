# Project Firefly — Kernel, OpenZFS & GPU/Compute Stack Specification

Kernel Target: Linux 7.2.15 (C + Rust for Linux with CONFIG_RUST=y)
Filesystems: Built-in Btrfs (CONFIG_BTRFS_FS=y, CONFIG_BTRFS_FS_POSIX_ACL=y) and built-in OpenZFS (CONFIG_ZFS=y via ./configure LLVM=1 --enable-linux-builtin and ./copy-builtin)
GPU & Compute Stack: CUDA (60-real;86-real), AOCC 6.0, ZenDNN, OpenMP, mimalloc

---

## 1. Kernel Build & Export Rules

- Isolate kernel flags to KCFLAGS="-O3 -march=znver3 -mtune=znver3" and KBUILD_LDFLAGS="-fuse-ld=lld" with LLVM=1.
- Never pass userspace -flto=full, -ffast-math, -zopt, -fveclib=AMDLIBM, or -l:libamdlibm.a into kernel builds.
- For Rust kernel modules, install the rustup toolchain matching scripts/min-tool-version.sh rustc along with rust-src, bindgen-cli, clang-devel, and dwarves.
- Export /boot (vmlinuz, System.map, config) and /lib/modules/7.2.15-... (merged into /usr/lib/modules/ in bootc).
