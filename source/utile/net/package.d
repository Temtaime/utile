module utile.net;

import core.thread;
import std, utile, core.memory, core.sys.posix.arpa.inet;

public import utile.net.set, utile.net.headers;

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
