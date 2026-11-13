# Destinos de publicação e prazos

Fonte: documento de adequação de 07/11/2026 ("Adequação para publicação científica"), que cita o
levantamento analisado em 03/11/2026. **Nada aqui foi reconferido em chamadas oficiais nesta revisão.**
Os estratos Qualis são transcrições das planilhas do projeto (a própria fonte avisa que não validam a
classificação CAPES vigente, e que a lista de 192 conferências usa CORE, outra metodologia). Aderência
temática **não** equivale a probabilidade de aceitação.

## Prazos, atualizados para 13/11/2026 (data desta revisão)

| Evento | Prazo (segundo a fonte) | Situação em 13/11/2026 | Ação |
|---|---|---|---|
| FormaliSE 2027 | resumo 30/10/2026; artigo 06/11/2026 | **encerrado há 7 dias** (a própria fonte já dizia "resumo encerrado; verificar elegibilidade") | descartar para esta rodada; acompanhar a próxima edição |
| PLDI 2027 | 12/11/2026 | **encerrou ontem**; exigência científica elevada | descartar |
| ETAPS 2027 (iFS, TACAS, ESOP) | 15/10/2026 | encerrado | descartar |
| POPL 2027 | artigos principais encerrados | encerrado | considerar edições futuras |
| **ICFP 2027** | **25/02/2027** | **104 dias**; "oportunidade futura; avaliar a modalidade Experience Report" | **única janela concreta**: confirmar a chamada e as regras do Experience Report |
| Haskell Symposium 2027 | não confirmado | acompanhar | monitorar a chamada |
| SBLP 2027 | não confirmado (previsto em Belo Horizonte) | acompanhar | monitorar a chamada |
| SBMF (próxima) | não confirmado para 2027 | acompanhar | monitorar a chamada |
| SE4FP (workshop) | edição de 2026 já ocorreu; sem chamada para 2027 | acompanhar | artigo curto (até 5 páginas) sobre a experiência com o CREM |

Em 2027, FASE e iFM foram reunidas na iFS (ETAPS): não tratar as siglas antigas como eventos separados nem
transferir suas classificações à iFS.

## Estratos conforme as duas planilhas do projeto

As planilhas **divergem** em FACS (B2 × A3), TACAS (A1 × A2), ISSRE (A2 × A3) e GPCE (B1 × B3). Conferir
o estrato antes de decidir. SBLP, SBMF (A4), SEFM (A3), ICFEM (A4), CAV (A1), SAST e SBCARS (B1) coincidem.
FormaliSE, ICFP, PLDI e POPL não constam na planilha de eventos 2025. Siglas ambíguas pedem o nome completo
(FSE = Fast Software Encryption; ICST = International Conference on Sensing Technology).

## Periódicos (aderência e enquadramento segundo a fonte)

| Periódico | Aderência | Enquadramento para o manuscrito |
|---|---|---|
| Journal of Functional Programming (JFP) | muito alta | Tools and Applications ou experiência e limites de garantias estáticas; exige contribuição reutilizável |
| Science of Computer Programming (SCP) | muito alta | avaliação experimental de máquinas de estados tipadas contra implementações convencionais |
| Formal Aspects of Computing (FAC) | alta | propriedades garantidas pelo sistema de tipos contra as que dependem de validação dinâmica |
| JLAMP | alta, mais exigência teórica | propriedades formais da composição; provavelmente exige novos resultados formais |
| Software: Practice and Experience (SPE) | alta, para relato de experiência | comparativo Haskell, C e C++ (esforço, complexidade, manutenibilidade) |
| SoSyM | sexta opção | se o foco migrar para modelagem formal, composição e refinamento |

## Ordem recomendada pela fonte

1. SBLP e Haskell Symposium; 2. SBMF e FormaliSE; entre periódicos, JFP e SCP como referência para a evolução do
manuscrito. A modalidade Experience Report do ICFP 2027 "acolhe experiência técnica sem exigir nova teoria, mas
ainda precisa oferecer lições úteis à comunidade". O caminho mais sólido: convergir para **uma** contribuição
central bem demonstrada e só depois adaptar o texto ao destino.

## Mapa artigo × destino

| Artigo | Destinos prioritários |
|---|---|
| 1. *Compile-Time Transition Safety versus Exhaustive Testing…* | SBLP, Haskell Symposium, ICFP (Experience Report) |
| 2. *Limits of Type-Level Transition Guarantees…* | SBMF, FormaliSE, SEFM, FACS e, ampliado, SCP |

## Lembrete de calendário

Para submeter ao ICFP 2027 (25/02/2027) com o artigo 1 como Experience Report, os pré-requisitos são:
estado da arte executado, revisão externa de C/C++, tabela revisada pela orientação, artefato público e arquivado.
Contando para trás de 25/02/2027: fechar o texto até fim de janeiro de 2027 deixa quase quatro semanas de folga.
