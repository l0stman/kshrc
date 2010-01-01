user=$(whoami)
host=$(hostname -s)
tty=$(tty | sed s@/dev/@@)

case $(id -u) in
    0) prompt=\#;;
    *) prompt=\$;;
esac

# Generate an associative array containing the alternative character
# set for the terminal.  See termcap (5) for more details.

typeset -A altchar

tput ac |
sed -E 's/(.)(.)/\1 \2\
/g' |
{
    while read key val; do
	if [[ -n $key ]]; then
	    altchar+=([$key]=$val)
	fi
    done
}

# Use alternative characters to draw lines if supported or degrade to
# normal characters if not.

alt_on=$(tput as)
alt_off=$(tput ae)
hbar=${altchar[q]:--}
vbar=${altchar[x]:-\|}
ulcorner=${altchar[l]:--}
llcorner=${altchar[m]:--}
urcorner=${altchar[k]:--}
lrcorner=${altchar[j]:--}
lbracket=${altchar[u]:-\[}
rbracket=${altchar[t]:-\]}

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
    typeset termwidth=$(tput co)
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
    
    typeset padsiz i line
    typeset prompt="--[${user}@${host}:${tty}]--($(_pwd))--"
    typeset termwidth=$(tput co)
    
    padsiz=$(( $termwidth - ${#prompt} ))
    line=${alt_on}
    for (( i=0; i < $padsiz; i++ )); do
	line=${line}${hbar}
    done
    line=${line}${alt_off}
    print -n -- $line
}

# Move the cursor forward to print the right prompt.
_curs_forward ()
{
    typeset right_prompt="-($(date "+%a, %d %b"))--"
    typeset pos=$(( $(tput co) - ${#right_prompt} ))

    tput RI $pos
}

# This is a two lines prompt using carriage return to have a right
# prompt too.

# Upper part.
PS1="\
${alt_on}${ulcorner}${hbar}${lbracket}${alt_off}\
${user}@${host}:${tty}\
${alt_on}${rbracket}${alt_off}\
\$(_padline)\
${alt_on}${hbar}${hbar}${alt_off}\
(\$(_tpwd))\
${alt_on}${hbar}${urcorner}${alt_off}"

# If the terminal doesn't ignore a newline after the last column and
# has automatic margin (e.g. cons25), a newline or carriage return is
# written on the next line.  So don't add a newline and for good
# mesure, move the cursor to the left before writing cr.

if ! tput am || tput xn; then
    PS1="${PS1}
"
fi

# Lower part
PS1="${PS1}\
\$(_curs_forward)\
${alt_on}${hbar}${alt_off}\
(\$(date \"+%a, %d %b\"))\
${alt_on}${hbar}${lrcorner}${alt_off}\
$(tput le)$(tput cr)\
${alt_on}${llcorner}${hbar}${alt_off}\
(\$(date +%H:%M)${alt_on}${vbar}${alt_off}${prompt})\
${alt_on}${hbar}${alt_off} "
