module utile.binary.tests;
import std, utile.misc, utile.binary, utile.logger, utile.binary.helpers;

unittest
{
	static struct S
	{
		@ZeroTerminated const(ubyte)[] str;
		wstring wstr;

		@(ArrayLength!(_ => 6), ZeroTerminated) string st;
		@(ArrayLength!(_ => 6), ZeroTerminated) string st2;

		@(ArrayLength!(_ => 4), ZeroTerminated) ubyte[] st3;
	}

	S s;
	s.str = [1, 2, 3];
	s.wstr = `1234`w;
	s.st = `abc`;
	s.st2 = `abcdef`;
	s.st3 = [1, 2];

	const(ubyte)[] data = [
		1, 2, 3, 0, // str
		49, 0, 50, 0, 51, 0, 52, 0, 0, 0, // wstr
		97, 98, 99, 0, 0, 0, // st
		97, 98, 99, 100, 101, 102, // st2
		1, 2, 0, 0, // st3
	];

	ensureResult(s, data);
}

unittest
{
	static struct S
	{
		ubyte val;
		S* next;
	}

	auto s = S(12);
	s.next = new S(13);

	auto data = s.serializeMem;
	assert(data == [12, 1, 13, 0]);

	auto v = data.deserializeMem!S;

	assert(v.val == s.val);
	assert(v.next && *v.next == *s.next);
}

unittest
{
	static struct Test
	{
		enum X = 10;

		enum Y
		{
			i = 12
		}

		static struct S
		{
			uint k = 4;
		}

		static int sx = 1;
		__gshared int gx = 2;

		Y y;
		static Y sy;

		static void f()
		{
		}

		static void f2() pure nothrow @nogc @safe
		{
		}

		shared void g()
		{
		}

		static void function() fp;
		__gshared void function() gfp;
		void function() fpm;

		void delegate() dm;
		static void delegate() sd;

		void m()
		{
		}

		final void m2() const pure nothrow @nogc @safe
		{
		}

		inout(int) iom() inout
		{
			return 10;
		}

		static inout(int) iosf(inout int x)
		{
			return x;
		}

		@property int p()
		{
			return 10;
		}

		static @property int sp()
		{
			return 10;
		}

		union
		{
			int a;
			float b;
			long u;
			double gg;
		}

		S s;
		static immutable char[4] c = `ABCD`;
		string d;

		@(ArrayLength!uint) int[] e;
		@(ArrayLength!(a => a.that.e.length)) int[] r;

		@Ignored int kk;
		@(IgnoreIf!(a => a.that.r.length == 3)) int rt;

		@(ToTheEnd, Skip!(a => a.that.rt)) byte[] q;
	}

	static assert(fieldsToProcess!Test == [
			`y`, `u`, `s`, `c`, `d`, `e`, `r`, `rt`, `q`
			]);

	const(ubyte)[] data = [
		12, 0, 0, 0, // y
		11, 0, 0, 0, 0, 0, 0, 0, // a
		4, 0, 0, 0, // S.k
		65, 66, 67, 68, // c
		97, 98, 99, 0, // d, null terminated
		3, 0, 0, 0, // e.length
		1, 0, 0, 0, // e[0]
		2, 0, 0, 0, // e[1]
		3, 0, 0, 0, // e[3]
		4, 0, 0, 0, // r[0], length is set by the user
		5, 0, 0, 0, // r[1]
		6, 0, 0, 0, // r[2]
		1, 2, 3, 4, // q[4]
	];

	Test t = {a: 11, d: `abc`, e: [1, 2, 3], r: [4, 5, 6], q: [1, 2, 3, 4]};

	ensureResult(t, data);

	enum File = `__tmp`;
	serializeFile(File, t);

	scope (exit)
		std.file.remove(File);

	assert(deserializeFile!Test(File) == t);
}

void ensureResult(T)(ref in T value, const(ubyte)[] data)
{
	const res = value.serializeMem;
	assert(res == data, res.to!string);

	const parsed = data.deserializeMem!T;
	assert(parsed == value, parsed.to!string);
}
