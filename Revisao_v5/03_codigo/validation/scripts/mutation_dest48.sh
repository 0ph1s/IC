#!/usr/bin/env bash
# ============================================================================
# MUTAÇÃO EXAUSTIVA DE DESTINOS (48 mutantes) DA AÇÃO DA AVIÔNICA EM CREM
# Derivado de mutation.sh (mesma mecânica); proposto na edição de 14/11/2026 e AINDA NÃO EXECUTADO
# com GHC: a mecânica de geração/aplicação foi ensaiada com cabal/ghc simulados.
#   "Manter testes de mutação capazes de acusar arestas ilegais, destinos incorretos e eventos trocados."
#
# Trabalha numa CÓPIA TEMPORÁRIA de 03_codigo (os arquivos do projeto nunca são tocados). Para cada
# mutante: restaura os fontes, aplica a mutação, compila e roda as suítes. Resultado por mutante:
#   - "recusado na compilação" (com a causa) : o compilador barrou o defeito;
#   - "morto por: ..."                       : compilou, e alguma suíte reprovou;
#   - "VIVO"                                 : compilou e TODAS as suítes passaram (lacuna dos testes).
# Suítes usadas: avionics-spec-tests (pacote base), avionics-sim-tests (N = 3), validation-conformance-tests,
# validation-reach-tests e validation-model-tests (Hedgehog).
#
# Uso:   bash validation/scripts/mutation_dest48.sh          # todos os 48
#        bash validation/scripts/mutation_dest48.sh D01 D17  # só alguns
# Escreve: 08_reprodutibilidade/logs/06b_mutation_dest48.md
# Demora: a primeira compilação da cópia refaz tudo (minutos); depois é incremental.
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"        # validation/
CODE="$(cd "$HERE/.." && pwd)"                  # 03_codigo/
ROOT="$(cd "$CODE/.." && pwd)"                  # Revisao_v5/
OUT="${OUT_MD:-$ROOT/08_reprodutibilidade/logs/06b_mutation_dest48.md}"   # OUT_MD: outro destino (útil ao rodar só alguns mutantes)
TMP="${TMPDIR:-${TEMP:-/tmp}}/mutv5_dest48"
KEEP="${KEEP:-0}"
export LANG=C.UTF-8
rm -rf "$TMP"; mkdir -p "$TMP/code" "$TMP/logs"
( cd "$CODE" && tar --exclude=dist-newstyle -cf - . ) | ( cd "$TMP/code" && tar -xf - )
D="$TMP/dist"
CREM="base/avionics-crem/src/Avionics/Crem.hs"
POWER="base/avionics-crem/src/Avionics/Power.hs"
MISSION="base/avionics-crem/src/Avionics/Sim/Mission.hs"

# ---------------------------------------------------------------------------------------------
# Os 48 mutantes de DESTINO sao gerados a partir das 16 equacoes de avionicsAction em Crem.hs:
# para cada equacao, o destino e trocado por cada um dos outros tres vertices (saida inalterada).
# PREVISAO (combinatoria, a partir da topologia declarada): 32 fora da topologia -> recusa esperada
# com "Could not deduce AllowedTransition"; 16 dentro da topologia -> compilacao esperada, e o
# mutante so pode ser morto por teste. O relatorio confronta previsao e resultado observado.
# id | descrição | arquivo | expressão sed -E | previsão
VERTS=(Grounded InFlight EmergencyLanding Shutdown)
allowed() { # origem destino -> 0 se a aresta (ou identidade) esta na topologia
  case "$1>$2" in
    "Grounded>Grounded"|"Grounded>InFlight"|"Grounded>Shutdown") return 0;;
    "InFlight>InFlight"|"InFlight>EmergencyLanding") return 0;;
    "EmergencyLanding>EmergencyLanding"|"EmergencyLanding>Grounded") return 0;;
    "Shutdown>Shutdown") return 0;;
  esac; return 1; }
MUTANTS=(); n=0
while read -r st ev dest; do
  for v in "${VERTS[@]}"; do
    [ "$v" = "$dest" ] && continue
    n=$((n+1)); id=$(printf 'D%02d' "$n")
    if allowed "$st" "$v"; then pred="aceito"; else pred="recusado"; fi
    MUTANTS+=("$id|destino trocado: $st+$ev -> $v (original $dest)|$CREM|s/^(avionicsAction S$st $ev[[:space:]]*= pureResult [A-Za-z]+ )S$dest[[:space:]]*\$/\\1S$v/|$pred")
  done
