# -*-sh-*-

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:\
$HOME/bin; export PATH

export BLOCKSIZE=K
export EDITOR=emacsclient
export PAGER=more
export CDPATH=.:$HOME:$HOME/projects
export HISTEDIT='emacsclient -a vi'

# Define colors for the output of ls in a dark background.
export CLICOLOR=yes
if [ $TERM = cons25 ]; then
    LSCOLORS="AxHxcxdxhxefgxAHahBxbx"
else
    LSCOLORS="hxHxcxdxAxefgxAHahBxbx"
fi
export LSCOLORS

# ksh93 will look for ~/.kshrc for interactive shell if ENV is not
# set.  Set it only for the other shells.
if [ ${SHELL##*/} != ksh93 ]; then
    export ENV=$HOME/.shrc
fi

if [ -x /usr/games/fortune ]; then
    fortune
fi
