module utile.web;

import std, utile, utile.net;
import utile_microhttpd;

public import utile.web.client;

class WebServer
{
	this(ushort port, Duration connectionTimeout)
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

	nothrow WebClient delegate(void* conn, string url, string method) createClient;
private:
	alias F = utile_microhttpd.fd_set;

	MHD_Daemon* _daemon;
}
