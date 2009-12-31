user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

typeset alt_on alt_off hbar=- ulcorner=- llcorner=-

if tput as; then
    # Terminal supports alternative charset mode, see termcap(5)
    tput ae
    alt_on=$(tput as)
    alt_off=$(tput ae)
    hbar=q
    ulcorner=l
    llcorner=m
fi

# Show a truncated current directory if too long.
_tpwd ()
{
    typeset dir="${PWD:-$(pwd)}"
    typeset termwidth=${COLUMNS:-$(tput col)}
    typeset prompt="--[${user}@${host}:${tty}]--(${dir})--"
    typeset size=${#prompt}
    
    if [[ $size -gt $termwidth ]]; then
	dir="...$(print ${dir} | cut -c $(( $size - $termwidth + 4 ))-)"
    fi

    print "$dir"
}

# Print a line composed of _padsiz characters
_padline ()
{
    
    typeset padsiz i=0 line=${alt_on}
    typeset prompt="--[${user}@${host}:${tty}]--(${PWD:-$(pwd)})--"
    typeset termwidth=${COLUMNS:-$(tput col)}
    
    padsiz=$(( $termwidth - ${#prompt} ))
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
