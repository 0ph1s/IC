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

## Resultado (traços da implementação: 520 de aresta + 500 aleatórios de 30 ticks; 16.099 finais de tick)

| Classe | Finais de tick |
|---|---|
| Concordam | 15.849 |
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
  um tick em `(InFlight, Critical)` por perder o sinal. É o mesmo defeito que o TLC aponta como violação de
  `NoPermanentBlindness`, agora visto por uma referência cuja regra não é nossa. Isso **não** prova que a nossa
  especificação está certa; mostra que uma implementação de terceiros, com semântica de nível, não tem o defeito.
* **Trava (41).** No PX4, a ação de bateria `Critical` usa a condição de limpeza padrão (`WhenConditionClears`,
  `failsafe.cpp`, `fromBatteryWarningActParam`): quando o nível melhora, a ação some. Na nossa máquina,
  `EmergencyLanding` só sai com `LandedSignal`. É uma **diferença de projeto**, não necessariamente um defeito:
  o que o Commander do PX4 faz depois de a ação sumir está fora desta pasta.
* **Só avisa (8).** Se a bateria já estava pior que `NONE` ao armar, o PX4 só avisa
  (`warning_worse_than_at_arming`, `failsafe.cpp`). Na nossa, o `CriticalBattery` seguinte leva a `EmergencyLanding`.
  O script confere que, nesses casos, a bateria estava `Critical` no momento do armamento.

## Atraso `COM_FAIL_ACT_T` e o limite de (SD) (hipótese (b) da T27)

Com `COM_FAIL_ACT_T > 0`, o PX4 não executa a ação na hora: entra em `Hold`, conta o atraso (`_current_delay`) e só então
age. Isso foi medido de duas formas. O harness lê o estado interno do `Failsafe` (diretiva `VERBOSE 1`) por um truque de
compilação só no `harness.cpp`; o código do PX4 continua sem modificação.

**1. Os traços da implementação, com atraso** (`logs/px4_diff_act2_T5_100ms.md`, `px4_diff_act2_T5_1000ms.md`).
Com `COM_FAIL_ACT_T = 5 s`, aparece uma classe nova: o PX4 está em `Hold` esperando o atraso, enquanto a nossa já está em
`EmergencyLanding` (517 finais de tick) ou ainda em `InFlight` com bateria `Critical` (201). As outras classes não mudam.
O que isso mostra é só que **o resultado depende de uma escala de tempo que o nosso modelo não tem**: com 1 s por passo,
o atraso expira dentro de um traço aleatório e a classe "cegueira" volta (1 caso). Não é conformância nem defeito.

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

1. **Só o recorte "nível de bateria → ação".** A máquina de atraso (Hold antes da ação, refil do atraso) é exercida
   na seção acima; o takeover do piloto (`rc_sticks_takeover_request`, mudança de modo) e as demais causas de failsafe
   (GNSS, GCS, link, geofence) **não** são.
2. **A tradução é nossa.** A independência é a das *regras* de decisão, não da tradução de estados.
3. Parâmetros além de `COM_LOW_BAT_ACT` e `COM_FAIL_ACT_T` têm os valores de `harness.cpp` (`defaults()`), que **não**
   foram conferidos contra os metadados de parâmetros do PX4; só importam para flags que aqui ficam sempre falsas.
4. A comparação é por final de tick e por classe; não há comparação passo a passo (dentro de um tick a nossa
   máquina entrega os sinais em sequência, e o PX4 reage ao nível).
5. Só traços da implementação atual (`OneSlot`); **não** foi rodado contra os mutantes nem contra a política `Level`.
6. Cada traço roda numa instância nova do `Failsafe` (`NEW`), com o tipo de veículo fixo em asa rotativa.

## Reproduzir

```bash
# Windows: clang++ do GHC no PATH, por exemplo C:/ghcup/ghc/9.6.7/mingw/bin; pasta de trabalho de caminho curto
bash 11_oraculo-px4/run_px4_oracle.sh C:/mv/px4   # ~1 minuto, precisa de rede (github.com) na primeira execução
# ou, dentro do run_all: bash 08_reprodutibilidade/run_all.sh --px4
# FULL=1 acrescenta as enumerações maiores de px4_sd.py (cerca de 3 minutos)
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
| `px4_sd.py` | mede o estado escondido do PX4 com atraso: conflitos de (SD) por abstração e classes de comportamento futuro |
| `run_px4_oracle.sh` | tudo isso em sequência |
| `logs/` | resultados |
