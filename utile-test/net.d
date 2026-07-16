import std, utile.log, utile.net, utile.curl, utile.web, utile.time.app, utile.net.headers;

enum PORT = 23_769;

final class Handler : WebHandler
{
	this(WebConnection conn)
	{
		super(conn);

		assert(conn.url == `/hehe`);
		assert(conn.method == `GET`);
		assert(conn.addr.toAddrString == `1.1.1.1`);

		assert(conn.query[`foo`] == `bar`);
		assert(conn.cookies[`cookie`] == `chocolate`);

		conn.logger.info!`handler created: %s`(conn.url);
	}

	~this()
	{
		conn.logger.info!`handler completed: %s`(conn.url);
	}

	override void onResponse()
	{
		conn.send(200, `hello world`);

		conn.logger.info!`handler responded: %s`(conn.url);
	}
}

unittest
{
	scope req = new Requests(logger);
	scope web = new WebServer(PORT, 10.seconds, logger);

	web.setClientIP(HeaderNormalized.xForwardedFor);

	web.routes[`/hehe`][`GET`] = (conn) => new Handler(conn);

	auto e = req.create(format!`http://127.0.0.1:%u/hehe?foo=bar`(PORT));

	auto aa = [`cookie`: `chocolate`];
	e.cookies(aa);
	e.header(`X-Forwarded-For`, `1.1.1.1`);

	for (scope ts = new ThreeSet; !e.done; appTime.update)
	{
		ts.reset;

		req.fdset(ts);
		web.fdset(ts);

		ts.select(100.msecs);

		req.run;
		web.run(ts);
	}

	assert(!e.hasError);
	assert(e.code == 200);
	assert(e.data == `hello world`);
}

unittest
{
	scope req = new Requests(logger);

	auto e = req.create(`https://httpbin.org/get`);

	while (!e.done)
	{
		req.wait;
		req.run;
	}

	assert(!e.hasError);
	assert(e.code == 200);
	assert(!e.data.empty);
}
