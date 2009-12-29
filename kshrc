setprompt ()
{
    PS1="[$(whoami)@$(hostname -s):$(tty | sed s@/dev/@@)] \$ "
}

setprompt