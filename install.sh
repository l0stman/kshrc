#!/bin/sh -x

FPATH=~/.funcs
BINDIR=~/bin
CRONTAB=~/.crontab

cp kshrc ~/.kshrc
cp profile ~/.profile
if [ ! -d "$FPATH" ]; then
    mkdir -p "$FPATH"
fi
cp -R funcs/ "$FPATH"
install -d $BINDIR
install -m 744 cleanhist ~/bin

if [ ! -f $CRONTAB ] || ! grep -E '/cleanhist$' $CRONTAB; then
    cat <<EOF > $CRONTAB
0	22	*	*	*	$BINDIR/cleanhist
EOF
    crontab $CRONTAB
else
    echo "cleanhist already in crontab."
fi
