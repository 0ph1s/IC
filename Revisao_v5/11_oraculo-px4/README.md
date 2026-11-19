# Oráculo PX4 (O4): o failsafe do PX4 como referência de terceiros

**O que é.** Os traços da implementação em CREM (os mesmos que o TLC e o SCION validam) são passados pela máquina de
*failsafe* do PX4 Autopilot, e a decisão dela é comparada com a da nossa implementação ao fim de cada tick. O ganho em
relação a O2 (SCION) e O3 (TLC) é de **autoria**: o SCXML e o TLA+ foram escritos por quem escreveu a tabela, enquanto as
regras do PX4 não. Este oráculo ataca a ameaça "tabela, oráculo e TLA+ são do mesmo autor" (tarefa T27 do plano v2).

**O que roda.** O código **real** do PX4, sem modificação: `failsafe.cpp` e `framework.cpp`
(`src/modules/commander/failsafe/`), mais `module_params.cpp`. Só a infraestrutura em volta é nossa (pasta `stubs/`):
parâmetros (um mapa), tempo (`hrt_abstime`), eventos (desligados, como no build `EMSCRIPTEN_BUILD` que o próprio PX4
usa no simulador de failsafe) e os cabeçalhos uORB, **gerados dos `.msg` reais** por `gen_headers.py`. O `param.h` real
confere por `static_assert` que cada parâmetro é `int` ou `float` como declarado na nossa tabela de tipos.

## Procedência

| Item | Valor |
|---|---|
| Repositório | github.com/PX4/PX4-Autopilot |
| Commit | `4e44c822c9018120508bce6d8ad349f0775586a1` (19/11/2026) |
| Licença | BSD-3-Clause (arquivo `LICENSE` do repositório; o código do PX4 **não** é copiado para este repositório) |
| `git hash-object` dos arquivos | `failsafe.cpp` db98105…, `framework.cpp` a0661c4…, `failsafe.h` 9beeb58…, `framework.h` 23be7df…, `failsafe_test.cpp` 669fe7a… |
| Baixado | só os caminhos listados em `fetch_px4.sh` (checkout esparso e raso, cerca de 1 MB) |

## Verificação do harness (autoteste)

`selftest.py` reproduz as 14 expectativas do teste do próprio PX4, `BatteryFailsafeUsesLowBatActParam`
(`failsafe_test.cpp`, linhas 1202 a 1219): para cada valor de `COM_LOW_BAT_ACT` e cada nível de bateria, a ação
selecionada. Resultado: **14 de 14**. Sem isso, nada do que sai do harness valeria.

## Tradução (o que é nosso, e portanto não é propriedade do PX4)

Por passo `(aviônica, bateria, ambiente)` de um traço:

* `armed` = aviônica em `InFlight` ou `EmergencyLanding`;
* `battery_warning` = `Charged → NONE`, `Low → LOW`, `Critical → CRITICAL` (o nível `EMERGENCY` do PX4 não é usado);
* o comando `CriticalBattery` **afirma** bateria `Critical` durante os passos do seu tick (a variante sem isso,
  `assert=0`, também é registrada);
* modo pretendido `AUTO_MISSION`; `COM_FAIL_ACT_T = 0` (sem atraso de Hold); 100 ms por passo; o PX4 é atualizado a
  cada passo, então ele vê o traço inteiro, com a sua própria história interna;
* "pouso" no PX4 = ação selecionada `Land` ou `RTL`; na nossa, `EmergencyLanding`.

## Resultado (traços da implementação: 520 de aresta + 500 aleatórios de 30 ticks; 16.700 finais de tick)

| Classe | Finais de tick |
|---|---|
| Concordam | 16.450 |
| O PX4 pousa e a nossa fica em `InFlight` com bateria `Critical` (a **cegueira**) | 201 |
| Nossa segue em `EmergencyLanding` com bateria `Low` e o PX4 já liberou (**trava**) | 41 |
| O PX4 só avisa, porque a bateria já estava `Critical` ao armar | 8 |
| Qualquer outra classe | 0 |

O resultado é o mesmo para `COM_LOW_BAT_ACT` = 2 (Land), 3 e 4 (Return), porque se compara "pousa ou retorna".
`logs/px4_diff_act2.md`, `px4_diff_act3.md` e `px4_diff_act2_assert0.md` guardam as tabelas; `logs/px4_console.txt`, a
saída completa.

**Como ler cada classe**

