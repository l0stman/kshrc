# -*-sh-*-

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:\
$HOME/bin; export PATH

export BLOCKSIZE=K
export EDITOR=emacsclient
export PAGER=more
export CDPATH=.:$HOME:$HOME/projects
export HISTEDIT='emacsclient -a vi'
export PAPERSIZE=A4

# Define colors for the output of ls in a dark background.
export CLICOLOR=yes
if [ "$TERM" = cons25 ]; then
    LSCOLORS="AxHxcxdxhxefgxAHahBxbx"
else
    LSCOLORS="hxHxcxdxAxefgxAHahBxbx"
fi
export LSCOLORS

# ksh will look for ~/.kshrc for interactive shell if ENV is not
# set.  Set it only for the other shells.
case ${SHELL##*/} in
    ksh93|ksh2020)
    ;;
    *)
        export ENV=$HOME/.shrc;;
esac

if [ -x /usr/games/fortune ]; then
    fortune
fi
