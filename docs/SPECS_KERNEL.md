---

# ⚙️ Page 2: `FIREFLY-KERNEL-GPU.md` — Kernel, OpenZFS, NVIDIA & CUDA Spec

```markdown
# ⚡ Project Firefly — Kernel, OpenZFS & GPU/Compute Stack Specification

![Kernel](https://img.shields.io/badge/Kernel-Linux%207.2.15%20%2B%20Rust-orange?style=flat-square)
![ZFS](https://img.shields.io/badge/OpenZFS-Built--in%20%2B%20Userland-green?style=flat-square)
![CUDA](https://img.shields.io/badge/CUDA-sm__60%20%26%20sm__86-76b900?style=flat-square)
![Compute](https://img.shields.io/badge/Compute-AOCC%20%2B%20ZenDNN%20%2B%20OpenMP-red?style=flat-square)

---

## 1. Custom Linux 7.2.15 Kernel (`KERNEL.cf`)

### Kernel Build Specifications
* **Source:** Linux `v7.2.15` stable tree with **Rust for Linux** enabled (`CONFIG_RUST=y`).
* **Rust Toolchain:** Installed dynamically via `rustup` matching `scripts/min-tool-version.sh rustc` plus the `rust-src` component (`bindgen-cli`, `clang-devel`, and `dwarves` required).
* **OpenZFS Integration:** Injected directly into the kernel source tree (`./configure LLVM=1 --enable-linux-builtin` -> `./copy-builtin /build/linux`) so ZFS compiles straight into `vmlinuz` (`CONFIG_ZFS=y`) without DKMS or external `.ko` rebuilds.
* **Filesystems:** `CONFIG_BTRFS_FS=y` and `CONFIG_BTRFS_FS_POSIX_ACL=y` compiled built-in (`=y`) for zero-friction `btrfs` rootfs boot.

> [!CAUTION]
> **Keep userspace aggressive flags out of `KCFLAGS`!**
> Never pass `-flto=full`, `-ffast-math`, `-zopt`, or `-fveclib=AMDLIBM` into `KCFLAGS` or `KBUILD_LDFLAGS`. Ring-0 kernel code relies on strict IEEE/integer semantics and kernel-specific linker scripts. Stick strictly to:
> ```bash
> make LLVM=1 KCFLAGS="-O3 -march=znver3 -mtune=znver3" KBUILD_LDFLAGS="-fuse-ld=lld" -j"$(nproc)"
> ```

### Kernel Export Payload (`/out`)
```text
/out/
├── boot/
│   ├── vmlinuz-7.2.15-...
│   ├── System.map-7.2.15-...
│   └── config-7.2.15-...
├── lib/
│   └── modules/7.2.15-.../        # Merged into /usr/lib/modules/ in bootc
└── usr/

