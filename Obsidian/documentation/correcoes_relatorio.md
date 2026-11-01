# Correções ao relatório parcial (versão revisada)

Este arquivo reúne o texto revisado das seções §2.2.2, §5.2, §5.4, §5.7, §5.9, §5.11 e §5.12, mais notas sobre DDD, Bocchino e os pareceres. O relatório original (`ProjectPapers/RELATORIO_PARCIAL_PIC_Fatec_BS.pdf`) e o `Arquivo final.md` não foram alterados.

Todo o código e todas as saídas citadas vêm de `others/avionics-crem/` e foram obtidos com GHC 9.6.7 e cabal 3.12.1.0 nesta máquina. As mensagens do compilador estão em `aviso_exaustividade.txt` e `erro_invalidez_inflight_shutdown.txt`, sem edição.

Convenções do texto: poucas ênfases, paráfrase em vez de citação direta, e termos técnicos explicados na primeira ocorrência. Onde o conteúdo não tem apoio na base de referências anexada, está marcado como **[fora da base]** ou **[sem fonte]**.

---

## §2.2.2 Pattern Matching e Completude Funcional (revisado)

A função de transição é escrita por casamento de padrões (*pattern matching*): cada equação diz qual é o resultado para uma forma possível dos argumentos (Hutton, 2016, cap. 4). Como o estado e o evento são tipos soma com um número finito de construtores, o compilador consegue listar todos os pares (Estado, Evento) e conferir se cada um tem uma equação.

O GHC faz essa conferência, mas o resultado é um aviso, não um erro. Quando falta um par, o compilador emite o aviso `-Wincomplete-patterns`, que já vem ligado em `-Wall` e informa qual par ficou sem tratamento. O aviso só impede a compilação se o projeto pedir isso, com `-Werror` ou, de forma mais precisa, `-Werror=incomplete-patterns`. Na saída real do GHC 9.6.7 sem a opção, o programa compila e o aviso aparece; com a opção, a compilação falha no mesmo ponto (`aviso_exaustividade.txt`).

Duas condições, portanto, sustentam a completude funcional: a opção de erro precisa estar ligada (o `.cabal` de `avionics-crem` a liga) e a função não pode usar uma equação curinga (`_`), porque o curinga cobre qualquer par restante e esconde justamente as omissões. A versão anterior de `AvionicsFSM.hs` tinha um curinga na última equação, o que anulava a verificação; a versão nova escreve os 16 pares um a um.

Malakhovski e Shalyto afirmam que, com tipos de dados algébricos, o compilador de Haskell verifica a completude e a ausência de contradições na função de transição (2009, p. 21). No exemplo que eles mostram, uma equação supérflua faz o compilador emitir um aviso, o que concorda com o comportamento descrito acima.

---

## §5.2 A função de transição δ como morfismo em Hask (revisado)

A função δ : Q × Σ → Q foi implementada por casamento de padrões:

```haskell
transition :: State -> Input -> State
transition Locked   Coin = Unlocked
transition Locked   Push = Locked
transition Unlocked Coin = Unlocked
transition Unlocked Push = Locked
```

A assinatura `State -> Input -> State` é a forma *curried* de uma função cujo domínio é o par (State, Input). Currying é a equivalência entre uma função de dois argumentos `(a, b) -> c` e uma função que recebe um argumento e devolve outra, `a -> b -> c`; Milewski (2020, cap. 9, §9.2) a explica, e o cap. 9 a relaciona ao objeto exponencial; Hutton (2016, §3.6) trata o mesmo assunto sob o nome de funções *curried*. O domínio (State, Input) é o produto categorial, o mesmo construído por Milewski (2020, cap. 5) para pares. Assim, a assinatura em Haskell e a definição matemática de δ correspondem diretamente.

Sobre a completude: o GHC examina as quatro equações e avisa se algum dos quatro pares (2 × 2) faltar. Esse aviso pode ser promovido a erro de compilação (ver §2.2.2). Hutton (2016, §3.1) lembra que a inferência de tipos acontece antes da execução, de modo que erros de tipo não ocorrem durante a avaliação; a verificação de exaustividade é uma checagem adicional, feita também em tempo de compilação, mas de natureza diferente da checagem de tipos.

