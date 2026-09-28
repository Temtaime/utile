module utile.encoding.iconv;

import std, core.stdc.errno, utile.except;

version (linux):

string convert(string s, string from, string to)
{
	auto iv = libiconv_open(to.toStringz, from.toStringz);

	if (iv == size_t.max)
	{
		throwError!`iconv does not support %s -> %s`(from, to);
	}

	scope (exit)
	{
		libiconv_close(iv);
	}

	auto src = s.ptr;
	auto len = s.length;

	string r;
	char[2048] tmp = void;

	while (len)
	{
		auto dst = tmp.ptr;
		auto size = tmp.length;

		auto res = libiconv(iv, cast(char**)&src, &len, &dst, &size);

		if (res == size_t.max && errno != E2BIG)
		{
			throwError!`conversion error`;
		}

		r ~= tmp[0 .. $ - size];
	}

	return r;
}

alias iconv_t = size_t;

extern (C):

iconv_t libiconv_open(const(char)* tocode, const(char)* fromcode);
size_t libiconv(iconv_t cd, char** inbuf, size_t* inbytesleft, char** outbuf, size_t* outbytesleft);
int libiconv_close(iconv_t cd);
