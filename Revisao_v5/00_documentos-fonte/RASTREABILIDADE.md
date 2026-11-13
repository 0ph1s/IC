# Rastreabilidade: do parecer e do documento de adequação até esta pasta

Cada recomendação dos dois documentos, onde foi aplicada em `Revisao_v5/` e o estado real. Os documentos estão
neste diretório (`Parecer_tecnico_2026-11-03.pdf`, `Adequacao_publicacao_2026-11-07.pdf`).

**Legenda:** **feito** = há artefato e log reproduzível; **em parte** = feito o que dependia só do código, falta
pessoa ou ferramenta; **pendente** = não feito; **n/a** = informativo, nada a aplicar.

Caminhos abaixo são relativos a `Revisao_v5/`; `logs/` = `08_reprodutibilidade/logs/`.

## A. Parecer técnico de 03/11/2026

| § | Recomendação | Onde foi aplicada | Estado |
|---|---|---|---|
| 1 | Manter o simulador em Haskell; validar por modelo externo e testes independentes | `03_codigo/validation` (oráculo, Hedgehog, alcançabilidade) | **feito** |
| 1 | Adaptador de fronteira com decodificação, validação e testes de contrato | `Validation.Boundary`; `validation-boundary-tests` (21); 3 propriedades Hedgehog; relatório 5.15 | **feito** |
| 1 | Revisão técnica de propriedades, implementação e hipóteses | `spec/` com perguntas Q1–Q9; `01_plano/PLANO_DE_ACAO.md` | **pendente (orientação)** |
| 1 | Auditoria das versões e configurações de compilação de C/C++ | `05_c-cpp/` | **em parte** (revisor externo pendente) |
| 1 | Reutilizar QuickCheck State Machine, Hedgehog e exemplos públicos | Hedgehog usado; QSM, Motor e testes do repositório CREM **não** | **em parte** (`07_estado-da-arte/FERRAMENTAS.md`) |
| 1 | Documentar a semântica do simulador e confrontar com oráculo independente | `spec/POLITICAS.md`; `docs/simulador.md` do pacote base; `Validation.RefModel` | **feito** (oráculo do mesmo autor) |
| 1 | (Obs.) especificação e modelo escritos pelo mesmo pesquisador: erro de interpretação nos dois lados | `06_artigos/AMEACAS_A_VALIDADE.md`; relatório 5.16 e 5.20 | **declarado**; sem oráculo de terceiros |
| 2.1 | Preservar o simulador; documentar entradas, estados, tempo discreto e políticas; comparar com 2ª implementação ou especificação revisada | `POLITICAS.md`; oráculo; TLA+ | **em parte** |
| 2.2 | Limite de confiança explícito; a tipagem restringe arestas, não prova o destino semanticamente correto | relatório 5.15; Boundary | **feito** |
| 2.3 | C/C++ como comparação **controlada**, após revisão; evitar a conclusão ampla | relatório 5.18, resumo e conclusão; `05_c-cpp/AUDITORIA.md` (o C++17 tipado **enfraquece** a alegação) | **feito** (revisão externa pendente) |
| 3 | Seis recursos abertos com cuidados | `07_estado-da-arte/FERRAMENTAS.md` | **feito** (decisões registradas) |
| 4 | Diagrama da fronteira e exemplo `decodeEvent` | relatório Fig. 5.15; `Boundary.hs` | **feito** |
| 5, N1 | Preservar exaustividade com avisos promovidos a erro | `-Werror=incomplete-patterns`; mutante H5; `00_build_baseline.txt` (0 avisos) | **feito** |
| 5, N1 | Matriz origem × destino (16 pares, 8 aceitos e 8 rejeitados); não confundir com estado × evento | `negative_matrix.sh` (esperado derivado da tabela); relatório 5.16 | **feito** |
| 5, N1 | Testes que devem compilar e negativos que devem falhar, **conferindo a causa** | `logs/02_negative_matrix.md` (exatamente 1 erro, nomeando o par) | **feito** |
| 5, N1 | Mutação capaz de acusar arestas ilegais, destinos incorretos e eventos trocados | `validation/scripts/mutation.sh` (H1–H9) | **feito** (ver `logs/06_mutation_haskell.md`) |
| 5, N2 | Tabela de transições e políticas derivada dos requisitos, revisada pela orientação | `spec/transition_table.csv`, `power_table.csv`, `POLITICAS.md` | **em parte** (revisão pendente) |
| 5, N2 | Versão compacta em TLA+ verificada no TLC | `04_tla/` (TLC 2.19; `logs/14_tlc_*.txt`; `cross_check.py`) | **feito** |
| 5, N2 | Pressupostos de progresso explícitos (ticks futuros) | `AvionicsLoop.tla`: `WF` de `Step` e `Tick` | **feito** (na especificação) |
| 5, N2 | Propriedade: segurança da topologia (`InFlight` → `Shutdown`) | `logs/04_reach.txt` (520 arestas) ; TLA+ `NoDirectInFlightShutdown` | **feito** (Haskell e TLC) |
| 5, N2 | Propriedade: evento e destino (`TakeoffSignal` em `Grounded`) | `logs/07_conformance.txt` (D); TLA+ `EventDestination` | **feito** (Haskell e TLC) |
| 5, N2 | Propriedade: política de bateria (decolar com bateria crítica) | `logs/04_reach.txt` (seção 5); `scenarios/regressao_bateria_critica.scn`; TLC: `OneSlot` viola e `Level` satisfaz `NoPermanentBlindness` | **feito** (Haskell e TLC) |
| 5, N2 | Propriedade: composição (saídas da planta e do ambiente seguem o contrato a cada tick) | coberta **só indiretamente** pela equivalência passo a passo com o oráculo; contrato explícito não formalizado | **em parte** |
| 5, N2 | Propriedade: progresso/terminação da realimentação | `logs/04_reach.txt` (≤ 5 passos por tick); TLA+ `LoopTerminates`, `QueueBounded` | **feito** (Haskell e TLC) |
| 5, N3 | QSM ou Hedgehog para gerar eventos, executar em CREM e confrontar com o modelo; valor em diversidade, sementes e shrinking | `validation-model-tests`; `logs/03_model_hedgehog.txt` | **feito** |
| 5, N3 | Traço de regressão prioritário `Drain, Drain, TakeoffSignal, Idle, Idle` | `scenarios/regressao_bateria_critica.scn`; testes em Boundary e Model | **feito** |
| 6 | Revisar estados, eventos, regras e resultados esperados nas 3 linguagens | esperado vem de `transition_table.csv` | **em parte** (revisor pendente) |
| 6 | Reproduzir diagnósticos com opções publicadas; versões e saídas completas | `logs/05_c_cpp_matrix.md`, `05_c_cpp_raw.txt` | **feito** |
| 6 | Tratar separadamente `enum` (C) e `enum class` (C++) | pilhas 1 e 2 separadas | **feito** |
| 6 | Ao menos uma implementação moderna de C++; distinguir compilação, testes e análise estática | pilha 3 (`std::variant` + `static_assert`); colunas A/B/W/S/harness | **feito** |
| 6 | Mensurar esforço de teste, manutenção e legibilidade dos diagnósticos | tamanho de diagnóstico (proxy) | **em parte** (manutenção **não** medida) |
| 6 | Conclusão comparativa defensável (antecipação, não equivalência) | relatório 5.18 e resumo | **feito** |
| 7 | Contribuição: limites das garantias locais diante de comportamento global; verificar estado da arte antes de alegar ineditismo | relatório 1.2, 4 (ampliação), 5.17; protocolo | **feito** (texto); **busca de literatura pendente** |
| 7 | Reproduzir 87.381 cenários; 172 casos; 0 na política por nível; 5.841 estados finais diferentes | `logs/11_baseline_chain_tests.txt`, `12_baseline_policy_tests.txt` | **reproduzido** (87.381 cenários; 22.172 alcançam `EmergencyLanding`; 172 com bateria `Critical` e aviônica em voo; 0 na política por nível no alfabeto reduzido; 5.841 estados finais diferentes; 8.726 cenários com descarte) |
| 7 | Pergunta de pesquisa sugerida | relatório 1.2 (idêntica, mais PP1–PP4) | **feito** |
| 8 | Plano de ação (6 etapas) e pauta | `01_plano/PLANO_DE_ACAO.md` | **feito** (como documento) |
| 9 | Recursos públicos; confirmar manutenção, licença, versão e compatibilidade | `FERRAMENTAS.md` (só Hedgehog 1.7 + GHC 9.6.7 confirmado) | **em parte** |

