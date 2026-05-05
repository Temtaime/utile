import std, utile.net, utile.curl, utile.web;

enum PORT = 23_769;

final class Client : WebClient
{
	this(void* conn, string url, string method) nothrow
	{
		super(conn, url, method);

		assert(url == `/hehe`);
		assert(method == `GET`);
	}

	override void onCreate()
	{
	}

	override void onResponse()
	{
		send(200, `hello world`);
	}

	override void onComplete()
	{
	}
}

unittest
{
	scope r = new Requests;
	scope web = new WebServer(PORT, 10.seconds);

	web.createClient = (conn, url, method) => new Client(conn, url, method);

	auto j = r.makeJob(format!`http://127.0.0.1:%u/hehe`(PORT));

	for (scope ts = new ThreeSet; j.done == false;)
	{
		ts.reset;

		r.fdset(ts);
		web.fdset(ts);

		ts.select(1.seconds);

		r.run;
		web.run(ts);
	}

	assert(j.isError == false);
	assert(j.code == 200);
	assert(j.data == `hello world`);
}
