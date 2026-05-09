module utile.net.set;

import std.datetime, std.algorithm, core.sys.posix.sys.select, core.sys.windows.winsock2, core.stdc.errno, utile.except;

enum OpIndex
{
	read,
	write,
	except
}

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
			auto vals = timeout.split!(`seconds`, `usecs`);

			timeval tv;
			tv.tv_sec = cast(uint)vals.seconds;
			tv.tv_usec = cast(uint)vals.usecs;

			result = .select(_maxFd + 1, rp, wp, ep, &tv);
		}

		if (result >= 0)
		{
			return;
		}

		bool isOK;

		version (Windows)
		{
			isOK = WSAGetLastError() == WSAEINTR;
		}
		else
		{
			isOK = errno == EINTR;
		}

		isOK || throwError!`select failed`;
	}

	void reset()
	{
		_maxFd = -1;

		_sets.each!((ref a) => FD_ZERO(&a));
	}

	void maxFd(int fd)
	{
		if (fd > _maxFd)
		{
			_maxFd = fd;
		}
	}

	void add(OpIndex idx, int fd)
	{
		maxFd = fd;

		FD_SET(fd, _sets.ptr + idx);
	}

	auto rp(alias F = fd_set)() => cast(F*)&_sets[0];
	auto wp(alias F = fd_set)() => cast(F*)&_sets[1];
	auto ep(alias F = fd_set)() => cast(F*)&_sets[2];
private:
	fd_set[3] _sets = void;
	int _maxFd;
}
