module utile.log;
import std.datetime, std.conv, std.range, std.string, std.algorithm, core.stdc.stdio, utile.console;

import utile.log.base, utile.log.sub;

abstract class Logger : LoggerBase
{
	override void log(ushort color, string s)
	{
		if (timeOutput)
		{
			string time = Clock
				.currTime
				.toISOExtString(0)
				.replace('T', ' ');

			write(0, format!`[%s] `(time));
		}

		write(color, s);
	}

	bool timeOutput; // Whether to output time in log messages
protected:
	abstract void write(ushort color, string s);
}

final class ConsoleLogger : Logger
{
	override void log(ushort color, string s)
	{
		synchronized
		{
			{
				auto c = Colorizer(stdout, color);
				super.log(color, s);
			}

			fputc('\n', stdout);
			fflush(stdout);
		}
	}

protected:
	override void write(ushort color, string s)
	{
		fwrite(s.ptr, 1, s.length, stdout);
	}
}

__gshared Logger logger = new ConsoleLogger;
