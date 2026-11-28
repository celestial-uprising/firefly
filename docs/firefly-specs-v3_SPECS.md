# Project Firefly — Userland Package Container Specification

Target: x86_64 AMD Zen 3 (znver3)
Base: Fedora 44
Compiler & Linker: AOCC 6.0 (aoc / aoc++ / LLVM ld.lld / LLVM binutils)
Export Stage: Pure artifact payload via FROM scratch AS export

---

## 1. Core Architectural Rules

- Install Prefix: Always use --prefix=/usr (or -DCMAKE_INSTALL_PREFIX=/usr) with DESTDIR=/out so artifacts land in standard Fedora 44 /usr locations rather than /usr/local.
- No Root-Level Dumping: Never pass --prefix=/out alone; build systems that treat prefix as the final root will emit /out/bin, /out/share, or /out/systemd instead of /out/usr/....
- Toolchain & Math Library: Use AOCC 6.0 (aoc / aoc++), ld.lld, and LLVM binutils (llvm-ar, llvm-ranlib, llvm-nm, llvm-strip) with AMDLIBM (-fveclib=AMDLIBM and -l:libamdlibm.a) on supported userspace C/C++ builds.
- Static-First Linking for Minimal Runtime Dependencies: Prefer static linking for C++/compiler/math runtimes (-static-libstdc++, -static-libgcc, static archives where supported, and Meson --prefer-static / linker -Bstatic ... -Bdynamic where safe) while keeping glibc dynamic (libc.so.6 / libm.so.6) to preserve Fedora 44 nsswitch and dlopen/plugin compatibility.
- Diagnostic Safety: Avoid calling external tools such as file inside post-install checks unless explicitly installed; inspect ELF headers via readelf -d or magic bytes directly.
- Binary Stripping & Cleanup: Remove build-only headers/pkgconfig directories when not needed by downstream builds, normalize /out/usr/sbin into /out/usr/bin, and strip ELF binaries and shared objects using llvm-strip --strip-unneeded inside the compiler stage.
- Final Stage Contract: Export via FROM scratch AS export with COPY --from=compiler /out/ / so no build tools, DNF caches, or intermediate layers leak into the artifact image.

---

## 2. Standard Directory Contract (/out)

All files exported from compiler into scratch must conform to Fedora 44 usrmerge layout under /out:

/out/
└── usr/
    ├── bin/                  # Executables (NEVER /out/bin or /out/usr/sbin)
    ├── include/              # Headers (only when needed by downstream builds)
    ├── lib/
    │   ├── systemd/
    │   │   ├── system/       # System unit files
    │   │   └── user/         # User unit files
    │   └── udev/rules.d/     # udev rules
    ├── lib64/                # Shared libraries (*.so*)
    └── share/                # Desktop files, icons, manpages, Wayland sessions, themes
