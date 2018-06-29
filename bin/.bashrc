function mkd() { mkdir -p -- "$1" && cd -P -- "$_"; }
function strip() { echo $1 | sed 's/<\/*[^>]*>//g'; }
alias ls='ls --color=auto'
alias ll='ls -lha'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../../'
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
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias pscpu='ps auxf | sort -nr -k 3'
alias wget='wget -c'
alias df='df -H'
alias top='htop'
alias killgvfs='ps aux|grep gvfs|cut -d " " -f 2,2|tr "\n" " "| xargs sudo kill -9'
alias files='du | grep -v "/$" | sort -rh | more'
alias bashrc='vim ~/.bashrc'
alias ubashrc='source ~/.bashrc'
alias pyserver='python -m SimpleHTTPServer'
