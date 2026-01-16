#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

cd ${0%/*}/lib

CMD="-w -fno-stack-protector -O3 -DNDEBUG -DMINIZ_NO_ZLIB_APIS -DMINIZ_NO_ZLIB_COMPATIBLE_NAMES"
OPTS=-msse3

if [ -d /c/windows ]
then
	clang -m64 -fuse-ld=llvm-lib -m64 -o utile.lib $CMD $OPTS *.c
else
	SUFFIX=$(uname -m)

	case $SUFFIX in
	x86_64)
		;;
	aarch64)
		OPTS=
		;;
	*)
		echo "unsupported CPU"
		exit 1
		;;
	esac

	SUFFIX=_$SUFFIX
	[ $# -eq 1 ] && SUFFIX=$SUFFIX$1 || :

	clang -fPIC -c $CMD $OPTS *.c
	ar rcs libutile$SUFFIX.a *.o
fi
