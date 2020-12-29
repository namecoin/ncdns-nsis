#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

if grep -i MessageBox *.nsi *.nsdinc | grep -v '/SD'; then
    echo "MessageBox without /SD detected!  Silent installation will be broken."
    exit 1
fi

exit 0
