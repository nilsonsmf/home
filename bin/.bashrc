alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
function mkd() { mkdir -p -- "$1" && cd -P -- "$_"; }
function strip() { echo $1 | sed 's/<\/*[^>]*>//g'; }
function newalias() { echo "alias ${1}" >> ~/.bashrc; source ~/.bashrc; }
alias l='ls -CF'
alias la='ls -A'
alias ls='ls --color=auto'
alias ll='ls -lha'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../'
alias grep='grep --color=auto'
alias mkdir='mkdir -pv'
alias mount='mount |column -t'
alias h='history'
alias now='date +"%T"'
alias vi=vim
alias ports='netstat -tulanp'
alias apt-get="sudo apt-get"
alias update="sudo apt-get update --yes"
alias upgrade="sudo apt-get upgrade --yes"
alias search='sudo aptitude search'
alias install='sudo aptitude install'
alias arestart='sudo /etc/init.d/apache2 restart'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias wget='wget -c'
alias df='df -H'
alias top='atop'
alias killgvfs='ps aux|grep gvfs|cut -d " " -f 2,2|tr "\n" " "| xargs sudo kill -9'
alias files='du | grep -v "/$" | sort -rh | more'
alias dev='cd ~/Documentos/dev/'
alias bashrc='vim ~/.bashrc'
alias ubashrc='source ~/.bashrc'
alias pyserver='python -m SimpleHTTPServer'
alias filesbydate='find . -type f -printf "%-.22T+ %M %n %-8u %-8g %8s %Tx %.8TX %p\n" | sort | cut -f 2- -d " "'
