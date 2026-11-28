## Practical Notes

For a bootc (bootable container) distro using glibc, you can safely mix and match almost the entire userland with AOCC (AMD Optimizing C/C++ Compiler), leaving only glibc, the kernel, and a few core runtime libraries built with GCC.
Because Clang/AOCC and GCC follow the exact same System V AMD64 ABI (Application Binary Interface) on x86_64 Linux, binaries and shared libraries compiled by AOCC can link cleanly against GCC-compiled libraries (like glibc) without any runtime conflicts.

## The Safe Layering Strategy for a bootc Image

Since bootc relies on layered OCI container images, you have a huge advantage: you can pull a proven base image (like Fedora Bootc, CentOS Stream, or Debian) to keep the low-level GCC plumbing intact, and selectively overwrite upper layers with AOCC-built packages.
• Keep on GCC (The Foundation): Leave glibc, the Linux kernel, systemd (optional, though rebuilding it gives minimal AOCC benefit), and low-level GCC runtime libraries (libgcc_s.so and libstdc++.so if mixing C++ binaries) untouched in your base layer.
• Rebuild with AOCC (High-Value Userland): Focus your AOCC builds on compute-heavy libraries and applications. OpenSSL, zlib/zstd, SQLite, Python/Node/JVM runtimes, FFmpeg, databases, scientific libraries (BLAS/LAPACK), and your primary workload apps will link cleanly to the system's GCC-built glibc.
• Core Utilities: GNU Coreutils, Bash, curl, and networking tools compile cleanly with Clang/AOCC and can replace the base layer versions if you want a deeper rebuild.

## 3 Critical Rules for Mixing AOCC and GCC

When mixing compilers in a glibc system, ABI compatibility is guaranteed for C, but there are a few edge cases to watch out for:
• Be careful with C++ Standard Libraries. AOCC uses LLVM's libc++ or links against GCC's libstdc++. Keep C++ libraries consistent across dependency chains—if library A is built with AOCC using libc++ and app B links to it using libstdc++, you will hit symbol resolution errors at runtime. Force AOCC to link against the system's libstdc++ (-stdlib=libstdc++) so all C++ packages share one ABI.
• Watch out for LTO (Link-Time Optimization) mismatches. You cannot link static archives (.a files) built with GCC LTO into a binary compiled with AOCC LTO. If you rebuild a static library with AOCC, ensure any package linking statically against it is also built with AOCC (or disable LTO for static archives).
• OpenMP runtime collisions. AOCC includes AMD's high-performance OpenMP runtime (libomp). If a GCC-compiled library pulls in libgomp while an AOCC binary pulls in libomp in the same process, thread contention or crashes can occur. Stick to one OpenMP runtime for apps that load multiple math/compute libraries.

## Practical bootc Build Approach

1. Start from a minimal base: Use quay.io/fedora/fedora-bootc or a minimal Debian/Ubuntu base so you already have a working kernel, initramfs (dracut), bootc binary, and glibc.
2. Use a multi-stage Containerfile: Create a builder stage with AOCC installed, compile your target dependency tree into a custom prefix or native package format (RPM/DEB), and copy/install only the compiled artifacts into the final bootc stage.
3. Verify linkage: Run ldd on your AOCC-built binaries inside the container build to verify they resolve cleanly against /lib64/libc.so.6 and /lib64/libstdc++.so.6 without missing symbols.

Keep your minimal base and ZFS modules untouched on GCC, and avoid rebuilding low-level plumbing or security daemons

## Avoid Rebuilding with AOCC

• ZFS Kernel Modules (zfs.ko, spl.ko). Because F44 kernel is built with GCC, ZFS kernel modules must also be compiled with GCC. Mismatching compilers between the kernel and out-of-tree DKMS/akmod modules causes struct layout mismatches and kernel panics. (The userland zfs and zpool CLI utilities are fine on AOCC, though keeping the whole ZFS package set aligned on GCC is safer).
• Core Boot & Container Plumbing.
- Leave on Fedora's stock builds, as these manage atomic deployments and initramfs generation
    - bootc
    - ostree
    - rpm-ostree
    - dracut
    - grub2
    - podman
    - skopeo 
- Fedora's deep SELinux integration relies on strict memory layout and symbol behaviors in these
    - systemd
    - d-bus
    - pam
    - selinux
• Low-Level C Runtime & Crypto Plumbing. Avoid rebuilding glibc, libgcc, libstdc++, binutils, and elfutils. While OpenSSL compiles cleanly with AOCC and gives great performance gains, be cautious with gnutls and nss (Network Security Services), as they have strict FIPS/crypto self-checks in Fedora that can fail if compiler optimizations alter symbol tables.
