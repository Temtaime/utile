import core.stdc.stdio, utile, utile.console, utile.log.base;

unittest
{
	static foreach (name; COLOR_NAMES)
	{
		logger.log(mixin(`Fg.` ~ name), "this is fg color " ~ name);
	}

	static foreach (name; COLOR_NAMES)
	{
		logger.log(mixin(`Bg.` ~ name), "this is bg color " ~ name);
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
