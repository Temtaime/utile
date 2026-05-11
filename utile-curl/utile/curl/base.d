module utile.curl.base;

import utile.curl, utile_curl;
import std, core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile;

import std : min, max;

import utile.mem, utile.net;

package:

abstract class JobBase
{
protected:
	mixin publicProperty!(bool, `done`);
	mixin publicProperty!(bool, `aborted`);
	mixin publicProperty!(bool, `hasError`, `true`);

	mixin publicProperty!(bool, `paused`);
	mixin publicProperty!(long, `contentLength`, `-1`);

	mixin publicProperty!(ushort, `code`);
	mixin publicProperty!(string[string], `responseHeaders`);

	void option(CURLoption opt, string value) => option(opt, value.toStringz);
	void option(T)(CURLoption opt, T value) if (is(T == class) || isPointer!T) => option(opt, cast(long)cast(void*)value);

	void option(CURLoption opt, long value)
	{
		auto res = curl_easy_setopt(_handle, opt, value); // always pass value as 64-bit integer
		checkError(null, res, `option`);
	}

	static optget(T)(CURL* handle, CURLINFO opt, ref T value)
	{
		auto res = curl_easy_getinfo(handle, opt, &value);
		checkError(null, res, `get info`);
	}

	void optget(T)(CURLINFO opt, ref T value) => optget(_handle, opt, value);

	CURL* _handle;

	Blob _data;
	Blob _postdata;

	ulong _received;
}

void checkError(SubLogger logger, CURLcode code, string msg)
{
	if (code == CURLE_OK)
		return;

	enum F = `easy %s failed, error %d - %s`;
	auto error = curl_easy_strerror(code).fromStringz;

	if (logger)
	{
		logger.error!F(msg, code, error);
	}
	else
		throwError!F(msg, code, error);
}

extern (C):

size_t headersFunc(char* buffer, size_t size, size_t nitems, void* userdata)
{
	assert(size == 1);

	auto s = buffer[0 .. nitems].assumeUnique.strip;
	auto self = cast(Job)userdata;

	with (self)
	{
		if (s.empty)
		{
			if (onHeaders)
			{
				onHeaders(self);
			}

			return nitems;
		}

		if (s.startsWith(`HTTP/`))
		{
			auto chunks = s.split;

			if (chunks.length >= 2)
			{
				_code = cast(ushort)chunks[1].to!ushort;
				_hasError = _code / 100 != 2;
			}
			else
			{
				logger.error!`bad status line: %s`(s);
			}

			_responseHeaders.clear;
			return nitems;
		}

		auto idx = s.indexOf(':');

		if (idx < 0)
		{
			logger.error!`bad header: %s`(s);
		}
		else
		{
			auto key = s[0 .. idx]
				.stripRight
				.toLowerDup;

			auto value = s[idx + 1 .. $]
				.stripLeft
				.idup;

			if (key == HeaderNormalized.contentLength)
			{
				_contentLength = value.to!ulong;
			}

			_responseHeaders[key] = value;
		}

		return nitems;
	}
}

size_t readerFunc(ubyte* tmp, size_t size, size_t blocks, void* userdata)
{
	auto chunk = tmp[0 .. size * blocks];
	auto self = cast(Job)userdata;

	with (self)
	{
		if (onRead)
		{
			uint n = onRead(self, chunk);

			switch (n)
			{
			case Read.abort:
				abort(`read callback`);
				return n;

			case Read.pause:
				_paused = true;
				return n;

			default:
				return n;
			}
		}

		auto k = min(chunk.length, _postdata.length);

		chunk[] = _postdata[0 .. k];
		_postdata = _postdata[k .. $];

		return k;
	}
}

size_t writerFunc(ubyte* tmp, size_t size, size_t blocks, void* userdata)
{
	auto chunk = tmp[0 .. size * blocks];

	auto sz = chunk.length;
	auto self = cast(Job)userdata;

	with (self)
	{
		if (onWrite)
		{
			auto code = onWrite(self, chunk);

			switch (code)
			{
			case Write.abort:
				abort(`write callback`);
				return code;

			case Write.pause:
				_paused = true;
				return code;

			default:
				_received += sz;
				return code;
			}
		}

		_data ~= chunk;
		_received += sz;

		return sz;
	}
}
