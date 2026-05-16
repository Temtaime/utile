module utile.updater.verify;

import std.datetime, std.process, std.stdio;
import utile, utile.curl, utile.net.headers, utile.updater.helpers;

import utile.updater;

package:

enum State
{
	ok,
	updated,
	error
}

class VerifyUpdater : UpdaterBase
{
	this(string url, Requests req)
	{
		_url = url;
		_req = req;
		_helpers = new UpdaterHelpers;

		_func = TimerFunc(Duration.init, &createRequest);
	}

	override bool onStart()
	{
		logger.info!`verifying update ...`;
		loop;

		if (_state == State.ok)
		{
			stderr.write(UPDATED_TOKEN);
		}
		else
		{
			logger.fatal!`cannot check if current version is up to date`;
		}

		return true;
	}

	override void check()
	{
		assert(false);
	}

protected:
	void onRequest(Job j) => j.noBody;
	Duration checkDelay() nothrow => RETRY_DELAY;

	void doUpdate(Blob, SysTime)
	{
		assert(false);
	}

final:
	void loop() => timerLoop(&loopImpl);

	State _state = State.error;

	TimerFunc _func;
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
				_done = true; // give up
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

		_done = true;
	}

	bool loopImpl()
	{
		_func.check;

		_req.wait;
		_req.run;

		return _done;
	}

	string _url;
	Requests _req;

	bool _done;
	ubyte _retries;
}
