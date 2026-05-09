module utile.updater;

import std.datetime, utile, utile.curl, utile.updater.helpers;

enum RETRY_DELAY = 30.seconds;

final class Updater
{
	this(string url, Requests req, void delegate() onUpdate, Duration delay, Logger parent)
	{
		_url = url;
		_req = req;

		_delay = delay;
		_onUpdate = onUpdate;

		_helpers = new UpdaterHelpers;
		_func = TimerFunc(Duration.init, &onRequest); // run it immediately

		logger = new SubLogger(parent, `updater`);
	}

	void forceCheck()
	{
		logger.info!`forced update check ...`;

		// mark update as outdated to trigger update check
		_outdated = true;

		if (_func.isActive) // timer is active, so we are waiting for the next check, run it immediately
		{
			reset(Duration.init);
		}
		else
		{
			// if timer is not active, then there is already an update check in progress
			// so we just need to wait for it to complete
		}

		for (; _outdated; appTime.update)
		{
			_func.check;

			_req.run;
			_req.wait;
		}
	}

	void check() => _func.check;

	SubLogger logger;
private:
	void reset(Duration delay)
	{
		_func = TimerFunc(delay, &onRequest);
	}

	bool failed(Job j)
	{
		if (j.isError)
		{
			logger.error!`request failed with code %u`(j.code);

			reset(RETRY_DELAY);
			return true;
		}

		return false;
	}

	void onRequest()
	{
		auto job = _req.makeJob(_url);

		job.method = Method.head;
		job.onComplete = &onReceiveHeaders;

		logger.info!`checking for updates ...`;
	}

	void onReceiveHeaders(Job job)
	{
		if (failed(job))
		{
			return;
		}

		auto time = job
			.responseHeaders[`last-modified`]
			.parseHTTPDate;

		if (_helpers.isNewer(time))
		{
			logger.info3!`update is available, downloading ...`;

			job = _req.makeJob(_url);
			job.onComplete = &onReceiveData;

			return;
		}

		reset(_delay);
		_outdated = false;

		logger.msg!`no update is available`;
	}

	void onReceiveData(Job job)
	{
		if (failed(job))
		{
			return;
		}

		logger.warn!`update downloaded, processing ...`;

		_helpers.onUpdateData(job.data);
		_onUpdate();

		_outdated = false;
	}

	TimerFunc _func;
	UpdaterHelpers _helpers;

	const
	{
		string _url;
		Duration _delay;
	}

	Requests _req;

	bool _outdated;
	void delegate() _onUpdate;
}
