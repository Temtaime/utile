module utile.updater.net;

import std.datetime, std.process, std.stdio;
import utile, utile.curl, utile.net.headers, utile.updater.helpers;

import utile.updater;

package:

enum State
{
	none,
	ok,
	updated,
	error
}

abstract class NetUpdater : UpdaterBase
{
	this(string url, Requests req)
	{
		_url = url;
		_req = req;
		_helpers = new UpdaterHelpers;

		_func = TimerFunc(Duration.init, &createRequest);
	}

	override void check() => _func.check;

protected:
	Duration checkDelay() nothrow;

	void onRequest(Job);
	void doUpdate(Blob, SysTime);

final:
	void loop() => timerLoop(&loopImpl);
	State state() const @property => _state;

	UpdaterHelpers _helpers;
private:
	static srTime(Job j)
	{
		if (auto p = HeaderNormalized.lastModified in j.responseHeaders)
		{
			return parseHttpDate(*p);
		}

		throwError!`missing %s header in response`(Header.lastModified);
	}

	void createRequest()
	{
		auto e = _req.create(_url);

		e.header(Header.ifModifiedSince, _helpers.dateModified.toHttpDate);
		e.onComplete = &onResponse;

		onRequest(e);
	}

	void onResponse(Job e)
	{
		auto delay = RETRY_DELAY;

		scope (exit)
		{
			_func = TimerFunc(delay, &createRequest);
		}

		if (e.hasError)
		{
			if (_retries >= RETRY_COUNT)
			{
				_state = State.error; // give up
			}
			else
				_retries++;

			return;
		}

		try
		{
			auto date = srTime(e);
			auto data = e.code == 304 ? null : e.data;

			if (date == _helpers.dateModified)
			{
				_state = State.ok;
			}
			else
			{
				doUpdate(data, date);
				_state = State.updated;
			}

			delay = checkDelay;
		}
		catch (Exception ex)
		{
			logger.error(ex.msg);
		}
	}

	bool loopImpl()
	{
		_func.check;

		_req.wait;
		_req.run;

		return _state != State.none;
	}

	string _url;
	Requests _req;

	TimerFunc _func;

	State _state;
	ubyte _retries;
}
