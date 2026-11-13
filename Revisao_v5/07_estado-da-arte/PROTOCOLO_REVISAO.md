# Protocolo de ampliação do estado da arte

Atende à melhoria 1 do documento de adequação de 07/11/2026: "incluir sistemas de tipos, máquinas de
estados tipadas, typestate, técnicas de verificação e comparação com outras bibliotecas. O relatório
reconhece que a revisão ainda não é sistemática."

**Status: protocolo escrito; a busca NÃO foi executada.** Nada aqui é resultado de revisão. Os itens da
seção 3 são *candidatos a leitura*, citados de memória e de menções nos dois documentos, e precisam ter
os dados bibliográficos conferidos nas fontes antes de entrarem na lista de referências.

## 1. Perguntas que a revisão deve responder

1. Que garantias de tipos para máquinas de estados existem em linguagens funcionais e imperativas, e o que
   cada uma cobre (estados, arestas, eventos, sequências)?
2. Que bibliotecas de máquinas de estados tipadas em Haskell existem além do CREM, e o que garantem?
3. Que técnicas de verificação (model checking, testes baseados em propriedades/modelos) são usadas para
   propriedades **globais** de composições de máquinas?
4. O que já foi dito sobre a limitação evento–destino (o tipo da aresta não liga o evento ao destino)?
5. Há trabalho que compare, empiricamente, garantias de compilação com testes exaustivos para máquinas de estados?

## 2. Estratégia de busca (a executar)

* **Bases:** ACM Digital Library, IEEE Xplore, SpringerLink, Scopus, DBLP, arXiv, Hackage (pacotes), e os
  anais de ICFP, Haskell Symposium, TFP, SBLP, SBMF, FormaliSE, SEFM, ESOP, TACAS.
* **Cadeias (inglês), combinar com AND/OR e adaptar à sintaxe de cada base:**
  * `("finite state machine" OR "state machine" OR automaton) AND (Haskell OR "functional programming") AND ("type safe" OR "type-level" OR "dependent types" OR "singletons")`
  * `typestate AND ("state machine" OR protocol) AND (Haskell OR "type system")`
  * `("indexed monad" OR "type-indexed" OR "session types") AND "state machine"`
  * `("property-based testing" OR QuickCheck OR Hedgehog) AND ("state machine" OR "model-based")`
  * `("model checking" OR TLA+ OR Alloy) AND ("state machine" OR statechart) AND (composition OR "closed loop" OR feedback)`
  * `("compile-time" OR static) AND ("exhaustive testing" OR "unit testing") AND "state machine" AND empirical`
* **Janela:** sem limite inferior para trabalhos fundadores (typestate, TLA+); 2015 em diante para bibliotecas e
  técnicas recentes. **Idiomas:** inglês, português, e a fonte russa já usada (revisão por falante nativo pendente).
* **Snowballing:** referências e citações de Perone e Karachalias (2023) e dos três ou quatro trabalhos mais próximos.

## 3. Candidatos a leitura (não lidos; dados a conferir)

| Tema | Candidato | Por que | Situação |
|---|---|---|---|
| Typestate | Strom e Yemini, "Typestate: a programming language concept for enhancing software reliability", IEEE TSE, 1986 | origem do conceito | a conferir |
| Typestate OO | Aldrich et al., "Typestate-oriented programming", 2009 | typestate em linguagem com objetos | a conferir (venue exato) |
| Máquinas tipadas em Haskell | biblioteca `motor` (O. Wickström) | alternativa ao CREM citada pelos autores do CREM | não lida; verificar GHC |
| Testes baseados em propriedades | Claessen e Hughes, "QuickCheck", ICFP, 2000 | base de QuickCheck e do estilo Hedgehog | a conferir |
| Testes de máquinas de estados | `quickcheck-state-machine` (S. Andjelkovic) | modelo + comandos + shrinking | não testado aqui |
| Testes baseados em propriedades | `hedgehog` (J. Stanley e colaboradores) | adotado nesta revisão | usado (versão 1.7 resolveu com GHC 9.6.7) |
| Model checking | L. Lamport, "Specifying Systems", 2002; TLA+/TLC | especificação e propriedades temporais | a conferir |
| Domínio | PX4 Autopilot e sua documentação de segurança | segundo estudo de caso, requisitos reais | não usado (requisitos não reconciliados) |

## 4. Critérios de inclusão e exclusão

* **Inclui:** descreve ou avalia garantias estáticas para máquinas de estados ou protocolos; ou técnicas de
  verificação aplicadas a composições de máquinas; ou comparação empírica compile-time versus teste.
* **Exclui:** só descrição de padrão de projeto sem garantia verificável; só teoria de autômatos sem implementação;
  trabalho sem acesso ao texto completo (registrar como "não acessado").

## 5. Extração e síntese

Para cada trabalho incluído, registrar numa planilha: fonte; linguagem; o que é garantido por tipo; o que
depende de teste ou prova externa; se trata de composição; se trata de eventos (evento–destino); evidência
empírica (sim/não); limitações declaradas. A síntese deve preencher a tabela comparativa da seção 4 do
relatório com colunas novas (Motor, typestate, TLA+), e **só então** discutir ineditismo.

## 6. Ameaças à própria revisão

Busca por um único pesquisador; cadeias em inglês; literatura cinzenta (blogs, repositórios) sub-representada;
a fonte russa lida com apoio de IA, sem falante nativo. Registrar a data de cada busca e o número de resultados.

## 7. Como isto entra no artigo

Sem este levantamento, a alegação de ineditismo **não pode ser feita** (o relatório já diz isso na seção 4).
O artigo 1 depende de (1), (2) e (5); o artigo 2, de (3) e (4).
