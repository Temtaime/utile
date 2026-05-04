module utile.encrypt;
import std;

struct RC4
{
	this(string key)
	{
		this(key.representation);
	}

	this(const(ubyte)[] key)
	{
		foreach (i, ref v; _S)
			v = cast(ubyte)i;

		uint j;
		foreach (i, ref v; _S)
		{
			j += v + key[i % $];
			j %= N;
			swap(_S[j], v);
		}
	}

	void process(ubyte[] data)
	{
		uint j;
		ubyte[N] S = _S;

		foreach (i, ref v; data)
		{
			auto r = &S[(i + 1) % N];
			auto q = &S[(j += *r) %= N];

			swap(*r, *q);
			v ^= S[(*r + *q) % N];
		}
	}

private:
	enum N = 256;
	ubyte[N] _S;
}


