module utile.log.base;

import core.stdc.stdio, std.format, std.exception, std.conv, utile.console;
import utile.log.sub;

enum LogLevel
{
	dbg,
	msg,
	info,
	info2,
	info3,
	warn,
	error,
	fatal,
	none
}

abstract class LoggerBase
{
	final nothrow
	{
		mixin(makeFunc(`dbg`, `Fg.blue`));
		mixin(makeFunc(`msg`, `Fg.white`));

		mixin(makeFunc(`info`, `Fg.green`));
		mixin(makeFunc(`info2`, `Fg.magenta`));
		mixin(makeFunc(`info3`, `Fg.cyan`));

		mixin(makeFunc(`warn`, `Fg.yellow`));
		mixin(makeFunc(`error`, `Fg.red`));

		mixin(makeFunc(`fatal`, `Bg.darkRed`));
	}

	LogLevel level = LogLevel.msg;
nothrow:
	abstract void log(ushort color, string s);
private:
	void doLog(LogLevel r, ushort color, string s)
	{
		if (r >= level)
		{
			log(color, s);
		}
	}

	static makeFunc(string name, string color)
	{
		string s;
		s ~= `void ` ~ name ~ `(T)(T value) => doLog(LogLevel.` ~ name ~ ',' ~ color ~ `, value.to!string.assumeWontThrow);`;
		s ~= `void ` ~ name ~ `(string F, A...)(A args) => doLog(LogLevel.` ~ name ~ ',' ~ color ~ `, format!F(args).assumeWontThrow);`; // FIXME: why format throws ?!
		return s;
	}
}
