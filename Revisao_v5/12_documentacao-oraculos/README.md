# Guia dos oráculos (O1 a O4)

Este guia reúne, num lugar só, **o que cada oráculo é, o que ele pega e o que não pega, onde está o código, como rodar e o que
saiu**. Cada pasta técnica continua com o seu próprio README (links abaixo); aqui está o mapa. Estado de 19/11/2026, na branch
`revisao-v5-oraculos`.

> **Ressalva geral.** Nenhum oráculo aqui é independente em *todos* os sentidos. A tabela, o oráculo em Haskell, o TLA+ e o SCXML
> foram escritos pelo mesmo autor (com apoio de IA). O que cada um acrescenta é independência de **código** ou de **motor de
> execução**; a independência de **regras** só existe no O4 (PX4) e só para o recorte de bateria. A revisão da tabela pela
> orientação continua pendente.

## 1. Visão geral

| | Oráculo | O que é | Pega | Não pega | Autoria das regras |
|---|---|---|---|---|---|
| **O1** | Guiado pelas tabelas | Modelo de referência em Haskell, sem `crem`, lido de `spec/*.csv` (`Validation.RefModel`) | erro de implementação no `crem` | erro de interpretação das regras | nossa |
| **O2** | SCION / SCXML | O laço fechado em SCXML, executado pelo SCION (`scxml` 4.3.1, de terceiros) | erro comum a duas implementações nossas: o motor é de terceiros | erro de interpretação das regras; propriedades temporais | nossa (SCXML escrito a partir do TLA+ e das tabelas) |
| **O3** | Validação de traços no TLC | Os traços da implementação são seguidos pelo TLC contra `AvionicsLoop.tla` | a lacuna "o TLC verifica o modelo, não o código" | autoria (o modelo é nosso) | nossa |
| **O4** | Failsafe do PX4 | O `failsafe.cpp` e o `framework.cpp` **reais** do PX4, compilados e dirigidos pelos nossos traços | regra de decisão de terceiros, no próprio domínio | o que ficou fora do recorte de bateria | **de terceiros** (a tradução de estados é nossa) |

Fluxo de dados (as setas são as ferramentas deste repositório):

```
spec/*.csv ──► O1 (oráculo Haskell) ──┐
                                       ├─► equivalência exaustiva: 26 ternos, 520 arestas
implementação CREM ───────────────────┘
      │
      │  validation-export  (520 traços de aresta + 500 aleatórios [+ 100 corrompidos])
      ├──► O3: TLC (TraceCheck.tla sobre AvionicsLoop.tla)
      ├──► O2: SCION (avionics_loop.scxml)           ──► compara com a lista do TLC
      └──► O4: PX4 (failsafe real compilado)         ──► classes de divergência
```

## 2. O que cada um mostrou