* **Cegueira (201).** O PX4 trata a bateria como um *nível* (condição verificada a cada atualização) e, por isso, nunca
  fica "cego": com bateria `Critical` e armado, escolhe a ação. A nossa implementação (política `OneSlot`) pode terminar
  um tick em `(InFlight, Critical)` por perder o sinal. Esta classe conta **qualquer** fim de tick assim, inclusive os
  transitórios; o defeito que o TLC aponta (violação de `NoPermanentBlindness`) é a cegueira que **persiste**, medida
  na seção seguinte. Isso **não** prova que a nossa especificação está certa; mostra que uma implementação de
  terceiros, com semântica de nível, não tem o defeito.
* **Trava (41).** No PX4, a ação de bateria `Critical` usa a condição de limpeza padrão (`WhenConditionClears`,
  `failsafe.cpp`, `fromBatteryWarningActParam`): quando o nível melhora, a ação some. Na nossa máquina,
  `EmergencyLanding` só sai com `LandedSignal`. É uma **diferença de projeto**, não necessariamente um defeito:
  o que o Commander do PX4 faz depois de a ação sumir está fora desta pasta.
* **Só avisa (8).** Se a bateria já estava pior que `NONE` ao armar, o PX4 só avisa
  (`warning_worse_than_at_arming`, `failsafe.cpp`). Na nossa, o `CriticalBattery` seguinte leva a `EmergencyLanding`.
  O script confere que, nesses casos, a bateria estava `Critical` no momento do armamento.

## A política `Level` (e a cegueira que persiste)

A implementação em CREM só tem `OneSlot`; `Level` existe apenas no oráculo em Haskell (`refTS`). Por isso os traços de
`Level` vêm de `validation-export <pasta> level` (a pasta `03_codigo/validation`), e os de `oneslot` do mesmo comando
servem de controle: **são idênticos aos da implementação (1020 de 1020 traços)**. Cada conjunto ganha 3 traços "ociosos":
de cada terno que termina cego, 10 ticks sem nenhuma entrada.

| Medida (`COM_LOW_BAT_ACT = 2`, `logs/px4_diff_oneslot.md`, `px4_diff_level.md`) | `OneSlot` | `Level` |
|---|---|---|
| Concordam / cegueira / trava / só avisa (finais de tick) | 16.476 / 213 / 41 / 8 | 16.472 / 204 / 48 / 14 |
| Maior sequência de ticks seguidos terminando em `(InFlight, Critical)` | **11** | **2** |
| Traços ociosos que terminam ainda cegos | **2 de 3** | **0 de 3** |
| Traços aleatórios (500 de 30 ticks) que terminam cegos | 0 | 0 |

Leitura: a contagem da classe "cegueira" é quase igual nas duas políticas, porque `Level` também termina alguns ticks em
`(InFlight, Critical)` antes de reagir no tick seguinte. O que separa as duas é a **persistência**: com `OneSlot` dois
ternos ficam cegos para sempre sob ticks ociosos (sequência de 11 ticks), com `Level` a cegueira some em no máximo 2
ticks. O PX4 pousa nos três casos. Bate com o resultado do TLC (`OneSlot` viola `NoPermanentBlindness`, `Level` não),
mas por outro caminho. Os 500 traços aleatórios **não** distinguem as políticas (nenhum termina cego em nenhuma),
o que é coerente com a probabilidade pequena de a enumeração aleatória achar a lacuna (`19_amostragem.md`).

## O PX4 contra os mutantes de destino

`px4_mutants.py` pega os 16 mutantes de destino que o compilador aceita (a aresta mutada está dentro da topologia, os
outros 32 de 48 não compilam), numa cópia de `03_codigo`: compila a implementação mutada, exporta os traços dela, passa
pelo PX4 e compara com a implementação original. Resultado (`logs/px4_contra_mutantes.md`):

| Veredito | Mutantes |
|---|---|
| Morto por **classe nova** (uma divergência que a original não tem) | 1: D17 (`InFlight` + `CriticalBattery` fica em `InFlight`). Aparece "PX4 pousa; nossa (InFlight, Charged ou Low) não": a nossa nunca pousa, e o PX4 pousa |
| Morto pelas **contagens nos 500 traços aleatórios** (os mesmos cenários de entrada para toda implementação) | 15 |
| Morto só pelos traços de aresta | 0 |
| Vivo | 0 |

