#!/usr/bin/env bash

set -euxo pipefail
shopt -s nullglob globstar

if grep -i MessageBox *.nsi *.nsdinc | grep -v '/SD'; then
    echo "MessageBox without /SD detected!  Silent installation will be broken."
    exit 1
fi

if grep -i -r icacls ./* | grep -i grant | grep -i -P '(?!SID_).{4}(System|Administrator|User)' | grep -v lint.sh; then
    echo "Localized user/group detected!  Some locales might be broken."
    exit 1
fi

exit 0
