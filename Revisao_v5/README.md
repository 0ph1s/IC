# Revisao_v5 — aplicação do parecer de 03/11/2026 e do documento de adequação de 07/11/2026

Pasta **isolada**: tudo o que foi feito para aplicar os dois documentos está aqui, para não se misturar ao
progresso atual do projeto (relatório v4, `Code/`, `Obsidian/`, `Projects/` etc., que **não foram alterados**).
Nada foi commitado. Para voltar ao estado anterior basta apagar esta pasta.

| Pasta | Conteúdo | Comece por |
|---|---|---|
| `00_documentos-fonte/` | os dois PDFs e a **rastreabilidade** (cada recomendação → onde foi aplicada → estado) | `RASTREABILIDADE.md` |
| `01_plano/` | plano de ação em 6 etapas, pauta da reunião, decisões que dependem de pessoas | `PLANO_DE_ACAO.md` |
| `02_relatorio/` | **relatório v5** (`.tex` e `.pdf`, 51 páginas) e a lista do que mudou em relação ao v4 | `MUDANCAS_v4_para_v5.md` |
| `03_codigo/` | projeto cabal: instantâneo **congelado** de `avionics-crem` + pacote novo `avionics-validation` | `README.md` da pasta |
| `04_tla/` | especificação TLA+ do laço fechado, **executada no TLC** (confirma o Haskell: mesmos 26 ternos) | `README.md` da pasta |
| `05_c-cpp/` | auditoria reprodutível de C, C++ e C++17 tipado; lista para o revisor externo | `AUDITORIA.md` |
| `06_artigos/` | esqueletos dos dois artigos, destinos e prazos, ameaças à validade, declaração de uso de IA | `VENUES_E_PRAZOS.md` |
| `07_estado-da-arte/` | protocolo de ampliação do estado da arte; ferramentas adotadas e não adotadas | `FERRAMENTAS.md` |
| `08_reprodutibilidade/` | `run_all.sh` e todos os logs | `logs/SUMARIO.md` |
| `10_artigo-scp/` | **manuscrito formatado para o SCP** (classe `elsarticle`), estudo do guia da revista (lido no navegador do app) e checklist, com a sobreposição com o artigo do JFP | `CHECKLIST_SUBMISSAO.md` |
| `09_artigo-jfp/` | **manuscrito formatado para o JFP** (classe oficial `jfp-epi`), estudo do guia da revista e checklist de submissão | `CHECKLIST_SUBMISSAO.md` |

## Em uma página: o que se obteve

* **Fronteira tipada** (`Validation.Boundary`): texto → `Either BoundaryError AvEvent` → CREM; 21 verificações de contrato.
* **Especificação revisável** (`spec/*.csv`): tabela de 16 linhas da aviônica com a origem de cada regra (4 `REQ`, 12 `CONV`),
  9 linhas da energia (`MODEL`), políticas do ambiente. **A orientação ainda não revisou.**
* **Equivalência exaustiva** CREM × oráculo para **qualquer** comprimento de sequência (26 de 48 ternos alcançáveis, 520 arestas), sob a
  hipótese declarada de que o estado do laço é o terno de vértices.
* **Achado** (do modelo, não do CREM): 2 estados alcançáveis em que a aviônica fica em voo com a bateria crítica sem saída; a política
  que reage ao nível os elimina. O menor cenário tem 3 ticks (`DRAIN, DRAIN, TAKEOFF`).
* **Correção ao relatório v4:** com o alfabeto completo, o descarte do slot **não é inócuo** (a v4 só mediu o alfabeto reduzido).
* **TLC (TLA+):** `OneSlot` viola `NoPermanentBlindness` e `Level` satisfaz tudo; o conjunto de estados com a fila vazia é idêntico ao do Haskell.
* **Hedgehog:** 18 verificações; defeitos injetados detectados e reduzidos (1 a 4 ticks, com semente fixa; no caso da política, o shrinking chegou ao mínimo global de 4 ticks, que só a busca em largura garante).
* **C/C++:** reproduzido; **o C++17 com tipos também recusa a transição proibida na compilação**, o que enfraquece qualquer alegação de
  exclusividade do Haskell. Nenhum compilador detecta o destino errado em aresta permitida.

## O que NÃO foi feito (e depende de você ou da orientação)

1. **Revisão da tabela e das políticas pela orientação** (nenhuma linha está aprovada).
2. **Revisor externo de C/C++** (não definido).
3. **Busca sistemática de literatura** (só o protocolo foi escrito); sem ela não se pode alegar ineditismo.
4. **Outras topologias e escalas** e estudo de manutenção.
5. **Definir com a orientação externa a declaração de uso de IA** (seções deixadas em branco; `06_artigos/DECLARACAO_USO_IA.md`) e **confirmar autoria e financiamento**.
6. **QuickCheck State Machine, Motor e os testes do repositório CREM**: não testados.

(O TLC **foi executado** depois do pedido de download: ver `04_tla/README.md`.)

## Reproduzir

```bash
bash Revisao_v5/08_reprodutibilidade/run_all.sh            # tudo, sem a mutação
bash Revisao_v5/08_reprodutibilidade/run_all.sh --mutacao  # inclui a mutação do CREM (lenta)
```

A primeira execução compila tudo e baixa do Hackage as dependências do Hedgehog. `cabal build all` e `cabal test` sem alvo
**falham de propósito** (o teste de invalidez do pacote base não compila); use os alvos explícitos do script.

## Atenção: o repositório `Projects/avionics-crem` está desatualizado

`Projects/avionics-crem` (no repositório IC) está no commit `c97981a`, **sem** a especificação, a matriz de rejeição, os testes de
cadeia e de políticas e a comparação com C/C++ que o relatório v4 cita. A versão atual está em `GitHub/avionics-crem` (commit `9689ce8`);
foi ela que se congelou em `03_codigo/base/` (`SNAPSHOT.md`). Atualizar `Projects/avionics-crem` é decisão sua e não foi feito.
