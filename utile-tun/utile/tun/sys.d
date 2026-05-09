module utile.tun.sys;

version (linux)  :  // formatter bug

enum TUN_DEVICE = `/dev/net/tun`;

import core.stdc.errno, utile.except;
import utile_tun;

bool tunWrite(int fd, in void[] data)
{
	while (true)
	{
		auto written = write(fd, data.ptr, data.length);

		if (written == data.length)
		{
			return true;
		}

		if (errno != EAGAIN)
		{
			return false;
		}

		timespec ts;
		ts.tv_nsec = 100 * 1000; // 100 microseconds

		nanosleep(&ts, null);
	}
}

int tunRead(int fd, void[] data)
{
	return read(fd, data.ptr, data.length);
}

void tunClose(int fd)
{
	close(fd);
}

int tunOpen()
{
	int fd = open(TUN_DEVICE, O_RDWR | O_NONBLOCK);
	fd >= 0 || throwError!`failed to open %s`(TUN_DEVICE);
	return fd;
}

void createTun(int fd, string name, bool udp)
{
	ifreq e = makeIfr(name);

	with (e.ifr_ifru)
	{
		ifru_flags = IFF_TUN | IFF_NO_PI | IFF_VNET_HDR;
	}

	ioctl(fd, _TUNSETIFF, &e) >= 0 || throwError!`failed to create TUN device with name %s`(name);

	{
		uint vnetHdrSize = VNET_HEADER_SIZE;

		ioctl(fd, _TUNSETVNETHDRSZ, &vnetHdrSize) >= 0 || throwError!`failed to set VNET header size`;
	}

	{
		uint flags = _TUN_F_CSUM | _TUN_F_TSO_ECN; // enable checksum and ECN support for TSO

		// Enable TSO4 and TSO6 offloading
		flags |= _TUN_F_TSO4 | _TUN_F_TSO6;

		if (udp)
		{
			flags |= _TUN_F_USO4 | _TUN_F_USO6;
		}

		ioctl(fd, _TUNSETOFFLOAD, flags) >= 0 || throwError!`failed to enable offload features, error %d`(errno);
	}
}

void configureTun(string name, uint ip, uint mask, ushort mtu)
{
	int sock = socket(_AF_INET, SOCK_DGRAM, 0);
	sock >= 0 || throwError!`failed to create socket for TUN configuration`;

	scope (exit)
	{
		close(sock);
	}

	auto e = makeIfr(name);

	with (e.ifr_ifru)
	{
		// MTU
		ifru_mtu = mtu;
		doIoctl(sock, SIOCSIFMTU, &e);

		// IPv4 address
		*cast(sockaddr_in*)&ifru_addr = sockaddr_in(_AF_INET, 0, in_addr(ip));

		doIoctl(sock, SIOCSIFADDR, &e);

		// Netmask
		*cast(sockaddr_in*)&ifru_netmask = sockaddr_in(_AF_INET, 0, in_addr(mask));

		doIoctl(sock, SIOCSIFNETMASK, &e);

		// UP flag
		doIoctl(sock, SIOCGIFFLAGS, &e); // Need to re-fetch flags first.

		ifru_flags |= IFF_UP;

		doIoctl(sock, SIOCSIFFLAGS, &e);
	}
}

private:

void doIoctl(int fd, int op, void* arg)
{
	ioctl(fd, op, arg) >= 0 || throwError!`ioctl %d failed with error %d`(op, errno);
}

auto makeIfr(string name)
{
	ifreq ifr;

	with (ifr.ifr_ifrn)
	{
		ifrn_name[0 .. name.length] = name[];
		ifrn_name[name.length] = 0;
	}

	return ifr;
}
