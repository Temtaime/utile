Follow these rules:

1. Prefix private struct/class variables with `_`.
2. Prefer compact error checks:

```d
foo() || throwError!`foo failed, format string = %u`(123);

auto code = foo();
code && throwError!`foo failed, error is %d`(code);
```

Include relevant context when useful; otherwise use a short error message.

3. Use logger methods instead of `writeln`:

```d
logger.info!`format string %u`(123);
```

Use `info2`, `info3`, `dbg`, `warn`, `error`, or `fatal` when appropriate.

4. Use backtick string literals. Use double-quoted literals only when escape sequences are required.
5. Omit `()` when calling zero-argument functions.
6. Use English only in source files.
7. Logging and exception messages must:
   * start with lowercase;
   * preserve ALL-CAPS abbreviations of at least two characters, such as `IP`, `MTU`, `HTTP`, and `TLS`;
   * not end with a period;
   * use ` ...` to indicate a long-running process.
8. Do not add parentheses around `&&` and `||` expressions solely for precedence; `&&` has higher precedence.
9. Do not run the build unless explicitly requested.
