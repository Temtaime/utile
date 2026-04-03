#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

source ./compiler

cd $(mktemp -d)
wget https://ftp.gnu.org/gnu/libmicrohttpd/libmicrohttpd-latest.tar.gz -qO- | tar xzf -
cd libmicrohttpd-*

SRC_INC=src/include
SRC_DIR=src/microhttpd

if [ $IS_WIN -eq 0 ]
then
	./configure --disable-https --disable-messages --disable-examples --disable-tools --disable-curl --disable-doc --disable-shared --disable-thread-names
	make

	DIR=$DST/include/$SUFFIX
	mkdir -p $DIR

	mv $SRC_DIR/.libs/libmicrohttpd.a $DST_LIB
	mv MHD_config.h $DIR
else
	rm $SRC_DIR/test_*

	for p in md5_ext sha256_ext connection_https
	do
		rm $SRC_DIR/$p.c
	done

	CONF_DIR=w32/common
	CONF=$CONF_DIR/MHD_config.h

	perl -i -pe '$c+=s/^(#define HAVE_MESSAGES) 1/$1 0/g;END{exit(not $c)}' $CONF

	clang -fuse-ld=llvm-lib $CFLAGS -o $DST_LIB $SRC_DIR/*.c -I $SRC_INC -I $CONF_DIR

	DIR=$DST/include/w32
	mkdir -p $DIR

	mv $CONF $DIR
	mv $SRC_INC/*.h $DIR/..
fi