Limite desta verificação: o compilador confere que cada par tem uma equação, não que a equação seja a correta. Trocar `transition Locked Push = Locked` por `= Unlocked` compila sem aviso.

---

## §5.4 Da composição ingênua à abstração monádica (revisado)

A composição por `foldl` é suficiente enquanto o resultado de cada passo é só o novo estado. Quando se quer também uma saída por transição (por exemplo, uma mensagem de telemetria), há duas formulações equivalentes.

A primeira não usa mônada: é a máquina de Mealy, em que cada passo tem o tipo (Q, Σ) → (Q, Saída). Ela pode ser executada sobre uma lista com `mapAccumL`, que carrega o estado como acumulador e coleta as saídas. Em `Avionics.Naive.runMealy` isso é feito em poucas linhas.

A segunda é a State Monad, em que o passo é uma função `Σ -> ST Q Saída`. Em `Avionics.StateMonad`, as duas formulações foram executadas sobre as mesmas sequências de eventos, a partir dos quatro estados iniciais, e produziram os mesmos pares (saídas, estado final). A saída por transição, portanto, não exige mônada.

O que a formulação monádica acrescenta é outra coisa: os passos passam a ser funções `a -> ST s b` que se compõem com o operador `>=>` de Kleisli (Milewski, 2020, cap. 4), de modo que um passo posterior pode depender da saída de um anterior sem que o estado seja passado à mão. Em `Avionics.StateMonad`, a função `reaction` faz isso: ela recebe a saída de um passo e escolhe o próximo evento. Além disso, a mesma forma `a -> m b` vale para outros efeitos além do estado (Milewski, 2020, usa o `Writer` no cap. 4; Maia, 2022, seção 4, usa o mesmo exemplo). O argumento a favor da State Monad é, portanto, composição e generalidade, e não necessidade para produzir saída.

A formulação anterior do texto, que o ponto exato em que `foldl` deixaria de ser suficiente seria o aparecimento de saídas, deve ser removida.

---

## §5.7 Fundamentação categorial: monad como monoide na categoria dos endofuntores (revisado)

Um endofuntor é um functor de uma categoria nela mesma; em Haskell, é um construtor de tipo `m` com `fmap`. Uma mônada é um endofuntor com duas transformações naturais, `join` (achata `m (m a)` em `m a`) e `return` (injeta `a` em `m a`), que obedecem a leis de associatividade e de unidade com a mesma forma das leis de um monoide. É a leitura "monoide na categoria dos endofuntores", que aparece em Milewski (2020, cap. 22) e em Jahn (2020, cap. 2).

Para o projeto, o que importa é a consequência prática: a composição de Kleisli `>=>` é associativa e tem `return` como identidade. Mas isso só vale se a instância cumprir as leis, e o GHC não as verifica: uma instância `Monad` que as violasse compilaria normalmente. Por isso as leis foram provadas para a instância `ST`, em comentário no arquivo `Avionics/StateMonad.hs`, por raciocínio equacional (Hutton, 2016, §16.1; as leis são enunciadas em §12.3). Resumo das provas:

- Identidade à esquerda, `return a >>= f = f a`: substituir a definição de `>>=` e de `return`, e simplificar o `let` sobre um par conhecido.
- Identidade à direita, `m >>= return = m`: o `let` devolve o par `(fst p, snd p)`, que é igual a `p`.
- Associatividade, `(m >>= f) >>= g = m >>= (\x -> f x >>= g)`: expandir os dois lados e achatar os `let` aninhados; os dois lados ficam idênticos.

As provas supõem computações totais e ausência de `seq` (hipótese que Hutton, 2016, §12.4, também faz ao tratar de functores). Bocchino (2025, §4.4 a §4.6 e §6.4) mostra que as três leis de Haskell são, em essência, a associatividade e as identidades da composição de Kleisli, o que justifica o caminho inverso, de `ST` para `>=>`, usado no arquivo. Esses resultados foram também conferidos por exemplo, para todos os 4 estados e 4 eventos (`lawChecks`: sete verificações das leis e duas de consistência com `runMealy` e `foldr (>=>)`, todas aprovadas).

