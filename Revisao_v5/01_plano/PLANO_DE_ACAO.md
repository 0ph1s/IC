# Plano de ação para a orientação (parecer de 03/11/2026, seção 8)

Os seis passos do parecer, com o **entregável verificável**, o que foi feito nesta revisão (13/11/2026), a
evidência e o que **continua pendente**. Status honesto: só consta "feito" o que tem log reproduzível em
`08_reprodutibilidade/logs/`.

| # | Ação do parecer | Entregável exigido | Situação | Evidência | Pendência |
|---|---|---|---|---|---|
| 1 | Congelar a versão e reproduzir os experimentos atuais | Log de build, lista de testes positivos e negativos, versão do GHC e dependências | **feito** | instantâneo `9689ce8` com `MANIFEST.sha256`; `01_build_clean.txt` (compilação limpa, 0 avisos do GHC, refeita a cada `run_all.sh`); `run_all.sh`; `cabal.project.freeze` | repetir em outra máquina |
| 2 | Revisar requisitos e separar o oráculo do código | Tabela de transições e propriedades **aprovada na orientação** | **em parte** | `spec/transition_table.csv` (16 linhas, `REQ`/`CONV`), `power_table.csv`, `POLITICAS.md`; oráculo `Validation.RefModel` guiado por elas; `07_conformance.txt` | **aprovação da orientação** (perguntas Q1 a Q9) |
| 3 | Adotar QuickCheck State Machine ou Hedgehog | Geradores, casos mínimos e relatório de divergências | **feito com Hedgehog** | `03_model_hedgehog.txt` (18 verificações, mutantes reduzidos pelo shrinking, regressão prioritária) | QuickCheck State Machine não testado |
| 4 | Criar especificação compacta em TLA+/TLC | Invariantes, estados alcançáveis e contraexemplos, se existirem | **feito** | `04_tla/AvionicsLoop.tla`; `logs/14_tlc_*.txt` (1 143 estados; `OneSlot` viola `NoPermanentBlindness` com contraexemplo; `Level` satisfaz tudo); conferência cruzada com `04_reach.txt`: mesmos 26 ternos | revisão da orientação sobre as propriedades |
| 5 | Auditar versões em C e C++ | Matriz comparativa reproduzível e revisão de linguagem | **em parte** | `05_c_cpp_matrix.md` (3 pilhas, opções A/B/W, análise estática, harness) | **revisor externo** (`05_c-cpp/REVISAO_EXTERNA_CHECKLIST.md`) |
| 6 | Reescrever a contribuição do artigo | Questão de pesquisa, evidências, limites e ameaças à validade | **em parte** | `02_relatorio/ProgressoParcial_v5.pdf` (1.2, 5.15 a 5.19); `06_artigos/` | busca de literatura; outras topologias; decisão da orientação sobre o recorte |

## Nível 1 do parecer (verificação estática) — o que foi feito

| Pedido | Feito |
|---|---|
| preservar testes de exaustividade com avisos promovidos a erro | já em `-Werror=incomplete-patterns`; reproduzido (compilação limpa sem avisos, `01_build_clean.txt`) e testado por mutação (par omitido, H5; curinga, H9) |
| registrar testes que devem compilar e testes negativos que devem falhar, **conferindo a causa** | `negative_matrix.sh`: 8 compilam, 8 rejeitados, cada um com exatamente 1 erro `Could not deduce AllowedTransition ... <par>` |
| não confundir a matriz origem × destino com a matriz estado × evento | explicado na seção 5.16 do relatório v5 |
| manter mutação capaz de acusar arestas ilegais, destinos incorretos e eventos trocados | `mutation.sh` (H1 a H9) em cópia temporária; `06_mutation_haskell.md` |

## Pauta recomendada para a próxima reunião (parecer, seção 8)

| Item da pauta | Onde está o material | Decisão necessária |
|---|---|---|
| Confirmar que o UAV é só um exemplo discreto, sem promessa de segurança de voo | relatório v5, nota, 1 e 1.2 | confirmar o enquadramento (o título da proposta **não** foi alterado) |
| Revisar os 16 pares da topologia e as diferenças entre evento, aresta e propriedade temporal | `spec/transition_table.csv`; relatório 5.16 | responder Q1 a Q3 (aviônica), Q4 a Q5 (energia), Q6 a Q9 (ambiente) |
| Escolher um oráculo independente e a primeira ferramenta de testes | `07_estado-da-arte/FERRAMENTAS.md` | validar Hedgehog como primeira ferramenta; decidir se o oráculo de terceiros será a própria orientação |
| Definir critérios de conclusão e quem revisará C/C++ | `05_c-cpp/REVISAO_EXTERNA_CHECKLIST.md` | **nomear o revisor** |
| Escolher o recorte científico e registrar limitações não tratadas | `06_artigos/` (dois artigos), `AMEACAS_A_VALIDADE.md` | escolher **uma** contribuição central; decidir se divide em dois artigos |

## Decisões do documento de 07/11/2026 que dependem de pessoas

1. Aprovar a tabela e as políticas (passo 2).
2. Nomear o revisor de C/C++ (passo 5).
3. Escolher o destino prioritário. A única janela concreta é o **ICFP 2027 (25/02/2027, Experience Report)**;
   FormaliSE (06/11/2026) e PLDI (12/11/2026) já encerraram (`06_artigos/VENUES_E_PRAZOS.md`).
4. Confirmar autoria, papéis e a declaração de uso de IA (`06_artigos/DECLARACAO_USO_IA.md`).
5. Tornar público e arquivar o repositório com identificador permanente (o relatório v4 registra que ele era privado).

## Critério de conclusão sugerido por etapa

| # | Concluído quando |
|---|---|
| 1 | `bash 08_reprodutibilidade/run_all.sh` termina em "TUDO OK" em uma segunda máquina |
| 2 | ata da reunião com a resposta às perguntas Q1 a Q9 e a tabela com o status "aprovada" e a data |
| 3 | geradores revisados; contraexemplos mínimos documentados; decisão sobre QSM |
| 4 | **atendido**: saídas completas do TLC arquivadas e reconciliadas com `04_reach.txt` (`14_tlc_crosscheck.txt`) |
| 5 | checklist assinado pelo revisor; conclusão da seção 5.18 ajustada ao que ele observou |
| 6 | texto do artigo escolhido com estado da arte executado, outras topologias e revisão da orientação |
