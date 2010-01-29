#!/bin/sh -x

FPATH=~/.funcs
BINDIR=~/bin
CRONTAB=~/.crontab

for f in kshrc profile screenrc; do
    cp $f ~/.$f
done

install -d $FPATH
cp -R funcs/ $FPATH

install -d $BINDIR
for f in bin/*; do
    install -m 744 $f ~/bin
done

if [ ! -f $CRONTAB ] || ! grep -E '/cleanhist$' $CRONTAB; then
    cat <<EOF > $CRONTAB
0	22	*	*	*	$BINDIR/cleanhist
EOF
    crontab $CRONTAB
else
    echo "cleanhist already in crontab."
fi
