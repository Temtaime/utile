module utile.tun.sys;

version (linux)  :  // formatter bug

import utile.except;
import utile_tun;

int open_tun()
{
	return open("/dev/net/tun", O_RDWR | O_NONBLOCK);
}

bool write_tun(int fd, const void* data, size_t size)
{
	while (true)
	{
		int written = write(fd, data, size);

		if (written == size)
		{
			return true;
		}

		if (errno != EAGAIN)
		{
			return false;
		}

		timespec ts = {0, 500 * 1000}; // 500 microseconds
		nanosleep(&ts, nullptr);
	}
}

int read_tun(int fd, void* data, size_t size)
{
	return read(fd, data, size);
}

void close_tun(int fd)
{
	close(fd);
}

ifreq make(const char* name)
{
	ifreq e;

	strncpy(e.ifrn_name, name, IFNAMSIZ);

	return e;
}

void setup_device(int fd, const char* name, bool udp)
{
	ifreq e = make(name);

	void do_(A)(uint req, ref A arg, string msg)
	{
		ioctl(fd, req, &arg) >= 0 || throwError(msg);
	}

	// create tun device with vnet header and no packet info
	{
		e.ifru_flags = IFF_TUN | IFF_NO_PI | IFF_VNET_HDR;

		do_(TUNSETIFF, e, "failed to create tun device");
	}

	// set vnet header size
	{
		uint vnetHdrSize = VNET_HEADER_SIZE;

		do_(TUNSETVNETHDRSZ, vnetHdrSize, "failed to set vnet header size");
	}

	// enable offload features
	{
		uint flags = TUN_F_CSUM | TUN_F_TSO_ECN;

		flags |= TUN_F_TSO4 | TUN_F_TSO6;

		if (udp)
		{
			flags |= TUN_F_USO4 | TUN_F_USO6;
		}

		do_(TUNSETOFFLOAD, flags, "failed to enable offload features");
	}

	return nullptr;
}

void configure_tun(const char* name, uint32_t mtu, uint32_t ip, uint32_t mask)
{
	int sock = socket(AF_INET, SOCK_DGRAM, 0);
	sock >= 0 || throwError!`failed to create socket`;

	scope (exit)
	{
		close(sock);
	}

	void do_(A)(uint req, string msg)
	{
		ioctl(sock, req, &e) >= 0 || throwError(msg);
	}

	ifreq e = make(name);

	// MTU
	{
		e.ifru_mtu = mtu;

		do_(SIOCSIFMTU, "failed to set MTU");
	}

	// IPv4 address
	{
		auto sin = cast(sockaddr_in*)&e.ifru_addr;

		sin.sin_family = AF_INET;
		sin.sin_addr = in_addr(ip);

		do_(SIOCSIFADDR, "failed to set IP address");
	}

	// netmask
	{
		auto sin = cast(sockaddr_in*)&e.ifru_netmask;

		sin.sin_family = AF_INET;
		sin.sin_addr = in_addr(mask);

		do_(SIOCSIFNETMASK, "failed to set netmask");
	}

	// UP flag
	{
		// we need to get the existing flags first
		do_(SIOCGIFFLAGS, "failed to get interface flags");

		e.ifru_flags |= IFF_UP;

		do_(SIOCSIFFLAGS, "failed to set interface UP");
	}
}
