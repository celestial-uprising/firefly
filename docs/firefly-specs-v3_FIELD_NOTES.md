# Project Firefly — Field Notes, Roadblocks & Diagnostic Playbook

---

## 1. Known Roadblocks & Fixes

- Roadblock 1 — cp: cannot overwrite non-directory '/./usr/sbin' with directory: On Fedora 44, /bin, /sbin, /lib, /lib64, and /usr/sbin are usrmerge symlinks. Normalize staging directories in a Fedora stage before merging.
- Roadblock 2 — --prefix=/out dumping files at root: Always use --prefix=/usr with DESTDIR=/out so files land under /out/usr/....
- Roadblock 3 — RUN failing inside FROM scratch: FROM scratch has no shell or coreutils. Run all moves, stripping, and checks in a Fedora stage and use FROM scratch only for COPY --from=....
- Roadblock 4 — bootc container lint var-tmpfiles warnings: Clean /var/cache/*, /var/log/*, /var/tmp/*, /run/*, /tmp/*, and /var/lib/dkms in EORUN_CLEANUP without deleting /var/lib/* wholesale.
- Roadblock 5 — dive high wasted bytes from staging cleanup: Normalize and stage firefly:* artifacts in stage-prep / firefly-stage rather than copying and deleting inside the final image.
- Roadblock 6 — LLVM OpenMP out-of-tree CMake errors: Configure from ${LLVM_SRC}/runtimes with -DLLVM_ENABLE_RUNTIMES=openmp, -DLLVM_INCLUDE_TESTS=OFF, -DOPENMP_INCLUDE_TESTS=OFF, -DLIBOMP_BUILD_UNITTESTS=OFF, and -DOPENMP_ENABLE_LIBARCHER=OFF.
- Roadblock 7 — Missing libstdc++ at runtime on minimal bootc: Pass -static-libstdc++ -static-libgcc (and --prefer-static / static archives where supported) during linking so C++ binaries minimize runtime library dependencies, while keeping glibc dynamic for nsswitch and dlopen plugins.
- Roadblock 8 — Go -ldflags quoting error ("flag provided but not defined: -O3"): Do not nest single quotes inside EXTRA_LDFLAGS; pass repeated -extldflags flags instead.
- Roadblock 9 — file: command not found in post-install ELF checks: Do not assume file is installed; inspect ELF magic bytes or invoke readelf directly.
