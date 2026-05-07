module utile.log;

import std.datetime, std.conv, std.range, std.string, std.algorithm, std.exception, core.stdc.stdio, utile.console;
import utile.log.base;

public import utile.log.sub;

abstract class Logger : LoggerBase
{
	override void log(ushort color, string s)
	{
		if (timeOutput)
		{
			string time = Clock
				.currTime
				.toISOExtString(0)
				.replace('T', ' ')
				.assumeWontThrow;

			write(0, format!`[%s] `(time).assumeWontThrow); // FIXME: why format throws ?!
		}

		write(color, s);
	}

	bool timeOutput; // Whether to output time in log messages
protected:
	abstract void write(ushort color, string s) nothrow;
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
