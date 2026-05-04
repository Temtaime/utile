module utile.mem;

import std, core.memory;

void* toVoid(T)(T ptr) if (is(T == class) || isPointer!T)
{
	return cast(void*)ptr;
}

void gcNoMove(T)(T ptr, bool value) if (is(T == class) || isPointer!T)
{
	if (value)
		GC.setAttr(ptr.toVoid, GC.BlkAttr.NO_MOVE);
	else
		GC.clrAttr(ptr.toVoid, GC.BlkAttr.NO_MOVE);
}

void gcMark(T)(T ptr, bool value) if (is(T == class) || isPointer!T)
{
	if (value)
		GC.addRoot(ptr.toVoid);
	else
		GC.removeRoot(ptr.toVoid);
}
