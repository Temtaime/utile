module utile.binary.tests;
import std, utile.misc, utile.binary, utile.logger, utile.binary.helpers;

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
			int a = 11;
			float b;
			long u;
			double gg;
		}

		S s;
		static immutable char[4] c = `ABCD`;
		string d = `abc`;

		@(ArrayLength!uint) int[] e = [1, 2, 3];
		@(ArrayLength!(a => a.that.e.length)) int[] r = [4, 5, 6];

		@Ignored int kk;
		@(IgnoreIf!(a => a.that.r.length == 3)) int rt;

		@(ToTheEnd, Skip!(a => a.that.rt)) byte[] q = [1, 2, 3, 4];
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
		1, 2, 3,
		4 // q[4]
	];

	Test t;
	auto written = serializeMem(t);

	assert(written == data);
	assert(data.deserializeMem!Test == t);

	enum File = `__tmp`;
	serializeFile(File, t);

	scope (exit)
		std.file.remove(File);

	assert(deserializeFile!Test(File) == t);
}
