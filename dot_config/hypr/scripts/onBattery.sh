#!/usr/bin/env bash
# power-mode-battery.sh
# Applied when the AC adapter is unplugged. Run as root.
# Triggered automatically by udev (see 99-power-mode.rules), or run manually
# any time with: sudo /usr/local/bin/power-mode-battery.sh

set -uo pipefail

log() { echo "[power-mode-battery] $*"; }

# ---------------------------------------------------------------------------
# PCIe ASPM -> deepest link power state
# ---------------------------------------------------------------------------
if [ -w /sys/module/pcie_aspm/parameters/policy ]; then
  echo powersupersave > /sys/module/pcie_aspm/parameters/policy
  log "PCIe ASPM policy set to powersupersave"
fi

# ---------------------------------------------------------------------------
# CPU governor + EPP
# ---------------------------------------------------------------------------
for cpu_dir in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
  [ -d "$cpu_dir" ] || continue
  [ -w "$cpu_dir/scaling_governor" ] && echo powersave > "$cpu_dir/scaling_governor"
  [ -w "$cpu_dir/energy_performance_preference" ] && echo power > "$cpu_dir/energy_performance_preference"
done
log "CPU governor set to powersave, EPP set to power"

# ---------------------------------------------------------------------------
# power-profiles-daemon -> power-saver
# ---------------------------------------------------------------------------
if command -v powerprofilesctl &>/dev/null; then
  powerprofilesctl set power-saver
  log "power-profiles-daemon set to power-saver"
fi

# ---------------------------------------------------------------------------
# dGPU -> integrated-only mode, fully cut power to the dGPU
# ---------------------------------------------------------------------------
if command -v cardwire &>/dev/null; then
  if cardwire set integrated 2>/tmp/cardwire_err.log; then
    log "cardwire set to integrated mode"
  else
    log "WARNING: cardwire set integrated failed, see /tmp/cardwire_err.log"
  fi
fi

# ---------------------------------------------------------------------------
# Aura RGB keyboard lighting -> disabled
# ---------------------------------------------------------------------------
if command -v asusctl &>/dev/null; then
  if asusctl aura power-tuf --awake false --keyboard --boot false --sleep false 2>/tmp/asusctl_err.log; then
    log "Aura lighting disabled"
  else
    log "WARNING: asusctl aura power-tuf failed, see /tmp/asusctl_err.log"
  fi
fi

log "Battery profile applied."
