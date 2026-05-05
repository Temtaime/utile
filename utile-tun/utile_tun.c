#include "../source/utile_common.h"

#include <linux/posix_types.h>

#undef __SIZEOF_INT128__
#include <linux/types.h>

#include <sys/ioctl.h>
#include <unistd.h>

#include <linux/if.h>
#include <linux/if_tun.h>
#include <linux/in.h>

#include <fcntl.h>
#include <sys/stat.h>
#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>

int open_tun()
{
	return open("/dev/net/tun", O_RDWR | O_NONBLOCK);
}

bool write_tun(int fd, const void* data, size_t size)
{
	while(true)
	{
		int written = write(fd, data, size);

		if(written == size)
		{
			return true;
		}

		if(errno != EAGAIN)
		{
			return false;
		}

		timespec ts = { 0, 500 * 1000 }; // 500 microseconds
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
	ifreq e = {};

	strncpy(e.ifrn_name, name, IFNAMSIZ);

	return e;
}

#define CHECKED(req, arg, msg) if(ioctl(fd, req, &arg) < 0) return msg;

const char* setup_device(int fd, const char* name, bool udpOffload)
{
	ifreq e = make(name);

	// create tun device with vnet header and no packet info
	{
		e.ifru_flags = IFF_TUN | IFF_NO_PI | IFF_VNET_HDR;

		CHECKED(TUNSETIFF, e, "failed to create tun device")
	}

	// set vnet header size
	{
		uint32_t vnetHdrSize = VNET_HEADER_SIZE;

		CHECKED(TUNSETVNETHDRSZ, e, "failed to set vnet header size")
	}

	// enable offload features
	{
		uint32_t flags = TUN_F_CSUM | TUN_F_TSO_ECN;

		flags |= TUN_F_TSO4 | TUN_F_TSO6;

		if(udpOffload)
		{
			flags |= TUN_F_USO4 | TUN_F_USO6;
		}

		CHECKED(TUNSETOFFLOAD, flags, "failed to enable offload features")
	}

	return nullptr;
}

#undef CHECKED
#define CHECKED(req, s) if(ioctl(sock, req, &e) < 0) { msg = s; goto ret; }

const char* configure_tun(const char* name, uint32_t mtu, uint32_t ip, uint32_t mask)
{
	int sock = socket(AF_INET, SOCK_DGRAM, 0);

	if(sock < 0)
	{
		return "failed to create socket for TUN configuration";
	}

	ifreq e = make(name);
	const char* msg = nullptr;

	// MTU
	{
		e.ifru_mtu = mtu;

		CHECKED(SIOCSIFMTU, "failed to set MTU")
	}

	// IPv4 address
	{
		struct sockaddr_in *sin = (struct sockaddr_in*)&e.ifru_addr;

		sin.sin_family = AF_INET;
		sin.sin_addr = in_addr(ip);

		CHECKED(SIOCSIFADDR, "failed to set IP address")
	}

	// netmask
	{
		struct sockaddr_in *sin = (struct sockaddr_in*)&e.ifru_netmask;

		sin.sin_family = AF_INET;
		sin.sin_addr = in_addr(mask);

		CHECKED(SIOCSIFNETMASK, "failed to set netmask")
	}

	// UP flag
	{
		// we need to get the existing flags first
		CHECKED(SIOCGIFFLAGS, "failed to get interface flags")

		e.ifru_flags |= IFF_UP;

		CHECKED(SIOCSIFFLAGS, "failed to set interface UP")
	}

ret:
	close(sock);
	return msg;
}
