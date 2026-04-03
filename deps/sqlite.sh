#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

source ./compiler

build_simple
