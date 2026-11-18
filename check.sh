#!/usr/bin/env bash
# Ready check: laws hold and the echo example answers a fake Runtime API.
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build

bend http_test.bend | grep -q 'ALL PROOFS CHECK' || { bend http_test.bend; exit 1; }

# expect <answer> <command...>: the runtime must give <answer> to event {"n":1}.
expect() {
  answer=$1; shift
  node fake_api.mjs 9001 '{"n":1}' > build/got.txt &
  fake=$!
  sleep 0.3
  AWS_LAMBDA_RUNTIME_API=127.0.0.1:9001 "$@" 2> build/err.txt &
  rt=$!
  timeout 10 tail --pid=$fake -f /dev/null || { kill $fake $rt; cat build/err.txt; echo "FAIL: timeout ($*)"; exit 1; }
  kill $rt 2>/dev/null || true
  echo "/2018-06-01/runtime/invocation/id-0/response $answer" | diff build/got.txt -
}

./build.sh echo.bend build/x86_64 x86_64-linux-musl
./build.sh echo.bend build/aarch64
expect '{"echo":{"n":1}}' build/x86_64/bootstrap
expect '{"echo":{"n":1}}' qemu-aarch64 build/aarch64/bootstrap
echo OK
