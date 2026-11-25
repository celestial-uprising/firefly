# 🧩 Project Firefly — Unified Compiler & Linker Flags Specification

![CPU](https://img.shields.io/badge/Target-AMD%20Zen%203%20(znver3)-red?style=flat-square)
![Compiler](https://img.shields.io/badge/C%2FC%2B%2B-AOCC%206.0%20%2B%20ld.lld-blue?style=flat-square)
![GPU](https://img.shields.io/badge/CUDA-60--real%3B86--real-76b900?style=flat-square)
![Format](https://img.shields.io/badge/Markdown-GitHub%20%2B%20glow%20%2B%20nvim-purple?style=flat-square)

> [!IMPORTANT]
> Every language profile in this unified reference targets **Fedora 44** on **x86_64 AMD Zen 3 (`znver3`)** using **AOCC 6.0** (`aoc` / `aoc++` / LLVM `ld.lld` / `llvm-ar` / `llvm-ranlib` / `llvm-nm` / `llvm-strip`) where applicable. Always scope aggressive optimizations cleanly per layer—especially keeping kernel builds and strict IEEE-754 code free of conflicting flags.

---

## 1. Project-Wide Optimization Flags (Function & Benefit)

These baseline optimization flags form the shared performance DNA across Project Firefly's userspace C/C++ and linker pipelines:

| Flag / Option | Layer | What It Does (Function) | Why It Helps (Benefit) |
| :--- | :--- | :--- | :--- |
| **`-O3`** | C / C++ / Link | Enables high-level compiler passes including aggressive vectorization, function inlining, and loop unrolling. | Squeezes maximum instruction throughput and lower loop overhead out of compute-heavy code. |
| **`-march=znver3`** | C / C++ / Asm | Targets the exact Zen 3 instruction set (AVX2, FMA, SHA, VAES, VPCLMULQDQ, etc.) for code generation. | Unlocks full Zen 3 ISA instructions without generic baseline x86_64 fallbacks. |
| **`-mtune=znver3`** | C / C++ / Asm | Tunes instruction scheduling, alignment, and branch/cache behavior for Zen 3 microarchitecture. | Matches Zen 3's execution pipelines, L1/L2/L3 cache geometry, and uop cache behavior. |
| **`-flto=full`** | C / C++ / Link | Defers optimization and codegen until link time across the whole program/library graph (`ld.lld`). | Enables cross-translation-unit inlining, dead-code elimination, and whole-program devirtualization. |
| **`-zopt`** | C / C++ / Link | Enables AOCC/LLVM link-time and code layout optimizations. | Tightens hot-path layout and reduces code footprint and branch/fetch penalties. |
| **`-fscalar-transform`** | AOCC C / C++ | Applies AOCC scalar transformations to simplify and optimize scalar expressions and control flow. | Cuts redundant scalar operations and improves register pressure in inner loops. |
| **`-floop-transform`** | AOCC C / C++ | Runs AOCC loop restructuring passes (fusion, interchange, tiling, unrolling). | Improves spatial/temporal locality and exposes more vectorizable loop bodies. |
| **`-faggressive-loop-transform`** | AOCC C / C++ | Applies deeper, more assertive loop transformations beyond standard loop passes. | Accelerates dense numerical and tensor loops at the cost of longer compile times. |
| **`-fremap-arrays`** | AOCC C / C++ | Reorganizes array layouts/access patterns to improve memory access behavior. | Reduces cache misses and TLB pressure on array-heavy workloads. |
| **`-fstruct-layout=7`** | AOCC C / C++ | Enables aggressive structure layout optimization/reordering/splitting in AOCC. | Packs frequently co-accessed fields closer together to boost cache line utilization. |
| **`-fveclib=AMDLIBM`** | AOCC C / C++ | Routes vectorized math calls to AMD's tuned `AMDLIBM` vector math library. | Speeds up transcendental and floating-point math routines on AMD processors. |
| **`-fuse-ld=lld`** | Linker (`LDFLAGS`) | Selects LLVM's `ld.lld` linker instead of GNU `ld`. | Provides fast linking and native integration with LLVM/AOCC LTO bitcode. |
| **`-l:libamdlibm.a`** | Linker (`LDFLAGS`) | Explicitly links the static `AMDLIBM` archive during final linking. | Ensures required `AMDLIBM` math symbols resolve cleanly for vectorized/math builds. |

> [!TIP]
> **Layer discipline:** Keep `-flto=full`, `-fveclib=AMDLIBM`, `-l:libamdlibm.a`, and aggressive AOCC loop/struct flags in **userspace C/C++ builds** where tested safe—and **never** pass them into Linux kernel `KCFLAGS`.

---

## 2. Quick Matrix Across Languages

| Language | Compiler / Driver | Linker | Key Optimization Highlights |
| :--- | :--- | :--- | :--- |
| **C** | `aoc` (AOCC 6.0) | `ld.lld` | `-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fveclib=AMDLIBM` |
| **C++** | `aoc++` (AOCC 6.0) | `ld.lld` | Same as C + AOCC loop/array/struct transforms (`llama.cpp`, `ZenDNN`) |
| **Kernel C (Linux 7.2.15)** | `LLVM=1` (`clang` / `aoc`) | `ld.lld` (`KBUILD_LDFLAGS`) | `-O3 -march=znver3 -mtune=znver3` (**no** `-ffast-math` or `AMDLIBM`) |
| **Rust (Userspace)** | `rustc` / `cargo` | `ld.lld` | `-C target-cpu=znver3 -C opt-level=3 -C lto=fat -C codegen-units=1` |
| **Rust (Kernel 7.2.15)** | `rustc` via `Kbuild` (`LLVM=1`) | `ld.lld` | Managed by kernel Kbuild (`CONFIG_RUST=y`, `rustup` matching `min-tool-version.sh`) |
| **CUDA (`nvcc` + Host C++)** | `nvcc` + `aoc++` (`-ccbin`) | `ld.lld` / `nvlink` | `60-real;86-real`, `-O3`, `--use_fast_math` (where safe) |
| **Go** | `go` (`CGO_ENABLED=1` w/ `aoc`) | `ld.lld` (`-extldflags`) | `GOAMD64=v3` + `-s -w` strip + `-fuse-ld=lld` |
| **Python (C/C++ Extensions)** | `aoc` / `aoc++` (`CC`/`CXX`/`LDSHARED`) | `ld.lld -shared` | `-O3 -march=znver3 -mtune=znver3 -fPIC -flto=full -zopt` |
| **Lua / LuaJIT Native Mods** | `aoc` / `aoc++` | `ld.lld -shared` | `-O3 -march=znver3 -mtune=znver3 -fPIC -zopt` |
| **Assembly (x86_64 / Zen 3)** | `aoc` / `llvm-mc` / `nasm` | `ld.lld` | `-march=znver3` / `-mtune=znver3` / `-f elf64` |

---

## 3. C & C++ (`aoc` / `aoc++` + `ld.lld`)

### Full AOCC Zen 3 Profile (Compute, `llama.cpp`, `ZenDNN`, `mimalloc`, Utilities)
```bash
export CC="aoc"
export CXX="aoc++"
export LD="ld.lld"
export AR="llvm-ar"
export RANLIB="llvm-ranlib"
export NM="llvm-nm"
export STRIP="llvm-strip"

export CFLAGS="-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fscalar-transform -floop-transform -faggressive-loop-transform -fremap-arrays -fstruct-layout=7 -fveclib=AMDLIBM"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=lld -flto=full -O3 -l:libamdlibm.a -Wl,--no-fatal-warnings"
```

### Safer / Compatibility C & C++ Profile (Strict POSIX / System Tools / OpenZFS Userland)
```bash
export CFLAGS="-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fveclib=AMDLIBM -fno-unwind-tables -fno-asynchronous-unwind-tables"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=lld -flto=full -O3 -l:libamdlibm.a -Wl,--no-fatal-warnings"
```

### CMake / Meson Companion Flags
```bash
# CMake
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=aoc \
  -DCMAKE_CXX_COMPILER=aoc++ \
  -DCMAKE_LINKER=ld.lld \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_INSTALL_LIBDIR=lib64 \
  -DCMAKE_INSTALL_SBINDIR=bin

# Meson
meson setup build \
  --buildtype=release \
  --prefix=/usr \
  --libdir=lib64 \
  --sbindir=bin
```

---

## 4. Linux Kernel (`7.2.15` — C & Rust)

> [!CAUTION]
> Never leak userspace `CFLAGS`/`LDFLAGS` (`-flto=full`, `-ffast-math`, `-fveclib=AMDLIBM`, `-l:libamdlibm.a`) into the Linux kernel build. Keep kernel flags isolated to `KCFLAGS` and `KBUILD_LDFLAGS`.

```bash
make LLVM=1 \
  KCFLAGS="-O3 -march=znver3 -mtune=znver3" \
  KBUILD_LDFLAGS="-fuse-ld=lld" \
  -j"$(nproc)"
```

* **Kernel Rust (`CONFIG_RUST=y`):** Let Linux Kbuild invoke `rustc` and `bindgen` with its own `KRUSTFLAGS` and target specs, using the `rustup` toolchain version reported by `scripts/min-tool-version.sh rustc` with `rust-src` installed.

---

## 5. Rust (Userspace Binaries & Crates)

### Maximum Zen 3 + Fat LTO + `lld`
```bash
export CC="aoc"
export CXX="aoc++"
export AR="llvm-ar"
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER="ld.lld"
export RUSTFLAGS="-C target-cpu=znver3 -C opt-level=3 -C lto=fat -C codegen-units=1 -C link-arg=-fuse-ld=lld -C link-arg=-Wl,-z,opt"

cargo build --release --locked
```

> [!TIP]
> If a crate fails under `lto=fat` or `-z,opt`, drop `-C codegen-units=1` or switch `-C lto=fat` to `-C lto=thin` while keeping `-C target-cpu=znver3 -C opt-level=3 -C link-arg=-fuse-ld=lld`.

---

## 6. CUDA (`nvcc` + CMake for Pascal `sm_60` & Ampere `sm_86`)

### Direct `nvcc` Flags
```bash
nvcc -O3 \
  -gencode arch=compute_60,code=sm_60 \
  -gencode arch=compute_86,code=sm_86 \
  --use_fast_math \
  -Xcompiler "-O3 -march=znver3 -mtune=znver3 -fPIC"
```

### CMake (`llama.cpp` / `ggml-cuda` Style)
```bash
cmake -B build -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=aoc \
  -DCMAKE_CXX_COMPILER=aoc++ \
  -DCMAKE_CUDA_ARCHITECTURES="60-real;86-real" \
  -DCMAKE_CUDA_FLAGS="-O3 --use_fast_math" \
  -DCMAKE_CXX_FLAGS="-O3 -march=znver3 -mtune=znver3 -flto=full -zopt -fveclib=AMDLIBM" \
  -DCMAKE_EXE_LINKER_FLAGS="-fuse-ld=lld -O3 -l:libamdlibm.a" \
  -DGGML_CUDA=ON \
  -DGGML_CUDA_F16=ON \
  -DGGML_CUDA_GRAPHS=ON
```

---

## 7. Go (CLI & Container Tools)

Go's native compiler uses `GOAMD64` (`v1`–`v4`) rather than `-march=znver3`. Use `GOAMD64=v3` (AVX/AVX2/FMA baseline aligned with Zen 3) and pass `ld.lld` when `cgo` is active:

```bash
export GOOS="linux"
export GOARCH="amd64"
export GOAMD64="v3"
export CGO_ENABLED="1"
export CC="aoc"
export CXX="aoc++"

go build -trimpath \
  -ldflags="-s -w -extldflags '-fuse-ld=lld -O3 -Wl,-z,opt'" \
  ./...
```

---

## 8. Python Native Extensions & Lua / LuaJIT Modules

### Python (`pip` / `setuptools` / `scikit-build` / `pybind11` / `Cython`)
```bash
export CC="aoc"
export CXX="aoc++"
export LDSHARED="aoc++ -shared -fuse-ld=lld"
export CFLAGS="-O3 -march=znver3 -mtune=znver3 -fPIC -flto=full -zopt -fveclib=AMDLIBM"
export CXXFLAGS="${CFLAGS}"
export LDFLAGS="-fuse-ld=lld -flto=full -O3 -l:libamdlibm.a"

pip install --no-build-isolation --no-deps .
```

### Lua / LuaJIT Native C Modules (`luarocks` / Shared Libraries)
```bash
export CC="aoc"
export CXX="aoc++"
export CFLAGS="-O3 -march=znver3 -mtune=znver3 -fPIC -zopt -fveclib=AMDLIBM"
export LIBFLAG="-shared -fuse-ld=lld -O3 -l:libamdlibm.a"

# Example standalone shared object build:
aoc ${CFLAGS} -I/usr/include -c mod.c -o mod.o
aoc ${LIBFLAG} mod.o -o mod.so
```

---

## 9. Assembly (`x86_64` / Zen 3)

```bash
# LLVM / AOCC integrated assembler (AT&T / Intel syntax via clang/aoc)
aoc -c -O3 -march=znver3 -mtune=znver3 kernel_zen3.S -o kernel_zen3.o
ld.lld -O3 -zopt kernel_zen3.o -o kernel_zen3

# NASM (64-bit ELF)
nasm -f elf64 -O3 fast_routine.asm -o fast_routine.o
ld.lld -O3 -zopt fast_routine.o -o fast_routine
```