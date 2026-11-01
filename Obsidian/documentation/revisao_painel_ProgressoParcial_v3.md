# Revisão em painel — `ProgressoParcial_v3.tex`

Documento revisado: `ProjectPapers/ProgressoParcial_v3.tex` (27 páginas). O manuscrito não foi alterado. Âncoras são números de linha desse arquivo.

## Como esta revisão foi feita (limites)

- Modo `full`, cinco assentos: Revisor de Adequação (EIC), Revisores 1, 2 e 3, e o Advogado do Diabo. Os quatro cartões foram os mostrados na Fase 0 e aceitos por você ao delegar a decisão.
- **Os cinco assentos foram executados por uma única instância do modelo, em sequência, no mesmo contexto.** Cada relatório foi escrito pelo ângulo do seu cartão, mas eles não são independentes: o ponto cego de um é o ponto cego dos outros. A separação é de papel, não de erro.
- Os verificadores mecânicos do contrato de sprint do skill (`check_sprint_contract.py`, `check_panel_synthesis.py` e os anexos de acrônimos, referências sugeridas e afirmações) **não foram executados**. A decisão abaixo é qualitativa, não derivada por regra mecânica.
- Não consultei fontes externas à base do projeto. Onde um revisor sente falta de literatura, está marcado como **[sem fonte na base]**.
- Alvo de publicação: `criteria_binding_unavailable`. Nenhum julgamento de adequação a um periódico específico é feito.

---

## Relatório 1 — Revisor de Adequação (EIC)

**Pontos fortes**
- Honestidade sobre limites. A seção de limitações (l. 553 a 573) separa o que foi verificado em compilação, o que foi demonstrado e o que foi testado por enumeração. Isso é raro em relatórios parciais e deve ser preservado.
- Resultados reprodutíveis: versão do repositório (`c97981a`), versões de GHC e cabal, e saídas reais de compilador (l. 414 em diante).

**Problemas**
1. **Não há resumo nem palavras-chave** (o texto vai da capa direto ao sumário). Um relatório de iniciação científica deve ter resumo.
2. **O título promete mais do que o texto mostra.** "Completude Funcional via Monads" (l. 44): a completude vem do casamento de padrões e do `-Werror=incomplete-patterns`, não de mônadas, como o próprio §5.4 conclui (a saída por transição não exige mônada). Título e hipóteses (l. 154) não refletem esse achado.
3. **Contribuição não delimitada em relação ao CREM.** O texto mostra uma aplicação cuidadosa do CREM, mas não diz o que é novo em relação a Perone e Karachalias (2023). As candidatas existem (provas das leis para `ST`, o simulador em malha fechada, a análise "por aresta"), mas não estão declaradas como contribuição.
4. **Tempos verbais misturados.** As seções 1 e 3 ainda estão no futuro de proposta ("será demonstrado", l. 168; "será selecionado", l. 229) enquanto a §5 relata resultados. Falta dizer, objetivo por objetivo, o que foi cumprido.
5. **Parágrafos da introdução (l. 136 e 150) ainda dizem que a lógica de domínio é "validada pelo compilador antes da execução"**, o que a própria §5.12 qualifica. O texto antigo contradiz o novo.
6. **Cronograma sem coluna de situação**; não se vê o que já foi feito.
7. **Linguagem.** Misturam-se grafias do português europeu ("canónico", l. 177; "arquitetónico", "gerir", l. 197) com o brasileiro, e usa-se "Monads" e "mônadas" de forma alternada.

**Recomendação do assento:** revisão maior (ver decisão adiante). **Pontos cegos:** não avaliei as provas nem a validação.

---

## Relatório 2 — Revisor 1 (métodos e rigor formal)

**Pontos fortes**
- As provas equacionais das leis da mônada para `ST` (no código, resumidas nas l. 371 a 385) declaram as hipóteses usadas (sem `seq`, computações totais). É a forma correta de fazê-lo.
- Há um bloco de verificações com traços corrompidos à mão e um teste de mutação (l. 481 a 551), o que reduz o risco de propriedades vacuamente verdadeiras.

