# 03_codigo — projeto cabal da Revisao_v5

```
cabal.project                 dois pacotes locais; tests: True
cabal.project.freeze          versões exatas das dependências (gerado por run_all.sh)
base/
  SNAPSHOT.md  MANIFEST.sha256  proveniência e hashes do instantâneo
  avionics-crem/              instantâneo CONGELADO do commit 9689ce8 (NÃO alterar)
validation/                   pacote novo: avionics-validation
  src/Validation/
    Types.hs                  tipos compartilhados (Pw, Policy, Group, StepSum)
    Boundary.hs               fronteira tipada: String -> Either BoundaryError AvEvent; formato de cenário (.scn)
    Table.hs                  lê spec/*.csv, valida (função total e determinística), funções totais
    RefModel.hs               oráculo do laço fechado, guiado pelas tabelas; políticas OneSlot, Queue, Level
    Compare.hs                comparador de traços: CREM x oráculo, passo a passo; primeira divergência
    Reach.hs                  alcançabilidade exaustiva do laço (a própria implementação, via withSomeSing)
  test/                       as quatro suítes e os geradores Hedgehog
  spec/                       transition_table.csv, power_table.csv, POLITICAS.md  (para a orientação revisar)
  scenarios/                  cenários no formato da fronteira (traço de regressão prioritário)
  scripts/                    negative_matrix.sh (rejeição com causa conferida), mutation.sh (mutação do CREM)
```

## Comandos

Na pasta `03_codigo/` (**sempre com alvo explícito**: `cabal build all` e `cabal test` sem alvo tentam construir o teste de
invalidez do pacote base, que **não compila de propósito**).

```bash
cabal build avionics-validation:lib:avionics-validation
cabal test avionics-validation:test:validation-conformance-tests   # tabelas x CREM, exaustivo
cabal test avionics-validation:test:validation-boundary-tests      # contrato da fronteira
cabal test avionics-validation:test:validation-reach-tests         # alcançabilidade exaustiva
cabal test avionics-validation:test:validation-model-tests         # Hedgehog, com mutantes (falhas esperadas impressas)
bash validation/scripts/negative_matrix.sh                         # 16 pares, causa conferida
bash validation/scripts/mutation.sh                                # mutação do CREM (lenta; cópia temporária)
```

As suítes leem `spec/` e `scenarios/` por caminho relativo à pasta `validation/` (o `cabal test` já roda lá).

**Cuidado com `cabal run avionics-sim`:** sem argumento, o executável grava os diagramas em `../../Obsidian/documentation`
relativo ao diretório **atual**. A partir de `03_codigo/` isso aponta para o vault real do IC (`IC/Obsidian/documentation`).
Rode-o sempre com uma pasta explícita: `cabal run avionics-crem:exe:avionics-sim -- <pasta>`. O `run_all.sh` não o executa.

## O que o pacote é e não é

* **É** um segundo caminho (tabela → oráculo → comparação, e alcançabilidade) para conferir a implementação em CREM.
* **Não é** independente de autoria: tabela, oráculo, TLA+ e implementação foram escritos pela mesma pessoa.
* O oráculo **não** usa `Avionics.Naive.transition` nem `avionicsAction`; usa só os tipos de dados (estado, evento, saída).
* `Reach.cremNext` **usa** o `closedLoop` do CREM (com `Feedback`, `Mission` e as ações reais) em um terno de vértices qualquer;
  a hipótese de que o futuro depende só do terno vale por construção e é conferida por `faithful`.
* O pacote base **não foi tocado**: a hipótese de teste do CREM continua a do relatório v4.

## Dependências novas

`hedgehog` 1.7 (e ~30 pacotes transitivos, do Hackage) só na suíte `validation-model-tests`. As outras três suítes e a
biblioteca usam apenas `base`, `containers`, o pacote base, `crem` e `singletons-base`.
