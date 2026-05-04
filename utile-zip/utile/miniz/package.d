module utile.miniz;
import std, utile.except, utile_miniz;

final class Zip
{
	enum
	{
		ro,
		rw,
		create
	}

	this(string name, typeof(ro) flags)
	{
		auto s = name.toStringz;

		if (flags == create)
		{
			mz_zip_writer_init_file_v2(
				&_zip,
				name.toStringz,
				0,
				MZ_ZIP_FLAG_WRITE_ZIP64 | MZ_ZIP_FLAG_WRITE_ALLOW_READING
			);
		}
		else
		{
			name.exists || throwError(`archive does not exist`);

			mz_zip_reader_init_file(&_zip, s, 0);

			if (flags == rw)
			{
				mz_zip_writer_init_from_reader(&_zip, s);
			}
			else
				_ro = true;
		}
	}

	~this()
	{
		if (_ro)
		{
			mz_zip_reader_end(&_zip);
		}
		else
		{
			mz_zip_writer_finalize_archive(&_zip);
			mz_zip_writer_end(&_zip);
		}
	}

	ubyte[] get(string name)
	{
		auto idx = mz_zip_reader_locate_file(&_zip, name.toStringz, null, 0);
		idx >= 0 || throwError(lastError);

		mz_zip_archive_file_stat stat;
		mz_zip_reader_file_stat(&_zip, idx, &stat) || throwError(lastError);

		auto res = new ubyte[cast(size_t)stat.m_uncomp_size];

		mz_zip_reader_extract_to_mem(&_zip, idx, res.ptr, res.length, 0) || throwError(lastError);
		return res;
	}

	void put(string name, in void[] data)
	{
		mz_zip_writer_add_mem(&_zip, name.toStringz, data.ptr, data.length, 0);
	}

private:
	string lastError()
	{
		return mz_zip_get_last_error(&_zip)
			.mz_zip_get_error_string
			.fromStringz
			.assumeUnique;
	}

	bool _ro;
	mz_zip_archive _zip;
}
