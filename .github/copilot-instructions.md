1. use prefix _ for private struct/class variables
2. for error checking prefer following construction:

foo() || throwError!`foo failed, format string = %u`(123)
or
auto code = foo();
code && throwError!`foo failed, error is %d`(code)

this is only an example, use whatever is suitable(can be foo args or anything that matters in the context) or just a short error message
3. use logger.info!`format string %u`(123) for logs instead of writeln
also use dbg/msg/info2/info3/warn/error/fatal when applicable
4. write string literals in `` instead of "", use "" only when the string contains escape sequences
5. do not use () when calling functions with zero args
6. use only the english language in the source files
7. when you write a string literal for logging/exception:
always use lowercase, unless a token is an abbreviation: keep any ALL-CAPS token of length >= 2 unchanged (e.g. IP, MTU, HTTP, TLS), do not change the casing of such tokens
do not put the dot in the end (yet you can put three dots like "msg ..."(note the space) to indicate a long process)
8. boolean operators && and || ARE NOT ambiguous(&& has higher precedence), so do not use parentheses for them
9. do not run the build unless explicitly requested
