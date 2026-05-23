module utile.web;

import std.datetime, std.string, std.functional, utile, utile.net, utile.net.headers;
import utile_microhttpd;

public import utile.web.handler;
public import utile.web.connection;

final class WebServer
{
	this(ushort port, Duration connectionTimeout, LoggerBase parent)
	{
		_daemon = MHD_start_daemon(
			MHD_USE_ERROR_LOG | MHD_USE_NO_THREAD_SAFETY,
			port,
			null, null,
			&createResponse, this.toVoid,
			MHD_OPTION_CONNECTION_TIMEOUT, connectionTimeout.toSecs,
			MHD_OPTION_APP_FD_SETSIZE, _FD_SETSIZE,
			MHD_OPTION_NOTIFY_COMPLETED, &completeRequest, this.toVoid,
			MHD_OPTION_END
		);

		_daemon || throwError!`failed to start HTTP daemon on port %u`(port);

		routes[null][null] = toDelegate(&createHandler404);

		log = new SubLogger(parent, format!`HTTP:%u`(port));
	}

	~this()
	{
		MHD_stop_daemon(_daemon);
	}

	void run(ThreeSet ts)
	{
		MHD_run_from_select(_daemon, ts.rp!F, ts.wp!F, ts.ep!F) || throwError!`failed to run MHD from select`;
	}

	void fdset(ThreeSet ts)
	{
		MHD_socket fd;

		MHD_get_fdset(_daemon, ts.rp!F, ts.wp!F, ts.ep!F, &fd) || throwError!`failed to get MHD fdset`;

		ts.maxFd = cast(int)fd;
	}

	void setClientIP(HeaderNormalized header)
	{
		_ipHeader = header;
	}

	SubLogger log;

	//
	// routes[`/hello`][`GET`] = (conn) => new MyWebHandler(conn);
	//
	nothrow WebHandler delegate(WebConnection)[string][string] routes;
package:
	alias F = utile_microhttpd.fd_set;

	auto find(string method, string url) nothrow
	{
		if (auto h = url in routes)
		{
			if (auto m = method in *h) // exact match
			{
				return *m;
			}

			return (*h)[null]; // URL match
		}

		auto h = routes[null];

		if (auto m = method in h) // method match
		{
			return *m;
		}

		return h[null]; // default
	}

	string _ipHeader;
	MHD_Daemon* _daemon;
}
