# -*-sh-*-

#
# .kshrc - Korn shell 93 startup file
#

umask 0077
set -o emacs
set +o multiline

# History file.
export HISTFILE=~/.hist$$
trap 'rm -f $HISTFILE' EXIT

export CDSTACK=32
export FPATH=$HOME/.funcs
integer _push_max=${CDSTACK} _push_top=${CDSTACK}

# Directory manipulation functions.
unalias cd 2>/dev/null
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
alias c=clear
alias ec=emacsclient
alias mutt='TERM=xterm-256color mutt'

# Don't get fancy if we have a dumb terminal.  This happens for
# example if we're accessing files remotely through tramp in emacs.
[[ $TERM == 'dumb' ]] && return 0

case $(uname) in
    FreeBSD)
        # Use terminal capabilities codes.
        cap_altchars=ac
        cap_setfg=AF
        cap_setbg=AB
        cap_bold_on=md
        cap_allattr_off=me
        cap_alt_start=as
        cap_alt_end=ae
        cap_alt_on=eA
        cap_columns=co
        cap_ign_newline=xn
        cap_auto_marg=am
        cap_mvright=RI
        cap_cursleft=le
        cap_colors=Co
        cap_carriage_return=cr
        cap_save_cursor=sc
        cap_inv_cursor=civis
        cap_restore_cursor=rc
        cap_normal_cursor=cnorm
        cap_clr_eol=el
        ;;
    Linux)
        # Use terminal capabilities names.
        cap_altchars=acsc
        cap_setfg=setaf
        cap_setbg=setab
        cap_bold_on=bold
        cap_allattr_off=sgr0
        cap_alt_start=smacs
        cap_alt_end=rmacs
        cap_alt_on=enacs
        cap_columns=cols
        cap_ign_newline=xenl
        cap_auto_marg=am
        cap_mvright=cuf
        cap_cursleft=cub1
        cap_colors=colors
        cap_carriage_return=cr
        cap_save_cursor=sc
        cap_inv_cursor=vi
        cap_restore_cursor=rc
        cap_normal_cursor=ve
        cap_clr_eol=ce
        ;;
    *)
        echo "WARNING: Unknown OS for fancy prompt, cowardly refuse to proceed"
        return 0
        ;;
esac

# Generate an associative array containing the alternative characters
# set for the terminal.  See termcap (5) for more details.
eval typeset -A altchar=\($(tput $cap_altchars | \
                                sed -E "s/(.)(.)/['\1']='\2' /g")\)

# Generate two associative arrays containing the background
# and foreground colors.
typeset -A fg bg

function load_colors
{
    typeset color
    integer i=0

    for color in black red green brown blue magenta cyan white; do
        fg+=([$color]=$(tput $cap_setfg $i))
        bg+=([$color]=$(tput $cap_setbg $i))
        (( i++ ))
    done
}

function init_parms
{
    _user=$(whoami)
    _host=$(hostname -s)
    _tty=$(tty | sed s@/dev/@@)
    _rprompt=
    _lpos=
    _rpos=
    _cont_prompt=
    case $(id -u) in
	0) _prompt=\#;;
	*) _prompt=\$;;
    esac
    bold_on=$(tput $cap_bold_on)
    allattr_off=$(tput $cap_allattr_off)
    _prompt=${bold_on}${_prompt}${allattr_off}

    # Use alternative characters to draw lines if supported or degrade
    # to normal characters if not.
    alt_start=$(tput $cap_alt_start)
    alt_end=$(tput $cap_alt_end)
    _hbar=${altchar[q]:--}
    _vbar=${altchar[x]:-\|}
    _ulcorner=${altchar[l]:--}
    _llcorner=${altchar[m]:--}
    _urcorner=${altchar[k]:--}
    _lrcorner=${altchar[j]:--}
    _lbracket=${altchar[u]:-\[}
    _rbracket=${altchar[t]:-\]}

    integer colormax=$(tput $cap_colors)
    if (( ${colormax:-0} >= 8 )); then
        load_colors
        case $(id -u) in
            0)
                _bgcolor=${bg[red]}
                _fgcolor=${fg[white]}
                ;;
            *)
                _bgcolor=${bg[white]}
                _fgcolor=${fg[black]}
                ;;
        esac
    fi

    # Enable alternate char set.
    tput $cap_alt_on
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
# the position of the right prompt and _lpos to the position after the
# left prompt. See discipline function in the man page of ksh93.

