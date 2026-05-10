module utile.time.conv;

import std, utile.except;

//
// "Thu, 25 Dec 2025 05:07:18 GMT" to "2025-Dec-25 05:07:18"
//
string rfcToSimpleString(string dateStr)
{
	auto parts = dateStr.split(`,`);

	parts.length == 2 || throwError(`invalid RFC date format`);

	auto dateParts = parts[1]
		.strip
		.split;

	dateParts.length == 5 && dateParts[4] == `GMT` || throwError(`invalid RFC date format`);

	auto date = dateParts[0 .. 3];
	string time = dateParts[3];

	return format!`%-(%s-%) %s`(date.retro, time);
}

//
// Parse HTTP date format (RFC 1123)
//
SysTime parseHTTPDate(string dateStr)
{
	return DateTime
		.fromSimpleString(rfcToSimpleString(dateStr))
		.SysTime(UTC());
}
