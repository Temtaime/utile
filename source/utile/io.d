module utile.io;

import std;

string asTxt(ref File f)
{
	f.rewind;

	auto res = new char[cast(size_t)f.size];
	f.rawRead(res);

	return res.assumeUnique;
}
