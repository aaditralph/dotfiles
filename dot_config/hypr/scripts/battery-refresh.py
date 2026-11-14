import fcntl
import os
from pathlib import Path
import subprocess
import sys

from gi.repository import Gio, GLib


KEYBOARD_LEVEL = Path("/sys/class/leds/asus::kbd_backlight/brightness")
KEYBOARD_LEVELS = {0: "off", 1: "low", 2: "med", 3: "high"}
STATE_HOME = Path(os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state")
KEYBOARD_STATE = STATE_HOME / "hyprland-battery-refresh" / "keyboard-brightness"
BACKLIGHT = Path("/sys/class/backlight/nvidia_wmi_ec_backlight")
DISPLAY_PERCENT = {"battery": 32, "ac": 100}


def apply_display(mode):
    runtime = Path(os.environ["XDG_RUNTIME_DIR"])
    saved = runtime / "hyprland-display-idle-level"
    with (runtime / "hyprland-display-brightness.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        maximum = int((BACKLIGHT / "max_brightness").read_text())
        current = int((BACKLIGHT / "brightness").read_text())
        idle = saved.exists()
        if mode == "idle":
            if idle:
                return
            level = current
            idle = True
        elif mode == "resume":
            if not idle:
                return
            level = int(saved.read_text())
            idle = False
        else:
            level = round(maximum * DISPLAY_PERCENT[mode] / 100)

        if idle:
            # Resume to the latest power profile even if the charger changed while idle.
            pending = saved.with_suffix(".new")
            pending.write_text(f"{level}\n")
            pending.replace(saved)
            level = max(2, level - round(maximum * 0.30))
        if current != level:
            subprocess.run(
                ["/usr/bin/brightnessctl", "-q", "-d", BACKLIGHT.name, "set", str(level)],
                check=True, timeout=8,
            )
        if mode == "resume":
            saved.unlink()


def apply_keyboard(on_battery):
    if on_battery:
        current = int(KEYBOARD_LEVEL.read_text())
        if current == 0:
            return
        if not KEYBOARD_STATE.exists():
            KEYBOARD_STATE.parent.mkdir(parents=True, exist_ok=True)
            pending = KEYBOARD_STATE.with_suffix(".new")
            pending.write_text(f"{current}\n")
            pending.replace(KEYBOARD_STATE)
        level = 0
    else:
        try:
            level = int(KEYBOARD_STATE.read_text())
        except FileNotFoundError:
            return

    setting = KEYBOARD_LEVELS[level]
    subprocess.run(["/usr/bin/asusctl", "leds", "set", setting], check=True, timeout=8)
    if not on_battery:
        KEYBOARD_STATE.unlink()
    print(f"Set keyboard lighting to {level}", flush=True)


def apply_power_settings(upower):
    on_battery = upower.get_cached_property("OnBattery")
    if on_battery is None:
        return

    on_battery = on_battery.get_boolean()
    mode = "battery" if on_battery else "ac"
    try:
        apply_display(mode)
        print(f"Set display brightness profile to {DISPLAY_PERCENT[mode]}% ({mode})", flush=True)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"Could not set display brightness: {error}", file=sys.stderr)

    hz = 60 if on_battery else 144
    rule = f'hl.monitor({{output = "eDP-1", mode = "1920x1080@{hz}", position = "auto", scale = 1}})'
    result = subprocess.check_output(["/usr/bin/hyprctl", "eval", rule], text=True, timeout=8)
    if result.strip() != "ok":
        raise RuntimeError(result.strip())
    print(f"Set eDP-1 to {hz} Hz", flush=True)
    try:
        apply_keyboard(on_battery)
    except (OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"Could not set keyboard lighting: {error}", file=sys.stderr)


def main():
    upower = Gio.DBusProxy.new_for_bus_sync(
        Gio.BusType.SYSTEM, Gio.DBusProxyFlags.GET_INVALIDATED_PROPERTIES, None,
        "org.freedesktop.UPower", "/org/freedesktop/UPower", "org.freedesktop.UPower", None,
    )
    loop = GLib.MainLoop()

    def power_changed(proxy, changed, _invalidated):
        if "OnBattery" in changed.unpack():
            try:
                apply_power_settings(proxy)
            except (OSError, subprocess.SubprocessError, RuntimeError) as error:
                print(error, file=sys.stderr)
                loop.quit()

    upower.connect("g-properties-changed", power_changed)
    apply_power_settings(upower)
    loop.run()
    return 1


if __name__ == "__main__":
    if sys.argv[1:] in (["idle"], ["resume"]):
        apply_display(sys.argv[1])
    else:
        sys.exit(main())
