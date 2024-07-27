module utile.time;
import core.time, std.datetime.stopwatch, utile;

uint systemTick()
{
	return cast(uint)(MonoTime.currTime.ticks * 1000 / MonoTime.ticksPerSecond);
}

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
		logger.msg!`%s : %u ms`(_msg, _sw.peek.total!`msecs`);
	}

private:
	string _msg;
	StopWatch _sw;
}
