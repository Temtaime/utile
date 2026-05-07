module utile.time;
import core.time, std.datetime.stopwatch, utile;

public import utile.time.app;
public import utile.time.meter;
public import utile.time.timer;

uint systemTick()
{
	return cast(uint)(MonoTime.currTime.ticks * 1000 / MonoTime.ticksPerSecond);
}

uint toMsecs(Duration d) => cast(uint)d.total!`msecs`;
uint toSecs(Duration d) => cast(uint)d.total!`seconds`;