**Como ler.** Só D17 é pego por uma regra do PX4 sozinha: a nossa fica de fora de um pouso que o PX4 manda fazer. Os outros
15 são pegos por **comparação com a implementação original**: o "dedo" do PX4 (quantos finais de tick caem em cada classe)
muda. Isso é um oráculo de regressão, não de correção absoluta: o PX4 não diz que esses 15 estão errados, diz que o
comportamento mudou em relação ao original, e só o original foi explicado classe a classe. Algumas diferenças são
pequenas (D25: cegueira 100 → 101, concordam 14.861 → 14.867), mas determinísticas, porque os cenários são idênticos.
O TLC (O3) e o SCION (O2) recusam os mutantes por regras da própria especificação; este resultado é o complemento de
um terceiro.

## Outras causas de failsafe (RC, GCS, GNSS, geofence, vento, tempo de voo, missão, navegador)

A nossa implementação só conhece bateria e comandos, então **estas causas não têm correspondente nos nossos traços** e nada aqui é uma
comparação com o CREM. É a medida, rodando o failsafe real (`px4_causas.py`, `logs/px4_causas.md`, `px4_causas_rapido.md`), de regras que
uma extensão do modelo teria de decidir. Cada causa é ligada pelo parâmetro que o PX4 usa (`NAV_RCL_ACT`, `NAV_DLL_ACT`,
`COM_GNSSLOSS_ACT`, `GF_ACTION`, `COM_WIND_MAX_ACT`, `COM_LOW_BAT_ACT`), e todos os valores de cada parâmetro são exercidos.

**1. A ação trava ou libera quando a condição some?** (`COM_FAIL_ACT_T = 0`, armado, AUTO_MISSION; causa ligada por 3 passos e depois
desligada de forma explícita)

| Causa (ação configurada) | Quando a condição some |
|---|---|
| Bateria `Critical` com Return ou Land | **libera** (6 de 7 valores de `COM_LOW_BAT_ACT`; o outro só avisa) |
| Bateria `Emergency` com Return ou Land | **libera**; com Terminate, nunca |
| Perda de RC, perda de GCS, perda de GNSS, geofence, vento, com Hold, Return ou Land | **trava** até uma troca de modo ou até desarmar |
| Falha do navegador (Hold) | **trava** até uma troca de modo ou até desarmar |
| Perda de RC ou de GCS com Disarm; tempo de voo excedido; falha de missão (Return) | libera |
| Qualquer causa com Terminate | nunca libera |
| Qualquer causa com Warn ou sem ação | não age |

Ou seja: a "trava" que a nossa `EmergencyLanding` tem (só sai com `LandedSignal`, isto é, no pouso e desarme) é, no PX4, o
**comportamento comum** às causas de link, GNSS, geofence, vento e navegador; **a bateria é a exceção que libera**. A diferença "trava" da
primeira tabela de resultados é, portanto, específica da regra de limpeza da bateria no PX4, e não uma filosofia geral do PX4 contra
travar.

**2. Com várias causas ao mesmo tempo, vale a mais severa?** Vale. 300 configurações de parâmetros sorteadas (semente fixa) e todos os 502
subconjuntos de 2 a 9 das 9 causas (as oito acima e bateria `Critical`) ligados ao mesmo tempo: a ação escolhida é igual ao máximo das ações de
cada causa sozinha em **150.600 de 150.600 casos**, tanto com `COM_FAIL_ACT_T = 0` quanto com 5 s (depois de 8 passos). **A ordem de chegada
não importa**: para todos os subconjuntos de 2 e 3 causas e todas as suas ordens (36.000 casos por atraso), a ação final é a mesma e igual
ao máximo. Isso dá uma especificação simples para estender o modelo: a ação é o máximo de uma ordem de severidade (a do enum `Action` do PX4: `None < Warn < Fallback* < Hold <
RTL < Land < Descend < Disarm < Terminate`), sem dependência da ordem.

**3. Estado escondido com várias causas** (`px4_sd.py` com flags nomeadas; `logs/px4_sd_causas.md`, `px4_sd_causas_ref.md`,
`px4_sd_causas_rapido.md`; `NAV_RCL_ACT=2`, `COM_GNSSLOSS_ACT=2`, `GF_ACTION=2`, `COM_LOW_BAT_ACT=3`; 7 passos, histórias de 3):

