module utile.encoding.iconv;
import std.conv, std.string, std.encoding, core.stdc.errno, utile.except;

version (linux):

import utile_iconv;

string convert(string s, string from, string to)
{
	auto query = to ~ `//IGNORE//TRANSLIT`;
	auto iv = iconv_open(query.toStringz, from.toStringz);

	cast(ptrdiff_t)iv != -1 || throwError!`can't convert from %s to %s`(from, to);

	scope (exit)
	{
		iconv_close(iv);
	}

	auto src = s.ptr;
	auto len = s.length;

	string r;
	char[2048] tmp = void;

	while (len)
	{
		auto dst = tmp.ptr;
		auto size = tmp.length;

		int res = cast(int)iconv(iv, cast(char**)&src, &len, &dst, &size);

		if (res < 0 && errno != E2BIG)
		{
			throwError!`conversion error`;
		}

		r ~= tmp[0 .. $ - size];
	}

	return r;
}
