user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

setprompt ()
{
    local alt_on alt_off hbar=- ulcorner=- llcorner=-
    
    if tput as; then
    # Terminal supports alternative charset mode
    alt_on=$(tput as)
    alt_off=$(tput ae)
    hbar=q
    ulcorner=l
    llcorner=m
    fi
    
    PS1="\
${alt_on}${ulcorner}${hbar}${alt_off}\
[${user}@${host}:${tty}]${alt_on}${hbar}${alt_off}\
(\${PWD})${alt_on}${hbar}${alt_off}\

${alt_on}${llcorner}${hbar}${alt_off}\$ "
}

setprompt