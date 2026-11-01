# Estado da Arte — rascunho

Rascunho para a seção 4 do relatório, atendendo ao Parecer 2. Regra seguida: só entra o que está na base anexada (Malakhovski e Shalyto, Perone e Karachalias, Wadler, Jahn, Maia, Bocchino, mais Hutton, Milewski e Oliveira como apoio). Onde falta fonte, está escrito **[LACUNA]**; nada foi preenchido de memória. Os resultados experimentais citados vêm de `others/avionics-crem/` e das saídas em `aviso_exaustividade.txt` e `erro_invalidez_inflight_shutdown.txt`.

Limitação do levantamento: os textos anexados não são uma revisão sistemática da literatura. Eles permitem descrever e comparar quatro abordagens, mas não afirmar que o conjunto cobre a fronteira do conhecimento. Essa afirmação exigiria busca em bases de artigos, ainda não feita (ver as lacunas ao final).

---

## 1. O problema, como as fontes o descrevem

Malakhovski e Shalyto (2009) tratam de autômatos finitos "estruturais", que reagem a eventos, em linguagens funcionais puras. Eles observam que, em linguagens imperativas, o estado do autômato costuma ficar em um campo de classe ou em uma variável global, o que não existe em uma linguagem pura; logo, os métodos imperativos não podem ser aplicados diretamente em Haskell. Observam também que os identificadores de estado, nas versões imperativas, costumam ser inteiros ou cadeias (às vezes agrupados em um `enum`), e que isso não oferece um nível aceitável de verificação quando a função de transição é escrita à mão.

Perone e Karachalias (2023) partem de outro incômodo: a distância entre o modelo teórico do domínio e a implementação concreta, que se parece com a documentação desatualizada. Propõem construir arquiteturas como composição de máquinas de estados, com implementação que possa ser representada graficamente.

## 2. As quatro abordagens comparadas

### 2.1 FSM imperativa

O exemplo de Malakhovski e Shalyto (2009, p. 21) é um interruptor de lâmpada em C: um `enum` de eventos, um `enum` de estados, uma variável global `current_state` e uma função `got_event` com `switch`. Os autores notam que nada na implementação impede, por exemplo, comparar o estado com um evento, o que seria um erro. A verificação de que a máquina está correta fica com os testes em tempo de execução. A afirmação de que testes unitários detectam esses erros apenas em tempo de execução é do próprio relatório, e a comparação quantitativa de taxas de erro entre as abordagens **[LACUNA: nenhuma fonte da base mede isso]**.

### 2.2 Haskell ingênuo (tipos algébricos e casamento de padrões)

Na versão Haskell do mesmo exemplo (Malakhovski e Shalyto, 2009, p. 21), estados e eventos são tipos de dados algébricos e a função de transição é definida por equações. Os autores afirmam que o compilador verifica a tipagem e também a completude e a ausência de contradições da função; no exemplo deles, uma equação supérflua faz o GHC emitir um aviso. A execução sobre uma lista de eventos é uma dobra à esquerda (`applyEvents = foldl`), e o tipo `SwitchFunc state event = state -> event -> state` permite reaproveitar a dobra em qualquer autômato.

Resultado experimental deste projeto (GHC 9.6.7): retirar um par (estado, evento) de `transition` produz um aviso `-Wincomplete-patterns` que nomeia o par omitido, e a compilação só falha com `-Werror`. Dois pontos que as fontes não destacam: a função com equação curinga (`_`) escapa dessa verificação, e o compilador não confere se a tabela é a pretendida, apenas se está completa.

### 2.3 Haskell com State Monad

O mesmo artigo constrói uma mônada própria, `newtype FSM state a = FSM (state -> (state, a))`, com `getState` e `setState`, de modo que uma sequência de eventos vira um bloco `do` (Malakhovski e Shalyto, 2009, pp. 21–22). Wadler (1992, seções 1 e 4) mostra como mônadas permitem escrever em linguagem pura programas que manipulam estado; ele destaca que a técnica aumenta a legibilidade e elimina erros bobos, como passar o valor errado de um contador. Hutton (2016, cap. 12) apresenta a versão da State Monad como função de estado em par `(valor, novo estado)`, que é a usada neste projeto.

