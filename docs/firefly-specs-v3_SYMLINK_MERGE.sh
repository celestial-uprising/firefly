#!/usr/bin/env bash
set -xeuo pipefail

# 1. Normalize top-level usrmerge directories -> /stage/usr/...
for d in bin sbin lib lib64; do
    if [ -d "/stage/$d" ] && [ ! -L "/stage/$d" ]; then
        mkdir -p "/stage/usr/$d"
        cp -a "/stage/$d/." "/stage/usr/$d/"
        rm -rf "/stage/$d"
    fi
done

# 2. Collapse /stage/usr/sbin -> /stage/usr/bin (Fedora /usr/sbin symlinks to bin)
if [ -d "/stage/usr/sbin" ] && [ ! -L "/stage/usr/sbin" ]; then
    mkdir -p "/stage/usr/bin"
    cp -a "/stage/usr/sbin/." "/stage/usr/bin/"
    rm -rf "/stage/usr/sbin"
fi

# 3. Rescue any stray /stage/share or /stage/systemd folders exported at root
if [ -d "/stage/share" ] && [ ! -L "/stage/share" ]; then
    mkdir -p "/stage/usr/share"
    cp -a "/stage/share/." "/stage/usr/share/"
    rm -rf "/stage/share"
fi

if [ -d "/stage/systemd" ] && [ ! -L "/stage/systemd" ]; then
    mkdir -p "/stage/usr/lib/systemd"
    cp -a "/stage/systemd/." "/stage/usr/lib/systemd/"
    rm -rf "/stage/systemd"
fi
