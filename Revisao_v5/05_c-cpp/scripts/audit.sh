#!/usr/bin/env bash
# ============================================================================
# AUDITORIA REPRODUTÍVEL DA COMPARAÇÃO COM C E C++ (parecer de 03/11/2026, seção 6)
#
# Para cada implementação imperativa e cada defeito injetado, registra o que cada mecanismo faz:
#   - compilação com opções A, B e W (B promovido a erro: o análogo do -Werror=incomplete-patterns);
#   - análise estática (clang --analyze);
#   - harness exaustivo (os 16 pares estado x evento) contra spec/transition_table.csv.
# Três pilhas, tratadas SEPARADAMENTE (o parecer pede enum de C e enum class de C++ em separado):
#   c      : C, `enum` + `switch`                          (src/fsm.c)
#   cpp    : C++17, `enum class` + `switch`                (src/fsm.cpp)
#   typed  : C++17 moderno, std::variant + topologia em tipos (src/fsm_typed.cpp)
#
# Uso:   bash 05_c-cpp/scripts/audit.sh
# Escreve: 08_reprodutibilidade/logs/05_c_cpp_matrix.md  e  05_c_cpp_raw.txt
#          05_c-cpp/work/   (fontes mutantes, executáveis e logs brutos; não versionado)
# Variáveis: CC, CXX (compiladores), MINGW (pasta bin do clang que acompanha o GHC).
# Sai com 0 se as três versões SEM defeito (M0, M0, T0) compilarem sem aviso e passarem no harness.
# ============================================================================
set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
SPEC="$ROOT/03_codigo/validation/spec/transition_table.csv"
LOGDIR="$ROOT/08_reprodutibilidade/logs"
W="$HERE/work"
MINGW="${MINGW:-/c/ghcup/ghc/$(ghc --numeric-version 2>/dev/null)/mingw/bin}"
CC="${CC:-$MINGW/clang.exe}"
CXX="${CXX:-$MINGW/clang++.exe}"
export PATH="$MINGW:$PATH"        # o libc++.dll do clang precisa estar no PATH para os executáveis rodarem
export LANG=C.UTF-8

