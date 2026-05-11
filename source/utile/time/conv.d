module utile.time.conv;

import std;

SysTime parseHttpDate(string s) => s.parseRFC822DateTime;

string toHttpDate(SysTime t)
{
	auto dt = cast(DateTime)t.toUTC;

	auto day = dt.dayOfWeek.to!string.capitalize;
	auto month = dt.month.to!string.capitalize;

	return format!`%s, %02u %s %u %s GMT`(
		day,
		dt.day,
		month,
		dt.year,
		dt.timeOfDay.toISOExtString
	);
}
