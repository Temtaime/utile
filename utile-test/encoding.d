import std.string, utile.encoding;

unittest
{
	auto src = "\xBF\xF6\xC5\xCD".representation;

	string s = decode(src, 51949);
	assert(s == `워터`);

	auto data = encode(s, 51949);
	assert(data == src);
}
