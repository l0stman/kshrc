#!/bin/sh -x

FPATH=~/.funcs
BINDIR=~/bin

cp kshrc ~/.kshrc
cp profile ~/.profile
if [ ! -d "$FPATH" ]; then
    mkdir -p "$FPATH"
fi
cp -R funcs/ "$FPATH"
install -d $BINDIR
install -m 744 cleanhist ~/bin
