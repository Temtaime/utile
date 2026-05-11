module utile.container;

struct HashSet(T)
{
	auto values() @property => _aa.keys;
	auto byValue() @property => _aa.byKey;

	void add(T value)
	{
		_aa[value] = Elem.init;
	}

	bool remove(T value) => _aa.remove(value);
	void clear() => _aa.clear;

	int opApply(scope int delegate(T) dg)
	{
		foreach (v; byValue)
		{
			if (int res = dg(v))
			{
				return res;
			}
		}

		return 0;
	}

private:
	alias Elem = void[0];

	Elem[T] _aa;
}
