# Initialize the zsh completion system system-wide.
#
# Fedora ships zsh as the default login shell (/etc/default/useradd). Fedora's
# /etc/zshrc sources every /etc/zshrc.d/*.zsh, but it does NOT initialize the
# completion system, so `compinit`/`compdef` are undefined and any plugin or user
# rc that calls them fails with "command not found". This runs before the user's
# ~/.zshrc, making compdef available to it.
#
# Only set up completion for interactive shells.
if [[ -o interactive ]]; then
  autoload -Uz compinit
  # -i: silently ignore insecure directories instead of prompting.
  compinit -i
fi
