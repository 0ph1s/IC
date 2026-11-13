#!/usr/bin/env bash
# ============================================================================
# DEFEITOS NA FSM EM HASKELL — as colunas "Haskell" (sem CREM) e "Haskell + CREM" da comparação com C e C++
#
# Parte 1 (N0 a N6): as classes de defeito de audit.sh sobre a função `transition` de
# 03_codigo/base/avionics-crem/src/Avionics/Naive.hs (módulo sem dependências; cada mutante é um arquivo
# próprio em 05_c-cpp/work/haskell/):
#   N1 par omitido (sem curinga)            N2 par omitido + cláusula final com curinga
#   N3 transição proibida (InFlight+SystemCutoff -> Shutdown)
#   N4 destino errado em aresta permitida (Grounded+TakeoffSignal -> Shutdown)
#   N5 compara estado com evento            N6 valor fora da enumeração (42)
# Mecanismos: GHC `-Wall` (A), `-Wall -Werror=incomplete-patterns` (W) e o harness exaustivo (os 16 pares,
# via runghc) contra spec/transition_table.csv.
#
# Parte 2 (C0, C5, C6): as classes D5 e D6 sobre a AÇÃO do CREM (src/Avionics/Crem.hs), compiladas com as
# opções do pacote (GHC2021, `-Wall -Werror=incomplete-patterns`) e `-fno-code`. C0 é o arquivo sem defeito
# e prova que o comando de compilação funciona (sem ele, uma recusa poderia ser erro do próprio comando).
# As classes D1 a D4 do CREM estão na mutação da implementação (validation/scripts/mutation.sh: H5, H9, H4, H2).
#   C5 evento usado como destino (Grounded+CriticalBattery devolve o evento CriticalBattery)
#   C6 valor fora da enumeração (Grounded+CriticalBattery devolve 42)
#
# Cada expressão sed é aplicada e conferida em separado: nenhum mutante roda meio aplicado.
# Uso:  bash 05_c-cpp/scripts/haskell_defects.sh     Escreve 08_reprodutibilidade/logs/16_haskell_defects.md
# Sai com 0 se N0 e C0 compilam sem aviso (N0 passa no harness) e se C5 e C6 são recusados na compilação.
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"; ROOT="$(cd "$HERE/.." && pwd)"
CODE="$ROOT/03_codigo"
SPEC="$CODE/validation/spec/transition_table.csv"
BASE_SRC="$CODE/base/avionics-crem/src"
SRC="$BASE_SRC/Avionics/Naive.hs"
CREM_SRC="$BASE_SRC/Avionics/Crem.hs"
OUT="$ROOT/08_reprodutibilidade/logs/16_haskell_defects.md"
W="$HERE/work/haskell"; rm -rf "$W"; mkdir -p "$W" "$(dirname "$OUT")"
export LANG=C.UTF-8
# as mesmas opções do pacote avionics-crem (avionics-crem.cabal, stanza `common warnings`)
PKG_FLAGS="-XGHC2021 -Wall -Werror=incomplete-patterns -Wno-all-missed-specialisations -Wno-missing-export-lists -Wno-missing-local-signatures -Wno-name-shadowing -Wno-type-defaults"
awk -F, '/^#/ {next} NF>=4 {gsub(/\r/,""); print $1, $2, $3}' "$SPEC" > "$W/expected.txt"
cat > "$W/Harness.hs" <<'HSEOF'
import Avionics.Naive
main :: IO ()
main = mapM_ (\(s, e) -> putStrLn (show s ++ " " ++ show e ++ " " ++ show (transition s e)))
             [(s, e) | s <- [minBound .. maxBound], e <- [minBound .. maxBound]]
HSEOF

# mut <origem> <destino> <expressões sed -E separadas por ;;>: aplica e confere CADA expressão
mut() {
  local src="$1" dst="$2" exprs="$3" e k=0 parts
  cp "$src" "$dst"
  [ -z "$exprs" ] && return 0
  IFS=$'\n' read -r -d '' -a parts < <(printf '%s' "$exprs" | sed 's/;;/\n/g' && printf '\0')
  for e in "${parts[@]}"; do
    k=$((k+1))
    sed -E -e "$e" "$dst" > "$dst.next"
    if cmp -s "$dst" "$dst.next"; then echo "ERRO: a expressão $k não alterou $(basename "$src"): $e" >&2; exit 2; fi
    mv "$dst.next" "$dst"
  done
}

classify() { # $1 log, $2 código
  local warns; warns=$(grep -c "warning:" "$1")
  if [ "$2" -ne 0 ]; then echo "recusa|$(grep -m1 -A1 'error:' "$1" | tr -s ' \r\n' ' ' | sed 's/^.*error: //' | cut -c1-140)"
  elif [ "$warns" -gt 0 ]; then echo "aviso($warns)|$(grep -m1 'warning:' "$1" | sed 's/^.*warning: //')"
  else echo "silêncio|-"; fi
}

