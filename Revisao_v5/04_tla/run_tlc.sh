#!/usr/bin/env bash
# ============================================================================
# Roda o TLC sobre AvionicsLoop.tla nas três configurações e confere com a exploração em Haskell.
#
#   OneSlot              esperado: TLC termina com código 13 (propriedade temporal violada: NoPermanentBlindness)
#   OneSlot sem cegueira esperado: código 0 (as demais propriedades valem; o TLC para na 1a violação, por isso a separação)
#   Level                esperado: código 0 (todas as propriedades valem)
# Depois: cross_check.py compara os ternos com fila vazia do TLC com os de 04_reach.txt (rode run_all.sh antes).
#
# Pré-requisito: Java e tools/tla2tools.jar (não versionado). Versão usada: TLA+ Tools v1.7.4 (TLC 2.19), release ESTÁVEL
# de https://github.com/tlaplus/tlaplus/releases, 2 274 532 bytes, sha256 abaixo:
#   gh release download v1.7.4 --repo tlaplus/tlaplus --pattern tla2tools.jar --dir tools
# Uso:  bash 04_tla/run_tlc.sh        Escreve 08_reprodutibilidade/logs/14_tlc_*.txt
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
LOGS="$(cd "$HERE/.." && pwd)/08_reprodutibilidade/logs"
JAR="$HERE/tools/tla2tools.jar"
SHA=936a262061c914694dfd669a543be24573c45d5aa0ff20a8b96b23d01e050e88
[ -f "$JAR" ] || { echo "tools/tla2tools.jar ausente; veja o cabeçalho deste script"; exit 2; }
[ "$(sha256sum "$JAR" | cut -d' ' -f1)" = "$SHA" ] || { echo "sha256 do jar diferente do esperado ($SHA)"; exit 2; }
cd "$HERE" || exit 2
rm -rf states; mkdir -p states "$LOGS"
FAIL=0
tlc() { # $1 rótulo, $2 cfg, $3 código esperado, $4 log, resto: opções extras do TLC
  local label="$1" cfg="$2" want="$3" log="$4"; shift 4
  java -cp "$JAR" tlc2.TLC -metadir "states/$label" "$@" -config "$cfg" AvionicsLoop.tla > "$LOGS/$log" 2>&1
  local got=$?
  if [ "$got" -eq "$want" ]; then echo "ok    $label: código $got (esperado $want)"; else echo "FALHA $label: código $got (esperado $want)"; FAIL=1; fi
  sed 's/\x1b\[[0-9;]*m//g' "$LOGS/$log" | grep -E "distinct states found|Model checking completed|Temporal properties were violated|Invariant .* is violated" | head -3
}
tlc OneSlot AvionicsLoop_OneSlot.cfg 13 14_tlc_OneSlot.txt
tlc OneSlot_sem_cegueira AvionicsLoop_OneSlot_sem_cegueira.cfg 0 14_tlc_OneSlot_sem_cegueira.txt
tlc Level AvionicsLoop_Level.cfg 0 14_tlc_Level.txt
tlc dumpOneSlot AvionicsLoop_OneSlot.cfg 13 14_tlc_dump_OneSlot.txt -dump states/dump_OneSlot.txt
if [ -f "$LOGS/04_reach.txt" ]; then
  python "$HERE/cross_check.py" | tee "$LOGS/14_tlc_crosscheck.txt" || FAIL=1
else
  echo "04_reach.txt ausente: rode run_all.sh antes para a conferência com o Haskell"
fi
[ "$FAIL" -eq 0 ] && echo "TLC: tudo como esperado" || echo "TLC: HÁ DIVERGÊNCIAS"
exit $FAIL