| `COM_FAIL_ACT_T` (s) | 0 | 2 |
|---|---|---|
| estados β só com bateria (referência) | 5 | 26 |
| estados β com 4 causas (bateria, GNSS, RC, geofence), uma de cada vez | 77 | 664 |
| conflitos de (SD) no estado visível α, só bateria / 4 causas | 1 / 5 | 2 / 9 |
| conflitos no estado interno β | **0** | **0** |
| classes de comportamento futuro, só bateria / 4 causas | 2 / 7 | 5 / 19 |

O estado interno lido continua bastando (0 conflitos), mas o número de estados escondidos cresce **15 vezes** sem atraso e **25 vezes**
com atraso de 2 s. Com mais causas, um terno de vértices não basta nem de longe: cada causa acrescenta flags e entradas na lista de ações
que o PX4 guarda.

## Takeover do piloto

No PX4, com um failsafe de bateria ativo, o piloto pode retomar o controle. As regras, lidas em `framework.cpp`
(`checkFailsafe`, `getSelectedAction`) e confirmadas rodando o código: com `COM_FAIL_ACT_T = 0` a ação aceita takeover **só por troca de
modo** (`AlwaysModeSwitchOnly`: o manche não vale); com `COM_FAIL_ACT_T > 0.1` o manche também vale, **mas não durante o `Hold` do
atraso** (nele, só a troca de modo vale). Depois do takeover a ação vira `Warn` e fica assim enquanto a condição durar.
Na nossa máquina **não existe entrada do piloto**: `EmergencyLanding` só sai com `LandedSignal`.

**1. Cenários** (`logs/px4_takeover.md`, um passo por segundo, bateria `Critical` a partir do passo 1, `*` = takeover ativo):

| Cenário (`COM_LOW_BAT_ACT = 2`) | `COM_FAIL_ACT_T = 0` | `COM_FAIL_ACT_T = 5` |
|---|---|---|
| sem takeover | `Land` do passo 1 em diante | `Hold` nos passos 1 a 5, depois `Land` |
| manche no passo 8 | **sem efeito**, segue `Land` | `Land` → `Warn*` e fica |
| troca de modo no passo 8 | `Land` → `Warn*` e fica | `Land` → `Warn*` e fica |
| manche no 8, depois bateria `Emergency` no 11 | sem efeito | `Warn*` → `Hold` (novo atraso) → `Land`: o takeover é desfeito pelo novo failsafe |
| manche no 8, bateria recupera no 10 e cai de novo no 12 | `None` no 10, depois `Land` | `None` no 10, depois `Hold` (atraso de novo) → `Land` |

**2. Sonda nos nossos estados de `EmergencyLanding`** (566 fins de tick nos 1020 traços). Para cada um, repete-se o traço no PX4 e
acrescenta-se um passo com manche ou com troca de modo para `Loiter`. Dos 566, em 49 o PX4 já tinha liberado (a classe "trava"); nos 517
restantes ele ainda mandava pousar (ou estava no `Hold` do atraso):

| Configuração | Manche assume | Troca de modo assume |
|---|---|---|
| `COM_FAIL_ACT_T = 0` | **0 de 517** | **517 de 517** |
| `COM_FAIL_ACT_T = 5 s`, 100 ms por passo (tudo ainda no `Hold` do atraso) | 0 de 517 | 517 de 517 |
| `COM_FAIL_ACT_T = 5 s`, 1 s por passo (o atraso expira em parte dos traços) | 37 de 517 | 517 de 517 |

Ou seja: **em todo estado em que a nossa máquina está em `EmergencyLanding` e o PX4 ainda age, uma troca de modo do piloto abortaria o
pouso no PX4**, e o manche também, quando há atraso configurado e ele já expirou. A nossa máquina não tem essa transição.
Isto é uma diferença de projeto, não um defeito mostrado: se um pouso de emergência deve ou não poder ser abortado pelo piloto é uma
exigência de domínio, a decidir com a orientação. O que o experimento fixa é o que o PX4 faz e que a nossa especificação é, nesse ponto, mais
restritiva.

**3. O takeover no estado escondido** (`px4_sd.py` com entradas `bateria:manche:modo`; `logs/px4_sd_takeover.md`, `px4_sd_takeover_ref.md`,
`px4_sd_takeover_rapido.md`). Mesma medida da seção do atraso, agora com entradas de manche e troca de modo (8 passos, histórias de 4):

