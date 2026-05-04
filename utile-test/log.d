import core.stdc.stdio, utile, utile.console, utile.log.base;

unittest
{
	foreach (ushort i, name; COLOR_NAMES)
	{
		logger.log(i, "this is fg color " ~ name);
	}

	foreach (ushort i, name; COLOR_NAMES)
	{
		logger.log(cast(ushort)(i << COLOR_BITS), "this is fg color " ~ name);
	}
}

unittest
{
	logger.timeOutput = true;

	logger.msg(`hello, world`);
	logger.info2!`%s, %s`(`hello`, `world`);
}

unittest
{
	auto child = logger.makeChild(`a`);
	child.info(`message from child`);

	auto grandchild = child.makeChild(`b`);
	grandchild.info(`message from grandchild`);

	logger.info(`message from root`);
}
