---

# 🧭 Page 4: `FIREFLY-FIELD-NOTES.md` — Roadblocks, Clues & Reference Guide

```markdown
# 🛠️ Project Firefly — Field Notes, Roadblocks & Diagnostic Playbook

![Status](https://img.shields.io/badge/Docs-Living%20Runbook-purple?style=flat-square)
![Scope](https://img.shields.io/badge/Scope-Build%2C%20Lint%20%26%20Boot-teal?style=flat-square)

> [!TIP]
> Keep this file handy when adding new `firefly:<PKG>` images, bumping kernel versions, or debugging `bootc container lint` and `dive` regressions.

---

## 1. Known Roadblocks & Exact Fixes

### ❌ Roadblock 1: `cp: cannot overwrite non-directory '/./usr/sbin' with directory`
* **Cause:** On Fedora 44, `/bin`, `/sbin`, `/lib`, `/lib64`, and `/usr/sbin` are symlinks (`usr/bin`, `usr/sbin`, `usr/lib`, `usr/lib64`, and `bin`). `cp -a` refuses to merge a directory onto a symlink.
* **Fix:** Always normalize `/bin`, `/sbin`, `/lib`, `/lib64`, and `/usr/sbin` in staging *before* copying to `/`, or resolve symlink destinations with `readlink -f`.

### ❌ Roadblock 2: `--prefix=/out` Dumping `/bin` and `/share` at `/`
* **Cause:** Passing `--prefix=/out` instead of `--prefix=/usr` with `DESTDIR=/out` causes build systems to install `share/wayland-sessions`, `share/icons`, `share/rofi`, and `systemd/user` directly under `/out/...` instead of `/out/usr/...`.
* **Fix:** Use `--prefix=/usr` + `DESTDIR=/out` in new `PKG.cf` files, and keep the fallback normalizer in `bella.cf` for existing images.

### ❌ Roadblock 3: Running `RUN` Commands Inside `FROM scratch`
* **Cause:** `FROM scratch` contains zero binaries—not even `/bin/sh`. Any `RUN` instruction in a `scratch` stage will fail immediately.
* **Fix:** Perform all file moves, stripping, and symlink checks inside a Fedora-based `compiler` or `stage-prep` stage, then use `FROM scratch` strictly for `COPY --from=...`.

### ❌ Roadblock 4: `bootc container lint` `var-tmpfiles` Warnings
* **Cause:** `bootc` expects `/var` to be clean or backed by `systemd-tmpfiles` rules. Leftover `/var/cache/libdnf5`, `/var/cache/ccache`, `/var/log/*`, or `/var/lib/dkms` triggers `var-tmpfiles` warnings.
* **Fix:** Wipe `/var/cache/*`, `/var/log/*`, `/var/tmp/*`, `/run/*`, `/tmp/*`, and `/var/lib/dkms` in `EORUN_CLEANUP` right before `bootc container lint`. **Never** `rm -rf /var/lib/*` wholesale, as that destroys RPM/SELinux/state databases.

### ❌ Roadblock 5: `dive` Low Efficiency / High Wasted Bytes
* **Cause:** Copying 40+ images into `/tmp/staging` inside the final image and deleting `/tmp/staging` in a later layer records all staged bytes as "added then deleted" waste in OCI layer history.
* **Fix:** Assemble and normalize all `firefly:*` images in an external build stage (`stage-prep` -> `firefly-stage`), then merge with a single `COPY --from=firefly-stage / /`.

### ❌ Roadblock 6: LLVM OpenMP Out-of-Tree CMake Failures
* **Cause:** Building `openmp` standalone from `openmp/` fails to find LLVM CMake modules and GTest headers.
* **Fix:** Point CMake at `${LLVM_SRC}/runtimes` with:
  ```cmake
  -DLLVM_ENABLE_RUNTIMES=openmp
  -DLLVM_INCLUDE_TESTS=OFF
  -DOPENMP_INCLUDE_TESTS=OFF
  -DLIBOMP_BUILD_UNITTESTS=OFF
  -DOPENMP_ENABLE_LIBARCHER=OFF