| `COM_FAIL_ACT_T` (s) | 0 | 2 | 5 |
|---|---|---|---|
| estados β sem takeover (referência) | 5 | 28 | 50 |
| estados β com takeover | 10 | 75 | 180 |
| conflitos de (SD) no estado visível α, sem takeover | 1 | 2 | 2 |
| conflitos de (SD) no estado visível α, com takeover | 6 | 8 | 8 |
| conflitos no estado interno β (os dois casos) | **0** | **0** | **0** |

O estado interno que o harness lê (agora incluindo `_user_takeover_active` e `_last_user_intended_mode`) **continua bastando**: nenhum
conflito. Mas o número de estados escondidos cresce de 2 a 3,6 vezes, e o estado visível fica ainda pior (6 a 8 conflitos). O takeover
acrescenta à máquina uma dimensão de histórico que um terno de vértices não tem. Como antes, a contagem para T = 5 é limitada pelo
horizonte.

## Atraso `COM_FAIL_ACT_T` e o limite de (SD) (hipótese (b) da T27)

Com `COM_FAIL_ACT_T > 0`, o PX4 não executa a ação na hora: entra em `Hold`, conta o atraso (`_current_delay`) e só então
age. Isso foi medido de duas formas. O harness lê o estado interno do `Failsafe` (diretiva `VERBOSE 1`) por um truque de
compilação só no `harness.cpp`; o código do PX4 continua sem modificação.

**1. Os traços da implementação, com atraso** (`logs/px4_diff_act2_T5_100ms.md`, `px4_diff_act2_T5_1000ms.md`).
Com `COM_FAIL_ACT_T = 5 s`, aparece uma classe nova: o PX4 está em `Hold` esperando o atraso, enquanto a nossa já está em
`EmergencyLanding` (517 finais de tick) ou ainda em `InFlight` com bateria `Critical` (201). As outras classes não mudam.
O que isso mostra é só que **o resultado depende de uma escala de tempo que o nosso modelo não tem**: com 1 s por passo,
o atraso expira dentro de um traço aleatório e a classe "cegueira" volta (4 casos). Não é conformância nem defeito.

**2. Quanto estado escondido o PX4 carrega** (`px4_sd.py`; `logs/px4_sd_atraso_2simbolos.md`, `px4_sd_atraso_3simbolos.md`,
`px4_sd_rapido.md`). Todas as palavras de bateria (níveis a cada segundo, armado) até um comprimento fixo, para vários
valores de `COM_FAIL_ACT_T`. Para cada abstração do estado, conta-se os "conflitos": o mesmo par (estado abstrato,
entrada) levando a resultados diferentes. Conflito zero significa que (SD) vale para aquela abstração.

| Abstração | O que é | Conflitos |
|---|---|---|
| α | o que um observador vê: ação selecionada e takeover | **> 0 mesmo com `COM_FAIL_ACT_T = 0`** (1 a 3, conforme T) |
| α' | α mais o último nível de bateria (o análogo do nosso terno de vértices) | **> 0**, igual a α |
| β | α mais os atrasos, a lista de ações ativas e o resto do estado privado que o harness lê | **0 em todas as execuções** |

Resultados (alfabeto de dois níveis, 65.536 palavras de 16 passos; classes futuras com histórias de 8 passos e
continuações de 8):

| `COM_FAIL_ACT_T` (s) | 0 | 1 | 2 | 3 | 5 | 8 |
|---|---|---|---|---|---|---|
| estados β alcançados | 5 | 15 | 31 | 55 | 127 | 269 |
| classes de comportamento futuro | 2 | 3 | 15 | 29 | 38 | 23 |

As classes futuras para T = 5 e 8 são limitadas pelo horizonte (continuações de 8 passos não cobrem um atraso de 8 s), então
esses dois valores são **cotas inferiores**; de T = 0 a 3 a contagem cresce com o atraso.

**Leitura.**

* O estado visível **não** determina a saída nem sem temporizador. A causa, verificada na enumeração: o PX4 guarda o nível
  de bateria **na hora de armar** (`_battery_warning_at_arming`). A mesma história visível (`None` e depois bateria
  `Critical`) dá `RTL` ou só `Warn`, conforme esse bit.
* Com atraso, o estado escondido cresce com o parâmetro: dois contadores (`_current_delay`, que desce a cada atualização, e
  `_current_start_delay`, que volta a subir a um quarto da velocidade) mais a lista de ações. Aqui o estado interno que o
  harness lê **basta** (β sem conflitos), mas não é um terno de vértices.
