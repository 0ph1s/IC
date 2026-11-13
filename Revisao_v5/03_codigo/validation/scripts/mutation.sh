#!/usr/bin/env bash
# ============================================================================
# TESTES DE MUTAÇÃO DA IMPLEMENTAÇÃO EM CREM (parecer de 03/11/2026, nível 1)
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
# Uso:   bash validation/scripts/mutation.sh            # todos os mutantes
#        bash validation/scripts/mutation.sh H2 H3      # só alguns
# Escreve: 08_reprodutibilidade/logs/06_mutation_haskell.md
# Demora: a primeira compilação da cópia refaz tudo (minutos); depois é incremental.
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"        # validation/
CODE="$(cd "$HERE/.." && pwd)"                  # 03_codigo/
ROOT="$(cd "$CODE/.." && pwd)"                  # Revisao_v5/
OUT="${OUT_MD:-$ROOT/08_reprodutibilidade/logs/06_mutation_haskell.md}"   # OUT_MD: outro destino (útil ao rodar só alguns mutantes)
TMP="${TMPDIR:-${TEMP:-/tmp}}/mutv5"
KEEP="${KEEP:-0}"
export LANG=C.UTF-8
rm -rf "$TMP"; mkdir -p "$TMP/code" "$TMP/logs"
( cd "$CODE" && tar --exclude=dist-newstyle -cf - . ) | ( cd "$TMP/code" && tar -xf - )
D="$TMP/dist"
CREM="base/avionics-crem/src/Avionics/Crem.hs"
POWER="base/avionics-crem/src/Avionics/Power.hs"
MISSION="base/avionics-crem/src/Avionics/Sim/Mission.hs"