done < <(sed -nE 's/^avionicsAction S([A-Za-z]+) ([A-Za-z]+)[[:space:]]*= pureResult [A-Za-z]+ S([A-Za-z]+)[[:space:]]*$/\1 \2 \3/p' "$CODE/$CREM")
if [ "${#MUTANTS[@]}" -ne 48 ]; then echo "ERRO: esperados 48 mutantes de destino, gerados ${#MUTANTS[@]} (o formato de $CREM mudou?)"; exit 2; fi
WANT=("$@")
selected() { [ ${#WANT[@]} -eq 0 ] && return 0; local w; for w in "${WANT[@]}"; do [ "$w" = "$1" ] && return 0; done; return 1; }

TARGETS_BUILD=(avionics-crem:test:avionics-spec-tests avionics-crem:test:avionics-sim-tests avionics-validation:test:validation-conformance-tests avionics-validation:test:validation-reach-tests avionics-validation:test:validation-model-tests)
SUITES=("avionics-crem:test:avionics-spec-tests|spec-tests|" "avionics-crem:test:avionics-sim-tests|sim-tests (N=3)|--test-options=3" "avionics-validation:test:validation-conformance-tests|conformance|" "avionics-validation:test:validation-reach-tests|reach|" "avionics-validation:test:validation-model-tests|model (Hedgehog)|")

build() { ( cd "$TMP/code" && cabal build --builddir="$D" "${TARGETS_BUILD[@]}" > "$TMP/logs/$1.build.txt" 2>&1 ); }

restore() { cp "$CODE/$CREM" "$TMP/code/$CREM"; cp "$CODE/$POWER" "$TMP/code/$POWER"; cp "$CODE/$MISSION" "$TMP/code/$MISSION"; }

{
  echo "# Mutação exaustiva de destinos (48 mutantes) da ação da aviônica em CREM"
  echo
  echo "Gerado por \`validation/scripts/mutation_dest48.sh\` em $(date +%F), GHC $(ghc --numeric-version). Cada mutante é aplicado a uma cópia temporária de \`03_codigo\`."
  echo "Suítes: spec-tests e sim-tests (N=3) do pacote base; conformance, reach e model (Hedgehog) do pacote de validação."
  echo
  echo "| Id | Defeito injetado | Previsto | Resultado | Suítes que reprovaram / causa | Concorda |"
  echo "|---|---|---|---|---|---|"
} > "$OUT"

echo "[baseline] compilando a cópia sem mutação..."
restore
if ! build baseline; then echo "ERRO: a cópia sem mutação não compila; veja $TMP/logs/baseline.build.txt"; exit 2; fi
base_fail=""
for s in "${SUITES[@]}"; do
  t="${s%%|*}"; r="${s#*|}"; lbl="${r%%|*}"; opt="${r#*|}"
  ( cd "$TMP/code" && cabal test --builddir="$D" "$t" $opt > "$TMP/logs/baseline.$lbl.txt" 2>&1 ) || base_fail="$base_fail $lbl"
done
if [ -n "$base_fail" ]; then echo "ERRO: sem mutação, estas suítes já reprovam:$base_fail"; exit 2; fi
echo "[baseline] todas as suítes passam sem mutação"

alive=0; total=0; agree=0; nrej=0; nacc=0
for m in "${MUTANTS[@]}"; do
  id="${m%%|*}"; r1="${m#*|}"; desc="${r1%%|*}"; r2="${r1#*|}"; file="${r2%%|*}"; r3="${r2#*|}"; exprs="${r3%|*}"; pred="${r3##*|}"
  selected "$id" || continue
  total=$((total+1))
  restore
  IFS=$'\n' read -r -d '' -a parts < <(printf '%s' "$exprs" | sed 's/;;/\n/g' && printf '\0')
  # cada expressão é aplicada e conferida SEPARADAMENTE: se uma delas deixar de casar com o fonte, o
  # mutante não pode rodar meio aplicado sob a descrição completa
  cp "$CODE/$file" "$TMP/mut.cur"
  k=0
  for e in "${parts[@]}"; do
    k=$((k+1))
    sed -E -e "$e" "$TMP/mut.cur" > "$TMP/mut.next"
    if cmp -s "$TMP/mut.cur" "$TMP/mut.next"; then echo "ERRO: a expressão $k da mutação $id não alterou $file: $e"; exit 2; fi
    mv "$TMP/mut.next" "$TMP/mut.cur"
  done
  cp "$TMP/mut.cur" "$TMP/code/$file"
  echo "[$id] $desc"
  if ! build "$id"; then
    cause=$(grep -m1 -E "Could not deduce|incomplete-patterns|non-exhaustive|error:" "$TMP/logs/$id.build.txt" | sed 's/^ *//' | cut -c1-150)
    echo "      -> recusado na compilação: $cause"
    nrej=$((nrej+1))
    # só conta como a recusa prevista se a causa for a prova de aresta ausente
    if [ "$pred" = "recusado" ] && grep -q "AllowedTransition" "$TMP/logs/$id.build.txt"; then ok="sim"; agree=$((agree+1)); else ok="**NÃO**"; fi
    echo "| $id | $desc | $pred | **recusado na compilação** | $(echo "$cause" | sed 's/|/\\|/g') | $ok |" >> "$OUT"
    continue
  fi
  killers=""
  for s in "${SUITES[@]}"; do
    t="${s%%|*}"; r="${s#*|}"; lbl="${r%%|*}"; opt="${r#*|}"
    ( cd "$TMP/code" && cabal test --builddir="$D" "$t" $opt > "$TMP/logs/$id.$lbl.txt" 2>&1 ) || killers="$killers${killers:+, }$lbl"
  done
  if [ -n "$killers" ]; then
    echo "      -> morto por: $killers"
    nacc=$((nacc+1)); if [ "$pred" = "aceito" ]; then ok="sim"; agree=$((agree+1)); else ok="**NÃO**"; fi
    echo "| $id | $desc | $pred | compila; **morto** | $killers | $ok |" >> "$OUT"
  else
    alive=$((alive+1))
    echo "      -> VIVO"
    nacc=$((nacc+1)); if [ "$pred" = "aceito" ]; then ok="sim"; agree=$((agree+1)); else ok="**NÃO**"; fi
    echo "| $id | $desc | $pred | compila; **VIVO** | nenhuma suíte reprovou | $ok |" >> "$OUT"
  fi
done
{
  echo
  echo "Mutantes avaliados: $total. Recusados na compilação: $nrej. Aceitos: $nacc. Vivos: $alive. Previsão confirmada em $agree de $total."
  echo
  echo "Notas: a previsão (32 recusados, 16 aceitos) é combinatória e decorre da topologia declarada; este relatório é a medida."
  echo "Um mutante previsto como recusado só conta como confirmado se o erro do GHC citar AllowedTransition."
} >> "$OUT"
echo "relatório: $OUT   (vivos: $alive de $total)"
[ "$KEEP" = 1 ] || rm -rf "$TMP"
[ "$alive" -eq 0 ]