**Problemas**
1. **O oráculo da validação cruzada é circular.** A FSM ingênua e as ações do CREM foram escritas pela mesma pessoa a partir da mesma tabela de 16 pares. Que as duas coincidam em 85 e em 168 421 sequências mostra que o CREM executa a tabela, não que a tabela está certa. Nenhuma verificação confronta a tabela com uma especificação independente do domínio (por exemplo, as regras do enunciado original: "de `InFlight` só se vai a `EmergencyLanding`").
2. **Em malha fechada o ambiente foi desenhado para produzir exatamente as saídas esperadas.** A `Mission` libera `LandedSignal` logo após a emergência, sem sensor de pouso. Comparar a aviônica com a FSM ingênua "usando os eventos efetivamente recebidos" (l. 531) torna o teste insensível a erros do ambiente: qualquer sequência que a `Mission` gere será considerada consistente. O texto reconhece parte disso (l. 561), mas os resultados são apresentados como validação.
3. **Teste de invalidez com um único caso.** Só `InFlight → Shutdown` é exercitado em compilação (l. 414 a 464). O domínio finito permite um teste negativo completo: das 16 combinações de vértices, 8 são proibidas (todas exceto as quatro arestas e as quatro identidades). Mostrar que as oito falham e as oito restantes compilam fecharia a lacuna.
4. **Provas incompletas.** As leis de `Functor` e `Applicative` e a consistência `fmap f m = m >>= pure . f` não são tratadas, embora as instâncias existam. A parte "conferida por exemplo" (`lawChecks`) usa funções escolhidas pelo autor, por isso é um complemento, não substituto, da prova.
5. **Enumeração limitada apresentada como evidência de propriedades de sequência.** A limitação é declarada (l. 559), mas a síntese (l. 575 em diante) soma "32 verificações aprovadas" sem separar o que é prova do que é busca limitada. Sugere-se uma tabela com três colunas: provado, rejeitado pelo compilador, testado até N.
6. **N = 4 não alcança a cadeia induzida pela bateria** (6 ticks, l. 559). Ela é testada em um único cenário fixo. Como é o caminho central do estudo de caso, deveria ser coberta por enumeração (N = 6 sobre um alfabeto reduzido) ou por geração de casos.
7. **Os tempos** (7 a 8,5 s por verificação) são de uma máquina e uma execução; aparecem em tabela sem essa ressalva no corpo, apenas na legenda.

**Pontos cegos:** adequação ao domínio de aviônica; literatura de CREM.

---

## Relatório 3 — Revisor 2 (domínio: programação funcional e categorial)

**Pontos fortes**
- Correção: o papel de `Applicative` e `Monad` no CREM foi corrigido (l. 371 em diante), a aresta identidade está explicada (l. 400 a 410) e a distinção entre "representável" no CREM e functor representável de Milewski (l. 565) é feita com cuidado. Estas eram confusões comuns e foram resolvidas.

**Problemas**
1. **Instâncias `INCOHERENT` não discutidas.** A explicação de como o GHC "descarta as arestas uma a uma" (l. 462) é correta no resultado, mas a classe `AllowedTransition` usa instâncias sobrepostas e marcadas incoerentes (visto no código-fonte do pacote). O texto deveria dizer se a garantia depende dessa configuração e por que ela não abre brecha de aceitação indevida. Hoje a seção afirma segurança sem tratar o mecanismo de resolução.
2. **Uso decorativo de teoria das categorias.** "Coproduto" e "objeto terminal" (§5.1) e "monoide na categoria dos endofuntores" (§5.7) são apresentados, mas nenhum resultado do trabalho depende deles. A conexão com o código se resume a "é análogo". Ou se mostra o que a formulação categorial permite que a formulação em Haskell não permite, ou se reduz a seção.
3. **Analogia frágil** em "do mesmo modo que as classes de tipos de Hutton restringem tipos, a topologia restringe transições" (l. 408): classes restringem tipos, a topologia restringe valores promovidos a tipos por `singletons`. Convém dizer o que há de comum e o que não há.
4. **Literatura mínima.** 9 fontes técnicas e nenhuma sobre alternativas diretas ao problema: tipos de estado de protocolo, tipos dependentes, outras bibliotecas de máquinas de estados. O Estado da Arte (l. 237 a 284) reconhece as lacunas, o que é correto, mas a seção ainda não cumpre o pedido do Parecer 2. **[sem fonte na base]**
5. **Fonte em russo (Malakhovski e Shalyto) citada com página** (p. 21) sem indicar quem traduziu. A fidelidade das paráfrases é indicada pelo próprio texto como não conferida.
6. **O texto de §5.6** apresenta `mapM` como "o mecanismo exato" de generalização; `mapM` é apenas uma das formas, e o projeto usa `runEvents`, que o próprio texto define em seguida. Convém uniformizar.

