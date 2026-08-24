module utile.curl.requests;

import core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile, utile.net;

import std.string;

import utile.curl, utile_curl;

final class Requests
{
	this(Logger parent)
	{
		_m = curl_multi_init();

		logger = new SubLogger(parent, `requests`);
	}

	~this()
	{
		foreach (j; _jobs)
		{
			curl_multi_remove_handle(_m, j.handle);
			j.cleanup;
		}

		curl_multi_cleanup(_m);
	}

	void maxTotalConnections(uint c)
	{
		option(CURLMOPT_MAX_TOTAL_CONNECTIONS, c);
	}

	void maxConcurrentStreams(uint c)
	{
		option(CURLMOPT_MAX_CONCURRENT_STREAMS, c);
	}

	auto create(string url)
	{
		auto j = new Job(url, logger);

		if (onNewJob)
		{
			onNewJob(j);
		}

		_jobs.add(j);
		curl_multi_add_handle(_m, j.handle);

		return j;
	}

	void fdset(ThreeSet ts)
	{
		alias F = utile_curl.fd_set;

		int fd;

		{
			auto mc = curl_multi_fdset(_m, ts.rp!F, ts.wp!F, ts.ep!F, &fd);
			checkErrorM(false, mc, `fdset`);
		}

		ts.maxFd = fd;
	}

	void wait(Duration timeout = 1.seconds)
	{
		auto mc = curl_multi_poll(_m, null, 0, timeout.toMsecs, null);
		checkErrorM(false, mc, `wait`);
	}

	bool run()
	{
		int running;

		{
			auto mc = curl_multi_perform(_m, &running);
			checkErrorM(true, mc, `perform`);
		}

		bool res;

		while (true)
		{
			int queue;
			auto m = curl_multi_info_read(_m, &queue);

			if (m is null)
				break;

			if (m.msg != CURLMSG_DONE)
				continue;

			res = true;

			auto e = Job.fromHandle(m.easy_handle);
			removeJob(e, m.data.result);
		}

		return res;
	}

	void wakeup() nothrow @nogc
	{
		curl_multi_wakeup(_m);
	}

	void abort(Job j)
	{
		with (j)
		{
			abort(`user request`);
			removeJob(j, CURLE_OK);
		}
	}

	SubLogger logger;
	void delegate(Job) onNewJob;
private:
	void option(CURLMoption opt, long value)
	{
		auto res = curl_multi_setopt(_m, opt, value);
		checkErrorM(true, res, `option`);
	}

	void removeJob(Job job, CURLcode c)
	{
		with (job)
		{
			curl_multi_remove_handle(_m, handle);

			complete(c);
			cleanup;
		}

		_jobs.remove(job);
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

	CURLM* _m;
	HashSet!Job _jobs;
}
