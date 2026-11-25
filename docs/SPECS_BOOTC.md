---

# 🚀 Page 3: `FIREFLY-BOOTC-OS.md` — Immutable `bootc` OS Image Spec (`bella.cf`)

```markdown
# 🛡️ Project Firefly — Immutable `bootc` OS Image Specification (`bella.cf`)

![OS](https://img.shields.io/badge/OS-Fedora%2044%20bootc-294172?style=flat-square)
![RootFS](https://img.shields.io/badge/RootFS-Btrfs%20%2B%20composefs-success?style=flat-square)
![Lint](https://img.shields.io/badge/bootc%20lint-0%20Warnings-brightgreen?style=flat-square)

---

## 1. Multi-Stage Pipeline Architecture

To avoid `dive` layer-churn penalties and keep the final image clean, `bella.cf` separates **rootfs generation**, **artifact normalization**, and **final OS assembly** into distinct stages:

```text
┌──────────────────────────────────┐     ┌────────────────────────────────────────┐
│ Stage 1: builder                 │     │ Stage 2: stage-prep (Fedora + Tools)   │
│ fedora-bootc:44                  │     │ Copies all firefly:* payloads          │
│ bootc-base-imagectl build-rootfs │     │ Normalizes /bin, /sbin, /lib*, /share  │
└────────────────┬─────────────────┘     └───────────────────┬────────────────────┘
                 │                                           │
                 │                                           ▼
                 │                       ┌────────────────────────────────────────┐
                 │                       │ Stage 3: firefly-stage (FROM scratch)  │
                 │                       │ Clean, single-layer normalized payload │
                 │                       └───────────────────┬────────────────────┘
                 ▼                                           │
┌────────────────────────────────────────────────────────────▼────────────────────┐
│ Stage 4: Final Image (FROM scratch)                                             │
│ 1. Base rootfs + DNF packages + kargs + systemd units                           │
│ 2. COPY --from=firefly-stage / /                                                │
│ 3. depmod + dracut initramfs (btrfs + ostree + vfio)                            │
│ 4. EORUN_CLEANUP -> bootc container lint -> OCI bootc labels                    │
└─────────────────────────────────────────────────────────────────────────────────┘

    [!IMPORTANT]
    Why stage-prep sits in front of firefly-stage:
    A FROM scratch stage has no /bin/sh, cp, mkdir, or rm. Run the directory normalization script inside a lightweight builder stage (FROM fedora:44 AS stage-prep), then copy the clean result into FROM scratch AS firefly-stage (or directly into the final stage).
