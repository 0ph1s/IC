# Auditoria da comparação com C e C++ (parecer de 03/11/2026, seção 6)

**Status: reproduzida e ampliada por quem escreveu o experimento; revisão externa PENDENTE.** O parecer
pede revisão externa porque o discente relata pouca experiência em C/C++, e o risco é "equivalências
incorretas ou implementações injustamente fracas". Esta auditoria reduz o risco (scripts reprodutíveis,
versões registradas, opções publicadas, uma implementação moderna acrescentada), mas **não substitui** um
revisor de C/C++: ver `REVISAO_EXTERNA_CHECKLIST.md`.

Resultados completos e reproduzíveis: `08_reprodutibilidade/logs/05_c_cpp_matrix.md` (gerado por
`bash 05_c-cpp/scripts/audit.sh`). Compilador: clang 14.0.6 (o que acompanha o GHC 9.6.7), Windows 11.

## O que o parecer pediu e o que foi feito

| Pedido (seção 6) | Feito | Observação |
|---|---|---|
| Revisar estados, eventos, regras e resultados esperados nas três linguagens | **parcial** | O esperado agora vem de `spec/transition_table.csv` (16 triplos), e não de `domain_rules.txt`; as três pilhas imprimem os mesmos 16 triplos. Falta o revisor externo. |
| Reproduzir diagnósticos com opções publicadas; documentar versões e saídas completas | **sim** | Opções A, B, W e S registradas no cabeçalho de cada tabela; versão do clang; `05_c_cpp_raw.txt` guarda as primeiras linhas de cada diagnóstico. |
| Tratar separadamente `enum` em C e `enum class` em C++ | **sim** | Pilhas 1 e 2 separadas, com os mesmos sete defeitos. |
| Considerar ao menos uma implementação moderna de C++ | **sim** | Pilha 3: `std::variant` + `std::visit` + topologia em `static_assert`. |
| Distinguir compilação, testes e análise estática | **sim** | Colunas A/B/W (compilação), S (`clang --analyze`) e harness exaustivo (teste). |
| Mensurar esforço de teste, manutenção e legibilidade dos diagnósticos | **só proxy** | Tamanho dos diagnósticos (abaixo). Esforço de manutenção **não** foi medido. |

## Resultado (resumo; a tabela completa está no log)

| Defeito | C `enum` (A / W / S / teste) | C++ `enum class` (idem) | C++17 tipado | Haskell/CREM |
|---|---|---|---|---|
| M1/T1 par omitido, sem curinga | aviso / **recusa** / silêncio / passa | aviso / **recusa** / silêncio / passa | **recusa** (erro de `std::visit`) | recusa (`-Werror=incomplete-patterns`) |
| M2/T2 par omitido + curinga | silêncio (B: aviso) / **recusa** (W) / silêncio / passa | idem | **silêncio** / passa | curinga esconde (v4) |
| M3/T3 transição **proibida** | silêncio / silêncio / silêncio / **detecta** | idem | **recusa** (`static_assert`) | **recusa** (`AllowedTransition`) |
| M4/T4 destino errado em aresta **permitida** | silêncio / silêncio / silêncio / **detecta** | idem | silêncio / **detecta** | **compila**; só teste detecta |
| M5/T5 estado confundido com evento | silêncio / silêncio / silêncio / detecta só por coincidência numérica | **recusa** (tipos distintos) | **recusa** | recusa (tipos) |
| M6 valor fora da enumeração | silêncio / silêncio / silêncio / detecta | silêncio (`static_cast`) / **detecta** | não se aplica | recusa (tipos) |

A coluna Haskell/CREM resume as seções 5.9 e 5.14 do relatório e os mutantes H1 a H8 de
`08_reprodutibilidade/logs/06_mutation_haskell.md` (ver o relatório v5, seção 5.17).

## O que isto muda na conclusão comparativa

1. **A generalização "só o Haskell antecipa a transição proibida" não se sustenta.** Em C++17, com
   `std::variant` e um traço `Allowed` de cerca de 10 linhas, a transição proibida (T3) é **recusada na
   compilação**, como no CREM. A conclusão defensável do parecer vale: *certas restrições de topologia são
   verificadas na compilação em CREM; isso antecipa a detecção e dispensa testes específicos para essas
   arestas*, mas outras construções de tipos podem fazer o mesmo.
2. **Promover avisos a erro (W) é a comparação justa com `-Werror=incomplete-patterns`.** A versão A/B da v4 deixava
   o C só "avisando"; com `-Werror`, M1 e M2 também são recusados.
3. **Nenhum compilador, em nenhuma linguagem, detecta o destino errado em aresta permitida (M4/T4).** Isso vale para
   CREM e para o C++ tipado, e é a fronteira da garantia por aresta: exige especificação com eventos.
4. **O curinga é o ponto fraco comum:** M2 em C/C++ (com `default`) e T2 em C++ tipado (gabarito genérico) escondem a omissão
   sem aviso nas opções A e, no caso T2, em todas.
5. **O analisador estático (`clang --analyze`) não acusou nenhum dos defeitos** que compilam. Isso vale para este
   analisador, nesta versão, com estas opções; não é um resultado sobre análise estática em geral.
6. **Custo da recusa em C++ tipado:** o erro de T3 tem 7 linhas, mas o de T1 (par omitido em `std::visit`) tem 236 linhas
   (cerca de 36 KB) de mensagens de gabarito. O erro do CREM para `InFlight -> Shutdown` tem 25 linhas (1,6 KB).

## Proxy de legibilidade dos diagnósticos (tamanho, medido)

| Diagnóstico | Linhas | Bytes |
|---|---|---|
| C, M1 (`-Wswitch`) | 4 | 217 |
| C++ `enum class`, M5 (tipos distintos) | 4 | 276 |
| C++ tipado, T3 (`static_assert`, transição proibida) | 7 | 642 |
| C++ tipado, T5 (evento como destino) | 25 | 2 388 |
| Haskell/CREM, `InFlight -> Shutdown` (`Could not deduce AllowedTransition`) | 25 | 1 637 |
| C++ tipado, T1 (par omitido em `std::visit`) | 236 | 35 863 |

Tamanho **não é** legibilidade: não houve leitura por terceiros nem tarefa de depuração cronometrada. É só um
limite superior do que o leitor precisa percorrer.

## Limites desta auditoria

* Uma única máquina (4 estados, 4 eventos), um único compilador (clang 14.0.6) e um único sistema (Windows 11).
  GCC e MSVC não foram usados. `clang-tidy` não está disponível na instalação do GHC; só `--analyze`.
* Os defeitos são **injetados por mim** (sed sobre o fonte) a partir dos seis defeitos (M1 a M6) da v4, mais cinco novos (T1 a T5) para C++ tipado;
  não há amostra de defeitos reais.
* A implementação C++ tipada é a **minha** escolha de como um C++ moderno faria; outra escolha de projeto (por exemplo
  tabelas `constexpr` ou bibliotecas de máquinas de estado) pode mudar o resultado.
* Nenhuma medida de esforço de manutenção ou de tempo de compilação foi feita (o Template Haskell do CREM e os gabaritos
  do C++ têm custo de compilação não medido).
* A pilha em C usa o padrão do compilador (`gnu17`); a variação `-std=c11 -pedantic` não foi testada.
