module utile.tun.linux;

import std.string, std.process, std.conv, utile, core.stdc.errno, utile.tun, utile.net;
import core.sys.posix.time;

version (linux)
{
	import utile_tun;
}

final class LinuxTunDevice : TunDevice
{
	this(string name, Logger logger)
	{
		_name = name;
		_logger = new SubLogger(logger, _name);

		_logger.info!`creating tun ...`;

		version (linux)
		{
			_fd = open_tun;
			_fd >= 0 || throwError!`failed to access tun device`;

			auto err = setup_device(_fd, _name.toStringz, false);
			err && throwError(err.fromStringz);
		}
		else
			assert(false);
	}

	~this()
	{
		_logger.info!`tun shutting down ...`;

		version (linux)
		{
			close_tun(_fd);
		}
	}

	void configure(TunSettings s)
	{
		if (_s == s)
		{
			return;
		}

		_logger.info!`configuring: MTU %u, IP %s/%u`(s.mtu, s.ip.ipToString, s.prefix);

		version (linux)
		{
			auto err = configure_tun(_name.toStringz, s.mtu, s.ip, prefixToNetmask(s.prefix));
			err && throwError(err.fromStringz);
		}

		_s = s;
	}

	void write(const(ubyte)[] data)
	{
		_logger.dbg!`writing %u bytes`(data.length);

		version (linux)
		{
			write_tun(_fd, data.ptr, data.length) || throwError!`error %d writing to %s: buffer length %u`(errno, _name, data.length);
		}
	}

	ubyte[] read()
	{
		version (linux)
		{
			int bytesRead = read_tun(_fd, _buf.ptr, _buf.length);

			if (bytesRead <= 0)
			{
				errno == EAGAIN || throwError!`error %d reading from %s: buffer length %u, bytes read %d`(errno, _name, _buf.length, bytesRead);
				return null;
			}

			_logger.dbg!`read %u bytes`(bytesRead);

			assert(bytesRead >= MIN_FRAME && bytesRead <= MAX_FRAME);

			return _buf[0 .. bytesRead];
		}
		else
		{
			assert(false);
		}
	}

	mixin IpUtil;
private:
	mixin publicProperty!(int, `fd`);

	string _name;
	TunSettings _s;

	SubLogger _logger;
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

			_logger.info2!`adding IP %s/%u`(s, prefix);

			auto result = execute(cmd);
			result.status && throwError!`failed to add IP %s to %s: %s`(s, _name, result.output);
		}
	}

	void setupFwmark(uint value, uint table)
	{
		auto tableStr = table.to!string;
		auto markStr = value.to!string;

		_logger.info2!`setting up fwmark %u for table %u`(value, table);

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
