# Ladybird Browser Upstream Generic Linux Build Notes

## Build Prerequisites

Qt6.10+ development packages, nasm, additional build tools, and a C++23 capable compiler are required.

Qt6: install directly from the [Qt online installer](https://www.qt.io/download-open-source), and then point the build to it using `CMAKE_PREFIX_PATH`.

Rust-Nightly: install it via [rustup](https://rustup.rs/).

Upsteam Ladybird currently use gcc-16 and clang-22 in its CI pipeline.

See [`find_compiler.py`](../Meta/Utils/find_compiler.py) for the minimum compatible version.

CMake 3.30 or newer must be available in $PATH.

### Fedora:

```
dnf install \
  autoconf-archive \
  automake \
  ccache \
  cmake \
  curl \
  git \
  glslang \
  libdrm-devel \
  liberation-sans-fonts \
  libglvnd-devel \
  libtool \
  nasm \
  ncurses-devel \
  ninja-build \
  patchelf \
  perl-FindBin \
  perl-IPC-Cmd \
  perl-lib \
  perl-Time-Piece \
  pulseaudio-libs-devel \
  qt6-qtbase-devel \
  qt6-qtpositioning-devel \
  qt6-qttools-devel \
  qt6-qtwayland-devel \
  tar \
  unzip \
  xcb-util-wm-devel \
  zip \
  zlib-ng-compat-static
```

## Build steps

### Using ladybird.py

Upstream Default Release Build Method:

```bash
# From /path/to/ladybird
./Meta/ladybird.py run
```

CC=$(brew --prefix llvm)/bin/clang CXX=$(brew --prefix llvm)/bin/clang++ ./Meta/ladybird.py run

Upstream Debug Build Profile:

```bash
BUILD_PRESET=Debug ./Meta/ladybird.py run
```

Note that debug symbols are available in both Release and Debug builds.

### The User Interfaces

Ladybird is built with a [Qt](https://doc.qt.io/qt-6/) browser frontend on all platforms.

### Build error messages you may encounter

The section lists out some particular error messages you may run into, and explains how to deal with them.

#### Unable to find a build program corresponding to "Ninja"

This error message is a red herring. We use vcpkg to manage our third-party dependencies, and this error is logged when
something went wrong building those dependencies. The output in your terminal will vary depending on what exactly went
wrong, but it should look something like:

```
error: building skia:x64-linux failed with: BUILD_FAILED
Elapsed time to handle skia:x64-linux: 1.6 s

-- Running vcpkg install - failed
CMake Error at Build/vcpkg/scripts/buildsystems/vcpkg.cmake:899 (message):
  vcpkg install failed.  See logs for more information:
  Build/release/vcpkg-manifest-install.log
Call Stack (most recent call first):
  /usr/share/cmake-3.30/Modules/CMakeDetermineSystem.cmake:146 (include)
  CMakeLists.txt:15 (project)

CMake Error: CMake was unable to find a build program corresponding to "Ninja".  CMAKE_MAKE_PROGRAM is not set.  You probably need to select a different build tool.
-- Configuring incomplete, errors occurred!  See logs for more information:
  Build/release/vcpkg-manifest-install.log
```

If the error is not immediately clear from the terminal output, be sure to check the specified `vcpkg-manifest-install.log`.
for more information.

### Resource files

Ladybird requires resource files from the ladybird/Base/res directory in order to properly load
icons, fonts, and other theming information. These files are copied into the build directory by
special CMake rules. The expected location of resource files can be tweaked by packagers using
the standard CMAKE_INSTALL_DATADIR variable. CMAKE_INSTALL_DATADIR is expected to be a path relative
to CMAKE_INSTALL_PREFIX. If it is not, things will break.

PDF viewing also requires the PDF.js distribution. The vcpkg port provides it.
For other builds, use the version pinned in `vcpkg.json` and apply
[`0001-ladybird-embed.patch`](../Meta/CMake/vcpkg/overlay-ports/pdfjs/0001-ladybird-embed.patch).
Install the patched distribution under `<prefix>/share/pdfjs` and add that prefix to `CMAKE_PREFIX_PATH`,
or set `PDFJS_DIR` directly to the directory containing `build/pdf.mjs` and `web/`.
If PDF.js is unavailable, PDF-dependent tests are skipped. In a build configured with PDF.js, the JBIG2
test checks that its Wasm decoder is present and valid, and renders an image with both Wasm enabled and
the JavaScript fallback forced.

### Custom CMake build directory

The script Meta/ladybird.py and the Release preset in CMakePresets.json both define a build directory of
`Build/release`. For distribution purposes, or when building multiple configurations, it may be useful to create a custom
CMake build directory.

The install rules in UI/cmake/InstallRules.cmake define which binaries and libraries will be
installed into the configured CMAKE_PREFIX_PATH or path passed to ``cmake --install``.

Note that when using a custom build directory rather than Meta/ladybird.py, the user may need to provide a suitable C++
compiler (see [Build Prerequisites](BuildInstructionsLadybird.md#build-prerequisites)) via the CMAKE_C_COMPILER and
CMAKE_CXX_COMPILER cmake options.

```
cmake --preset Release -B MyBuildDir
# optionally, add -DCMAKE_CXX_COMPILER=<suitable compiler> -DCMAKE_C_COMPILER=<matching c compiler>
cmake --build --preset Release MyBuildDir
ninja -C MyBuildDir run-ladybird
```

### Building with limited system memory

The default build mode will run as many build steps in parallel as possible, which includes link steps;
this may be an issue for users with limited system memory (or users building with fat LTO in general).
If you wish to reduce the number of parallel link jobs, you may use the LAGOM_LINK_POOL_SIZE cmake option
to set a maximum limit for the number of parallel link jobs.

```
cmake --preset Release -B MyBuildDir -DLAGOM_LINK_POOL_SIZE=2
```

### Running manually

The Meta/ladybird.py script will execute the `run-ladybird` and `debug-ladybird` custom targets.
If you don't want to use the ladybird.py script to run the application, you can run the following commands:

To automatically run in gdb:
```
ninja -C Build/release debug-ladybird
```

To run without ninja rule on non-macOS systems:
```
./Build/release/bin/Ladybird
```

### Debugging with CLion  <- WE DONT NEED THIS BUILT AT ALL!!!!!!

Ladybird should be built with debug symbols first. This can be done by adding `-DCMAKE_BUILD_TYPE=Debug` to the cmake command line,
or selecting the Build Type Debug in the CLion CMake profile.

After running Ladybird as suggested above with `./Meta/ladybird.py run ladybird`, you can now in CLion use Run -> Attach to Process to connect. If debugging layout or rendering issues, filter the listing that opens for `WebContent` and attach to that.

Now breakpoints, stepping and variable inspection will work.

