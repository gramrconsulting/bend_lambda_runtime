#!/usr/bin/env bash
# build.sh <entry.bend> <out-dir> [target] [objects...]
# Builds <out-dir>/bootstrap, static, and function.zip for provided.al2023.
# Objects are linked in: the C side of the entry's foreign effects.
set -euo pipefail
entry=$1
out=$2
target=${3:-aarch64-linux-musl}
shift $(( $# < 3 ? $# : 3 ))
mkdir -p "$out"
bend "$entry" -o "$out/main.c"
zig cc -target "$target" -static -O2 -s -Wl,--gc-sections -o "$out/bootstrap" "$out/main.c" "$@"
(cd "$out" && zip -q -j function.zip bootstrap)
