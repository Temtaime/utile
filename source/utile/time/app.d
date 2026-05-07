module utile.time.app;

import core.time, utile.misc;

__gshared AppTime appTime;

shared static this()
{
	appTime.update;
}

struct AppTime
{
	void update()
	{
		_now = MonoTime.currTime;
	}

private:
	mixin publicProperty!(MonoTime, `now`);
}

struct AppTimeMeter
{
	static init() => AppTimeMeter(appTime.now);

	auto elapsed() => appTime.now - _start;
private:
	MonoTime _start;
}
