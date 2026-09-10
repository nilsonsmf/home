# Portable zsh configuration for this dotfiles repository.

typeset -U path PATH
path=("$HOME/bin" "$HOME/.local/bin" /usr/local/bin $path)
export PATH

# Machine-only overrides and secrets belong here, outside Git.
[[ -r "$HOME/.config/home-shell.local.zsh" ]] && source "$HOME/.config/home-shell.local.zsh"

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""
plugins=(git)

if [[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#999999'
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory histignoredups sharehistory

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Set PROMPT_ENGINE=oh-my-posh in ~/.config/home-shell.local.zsh to switch.
case "${PROMPT_ENGINE:-starship}" in
  oh-my-posh)
    if (( $+commands[oh-my-posh] )); then
      eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/dark-powerline.omp.json")"
    fi
    ;;
  starship)
    (( $+commands[starship] )) && eval "$(starship init zsh)"
    ;;
  none) ;;
  *) print -u2 "Unknown PROMPT_ENGINE: $PROMPT_ENGINE" ;;
esac

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3;5~' kill-word
bindkey '^H' backward-kill-word

export LANG="${LANG:-en_US.UTF-8}"
export STEAM_FORCE_DESKTOPUI_SCALING="${STEAM_FORCE_DESKTOPUI_SCALING:-1}"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"

if [[ -d "$HOME/.pyenv/bin" ]]; then
  path=("$HOME/.pyenv/bin" $path)
  (( $+commands[pyenv] )) && eval "$(pyenv init --path)"
  (( $+commands[pyenv] )) && eval "$(pyenv init -)"
fi

[[ -d "$HOME/.lmstudio/bin" ]] && path+=("$HOME/.lmstudio/bin")
[[ -d "$HOME/.opencode/bin" ]] && path=("$HOME/.opencode/bin" $path)
[[ -d "$HOME/.npm-global/bin" ]] && path=("$HOME/.npm-global/bin" $path)

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"

[[ -r "$HOME/.nix-profile/etc/profile.d/nix.sh" ]] && source "$HOME/.nix-profile/etc/profile.d/nix.sh"

if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"
fi

export PNPM_HOME="${PNPM_HOME:-$HOME/.local/share/pnpm}"
[[ -d "$PNPM_HOME" ]] && path=("$PNPM_HOME" $path)

(( $+commands[ng] )) && source <(ng completion script)
export PATH
