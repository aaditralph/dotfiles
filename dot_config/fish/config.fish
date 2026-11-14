source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx SONAR_SCANNER_HOME /opt/sonar-scanner
set -gx PATH $SONAR_SCANNER_HOME/bin $PATH
oh-my-posh init fish | source
abbr -a s "paru -Ss"
abbr -a u "paru -Syu"
zoxide init fish | source

# Hermes Agent command
fish_add_path "$HOME/.local/bin"

if set -q KITTY_WINDOW_ID
    alias ssh='kitten ssh'
end
