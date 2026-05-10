module utile.mem;

import std, core.memory;

private enum Pred(T) = is(T == class) || isPointer!T;

void* toVoid(T)(T ptr) if (Pred!T)
{
	return cast(void*)ptr;
}

void gcNoMove(T)(T ptr, bool value) if (Pred!T)
{
	if (value)
	{
		GC.setAttr(ptr.toVoid, GC.BlkAttr.NO_MOVE);
	}
	else
		GC.clrAttr(ptr.toVoid, GC.BlkAttr.NO_MOVE);
}

void gcMark(T)(T ptr, bool value) if (Pred!T)
{
	if (value)
	{
		GC.addRoot(ptr.toVoid);
	}
	else
		GC.removeRoot(ptr.toVoid);
}

void gcRetain(T)(T ptr, bool value) if (Pred!T)
{
	gcMark(ptr, value);
	gcNoMove(ptr, value);
}
