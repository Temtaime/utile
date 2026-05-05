module utile.net.set;

import std.datetime, core.sys.posix.sys.select, core.sys.windows.winsock2, core.stdc.errno, utile.except;

final class ThreeSet
{
	this()
	{
		reset;
	}

	void select(Duration timeout)
	{
		int result;

		{
			auto vals = timeout.split!(`seconds`, `usecs`)();

			timeval tv;
			tv.tv_sec = cast(uint)vals.seconds;
			tv.tv_usec = cast(uint)vals.usecs;

			result = .select(_maxFd + 1, rp, wp, ep, &tv);
		}

		if (result >= 0)
		{
			return;
		}

		version (Windows)
		{
			if (WSAGetLastError() == WSAEINTR)
				return;
		}
		else
		{
			if (errno == EINTR)
				return;
		}

		throwError!`select failed`;
	}

	void reset()
	{
		FD_ZERO(rp);
		FD_ZERO(wp);
		FD_ZERO(ep);

		_maxFd = -1;
	}

	void maxFd(int fd)
	{
		if (fd > _maxFd)
		{
			_maxFd = fd;
		}
	}

	auto rp(alias F = fd_set)() => cast(F*)&_sets[0];
	auto wp(alias F = fd_set)() => cast(F*)&_sets[1];
	auto ep(alias F = fd_set)() => cast(F*)&_sets[2];
private:
	fd_set[3] _sets = void;
	int _maxFd;
}
