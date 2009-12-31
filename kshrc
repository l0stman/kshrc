user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

typeset hbar=- ulcorner=- llcorner=- lbracket=[ rbracket=] vbar=\|

if tput as; then
    # Terminal supports alternative charset mode, see termcap(5)
    alt_on=$(tput as)
    alt_off=$(tput ae)
    hbar=q
    vbar=x
    ulcorner=l
    llcorner=m
    lbracket=u
    rbracket=t
fi

# Like pwd but display the $HOME directory as ~
_pwd ()
{
    typeset dir="${PWD:-$(pwd -L)}"

    dir="${dir#$HOME/}"
    case $dir in
	"$HOME")
	    dir=\~ ;;
	/*)
	    ;;
	*)
	    dir=\~/$dir ;;
    esac
    print $dir
}
	    
# Show a truncated current directory if too long.
_tpwd ()
{
    typeset dir="$(_pwd)"
    typeset termwidth=${COLUMNS:-$(tput col)}
    typeset prompt="--[${user}@${host}:${tty}]--(${dir})--"
    typeset size=${#prompt}
    
    if [[ $size -gt $termwidth ]]; then
	dir="...$(print ${dir} | cut -c $(( $size - $termwidth + 4 ))-)"
    fi

    print "$dir"
}

# Line padding such that the upper prompt occupy the terminal width.
_padline ()
{
    
    typeset padsiz i=0 line=${alt_on}
    typeset prompt="--[${user}@${host}:${tty}]--($(_pwd))--"
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
${alt_on}${ulcorner}${hbar}${lbracket}${alt_off}\
${user}@${host}:${tty}\
${alt_on}${rbracket}${alt_off}\
\$(_padline)\
${alt_on}${hbar}${hbar}${alt_off}\
(\$(_tpwd))\
${alt_on}${hbar}${hbar}${alt_off}\

${alt_on}${llcorner}${hbar}${alt_off}\
(\$(date \"+%H:%M\")${alt_on}${vbar}${alt_off}\$)\
${alt_on}${hbar}${alt_off} "
