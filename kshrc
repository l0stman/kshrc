user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

typeset alt_on alt_off hbar=- ulcorner=- llcorner=-

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
    typeset dir="${PWD}"
    typeset termwidth=${COLUMNS}
    typeset prompt="--[${user}@${host}:${tty}]--(${PWD})--"
    typeset size=${#prompt}
    
    if [[ $size -gt $termwidth ]]; then
	dir="...$(echo ${dir} | cut -c $(( 1 + $size - $termwidth + 3 ))-)"
    fi

    print "$dir"
}

# Print a line composed of _padsiz characters
_padline ()
{
    
    typeset padsiz i=0 line=${alt_on}
    typeset prompt="--[${user}@${host}:${tty}]--(${PWD})--"
    
    padsiz=$(( ${COLUMNS} - ${#prompt} ))
    while [[ $i -lt $padsiz ]]; do
	line=${line}${hbar}
	(( i++ ))
    done
    line=${line}${alt_off}
    print -n $line
}

PS1="\
${alt_on}${ulcorner}${hbar}${alt_off}\
[${user}@${host}:${tty}]\
\$(_padline)\
${alt_on}${hbar}${hbar}${alt_off}\
(\$(_tpwd))\
${alt_on}${hbar}${hbar}${alt_off}\

${alt_on}${llcorner}${hbar}${alt_off}\$ "
