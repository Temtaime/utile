module utile.string;
import std.ascii;

string toDup(alias F)(const(char)[] s)
{
	auto res = new char[s.length];

	foreach (i, c; s)
	{
		res[i] = F(c);
	}

	return res;
}

nothrow:

string toLowerDup(const(char)[] s) => toDup!toLower(s);
string toUpperDup(const(char)[] s) => toDup!toUpper(s);
