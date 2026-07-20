#!/usr/bin/env bash
# power-mode-ac.sh
# Applied when the AC adapter is plugged in. Run as root.
# Triggered automatically by udev (see 99-power-mode.rules), or run manually
# any time with: sudo /usr/local/bin/power-mode-ac.sh

set -uo pipefail

log() { echo "[power-mode-ac] $*"; }

# ---------------------------------------------------------------------------
# PCIe ASPM -> back to default (no need to force deepest link power states
# when plugged in)
# ---------------------------------------------------------------------------
if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
  echo default > /sys/module/pcie_aspm/parameters/policy
  log "PCIe ASPM policy set to default"
fi

# ---------------------------------------------------------------------------
# CPU governor + EPP
# ---------------------------------------------------------------------------
for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
  [ -d "$cpu_dir" ] || continue
  [ -w "$cpu_dir/scaling_governor" ] && echo powersave > "$cpu_dir/scaling_governor"
  [ -w "$cpu_dir/energy_performance_preference" ] && echo balance_performance > "$cpu_dir/energy_performance_preference"
done
log "CPU governor set to powersave, EPP set to balance_performance"

# ---------------------------------------------------------------------------
# power-profiles-daemon -> balanced
# ---------------------------------------------------------------------------
if command -v powerprofilesctl &>/dev/null; then
  powerprofilesctl set balanced
  log "power-profiles-daemon set to balanced"
fi

# ---------------------------------------------------------------------------
# dGPU -> hybrid mode (available again for use)
# ---------------------------------------------------------------------------
if command -v cardwire &>/dev/null; then
  if cardwire set hybrid 2>/tmp/cardwire_err.log; then
    log "cardwire set to hybrid mode"
  else
    log "WARNING: cardwire set hybrid failed, see /tmp/cardwire_err.log"
  fi
fi

# ---------------------------------------------------------------------------
# Aura RGB keyboard lighting -> restored
# ---------------------------------------------------------------------------
if command -v asusctl &>/dev/null; then
  if asusctl aura power-tuf --awake true --keyboard --boot true --sleep true 2>/tmp/asusctl_err.log; then
    log "Aura lighting restored"
  else
    log "WARNING: asusctl aura power-tuf failed, see /tmp/asusctl_err.log"
  fi
fi

log "AC profile applied."
