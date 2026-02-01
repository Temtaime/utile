module utile.logger;
import std.datetime, std.conv, std.range, std.string, std.algorithm, core.stdc.stdio, utile.console;

abstract class Logger
{
	final
	{
		mixin(makeFunc(`info`, `green`));
		mixin(makeFunc(`info2`, `magenta`));
		mixin(makeFunc(`info3`, `cyan`));

		mixin(makeFunc(`warn`, `yellow`));
		mixin(makeFunc(`error`, `red`));

		mixin(makeFunc(`dbg`, `blue`));
		mixin(makeFunc(`msg`, `white`));
	}

	static write(FILE* stream, ushort color, string s, bool newline)
	{
		void dg() => cast(void)fprintf(stream, "%.*s%.*s", cast(uint)s.length, s.ptr, uint(newline), "\n".ptr);

		version (Windows)
		{
			if (isTerminal(stream))
			{
				colorize(stream, color, &dg);
			}
			else
				dg();
		}
		else
			colorize(stream, color, &dg);

		fflush(stream);
	}

	ubyte ident;
	bool timeOutput;
protected:
	final void log(ushort color, string s)
	{
		if (timeOutput)
		{
			string time = Clock
				.currTime
				.toISOExtString(0)
				.replace('T', ' ');

			write(0, "[", false);
			write(0, time, false);
			write(0, "] ", false);
		}

		ident.iota.each!(a => write(color, "\t", false));
		write(color, s, true);
	}

	void write(ushort color, string s, bool newline);
private:
	static string makeFunc(string name, string color)
	{
		string s;
		s ~= `void ` ~ name ~ `(T)(T value) => log(Fg.` ~ color ~ `, value.to!string);`;
		s ~= `void ` ~ name ~ `(string F, A...)(A args) => log(Fg.` ~ color ~ `, format!F(args));`;
		return s;
	}
}

class ConsoleLogger : Logger
{
protected:
	override void write(ushort color, string s, bool newline) => Logger.write(stdout, color, s, newline);
}

__gshared Logger logger = new ConsoleLogger;

unittest
{
	logger.timeOutput = true;

	if (false)
	{
		foreach (ushort i, name; COLOR_NAMES)
		{
			string s = "This is fg color " ~ name;
			Logger.write(stdout, i, s, true);
		}

		foreach (ushort i, name; COLOR_NAMES)
		{
			string s = "This is bg color " ~ name;
			Logger.write(stdout, cast(ushort)(i << 5), s, true);
		}
	}

	logger.msg(`hello, world`);
	logger.info2!`%s, %s`(`hello`, `world`);
}
