module utile.curl.requests;

import std, core.atomic, core.sync.event, core.sync.mutex, core.thread, core.time, core.memory, utile;

import utile.curl, utile_curl;
import std : min, max;

import utile.net : Selector;

version (Windows)
{
	import core.sys.windows.winsock2 : fd_set;
}
else
{
	import core.sys.posix.sys.select : fd_set;
}

final class Requests
{
	this()
	{
		_m = curl_multi_init();
		curl_multi_setopt(_m, CURLMOPT_MAX_TOTAL_CONNECTIONS, ulong(MAX_CONNECTIONS));
	}

	~this()
	{
		foreach (job; _jobs)
		{
			curl_multi_remove_handle(_m, job.handle);
			job.cleanup;
		}

		curl_multi_cleanup(_m);
	}

	auto makeJob(string url)
	{
		auto job = new Job(url);

		_jobs ~= job;
		curl_multi_add_handle(_m, job.handle);

		return job;
	}

	void fdset(ref Selector s)
	{
		alias F = utile_curl.fd_set;

		int maxfd;

		{
			auto mc = curl_multi_fdset(_m, s.asPtr!F.expand, &maxfd);
			checkErrorM(false, mc, `fdset`);
		}

		s.add(maxfd);
	}

	void run()
	{
		int running;

		{
			auto mc = curl_multi_perform(_m, &running);
			checkErrorM(true, mc, `perform`);
		}

		while (true)
		{
			int queue;
			auto m = curl_multi_info_read(_m, &queue);

			if (m is null)
				break;

			if (m.msg != CURLMSG_DONE)
				continue;

			auto e = Job.fromHandle(m.easy_handle);

			if (!e.aborted)
			{
				checkError(false, m.data.result, `job`);
			}

			removeJob(e);
		}
	}

	void abort(Job j)
	{
		logger.info2!`curl job was forced to abort`;

		with (j)
		{
			_aborted = true;
			removeJob(j);
		}
	}

	enum MAX_CONNECTIONS = 32;
private:
	void removeJob(Job job)
	{
		with (job)
		{
			curl_multi_remove_handle(_m, handle);

			complete;
			cleanup;
		}

		auto idx = _jobs.countUntil!(a => a is job);
		_jobs.removeUnstable(idx);
	}

	CURLM* _m;
	Job[] _jobs;
}
