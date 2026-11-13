# O que mudou do relatório v4 para o v5

`ProgressoParcial_v5.tex` foi gerado **uma vez** do `ProjectPapers/ProgressoParcial_v4.tex` por um script (não mantido) que confere cada âncora
e falha se uma não existir; o v4 não foi alterado. A partir daqui, o `.tex` do v5 é um arquivo comum, para editar à mão. O texto de 1 a 3 e de 5.1 a 5.14 é o do v4, com os acréscimos abaixo. PDF: `ProgressoParcial_v5.pdf`.

## Mudanças de enquadramento (documento de 07/11/2026)

| Onde | Mudança |
|---|---|
| Nota sobre a versão (nova, antes do resumo) | explica o que mudou e o que está pendente; marcada "remover antes da entrega" |
| Resumo | reescrito: estudo de garantias estáticas e de validação; UAV como domínio de exemplo; resultados novos; limites e pendências |
| Abreviaturas | PBT, PP, TLA+/TLC |
| 1, "Enquadramento" (novo parágrafo) | o trabalho não é sobre aeronaves; não é novo sistema de tipos, nem semântica formal, nem prova geral |
| **1.2 Perguntas de pesquisa (nova)** | pergunta reformulada (parecer, seção 7), PP1 a PP4 e hipóteses falsificáveis H-A, H-B, H-C |
| 1.3.4 Contribuições | acrescentadas (v), (vi), (vii); delimitação explícita; 168.421 cenários não provam sequências longas |
| Tabela de objetivos | nova linha: validação independente e fronteira tipada |
| 4 Estado da arte | nova subseção: protocolo de ampliação (**busca não executada**), candidatos, sem alegação de ineditismo |

## Mudanças de conteúdo (parecer de 03/11/2026)

| Onde | Mudança |
|---|---|
| 5 (introdução) | aponta as seções 5.15 a 5.19 e o pacote `avionics-validation` |
| 5.12 | tabela de 16 linhas com origem `REQ`/`CONV` |
| **5.13** | **correção sinalizada**: "o descarte do slot é inócuo" só vale para o alfabeto reduzido |
| 5.14 | aponta a auditoria; a conclusão muda (C++17 tipado também recusa a transição proibida) |
| **5.15 (nova)** | fronteira de integração tipada: figura, `decodeEvent`, contrato, testes |
| **5.16 (nova)** | arquitetura de validação em três níveis; as duas matrizes que não se confundem; tabela revisável; oráculo; TLA+ |
| **5.17 (nova)** | resultados: suítes, alcançabilidade, política da bateria para todas as sequências, correção do descarte, Hedgehog, mutantes e shrinking, mutação do CREM |
| **5.18 (nova)** | auditoria de C e C++ (três pilhas; opções A/B/W; análise estática; diagnósticos) |
| **5.19 (nova)** | ameaças à validade (construto, interna, externa, conclusão, procedência) |
| 5.20 (antiga 5.15) | Limitações; acrescentadas a 11ª a 14ª; referências "seção 5.15" renumeradas para 5.20 |
| 5.21 (antiga 5.16) | Síntese: duas linhas na tabela de evidência; H-A, H-B, H-C |
| Cronograma | tabela "Plano de ação da versão 5" com a situação dos seis passos do parecer |
| Declarações | disponibilidade de código; uso de IA deixado em branco, a definir com a orientação externa |
| Referências | acrescentadas as citadas na nova subseção (Claessen e Hughes; Lamport; Strom e Yemini; Hedgehog; Motor; QSM; TLA+) — as de periódicos marcadas "dados a conferir" |
| Apêndice A | **corrige um erro do v4** (`\texttt{ab02fea}` saía como "exttt{ab02fea}" por um `\t` engolido) e acrescenta a reprodução da v5 |

## O que NÃO foi mudado de propósito

* Título e subtítulo da proposta (`\titulo`, `\subtitulo`): é decisão da orientação mudar o título de um projeto aprovado.
* O texto das seções 1 a 3 (redação da proposta) e 5.1 a 5.11.
* Os números do v4 (87.381 cenários, 172, 5.841): são reproduzidos pelas suítes do pacote base (`logs/11_*`, `12_*`).

## Pendências no texto

* Confirmar os dados bibliográficos marcados "a conferir".
* Remover a "Nota sobre esta versão" na versão final.
* Preencher CRediT, conflito de interesses e financiamento (já eram pendentes no v4).
* Rever o texto novo (foi escrito com assistência de IA).
