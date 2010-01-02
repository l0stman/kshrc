PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/games:/usr/local/sbin:/usr/local/bin:\
$HOME/bin; export PATH

export BLOCKSIZE=K
export EDITOR="emacs -nw"
export PAGER=more

# ksh93 will look for ~/.kshrc for interactive shell if ENV is not
# set.  Set it only for the other shells.
if [[ $(basename $SHELL) != ksh93 ]]; then
    export ENV=$HOME/.shrc
fi

if [ -x /usr/games/fortune ]; then
    /usr/games/fortune
fi

