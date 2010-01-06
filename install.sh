#!/bin/sh

FPATH=~/.funcs

cp kshrc ~/.kshrc
cp profile ~/.profile
if [ ! -d "$FPATH" ]; then
    mkdir -p "$FPATH"
fi
cp -R funcs/ "$FPATH"