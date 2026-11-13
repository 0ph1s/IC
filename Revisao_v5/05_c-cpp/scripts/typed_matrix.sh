#!/usr/bin/env bash
# ============================================================================
# MATRIZ DE REJEIÇÃO DA TOPOLOGIA EM C++17 TIPADO (análogo da matriz de 16 pares do CREM)
#
# Para cada par ordenado (origem, destino) de vértices gera um programa mínimo que usa o traço `Allowed` e a função
# `go<Destino>(Origem{})` de src/fsm_typed.cpp, e o compila. Esperado, derivado de
# 03_codigo/validation/spec/transition_table.csv: compilam as 4 arestas e as 4 identidades; os outros 8 pares são
# recusados com EXATAMENTE UM erro, e o erro é `static_assert failed ... Allowed<Origem, Destino>::value`.
# O preâmbulo (estados, `Allowed`, `go`) é extraído de src/fsm_typed.cpp, sem retranscrição.
#
# Uso:  bash 05_c-cpp/scripts/typed_matrix.sh        Escreve 08_reprodutibilidade/logs/15_typed_matrix.md
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
SPEC="$ROOT/03_codigo/validation/spec/transition_table.csv"
OUT="$ROOT/08_reprodutibilidade/logs/15_typed_matrix.md"
MINGW="${MINGW:-/c/ghcup/ghc/$(ghc --numeric-version 2>/dev/null)/mingw/bin}"
CXX="${CXX:-$MINGW/clang++.exe}"
export PATH="$MINGW:$PATH" LANG=C.UTF-8
W="$HERE/work/typed_matrix"; rm -rf "$W"; mkdir -p "$W" "$(dirname "$OUT")"
VERTS="Grounded InFlight EmergencyLanding Shutdown"
# preâmbulo: tudo de fsm_typed.cpp antes da primeira equação `step`
awk '/^State step\(Grounded s, TakeoffSignal\)/ {exit} {print}' "$HERE/src/fsm_typed.cpp" > "$W/preamble.hpp"
allowed_in_spec() { awk -F, -v a="$1" -v b="$2" '/^#/ {next} $1==a && $3==b && $1!=$3 {f=1} END{exit !f}' "$SPEC"; }
expected() { if [ "$1" = "$2" ] || allowed_in_spec "$1" "$2"; then echo compila; else echo rejeitado; fi; }
mismatch=0; n_comp=0; n_rej=0; rows=""; msgs=""
for from in $VERTS; do for to in $VERTS; do
  f="$W/${from}_${to}.cpp"
  { cat "$W/preamble.hpp"; printf 'int main() { go<%s>(%s{}); return 0; }\n' "$to" "$from"; } > "$f"
  "$CXX" -std=c++17 -Wall -Wextra -o "$W/${from}_${to}.exe" "$f" > "$W/${from}_${to}.log" 2>&1; code=$?
  nerr=$(grep -c "error:" "$W/${from}_${to}.log")
  exp=$(expected "$from" "$to")
  if [ $code -eq 0 ] && [ "$nerr" -eq 0 ]; then got=compila
  elif [ $code -ne 0 ] && [ "$nerr" -eq 1 ] && grep -q "static_assert failed.*Allowed<$from, $to>" "$W/${from}_${to}.log"; then got=rejeitado
  else got="inesperado(exit=$code,erros=$nerr)"; fi
  if [ "$got" = "$exp" ]; then ok=ok; else ok=DIVERGE; mismatch=$((mismatch+1)); fi
  [ "$got" = compila ] && n_comp=$((n_comp+1)); [ "$got" = rejeitado ] && n_rej=$((n_rej+1))
  printf '%-17s -> %-17s  esperado=%-9s obtido=%-9s %s\n' "$from" "$to" "$exp" "$got" "$ok"
  rows="$rows| $from | $to | $exp | $got | $ok |
"
  [ "$got" = rejeitado ] && msgs="$msgs- \`$from → $to\`: $(grep -m1 'static_assert failed' "$W/${from}_${to}.log" | sed 's/^.*error: //')
"
done; done
{
  echo "# Matriz de rejeição da topologia em C++17 tipado (16 pares), com a causa conferida"
  echo
  echo "Gerado por \`05_c-cpp/scripts/typed_matrix.sh\` em $(date +%F). Compilador: $("$CXX" --version | head -1), \`-std=c++17 -Wall -Wextra\`."
  echo "Esperado: derivado de \`03_codigo/validation/spec/transition_table.csv\`. Rejeitado = exatamente um erro, \`static_assert\` nomeando o par."
  echo
  echo "| De | Para | Esperado | Obtido | Confere |"
  echo "|---|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "Compilaram: $n_comp. Rejeitados: $n_rej. Divergências: $mismatch."
  echo
  echo "## Mensagem nos pares rejeitados"
  echo
  printf '%s' "$msgs"
} > "$OUT"
echo "compilaram=$n_comp rejeitados=$n_rej divergencias=$mismatch  (relatório: $OUT)"
[ "$mismatch" -eq 0 ] && [ "$n_comp" -eq 8 ] && [ "$n_rej" -eq 8 ]
