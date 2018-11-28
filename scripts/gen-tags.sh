#!/usr/bin/env bash

# run this script in the main boom-template directory to generate ctags for boom and other relevant repos

# ctags wrapper
ctags -R --exclude=@.ctagsignore --links=no
