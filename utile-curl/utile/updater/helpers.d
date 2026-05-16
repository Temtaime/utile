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

		version (Posix)
		{
			stat(_exe.toStringz, &_st);
		}
	}

	void cleanup()
	{
		while (old.exists)
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
			chmod(tmp.toStringz, _st.st_mode);
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

	void verify(SubLogger logger)
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
			logger.error!"process exited with code %d:\n%s"(code, output.asTxt);

			throwError!`verification failed`;
		}
		else
			logger.info2!`update verified successfully`;
	}

private:
	mixin publicProperty!(SysTime, `dateModified`);

	@property tmp() => _exe ~ TMP_SUFFIX;
	@property old() => _exe ~ OLD_SUFFIX;

	version (Posix)
	{
		stat_t _st;
	}

	string _exe;
}
