set -o emacs

# Generate an associative array containing the alternative character
# set for the terminal.  See termcap (5) for more details.

typeset -A altchar

function load_alt
{
    typeset key val
    
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
}

function init_parms
{
    _dir=
    _padline=
    _rpos=
    _user=$(whoami)
    _host=$(hostname -s)
    _tty=$(tty | sed s@/dev/@@)
    _has_rprompt=
    _rprompt=
    case $(id -u) in
	0) _prompt=\#;;
	*) _prompt=\$;;
    esac
    
    # Use alternative characters to draw lines if supported or degrade
    # to normal characters if not.

    load_alt
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
}

# Like pwd but display the $HOME directory as ~
function _pwd
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

# This function is executed before PS1 is referenced.  It sets the
# variable _dir to the current directory, eventually truncated if too
# long.  And it stores a line padding in _padline such that the upper
# prompt occupy the terminal width. _rpos is the position of the right
# prompt. See discipline function in the man page of ksh93.

function _hour.get
{
    .sh.value=$(date +%H:%M:%S)
}

function _date.get
{
    .sh.value=$(date "+%a, %d %b")
}

function PS1.get
{
    typeset rc=$?  # save the return value of the last command
    _dir="$(_pwd)"
    typeset uprompt="--[${_user}@${_host}:${_tty}]--(${_dir})--"
    typeset rprompt="-(${_date})--"
    integer termwidth=$(tput co)
    integer offset=$(( ${#uprompt} - ${termwidth} ))
    integer i

    if (( $offset > 0 )) ; then
	_dir="...${_dir:$(( $offset + 3 ))}"
	_padline=""
    else
	offset=$(( - $offset ))
	_padline=${alt_on}
	for (( i=0; i<$offset; i++ )); do
	    _padline=${_padline}${hbar}
	done
	_padline=${_padline}${alt_off}
    fi
    
    _rpos=$(( $termwidth - ${#rprompt} ))
    _has_rprompt=yes
    
    return $rc
}

# Right prompt.
function _rprompt.get
{
    .sh.value="\
${alt_on}${hbar}${alt_off}\
(${_date})\
${alt_on}${hbar}${lrcorner}${alt_off}"
}

# This is a two lines prompt using carriage return to display the
# right prompt.

function setprompt
{
    # Upper prompt.
    PS1="\
${alt_on}${ulcorner}${hbar}${lbracket}${alt_off}\
${_user}@${_host}:${_tty}\
${alt_on}${rbracket}${alt_off}\
\${_padline}\
${alt_on}${hbar}${hbar}${alt_off}\
(\${_dir})\
${alt_on}${hbar}${urcorner}${alt_off}"

    # If the terminal doesn't ignore a newline after the last column
    # and has automatic margin (e.g. cons25), a newline or carriage
    # return if written will be on the next line.  So don't add a
    # newline and for good mesure, move the cursor to the left before
    # writing cr at the end of a line.

    if ! tput am || tput xn; then
	PS1=${PS1}$'\n'
    fi

    # Lower prompt.
    PS1="${PS1}\
\$(tput RI \$_rpos)\
\${_rprompt}\
$(tput le)$(tput cr)\
${alt_on}${llcorner}${hbar}${alt_off}\
(\${_hour}${alt_on}${vbar}${alt_off}${_prompt})\
${alt_on}${hbar}${alt_off} "
}

# Erase the right prompt if the text reaches it and redraw it if the
# text fits in the region between the left prompt and the right one.

function _rpdisplay
{
    typeset lprompt="--(${_hour}|$)- "
    integer width=$(( ${_rpos} - ${#lprompt} - 1))
    integer pos=${#.sh.edtext}
    typeset text
    
    if (( $pos <= $width )); then
	if (( $pos == $width)); then
		tput ce
		_has_rprompt=
	elif [[ -z $_has_rprompt ]]; then
	    text=${.sh.edtext}
	    tput sc; tput vi
	    tput cr; tput RI $_rpos
	    print -n -- "${_rprompt}"
	    tput rc; tput ve
	    .sh.edtext=$text
	    _has_rprompt=yes
	fi
    fi
}

# Assoctiate a key  with an action.
typeset -A Keytable

function keybind # key [action]
{
    typeset key=$(print -f "%q" "$2")
    case $# in
    2)      Keytable[$1]=' .sh.edchar=${.sh.edmode}'"$key"
            ;;
    1)      unset Keytable[$1]
            ;;
    *)      print -u2 "Usage: $0 key [action]"
            return 2 # usage errors return 2 by default
            ;;
    esac
}

function _keytrap
{
    eval "${Keytable[${.sh.edchar}]}"
    _rpdisplay
}
trap _keytrap KEYBD

# Swap ^W and M-baskspce in emacs editing mode.
keybind $'\cw' $'\E\177'
keybind $'\E\177' $'\cw'

init_parms
setprompt