Do lado categorial, Milewski (2020, cap. 4) e Maia (2022, seção 4) apresentam a composição de Kleisli, e Bocchino (2025, §4 a §7) mostra que as leis da mônada de Haskell equivalem à associatividade e às identidades dessa composição e que, a partir delas, se obtém a categoria de Kleisli. Jahn (2020, cap. 2) formaliza a mônada como monoide na categoria dos endofuntores.

Contribuição deste projeto nesta linha, a ser conferida contra a literatura: as três leis foram provadas à mão para a instância `ST` e conferidas por exemplo (`Avionics/StateMonad.hs`), e a execução com a mônada coincide com a execução por `mapAccumL`, o que mostra que a mônada organiza o código mas não é necessária para produzir saída por transição. Se há trabalho publicado que faça a mesma verificação **[LACUNA: busca não feita]**.

Limite: o tipo `ST s a` diz qual é o tipo do estado, mas não quais transições entre estados são permitidas. Qualquer função `s -> (a, s)` serve.

### 2.4 CREM

Perone e Karachalias (2023) definem máquina de estados como máquina de Mealy: uma função com estado e o valor atual do estado, que a cada entrada emite uma saída e atualiza o estado. As transições permitidas são descritas por uma topologia, promovida ao nível de tipos; a classe `AllowedTransition` procura a aresta na topologia, com uma instância de aresta identidade (Fig. 4), e o construtor de resultado das ações só aceita transições para as quais essa prova exista. As máquinas são folhas de uma árvore (`Basic`) combinadas por `Sequential`, `Parallel`, `Alternative`, `Feedback` e `Kleisli`, que se apoiam nas classes `Category`, `Profunctor` e `Arrow`. A representabilidade, no sentido dos autores, é a capacidade de gerar uma representação gráfica a partir da implementação.

Os autores mencionam o pacote `motor`, que também gera representação gráfica, mas se concentra em máquinas únicas, enquanto o CREM acrescenta composição (Perone e Karachalias, 2023, introdução). Também citam o pacote `machines`. O conteúdo desses dois pacotes não está na base **[LACUNA: sem fonte; só a menção em Perone e Karachalias]**.

Limitações declaradas pelos próprios autores (seção 6): a topologia guarda apenas as transições permitidas, sem ligação com as entradas que as disparam; a implementação não aproveita concorrência nem paralelismo; `Sequential` e `Kleisli` poderiam ser unificados. Os autores também sugerem como trabalho futuro exportar a topologia para linguagens como TLA+ ou Alloy e testar invariantes com lógica temporal linear.

Resultado experimental deste projeto (`others/avionics-crem`):

- Uma transição fora da topologia (`InFlight → Shutdown` via `pureResult`) é rejeitada pelo GHC com a mensagem `Could not deduce AllowedTransition (Topology '[]) InFlight Shutdown`; o texto integral está em `erro_invalidez_inflight_shutdown.txt`.
- A garantia vale por aresta: a sequência `InFlight → EmergencyLanding → Grounded → Shutdown` é aceita.
- Uma topologia completa, como a da catraca, não rejeita nada.
- A composição foi exercitada com `Parallel`, `Sequential` e `Alternative` (aviônica e energia). `Feedback` e `Kleisli` não foram exercitados.

## 3. Quadro comparativo

| Critério | Imperativa | Haskell ingênuo | State Monad | CREM |
|---|---|---|---|---|
| Onde fica o estado | Campo de classe ou variável global (Malakhovski e Shalyto) | Argumento e resultado da função de transição | Dentro da computação `s -> (a, s)` | Dentro de cada máquina; `run` devolve a máquina atualizada (Perone e Karachalias) |
| Identificadores de estado | Inteiros, cadeias ou `enum` | Tipo algébrico | Tipo algébrico | Tipo algébrico promovido a tipo (`singletons`) |
| Completude da função de transição | Testes | Aviso do GHC; erro com `-Werror`; curinga escapa | Igual ao ingênuo (a lógica é a mesma função) | Igual, sobre os singletons e os eventos |
| Transição fora do modelo | Testes | Não detectada | Não detectada | Rejeitada por aresta (compilação) |
| Relação evento → aresta | Código | Código | Código | Só no código (limitação declarada pelos autores) |
| Saída por transição | Variável de saída | Máquina de Mealy via `mapAccumL` | Valor da computação | Saída da ação (`ActionResult`) |
| Composição | Manual | Manual | Kleisli (`>=>`), com leis a provar | `Sequential`, `Parallel`, `Alternative`, `Feedback`, `Kleisli` |
| Representação gráfica | Não prevista | Não prevista | Não prevista | Módulo `Render` (Mermaid) |
| Fontes na base | Malakhovski e Shalyto | Malakhovski e Shalyto; Hutton | Wadler; Hutton; Milewski; Maia; Jahn; Bocchino; Malakhovski e Shalyto | Perone e Karachalias |