| Oráculo | Resultado | Onde |
|---|---|---|
| O1 | CREM e oráculo equivalentes para qualquer comprimento de sequência (26 de 48 ternos, 520 arestas), sob a hipótese de que o estado do laço é o terno de vértices | `03_codigo/validation/`, `08_reprodutibilidade/logs/04_reach.txt` |
| Determinação do estado (SD) | vale nos 48 ternos, no sentido comportamental (404.208 casos exaustivos e 5.000 testes Hedgehog); dois controles negativos reprovam | `08_reprodutibilidade/logs/17_sd_48_ternos.txt` |
| O3 | 520 traços de aresta e 500 aleatórios aceitos; 100 corrompidos recusados | `08_reprodutibilidade/logs/18_trace_validation_*`, `04_tla/` |
| O2 | o SCION aceita exatamente a mesma lista de traços que o TLC | `08_reprodutibilidade/logs/18_scion_console.txt`, `04_tla/scion/` |
| TLC (modelo) | `OneSlot` viola `NoPermanentBlindness`; `Level` satisfaz tudo | `08_reprodutibilidade/logs/14_tlc_*.txt` |
| Justiça | `OneSlot` viola sob a hipótese base e sob comandos de pouso, corte e decolagem justos; vale sob as demais; `Level` vale em todas (9 hipóteses × 2 políticas) | `08_reprodutibilidade/logs/20_justica/` |
| Mutação de destinos | dos 48 mutantes, 32 o compilador recusa e 16 as suítes matam; nenhum vivo | `08_reprodutibilidade/logs/06b_mutation_dest48.md` |
| Amostragem | probabilidade exata de um teste aleatório (gerador do Hedgehog) achar a lacuna da bateria: no máximo 0,39%, com 8 ticks | `08_reprodutibilidade/logs/19_amostragem.md` |
| O4, traços | 16.450 de 16.700 finais de tick concordam; o resto cai em três classes explicadas (cegueira 201, trava 41, só avisa 8), nenhuma inexplicada | `11_oraculo-px4/` |
| O4, `Level` | a cegueira não **persiste** com `Level` (sequência máxima de 2 ticks; 0 de 3 traços ociosos terminam cegos) e persiste com `OneSlot` (11 ticks; 2 de 3) | `11_oraculo-px4/logs/px4_diff_{oneslot,level}.md` |
| O4, mutantes | 16 de 16 mutantes de destino detectados: 1 por classe nova, 15 por comparação com a original (oráculo de regressão, não de correção absoluta) | `11_oraculo-px4/logs/px4_contra_mutantes.md` |
| O4, atraso, takeover, outras causas | ver a tabela da seção 4 | `11_oraculo-px4/README.md` |

## 3. Como rodar

Pré-requisitos por oráculo:

| Para | Precisa de |
|---|---|
| tudo em Haskell (O1, SD, exportação, amostragem) | GHC 9.6.7 e cabal 3.12.1.0 |
| O3 e justiça | Java (testado com o 8) e `04_tla/tools/tla2tools.jar` v1.7.4, não versionado (ver `04_tla/run_tlc.sh`); Python 3 |
| O2 | Node.js e `npm install scxml@4.3.1 --ignore-scripts` numa pasta à parte; `SCXML_DIR` apontando para ela |
| O4 | `clang++` (no Windows, o do GHC, em `<ghc>/mingw/bin`, que também precisa estar no `PATH` para rodar o executável), Python 3 e rede (github.com) na primeira execução |

```bash
bash Revisao_v5/08_reprodutibilidade/run_all.sh                      # base: O1, O3, SD, amostragem (+ SCION se SCXML_DIR)
bash Revisao_v5/08_reprodutibilidade/run_all.sh --destinos --justica # inclui mutação de destinos (~2 h) e justiça (~35 min)
bash Revisao_v5/08_reprodutibilidade/run_all.sh --px4                # inclui o O4 (~1 min)
bash Revisao_v5/11_oraculo-px4/run_px4_oracle.sh C:/mv/px4           # só o O4; FULL=1 e MUTANTES=1 acrescentam as partes lentas
```

Nesta máquina (Windows): usar pasta de trabalho de **caminho curto** (por exemplo `C:\mv`), porque o limite de caminho do sistema
quebra compilações em pastas fundas; o Python do Windows não lê caminhos `/c/...` (use `C:\...`); e, no Git Bash, argumentos que
começam com `/` viram caminhos do Git (`MSYS_NO_PATHCONV=1`).

## 4. O que o O4 (PX4) mediu, em uma tabela

Tudo em `11_oraculo-px4/README.md`, com a metodologia e os limites de cada linha.

| Tema | Achado |
|---|---|
| Traços do CREM | as divergências com o PX4 são só três: **cegueira** (o PX4 trata a bateria como nível e nunca fica cego), **trava** (a nossa `EmergencyLanding` segue depois de a bateria melhorar; o PX4 libera) e **só avisa** (bateria já `Critical` ao armar) |
| Atraso `COM_FAIL_ACT_T` | o resultado depende de uma escala de tempo que o nosso modelo não tem; o estado visível não determina a saída nem sem atraso (bit de bateria ao armar); com o estado interno completo não há conflito de (SD); os estados escondidos crescem com o atraso (5, 15, 31, 55, 127 e 269 para T = 0, 1, 2, 3, 5 e 8 s) |
| Takeover do piloto | em todo estado de `EmergencyLanding` em que o PX4 ainda age, uma troca de modo abortaria o pouso (517 de 517); o manche, só com atraso configurado e já expirado. A nossa máquina não tem entrada do piloto: diferença de projeto, a decidir com a orientação |
| Outras causas | só a bateria **libera** quando a condição some; link, GNSS, geofence, vento e navegador **travam** até troca de modo ou desarme (como a nossa `EmergencyLanding`); várias causas combinam por **máximo de severidade**, sem dependência da ordem (150.600 e 36.000 casos, nenhuma violação) |
| Limite de (SD) | cada causa acrescenta estados escondidos (15 vezes mais com 4 causas, sem atraso); o estado interno lido continua bastando, um terno de vértices não |

