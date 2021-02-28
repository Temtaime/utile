module utile.misc;
import std.traits;

mixin template publicProperty(T, string Name, string Value = null)
{
	mixin(`
		public ref ` ~ Name ~ `() @property const { return _` ~ Name ~ `; }
		T _` ~ Name ~ (Value.length
			? `=` ~ Value : null) ~ `;`);
}

auto as(T, E)(E data) if (isDynamicArray!E)
{
	return cast(T[])data;
}

auto as(T, E)(ref E data) if (!isDynamicArray!E)
{
	return cast(T[])(&data)[0 .. 1];
}

auto toByte(T)(auto ref T data)
{
	return data.as!ubyte;
}