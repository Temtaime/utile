module utile.tun.linux;

import std.string, std.process, std.conv, utile, core.stdc.errno, utile.tun, utile.net;
import core.sys.posix.time;

version (linux)
{
	import utile.tun.sys;
}

final class LinuxTunDevice : TunDevice
{
	this(string name, Logger parent)
	{
		_name = name;

		logger = new SubLogger(parent, _name);
		logger.info!`creating tun ...`;

		version (linux)
		{
			_fd = tunOpen;
			createTun(_fd, _name, false);
		}
		else
			assert(false);
	}

	~this()
	{
		logger.info!`tun shutting down ...`;

		version (linux)
		{
			tunClose(_fd);
		}
	}

	void configure(TunSettings s)
	{
		if (_s == s)
		{
			return;
		}

		logger.info!`configuring: MTU %u, IP %s/%u`(s.mtu, s.ip.ipToString, s.prefix);

		version (linux)
		{
			configureTun(_name, s.ip, prefixToNetmask(s.prefix), s.mtu);
		}

		_s = s;
	}

	void write(const(ubyte)[] data)
	{
		logger.dbg!`writing %u bytes`(data.length);

		version (linux)
		{
			tunWrite(_fd, data);
		}
	}

	ubyte[] read()
	{
		version (linux)
		{
			uint n = tunRead(_fd, _buf);

			if (n == 0)
			{
				return null;
			}

			logger.dbg!`read %u bytes`(n);

			assert(n >= MIN_FRAME && n <= MAX_FRAME);

			return _buf[0 .. n];
		}
		else
		{
			assert(false);
		}
	}

	mixin IpUtil;

	SubLogger logger;
private:
	mixin publicProperty!(int, `fd`);

	string _name;
	TunSettings _s;

	ubyte[MAX_FRAME + 1] _buf; // extra space to be able to detect if packet is too big for buffer
}

private:

mixin template IpUtil()
{
	void assignAddress(uint[] ips, ubyte prefix)
	{
		foreach (ip; ips)
		{
			auto s = ip.ipToString;
			auto cmd = [`ip`, `addr`, `add`, s ~ `/` ~ prefix.to!string, `dev`, _name];

			logger.info2!`adding IP %s/%u`(s, prefix);

			auto result = execute(cmd);
			result.status && throwError!`failed to add IP %s to %s: %s`(s, _name, result.output);
		}
	}

	void setupFwmark(uint value, uint table)
	{
		auto tableStr = table.to!string;
		auto markStr = value.to!string;

		logger.info2!`setting up fwmark %u for table %u`(value, table);

		// clean table
		[`ip`, `route`, `flush`, `table`, tableStr].execute;

		// add route
		{
			auto result = [`ip`, `route`, `add`, `default`, `dev`, _name, `table`, tableStr].execute;

			result.status && throwError!`failed to add route for %s: %s`(_name, result.output);
		}

		// clean fwmark
		[`ip`, `rule`, `del`, `fwmark`, markStr, `table`, tableStr].execute;

		// add fwmark
		{
			auto result = [`ip`, `rule`, `add`, `fwmark`, markStr, `table`, tableStr].execute;

			result.status && throwError!`failed to add rule for fwmark %u: %s`(value, result.output);
		}
	}
}
