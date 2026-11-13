#!/usr/bin/env bash
# ============================================================================
# DEFEITOS NA FSM EM HASKELL "INGÊNUA" (Avionics.Naive) — a coluna Haskell sem CREM da comparação com C e C++
#
# Mesmas classes de defeito de audit.sh, sobre a função `transition` de 03_codigo/base/avionics-crem/src/Avionics/Naive.hs
# (módulo sem dependências; cada mutante é um arquivo próprio em 05_c-cpp/work/):
#   N1 par omitido (sem curinga)            N2 par omitido + cláusula final com curinga
#   N3 transição proibida (InFlight+SystemCutoff -> Shutdown)
#   N4 destino errado em aresta permitida (Grounded+TakeoffSignal -> Shutdown)
#   N5 compara estado com evento            N6 valor fora da enumeração (42)
# Mecanismos: GHC `-Wall` (A), `-Wall -Werror=incomplete-patterns` (W) e o harness exaustivo (os 16 pares, via runghc)
# contra spec/transition_table.csv.
# Uso:  bash 05_c-cpp/scripts/haskell_defects.sh     Escreve 08_reprodutibilidade/logs/16_haskell_defects.md
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
SPEC="$ROOT/03_codigo/validation/spec/transition_table.csv"
SRC="$ROOT/03_codigo/base/avionics-crem/src/Avionics/Naive.hs"
OUT="$ROOT/08_reprodutibilidade/logs/16_haskell_defects.md"
W="$HERE/work/haskell"; rm -rf "$W"; mkdir -p "$W" "$(dirname "$OUT")"
export LANG=C.UTF-8
awk -F, '/^#/ {next} NF>=4 {gsub(/\r/,""); print $1, $2, $3}' "$SPEC" > "$W/expected.txt"
cat > "$W/Harness.hs" <<'HSEOF'
import Avionics.Naive
main :: IO ()
main = mapM_ (\(s, e) -> putStrLn (show s ++ " " ++ show e ++ " " ++ show (transition s e)))
             [(s, e) | s <- [minBound .. maxBound], e <- [minBound .. maxBound]]
HSEOF
L_IN='^transition InFlight +LandedSignal +='
mk() { # $1 id, $2 expressão sed -E (vazia = nenhuma), $3 texto a acrescentar no fim do arquivo (opcional)
  mkdir -p "$W/$1/Avionics"
  if [ -z "$2" ]; then cp "$SRC" "$W/$1/Avionics/Naive.hs"; else sed -E -e "$2" "$SRC" > "$W/$1/Avionics/Naive.hs"; fi
  [ -n "${3:-}" ] && printf '\n%s\n' "$3" >> "$W/$1/Avionics/Naive.hs"
  if [ "$1" != N0 ] && cmp -s "$SRC" "$W/$1/Avionics/Naive.hs"; then echo "mutação $1 não alterou o arquivo" >&2; exit 2; fi
}
mk N0 ""
mk N1 "/$L_IN/d"
mk N2 "/$L_IN/d;/^transition Shutdown +SystemCutoff +=/a\\transition s _ = s"
mk N3 "s/^(transition InFlight +SystemCutoff +=) InFlight/\\1 Shutdown/"
mk N4 "s/^(transition Grounded +TakeoffSignal +=) InFlight/\\1 Shutdown/"
mk N5 "" $'confunde :: AvState -> AvEvent -> Bool\nconfunde s e = s == e'
mk N6 "" $'forade :: AvState\nforade = 42'
names=(N0 N1 N2 N3 N4 N5 N6)
desc=("baseline (sem defeito)" "par omitido (InFlight+LandedSignal), sem curinga" "par omitido e cláusula final com curinga (transition s _ = s)" "transição proibida InFlight+SystemCutoff -> Shutdown" "aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown)" "compara estado com evento (s == e)" "valor fora da enumeração (42 :: AvState)")
classify() { # $1 log, $2 código
  local warns; warns=$(grep -c "warning:" "$1")
  if [ "$2" -ne 0 ]; then echo "recusa|$(grep -m1 'error:' "$1" | sed 's/^.*error: //')"
  elif [ "$warns" -gt 0 ]; then echo "aviso($warns)|$(grep -m1 'warning:' "$1" | sed 's/^.*warning: //')"
  else echo "silêncio|-"; fi
}
rows=""; bad=0
for i in "${!names[@]}"; do
  n=${names[$i]}; d="$W/$n"
  ( cd "$d" && ghc -fno-code -Wall Avionics/Naive.hs > A.log 2>&1 ); ccA=$?
  ( cd "$d" && ghc -fno-code -Wall -Werror=incomplete-patterns Avionics/Naive.hs > W.log 2>&1 ); ccW=$?
  rA=$(classify "$d/A.log" $ccA); rW=$(classify "$d/W.log" $ccW); msgW="${rW#*|}"; rA="${rA%%|*}"; rW="${rW%%|*}"
  if [ $ccA -eq 0 ]; then
    ( cd "$d" && runghc -i. "$W/Harness.hs" > out.raw 2> out.err ); tr -d '\r' < "$d/out.raw" > "$d/out.txt"
    if diff -q "$d/out.txt" "$W/expected.txt" > /dev/null; then run="passa"
    elif [ -s "$d/out.err" ]; then run="detecta (exceção em execução: $(head -c 60 "$d/out.err" | tr '\n' ' '))"
    else run="detecta ($(diff "$d/out.txt" "$W/expected.txt" | grep -c '^<') par)"; fi
  else run="-"; fi
  if [ "$n" = N0 ] && { [ "$rA" != "silêncio" ] || [ "$rW" != "silêncio" ] || [ "$run" != "passa" ]; }; then bad=1; fi
  printf '%-3s A:%-11s W:%-9s %s\n' "$n" "$rA" "$rW" "$run"
  rows="$rows| $n | ${desc[$i]} | $rA | $rW | $run | ${msgW//|/\\|} |
"
done
{
  echo "# Defeitos na FSM em Haskell ingênua (Avionics.Naive)"
  echo
  echo "Gerado por \`05_c-cpp/scripts/haskell_defects.sh\` em $(date +%F), GHC $(ghc --numeric-version). A: \`-Wall\`. W: \`-Wall -Werror=incomplete-patterns\`."
  echo "Harness: \`runghc\` imprime os 16 pares e compara com \`spec/transition_table.csv\`."
  echo
  echo "| Id | Defeito | A | W | Harness exaustivo | Primeira mensagem (W) |"
  echo "|---|---|---|---|---|---|"
  printf '%s' "$rows"
} > "$OUT"
echo "relatório: $OUT"; [ "$bad" -eq 0 ]