**Pontos cegos:** relevância de domínio e requisitos de segurança reais.

---

## Relatório 4 — Revisor 3 (engenharia de sistemas críticos)

**Pontos fortes**
- O simulador deixa explícito o que não é: discreto, sem física, sem tempo contínuo (l. 561). Não há alegação de certificação ou de segurança de voo.

**Problemas**
1. **A aviônica é um domínio de exemplo sem requisitos.** As regras (4 estados, 4 eventos, desligamento só em solo) vêm de um enunciado do próprio projeto. O título e a introdução falam em "sistemas reativos" e "segurança"; o leitor pode concluir que os resultados se aplicam a sistemas reais. Falta uma frase de escopo logo no início. **[sem fonte na base]** para requisitos de domínio.
2. **O registrador de um slot descarta sinais** (l. 563). Num sistema crítico, perder um `CriticalBattery` porque o slot está ocupado é um modo de falha, não um detalhe. O texto trata como limitação de modelagem; deveria avaliar a consequência (por exemplo, enumerar cenários em que o descarte altera o estado final em relação à FSM ingênua, que o texto afirma não ocorrer em N = 4).
3. **O "atraso de um tick" é arbitrário** e não corresponde a tempo real, o que é dito, mas o relato apresenta o resultado "o MsgEmergency ocorre no tick seguinte" como verificação de comportamento. É uma verificação do modelo, não do sistema.
4. **O `ShedLoad` e a ordem de liberação** (`ShedLoad` antes de `LandedSignal`) são escolhas do autor sem justificativa de domínio (l. 489).
5. **Ausência de comparação com a abordagem imperativa**, que é a premissa do trabalho. Um experimento mínimo bastaria: implementar a mesma máquina com `enum` e `switch` (como em Malakhovski e Shalyto) e mostrar o que o compilador detecta nela e o que escapa (a pergunta de pesquisa trata disso e a Fase 4 a adia).
6. **Rastro de reprodutibilidade** apenas por versão local de repositório; não há URL, arquivamento ou DOI.

**Pontos cegos:** detalhes das provas e dos tipos.

---

## Relatório 5 — Advogado do Diabo

**Contra-argumento mais forte.** Se o conjunto de estados e o de eventos são finitos, a correção de uma função de transição pode ser verificada por teste exaustivo dos 16 pares, e o próprio relatório faz isso (l. 531). Nesse caso, o CREM não oferece uma garantia a mais; oferece a mesma garantia mais cedo (em compilação). A hipótese central ("Segurança de Tipos superior", l. 154) confunde antecipação com superioridade. Além disso, a regra que o estudo de caso quer proteger ("não desligar em voo") pode ser violada por uma sequência de três eventos que o sistema de tipos aceita, e o próprio texto admite (l. 464). O que se demonstra é que a aresta direta é rejeitada, não que o UAV não se desliga em voo.

**Problemas**

