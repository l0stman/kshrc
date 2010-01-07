# -*-sh-*-

#
# .kshrc - Korn shell 93 startup file
#

umask 0022
set -o emacs

# History file.
export HISTFILE=~/.hist$$
trap 'rm -f $HISTFILE' EXIT

export CDSTACK=32
export FPATH=$HOME/.funcs
integer _push_max=${CDSTACK} _push_top=${CDSTACK}

# Directory manipulation functions.
unalias cd
alias cd=_cd
alias pu=pushd
alias po=popd
alias d=dirs

alias h=history
alias j=jobs
alias m=$PAGER
alias ll='ls -laFo'
alias l='ls -l'
alias g='fgrep -i'

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
    _user=$(whoami)
    _host=$(hostname -s)
    _tty=$(tty | sed s@/dev/@@)
    _rprompt=
    _rpos=
    _cont_prompt=
    case $(id -u) in
	0) _prompt=\#;;
	*) _prompt=\$;;
    esac
    
    # Use alternative characters to draw lines if supported or degrade
    # to normal characters if not.

    load_alt
    alt_on=$(tput as)
    alt_off=$(tput ae)
    _hbar=${altchar[q]:--}
    _vbar=${altchar[x]:-\|}
    _ulcorner=${altchar[l]:--}
    _llcorner=${altchar[m]:--}
    _urcorner=${altchar[k]:--}
    _lrcorner=${altchar[j]:--}
    _lbracket=${altchar[u]:-\[}
    _rbracket=${altchar[t]:-\]}
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

#### Two lines prompt.
# This function is executed before PS1 is referenced. It sets _rpos to
# the position of the right prompt. See discipline function in the man
# page of ksh93.

function PS1.get
{
    typeset rc=$?  # save the return value of the last command
    typeset dir="$(_pwd)" padline
    typeset uprompt="--[${_user}@${_host}:${_tty}]--(${dir})--"
    typeset rprompt="-(${_rstatue})--"
    integer termwidth=$(tput co)
    integer offset=$(( ${#uprompt} - ${termwidth} ))
    integer i

    # Truncate the current directory if too long and define a line
    # padding such that the upper prompt occupy the terminal width.
    if (( $offset > 0 )) ; then
	dir="...${dir:$(( $offset + 3 ))}"
	padline=""
    else
	offset=$(( - $offset ))
	padline=${alt_on}
	for (( i=0; i<$offset; i++ )); do
	    padline=${padline}${_hbar}
	done
	padline=${padline}${alt_off}
    fi
    
    _rpos=$(( $termwidth - ${#rprompt} ))
    _cont_prompt=
    
    # Upper prompt.
    .sh.value="\
${alt_on}${_ulcorner}${_hbar}${_lbracket}${alt_off}\
${_user}@${_host}:${_tty}\
${alt_on}${_rbracket}${alt_off}\
${padline}\
${alt_on}${_hbar}${_hbar}${alt_off}\
(${dir})\
${alt_on}${_hbar}${_urcorner}${alt_off}"

    # If the terminal doesn't ignore a newline after the last column
    # and has automatic margin (e.g. cons25), a newline or carriage
    # return if written will be on the next line.  So don't add a
    # newline and for good mesure, move the cursor to the left before
    # writing cr at the end of a line.

    if ! tput am || tput xn; then
	.sh.value=${.sh.value}$'\n'
    fi

    # Lower prompt using carriage return to display the right prompt.
    .sh.value="${.sh.value}\
$(tput RI $_rpos)\
${_rprompt}\
$(tput le)$(tput cr)\
${alt_on}${_llcorner}${_hbar}${alt_off}\
(${_lstatue}${alt_on}${_vbar}${alt_off}${_prompt})\
${alt_on}${_hbar}${alt_off} "

    return $rc
}

# Statue in the left prompt
function _lstatue.get
{
    .sh.value=$(date +%H:%M:%S)
}

# Statue in the right prompt
function _rstatue.get
{
    # Use the current branch in a git repository or the current date.
    typeset b=$(__git_ps1 git:)
    .sh.value=${b:-$(date "+%a, %d %b")}
}

# Right prompt.
function _rprompt.get
{
    .sh.value="\
${alt_on}${_hbar}${alt_off}\
(${_rstatue})\
${alt_on}${_hbar}${_lrcorner}${alt_off}"
}

# Continuation prompt
function PS2.get
{
    _cont_prompt=yes
    .sh.value="${alt_on}${_hbar}${_hbar}${alt_off} "
}

# Erase the right prompt if the text reaches it and redraw it if the
# text fits in the region between the left prompt and the right one.

function _rpdisplay
{
    typeset lprompt="--(${_lstatue}|$)- "
    integer width=$(( ${_rpos} - ${#lprompt} - 1))
    integer pos=${#.sh.edtext}
    typeset -S has_prompt=yes
    typeset text
    
    if (( $pos <= $width )); then
	if (( $pos == $width)); then
		tput ce
		has_rprompt=
	elif [[ -z $has_rprompt ]]; then
	    text=${.sh.edtext}
	    tput sc; tput vi
	    tput cr; tput RI $_rpos
	    print -n -- "${_rprompt}"
	    tput rc; tput ve
	    .sh.edtext=$text
	    has_rprompt=yes
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

    # Execute only if we're not on a continuation prompt
    if [[ -z $_cont_prompt ]]; then
	_rpdisplay
    fi
}
trap _keytrap KEYBD

# Swap ^W and M-baskspce in emacs editing mode.
keybind $'\cw' $'\E\177'
keybind $'\E\177' $'\cw'

init_parms