Nota sobre a linha "Reproduzir 87.381...": os números do relatório v4 foram conferidos nos logs 09 a 12 gerados por
`run_all.sh` (16 verificações de conformidade, 32 do simulador, 87.381 cenários nos testes de cadeia e de políticas).
**Ressalva:** o parecer lê o 5.841 como "alteração relevante de comportamento"; a caracterização caso a caso desses estados
finais não foi feita (o relatório v4 já dizia isso).

## B. Documento de adequação para publicação de 07/11/2026

| Seção | Recomendação | Onde foi aplicada | Estado |
|---|---|---|---|
| Diagnóstico | Enquadrar como estudo de garantias estáticas e validação, **não** sobre UAVs | relatório: nota, resumo, introdução ("Enquadramento"), 1.2 | **feito** (título da proposta **não** alterado) |
| Diagnóstico | Delimitar a contribuição em relação a Perone e Karachalias (2023): sem novo sistema de tipos, nova semântica formal ou prova geral; 168.421 cenários não provam sequências arbitrariamente longas | relatório 1.3.4 (contribuições) e 4; alcançabilidade (5.17) trata o ponto para o modelo | **feito** |
| Pontos fortes | Matriz 8/8 de 16; leis de Functor/Applicative/Monad; 5 construtores; 168.421 e 87.381 cenários; comparação C/C++; lacuna borda × nível | reproduzidos por `run_all.sh` (logs 09–12, 02, 05) | **feito** |
| Destinos | JFP e SCP (periódicos); SBLP, SBMF, Haskell Symposium (conferências) | `06_artigos/VENUES_E_PRAZOS.md` | **feito** (não reconferido em chamadas) |
| Prazos | ICFP 2027 (25/02/2027) a mais concreta | `VENUES_E_PRAZOS.md`, **atualizado para 13/11/2026** (FormaliSE e PLDI já encerraram) | **feito** |
| Classificações | Planilhas divergem em FACS, TACAS, ISSRE, GPCE; conferir o estrato | `VENUES_E_PRAZOS.md` | **feito** (conferência externa pendente) |
| Melhorar 1 | Ampliar o estado da arte | `07_estado-da-arte/PROTOCOLO_REVISAO.md`; relatório seção 4 | **em parte** (**busca não executada**) |
| Melhorar 2 | Fortalecer a contribuição: perguntas, hipóteses, resultados próprios | relatório 1.2; `ARTIGO_2` | **feito** (texto e evidências) |
| Melhorar 3 | Outras topologias, escalas, cenários, implementações; esforço, manutenção, diagnósticos | alfabeto completo e fechamento do grafo; cenários até 60 ticks; C++17 tipado; tamanho de diagnóstico | **em parte** (**outras topologias, escalas e manutenção: não feito**) |
| Melhorar 4 | Separar contexto pedagógico de resultados novos; scripts reprodutíveis; ameaças à validade; autoria e declaração de IA | `run_all.sh`; `AMEACAS_A_VALIDADE.md`; `DECLARACAO_USO_IA.md`; relatório DECLARAÇÕES | **em parte** (separação pedagógica do texto e confirmação do autor pendentes) |
| Estratégia | Dividir em dois artigos só se cada um tiver contribuição distinta | `ARTIGO_1_*.md` e `ARTIGO_2_*.md`, com cuidados de integridade | **feito** (esqueletos) |
| Conclusão | Priorizar SBLP e Haskell Symposium, depois SBMF e FormaliSE; Experience Report do ICFP a avaliar | `VENUES_E_PRAZOS.md` | **feito** (decisão é da orientação) |

## C. O que esta pasta **não** faz

* Não altera o relatório v4, o código nem as notas existentes do repositório IC; não faz commit.
* Não executa a busca de literatura nem a revisão externa de C/C++. (O TLC foi executado.)
* Não substitui a aprovação da tabela pela orientação.
* Não verifica prazos e classificações em fontes oficiais.
