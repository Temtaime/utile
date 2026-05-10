module utile.curl.job;

import utile.curl, utile_curl;
import std, core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile;

import std : min, max;

import utile.mem, utile.net;

final class Job
{
	package this(string url)
	{
		_handle = curl_easy_init();

		{
			ubyte zero;
			option(CURLOPT_ACCEPT_ENCODING, &zero); // allow all encodings
		}

		// FIXME : centos bug
		{
			enum CERT = `/etc/pki/tls/certs/ca-bundle.crt`;

			if (CERT.exists)
			{
				option(CURLOPT_CAINFO, CERT);
			}
		}

		gcNoMove(this, true);

		option(CURLOPT_URL, url);
		option(CURLOPT_PRIVATE, this);

		option(CURLOPT_WRITEDATA, this);
		option(CURLOPT_WRITEFUNCTION, &writerFunc);

		option(CURLOPT_HEADERDATA, this);
		option(CURLOPT_HEADERFUNCTION, &headersFunc);

		_changeTime = MonoTime.currTime;
	}

	void lowSpeed(uint speed, Duration time)
	{
		option(CURLOPT_LOW_SPEED_LIMIT, speed);
		option(CURLOPT_LOW_SPEED_TIME, time.toSecs);
	}

	void impersonate(Browser b, bool impersonateHeaders)
	{
		auto c = curl_easy_impersonate(_handle, b.to!string.toStringz, impersonateHeaders);
		checkError(true, c, `impersonate`);
	}

	void buffers(uint sz)
	{
		option(CURLOPT_BUFFERSIZE, sz);
		option(CURLOPT_UPLOAD_BUFFERSIZE, sz);
	}

	void version_(Alpn v)
	{
		option(CURLOPT_HTTP_VERSION, v);
	}

	void header(string header, string value)
	{
		_headers = curl_slist_append(_headers, only(header, value).join(':').toStringz);
		option(CURLOPT_HTTPHEADER, _headers);
	}

	void cookies(string[string] aa)
	{
		string s;

		foreach (k, ref v; aa)
		{
			if (s.length)
			{
				s ~= ';';
			}

			auto p = curl_easy_escape(_handle, v.ptr, cast(uint)v.length);
			s ~= format!`%s=%s`(k, p.fromStringz);
			curl_free(p);
		}

		option(CURLOPT_COOKIE, s.toStringz);
	}

	void etag(string etag)
	{
		header(Header.ifMatch, etag);
	}

	void range(ulong start, ulong end)
	{
		option(CURLOPT_RANGE, format!`%u-%u`(start, end));
	}

	void auth(string user, string pass)
	{
		option(CURLOPT_USERNAME, user);
		option(CURLOPT_PASSWORD, pass);
	}

	void upload()
	{
		option(CURLOPT_UPLOAD, 1);
		option(CURLOPT_READDATA, this);
		option(CURLOPT_READFUNCTION, &readerFunc);
	}

	void upload(in void[] data)
	{
		static assert(size_t.sizeof == 8);

		option(CURLOPT_INFILESIZE_LARGE, data.length);
		upload();

		_postdata = data.toByte;
	}

	void noBody()
	{
		_noBody = true;
		option(CURLOPT_NOBODY, 1);
	}

	void method(string m)
	{
		option(CURLOPT_CUSTOMREQUEST, m);

		if (m == Method.head || m == Method.put || m == Method.delete_)
		{
			noBody;
		}
	}

	void wait()
	{
		while (!_done)
		{
			Fiber.yield;
		}
	}

	void wakeup()
	{
		assert(_paused);

		{
			auto c = curl_easy_pause(_handle, CURLPAUSE_CONT);
			checkError(true, c, `resume`);
		}

		_paused = false;
	}

	Blob data() const @property
	{
		isLengthBad && throwError!`%s is %u, but response length is %u`(Header.contentLength, _contentLength, _data.length);

		return _data;
	}

	string responseHeader(string name) => _responseHeaders.get(name.toLower, null);

	uint delegate(Job, ubyte[] data) onRead;
	uint delegate(Job, ubyte[] data) onWrite;

	void delegate(Job) onHeaders;
	void delegate(Job) onComplete;
package:
	mixin publicProperty!(bool, `aborted`);

	void complete()
	{
		gcNoMove(this, false);

		if (isLengthBad)
		{
			_isError = true;
		}

		try
		{
			if (onComplete)
			{
				onComplete(this);
			}
		}
		catch (Exception ex)
		{
			logger.error(ex);
		}

		_done = true;
		onComplete = null;
	}

	void cleanup()
	{
		curl_easy_cleanup(_handle);
		curl_slist_free_all(_headers);
	}

	static fromHandle(CURL* handle)
	{
		Job job;
		optget(handle, CURLINFO_PRIVATE, job);
		return job;
	}

	@property handle() => _handle;
private:
	mixin publicProperty!(bool, `done`);
	mixin publicProperty!(bool, `isError`, `true`);

	mixin publicProperty!(bool, `paused`);
	mixin publicProperty!(long, `contentLength`, `-1`);

	mixin publicProperty!(ushort, `code`);
	mixin publicProperty!(string[string], `responseHeaders`);

	void option(CURLoption opt, string value) => option(opt, value.toStringz);
	void option(T)(CURLoption opt, T value) if (is(T == class) || isPointer!T) => option(opt, cast(long)cast(void*)value);

	void option(CURLoption opt, long value)
	{
		auto res = curl_easy_setopt(_handle, opt, value); // always pass value as 64-bit integer
		checkError(true, res, `option`);
	}

	static optget(T)(CURL* handle, CURLINFO opt, ref T value)
	{
		auto res = curl_easy_getinfo(handle, opt, &value);
		checkError(true, res, `get info`);
	}

	void optget(T)(CURLINFO opt, ref T value) => optget(_handle, opt, value);

	bool isLengthBad() const
	{
		if (_noBody || _contentLength < 0 || onWrite is null)
		{
			return false;
		}

		return _data.length != _contentLength;
	}

	extern (C) static
	{
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
						_isError = _code / 100 != 2;
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
						_aborted = true;
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
			auto self = cast(Job)userdata;

			with (self)
			{
				if (onWrite)
				{
					uint n = onWrite(self, chunk);

					switch (n)
					{
					case Write.abort:
						_aborted = true;
						return n;

					case Write.pause:
						_paused = true;
						return n;

					default:
						return n;
					}
				}

				_data ~= chunk;
				return chunk.length;
			}
		}
	}

	bool _noBody;
	MonoTime _changeTime;

	uint _upload;
	uint _download;

	Blob _data;

	curl_slist* _headers;
	Blob _postdata;

	CURL* _handle;
}
