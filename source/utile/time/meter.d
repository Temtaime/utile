module utile.time.meter;

import std.datetime.stopwatch, std.format, utile.log, utile.time;

struct TimeMeter
{
	this(A...)(string msg, in A args)
	{
		static if (args.length)
		{
			msg = format(msg, args);
		}

		_msg = msg;
		_sw = StopWatch(AutoStart.yes);
	}

	~this()
	{
		logger.msg!`%s : %u ms`(_msg, _sw.peek.toMsecs);
	}

private:
	string _msg;
	StopWatch _sw;
}
