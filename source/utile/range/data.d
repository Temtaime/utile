module utile.range.data;

struct DataRange
{
	this(ulong a, ulong b)
	{
		assert(b > a);

		start = a;
		end = b;
	}

	ulong length() const => end - start;

	ulong start, end; // [start, end)
}