As linhas "Fontes" e os comentários entre parênteses indicam onde a base sustenta a célula. As demais células resultam de experimentos deste projeto (aviso de exaustividade, erro de invalidez, execução de `Compose.hs`) ou do código-fonte do pacote `crem` 0.1.0.0, que não é fonte teórica da base.

## 4. Posição do trabalho

O trabalho se situa entre a terceira e a quarta abordagens: usa a State Monad e a composição de Kleisli como fundamento e o CREM como veículo de segurança de transição e de composição. O que ele pode acrescentar, condicionado à busca ainda não feita: (a) um caso de aviônica com teste de rejeição documentado com mensagem real do compilador; (b) a prova das leis da mônada para a instância usada, e não apenas a citação delas; (c) a observação de que a garantia do CREM é por aresta e de que uma topologia completa, como a da catraca, não rejeita nada.

## 5. Lacunas de fonte (a preencher antes de escrever a versão final)

1. Artigos de conferência e periódicos sobre FSMs em linguagens funcionais com tipos avançados (o relatório já registra que ainda faltam). **[LACUNA]**
2. Outras bibliotecas de máquinas de estados em Haskell além das que Perone e Karachalias apenas mencionam (`motor`, `machines`). **[LACUNA]**
3. Abordagens com tipos dependentes ou linguagens como Idris e Agda para o mesmo problema. **[LACUNA: nada na base]**
4. Statecharts e máquinas hierárquicas (há nota em `Obsidian/concepts/`, mas não há fonte da base). **[LACUNA]**
5. Verificação formal de modelos (TLA+, Alloy) para validar propriedades de alcançabilidade; só há a menção em Perone e Karachalias como trabalho futuro. **[LACUNA]**
6. Mealy (1955), citado por Perone e Karachalias como origem da máquina de Mealy; não está na base. **[LACUNA]**
7. Dados empíricos de comparação entre implementações imperativas e funcionais (taxas de erro, esforço de manutenção). **[LACUNA]**
8. Requisitos de segurança do domínio de aviônica, se o estudo de caso for apresentado como relevante para esse domínio; hoje a aviônica é só um domínio de exemplo escolhido pelo projeto. **[LACUNA]**
9. Textos primários de *Domain-Driven Design* (Evans, 2003, citado por Perone e Karachalias, não está na base).
10. Malakhovski e Shalyto está em russo; as páginas 20 e 21 foram lidas diretamente no PDF por esta revisão (a página 22 só pela extração de texto do código), e convém conferir a tradução usada no relatório antes de entregar.

## 6. Referências usadas neste rascunho (todas da base)

BOCCHINO JR., R. L. *Monads, Categories, and Computation*. 2025.
HUTTON, G. *Programming in Haskell*. 2. ed. 2016.
JAHN, M. *Monads and their Applications in Haskell*. 2020.
MAIA, D. *Applied Category Theory: Monads and Haskell*. 2022.
MALAKHOVSKI, Y. M.; SHALYTO, A. A. Máquinas de estados finitos em linguagens de programação funcional pura. *RSDN Magazine*, n. 1, 2009.
MILEWSKI, B. *Category Theory for Programmers*. 2020.
PERONE, M.; KARACHALIAS, G. *Crème de la Crem: Composable Representable Executable Machines*. 2023.
WADLER, P. Comprehending Monads. *Mathematical Structures in Computer Science*, v. 2, n. 4, 1992.
