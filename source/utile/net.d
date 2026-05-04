module utile.net;

import core.thread;
import std, utile, core.memory, core.sys.posix.arpa.inet;

version (Windows)
{
	import core.sys.windows.winsock2 : fd_set;
	public import core.sys.windows.winsock2 : FD_SET;
}
else
{
	import core.stdc.errno;
	import core.sys.posix.sys.time : timeval;
	import core.sys.posix.sys.select : select, fd_set;
	public import core.sys.posix.sys.select : FD_SET;
}

uint prefixToNetmask(ubyte prefix)
{
	uint mask = prefix ? uint.max << (32 - prefix) : 0;
	return mask.htonl;
}

string ipToString(uint ip)
{
	return InternetAddress.addrToString(ip.ntohl);
}

uint parseIp(string ip)
{
	uint res = InternetAddress.parse(ip);
	res != InternetAddress.ADDR_NONE || throwError!`invalid IP address: %s`(ip);

	return res.htonl;
}

void checkMtu(ushort mtu)
{
	mtu >= 68 && mtu <= 9000 || throwError!`invalid MTU size: %u`(mtu);
}

struct Selector
{
	void do_(Duration d)
	{
		auto ds = d.split!(`seconds`, `usecs`);

		timeval tv = timeval(cast(uint)ds.seconds, cast(uint)ds.usecs);

		if (select(_maxFd + 1, asPtr.expand, &tv) < 0)
		{
			version (Posix)
			{
				errno == EINTR || throwError!`select failed: %d`(errno);
			}
			else
			{
				auto err = WSAGetLastError();

				if (err != WSAEINVAL || _sets[].any!(a => a.fd_count))
				{
					throwError!`select failed: %d`(err);
				}

				Thread.sleep(1.msecs);
			}
		}
	}

	auto asPtr(T = fd_set)()
	{
		alias U = Tuple!(T*, T*, T*);

		// FIXME : for curl
		//static assert(T.sizeof == fd_set.sizeof);

		return U(_sets[]
				.map!((ref a) => cast(T*)&a)
				.staticArray!3);
	}

	ref asRef(T = fd_set)()
	{
		alias U = Tuple!(T, T, T);
		static assert(U.sizeof == _sets.sizeof);

		return cast(U)_sets;
	}

	void add(int maxfd)
	{
		if (maxfd > _maxFd)
		{
			_maxFd = maxfd;
		}
	}

	auto read() => &_sets[0];
	auto write() => &_sets[1];
	auto except() => &_sets[2];

private:
	fd_set[3] _sets;
	int _maxFd = -1;
}
