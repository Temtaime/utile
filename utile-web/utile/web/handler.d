module utile.web.handler;

import std.datetime, std.string, std.socket, utile, utile.web;

import utile_microhttpd;

abstract class WebHandler
{
	this(WebConnection conn_) nothrow
	{
		conn = conn_;
	}

	void onCreate()
	{
	}

	abstract void onResponse();

	void onComplete()
	{
	}

	// used for receiving request body
	void onReceive(in ubyte[] chunk)
	{
	}

	@property logger() => conn.logger;

	WebConnection conn;
}

final class HandlerErrorCode : WebHandler
{
	this(WebConnection conn, ushort code, string msg) nothrow
	{
		super(conn);

		_msg = msg;
		_code = code;
	}

	override void onResponse() => conn.send(_code, _msg);
private:
	string _msg;
	ushort _code;
}

nothrow:

auto createHandler403(WebConnection conn) => new HandlerErrorCode(conn, 403, `Forbidden`);
auto createHandler404(WebConnection conn) => new HandlerErrorCode(conn, 404, `Not Found`);
auto createHandler500(WebConnection conn) => new HandlerErrorCode(conn, 500, `Internal Server Error`);

package static extern (C):

struct ReaderContext
{
	WriteFunc sender;
	WebConnection conn;
}

ptrdiff_t cbReader(void* cls, ulong pos, char* buf, size_t max)
{
	auto ctx = cast(ReaderContext*)cls;
	auto l = ctx.conn.logger;

	try
	{
		return ctx.sender(pos, buf[0 .. max].toByte);
	}
	catch (Exception e)
	{
		l.error!`failed to send data: %s`(e.msg);

		return MHD_CONTENT_READER_END_WITH_ERROR;
	}
}

void cbReaderEnd(void* cls)
{
	auto ctx = cast(ReaderContext*)cls;
	gcRetain(ctx, false);
}

void completeRequest(void* cls, MHD_Connection* connection, void** req_cls, MHD_RequestTerminationCode toe)
{
	auto handler = cast(WebHandler)*req_cls;
	auto l = handler.logger;

	try
	{
		handler.onComplete;
	}
	catch (Exception e)
	{
		l.error!`failed to complete request: %s`(e.msg);
	}

	gcRetain(handler, false);

	l.info2!`completed with code %s`(toe);
}

MHD_Result createResponse(
	void* cls,
	MHD_Connection* connection,
	const(char)* url,
	const(char)* method,
	const(char)* version_,
	const(char)* upload_data,
	size_t* upload_data_size,
	void** req_cls)
{
	auto handler = cast(WebHandler)*req_cls;

	if (handler)
	{
		auto l = handler.conn.logger;
		size_t data = *upload_data_size;

		try
		{
			if (data)
			{
				handler.onReceive(upload_data[0 .. data].toByte);
				*upload_data_size = 0;
			}
			else
			{
				handler.onResponse;
			}

			return MHD_YES;
		}
		catch (Exception e)
		{
			if (data)
			{
				l.error!`failed to receive %u bytes: %s`(data, e.msg);
			}
			else
			{
				l.error!`failed to handle request: %s`(e.msg);
			}

			return MHD_NO;
		}
	}

	with (cast(WebServer)cls)
	{
		WebConnection conn;

		try
		{
			conn = new WebConnection(connection, url.fromStringz.idup, method.fromStringz.idup);
			conn.initialize(_ipHeader, log);
		}
		catch (Exception e)
		{
			log.error!`failed to initialize connection: %s`(e.msg);
			return MHD_NO;
		}

		auto l = conn.logger;
		auto h = find(conn.method, conn.url)(conn);

		l.info!`got a new request: %s %s`(conn.method, conn.url);

		try
		{
			h.onCreate;
		}
		catch (Exception e)
		{
			l.error!`failed to create handler: %s`(e.msg);
			h = createHandler500(conn);
		}

		gcRetain(h, true);

		*req_cls = h.toVoid;
	}

	return MHD_YES;
}