function PS1.get
{
    typeset rc=$?  # save the return value of the last command
    typeset dir="$(_pwd)" padline
    typeset uprompt="--[${_user}@${_host}:${_tty}]--(${dir})--"
    typeset rprompt="-(${_rstatue})--" lprompt="--(${_lstatue}|$)- "
    integer termwidth=$(tput $cap_columns)
    integer offset=$(( ${#uprompt} - ${termwidth} ))
    integer i

    # Truncate the current directory if too long and define a line
    # padding such that the upper prompt occupy the terminal width.
    if (( $offset > 0 )) ; then
	dir="...${dir:$(( $offset + 3 ))}"
	padline=""
    else
	offset=$(( - $offset ))
	padline=${alt_start}
	for (( i=0; i<$offset; i++ )); do
	    padline=${padline}${_hbar}
	done
	padline=${padline}${alt_end}
    fi

    _rpos=$(( $termwidth - ${#rprompt} ))
    _lpos=${#lprompt}
    _cont_prompt=

    # Upper prompt.
    .sh.value="\
${alt_start}${_ulcorner}${_hbar}${_lbracket}${alt_end}\
${_bgcolor}${_fgcolor}\
${_user}@${_host}:${_tty}\
${allattr_off}\
${alt_start}${_rbracket}${alt_end}\
${padline}\
${alt_start}${_hbar}${_hbar}${alt_end}\
${bold_on}(${dir})${allattr_off}\
${alt_start}${_hbar}${_urcorner}${alt_end}"

    # If the terminal doesn't ignore a newline after the last column
    # and has automatic margin (e.g. cons25), a newline or carriage
    # return if written will be on the next line.  So don't add a
    # newline and for good mesure, move the cursor to the left before
    # writing cr at the end of a line.

    if ! tput $cap_auto_marg || tput $cap_ign_newline; then
	.sh.value=${.sh.value}$'\n'
    fi

    # Lower prompt using carriage return to display the right prompt.
    .sh.value="${.sh.value}\
$(tput $cap_mvright $_rpos)\
${_rprompt}\
$(tput $cap_cursleft)$(tput $cap_carriage_return)\
${alt_start}${_llcorner}${_hbar}${alt_end}\
(${_lstatue}${alt_start}${_vbar}${alt_end}${_prompt})\
${alt_start}${_hbar}${alt_end} "

    return $rc
}

# Statue in the left prompt
function _lstatue.get
{
    .sh.value=$(date +%H:%M:%S)
}

export GIT_PS1_SHOWDIRTYSTATE=yes
export GIT_PS1_SHOWUNTRACKEDFILES=yes

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
${alt_start}${_hbar}${alt_end}\
(${_rstatue})\
${alt_start}${_hbar}${_lrcorner}${alt_end}"
}

# Continuation prompt
function PS2.get
{
    _cont_prompt=yes
    .sh.value="${alt_start}${_hbar}${_hbar}${alt_end} "
}

# Deletion characters in emacs editing mode and from stty.
typeset -A _delchars=(
    [$'\ch']=DEL
    [$'\177']=BS
    [$'\E\177']=KILL-REGION
    [$'\cw']=BACKWARD-KILL-WORD
    [$'\cu']=KILL-LINE
)

# Erase the right prompt if the text reaches it and redraw it if the
# text fits in the region between the left prompt and the right one.
function _rpdisplay
{
    integer width=$(( $_rpos - $_lpos - 1))
    integer pos=${#.sh.edtext}
    typeset -S has_rprompt=yes
    typeset ch=${.sh.edchar}

    if [[ -z $has_rprompt ]]; then
        if (( $pos < $width )) ||
            ( (($pos == $width+1)) && [[ -n ${_delchars[$ch]} ]] ); then
            tput $cap_save_cursor; tput $cap_inv_cursor
            tput $cap_carriage_return; tput $cap_mvright $_rpos
            print -n -- "${_rprompt}"
            tput $cap_restore_cursor; tput $cap_normal_cursor
            has_rprompt=yes
        fi
    elif (( $pos >= $width )) && [[ -z ${_delchars[$ch]} ]]; then
        tput $cap_clr_eol
        has_rprompt=
    fi
}

# Set the line status to the command buffer and the window title
# to the command name.
function _setscreen
{
    typeset hs=${.sh.edtext/#*(\s)/} # delete leading blanks
    typeset cmd=${hs/%@(\s)*}
    typeset args=${hs/#+(\S)/}
    typeset sudopts=AbEHhKkLlnPSVvg:p:U:u:C:c:
    typeset -S lastcmd

    if [[ -n $cmd ]]; then
        cmd=${cmd##*/}
        if [[ $cmd == sudo || $cmd == *=* ]]; then
            # Find the real command name
            set -- $args
            {
                while getopts $sudopts c; do
                    ;               # skip options
                done
            } 2>/dev/null
            shift $((OPTIND-1))
            if [[ -n $1 ]]; then
                cmd=${1##*/}
            fi
        fi
        # Ignore variable assignment
        if [[  $cmd != *=* ]]; then
            lastcmd=$cmd
        fi
    fi
    print -nR $'\E_'${hs}$'\E\\'
    print -nR $'\Ek'${lastcmd}$'\E\\'
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
        [[ $TERM == screen && ${.sh.edchar} == $'\r' ]] && _setscreen
	_rpdisplay
    fi
}
trap _keytrap KEYBD

# Swap ^W and M-baskspace in emacs editing mode.
keybind $'\cw' $'\E\177'
keybind $'\E\177' $'\cw'

init_parms