| # | Severidade | Dimensão | Local | Problema |
|---|---|---|---|---|
| 1 | CRÍTICO | Validade do argumento | l. 154, 575 em diante | "Superior" e "composicional" não são testados contra uma alternativa; em domínio finito, o teste exaustivo dá a mesma garantia que o tipo. A vantagem real (detecção antecipada, localização do erro) não é medida |
| 2 | CRÍTICO | Validação circular | l. 466 a 551 | Tabela, FSM ingênua, ações do CREM e ambiente foram escritos pelo mesmo autor; todos os testes comparam esses artefatos entre si. Não há oráculo externo |
| 3 | MAIOR | Escopo da garantia | l. 456 a 464 | A regra do domínio é violável por sequência; o texto de §5.12 diz isso, a síntese (l. 575 em diante) ainda declara segurança "confirmada" |
| 4 | MAIOR | Pergunta de pesquisa | l. 140 a 146 | A pergunta fala em "garantias verificáveis de correção"; o trabalho não define "correção" além de "coincide com a tabela" |
| 5 | MAIOR | Cherry-picking | l. 456 a 464 | Apenas o caso mais favorável de rejeição é mostrado (o que o autor escolheu como proibido) |
| 6 | MENOR | Generalização | §5.1 | Dois tipos de duas constantes isomorfos a `Bool` não sustentam afirmação alguma sobre "finitude preservada com fidelidade" além da trivialidade |

**Alternativas ignoradas:** teste exaustivo como método de verificação para domínio finito; enumerações como `enum class` com aviso de exaustividade em linguagens imperativas (**[sem fonte na base]**, deve ser incluída na comparação da Fase 4); verificação de modelos para alcançabilidade (citada por Perone e Karachalias como trabalho futuro).

**Perspectivas ausentes:** o engenheiro que manteria a máquina quando as regras mudarem. O custo de manutenção do código tipado (módulos TH, instâncias incoerentes, mensagens de erro como `Topology '[]`) não é discutido.

**Teste "e daí?":** responde-se parcialmente. A resposta mais forte do texto é "o erro aparece em compilação, localizado na equação que o provoca"; está dispersa e não é apresentada como resultado.

---

# Carta de Decisão Editorial (sintetizador)

**Decisão: Revisão Maior.** Não se trata de rejeição: o relatório é honesto, tecnicamente cuidadoso e reproduzível. Mas as afirmações centrais ainda não estão sustentadas na forma como são enunciadas.

**Consenso (4 ou 5 assentos):**
- A validação não tem oráculo independente (R1-1, R1-2, AD-2, R3-2).
- A garantia dos tipos é por aresta, e a síntese a apresenta de forma mais forte do que o corpo (R1-5, AD-3, EIC-5).
- Falta o experimento de comparação que a premissa exige (R3-5, AD-1, EIC-3).
- O texto das seções 1 a 3 não acompanhou os resultados da §5 (EIC-4, EIC-5, AD-4).

**Divergências arbitradas:**
- *Teoria das categorias.* R2 pede que seja justificada ou reduzida; EIC e R1 não a criticam. Arbitragem: manter, mas cada resultado categorial deve apontar uma consequência no código ou ser marcado como contextual.
- *Peso do registrador de um slot.* R3 o vê como falha de segurança; R1 como limitação de modelagem. Arbitragem: tratar como limitação, mas exigir a enumeração do descarte (item de roteiro 8).

**Advogado do Diabo — itens CRÍTICOS, adjudicados:**
- **AD-1 (superioridade vs. antecipação):** *validado em parte.* O texto já reconhece que a comparação cabe à Fase 4, mas a hipótese e o título ainda afirmam superioridade. Bloqueia "Aceitar". Resposta exigida: reformular a hipótese como antecipação e localização de erros e definir como será medida.
- **AD-2 (validação circular):** *validado.* Bloqueia "Aceitar". Resposta exigida: confrontar a tabela com uma especificação independente e acrescentar o teste negativo completo (roteiro 3).
Nenhum CRÍTICO foi descartado.

**Pontos fortes a preservar:** seção de limitações; saídas reais de compilador; provas com hipóteses explícitas; separação entre provado, rejeitado em compilação e testado.

---

# Roteiro de Revisão