[ -x "$CC" ] && [ -x "$CXX" ] || { echo "clang/clang++ não encontrados (defina CC e CXX ou MINGW)"; exit 2; }
[ -f "$SPEC" ] || { echo "tabela não encontrada: $SPEC"; exit 2; }
mkdir -p "$W" "$LOGDIR"
rm -rf "$W"/*
RAW="$LOGDIR/05_c_cpp_raw.txt"; : > "$RAW"
MD="$LOGDIR/05_c_cpp_matrix.md"

# Saída esperada: os 16 triplos (estado evento destino) da tabela revisável, em ordem.
awk -F, '/^#/ {next} NF>=4 {gsub(/\r/,""); print $1, $2, $3}' "$SPEC" > "$W/expected.txt"
[ "$(wc -l < "$W/expected.txt")" -eq 16 ] || { echo "a tabela deveria ter 16 linhas de dados"; exit 2; }

FLAGS_A="-Wall -Wextra"
FLAGS_B="-Wall -Wextra -Wswitch-enum -Wenum-compare -Wassign-enum"
FLAGS_W="$FLAGS_B -Werror"

classify() { # $1 log, $2 código de saída -> "recusa|aviso(N)|silêncio" seguido de "|" e da 1a mensagem
  local warns; warns=$(grep -c "warning:" "$1")
  if [ "$2" -ne 0 ]; then echo "recusa|$(grep -m1 'error:' "$1" | sed 's/^.*error: //')"
  elif [ "$warns" -gt 0 ]; then echo "aviso($warns)|$(grep -m1 'warning:' "$1" | sed 's/^.*warning: //')"
  else echo "silêncio|-"; fi
}

BAD_BASELINE=0
rows_all=""

# audit_stack <id> <título> <compilador> <extensão> <std> <arquivo-fonte> <arranjo de variantes>
audit_stack() {
  local id="$1" title="$2" comp="$3" ext="$4" std="$5" src="$6"; shift 6
  local variants=("$@")
  mkdir -p "$W/$id"
  {
    echo
    echo "## $title"
    echo
    echo "Fonte: \`05_c-cpp/src/$(basename "$src")\`. Compilador: $("$comp" --version | head -1). Padrão: \`${std:-padrão do compilador}\`."
    echo "A: \`$FLAGS_A\`. B: \`$FLAGS_B\`. W: B com \`-Werror\`. S: \`--analyze\`."
    echo
    echo "| Id | Defeito injetado | A | B | W (erro) | S (análise) | Harness exaustivo | Primeira mensagem (W) |"
    echo "|---|---|---|---|---|---|---|---|"
  } >> "$MD"
  local v
  for v in "${variants[@]}"; do
    local name="${v%%|*}"; local rest="${v#*|}"; local desc="${rest%%|*}"; local expr="${rest#*|}"
    local file="$W/$id/$name.$ext"
    if [ -z "$expr" ]; then cp "$src" "$file"; else sed -e "$expr" "$src" > "$file"; fi
    if [ -n "$expr" ] && cmp -s "$src" "$file"; then echo "mutação $id/$name não alterou o arquivo" >&2; exit 2; fi
    local exe="$W/$id/$name.exe"
    "$comp" $std $FLAGS_A -o "$exe" "$file" > "$W/$id/$name.logA" 2>&1; local ccA=$?
    local rA; rA=$(classify "$W/$id/$name.logA" $ccA); rA="${rA%%|*}"
    "$comp" $std $FLAGS_B -o "$W/$id/${name}_b.exe" "$file" > "$W/$id/$name.logB" 2>&1; local ccB=$?
    local rB; rB=$(classify "$W/$id/$name.logB" $ccB); rB="${rB%%|*}"
    "$comp" $std $FLAGS_W -o "$W/$id/${name}_w.exe" "$file" > "$W/$id/$name.logW" 2>&1; local ccW=$?
    local rW; rW=$(classify "$W/$id/$name.logW" $ccW); local msgW="${rW#*|}"; rW="${rW%%|*}"
    # o analisador grava arquivos .plist no diretório atual: rodar dentro de work/ (não versionado)
    ( cd "$W/$id" && "$comp" $std --analyze "$file" > "$name.logS" 2>&1 ); local ccS=$?
    local rS; rS=$(classify "$W/$id/$name.logS" $ccS); rS="${rS%%|*}"
    local run="-"
    if [ -x "$exe" ]; then
      "$exe" | tr -d '\r' > "$W/$id/$name.out"
      if diff -q "$W/$id/$name.out" "$W/expected.txt" > /dev/null; then run="passa"
      else run="detecta ($(diff "$W/$id/$name.out" "$W/expected.txt" | grep -c '^<') par)"; fi
    fi
    # o baseline não pode ter aviso nem divergência
    if [ -z "$expr" ] && { [ "$rA" != "silêncio" ] || [ "$rB" != "silêncio" ] || [ "$rW" != "silêncio" ] || [ "$run" != "passa" ]; }; then BAD_BASELINE=1; fi
    printf '%-7s %-6s | A:%-11s B:%-11s W:%-9s S:%-9s | %s\n' "$id/$name" "" "$rA" "$rB" "$rW" "$rS" "$run"
    echo "| $name | $desc | $rA | $rB | $rW | $rS | $run | ${msgW//|/\\|} |" >> "$MD"
    { echo "=== $id/$name — $desc"; echo "--- A"; head -4 "$W/$id/$name.logA"; echo "--- B"; head -4 "$W/$id/$name.logB"
      echo "--- W"; head -4 "$W/$id/$name.logW"; echo "--- S"; head -4 "$W/$id/$name.logS"; } >> "$RAW"
  done
}

{
  echo "# Auditoria da comparação com C e C++ (matriz reproduzível)"
  echo
  echo "Gerado por \`05_c-cpp/scripts/audit.sh\` em $(date +%F). Sistema: $(uname -s 2>/dev/null) ($(uname -m 2>/dev/null))."
  echo "Compilador C: $("$CC" --version | head -1). Compilador C++: $("$CXX" --version | head -1)."
  echo "Esperado: os 16 triplos de \`03_codigo/validation/spec/transition_table.csv\` (coluna \`origem\` não usada aqui)."
  echo
  echo "Legenda: **recusa** = a compilação falha; **aviso(N)** = compila com N avisos; **silêncio** = compila sem aviso."
  echo "O harness imprime os 16 pares e os compara com a tabela: **passa** = igual; **detecta** = diferente."
} > "$MD"

# --- C, enum + switch (mesmas expressões sed do pacote base, compare-c/run.sh) ---
C_VARS=(
  "M0|baseline (sem defeito)|"
  "M1|omite o caso InFlight+LandedSignal (sem default)|/case LANDED_SIGNAL:    return IN_FLIGHT;/d"
  "M2|omite o mesmo caso e acrescenta default (curinga)|/case LANDED_SIGNAL:    return IN_FLIGHT;/c\\        default: return s;"
  "M3|transição proibida InFlight+SystemCutoff -> Shutdown|/case SYSTEM_CUTOFF:    return IN_FLIGHT;/s/IN_FLIGHT/SHUTDOWN/"
  "M4|aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown)|0,/case TAKEOFF_SIGNAL:   return IN_FLIGHT;/s//case TAKEOFF_SIGNAL:   return SHUTDOWN;/"
  "M5|compara estado com constante de evento|s/^    switch (s) {\$/    if (s == TAKEOFF_SIGNAL) return SHUTDOWN;\\n    switch (s) {/"
  "M6|retorna valor fora da enumeração (42)|s/^    switch (s) {\$/    if (s == GROUNDED \\&\\& e == LANDED_SIGNAL) return (state_t)42;\\n    switch (s) {/"
)
audit_stack c "Pilha 1 — C (\`enum\` + \`switch\`)" "$CC" c "" "$HERE/src/fsm.c" "${C_VARS[@]}"

# --- C++17, enum class + switch (expressões do pacote base, compare-c/run_cpp.sh) ---
CPP_VARS=(
  "M0|baseline (sem defeito)|"
  "M1|omite o caso InFlight+LandedSignal (sem default)|/case event_t::LANDED_SIGNAL:    return state_t::IN_FLIGHT;/d"
  "M2|omite o mesmo caso e acrescenta default (curinga)|/case event_t::LANDED_SIGNAL:    return state_t::IN_FLIGHT;/c\\        default: return s;"
  "M3|transição proibida InFlight+SystemCutoff -> Shutdown|/case event_t::SYSTEM_CUTOFF:    return state_t::IN_FLIGHT;/s/IN_FLIGHT/SHUTDOWN/"
  "M4|aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown)|0,/case event_t::TAKEOFF_SIGNAL:   return state_t::IN_FLIGHT;/s//case event_t::TAKEOFF_SIGNAL:   return state_t::SHUTDOWN;/"
  "M5|compara estado com constante de evento|s/^    switch (s) {\$/    if (s == event_t::TAKEOFF_SIGNAL) return state_t::SHUTDOWN;\\n    switch (s) {/"
  "M6|retorna valor fora da enumeração (42, via static_cast)|s/^    switch (s) {\$/    if (s == state_t::GROUNDED \\&\\& e == event_t::LANDED_SIGNAL) return static_cast<state_t>(42);\\n    switch (s) {/"
)
audit_stack cpp "Pilha 2 — C++17 (\`enum class\` + \`switch\`)" "$CXX" cpp "-std=c++17" "$HERE/src/fsm.cpp" "${CPP_VARS[@]}"

# --- C++17 moderno: std::variant + topologia nos tipos (novo nesta revisão) ---
TYPED_VARS=(
  "T0|baseline (sem defeito)|"
  "T1|omite o par InFlight+LandedSignal (sem curinga)|/State step(InFlight s, LandedSignal)/d"
  "T2|omite o mesmo par e acrescenta um gabarito genérico (curinga)|/State step(InFlight s, LandedSignal)/c\\template <class S, class E> State step(S s, E) { return s; }"
  "T3|transição proibida InFlight+SystemCutoff -> Shutdown|/State step(InFlight s, SystemCutoff)/s/go<InFlight>/go<Shutdown>/"
  "T4|aresta permitida, destino errado (Grounded+TakeoffSignal -> Shutdown)|/State step(Grounded s, TakeoffSignal)/s/go<InFlight>/go<Shutdown>/"
  "T5|usa um evento como destino (estado x evento)|/State step(Grounded s, CriticalBattery)/s/go<Grounded>/go<TakeoffSignal>/"
)
audit_stack typed "Pilha 3 — C++17 moderno (\`std::variant\` + topologia em \`static_assert\`)" "$CXX" cpp "-std=c++17" "$HERE/src/fsm_typed.cpp" "${TYPED_VARS[@]}"
{
  echo
  echo "T6 (valor fora da enumeração) não se aplica: com \`std::variant\` de tipos distintos não existe valor 42 do tipo de estado."
  echo
  echo "Pares que a tabela deixa como convenção do projeto (\`CONV\`) valem igualmente para as três pilhas: o estado não muda."
} >> "$MD"

echo
echo "matriz: $MD"
if [ "$BAD_BASELINE" -ne 0 ]; then echo "ATENÇÃO: alguma versão sem defeito (M0/M0/T0) tem aviso ou diverge da tabela"; exit 1; fi
echo "versões sem defeito: sem aviso e iguais à tabela."
