#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

EXTRA_FLAGS="-DMINIZ_NO_ZLIB_APIS -DMINIZ_NO_ZLIB_COMPATIBLE_NAMES"
source ./compiler

build_simple
