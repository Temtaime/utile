module utile.log.base;

import core.stdc.stdio, std.format, std.exception, std.conv, utile.console;
import utile.log.sub;

abstract class LoggerBase
{
	final nothrow
	{
		mixin(makeFunc(`info`, `green`));
		mixin(makeFunc(`info2`, `magenta`));
		mixin(makeFunc(`info3`, `cyan`));

		mixin(makeFunc(`warn`, `yellow`));
		mixin(makeFunc(`error`, `red`));

		mixin(makeFunc(`dbg`, `blue`));
		mixin(makeFunc(`msg`, `white`));
	}

	abstract void log(ushort color, string s) nothrow;
private:
	static makeFunc(string name, string color)
	{
		string s;
		s ~= `void ` ~ name ~ `(T)(T value) => log(Fg.` ~ color ~ `, value.to!string.assumeWontThrow);`;
		s ~= `void ` ~ name ~ `(string F, A...)(A args) => log(Fg.` ~ color ~ `, format!F(args)).assumeWontThrow;`; // FIXME: why format throws ?!
		return s;
	}
}
