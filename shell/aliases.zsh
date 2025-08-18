# Blue Water Autonomy
alias bwatestbench='ssh bwatestbench'

# OS
alias -- -='cd -'
alias ..='cd ../'
alias ...=../..
alias ....=../../..
alias .....=../../../..
alias ......=../../../../..
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias _='sudo '
alias aliasg='alias | grep '
alias envg='env | grep -i'
alias envs='env | sort'
alias guid='uuidgen | tr "[:upper:]" "[:lower:]"'
alias localip="ifconfig | grep 'inet ' | grep -v 127.0.0.1 | cut -d\\  -f2"
alias ls='ls -lGh'
alias la='ls -laXh'
alias open-chrome='open -a "Google Chrome"'
alias open-ports="lsof -i -P -n | grep LISTEN"
alias path-list='echo $PATH | tr ":" "\n"'
alias publicip="dig +short myip.opendns.com @resolver1.opendns.com"
alias week='date +%V'

# Weather
function weather() {
  curl "https://wttr.in/$1"
}

function wslim() {
  curl "https://wttr.in/$1?format=%cWeather+in+%l:+%C+%t,+%p+%w"
}