# ---------------------------------------------------------------------------
# Parte 1: Avionics.Naive
# ---------------------------------------------------------------------------
L_IN='^transition InFlight +LandedSignal +='
mk() { # $1 id, $2 expressões sed -E separadas por ;; (vazia = nenhuma), $3 texto a acrescentar no fim (opcional)
  mkdir -p "$W/$1/Avionics"
  mut "$SRC" "$W/$1/Avionics/Naive.hs" "$2"
  [ -n "${3:-}" ] && printf '\n%s\n' "$3" >> "$W/$1/Avionics/Naive.hs"
  if [ "$1" != N0 ] && cmp -s "$SRC" "$W/$1/Avionics/Naive.hs"; then echo "mutação $1 não alterou o arquivo" >&2; exit 2; fi
}
mk N0 ""
mk N1 "/$L_IN/d"
mk N2 "/$L_IN/d;;/^transition Shutdown +SystemCutoff +=/a\\transition s _ = s"
mk N3 "s/^(transition InFlight +SystemCutoff +=) InFlight/\\1 Shutdown/"
mk N4 "s/^(transition Grounded +TakeoffSignal +=) InFlight/\\1 Shutdown/"
mk N5 "" $'confunde :: AvState -> AvEvent -> Bool\nconfunde s e = s == e'
mk N6 "" $'forade :: AvState\nforade = 42'
names=(N0 N1 N2 N3 N4 N5 N6)
desc=("baseline (sem defeito)" "par omitido (InFlight+LandedSignal), sem curinga" "par omitido e cláusula final com curinga (transition s _ = s)" "transição proibida InFlight+SystemCutoff -> Shutdown" "aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown)" "compara estado com evento (s == e)" "valor fora da enumeração (42 :: AvState)")
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

# ---------------------------------------------------------------------------
# Parte 2: a ação do CREM (Avionics.Crem), classes D5 e D6
# ---------------------------------------------------------------------------
L_GC='^(avionicsAction SGrounded CriticalBattery[[:space:]]*= pureResult MsgIgnored )SGrounded'
c_names=(C0 C5 C6)
c_desc=("baseline (sem defeito)" "evento usado como destino (Grounded+CriticalBattery devolve o evento CriticalBattery)" "valor fora da enumeração (Grounded+CriticalBattery devolve 42)")
c_expr=("" "s/$L_GC/\\1CriticalBattery/" "s/$L_GC/\\1(42)/")
crows=""
for i in "${!c_names[@]}"; do
  n=${c_names[$i]}; d="$W/$n"; mkdir -p "$d/Avionics"
  mut "$CREM_SRC" "$d/Avionics/Crem.hs" "${c_expr[$i]}"
  # `-i$d` antes da pasta original: o Avionics.Crem mutado tem precedência; Avionics.Naive vem do original
  ( cd "$CODE" && cabal exec -v0 -- ghc -fno-code $PKG_FLAGS -i"$d" -i"$BASE_SRC" "$d/Avionics/Crem.hs" > "$d/W.log" 2>&1 ); cc=$?
  r=$(classify "$d/W.log" $cc); msg="${r#*|}"; r="${r%%|*}"
  if [ "$n" = C0 ]; then [ "$r" = "silêncio" ] || bad=1; else [ "$r" = "recusa" ] || bad=1; fi
  printf '%-3s W:%-9s %s\n' "$n" "$r" "$msg"
  crows="$crows| $n | ${c_desc[$i]} | $r | ${msg//|/\\|} |
"
done

{
  echo "# Defeitos na FSM em Haskell: \`Avionics.Naive\` (sem CREM) e a ação do CREM"
  echo
  echo "Gerado por \`05_c-cpp/scripts/haskell_defects.sh\` em $(date +%F), GHC $(ghc --numeric-version)."
  echo
  echo "## Haskell sem CREM (\`Avionics.Naive\`)"
  echo
  echo "A: \`-Wall\`. W: \`-Wall -Werror=incomplete-patterns\`. Harness: \`runghc\` imprime os 16 pares e compara com \`spec/transition_table.csv\`."
  echo
  echo "| Id | Defeito | A | W | Harness exaustivo | Primeira mensagem (W) |"
  echo "|---|---|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "## Haskell + CREM (\`Avionics.Crem\`), classes D5 e D6"
  echo
  echo "Compilado com as opções do pacote (GHC2021, \`-Wall -Werror=incomplete-patterns\`) e \`-fno-code\`. C0 (sem defeito) confere o comando."
  echo "As classes D1 a D4 do CREM estão em \`06_mutation_haskell.md\` (H5, H9, H4, H2)."
  echo
  echo "| Id | Defeito | W | Primeira mensagem |"
  echo "|---|---|---|---|"
  printf '%s' "$crows"
} > "$OUT"
echo "relatório: $OUT"; [ "$bad" -eq 0 ]
