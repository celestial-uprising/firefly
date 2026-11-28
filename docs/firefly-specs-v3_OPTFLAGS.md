# Project Firefly — Unified Compiler & Linker Flags Specification

Target: x86_64 AMD Zen 3 (znver3) on Fedora 44
Compiler Suite: AOCC 6.0 (aoc, aoc++, ld.lld, llvm-ar, llvm-ranlib, llvm-nm, llvm-strip)
GPU Targets: NVIDIA Pascal (60-real / sm_60) and Ampere (86-real / sm_86)

---

## 1. Project-Wide Optimization Flags

- -O3: High-level optimization including loop unrolling, inlining, and aggressive vectorization.
- -march=znver3: Emits Zen 3 ISA instructions (AVX2, FMA, SHA, VAES, VPCLMULQDQ, etc.).
- -mtune=znver3: Tunes scheduling, alignment, and cache behavior for Zen 3 microarchitecture.
- -flto=full: Whole-program link-time optimization across C/C++ translation units with ld.lld.
- -zopt: Enables AOCC/LLVM link-time and code layout optimizations.
- -fscalar-transform: Applies AOCC scalar transformations to simplify scalar expressions and control flow.
- -floop-transform: Enables AOCC loop restructuring passes (fusion, interchange, tiling, unrolling).
- -faggressive-loop-transform: Applies deeper loop transformations for compute-heavy workloads.
- -fremap-arrays: Reorganizes array layouts/accesses to improve cache locality and TLB behavior.
- -fstruct-layout=7: Enables AOCC structure layout optimization/reordering/splitting.
- -fveclib=AMDLIBM: Routes vectorized math calls to AMD's tuned AMDLIBM library.
- -fuse-ld=lld: Selects LLVM's ld.lld linker.
- -l:libamdlibm.a: Links the static AMDLIBM archive during final linking.

Layer discipline: Keep -flto=full, -fveclib=AMDLIBM, -l:libamdlibm.a, and aggressive AOCC loop/struct flags scoped to userspace builds where validated—never leak them into Linux kernel KCFLAGS or KBUILD_LDFLAGS.

---

## 2. Language Profiles

### C & C++ (AOCC 6.0 + ld.lld + Static Runtime Preference)

export CC="aoc"
export CXX="aoc++"
export LD="ld.lld"
export AR="llvm-ar"
export RANLIB="llvm-ranlib"
export NM="llvm-nm"
export STRIP="llvm-strip"

export CFLAGS="-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fscalar-transform -floop-transform -faggressive-loop-transform -fremap-arrays -fstruct-layout=7 -fveclib=AMDLIBM"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=lld -flto=full -O3 -static-libstdc++ -static-libgcc -Wl,-O3,--gc-sections,--as-needed,--no-fatal-warnings -l:libamdlibm.a"

For compatibility-sensitive C/C++ targets (such as strict POSIX utilities or OpenZFS userland), use the safer profile (-fno-unwind-tables -fno-asynchronous-unwind-tables as needed and omit risky transforms if a target requires them).

### Linux Kernel (7.2.15 — C & Rust)

make LLVM=1 \
  KCFLAGS="-O3 -march=znver3 -mtune=znver3" \
  KBUILD_LDFLAGS="-fuse-ld=lld" \
  -j"$(nproc)"

Keep userspace LTO, fast-math, and AMDLIBM flags out of kernel builds. For CONFIG_RUST=y, match the rustup toolchain version reported by scripts/min-tool-version.sh rustc with rust-src installed and let Kbuild manage KRUSTFLAGS.

### Rust (Userspace Binaries & Crates)

export CC="aoc"
export CXX="aoc++"
export AR="llvm-ar"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="ld.lld"
export RUSTFLAGS="-C target-cpu=znver3 -C opt-level=3 -C lto=fat -C codegen-units=1 -C link-arg=-fuse-ld=lld -C link-arg=-static-libstdc++ -C link-arg=-static-libgcc -C link-arg=-Wl,-O3,-z,opt,--gc-sections,--as-needed"

cargo build --release --locked

### CUDA (nvcc + AOCC Host + CMake)

cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=aoc \
  -DCMAKE_CXX_COMPILER=aoc++ \
  -DCMAKE_CUDA_ARCHITECTURES="60-real;86-real" \
  -DCMAKE_CUDA_FLAGS="-O3 --use_fast_math" \
  -DCMAKE_CXX_FLAGS="-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fveclib=AMDLIBM" \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -O3 -static-libstdc++ -static-libgcc -l:libamdlibm.a" \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_F16=ON \
  -DGGML_CUDA_GRAPHS=ON

### Go (CGO + AOCC + ld.lld)

Avoid nested single quotes inside EXTRA_LDFLAGS / -ldflags when passing -extldflags; repeat -extldflags per flag instead:

export GOOS="linux"
export GOARCH="amd64"
export GOAMD64="v3"
export CGO_ENABLED="1"
export CC="aoc"
export CXX="aoc++"

go build -trimpath \
  -ldflags="-s -w -extldflags=-fuse-ld=lld -extldflags=-static-libstdc++ -extldflags=-static-libgcc -extldflags=-Wl,-O3,-z,opt,--gc-sections,--as-needed,--no-fatal-warnings" \
  ./...

### Python Native Extensions & Lua / LuaJIT Modules

export CC="aoc"
export CXX="aoc++"
export LDSHARED="aoc++ -shared -fuse-ld=lld"
export CFLAGS="-O3 -march=znver3 -mtune=znver3 -fPIC -flto=full -zopt -fveclib=AMDLIBM"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=lld -flto=full -O3 -static-libstdc++ -static-libgcc -l:libamdlibm.a"

### Assembly (x86_64 / Zen 3)

aoc -c -O3 -march=znver3 -mtune=znver3 kernel_zen3.S -o kernel_zen3.o
ld.lld -O3 -zopt kernel_zen3.o -o kernel_zen3
