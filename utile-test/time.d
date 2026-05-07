import utile.time;

unittest
{
	string s = rfcToSimpleString(`Thu, 25 Dec 2025 05:07:18 GMT`);

	assert(s == `2025-Dec-25 05:07:18`);
}
