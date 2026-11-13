# Especificação TLA+ do laço fechado (nível 2 do parecer de 03/11/2026)

**Status: executada no TLC em 13/11/2026 (TLC 2.19, TLA+ Tools 1.7.4, Java 8).** O `tla2tools.jar` foi baixado da release
estável v1.7.4 de https://github.com/tlaplus/tlaplus/releases (2 274 532 bytes, sha256
`936a2620...0e88`; fica em `tools/`, não versionado). A prerelease v1.8.0 existe e **não** foi usada.
O TLC verifica o **modelo**, não a implementação Haskell; ver a conferência cruzada abaixo.

## O que é

`AvionicsLoop.tla` descreve o laço aviônica ‖ energia → ambiente **a partir das tabelas
revisáveis** (`03_codigo/validation/spec/transition_table.csv`, `power_table.csv`, `POLITICAS.md`), e
não do código Haskell. É o terceiro artefato independente do código em teste, ao lado do oráculo
guiado por tabela (`Validation.RefModel`) e da implementação em CREM. Os três foram escritos pela
mesma pessoa (ver `06_artigos/AMEACAS_A_VALIDADE.md`).

Modelagem: cada **sinal processado** é um passo (`Step`); a fila de sinais de um tick guarda o `Beat`,
o comando e a energia; o que o ambiente libera entra **na frente** da fila (profundidade primeiro,
como o `Feedback` do CREM). `Tick` só começa com a fila vazia.

A constante `Policy` escolhe a política do ambiente: `"OneSlot"` (a do projeto) ou `"Level"`.
A `Queue` existe só no oráculo Haskell.

## Propriedades e o resultado esperado

| Propriedade | Linha do parecer | `OneSlot` | `Level` |
|---|---|---|---|
| `TypeOK`, `QueueBounded` (invariantes) | composição; terminação | vale | vale |
| `NoDirectInFlightShutdown` | segurança da topologia | vale | vale |
| `ShutdownOnlyFromGrounded`, `EmergencyOnlyFromFlight` | propriedades de sequência (v4, 5.11) | vale | vale |
| `EventDestination` (`TakeoffSignal` em `Grounded` leva a `InFlight`) | evento e destino | vale | vale |
| `LoopTerminates` (`[]<>(queue = <<>>)`) | progresso / terminação | vale | vale |
| `NoPermanentBlindness` (`[]<>(~(av = InFlight /\ pw = Critical))`) | política de bateria | **violada** | vale |

Contraexemplo esperado de `NoPermanentBlindness` com `OneSlot`: `Drain, Drain, TakeoffSignal` e depois
ticks ociosos para sempre (o estado `(InFlight, Critical, Standby)` não tem saída sem entrada nova).
A coluna "esperado" vinha da exploração em Haskell; o TLC **confirmou** todas as linhas (ver "Resultado do TLC").

## Resultado do TLC (13/11/2026)

| Configuração | Código de saída | Resultado |
|---|---|---|
| `AvionicsLoop_OneSlot.cfg` | 13 (propriedade temporal violada) | **viola `NoPermanentBlindness`**; contraexemplo em laço: `Drain`, `Drain`, `TakeoffSignal`, depois ticks sem efeito, com `av = InFlight` e `pw = Critical` |
| `AvionicsLoop_OneSlot_sem_cegueira.cfg` | 0 | com `OneSlot`, **todas as outras propriedades valem** (o TLC para na primeira violação; por isso a configuração separada) |
| `AvionicsLoop_Level.cfg` | 0 | **todas as propriedades valem** |

Em todas: 1 143 estados distintos, 1 638 gerados (profundidade 16 em `OneSlot`, 17 em `Level`). Logs: `08_reprodutibilidade/logs/14_tlc_*.txt`.

**Conferência cruzada com o Haskell** (`cross_check.py`): o conjunto de ternos (aviônica, energia, ambiente) com a fila vazia, no
dump do TLC, tem **26** elementos e é **idêntico** ao que `cabal test validation-reach-tests` imprime. Dois caminhos independentes de
código (a implementação em CREM e uma especificação em TLA+ escrita a partir das tabelas) chegam ao mesmo espaço de estados e à mesma
conclusão sobre a política da bateria. A independência é de código, **não de autoria**: o mesmo autor escreveu os dois.

## Como rodar

Pré-requisitos: Java e `tools/tla2tools.jar` (v1.7.4 estável; o comando de download e o sha256 estão no cabeçalho de `run_tlc.sh`).

```bash
bash 04_tla/run_tlc.sh     # roda as três configurações, confere os códigos de saída e compara com o Haskell
```

Se os resultados divergirem do esperado, o erro pode estar na especificação, no oráculo ou na implementação: investigar antes de concluir qual.

## Correspondência com o modelo Haskell (para conferir os números do TLC)

* O modelo Haskell tem 26 ternos (aviônica, energia, ambiente) alcançáveis entre os 48 possíveis,
  com 20 entradas de tick e 520 arestas. O TLC conta estados **intermediários** (com a fila): 1 143. O que coincide é o conjunto de
  ternos com a fila vazia (26, idêntico, conferido por `cross_check.py`).
* No máximo 5 passos por tick (Beat, até 2 liberações, comando, energia); a fila tem no máximo 4 sinais.

## Limites

* O TLC analisou a especificação sem erro de sintaxe ou de semântica, mas ela foi escrita pelo mesmo autor do código.
* O TLC verifica o **modelo**, não a implementação Haskell (o parecer faz a mesma ressalva).
* As propriedades temporais dependem das hipóteses de justiça (`WF` de `Step` e de `Tick`): há infinitos
  ticks, mas as entradas de cada tick são livres (inclusive ociosas para sempre).
