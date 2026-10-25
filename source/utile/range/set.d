module utile.range.set;

import std, utile.binary, utile.range.data;

struct RangeSet
{
	//alias Pred = (a, b) => a.start < b.start; // https://github.com/dlang/dmd/issues/21474
	enum Pred = `a.start < b.start`;

	bool opBinaryRight(string op : `in`)(DataRange n) const
	{
		auto r = ranges
			.assumeSorted!Pred
			.upperBound(n)
			.release;

		r = ranges[0 .. $ - r.length];

		return r.length && r[$ - 1].start <= n.start && r[$ - 1].end >= n.end;
	}

	void opOpAssign(string op)(RangeSet rs) => cast(void)rs.ranges.each!(a => this.opOpAssign!op(a));

	void opOpAssign(string op : `+`)(DataRange n)
	{
		auto r = ranges
			.assumeSorted!Pred
			.lowerBound(n)
			.release;

		auto k = r.length;

		if (k && r[k - 1].end >= n.start)
		{
			--k;
			r[k].end = max(r[k].end, n.end);
		}
		else
		{
			ranges.insertInPlace(k, n);
		}

		auto cur = &ranges[k++];

		while (k < ranges.length && ranges[k].start <= cur.end)
		{
			cur.end = max(cur.end, ranges[k].end);
			ranges = ranges.remove(k);
		}
	}

	void opOpAssign(string op : `-`)(DataRange n)
	{
		auto r = ranges
			.assumeSorted!Pred
			.lowerBound(n)
			.release;

		auto k = r.length;

		if (k)
		{
			auto c = &r[k - 1];
			auto e = c.end;

			if (e > n.start)
			{
				c.end = n.start;

				if (e > n.end)
				{
					ranges.insertInPlace(k, DataRange(n.end, e));
					return;
				}
			}
		}

		while (k < ranges.length && ranges[k].start < n.end)
		{
			if (ranges[k].end > n.end)
			{
				ranges[k].start = n.end;
				break;
			}
			else
			{
				ranges = ranges.remove(k);
			}
		}
	}

	bool hasIntersections(DataRange n) const
	{
		auto k = ranges
			.assumeSorted!Pred
			.lowerBound(n)
			.length;

		if (k && ranges[k - 1].end > n.start)
		{
			return true;
		}

		auto r = ranges[k .. $];

		foreach (e; r)
		{
			if (e.start >= n.end)
			{
				break;
			}

			return true;
		}

		return false;
	}

	auto holes(DataRange n) const
	{
		static struct S
		{
			void popFront()
			{
				assert(!empty);
				fetch;
			}

			@property front() const => _res;
			@property empty() const => _res.start == _res.end;
		private:
			this(const(DataRange)[] ranges, DataRange n)
			{
				auto k = ranges
					.assumeSorted!Pred
					.lowerBound(n)
					.length;

				if (k && ranges[k - 1].end > n.start)
				{
					if (ranges[k - 1].end >= n.end)
					{
						return;
					}

					n.start = ranges[k - 1].end;
				}

				_n = n;
				_ranges = ranges[k .. $];

				fetch;
			}

			void fetch()
			{
				while (_ranges.length)
				{
					auto r = _ranges[0];
					_ranges.popFront;

					if (r.start >= _n.end)
					{
						break;
					}

					scope (exit)
					{
						_n.start = min(r.end, _n.end);
					}

					if (r.start != _n.start)
					{
						_res = DataRange(_n.start, r.start);
						return;
					}
				}

				_res = _n;
				_n.start = _n.end;
			}

			DataRange _n;
			DataRange _res;

			const(DataRange)[] _ranges;
		}

		return S(ranges, n);
	}

	auto dup() const => RangeSet(ranges.dup);

	@(ArrayLength!uint) DataRange[] ranges; // assume ranges are sorted and non-overlapping
}
