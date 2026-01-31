module utile.logger;
import std.conv, std.range, std.string, std.algorithm, core.stdc.stdio, utile.console;

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

	ubyte ident;
protected:
	final void log(ushort color, string s)
	{
		ident.iota.each!(a => write(color, "\t"));
		write(color, s);
	}

	void write(ushort color, string s);
private:
	static string makeFunc(string name, string color)
	{
		string s;
		s ~= `void ` ~ name ~ `(T)(T value) => log(Fg.` ~ color ~ `, value.to!string);`;
		s ~= `void ` ~ name ~ `(string F, A...)(A args) => log(Fg.` ~ color ~ `, format!F(args));`;
		return s;
	}
}

final class ConsoleLogger : Logger
{
protected:
	override void write(ushort color, string s)
	{
		colorize(stdout, color, () => cast(void)fprintf(stdout, "%.*s\n", cast(uint)s.length, s.ptr));
		fflush(stdout);
	}
}

__gshared Logger logger = new ConsoleLogger;

unittest
{
	if (false)
	{
		foreach (ushort i, name; COLOR_NAMES)
		{
			string s = "This is fg color " ~ name;
			colorize(stdout, i, () => cast(void)fprintf(stdout, "%.*s\n", cast(uint)s.length, s.ptr));
		}

		foreach (ushort i, name; COLOR_NAMES)
		{
			string s = "This is bg color " ~ name;
			colorize(stdout, cast(ushort)(i << 5), () => cast(void)fprintf(stdout, "%.*s\n", cast(uint)s.length, s.ptr));
		}
	}

	logger.msg(`hello, world`);
	logger.info2!`%s, %s`(`hello`, `world`);
}
