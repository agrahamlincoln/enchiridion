# Suspend/Resume Freeze on Framework 13 (AMD Ryzen AI 300)

**Date discovered:** 2026-03-21
**Status:** RESOLVED 2026-06-12 — root cause was the Intel AX210 wifi card; replaced with MediaTek MT7925 (see Resolution section)
**Active follow-up (2026-06-22):** a *separate* kernel-7.0+ TTM hibernate regression is mitigated by defaulting to `linux-lts`. See the final section, "TTM Hibernate Lockup (kernel 7.0+ regression) & linux-lts Pin," for the proven root cause and the exit criteria for swapping back.
**Machine:** Framework Laptop 13 (AMD Ryzen AI 300 Series)

## Hardware

| Component | Detail |
|---|---|
| CPU | AMD Ryzen AI 7 350 w/ Radeon 860M |
| GPU | AMD Krackan (Radeon 840M / 860M), PCI c1:00.0 |
| WiFi | Intel AX210 (Wi-Fi 6E), PCI c0:00.0 |
| BIOS | 03.05 (latest stable as of 2026-03-21) |
| Suspend mode | s2idle only (ACPI supports S0, S4, S5 — no S3) |
| RAM | ADATA AD5S560016G-SFW DDR5-5600 2x16GB (CL46 — not affected by CL40 bug) |
| PMC driver | amd_pmc loaded, but `acpi_idle` as cpuidle driver |

## Symptom