A frase "a generalização monádica é pré-requisito porque o CREM exige `Applicative m`" deve ser removida. `Applicative` é uma interface mais fraca que `Monad`: oferece `pure` e `<*>`, mas não `>>=`. No código do `crem` 0.1.0.0, `pureResult` exige `Applicative m`, enquanto a execução (`run`) e o sinônimo `StateMachine` exigem `Monad m`. Isso mostra que o CREM é parametrizado por um efeito `m`; não mostra que a State Monad seja necessária. O CREM nem usa a State Monad: o estado fica dentro da própria máquina, e `run` devolve a máquina com o estado atualizado. A relação entre os dois é de analogia, e não de dependência. (Verificado no código-fonte do pacote, que é o objeto de estudo, e não uma fonte da base teórica.)

---

## §5.9 Verificação de segurança de tipos em tempo de compilação (revisado)

O CREM descreve as transições permitidas por uma topologia, e a ação de cada máquina devolve um `ActionResult` construído com `pureResult`. Essa função exige a restrição `AllowedTransition topologia vértice-inicial vértice-final`, uma classe de tipos que o GHC resolve procurando a aresta na lista da topologia. A classe tem ainda uma instância de aresta identidade, `AllowedTransition topologia a a`, que torna sempre permitida a permanência no mesmo vértice (Perone e Karachalias, 2023, Fig. 4). Por isso uma topologia admite sempre as auto-transições, mesmo sem listá-las; a afirmação anterior de que o CREM as proibiria estava errada.

A catraca não serve como teste de rejeição. Sua topologia tem as arestas `Locked → Unlocked` e `Unlocked → Locked`; somadas às arestas identidade, resultam todos os quatro pares de vértices. Com um grafo completo, nenhuma equação de `turnstileAction` pode ser rejeitada. Em particular, `turnstileAction SLocked Push = pureResult "..." SUnlocked`, citada na versão anterior como rejeitada, compila, porque `Locked → Unlocked` existe. A catraca ilustra a sintaxe do CREM, mas não a rejeição.

O teste foi feito, então, com a máquina de aviônica de um UAV (veículo aéreo não tripulado), cuja topologia é:

```
Grounded         -> InFlight, Shutdown
InFlight         -> EmergencyLanding
EmergencyLanding -> Grounded
```

Não existe a aresta `InFlight → Shutdown`: desligar o sistema em voo é proibido. O módulo `invalid/InvalidInFlightShutdown.hs` tenta essa transição:

```haskell
invalidInFlightShutdown SInFlight _ = pureResult MsgShutdown SShutdown
```

Ele fica fora do build principal (é um alvo de teste do cabal, construído apenas com `cabal build invalid-inflight-shutdown --enable-tests`). A compilação falha, e a mensagem real do GHC 9.6.7 é:

