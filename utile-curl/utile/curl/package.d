module utile.curl;
import std, core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile;

import utile_curl;

public import utile.curl.job;
public import utile.curl.browsers;
public import utile.curl.requests;

shared static this()
{
	auto c = curl_global_init(CURL_GLOBAL_ALL);

	checkError(true, c, `global init`);
}

enum Alpn
{
	any = CURL_HTTP_VERSION_NONE,

	v1_only = CURL_HTTP_VERSION_1_0,
	v1_1_only = CURL_HTTP_VERSION_1_1,

	v2 = CURL_HTTP_VERSION_2_0,
	v2_only = CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE,

	v3 = CURL_HTTP_VERSION_3,
	v3_only = CURL_HTTP_VERSION_3ONLY
}

enum Method
{
	get = `GET`,
	post = `POST`,
	put = `PUT`,
	delete_ = `DELETE`,
	head = `HEAD`
}

enum Read
{
	abort = CURL_READFUNC_ABORT,
	pause = CURL_READFUNC_PAUSE
}

enum Write
{
	abort = CURL_WRITEFUNC_ERROR,
	pause = CURL_WRITEFUNC_PAUSE
}

package:

enum CONNECTION_IDLE_ABORT_TIME = 60.seconds;

void checkError(bool doThrow, CURLcode code, string msg)
{
	if (code == CURLE_OK)
		return;

	enum F = `easy %s failed, error %d - %s`;
	auto error = curl_easy_strerror(code).fromStringz;

	if (doThrow)
	{
		throwError!F(msg, code, error);
	}
	else
		logger.error!F(msg, code, error);
}

void checkErrorM(bool doThrow, CURLMcode code, string msg)
{
	if (code == CURLM_OK)
		return;

	enum F = `multi %s failed, error %d - %s`;
	auto error = curl_multi_strerror(code).fromStringz;

	if (doThrow)
	{
		throwError!F(msg, code, error);
	}
	else
		logger.error!F(msg, code, error);
}
