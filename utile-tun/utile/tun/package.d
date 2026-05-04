module utile.tun;
import std, utile, core.stdc.errno;

import utile.tun.linux;

//version = DEBUG_TUN;

enum MIN_PACKET = 20;
enum MAX_PACKET = ushort.max;

enum VNET_HEADER_SIZE = 12;

enum MIN_FRAME = VNET_HEADER_SIZE + MIN_PACKET; // min IP packet + VNET header size
enum MAX_FRAME = VNET_HEADER_SIZE + MAX_PACKET; // max MTU + VNET header size

struct TunSettings
{
	uint ip;
	ubyte prefix;
	ushort mtu;
}

interface TunDevice
{
	ubyte[] read();
	void write(Blob data);

	void configure(TunSettings s);
}

TunDevice createTunDevice(string name)
{
	version (linux)
	{
		return new LinuxTunDevice(name);
	}
	else
	{
		assert(false);
	}
}