* Em termos de (SD): vale para a abstração β (estado interno completo, com temporizadores), e **não** vale para α nem α'.
  Ou seja, aplicar o mesmo método de exploração ao PX4 exigiria acrescentar à abstração o bit de armamento e os
  temporizadores, e o número de estados passa a depender de `COM_FAIL_ACT_T`.
* Isto é uma medida sobre o recorte "bateria → ação" do PX4, não um teorema sobre (SD) em geral.

## Limites (o que esta pasta **não** mostra)

1. **Só o recorte "nível de bateria → ação" é comparado com o CREM.** O atraso, o takeover do piloto e as outras causas de
   failsafe são medidas sobre o PX4 (e o que elas implicam para uma extensão do modelo), não comparações com traços do CREM, que não
   tem essas causas. Ficam de fora o nível `EMERGENCY` em traços do CREM, os modos de voo além de `AUTO_MISSION` e `AUTO_LOITER`, as causas de
   falha de motor, paraquedas, tráfego e Remote ID, e as exceções de link (`COM_RCL_EXCEPT`, `COM_DLL_EXCEPT`).
2. **A tradução é nossa.** A independência é a das *regras* de decisão, não da tradução de estados.
3. Parâmetros além de `COM_LOW_BAT_ACT` e `COM_FAIL_ACT_T` têm os valores de `harness.cpp` (`defaults()`), que **não**
   foram conferidos contra os metadados de parâmetros do PX4; só importam para flags que aqui ficam sempre falsas.
4. A comparação é por final de tick e por classe; não há comparação passo a passo (dentro de um tick a nossa
   máquina entrega os sinais em sequência, e o PX4 reage ao nível).
5. Os mutantes cobrem só os 16 de destino aceitos pelo compilador (não os 9 da implementação em `mutation.sh`), e 15 deles
   são detectados por comparação com o original, não por uma regra do PX4 (ver seção dos mutantes). `Level` só foi
   testado no oráculo em Haskell, porque não existe na implementação.
6. Cada traço roda numa instância nova do `Failsafe` (`NEW`), com o tipo de veículo fixo em asa rotativa.

## Reproduzir

```bash
# Windows: clang++ do GHC no PATH, por exemplo C:/ghcup/ghc/9.6.7/mingw/bin; pasta de trabalho de caminho curto
bash 11_oraculo-px4/run_px4_oracle.sh C:/mv/px4   # ~1 minuto, precisa de rede (github.com) na primeira execução
# ou, dentro do run_all: bash 08_reprodutibilidade/run_all.sh --px4
# FULL=1 acrescenta as enumerações maiores de px4_sd.py (cerca de 3 minutos); MUTANTES=1, o PX4 contra os mutantes (~35 min)
```

Pré-requisito: os traços em `08_reprodutibilidade/logs/18_traces/` (gerados pelo `run_all.sh`).
O script sai com 0 se o autoteste passar (14/14) e toda divergência cair nas três classes acima.

## Arquivos

| Arquivo | Papel |
|---|---|
| `fetch_px4.sh` | checkout esparso e raso do commit fixado |
| `gen_headers.py` | gera `uORB/topics/*.h` dos `.msg` reais |
| `stubs/`, `prelude.h` | infraestrutura mínima nossa (parâmetros, tempo, eventos, log) |
| `harness.cpp` | liga o `Failsafe` real a uma interface de texto (`PARAM`, `NEW`, `STEP`) |
| `build.sh` | compila o código real e o harness |
| `selftest.py` | 14 expectativas do teste do PX4 |
| `px4_diff.py` | passa os traços pelo PX4 e classifica as divergências (aceita `COM_FAIL_ACT_T` e tempo por passo) |
| `px4_causas.py` | outras causas de failsafe: trava ou libera, lei de severidade com várias causas e independência da ordem |
| `px4_takeover.py` | takeover do piloto: cenários roteirizados e sonda nos estados de `EmergencyLanding` dos traços (manche e troca de modo) |
| `px4_mutants.py` | o PX4 contra os 16 mutantes de destino aceitos pelo compilador, em cópia de trabalho (lento: cerca de 35 minutos; `MUTANTES=1` no `run_px4_oracle.sh`) |
| `px4_sd.py` | mede o estado escondido do PX4 com atraso: conflitos de (SD) por abstração e classes de comportamento futuro |
| `run_px4_oracle.sh` | tudo isso em sequência |
| `logs/` | resultados |
