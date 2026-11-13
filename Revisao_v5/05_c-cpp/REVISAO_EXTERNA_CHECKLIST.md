# Lista para o revisor externo de C/C++

O parecer de 03/11/2026 (seção 6 e pauta da reunião) pede "definir quem revisará C/C++". **Revisor: não
definido.** Esta lista é o que ele deve conferir; cada item marcado "pendente" só passa a "ok" com a assinatura
do revisor e a data.

Material: `05_c-cpp/src/*`, `05_c-cpp/scripts/audit.sh`, `08_reprodutibilidade/logs/05_c_cpp_matrix.md` e
`03_codigo/validation/spec/transition_table.csv` (o esperado).

| # | Pergunta | Onde | Situação |
|---|---|---|---|
| 1 | As três implementações (`fsm.c`, `fsm.cpp`, `fsm_typed.cpp`) realizam exatamente a tabela de 16 pares? | `src/` e harness | pendente |
| 2 | O estilo `enum` + `switch` é um representante razoável do que um desenvolvedor de C usaria, ou a versão está "injustamente fraca"? | `src/fsm.c` | pendente |
| 3 | `enum class` + `switch` em C++17 é representativo? Há idioma mais comum (por exemplo tabela `constexpr` de transição)? | `src/fsm.cpp` | pendente |
| 4 | A versão tipada (`std::variant` + `Allowed` + `static_assert`) é C++ moderno idiomático? Um C++20 com `concept`s ou `consteval` seria mais justo? | `src/fsm_typed.cpp` | pendente |
| 5 | As opções A, B, W estão bem escolhidas? Faltam `-Wcovered-switch-default`, `-Wunreachable-code`, `-Wconversion`, `-fsanitize=*`? | `scripts/audit.sh` | pendente |
| 6 | Os seis defeitos M1–M6 e os cinco T1–T5 são representativos? Que classes de defeito reais de FSM em C/C++ faltam? | `scripts/audit.sh` | pendente |
| 7 | O resultado muda com GCC ou MSVC? (só clang 14.0.6 foi usado) | — | pendente |
| 8 | Outro analisador (clang-tidy, cppcheck, Coverity) detectaria M3/M4? (só `clang --analyze` foi usado) | — | pendente |
| 9 | O harness exaustivo é um "teste" justo para o C/C++, ou um framework (Catch2, GoogleTest) mudaria o esforço? | harness em `main` | pendente |
| 10 | A conclusão da seção 5.18 do relatório v5 está de acordo com o que o revisor observa? | relatório v5 | pendente |

**Revisor:** ______________________   **Data:** ____________   **Observações:** ______________________
