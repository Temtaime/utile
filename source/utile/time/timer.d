module utile.time.timer;

import std.datetime, utile.time.app;

struct AppTimer
{
	@disable this();

nothrow:
	this(Duration delay)
	{
		_delay = delay;
		reset;
	}

	bool peek() => appTime.now >= _fire;

	bool isFired()
	{
		if (peek)
		{
			reset;
			return true;
		}

		return false;
	}

	void reset()
	{
		_fire = appTime.now + _delay;
	}

private:
	MonoTime _fire;
	Duration _delay;
}

struct TimerFunc
{
	@disable this();

	nothrow
	{
		this(Duration delay, void delegate() func, bool once = true)
		{
			_func = func;
			_once = once;

			_tm = AppTimer(delay);
		}

		void stop()
		{
			_func = null;
		}

		void reset() => _tm.reset;
		const isActive() @property => !!_func;
	}

	void check()
	{
		if (_func && _tm.isFired)
		{
			_func();

			if (_once)
			{
				_func = null;
			}
		}
	}

private:
	void delegate() _func;
	AppTimer _tm;
	bool _once;
}
