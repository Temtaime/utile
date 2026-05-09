module utile.time;
import core.time, std.datetime.stopwatch, utile;

public import utile.time.app;
public import utile.time.conv;
public import utile.time.meter;
public import utile.time.timer;

nothrow:

uint systemTick()
{
	return cast(uint)(MonoTime.currTime.ticks * 1000 / MonoTime.ticksPerSecond);
}

int toMsecs(Duration d) => cast(int)d.total!`msecs`;
int toSecs(Duration d) => cast(int)d.total!`seconds`;