## 5. Onde está o quê

| Pasta | Conteúdo |
|---|---|
| `03_codigo/validation/` | `src/` (tabelas, oráculo, alcançabilidade); `app/ExportTraces.hs` (exporta traços da implementação e, com `oneslot` ou `level`, do oráculo); `app/Sampling.hs`; `test/` (inclui `SDSpec.hs`); `scripts/` (mutação, figura, `o3_mutants.py`) |
| `04_tla/` | `AvionicsLoop.tla` (não alterado), `TraceCheck.tla` (O3), `AvionicsLoopFairness.tla`, `scion/` (O2), scripts `run_*.sh` |
| `08_reprodutibilidade/` | `run_all.sh` e todos os logs, com o `SUMARIO.md` |
| `11_oraculo-px4/` | o O4: `fetch_px4.sh`, `build.sh`, `harness.cpp`, `stubs/`, `px4_*.py`, `selftest.py`, `logs/` |

## 6. O que cada oráculo **não** prova

* **O1, O2, O3:** concordam entre si e com a implementação, mas as regras são todas do mesmo autor. Concordância não é correção.
* **O3 contra mutantes** e **SCION contra mutantes:** o resultado de uma execução anterior (18 e 19/11/2026, em cópias de trabalho) está
  descrito no README de `08_reprodutibilidade`; o script `o3_mutants.py` **não foi executado neste repositório**.
* **O4:** só o recorte "nível de bateria → ação" é comparado traço a traço com o CREM; atraso, takeover e outras causas são medidas sobre
  o PX4, não comparações. A tradução de estados é nossa. 15 dos 16 mutantes são detectados por comparação com a original, não por uma
  regra do PX4. O comando `--px4` do `run_all.sh` foi testado só isoladamente, não numa execução completa.
* **Nenhum** substitui a revisão da tabela pela orientação, o revisor externo de C/C++ ou a busca de literatura.

## 7. Glossário

| Termo | Significado |
|---|---|
| terno | o estado abstrato do laço: (aviônica, bateria, ambiente). 48 possíveis, 26 alcançáveis |
| tick | um passo do mundo externo: um comando opcional e um evento de energia opcional, mais o `Beat` |
| passo | um sinal processado dentro de um tick; um traço registra o terno depois de cada passo |
| (SD) | determinação do estado: o comportamento futuro depende só do terno (hipótese que sustenta a exploração do grafo) |
| `OneSlot` | política do ambiente: um slot, quem chega primeiro fica (a da implementação) |
| `Level` | política que, além disso, reage ao **nível** da bateria; só existe no modelo |
| cegueira | aviônica em `InFlight` com bateria `Critical`, sem reação; `NoPermanentBlindness` proíbe que persista |
| traço | sequência de ticks com os ternos observados; vem da implementação, do oráculo ou (corrompido de propósito) para teste negativo |
| mutante de destino | a implementação com o destino de uma transição trocado; 48 no total, 16 dentro da topologia |
| trava | uma ação que continua depois de a condição que a causou ter sumido |
| classe de divergência | por que o PX4 e a nossa máquina diferem num fim de tick (cegueira, trava, só avisa, atraso) |
| α, α', β | abstrações do estado do PX4: o que se vê; o que se vê mais a última entrada; o estado interno lido pelo harness |
| oráculo de regressão | detecta que o comportamento **mudou** em relação a uma versão de referência, sem dizer que a nova está errada |
