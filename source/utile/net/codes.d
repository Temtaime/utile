module utile.net.codes;

enum Code : ushort
{
	// 1xx informational
	continue_ = 100,
	switchingProtocols = 101,
	processing = 102,
	earlyHints = 103,

	// 2xx success
	ok = 200,
	created = 201,
	accepted = 202,
	nonAuthoritativeInformation = 203,
	noContent = 204,
	resetContent = 205,
	partialContent = 206,
	multiStatus = 207,
	alreadyReported = 208,
	imUsed = 226,

	// 3xx redirection
	multipleChoices = 300,
	movedPermanently = 301,
	found = 302,
	seeOther = 303,
	notModified = 304,
	useProxy = 305,
	switchProxy = 306,
	temporaryRedirect = 307,
	permanentRedirect = 308,

	// 4xx client error
	badRequest = 400,
	unauthorized = 401,
	paymentRequired = 402,
	forbidden = 403,
	notFound = 404,
	methodNotAllowed = 405,
	notAcceptable = 406,
	proxyAuthenticationRequired = 407,
	requestTimeout = 408,
	conflict = 409,
	gone = 410,
	lengthRequired = 411,
	preconditionFailed = 412,
	contentTooLarge = 413,
	uriTooLong = 414,
	unsupportedMediaType = 415,
	rangeNotSatisfiable = 416,
	expectationFailed = 417,
	imATeapot = 418,
	misdirectedRequest = 421,
	unprocessableContent = 422,
	locked = 423,
	failedDependency = 424,
	tooEarly = 425,
	upgradeRequired = 426,
	preconditionRequired = 428,
	tooManyRequests = 429,
	requestHeaderFieldsTooLarge = 431,
	unavailableForLegalReasons = 451,

	// 5xx server error
	internalServerError = 500,
	notImplemented = 501,
	badGateway = 502,
	serviceUnavailable = 503,
	gatewayTimeout = 504,
	httpVersionNotSupported = 505,
	variantAlsoNegotiates = 506,
	insufficientStorage = 507,
	loopDetected = 508,
	notExtended = 510,
	networkAuthenticationRequired = 511,

	// Non-standard: IIS
	loginTimeout = 440,
	retryWith = 449,
	blockedByWindowsParentalControls = 450,
	iisRedirect = 451,

	// Non-standard: nginx
	noResponse = 444,
	nginxRequestHeaderTooLarge = 494,
	sslCertificateError = 495,
	sslCertificateRequired = 496,
	httpRequestSentToHttpsPort = 497,
	clientClosedRequest = 499,

	// Non-standard: Cloudflare
	webServerReturnedUnknownError = 520,
	webServerIsDown = 521,
	connectionTimedOut = 522,
	originIsUnreachable = 523,
	timeoutOccurred = 524,
	sslHandshakeFailed = 525,
	invalidSslCertificate = 526,
	railgunError = 527,
	originUnavailable = 530,

	// Non-standard: AWS Elastic Load Balancing
	awsHeaderTooLarge = 0,
	awsClientClosedConnection = 460,
	awsTooManyForwardedForIps = 463,
	awsIncompatibleProtocolVersions = 464,
	awsUnauthorized = 561,

	// Non-standard: Apache / Laravel / Spring / Twitter
	bandwidthLimitExceeded = 509,
	pageExpired = 419,
	methodFailure = 420,
	enhanceYourCalm = 420,

	// Non-standard: Shopify
	shopifyRequestHeaderFieldsTooLarge = 430,
	shopifySecurityRejection = 430,
	originDnsError = 530,
	temporarilyDisabled = 540,
	unexpectedToken = 783,

	// Non-standard: ArcGIS
	invalidToken = 498,
	tokenRequired = 499,

	// Non-standard: cPanel / SSL Labs / Pantheon / LinkedIn / Misc
	resourceLimitIsReached = 508,
	siteIsOverloaded = 529,
	siteIsFrozen = 530,
	requestDenied = 999,
	thisIsFine = 218,
	networkReadTimeoutError = 598,
	networkConnectTimeoutError = 599
}
