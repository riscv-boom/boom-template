#!/usr/bin/env bash

# run this script in the main boom-template directory to generate ctags for boom and other relevant repos
# note: this requires exuberant-ctags
# tested with: Exuberant Ctags 5.8
# instructions:
#    cd /path/to/boom-template/
#    ./scripts/gen-tags.sh

# ctags wrapper
ctags -R --exclude=@.ctagsignore --links=no
