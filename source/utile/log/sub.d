module utile.log.sub;

import std.array, std.format, utile.log;
import utile.log.base;

final class SubLogger : LoggerBase
{
	this(LoggerBase parent, string suffix)
	{
		_parent = parent;
		_suffix = suffix;
	}

protected:
	override void log(ushort color, string s)
	{
		string sf = _suffix;
		LoggerBase p = _parent;

		while (true)
		{
			auto r = cast(SubLogger)p;

			if (r is null)
				break;

			with (r)
			{
				sf = _suffix ~ ` / ` ~ sf;
				p = _parent;
			}
		}

		p.log(color, format!`[ %s ] %s`(sf, s));
	}

private:
	LoggerBase _parent;
	string _suffix;
}