# id | descrição | arquivo | expressões sed -E (separadas por ;;)
MUTANTS=(
  "H1|aresta ILEGAL na topologia E na ação (InFlight -> Shutdown permitida)|$CREM|s/\\(InFlight, \\[EmergencyLanding\\]\\)/(InFlight, [EmergencyLanding, Shutdown])/;;s/^(avionicsAction SInFlight SystemCutoff[[:space:]]*= pureResult )MsgIgnored SInFlight/\\1MsgShutdown SShutdown/"
  "H2|DESTINO errado em aresta permitida (Grounded+TakeoffSignal -> Shutdown)|$CREM|s/^(avionicsAction SGrounded TakeoffSignal[[:space:]]*= pureResult MsgTakeoff )SInFlight/\\1SShutdown/"
  "H3|EVENTOS trocados em Grounded (TakeoffSignal <-> SystemCutoff)|$CREM|s/^(avionicsAction SGrounded TakeoffSignal[[:space:]]*= pureResult )MsgTakeoff SInFlight/\\1MsgShutdown SShutdown/;;s/^(avionicsAction SGrounded SystemCutoff[[:space:]]*= pureResult )MsgShutdown SShutdown/\\1MsgTakeoff SInFlight/"
  "H4|ação ilegal SEM tocar na topologia (InFlight+SystemCutoff -> Shutdown)|$CREM|s/^(avionicsAction SInFlight SystemCutoff[[:space:]]*= pureResult )MsgIgnored SInFlight/\\1MsgShutdown SShutdown/"
  "H5|par (estado, evento) OMITIDO (Shutdown+SystemCutoff)|$CREM|/^avionicsAction SShutdown SystemCutoff/d"
  "H6|SAÍDA errada (EmergencyLanding+LandedSignal emite MsgIgnored)|$CREM|s/^(avionicsAction SEmergencyLanding LandedSignal[[:space:]]*= pureResult )MsgLanded SGrounded/\\1MsgIgnored SGrounded/"
  "H7|AMBIENTE: CriticalHeld libera LandedSignal em vez de CriticalBattery|$MISSION|s/^(missionAction SCriticalHeld CueBeat[[:space:]]*= pureResult \\[ToAvionics )CriticalBattery(\\] SStandby)/\\1LandedSignal\\2/"
  "H8|ENERGIA: Low+Drain fica em Low (não desce a Critical)|$POWER|s/^(powerAction SLow[[:space:]]+Drain[[:space:]]+= pureResult )ReportCritical SCritical/\\1ReportLow SLow/"
  "H9|CURINGA: Grounded+TakeoffSignal omitida e cláusula final avionicsAction s _ = pureResult MsgIgnored s (identidade)|$CREM|/^avionicsAction SGrounded TakeoffSignal/d;;/^avionicsAction SShutdown SystemCutoff/a\\avionicsAction s _ = pureResult MsgIgnored s"
)
WANT=("$@")
selected() { [ ${#WANT[@]} -eq 0 ] && return 0; local w; for w in "${WANT[@]}"; do [ "$w" = "$1" ] && return 0; done; return 1; }

TARGETS_BUILD=(avionics-crem:test:avionics-spec-tests avionics-crem:test:avionics-sim-tests avionics-validation:test:validation-conformance-tests avionics-validation:test:validation-reach-tests avionics-validation:test:validation-model-tests)
SUITES=("avionics-crem:test:avionics-spec-tests|spec-tests|" "avionics-crem:test:avionics-sim-tests|sim-tests (N=3)|--test-options=3" "avionics-validation:test:validation-conformance-tests|conformance|" "avionics-validation:test:validation-reach-tests|reach|" "avionics-validation:test:validation-model-tests|model (Hedgehog)|")

build() { ( cd "$TMP/code" && cabal build --builddir="$D" "${TARGETS_BUILD[@]}" > "$TMP/logs/$1.build.txt" 2>&1 ); }

restore() { cp "$CODE/$CREM" "$TMP/code/$CREM"; cp "$CODE/$POWER" "$TMP/code/$POWER"; cp "$CODE/$MISSION" "$TMP/code/$MISSION"; }

{
  echo "# Testes de mutação da implementação em CREM"
  echo
  echo "Gerado por \`validation/scripts/mutation.sh\` em $(date +%F), GHC $(ghc --numeric-version). Cada mutante é aplicado a uma cópia temporária de \`03_codigo\`."
  echo "Suítes: spec-tests e sim-tests (N=3) do pacote base; conformance, reach e model (Hedgehog) do pacote de validação."
  echo
  echo "| Id | Defeito injetado | Resultado | Suítes que reprovaram / causa |"
  echo "|---|---|---|---|"
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

alive=0; total=0
for m in "${MUTANTS[@]}"; do
  id="${m%%|*}"; r1="${m#*|}"; desc="${r1%%|*}"; r2="${r1#*|}"; file="${r2%%|*}"; exprs="${r2#*|}"
  selected "$id" || continue
  total=$((total+1))
  restore
  args=(-E)
  IFS=$'\n' read -r -d '' -a parts < <(printf '%s' "$exprs" | sed 's/;;/\n/g' && printf '\0')
  for e in "${parts[@]}"; do args+=(-e "$e"); done
  sed "${args[@]}" "$CODE/$file" > "$TMP/code/$file"
  if cmp -s "$CODE/$file" "$TMP/code/$file"; then echo "ERRO: a mutação $id não alterou $file"; exit 2; fi
  echo "[$id] $desc"
  if ! build "$id"; then
    cause=$(grep -m1 -E "Could not deduce|incomplete-patterns|non-exhaustive|error:" "$TMP/logs/$id.build.txt" | sed 's/^ *//' | cut -c1-150)
    echo "      -> recusado na compilação: $cause"
    echo "| $id | $desc | **recusado na compilação** | $(echo "$cause" | sed 's/|/\\|/g') |" >> "$OUT"
    continue
  fi
  killers=""
  for s in "${SUITES[@]}"; do
    t="${s%%|*}"; r="${s#*|}"; lbl="${r%%|*}"; opt="${r#*|}"
    ( cd "$TMP/code" && cabal test --builddir="$D" "$t" $opt > "$TMP/logs/$id.$lbl.txt" 2>&1 ) || killers="$killers${killers:+, }$lbl"
  done
  if [ -n "$killers" ]; then
    echo "      -> morto por: $killers"
    echo "| $id | $desc | compila; **morto** | $killers |" >> "$OUT"
  else
    alive=$((alive+1))
    echo "      -> VIVO"
    echo "| $id | $desc | compila; **VIVO** | nenhuma suíte reprovou |" >> "$OUT"
  fi
done
{
  echo
  echo "Mutantes avaliados: $total. Vivos: $alive."
  echo
  echo "Notas: um mutante recusado na compilação não precisa de teste (é o que se quer da tipagem e de \`-Werror=incomplete-patterns\`)."
  echo "Um mutante que compila e é morto só por teste mostra a fronteira da garantia dos tipos (H2, H3, H6, H7, H8: o compilador os aceita)."
} >> "$OUT"
echo "relatório: $OUT   (vivos: $alive de $total)"
[ "$KEEP" = 1 ] || rm -rf "$TMP"
[ "$alive" -eq 0 ]
