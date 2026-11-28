# PROJECT FIREFLY
Bottom Line for Your bootc Build

With pinned versions, kernel 7.2.15, and a custom userland, almost everything can be incorporated; the only real concessions are kernel/driver/D-Bus/systemd boundary alignment (udev, mesa, wayland, pipewire/wireplumber, xdg-desktop-portal*) and library/soname discipline (openssl, zlib-ng).

## 2. Low-Friction / Clean

    - openssl (libcrypto / libssl / libz)
    - zlib-ng (ZLIB_COMPAT=ON)
    - bash
    - upower
    - libnl
    - libdbusmenu-gtk3
    - libappindicator-gtk3
    - cmus
    - htop
    - tig
    - goaccess
    - fastfetch
    - blink
    - tmux
    - dunst
    - swaylock
    - swayidle
    - swaybg
    - playerctl
    - xwayland-satellite
    - lz4
    - xz
    - cpython
    - php-src
    - luajit

    Practical reality checks are purely runtime / integration details
    - nvtop
      - (nvtop against kernel 7.2.15 DRM/KFD/NVML telemetry)
    - cava
      - (cava against your PipeWire/ALSA setup)
    - hm
      - (hm having its GPU/WebGPU/display dependencies present)
    - nodejs (node-v8)
      - (nodejs / node-v8 being an experimental V8 LKGR mirror)

## DEPENDENCIES TO BUILD

    - openssl (libcrypto / libssl / libz)
    - zlib-ng (ZLIB_COMPAT=ON)
    - bash
    - upower (libupower-glib)
    - libnl
    - libdbusmenu-gtk3
    - libappindicator-gtk3
    - cmus
    - htop
    - dunst
    - swaylock
    - swayidle
    - swaybg
    - playerctl
    - xwayland-satellite
    - lz4
    - xz
    - cpython
    - php-src
    - luajit
- libxkbcommon
- cairo (cairomm)
- pango
- pixman
- jsoncpp
- fmt
- libmpdclient

#--------------------------->

1. High-friction (even with custom userland)

    - udev (libudev / eudev)
    - mesa (libEGL / libgbl)
    - wayland (libwayland-server)
    Even with kernel 7.2.15 and a custom userland, udev rules, /usr/lib/udev/rules.d, device permissions, and graphics/EGL/GBL paths sit right at the kernel/compositor boundary. In a bootc (ostree/composefs) image, mutating /etc vs /usr rules and keeping mesa + libEGL/libgbl + kernel 7.2.15 DRM/KFD/NVML interfaces in sync is the main place to watch—totally doable, just needs explicit verification against your pinned kernel and compositor.

    - pipewire
    - libwireplumber
    - pipewire-jack
    Safe if you control the audio stack end-to-end, provided systemd user/system units, socket activation, and SPA/WirePlumber paths line up cleanly inside the read-only /usr tree (bootc container lint likes clean unit/path layouts).

    - xdg-desktop-portal
    - xdg-desktop-portal-gnome
    - xdg-desktop-portal-gtk
    Portal activation relies on D-Bus .service files, portal config (portals.conf), and systemd units matching your actual session/compositor. 
    The risk is silent portal failures if D-Bus/systemd unit paths don't match your session.

Even with a matching glibc in a Fedora 44 bootc image, copying /out/usr artifacts on top of an immutable image rootfs can still cause real problems when a build overwrites core base-OS/session daemons or shared libraries that systemd, bootc, graphics/audio stacks, or other Fedora binaries expect in exact lockstep (bootc container lint / composefs / ostree / /usr immutability).

#--------------------------->

Here is the reduced list of items most likely to cause friction or breakage when incorporated into a bootc image:
High-Risk / Likely to Cause bootc Image Friction

    mesa (libEGL / libgbl) & wayland (libwayland-server) & udev: Tightly coupled to the kernel, display server/compositor, and hardware drivers in the base image. Replacing their .sos or udev rules/helpers in /usr risks compositor/driver/device-node mismatches or bootc lint/upgrade surprises.

    pipewire, libwireplumber, & pipewire-jack: Core audio/media daemon and plugin libraries that interact closely with systemd user/system units, session managers, and SPA plugins. Partial or mismatched overlays can break audio routing or WirePlumber session policy.

    openssl & zlib-ng (ZLIB_COMPAT=ON): Fundamental system libraries linked by systemd, networking/crypto tools, and base utilities. Overwriting libcrypto/libssl or libz in /usr/lib64 can silently break or destabilize base-image binaries if symbols, sonames, or build assumptions differ from Fedora's baseline.

    xdg-desktop-portal, xdg-desktop-portal-gnome, & xdg-desktop-portal-gtk: Portal D-Bus services, systemd units, and backend integrations that must match the desktop session/compositor setup in the bootc image rather than being blindly overlaid from a generic build.

    bash: Core shell in the base OS; replacing /usr/bin/bash (and /bin/sh symlink expectations) carries boot/script-execution risk if anything in the image depends on Fedora's exact bash build or features.

    upower, libnl, libdbusmenu-gtk3, & libappindicator-gtk3: System/session integration libraries tied to D-Bus services, network/power management, or legacy status-notifier/tray stacks—less catastrophic than openssl or mesa, but prone to version/service-unit drift in an immutable image.

Lower-Risk in a bootc Image (Better Fit for /out/usr/bin Overlays)

    Leaf CLI / TUI / utility tools: cmus, cava, htop, nvtop, tig, goaccess, fastfetch, blink, tmux, hm, dunst, swaylock, swayidle, swaybg, playerctl, xwayland-satellite, lz4, xz. As long as they don't clobber base-system libraries (libz/liblzma sonames), they are much safer to fold into a bootc /usr tree.

    Language runtimes (cpython, php-src, luajit, nodejs/node-v8): Generally safe from a bootc base-OS stability standpoint if installed cleanly without shadowing system binaries/libraries you rely on, though luajit and nodejs/node-v8 are niche/experimental for a production bootc image.

Running bootc container lint in your image build pipeline will also catch many /usr layout or unit/file issues before deployment. Which of the lower-risk tools from this set do you want to pull into your bootc image next?

#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->
#--------------------------->

