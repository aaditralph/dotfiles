#!/usr/bin/env bash

# Wait for Waybar's tray host so the background apps can register their icons.
for ((attempt = 0; attempt < 20; attempt++)); do
    if [[ $(/usr/bin/busctl --user --timeout=1s get-property org.kde.StatusNotifierWatcher \
            /StatusNotifierWatcher org.kde.StatusNotifierWatcher IsStatusNotifierHostRegistered 2>/dev/null) == 'b true' ]]; then
        /usr/bin/rog-control-center --autostart --background &
        exec /usr/bin/cardwire-gui --background
    fi
    sleep 0.5
done

printf 'Power tray apps could not start: no system tray host became ready.\n' >&2
exit 1
