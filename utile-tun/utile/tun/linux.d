module utile.tun.linux;

import std.string, std.process, std.conv, utile, core.stdc.errno, utile.tun, utile.net;

import core.sys.posix.time;

class LinuxTunDevice : TunDevice
{
	this(string name)
	{
		logger.info!`creating %s`(name);

		_name = name;

		version (linux)
		{
			_fd = open_tun;
			_fd >= 0 || throwError!`failed to access tun device`;

			auto err = setup_device(_fd, name.toStringz, false);
			err && throwError!`failed to setup tun device %s: %s`(name, err);
		}
		else
			assert(false);
	}

	~this()
	{
		logger.info!`closing %s`(_name);

		version (linux)
		{
			close_tun(_fd);
		}
	}

	void configure(TunSettings s)
	{
		if (_s == s)
			return;

		logger.info!`configuring %s with MTU %u, IP %s/%u`(_name, s.mtu, s.ip.ipToString, s.prefix);

		version (linux)
		{
			auto err = configure_tun(_name.toStringz, s.mtu, s.ip, prefixToNetmask(s.prefix));
			err && throwError!`failed to configure tun device %s: %s`(_name, err);
		}

		_s = s;
	}

	void write(const(ubyte)[] data)
	{
		version (DEBUG_TUN)
		{
			logger.info3!`writing %u bytes to %s`(data.length, _name);
		}

		version (linux)
		{
			write_tun(_fd, data.ptr, data.length) || throwError!`error %d writing to %s, data length %u`(errno, _name, data.length);
		}
	}

	ubyte[] read()
	{
		version (linux)
		{
			int bytesRead = read_tun(_fd, _buf.ptr, _buf.length);

			if (bytesRead <= 0)
			{
				errno == EAGAIN || throwError!`error %d reading from %s, buffer length %u, bytes read %d`(errno, _name, _buf.length, bytesRead);
				return null;
			}

			version (DEBUG_TUN)
			{
				logger.info3!`read %u bytes from %s`(bytesRead, _name);
			}

			assert(bytesRead >= MIN_FRAME && bytesRead <= MAX_FRAME);

			return _buf[0 .. bytesRead];
		}
		else
		{
			assert(false);
		}
	}

private:
	mixin publicProperty!(int, `fd`);

	TunSettings _s;
	string _name;

	ubyte[MAX_FRAME + 1] _buf; // extra space to be able to detect if packet is too big for buffer
}

struct IpUtil
{
static:
	void assignAddress(string dev, uint[] ips, ubyte prefix)
	{
		foreach (ip; ips)
		{
			auto s = ip.ipToString;
			auto cmd = [`ip`, `addr`, `add`, s ~ `/` ~ prefix.to!string, `dev`, dev];

			logger.info2!`adding IP %s/%u to %s`(s, prefix, dev);

			auto result = execute(cmd);
			result.status && throwError!`failed to add IP %s to %s: %s`(s, dev, result.output);
		}
	}

	void setupFwmark(string dev, uint value, uint table)
	{
		auto tableStr = table.to!string;
		auto markStr = value.to!string;

		logger.info2!`setting up fwmark %u routing for %s (table %u)`(value, dev, table);

		// clean table
		[`ip`, `route`, `flush`, `table`, tableStr].execute;

		// add route
		{
			auto result = [`ip`, `route`, `add`, `default`, `dev`, dev, `table`, tableStr].execute;

			result.status && throwError!`failed to add route for %s: %s`(dev, result.output);
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

version (linux)  :  // formatter bug

import utile_tun;
