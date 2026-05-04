#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

EXTRA_FLAGS="-DUTILE_BUILD"
source ./compiler

build_simple ../utile-sqlite
