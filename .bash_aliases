# Bash-safe subset of the interactive aliases.
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons=auto'
  alias la='eza --icons=auto -la'
  alias ll='eza --icons=auto -lh'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa --icons'
  alias la='exa --icons -la'
  alias ll='exa --icons -lh'
else
  alias ls='ls --color=auto'
  alias la='ls -la --color=auto'
  alias ll='ls -lh --color=auto'
fi
command -v batcat >/dev/null 2>&1 && alias bat='batcat --style=auto'
alias ports='ss -tulpen'
alias meminfo='free -m -l -t'
alias now='date +"%T"'
alias h='history'
alias vi='vim'
alias dev='cd "$HOME/dev"'
alias restart-plasma='systemctl --user restart plasma-plasmashell.service'
