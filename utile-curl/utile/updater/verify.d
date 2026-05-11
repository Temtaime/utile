module utile.updater.verify;

import std.datetime, std.process, std.stdio;
import utile, utile.curl, utile.updater.helpers;

import utile.updater;

package:

class VerifyUpdater : UpdaterBase
{
	this(string url, Requests req)
	{
		_url = url;
		_req = req;
		_helpers = new UpdaterHelpers;

		_func = TimerFunc(Duration.init, &onRequest);
	}

	override bool onStart()
	{
		logger.info!`verifying update ...`;

		loop;

		if (_hasUpdate)
		{
			logger.error!`newer version found during verify`;
		}
		else
		{
			stderr.write(UPDATED_TOKEN);
		}

		return true;
	}

	override void check()
	{
		assert(false);
	}

protected:
	void onCheck()
	{
		_done = true;
	}

final:
	static srTime(Job j)
	{
		if (auto p = HeaderNormalized.lastModified in j.responseHeaders)
		{
			return parseHTTPDate(*p);
		}

		throwError!`missing %s header in response`(Header.lastModified);
	}

	void loop()
	{
		for (; !_done; appTime.update)
		{
			_func.check;

			_req.run;
			_req.wait;
		}
	}

	nothrow
	{
		void wrap(void delegate(Job) dg, Job j)
		{
			if (j.hasError)
			{
				logger.error!`request failed with code %u`(j.code);
			}
			else
				try
				{
					return dg(j);
				}
				catch (Exception ex)
				{
					logger.error(ex.msg);
				}

			reset;
		}

		void reset(Duration delay = RETRY_DELAY)
		{
			_func = TimerFunc(delay, &onRequest);
		}
	}

	auto createJob() => _req.create(_url);

	bool _done;
	bool _hasUpdate;

	TimerFunc _func;
	UpdaterHelpers _helpers;
private:
	void onRequest()
	{
		auto j = createJob;

		j.noBody;
		j.onComplete = a => wrap(&onHeaders, a);
	}

	void onHeaders(Job j)
	{
		_hasUpdate = _helpers.isNewVersion(srTime(j));
		onCheck;
	}

	string _url;
	Requests _req;
}
