module utile.web.client;

import std, utile, utile.web;
import utile_microhttpd;

//version = DEBUG_REQUESTS;

abstract class WebClient
{
	nothrow
	{
		this(void* conn, string url, string method)
		{
			_conn = cast(MHD_Connection*)conn;
			_url = url;
			_method = method;

			MHD_get_connection_values_n(_conn, MHD_HEADER_KIND, &collectHeaders, this.toVoid); // >= 0 || throwError!`failed to get connection headers`;
		}

		abstract void onCreate();
		abstract void onResponse();
		abstract void onComplete();

		// used for chunked responses
		int onSend(ulong pos, ubyte[] chunk)
		{
			assert(false);
		}

		// used for receiving request body in chunks
		void onReceive(in ubyte[] chunk)
		{
		}

		void send(ushort code, string msg)
		{
			auto response = MHD_create_response_from_buffer_copy(msg.length, msg.ptr);

			queueResponse(response, code);
			MHD_destroy_response(response);
		}

		void send(uint chunkSize)
		{
			auto response = MHD_create_response_from_callback(
				_MHD_SIZE_UNKNOWN,
				chunkSize,
				&cbReader,
				this.toVoid,
				&cbReaderEnd);

			queueResponse(response, 200);
			MHD_destroy_response(response);
		}
	}

	string[string] responseHeaders;
private:
	nothrow
	{
		void queueResponse(MHD_Response* response, ushort code)
		{
			processHeaders(response);

			if (MHD_queue_response(_conn, code, response) == MHD_NO)
			{
				//logger.error!`failed to queue response`;
			}
		}

		void processHeaders(MHD_Response* response)
		{
			foreach (kv; responseHeaders.byKeyValue)
			{
				MHD_add_response_header(response, kv.key.toStringz, kv.value.toStringz); // || throwError!`failed to set header: %s=%s`(k, v);
			}

			responseHeaders.clear;
		}
	}

	mixin publicProperty!(string, `url`);
	mixin publicProperty!(string, `method`);
	mixin publicProperty!(string[string], `headers`);

	MHD_Connection* _conn;
}

extern (C) static nothrow:

MHD_Result collectHeaders(
	void* cls,
	MHD_ValueKind kind,
	const char* key,
	size_t keySize,
	const char* value,
	size_t valueSize)
{
	with (cast(WebClient)cls)
	{
		assert(kind == MHD_HEADER_KIND);

		auto k = key[0 .. keySize];

		_headers[k.toLowerDup] = value[0 .. valueSize].idup;
	}

	return MHD_YES;
}

ptrdiff_t cbReader(void* cls, ulong pos, char* buf, size_t max)
{
	auto client = cast(WebClient)cls;

	return client.onSend(pos, buf[0 .. max].toByte);
}

void cbReaderEnd(void* cls)
{
}

void completeRequest(void* cls, MHD_Connection* connection, void** req_cls, MHD_RequestTerminationCode /*toe*/ )
{
	auto client = cast(WebClient)*req_cls;
	client.onComplete;

	gcMark(client, false);
	gcNoMove(client, false);

	version (DEBUG_REQUESTS)
	{
		logger.info2!`[WEB] Completed request : %s %s`(client.method, client.url);
	}
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
	WebClient client = cast(WebClient)*req_cls;

	if (client)
	{
		if (*upload_data_size)
		{
			client.onReceive(upload_data[0 .. *upload_data_size].toByte);
			*upload_data_size = 0;
		}
		else
		{
			client.onResponse;
		}
	}
	else
	{
		WebServer server = cast(WebServer)cls;

		client = server.createClient(connection, url.fromStringz.idup, method.fromStringz.idup);

		gcMark(client, true);
		gcNoMove(client, true);

		version (DEBUG_REQUESTS)
		{
			logger.info2!`[WEB] New request : %s %s`(client.method, client.url);
		}

		client.onCreate;
		*req_cls = client.toVoid;
	}

	return MHD_YES;
}
