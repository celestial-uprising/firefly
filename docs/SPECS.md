# 🔥 Project Firefly — Userland Package Container Specification

![Target](https://img.shields.io/badge/Target-x86__64%20Zen%203-blue?style=flat-square)
![Base](https://img.shields.io/badge/Base-Fedora%2044-51a2da?style=flat-square)
![Compiler](https://img.shields.io/badge/Compiler-AOCC%206.0%20%2B%20LLD-red?style=flat-square)
![Export](https://img.shields.io/badge/Export-FROM%20scratch-black?style=flat-square)

> [!IMPORTANT]
> Every generic `firefly:<PKG>` image is a **pure artifact payload** exported `FROM scratch`. It must never ship a full OS rootfs, package manager cache, or `/usr/local` hierarchy.

---

## 1. Core Architectural Rules

| Rule | Requirement | Rationale |
| :--- | :--- | :--- |
| **Install Prefix** | `--prefix=/usr` with `DESTDIR=/out` | Prevents split `/usr/local` paths and keeps all binaries/libs in standard `bootc` locations. |
| **No Root-Level Dumping** | Never use `--prefix=/out` alone | Avoids emitting `/bin`, `/share`, or `/systemd` at `/` instead of `/usr/bin`, `/usr/share`, and `/usr/lib/systemd`. |
| **Toolchain** | AOCC 6.0 (`aoc` / `aoc++`) + `ld.lld` | Maximizes Zen 3 (`znver3`) vectorization, LTO, and `AMDLIBM` math routines. |
| **Binary Stripping** | `llvm-strip --strip-unneeded` | Cuts image bloat before exporting to `scratch`. |
| **Final Stage** | `FROM scratch AS export` | Keeps build dependencies out of the registry and enables clean multi-stage merging into `bella.cf`. |

---

## 2. Standard Directory Contract (`/out`)

All files exported from `compiler` into `scratch` **must** conform to Fedora `usrmerge` layout under `/out`:

```text
/out/
└── usr/
    ├── bin/                  # Executables (NEVER /out/bin or /out/usr/sbin)
    ├── include/              # Headers (only if needed by downstream builds)
    ├── lib/
    │   ├── systemd/
    │   │   ├── system/       # System unit files
    │   │   └── user/         # User unit files
    │   └── udev/rules.d/     # udev rules
    ├── lib64/                # Shared libraries (*.so*)
    └── share/                # Desktop files, icons, manpages, Wayland sessions, themes

```text

