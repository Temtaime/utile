module utile.encoding.iconv;

import std, core.stdc.errno, utile.except;

version (Windows)
{
}
else:

string convert(string s, string from, string to)
{
	auto cd = mixin(PREFIX ~ `iconv_open(to.toStringz, from.toStringz)`);

	if (cd == size_t.max)
	{
		throwError!`iconv does not support %s -> %s`(from, to);
	}

	scope (exit)
	{
		mixin(PREFIX ~ `iconv_close(cd);`);
	}

	auto src = s.ptr;
	size_t _in = s.length;

	string r;
	char[2048] tmp = void;

	while (_in)
	{
		auto dst = tmp.ptr;
		size_t _out = tmp.length;

		size_t res = mixin(PREFIX ~ `iconv(cd, cast(char**)&src, &_in, &dst, &_out)`);

		if (res == size_t.max && errno != E2BIG)
		{
			throwError!`conversion error`;
		}

		r ~= tmp[0 .. $ - _out];
	}

	return r;
}

alias iconv_t = size_t;

version (Emscripten)
{
	enum string PREFIX = null;
}
else
{
	enum string PREFIX = `lib`;
}

extern (C):

mixin(`
iconv_t `
		~ PREFIX ~ `iconv_open(const(char)*, const(char)*);

size_t `
		~ PREFIX ~ `iconv(iconv_t, char**, size_t*, char**, size_t*);

int `
		~ PREFIX ~ `iconv_close(iconv_t);
`);
