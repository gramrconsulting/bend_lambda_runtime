# bend_lambda_runtime

An AWS Lambda custom runtime written in Bend 2. A function is a Bend handler
`String -> IO(String)`: the event's JSON text in, the reply text out.

```python
import Base
import ../bend_lambda_runtime/runtime.bend as Lambda

def echo(event: String) -> IO(String):
  IO.pure(String, "{\"echo\":" ++ event ++ "}")

def main() -> IO(Unit):
  Lambda.run(~echo)
```

## Build

```bash
./build.sh echo.bend build/aarch64    # bootstrap + function.zip, static aarch64
```

Deploy `function.zip` as runtime `provided.al2023`, architecture `arm64`.
Needs `bend` 2.0.40 and `zig` (the cross-compiler). A function with foreign
effects passes their object files after the target.

## Check

```bash
./check.sh    # laws, then echo against a fake Runtime API, native and under qemu-aarch64
```

## Limits

- A multi-byte character split across two TCP reads of an event may be mangled.
- A handler cannot report an error to Lambda: it answers text, whatever happens.
- The loop serves 1,000,000 invocations, then exits and Lambda restarts it.
