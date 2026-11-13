# Artigo 1 — *Compile-Time Transition Safety versus Exhaustive Testing in Composable Finite-State Machines*

Documento de adequação de 07/11/2026, tabela "Estratégia e conclusão": foco em Haskell, CREM, matriz de
rejeição de transições e comparação com C/C++. Destinos prioritários: **SBLP, Haskell Symposium, ICFP
(Experience Report)**. **Status: manuscrito escrito e formatado para o SCP em `10_artigo-scp/` (pendências no `CHECKLIST_SUBMISSAO.md` de lá).**

## Contribuição central (proposta, a validar com a orientação)

> Em um estudo de caso de 4 estados, restrições de topologia verificadas pelo compilador em CREM antecipam a
> detecção de transições proibidas e dispensam testes específicos para essas arestas. Um teste exaustivo em
> domínio finito detecta os mesmos defeitos, e outras construções de tipos (C++17) recusam a transição proibida
> na compilação; **nenhum compilador detectou o destino errado em aresta permitida**. A contribuição é delimitar
> o que a verificação de compilação antecipa, não afirmar que ela é exclusiva.

O que **não** é contribuição (documento de 07/11/2026): novo sistema de tipos, nova semântica formal, prova geral
de correção da composição. Perone e Karachalias (2023) introduziram o CREM; o texto precisa delimitar o acréscimo.

## Perguntas de pesquisa

* **A1.** Que classes de defeito de uma FSM são recusadas na compilação em CREM, e quais exigem teste?
* **A2.** O que um teste exaustivo em domínio finito acrescenta ou dispensa em relação à garantia de compilação?
* **A3.** O resultado depende da linguagem/construção de tipos (C `enum`, C++ `enum class`, C++17 tipado)?

## Hipóteses falsificáveis

* **HA1.** Toda transição fora da topologia é recusada pelo CREM na compilação. *Evidência:* matriz de 16 pares
  (8 compilam, 8 recusados, com a causa conferida) e mutantes H1 e H4.
* **HA2.** O CREM aceita destino errado em aresta permitida e evento trocado. *Evidência:* mutantes H2, H3.
* **HA3.** Uma construção de tipos em C++17 reproduz HA1. *Evidência:* variante T3 (**confirma**: o resultado
  enfraquece a alegação de exclusividade).

## Estrutura proposta

1. Introdução (problema, delimitação em relação a Perone e Karachalias, 2023).
2. Fundamentos (ADTs, singletons, `AllowedTransition`); só o necessário.
3. O estudo de caso e a especificação revisável (tabela `REQ`/`CONV`).
4. Método: matriz de rejeição, mutação, harness exaustivo, auditoria C/C++ (opções, versões).
5. Resultados (tabelas de `08_reprodutibilidade/logs/02_*`, `05_*`, `06_*`).
6. Discussão: o que a tipagem antecipa, o que não cobre (evento–destino), custo (diagnósticos, gabaritos).
7. Ameaças à validade (`AMEACAS_A_VALIDADE.md`).
8. Trabalho relacionado (depende de `07_estado-da-arte/PROTOCOLO_REVISAO.md`, **ainda não executado**).
9. Conclusão e lições (para a modalidade Experience Report do ICFP: o que a comunidade aprende).

## Evidências que já existem

| Evidência | Onde | Estado |
|---|---|---|
| Matriz de rejeição de 16 pares, causa conferida | `08_.../02_negative_matrix.md` | reproduzida (8/8/0) |
| Mutação do CREM (H1–H9) | `08_.../06_mutation_haskell.md` | executada: 9 mutantes, 0 vivos (2 recusados na compilação: H4 e H5; 7 aceitos pelo compilador e mortos por teste, entre eles o curinga H9) |
| Comparação C, C++ enum class, C++17 tipado | `08_.../05_c_cpp_matrix.md` | reproduzida e ampliada |
| Tamanho dos diagnósticos | `08_.../05_c_cpp_matrix.md` (coluna "Diagnóstico em A") e `08_.../02_negative_matrix.md` | medido pelos scripts (proxy) |

## O que falta antes de submeter

1. Estado da arte (melhoria 1): busca executada, tabela comparativa com Motor e typestate.
2. **Revisão externa de C/C++** (`05_c-cpp/REVISAO_EXTERNA_CHECKLIST.md`).
3. Outras topologias e escalas (melhoria 3): só há **uma** topologia de 4 vértices. Sem isso, não generalizar.
4. Estudo de esforço/manutenção (não medido): no máximo "diagnósticos" e "linhas de gabarito" como proxy.
5. Reconciliar o oráculo com a orientação (tabela revisada e assinada).
6. Artefato público e arquivado com identificador permanente; o repositório remoto era privado segundo o relatório v4.
7. Regras do destino sobre autoria e declaração de uso de IA (`DECLARACAO_USO_IA.md`).

## Cuidados de integridade

* Não reutilizar neste artigo os resultados de **comportamento global** do artigo 2 (lacuna borda x nível,
  alcançabilidade); citar o artigo 2 se necessário. Só dividir em dois artigos se cada um tiver contribuição
  distinta e substancial.
* Citar o parecer apenas como "orientação"; não tratá-lo como revisão por pares.
