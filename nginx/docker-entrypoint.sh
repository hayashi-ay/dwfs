#!/bin/bash

# exit immediately if a command fails or unset variables are used.
# https://sipb.mit.edu/doc/safe-shell/
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#The-Set-Builtin
set -eu -o pipefail

# $@ expands to the positional parameters, starting from one.
# https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Positional-Parameters
exec "$@"
