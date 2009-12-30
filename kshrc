user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

local alt_on alt_off hbar=- ulcorner=- llcorner=-

if tput as; then
    # Terminal supports alternative charset mode, see termcap(5)
    alt_on=$(tput as)
    alt_off=$(tput ae)
    hbar=q
    ulcorner=l
    llcorner=m
fi

# Show a truncated current directory if too long.
_tpwd ()
{
    local dir
    local termwidth=${COLUMNS}
    local size=$(( ${#_ulprompt} + ${#PWD} + 4))
    
    if [[ $size -gt $termwidth ]]; then
	dir="...$(echo ${PWD} | cut -c $(( 1 + $size - $termwidth + 3 ))-)"
    else
	dir="${PWD}"
    fi

    echo "$dir"
}

# Print a line composed of _padsiz characters
_padline ()
{
    local _padsiz i=0 line=${alt_on} dir=$(_tpwd)

    _padsiz=$(( ${COLUMNS} - ${#_ulprompt} - ${#dir} - 4 ))
    while [[ $i -lt $_padsiz ]]; do
	line=${line}${hbar}
	(( i++ ))
    done
    line=${line}${alt_off}
    echo -n $line
}

_setprompt ()
{
    # Upper left prompt
    _ulprompt="\
${alt_on}${ulcorner}${hbar}${alt_off}\
[${user}@${host}:${tty}]\
${alt_on}${hbar}${alt_off}"

    # Upper right prompt
    _urprompt="\
${alt_on}${hbar}${alt_off}\
(\$(_tpwd))\
${alt_on}${hbar}${alt_off}"

    PS1="\
${_ulprompt}\$(_padline)${_urprompt}
${alt_on}${llcorner}${hbar}${alt_off}\$ "
}

_setprompt
