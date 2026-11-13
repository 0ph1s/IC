# Artigo 2 — *Limits of Type-Level Transition Guarantees in Composable State Machines: A Closed-Loop Case Study*

Documento de adequação de 07/11/2026: foco em composição, testes de propriedades, modelo de referência,
realimentação, descarte de eventos e políticas de bateria crítica. Destinos prioritários: **SBMF, FormaliSE,
SEFM, FACS** e, com resultados ampliados, **SCP**. **Status: esqueleto; nenhum texto de submissão foi escrito.**

## Pergunta de pesquisa (do parecer de 03/11/2026, seção 7)

> Em que medida as garantias estáticas de transição oferecidas pelo CREM asseguram propriedades globais de
> máquinas de estados componíveis, e quais técnicas complementares são necessárias para verificar o comportamento?

Desdobrada em: o que a tipagem garante (arestas); o que exige contratos de evento–destino; o que depende de
verificação temporal.

## Contribuição proposta (a validar)

> Com todas as arestas corretas e todos os testes de aresta passando, a composição em malha fechada ainda pode
> ter uma propriedade global violada (o sistema pode ficar "cego" para sempre à bateria crítica), por causa de uma
> escolha do ambiente (reagir à *borda*, não ao *nível*) e do descarte com o slot ocupado. A garantia local do
> tipo não implica a global; a exploração exaustiva do grafo de estados (finito, 26 ternos alcançáveis) detecta
> o problema para **qualquer comprimento de sequência**, e confirma que a política `Level` o elimina, no modelo.

Esta formulação desloca o foco de "o compilador aceita ou rejeita uma aresta?" para "quais propriedades são
garantidas pela tipagem, quais exigem contratos evento–destino e quais dependem de verificação temporal?".

## Hipóteses falsificáveis

* **HB1.** A tipagem por aresta não implica `NoPermanentBlindness`. *Evidência:* `validation-reach-tests`
  (2 estados alcançáveis cegos em OneSlot, a 3 ticks; 0 em Level).
* **HB2.** O descarte do slot altera o estado final quando o alfabeto inclui ticks com comando e energia juntos.
  *Evidência:* produto OneSlot × Queue no alfabeto completo (232 de 282 pares diferem; menor caso com 4 ticks).
  *Corrige* a leitura "o descarte é inócuo" da v4, que valia só para o alfabeto reduzido e N = 8.
* **HB3.** A implementação em CREM é equivalente ao oráculo guiado por tabela para todas as sequências, sob a
  hipótese de abstração (o estado entre ticks é o terno de vértices). *Evidência:* mesmos estados e arestas, e a
  abstração conferida em 8 421 cenários.

## Estrutura proposta

1. Introdução e delimitação (sem novo sistema de tipos; sem prova geral de correção da composição).
2. Estudo de caso: aviônica ‖ energia, ambiente de um slot, `Feedback` (instantâneo; atraso de um tick por modelagem).
3. Especificação: tabelas revisáveis, políticas, TLA+ (executada no TLC).
4. Verificação em três níveis: estática, especificação/model checking, testes baseados em modelo.
5. Resultados: equivalência, alcançabilidade, achados, regressão prioritária, mutantes e shrinking.
6. Discussão: contrato evento–destino, propriedades temporais, relação com tipos dependentes e typestate (**depende do estado da arte**).
7. Ameaças à validade; limites (pares CONV, ambiente é escolha de modelagem, sem requisitos reais de aviônica).

## Evidências que já existem

| Evidência | Onde | Estado |
|---|---|---|
| Equivalência CREM × oráculo para todas as sequências | `08_.../04_reach.txt` | reproduzida (12 verificações) |
| Testes baseados em modelo, 18 verificações, sementes impressas | `08_.../03_model_hedgehog.txt` | reproduzida |
| Regressão prioritária `Drain, Drain, TakeoffSignal, Idle, Idle` | `03_codigo/validation/scenarios/` | reproduzida |
| Especificação TLA+ executada no TLC (1 143 estados; `OneSlot` viola `NoPermanentBlindness`, `Level` satisfaz; mesmos 26 ternos que o Haskell) | `08_.../14_tlc_*.txt` | reproduzida |
| Oráculo revisado por terceiros | — | **não existe** |

## O que falta antes de submeter

1. (feito) TLC rodado e reconciliado com o Haskell (`04_tla/README.md`).
2. Revisão da tabela e das políticas pela orientação (perguntas Q1–Q9 em `spec/`).
3. **Requisitos reais** para o ambiente: hoje ele é escolha de modelagem. PX4 como segundo caso exigiria reconciliar requisitos.
4. Outras topologias e escalas (só há uma). Sem isso, o resultado é um estudo de caso, não uma regra geral.
5. Estado da arte (typestate, verificação de composições): sem ele não há alegação de ineditismo.
6. Para SCP: resultados ampliados (outros casos, esforço de verificação).

## Cuidados de integridade

* Não reutilizar o material do artigo 1 (matriz de rejeição, comparação C/C++).
* O 'achado' é uma propriedade **do modelo do projeto**; não é um defeito do CREM nem do GHC. Dizer isso no título,
  no resumo e na discussão.
