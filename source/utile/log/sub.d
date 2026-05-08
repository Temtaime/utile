module utile.log.sub;

import std.array, std.exception, std.format, utile.log;
import utile.log.base;

final class SubLogger : LoggerBase
{
	this(LoggerBase parent, string suffix) nothrow
	{
		if (auto r = cast(SubLogger)parent)
		{
			if (r._parent)
			{
				_suffix = r._suffix ~ ` / ` ~ suffix;
				_parent = r._parent;
			}

			return;
		}

		if (parent)
		{
			_parent = parent;
			_suffix = suffix;
		}
	}

protected:
	override void log(ushort color, string s)
	{
		if (_parent)
		{
			_parent.log(color, format!`[ %s ] %s`(_suffix, s).assumeWontThrow); // FIXME: why format throws ?!
		}
	}

private:
	LoggerBase _parent;
	string _suffix;
}
