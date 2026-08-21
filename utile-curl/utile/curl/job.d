module utile.curl.job;

import utile.curl, utile_curl;
import std, core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile;

import std : min, max;

import utile.mem, utile.net, utile.net.headers;
import utile.curl.base;

final class Job : JobBase
{
	void lowSpeed(uint speed, Duration time)
	{
		option(CURLOPT_LOW_SPEED_LIMIT, speed);
		option(CURLOPT_LOW_SPEED_TIME, time.toSecs);
	}

	void impersonate(Browser b, bool impersonateHeaders)
	{
		auto c = curl_easy_impersonate(_handle, b.to!string.toStringz, impersonateHeaders);
		checkError(null, c, `impersonate`);
	}

	void buffers(uint sz)
	{
		option(CURLOPT_BUFFERSIZE, sz);
		option(CURLOPT_UPLOAD_BUFFERSIZE, sz);
	}

	void userAgent(string ua) => option(CURLOPT_USERAGENT, ua);

	void etag(string etag) => header(Header.ifMatch, etag);

	void header(string header, string value)
	{
		auto p = format!`%s: %s`(header, value);

		_headers = curl_slist_append(_headers, p.toStringz);
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

	void version_(Alpn v) => option(CURLOPT_HTTP_VERSION, v);

	void range(ulong start, ulong end) => option(CURLOPT_RANGE, format!`%u-%u`(start, end));

	void noBody() => option(CURLOPT_NOBODY, 1);

	void method(string m) => option(CURLOPT_CUSTOMREQUEST, m);

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
			checkError(null, c, `resume`);
		}

		_paused = false;
	}

	uint delegate(Job, ubyte[] data) onRead;
	uint delegate(Job, ubyte[] data) onWrite;

	void delegate(Job) onHeaders;
	void delegate(Job) onComplete;

	SubLogger logger;
package:
	this(string url, SubLogger parent)
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

		logger = new SubLogger(parent, format!`%x`(this.toVoid));
		logger.info!`created: %s`(url);

		_meter = AppTimeMeter.init;
	}

	void complete(CURLcode c)
	{
		if (_aborted)
		{
			_hasError = true;
		}
		else if (c != CURLE_OK)
		{
			_hasError = true;
			checkError(logger, c, `job`);
		}

		if (_hasError)
		{
			logger.warn!`failed, elapsed %s`(_meter.elapsed);
		}
		else
			logger.info2!`completed, elapsed %s`(_meter.elapsed);

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
		gcNoMove(this, false);

		curl_easy_cleanup(_handle);
		curl_slist_free_all(_headers);
	}

	void abort(string reason)
	{
		_aborted = true;
		logger.info2!`aborted by %s`(reason);
	}

	static fromHandle(CURL* handle)
	{
		Job job;
		optget(handle, CURLINFO_PRIVATE, job);
		return job;
	}

	@property handle() => _handle;
private:
	AppTimeMeter _meter;

	curl_slist* _headers;
}