```
invalid\InvalidInFlightShutdown.hs:23:39: error: [GHC-39999]
    * Could not deduce `Crem.Topology.AllowedTransition
                          (Crem.Topology.Topology '[]) InFlight Shutdown'
        arising from a use of `pureResult'
      from the context: Applicative m
        bound by the type signature for:
                   invalidInFlightShutdown :: forall (m :: * -> *).
                                              Applicative m =>
                                              SAvionicsVertex InFlight
                                              -> AvEvent
                                              -> ActionResult
                                                   m
                                                   AvionicsTopology
                                                   SAvionicsVertex
                                                   InFlight
                                                   Output
        at invalid\InvalidInFlightShutdown.hs:(18,1)-(22,69)
      or from: ()
        bound by a pattern with constructor:
                   SInFlight :: SAvionicsVertex InFlight,
                 in an equation for `invalidInFlightShutdown'
        at invalid\InvalidInFlightShutdown.hs:23:25-33
    * In the expression: pureResult MsgShutdown SShutdown
      In an equation for `invalidInFlightShutdown':
          invalidInFlightShutdown SInFlight _
            = pureResult MsgShutdown SShutdown
```

O trecho `Topology '[]` indica como a busca termina: as instâncias de `AllowedTransition` vão descartando as arestas da topologia uma a uma, e, ao chegar à lista vazia sem ter encontrado `InFlight → Shutdown`, o GHC fica sem evidência e rejeita a expressão. Essa é a prova de que a regra de negócio foi checada antes de o programa existir. O texto completo, com o cabeçalho do experimento, está em `erro_invalidez_inflight_shutdown.txt`.

Há um limite que deve constar no relatório. A garantia vale para uma transição isolada. O caminho `InFlight → EmergencyLanding → Grounded → Shutdown` existe na topologia, de modo que a regra "nunca desligar em voo" é respeitada para a aresta direta, mas não é uma propriedade de todas as sequências de eventos. Provar propriedades de alcançabilidade exigiria outra técnica.

---

## §5.11 Limitações identificadas e encaminhamentos (revisado)

1. O evento não faz parte do vértice. A topologia restringe apenas quais vértices podem suceder quais, e não qual evento causa cada transição. A relação entre eventos e arestas fica, portanto, só no casamento de padrões da ação. Perone e Karachalias (2023, seção 6) registram a mesma limitação como trabalho futuro: não há ligação entre as transições permitidas e as entradas que as disparam.

2. Termo "representável". No título e no resumo de Perone e Karachalias (2023), uma máquina "representável" é aquela cuja implementação se mantém sincronizada com sua representação gráfica, ou seja, da qual se gera um diagrama automaticamente. Isso não é a mesma coisa que o functor representável de Milewski (2020, cap. 14), que é um functor isomorfo ao functor de morfismos `Hom(a, -)`, isto é, uma espécie de contêiner indexado por chaves do tipo `a`, de que uma tabela de resultados memoizados de uma função é um caso. A ideia de usar o functor representável para indexar a topologia pelo alfabeto Σ é uma hipótese de trabalho do projeto, **[sem fonte]** que a sustente na base anexada, e deve ser apresentada como tal.

3. Os diagramas, que o texto anterior dava como pendentes, foram gerados com o módulo `Render` do CREM: `avionics_topology.mmd`, `power_topology.mmd` e `coupled_flow.mmd`, em `Obsidian/documentation/`, em formato Mermaid. Não foram renderizados por uma ferramenta Mermaid nesta máquina; só o texto gerado foi conferido. Um quarto arquivo, `uav_product.mmd` (grafo-produto da composição em paralelo, com 12 vértices), tem identificadores com parênteses e vírgulas e não foi validado; deve ser usado com cautela.

4. Alcançabilidade. Ver o limite descrito no final do §5.9.

---

## §5.12 Síntese geral e validação preliminar das hipóteses (revisado)

Na implementação ingênua, a verificação de corretude é a exaustividade do casamento de padrões, que o GHC executa como aviso e que o projeto promove a erro com `-Werror=incomplete-patterns`; a sequência de eventos é percorrida com `foldl` ou `mapAccumL`. Na etapa monádica, a State Monad e a composição de Kleisli organizam a passagem de estado e saída; as três leis da mônada foram provadas à mão para a instância usada, e conferidas por exemplo. Na etapa do CREM, a prova `AllowedTransition` é exigida pelo compilador, e uma transição fora da topologia é rejeitada em tempo de compilação, como mostra a mensagem real do §5.9.

Quanto à composição, a versão anterior afirmava ter generalizado o mecanismo para `Sequential` e `Parallel`, e ao mesmo tempo admitia que a composição não havia sido feita. A afirmação não era sustentável. Agora há composição real, em `Avionics/Compose.hs`:

- `Parallel`: aviônica e energia (`PowerFSM`, com os vértices `Charged`, `Low` e `Critical`) rodam lado a lado, cada uma com seu estado e sua topologia.
- `Sequential` com `Alternative`: a saída da máquina de energia é traduzida por uma máquina sem estado em um evento de aviônica; um nível de bateria crítico produz o evento `CriticalBattery`, que faz a aviônica passar de `InFlight` para `EmergencyLanding`. Esse comportamento foi observado na execução (`cabal run`).

Os construtores `Feedback` e `Kleisli` não foram exercitados.

Avaliação das hipóteses, com o que está e o que não está estabelecido:

- Completude funcional: confirmada para a função de transição de aviônica (16 pares escritos um a um), com a ressalva de que depende de `-Werror=incomplete-patterns` e da ausência de curinga (§2.2.2).
- Segurança de tipos: confirmada no sentido de que uma aresta ausente na topologia é rejeitada em compilação; não cobre sequências de transições nem a relação entre eventos e arestas (§5.9 e §5.11).
- Composabilidade: demonstrada para `Basic`, `Sequential`, `Parallel` e `Alternative`; falta `Feedback`/`Kleisli`, e a propriedade de que a composição preserva as garantias de cada folha ainda não foi formalizada, apenas observada.
- A afirmação de "superioridade" sobre linguagens imperativas, presente nas hipóteses, só pode ser avaliada na Fase 4, com a comparação qualitativa prevista no cronograma; nenhum experimento dessa comparação foi feito até aqui.

---

## Notas adicionais

### Sobre DDD (§2.4)

A menção ao *Domain-Driven Design* aparecia sem referência. Duas opções:

1. Remover a frase "o projeto alinha-se aos princípios do DDD", que não é um objetivo do trabalho.
2. Mantê-la com apoio na base: o CREM foi concebido por Perone e Karachalias (2023, seção 2) a partir de ideias de DDD, tratando agregados, políticas e projeções como máquinas de estados. A apresentação do DDD é dessa fonte. Os textos primários sobre DDD, que o artigo cita (por exemplo Evans, 2003), **não estão na base anexada**.

Texto sugerido para a opção 2: "O CREM nasce de ideias do *Domain-Driven Design*, em que partes do domínio de um sistema (agregados, políticas e projeções) são modeladas como máquinas de estados (Perone e Karachalias, 2023). Neste trabalho o interesse recai sobre a composição dessas máquinas, e não sobre o DDD em si." Nas listas de siglas, manter DDD só se a opção 2 for adotada.

### Bocchino nas referências

Bocchino (2025) está na lista de referências, mas não é citado no texto. Passa a ser citado onde as leis da mônada são tratadas (§2.3.1 e §5.7): "as leis de identidade e de associatividade da mônada correspondem à associatividade e às identidades da composição de Kleisli (Bocchino, 2025, §4.4 a §4.6)". A categoria de Kleisli é construída em Bocchino (2025, §7).

### Autoria de Perone (2023)

O artigo tem dois autores: Perone e Karachalias. Nas citações, usar "Perone e Karachalias (2023)" e acertar a entrada em REFERÊNCIAS.

### Pareceres

- Parecer 1: reduzir o negrito, reservando-o a poucas expressões-chave; trocar citações diretas por paráfrase; explicar termos técnicos. Neste arquivo, as seções revisadas usam paráfrase e explicam endofuntor, functor representável, currying, produto e coproduto na primeira ocorrência. Falta aplicar o mesmo tratamento ao restante do relatório (Introdução, §2.1, §2.3, §2.4, §3, §5.1, §5.3, §5.5, §5.6, §5.8, §5.10).
- Parecer 2: pediu Estado da Arte. Rascunho em `estado_da_arte_rascunho.md`.
- Termos que merecem uma frase de explicação na primeira ocorrência no relatório: *coproduto* (o tipo soma é o coproduto: um valor é de um construtor ou de outro; `Bool = 1 + 1`); *singletons* (técnica que dá, a cada valor de um tipo enumerado, um tipo correspondente no nível dos tipos, de modo que o compilador possa raciocinar sobre ele; o CREM a usa por meio de Template Haskell); *morfismo*, *functor*, *endofuntor*.