Itens em ordem da fonte (não é ordem de trabalho). Cada um tem a correção mínima; opções mais fortes estão como "ou".

| # | Origem | Item | Correção mínima | Opção mais forte |
|---|---|---|---|---|
| 1 | EIC-1 | Falta resumo e palavras-chave | Escrever resumo (150 a 250 palavras) e 3 a 5 palavras-chave | — |
| 2 | EIC-2, AD-1 | Título e hipótese prometem "via Monads" e "superior" | Reformular: completude vem do casamento de padrões; CREM dá rejeição antecipada por aresta | Definir critério mensurável de "antecipação" (por exemplo, onde e quando o erro é detectado) |
| 3 | R1-1, R1-3, AD-2, AD-5 | Validação circular e teste de invalidez com um caso | Teste negativo completo: 8 pares proibidos falham, 8 permitidos compilam; escrever as regras do domínio como especificação separada e testar a tabela contra ela | Gerar os casos de compilação automaticamente |
| 4 | EIC-3 | Contribuição em relação ao CREM não delimitada | Parágrafo "contribuições" na introdução, separando o que é do CREM do que é do projeto | — |
| 5 | EIC-4, EIC-5, AD-4 | Seções 1 e 3 desatualizadas | Revisar tempos verbais, remover "validado pelo compilador antes da execução" (l. 136, 150), acrescentar quadro "objetivo, situação, evidência" | — |
| 6 | R1-4 | Leis de `Functor` e `Applicative` sem prova | Demonstrar ou declarar explicitamente que ficam fora do escopo | Provar também `fmap = liftM` |
| 7 | R1-5, AD-3 | Síntese mistura prova, compilação e enumeração | Tabela de três colunas: provado, rejeitado em compilação, testado até N | — |
| 8 | R1-6, R3-2 | Cadeia da bateria só em cenário fixo; descarte de sinais no slot | Enumerar a cadeia (N = 6 sobre alfabeto reduzido) e os cenários em que o descarte altera o estado final | Fila ou prioridade como alternativa avaliada |
| 9 | R2-1 | Instâncias `INCOHERENT` | Subseção breve sobre como o GHC resolve `AllowedTransition` e por que a rejeição não depende de acaso | — |
| 10 | R2-2, R2-3 | Teoria das categorias decorativa; analogia com classes de tipos | Ligar cada resultado categorial a uma consequência no código ou rotulá-lo contextual; reformular a analogia | — |
| 11 | R2-4, R2-5 | Literatura mínima; fonte em russo | Ampliar o Estado da Arte conforme o Parecer 2; registrar quem conferiu a tradução | **[sem fonte na base]** |
| 12 | R3-1 | Escopo do domínio | Frase de escopo: aviônica é exemplo, sem requisitos reais | — |
| 13 | R3-3, R3-4 | Atraso de um tick e `ShedLoad` arbitrários | Rotular como escolhas de modelagem na própria §5.11 | Justificar por uma regra de domínio declarada |
| 14 | R3-5, AD (alternativas) | Falta comparação com a abordagem imperativa | Implementar a mesma máquina com `enum` e `switch` e registrar o que o compilador detecta | Medir esforço de manutenção |
| 15 | R3-6 | Reprodutibilidade | URL do repositório, etiqueta de versão e arquivamento | — |
| 16 | EIC-6, EIC-7 | Cronograma sem situação; grafias mistas | Coluna de situação; uniformizar para português brasileiro e um termo para "mônada" | — |

**Fora do escopo desta revisão:** reescrever o manuscrito (leitura somente); a verificação mecânica do contrato de sprint; o julgamento sobre um periódico específico.

---

## Próximo passo (Fase 2.5, orientação de revisão)

Cabe a você decidir o que fazer com cada item do roteiro: *vou tratar*, *não vou tratar* ou *não procede*. Os itens que mais mudam o argumento são o 2, o 3 e o 14. Quer que eu comece pelo teste negativo completo (item 3), que é mecânico e sai do próprio `avionics-crem`, ou prefere responder primeiro à triagem?
