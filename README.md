# CachyOS laptop dotfiles

This repo manages the Hyprland and Plasma desktop settings, GTK and Qt appearance, shell and editor configuration, OpenCode, Hermes Desktop, and the user services that support them.

## Restore

Install the desktop and applications on the new machine, then run `chezmoi init aaditralph/dotfiles`, `chezmoi diff`, and `chezmoi apply` from the graphical session. The dconf restore runs after apply when a desktop session bus is available.

Set these environment variables before the first apply if you want chezmoi to seed the related files. For existing installations, configure the apps directly or update their local files.

| Environment variable | What it configures |
| --- | --- |
| `HERMES_DESKTOP_REMOTE_URL` | The Hermes Desktop OAuth server. With no URL, the initial profile selects the local backend. Sign in again after restoring. |
| `OPENCODE_SERVICE_PASSWORD` | The local OpenCode service password. Without a password, chezmoi leaves the service file alone. |
| `ZED_STITCH_API_KEY` | The Stitch API key. Stitch starts disabled when the key is absent. |
| `ZED_SONARQUBE_AUTHORIZATION` | The Authorization header for Zed's SonarQube connection. |

The [system reference](system-reference) contains the SDDM theme, selected system and laptop power settings, and the list of explicitly installed Arch packages. Review the hardware-specific settings before copying any of these files into `/etc` or `/usr`. Chezmoi applies the user configuration in your home directory.

The local LLM service needs its llama.cpp CUDA runtime and GGUF models. The optional Hermes phone backup service needs its separately installed Hermes runtime and router, SSH access, and local credentials. Its timer can be enabled manually after setup with `systemctl --user enable --now hermes-backup-sync.timer`.

Account logins, keyrings, SSH material, app history, caches, and model weights are stored separately from this repo. Restore those through the apps or your own private backup.
