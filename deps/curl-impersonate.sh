#!/bin/sh
set -eu; trap 'echo "$0 at line $LINENO: exit code is $?" >&2' ERR

source ./compiler

if [ $IS_WIN -eq 0 ]
then
	REPO=https://api.github.com/repos/lexiforest/curl-impersonate/releases/latest

	cd $(mktemp -d)
	wget $(wget -qO- $REPO | jq -r .tarball_url) -qO- | tar xzf -

	cd lexiforest-curl-impersonate-*
	sed "s/SUBJOBS := 4/SUBJOBS := $(grep processor /proc/cpuinfo | wc -l)/" -i Makefile.in

	./configure --enable-static
	make build

	ar -M <<- EOF
		CREATE $DST_LIB
		$(find . -name '*.a' -exec echo ADDLIB {} \; | grep installed)
		$(find ./boringssl-*/lib -name '*.a' -exec echo ADDLIB {} \;)
		ADDLIB $(ls ./curl-*/lib/.libs/libcurl-impersonate.a)
		SAVE
		END
	EOF
else
	cd ..

	gh release download --repo lexiforest/curl-impersonate --archive zip
	unzip *.zip
	rm *.zip
	cd curl-impersonate-*

	pip install pyyaml
	python - > env.sh <<- EOF
		import yaml

		with open('.github/workflows/build-win.yaml', 'r', encoding='utf-8') as f:
		    data = yaml.safe_load(f)

		env = data.get('env', {})

		for k, v in env.items():
		    print(f'export {k}="{v}"')
	EOF

	source ./env.sh

	perl -i -pe "\$c+=s/^(set cmake_common_args)=/\$1=-DCMAKE_C_FLAGS_RELEASE=\"$CFLAGS\" /;END{exit(not \$c)}" win/build.bat
	perl -i -pe "\$c+=s/^(set cmake_common_args)=/\$1=-DCMAKE_CXX_FLAGS_RELEASE=\"$CXXFLAGS\" /;END{exit(not \$c)}" win/build.bat

	# cmake removes NDEBUG, so force it in common flags too
	for p in DST DST_LIB CFLAGS CXXFLAGS C_FLAGS CXX_FLAGS; do echo "$p=$(eval echo \$$p)" >> $GITHUB_ENV; done

	./win/deps.sh
fi
