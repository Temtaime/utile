module utile.updater.helpers;

import std, utile, utile.updater;

enum OLD_SUFFIX = `.old`;
enum TMP_SUFFIX = `.tmp`;

import core.thread, core.sys.posix.sys.stat, utile.time;

package:

final class UpdaterHelpers
{
	this()
	{
		_exe = thisExePath;
		_dateModified = _exe.timeLastModified;
	}

	void cleanup()
	{
		while (exists(old))
		{
			collectException(old.remove);
			Thread.sleep(100.msecs);
		}
	}

	void unpack(in ubyte[] data, SysTime srTime)
	{
		data.toFile(tmp);
		tmp.setTimes(srTime, srTime);

		version (Posix)
		{
			stat_t e;

			stat(exe.toStringz, &e);
			chmod(tmp.toStringz, e.st_mode);
		}
	}

	void apply()
	{
		version (Windows)
		{
			rename(_exe, old);
		}

		rename(tmp, _exe);
	}

	bool verify(SubLogger logger)
	{
		auto inp = File.tmpfile;
		auto output = File.tmpfile;
		auto error = File.tmpfile;

		auto pid = spawnProcess(
			tmp,
			inp,
			output,
			error,
			[VERIFY_ENV: null],
			Config.retainStdout | Config.retainStderr | Config.suppressConsole
		);

		int code = pid.wait;

		if (code || error.asTxt != UPDATED_TOKEN)
		{
			logger.error!"verification failed with code %d:\n%s"(code, output.asTxt);
			return false;
		}

		return true;
	}

private:
	mixin publicProperty!(SysTime, `dateModified`);

	@property tmp() => _exe ~ TMP_SUFFIX;
	@property old() => _exe ~ OLD_SUFFIX;

	string _exe;
}
