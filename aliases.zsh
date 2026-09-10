# Loaded by Oh My Zsh from ~/.oh-my-zsh/custom/aliases.zsh.
if (( $+commands[eza] )); then
  alias ls='eza --icons=auto'
  alias la='eza --icons=auto -la'
  alias ll='eza --icons=auto -lh'
elif (( $+commands[exa] )); then
  alias ls='exa --icons'
  alias la='exa --icons -la'
  alias ll='exa --icons -lh'
else
  alias ls='ls --color=auto'
  alias la='ls -la --color=auto'
  alias ll='ls -lh --color=auto'
fi

(( $+commands[batcat] )) && alias bat='batcat --style=auto'
alias ports='ss -tulpen'
alias meminfo='free -m -l -t'
alias now='date +"%T"'
alias h='history'
alias vi='vim'
alias i='sudo apt install'
alias r='sudo apt remove'
alias s='apt search'
alias dev='cd "$HOME/dev"'
alias zreload='exec zsh'
alias restart-plasma='systemctl --user restart plasma-plasmashell.service'
