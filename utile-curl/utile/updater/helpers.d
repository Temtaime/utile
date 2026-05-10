module utile.updater.helpers;

import std;

enum OLD_SUFFIX = `.old`;
enum TMP_SUFFIX = `.tmp`;

import core.thread, core.sys.posix.sys.stat, utile.time;

package:

class UpdaterHelpers
{
	void cleanup()
	{
		while (exists(old))
		{
			collectException(old.remove);
			Thread.sleep(100.msecs);
		}
	}

	bool isNewVersion(SysTime srTime) => srTime != exe.timeLastModified;

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
			rename(exe, old);
		}

		rename(tmp, exe);
	}

	@property tmp() => exe ~ TMP_SUFFIX;
private:
	@property exe() => thisExePath;
	@property old() => exe ~ OLD_SUFFIX;
}
