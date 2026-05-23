module utile.web.connection;

import std.string, utile, utile.web;
import std.socket : Address, InternetAddress, Internet6Address, parseAddress, sockaddr_in, sockaddr_in6, AF_INET;

import utile_microhttpd;

alias WriteFunc = int delegate(ulong pos, ubyte[] chunk);

final class WebConnection
{
	void send(ushort code, string msg)
	{
		auto response = MHD_create_response_from_buffer_copy(msg.length, msg.ptr);

		scope (exit)
		{
			MHD_destroy_response(response);
		}

		queueResponse(response, code);
	}

	void send(uint chunkSize, WriteFunc dg)
	{
		auto ctx = new ReaderContext(dg, this);
		gcRetain(ctx, true);

		auto response = MHD_create_response_from_callback(
			_MHD_SIZE_UNKNOWN,
			chunkSize,
			&cbReader,
			ctx,
			&cbReaderEnd);

		scope (exit)
		{
			MHD_destroy_response(response);
		}

		queueResponse(response, 200);
	}

	SubLogger logger;
	string[string] responseHeaders;
package:
	this(MHD_Connection* conn, string url, string method)
	{
		_conn = conn;
		_url = url;
		_method = method;
	}

	void initialize(string ipHeader, SubLogger parent)
	{
		collect(_headers, MHD_HEADER_KIND, `headers`);
		collect(_cookies, MHD_COOKIE_KIND, `cookies`);
		collect(_query, MHD_GET_ARGUMENT_KIND, `query parameters`);

		restoreIP(ipHeader, parent);

		logger = new SubLogger(parent, _addr.toString);
	}

	void collect(ref string[string] aa, MHD_ValueKind kind, string msg)
	{
		MHD_get_connection_values_n(_conn, kind, &collectHeaders, toVoid(&aa)) >= 0 || throwError!`failed to collect %s`(msg);
	}

	void restoreIP(string header, SubLogger l)
	{
		auto info = MHD_get_connection_info(_conn, MHD_CONNECTION_INFO_CLIENT_ADDRESS);
		assert(info);

		auto sa = info.client_addr;

		if (sa.sa_family == AF_INET)
		{
			_addr = new InternetAddress(*cast(sockaddr_in*)sa);
		}
		else
		{
			_addr = new Internet6Address(*cast(sockaddr_in6*)sa);
		}

		if (auto p = header in _headers)
		{
			auto s = split(*p, ',')[0].strip;

			try
			{
				_addr = parseAddress(s, _addr.toPortString);
			}
			catch (Exception e)
			{
				l.error!`failed to parse IP address: %s, error: %s`(s, e.msg);
			}
		}
	}

	void queueResponse(MHD_Response* response, ushort code)
	{
		processHeaders(response);
		MHD_queue_response(_conn, code, response) || throwError!`failed to queue response`;
	}

	void processHeaders(MHD_Response* response)
	{
		foreach (k, v; responseHeaders)
		{
			MHD_add_response_header(response, k.toStringz, v.toStringz) || throwError!`failed to set header: %s=%s`(k, v);
		}

		responseHeaders.clear;
	}

	mixin publicProperty!(string, `url`);
	mixin publicProperty!(string, `method`);
	mixin publicProperty!(string[string], `query`);
	mixin publicProperty!(string[string], `headers`);
	mixin publicProperty!(string[string], `cookies`);
	mixin publicProperty!(Address, `addr`);

	MHD_Connection* _conn;
}

private nothrow static extern (C):

MHD_Result collectHeaders(
	void* cls,
	MHD_ValueKind /*kind*/ ,
	const char* key,
	size_t keySize,
	const char* value,
	size_t valueSize)
{
	alias AA = string[string];

	auto aa = cast(AA*)cls;
	(*aa)[key[0 .. keySize].toLowerDup] = value[0 .. valueSize].idup;

	return MHD_YES;
}
