#!/usr/bin/env bash
# Compila o failsafe REAL do PX4 (failsafe.cpp e framework.cpp, sem modificação) com os stubs desta pasta.
# Uso: bash build.sh <pasta do PX4 baixada por fetch_px4.sh> <pasta de saída>
# Requisitos: um compilador C++17 (CXX; padrão clang++ — no Windows, o clang do GHC em
#   <ghc>/mingw/bin, que também precisa estar no PATH para rodar o executável) e Python 3.
# O build define EMSCRIPTEN_BUILD, como o próprio PX4 faz no simulador de failsafe (sem chamadas a events::send).
set -eu
HERE="$(cd "$(dirname "$0")" && pwd)"
R="$(cd "${1:?pasta do PX4}" && pwd)"
OUT="$(mkdir -p "${2:?pasta de saída}" && cd "$2" && pwd)"
CXX="${CXX:-clang++}"
PY=""; for c in python python3; do if "$c" -c 'import sys' > /dev/null 2>&1; then PY="$c"; break; fi; done
[ -n "$PY" ] || { echo "nenhum Python"; exit 2; }
mkdir -p "$OUT/stubs"
cp -r "$HERE/stubs/." "$OUT/stubs/"
RW="$R"; command -v cygpath > /dev/null 2>&1 && RW="$(cygpath -w "$R")"
"$PY" "$HERE/gen_headers.py" "$RW" "$(command -v cygpath > /dev/null 2>&1 && cygpath -w "$OUT/stubs" || echo "$OUT/stubs")"
F="$R/src/modules/commander/failsafe"
FLAGS=(-std=c++17 -O1 -DEMSCRIPTEN_BUILD '-DMODULE_NAME="failsafe"' -include "$HERE/prelude.h" -I"$OUT/stubs"
  -I"$R/platforms/common/include" -I"$R/src/include" -I"$F" -I"$R/src/modules/commander" -I"$R/src/lib/circuit_breaker"
  -I"$R/src" -I"$R/src/lib" -I"$R")
for src in "$F/framework.cpp" "$F/failsafe.cpp" "$R/platforms/common/module_params.cpp" "$HERE/harness.cpp"; do
  "$CXX" "${FLAGS[@]}" -c "$src" -o "$OUT/$(basename "$src" .cpp).o"
done
"$CXX" "$OUT/harness.o" "$OUT/failsafe.o" "$OUT/framework.o" "$OUT/module_params.o" -o "$OUT/px4_failsafe"
echo "ok: $OUT/px4_failsafe"
