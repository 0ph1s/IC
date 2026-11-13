# Política do ambiente (registrador de um slot) — especificação para revisão

Complementa `transition_table.csv` e `power_table.csv`. Descreve o ambiente que fecha o laço
aviônica → ambiente → aviônica e as três políticas comparadas. **Nada aqui vem dos requisitos do
domínio** (`Obsidian/documentation/Example Avionics.md` não fala de ambiente nem de realimentação):
é escolha de modelagem do projeto, a ser revisada pela orientação.

**Status da revisão: PENDENTE.**

## 1. O tick

Um tick processa, nesta ordem: `Beat` (relógio), o comando para a aviônica (se houver), o evento de
energia (se houver). Cada sinal passa pela planta (aviônica ‖ energia), a telemetria é classificada
e entregue ao ambiente; o que o ambiente liberar é processado **em profundidade, no mesmo tick**,
antes do próximo sinal externo (é a ordem do `Feedback` do CREM e do `Step` do TLA+).

## 2. Telemetria (cue) e retenção

| Telemetria que o ambiente recebe | Regra |
|---|---|
| bateria passou a `Critical` (relato `ReportCritical`) | `Crit` |
| aviônica emitiu `MsgEmergency` | `Emergency` |
| aviônica emitiu `MsgLanded` | `Landed` |
| qualquer outra | `Quiet` (ignorada) |
| `Beat` | libera o que está retido |

| Retenção (slot) | Libera no `Beat` seguinte, em ordem |
|---|---|
| `CriticalHeld` (de `Crit`) | `CriticalBattery` → aviônica |
| `TouchdownHeld` (de `Emergency`) | `ShedLoad` → energia; depois `LandedSignal` → aviônica |
| `CutoffHeld` (de `Landed`) | `SystemCutoff` → aviônica |

O `Beat` sempre esvazia o slot.

## 3. As três políticas

| Política | Slot | Telemetria com slot ocupado | Reação ao nível da bateria | Onde existe |
|---|---|---|---|---|
| `OneSlot` (do projeto) | um grupo | **descartada** | não | CREM (`Avionics.Sim.Mission`) e oráculo |
| `Queue` | fila, cada tipo uma vez | enfileirada | não | só no oráculo |
| `Level` | um grupo | descartada | **sim**: no `Beat`, com o slot livre, bateria `Critical` e aviônica `InFlight`, libera `CriticalBattery` | só no oráculo |

## 4. Perguntas para a revisão

- **Q6.** A reação deve ser à **entrada** da bateria em `Critical` (`OneSlot`) ou à **permanência**
  nesse nível (`Level`)? O requisito de domínio não diz. É a lacuna que o relatório v4 (seção 5.13)
  e os testes de alcançabilidade (`cabal test validation-reach-tests`) reproduzem.
- **Q7.** Telemetria que chega com o slot ocupado deve ser **descartada** (`OneSlot`) ou preservada
  (`Queue`)? O relatório v4 mediu, com alfabeto reduzido e N = 8, que o descarte não muda o estado
  final; com o alfabeto completo de 20 ticks a exploração exaustiva encontra pares que diferem
  (ver `08_reprodutibilidade/logs/04_reach.txt`).
- **Q8.** A ordem de liberação `ShedLoad` antes de `LandedSignal` tem justificativa de domínio?
- **Q9.** O atraso de um tick entre a telemetria e a reação é um requisito ou um artefato do modelo?

## 5. Relação com a especificação em TLA+

`../../../04_tla/AvionicsLoop.tla` descreve as mesmas regras **sem olhar o código Haskell**, a
partir deste arquivo. As propriedades que ele verifica estão em `04_tla/README.md`.