After `systemctl suspend`, the machine enters s2idle. On wake (power button press), the screen shows a frozen frame (hyprlock's blurry lock screen if hypridle locked before sleep, otherwise the last desktop frame). No input is accepted — keyboard, touchpad, and fingerprint sensor are all unresponsive. The only recovery is a hard power-off (hold power button).

## Diagnostic Fingerprint

Use these markers to confirm this is the same issue:

1. **Journal ends at suspend entry.** In the boot prior to the forced reboot:
   ```
   journalctl -b -1 | grep 'PM: suspend'
   ```
   Shows `PM: suspend entry (s2idle)` with **no** `PM: suspend exit` — the kernel never logs a resume.

2. **No GPU error messages.** Unlike other known amdgpu resume issues, there are no MES timeout, VPE queue reset, or SMU errors in the journal. The hang occurs at a level below where the journal can write.

3. **Frozen framebuffer, not black screen.** The display shows the last rendered frame. This distinguishes it from DPMS/EDID resume failures which produce a black screen.

4. **amd_pmc deepest-state warning.** Even in successful suspend cycles, the journal shows:
   ```
   amd_pmc AMDI000A:00: Last suspend didn't reach deepest state
   ```
   This indicates s2idle is not reaching S0i3, which is a precondition for the issue.

## What a Successful Resume Looks Like

From the last known working suspend at 14:26 on 2026-03-21 (kernel 6.19.6, firmware 20260221):

```
PM: suspend entry (s2idle)
Filesystems sync: 0.002 seconds
Freezing user space processes
Freezing user space processes completed (elapsed 0.001 seconds)
OOM killer disabled.
Freezing remaining freezable tasks
Freezing remaining freezable tasks completed (elapsed 0.001 seconds)
printk: Suspending console(s) (use no_console_suspend to debug)
ACPI: EC: interrupt blocked
amd_pmc AMDI000A:00: Last suspend didn't reach deepest state
ACPI: EC: interrupt unblocked
[drm] PCIE GART of 512M enabled (table at 0x0000008000F00000).
amdgpu 0000:c1:00.0: amdgpu: SMU is resuming...
amdgpu 0000:c1:00.0: amdgpu: SMU is resumed successfully!
nvme nvme0: 16/0/0 default/read/poll queues
<amdgpu ring re-initialization>
OOM killer enabled.
Restarting tasks: Starting
Restarting tasks: Done
PM: suspend exit
```

In broken resumes, the journal stops at `PM: suspend entry (s2idle)` — nothing after it, not even "Freezing user space processes."

## Timeline of 2026-03-21

| Time | Event | Suspend Status |
|---|---|---|
| 10:31 | Successful suspend/resume | Working |
| 12:19 | Boot, cmdline: `...rw` | |
| 12:58 | logind drop-in: `HandlePowerKey=ignore` | |
| ~13:00 | `quiet loglevel=3 systemd.show_status=auto` added to arch.conf | |
| 14:25 | Successful suspend/resume | **Last known working** |
| 14:28 | Reboot, cmdline: `...rw quiet loglevel=3 systemd.show_status=auto` | |
| 14:36 | Plymouth installed, initramfs rebuilt 4 times with various HOOKS | |
| 14:42 | Reboot with Plymouth in initramfs, `splash` added to cmdline | Never tested |
| 15:39 | `paru -Syu` — kernel 6.19.6→6.19.9, firmware 20260221→20260309, mesa 26.0.1→26.0.3, systemd 259.3→260, +90 other packages | |
| 15:41 | Additional AUR upgrades | |
| ~18:00+ | First suspend attempt after upgrades | **Broken** |

**Key ambiguity:** Suspend was never tested between the Plymouth install (14:36) and the system upgrade (15:39). We cannot determine which change caused the regression.

## What Was Tried

### Package Downgrades

| Downgrade | Result |
|---|---|
| linux 6.19.9 → 6.19.6 + firmware 20260309 → 20260221 (kernel+firmware only) | Still broken |
| + mesa 26.0.3 → 26.0.1 + vulkan-radeon + vulkan-mesa-implicit-layers | Still broken |
| + llvm-libs 22.1.1 → 21.1.8 (required for mesa 26.0.1) | Still broken |
| Full `paru -Syu` back to latest | Still broken |
| All packages + systemd + pipewire downgraded together | Broke Hyprland (ABI mismatch) |

**Note:** The full rollback to pre-upgrade package versions still failed, which suggests either the issue is not purely package-related, or the test environment was not identical to the 14:26 state.

### Kernel Parameters

| Parameter | Result |
|---|---|
| `amd_iommu=fullflush` | No effect |
| `amdgpu.cwsr_enable=0` | No effect |
| `amdgpu.cwsr_enable=0 amdgpu.sg_display=0` | No effect |
| Removed `splash` | No effect |
| Removed `quiet loglevel=3 systemd.show_status=auto` | No effect |

### System Config Changes

| Change | Result |
|---|---|
| Blacklisted amdxdna (NPU driver) | No effect |
| Removed Plymouth from mkinitcpio HOOKS + rebuilt initramfs | No effect |
| Added `account`/`session` to hyprlock PAM config | No effect |
| Reverted hyprlock.conf to pre-today state (removed fingerprint auth block, grim screenshot) | No effect |
| Reverted hypridle.conf to pre-today state (removed grim from lock_cmd) | No effect |
| `killall hypridle; systemctl suspend` (bypass hyprlock entirely) | Still broken |
| Clean `mkinitcpio -P` rebuild | No effect |

### What Was NOT Tried

- BIOS update beyond 03.05 (3.07+ reportedly helps but not yet publicly released as stable)
- Hibernate (S4) as alternative to s2idle — the system does support S4
- `no_console_suspend` kernel parameter for debug output during resume
- Booting a live USB / older kernel from Arch archive to isolate hardware vs software
- Reseating RAM modules (reported to temporarily help in Framework community)
- Testing suspend from a bare TTY without Hyprland running (we tested without hyprlock/hypridle but Hyprland was still the compositor)

## Relevant Community Threads

- [Framework 13 AI 300 Series won't resume most of the time](https://community.frame.work/t/framework-13-ai-300-series-wont-resume-most-of-the-time/72695) — CL40 vs CL46 RAM incompatibility
- [AMD GPU MES Timeouts Causing System Hangs](https://community.frame.work/t/amd-gpu-mes-timeouts-causing-system-hangs-on-framework-laptop-13-amd-ai-300-series/71364) — upstream amdgpu TLB fence fix for kernel 7.0
- [Framework 13 Ryzen AI 300 Fails to Properly Suspend](https://community.frame.work/t/framework-13-ryzen-ai-300-fails-to-properly-suspend-and-resume-from-suspend/74660) — `amd_iommu=fullflush` workaround (didn't work for us)
- [S2idle resumes with a black screen](https://community.frame.work/t/s2idle-resumes-with-a-black-screen-forcing-me-to-reboot-manually-each-time/81173) — amdxdna NPU driver firmware mismatch
- [Crashing on sleep (AMD Ryzen AI 300 Series)](https://community.frame.work/t/crashing-on-sleep-amd-ryzen-ai-300-series/79210) — kernel regression in 6.19.4, VPE driver race condition identified by AMD
- [Critical bugs in amdgpu driver in kernel 6.18.x / 6.19.x](https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221) — CWSR/MES/VPE bugs, recommends 6.15–6.17 or 7.0
- [Significant suspend regressions on Framework 13/AMD Linux 6.18.2 (Arch)](https://community.frame.work/t/significant-suspend-regressions-on-framework-13-amd-linux-6-18-2-arch/79057) — linux-firmware downgrade helped some users
- [amd_pmc: Last suspend didn't reach deepest state](https://community.frame.work/t/amd-pmc-last-suspend-didnt-reach-deepest-state/81219) — linux-firmware 20260221 regression, fixed in 20260309
- [linux-firmware amdgpu regression (NixOS)](https://github.com/nixos/nixpkgs/issues/466945) — SMU firmware mismatch between driver and firmware versions
- [ROCm issue #5844](https://github.com/ROCm/ROCm/issues/5844) — MES TLB fence fix tracking for kernel 7.0
- [Hyprlock crash investigation #953](https://github.com/hyprwm/hyprlock/issues/953) — multiple crash causes including DPMS, suspend, PAM
- [Framework Laptop 13 Ryzen AI300 BIOS 3.05 Release](https://community.frame.work/t/framework-laptop-13-ryzen-ai300-bios-3-05-release-stable/77778) — watch for newer BIOS releases

## Second Occurrence (2026-03-22)

Suspend froze again overnight. The laptop was suspended via hypridle at 01:00:02 and never resumed — journal ends at `Performing sleep operation 'suspend'...` with no kernel-level `PM: suspend entry` logged. Required a hard power-off; cold boot at 09:18:11.

This confirms the issue persists across reboots and is not a one-time event.

## Hibernate (S4) Workaround

**Status:** Tested and working as of 2026-03-22.

Hibernate bypasses the broken s2idle path entirely by writing RAM to disk and fully powering off. Resume loads the image from swap after LUKS unlock.

### Setup

Hibernate is opt-in per machine via a flag file. On affected machines:
```bash
touch ~/.config/hypr/use-hibernate    # enable hibernate
rm ~/.config/hypr/use-hibernate       # disable (revert to suspend)
```

When the flag exists:
1. **hypridle** uses `systemctl hibernate` instead of `systemctl suspend` at 30-minute idle
2. **wlogout** suspend button runs `systemctl hibernate` instead of `systemctl suspend`
3. **logind** lid close triggers hibernate (configured by `setup.sh` when flag is present)

Infrastructure (set up on all LUKS+systemd-boot machines by `setup.sh`):
1. **Swap file** at `/swapfile`, sized to RAM (>= RAM required for hibernate)
2. **Kernel params**: `resume=/dev/mapper/cryptroot resume_offset=<N>` in boot entry
3. **No extra initramfs hook** needed — systemd-based initramfs (`sd-encrypt`) handles resume natively

### Tradeoffs vs Suspend

| | Suspend (s2idle) | Hibernate (S4) |
|---|---|---|
| Resume time | ~1-2 seconds | ~5-10 seconds |
| Power draw while asleep | Small but nonzero | Zero |
| SSD write wear | None | Writes full RAM to swap each cycle |
| Reliability on this hardware | **Broken** | Working |

### Testing the Bug

To check if the suspend bug is fixed after a kernel or BIOS update:
```bash
systemctl suspend
```
If the system resumes cleanly, disable the workaround:
```bash
rm ~/.config/hypr/use-hibernate
sudo rm /etc/systemd/logind.conf.d/lid-hibernate.conf
```

## Upstream Research (as of 2026-03-22)

### Known amdgpu Regression in 6.18.x / 6.19.x

A [Framework community thread](https://community.frame.work/t/attn-critical-bugs-in-amdgpu-driver-included-with-kernel-6-18-x-6-19-x/79221) warns of critical amdgpu driver bugs in kernels 6.18.x and 6.19.x affecting RDNA3/RDNA4 GPUs. Broken CWSR causes MES ring buffer saturation, VPE queue reset failures, and hard hangs. Recommended stable kernels are **6.15–6.17** until 7.0 lands. This may explain why downgrading within 6.19.x didn't help.

### MES Fix Confirmed for Kernel 7.0

Mario Limonciello (AMD kernel engineer) confirmed the MES TLB fence fix has been merged for kernel 7.0 ([ROCm issue #5844](https://github.com/ROCm/ROCm/issues/5844)). He also stated the underlying s2idle issue is being **fixed in BIOS**, not just kernel.

### VPE Driver Race Condition

AMD identified a race condition in the VPE (Video Processing Engine) driver during s0i3 entry. The [revert commit](https://lists.freedesktop.org/archives/amd-gfx/2025-December/134729.html) for `"drm/amd: Skip power ungate during suspend for VPE"` landed in kernel 6.19.6, but the deeper s2idle issue it exposed is a BIOS-level problem.

### linux-firmware Regression

A [community report](https://community.frame.work/t/amd-pmc-last-suspend-didnt-reach-deepest-state/81219) identified `linux-firmware 20260221` as introducing an AMD microcode regression preventing the deepest sleep state, fixed in `20260309`. However, we tested both versions with no change — suggesting multiple interacting issues or a different root cause in our case.

### RAM Compatibility Ruled Out

CL40 DDR5 RAM (particularly Mushkin) causes suspend failures on AI 300 series. Our RAM is ADATA AD5S560016G-SFW (**CL46**) — not affected.

### No New BIOS Available

BIOS 03.05 remains the latest stable release for the AI 300 series as of 2026-03-22. References to "3.07" in community threads are for other Framework models (Intel 13th Gen, Framework 16).

## Likely Root Cause

The AMD Ryzen AI 300 (Strix Point) platform's s2idle implementation is fragile. The `amd_pmc` driver consistently reports `Last suspend didn't reach deepest state`, meaning the system never enters S0i3 — it idles in a shallow sleep state where resume reliability depends on firmware behavior.

Multiple interacting issues exist in kernels 6.18–6.19 (CWSR/MES/VPE bugs). The most probable fixes are:
- **BIOS update from Framework** beyond 03.05 (AMD engineer confirmed s2idle fix is BIOS-side)
- **Kernel 7.0** for the amdgpu MES TLB fence fix

## Next Steps

1. **Watch for Framework BIOS updates** beyond 03.05 at [Framework BIOS releases](https://community.frame.work/t/framework-laptop-13-ryzen-ai300-bios-3-05-release-stable/77778)
2. **Test kernel 7.0** when available — MES fix confirmed merged
3. **Try `no_console_suspend` kernel param** to get debug output during the hang
4. **Try suspend from bare TTY** (no Hyprland) to fully rule out compositor involvement
5. **File a bug** at [FrameworkComputer/SoftwareFirmwareIssueTracker](https://github.com/FrameworkComputer/SoftwareFirmwareIssueTracker/issues) for AMD engineering visibility

## Resolution (2026-06-12)

The culprit was the **Intel AX210 wifi card**, not amdgpu, BIOS, or the kernel. Replacing it with the platform-validated MediaTek MT7925 (AMD RZ717) made suspend/resume fully reliable on kernel 7.1-rc7.

What happened in June 2026, in order:

1. A *separate* bug — an amdgpu/TTM NULL deref (`ttm_lru_bulk_move_del`) introduced in kernel 7.0 — started hard-freezing **hibernate** resume too. Fixed by running mainline 7.1-rc (commit `b2ed01e7ad3d`, first in v7.1-rc4). Three kernels are now installed: `linux`, `linux-lts` (fallback), `linux-mainline` (default until Arch ships 7.1 stable). **[Correction, 2026-06-22: this was wrong. `b2ed01e7ad3d` (a swapout LRU-walk fix) did NOT fix it — the TTM NULL deref persisted into 7.1.0 and was later proven by ramoops capture. The real fix is still in upstream review. See the final section.]**
2. With hibernate fixed, suspend testing on 7.1-rc7 showed the AX210 dying on s2idle resume: card off the PCI bus ("Unable to change power state from D3hot to D0, device inaccessible", config space all `0xffffffff`, firmware SecBoot `0x5a5a5a5a`), followed by a ~1-minute desktop hang (driver firmware-restart retries holding rtnl) and the *next* suspend aborting with "Device or resource busy" (screen stays on lock screen).
3. Upstream research showed this AX210-on-AMD failure is known and unfixed: three AX210 firmware updates (Dec 2025–Mar 2026), a disputed un-merged kernel revert (`STATUS_SUSPENDED`), and an Intel resume workaround merged 2026-05-31 (`093305d801fa`, "for unclear reasons, grabbing NIC access was harmful") that was already in 7.1-rc7 and didn't help. See Framework thread [Intel AX210 system hang on resume](https://community.frame.work/t/intel-ax210-wifi-system-hang-on-resume-from-standby/79977) — same platform, same card, matching reports since January 2026.
4. **Hardware swap to MT7925**: no driver work needed (`mt7925e` ships in every kernel; `linux-firmware-mediatek` already installed, including Bluetooth blobs). Suspend/resume now works, including back-to-back cycles.

In hindsight, the original March freeze (journal ending at suspend entry, hard hang) matches the AX210 hang reports in the Framework thread above — the card likely was the root cause all along, masked by the concurrent amdgpu/kernel churn.

Cleanup done with the swap:
- `/etc/udev/rules.d/81-wifi-no-d3cold.rules` (AX210 workaround, live-only) — removed
- The `~/.config/hypr/use-hibernate` flag mechanism described above — removed entirely (flag file, hypridle/wlogout runtime checks, setup.sh lid branching); recover it from git history if a future regression breaks suspend
- Sleep mode is now **suspend-then-hibernate**: `HibernateDelaySec=6h` via `/etc/systemd/sleep.conf.d/hibernate-delay.conf`, lid via `/etc/systemd/logind.conf.d/lid-sleep.conf`, both written by `setup.sh`

## TTM Hibernate Lockup (kernel 7.0+ regression) & linux-lts Pin

**Date:** 2026-06-22
**Status:** MITIGATED — boot `linux-lts` 6.18 by default (set in `loader.conf` by `setup.sh`, commit `f94433e`). Upstream fix is in review but **not yet merged**. Swap back to a mainline `linux` kernel once the fix lands — see **Exit Criteria** below.

### Root cause (proven via ramoops capture)

A NULL-pointer dereference in TTM's bulk-move LRU bookkeeping, in the buffer **eviction** path. Captured 2026-06-22 (`~/lockup-dump-20260622-143751.txt`, via `~/lockup-trap.sh`):

```
BUG: kernel NULL pointer dereference, address: 0x10   (RDI = 0)
RIP: ttm_lru_bulk_move_del+0xd4/0x120 [ttm]
  ttm_lru_bulk_move_del   <- faults on NULL
  ttm_resource_free
  amdgpu_bo_move           <- a buffer is being evicted/moved
  ttm_bo_handle_move_mem
  ttm_bo_validate
  amdgpu_cs_bo_validate
  amdgpu_cs_ioctl          <- during GPU command submission
```

The faulting task oopses **while holding `lru_lock` with IRQs disabled** (`exited with irqs disabled, preempt_count 1`). The spinlock is never released → every other GPU client deadlocks on it ~26s later in `native_queued_spin_lock_slowpath` → soft-lockup cascade → hard hang. **The lock-held-forever hang is the symptom; the NULL deref is the cause.** (Earlier diagnoses chasing the soft-lockup / an `pm_async` async-resume theory were wrong — they only ever saw the lock *waiters*, never the holder.)

**Trigger:** GPU buffer eviction under VRAM pressure (only 512 MB VRAM). In practice: opening a heavy GPU client (Zen browser), worse with the `bijutsu` LLM service holding GPU/KFD memory. Often after a hibernate cycle, but NOT strictly resume-timing — it can fire minutes into normal use. The benign `VM memory stats … non-zero when fini` and `VPE queue reset failed` warnings appear on clean resumes too and are **not** the bug.

### Why linux-lts fixes it

Regression window: **6.19.11 good → 7.0+ bad**. The bug is fallout from the Jan-2025 refactor [*"drm/ttm: use ttm_resource_unevictable() to replace pin_count and swapped"*](https://www.mail-archive.com/dri-devel@lists.freedesktop.org/msg507817.html), which landed in 7.0. `linux-lts` 6.18.36 predates it (confirmed sideways: the 7.0-stable swapout backport *failed to apply to 6.18-stable* — 6.18 lacks the buggy code). Validated 2026-06-22: hibernate → resume → Zen under load on 6.18 = zero crash.

### Upstream fix (in review, NOT merged as of 2026-06-22)

Two overlapping series on dri-devel fix the bulk_move / unevictable-resource corruption:
- **Samuel Ainsworth** — *"drm/ttm: fix bulk_move cursor use-after-free for unevictable resources"* / *"don't leave bulk_move cursor dangling for unevictable resources"* + regression tests. Reviewed by Christian König (TTM/amdgpu maintainer). June 2026.
- **Thomas Hellström** — [*"drm/ttm: Really use a separate LRU list for swapped- and pinned objects"*](https://www.mail-archive.com/dri-devel@lists.freedesktop.org/msg508207.html) (v5). Deeper rework: pinned/swapped objects weren't being moved off the LRU list.

**Do not file a new bug** — it would duplicate this active, maintainer-reviewed work. The only useful upstream contribution would be a `Tested-by:` confirming the fix on Ryzen AI 300, which needs a locally-built patched kernel (optional).

### Exit Criteria — when to swap back off linux-lts default

Swap the default boot entry back to mainline (`arch.conf` / `arch-mainline.conf`) once **both** hold:
1. One of the fixes above has **merged to mainline and been backported into the Arch `linux` (or `linux-mainline`) version you're running** — check the package changelog / kernel `git log` for "bulk_move cursor" or the merged commit hash; and
2. It **passes the reproducer** on this machine.

Procedure (re-test periodically, e.g. monthly or when a new `linux` major lands):
```bash
~/lockup-trap.sh arm && sudo reboot       # then pick the NON-LTS entry at the menu
~/lockup-trap.sh status                   # confirm "ramoops ACTIVE this boot"
# Hammer the reproducer: systemctl hibernate -> resume -> open Zen + GPU/mem load,
# churn windows. Bug is ~15%/cycle, so survive >=10 cycles before trusting it.
~/lockup-trap.sh dump                     # should find nothing if fixed
# If clean, make mainline the default again and tear down the pin:
sudo sed -i 's/^default .*/default arch.conf/' /boot/loader/loader.conf
~/lockup-trap.sh disarm
```
Then revert the `setup.sh` LTS-default block added in commit `f94433e`.

**Why swap back at all:** the MT7925 wifi (mt76) hard-lockup fix landed in **7.1.0 mainline** — there is no single mainline version with *both* that wifi fix and the pre-7.0 TTM code, so on LTS 6.18 you depend on the wifi fix being backported to 6.18.x (probable but unverified). A current kernel with the TTM fix merged restores both. If a **wifi-related** freeze ever appears on LTS, that's the likely cause — check whether the mt76 fix is actually in 6.18.x.
