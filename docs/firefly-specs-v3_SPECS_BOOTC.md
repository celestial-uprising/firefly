# Project Firefly — Immutable bootc OS Image Specification (bella.cf)

OS Base: Fedora 44 bootc
RootFS: Btrfs + composefs
Goal: Zero-warning bootc container lint, minimal runtime dependencies, and clean layer efficiency (dive)

---

## 1. Multi-Stage Assembly Pipeline

1. Base RootFS Stage (fedora-bootc:44): Prepares the Fedora 44 bootc base rootfs and required runtime packages (such as libstdc++ and minimal runtime shared libraries needed by dynamic plugins/nsswitch).
2. Staging & Normalization Stage (stage-prep from fedora:44): Copies firefly:* artifact payloads and runs symlink/usrmerge normalization (/bin, /sbin, /lib, /lib64, /usr/sbin, /share, /systemd) before assembling the final image.
3. Clean Payload Stage (firefly-stage from scratch): Holds the normalized single-layer payload without intermediate build churn.
4. Final bootc Image Stage (from scratch): Combines the base rootfs, COPY --from=firefly-stage / /, kernel 7.2.15 + depmod + dracut initramfs (btrfs + ostree + vfio), EORUN_CLEANUP, bootc container lint, and OCI bootc labels.

Never run shell commands inside a FROM scratch stage; perform all filesystem operations in a Fedora-based stage prior to FROM scratch.
