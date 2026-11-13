#!/usr/bin/env bash
# ============================================================================
# MATRIZ DE REJEIÇÃO EM COMPILAÇÃO — os 16 pares (origem, destino) de vértices, com a CAUSA conferida.
#
# Parecer de 03/11/2026, nível 1: "registrar testes que devem compilar e testes negativos que devem
# falhar, conferindo a causa do erro". Para cada par gera um módulo mínimo
#       act SFrom = pureResult MsgIgnored STo
# e o compila com `ghc -fno-code`. Esperado, derivado de spec/transition_table.csv (e não de uma lista
# escrita à mão neste script):
#   - COMPILA     : o par é uma aresta da tabela ou a identidade (8 pares);
#   - É REJEITADO : qualquer outro par, com EXATAMENTE UM erro, e esse erro é
#                   `Could not deduce ... AllowedTransition ... From To` nomeando o par (8 pares).
# Sai com 0 só se os 16 resultados coincidirem com o esperado, inclusive a causa.
#
# Uso:  bash validation/scripts/negative_matrix.sh      (de qualquer pasta)
# Escreve: 08_reprodutibilidade/logs/02_negative_matrix.md
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"        # validation/
CODE="$(cd "$HERE/.." && pwd)"                  # 03_codigo/
ROOT="$(cd "$CODE/.." && pwd)"                  # Revisao_v5/
SPEC="$HERE/spec/transition_table.csv"
WORK="$CODE/dist-newstyle/negative-matrix"
OUT="$ROOT/08_reprodutibilidade/logs/02_negative_matrix.md"
VERTS="Grounded InFlight EmergencyLanding Shutdown"
export LANG=C.UTF-8
mkdir -p "$WORK" "$(dirname "$OUT")"
rm -f "$WORK"/*.hs "$WORK"/*.log

# aresta da tabela: linha com destino diferente do estado
allowed_in_spec() { awk -F, -v a="$1" -v b="$2" '/^#/ {next} $1==a && $3==b && $1!=$3 {f=1} END{exit !f}' "$SPEC"; }
expected() { if [ "$1" = "$2" ] || allowed_in_spec "$1" "$2"; then echo compila; else echo rejeitado; fi; }

mismatch=0; rows=""; errlines=""; n_comp=0; n_rej=0
cd "$CODE" || exit 2
for from in $VERTS; do
  for to in $VERTS; do
    mod="M_${from}_${to}"; file="$WORK/$mod.hs"
    cat > "$file" <<HSEOF
{-# LANGUAGE DataKinds #-}
module $mod where

import Avionics.Crem
import Crem.BaseMachine (ActionResult, pureResult)

act :: Applicative m => SAvionicsVertex '$from -> ActionResult m AvionicsTopology SAvionicsVertex '$from Output
act S$from = pureResult MsgIgnored S$to
HSEOF
    log="$WORK/$mod.log"
    cabal exec -v0 -- ghc -fno-code -package avionics-crem -package crem -package singletons-base "$file" > "$log" 2>&1
    code=$?
    flat=$(tr -s ' \r\n' '   ' < "$log")
    nerr=$(grep -c "error:" "$log")
    exp=$(expected "$from" "$to")
    if [ $code -eq 0 ] && [ "$nerr" -eq 0 ]; then got=compila
    elif [ $code -ne 0 ] && [ "$nerr" -eq 1 ] && echo "$flat" | grep -Eq "Could not deduce .?Crem\.Topology\.AllowedTransition.* $from $to'"; then got=rejeitado
    else got="inesperado(exit=$code,erros=$nerr)"; fi
    if [ "$got" = "$exp" ]; then ok="ok"; else ok="DIVERGE"; mismatch=$((mismatch+1)); fi
    [ "$got" = compila ] && n_comp=$((n_comp+1)); [ "$got" = rejeitado ] && n_rej=$((n_rej+1))
    printf '%-17s -> %-17s  esperado=%-9s obtido=%-9s %s\n' "$from" "$to" "$exp" "$got" "$ok"
    kind="aresta"; [ "$from" = "$to" ] && kind="identidade"; [ "$exp" = rejeitado ] && kind="proibido"
    rows="$rows| $from | $to | $kind | $exp | $got | $ok |
"
    if [ "$got" = rejeitado ]; then
      # tamanho do diagnóstico (a Figura 2 do artigo do SCP usa InFlight -> Shutdown); os bytes incluem o caminho
      errlines="$errlines- \`$from → $to\` ($(wc -l < "$log" | tr -d ' ') linhas, $(wc -c < "$log" | tr -d ' ') bytes): $(echo "$flat" | grep -Eo "Could not deduce .{0,160}$from $to'" | head -1 | sed 's/  */ /g')
"
    fi
  done
done
{
  echo "# Matriz de rejeição em compilação (16 pares de vértices), com a causa conferida"
  echo
  echo "Gerado por \`validation/scripts/negative_matrix.sh\` em $(date +%F), com GHC $(ghc --numeric-version)."
  echo "Esperado: derivado de \`validation/spec/transition_table.csv\`. Cada linha foi compilada com \`ghc -fno-code\`."
  echo "Rejeitado = exatamente um erro, e é \`Could not deduce AllowedTransition ... <origem> <destino>\`."
  echo
  echo "| De | Para | Natureza | Esperado | Obtido | Confere |"
  echo "|---|---|---|---|---|---|"
  printf '%s' "$rows"
  echo
  echo "Compilaram: $n_comp. Rejeitados: $n_rej. Divergências: $mismatch."
  echo
  echo "## Erro do GHC nos pares rejeitados (trecho)"
  echo
  echo "Entre parênteses, o tamanho da saída do GHC (\`wc -l\` / \`wc -c\`); os bytes incluem o caminho do módulo gerado."
  echo
  printf '%s' "$errlines"
} > "$OUT"
echo
echo "compilaram=$n_comp rejeitados=$n_rej divergencias=$mismatch  (relatório: $OUT)"
[ "$mismatch" -eq 0 ] && [ "$n_comp" -eq 8 ] && [ "$n_rej" -eq 8 ]
