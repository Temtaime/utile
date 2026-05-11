import utile.time;

import std;

unittest
{
	string a = `Thu, 25 Dec 2025 05:07:18 GMT`;

	auto t = parseHttpDate(a);

	assert(t.toSimpleString == `2025-Dec-25 05:07:18Z`);
	assert(t.toHttpDate == a);
}

unittest
{
	auto s = `Sun, 06 Nov 1994 08:49:37 GMT`;

	auto t = parseHttpDate(s);

	assert(t.timezone is UTC());
	assert(cast(DateTime)t.toUTC == DateTime(1994, 11, 6, 8, 49, 37));
}

unittest
{
	auto s = `Tue, 15 Nov 1994 12:45:26 GMT`;

	auto t = parseHttpDate(s);

	assert(cast(DateTime)t.toUTC == DateTime(1994, 11, 15, 12, 45, 26));
}

unittest
{
	auto local = SysTime(
		DateTime(1994, 11, 6, 10, 49, 37),
		new immutable SimpleTimeZone(dur!`hours`(2), `UTC+2`)
	);

	assert(toHttpDate(local) == `Sun, 06 Nov 1994 08:49:37 GMT`);
}

unittest
{
	auto t = SysTime(DateTime(1994, 11, 6, 8, 49, 37), UTC());

	assert(toHttpDate(t) == `Sun, 06 Nov 1994 08:49:37 GMT`);
}

unittest
{
	auto original = `Sun, 06 Nov 1994 08:49:37 GMT`;

	auto parsed1 = parseHttpDate(original);
	auto rendered = toHttpDate(parsed1);
	auto parsed2 = parseHttpDate(rendered);

	assert(cast(DateTime)parsed1.toUTC == cast(DateTime)parsed2.toUTC);
}

unittest
{
	auto t = SysTime(DateTime(2023, 12, 31, 23, 59, 59), UTC());

	assert(toHttpDate(t) == `Sun, 31 Dec 2023 23:59:59 GMT`);
}

unittest
{
	auto t = SysTime(DateTime(2024, 1, 1, 0, 0, 0), UTC());

	assert(toHttpDate(t) == `Mon, 01 Jan 2024 00:00:00 GMT`);
}

unittest
{
	auto t = SysTime(DateTime(2000, 2, 29, 12, 0, 0), UTC());

	auto s = toHttpDate(t);
	assert(s == `Tue, 29 Feb 2000 12:00:00 GMT`);

	auto parsed = parseHttpDate(s);
	assert(cast(DateTime)parsed.toUTC == DateTime(2000, 2, 29, 12, 0, 0));
}

unittest
{
	assert(toHttpDate(SysTime(DateTime(2025, 1, 1, 0, 0, 0), UTC())) == `Wed, 01 Jan 2025 00:00:00 GMT`);
	assert(toHttpDate(SysTime(DateTime(2025, 1, 3, 0, 0, 0), UTC())) == `Fri, 03 Jan 2025 00:00:00 GMT`);
	assert(toHttpDate(SysTime(DateTime(2025, 1, 4, 0, 0, 0), UTC())) == `Sat, 04 Jan 2025 00:00:00 GMT`);
}
