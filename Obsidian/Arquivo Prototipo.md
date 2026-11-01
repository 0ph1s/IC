## 1 INTRODUÇÃO

As Máquinas de Estados Finitos (FSMs) são um dos pilares da Teoria da Computação e fornecem um formalismo matemático rigoroso para a modelagem de sistemas cujo comportamento é determinado por um conjunto discreto de estados e regras de transição. Sua aplicação abrange diversas áreas, desde o _design_ de _hardware_ e o controle de protocolos de rede até a construção de _parsers_ e a modelagem de domínio em arquiteturas de software complexas (Perone, **"Crème de la Crem: Composable Representable Executable Machines"**). No entanto, a tradução desses modelos abstratos para linguagens de programação de propósito geral, em particular as do paradigma imperativo, introduz dificuldades inerentes.

A implementação tradicional de FSMs em linguagens como C++ frequentemente recorre à representação do estado via variáveis mutáveis (campos de classe) ou identificadores de baixo nível (_strings_ ou inteiros). Essa prática viola a pureza do modelo matemático e, mais criticamente, **"não consegue aplicar diretamente os métodos utilizados na implementação de máquinas de estados finitos em linguagens de programação imperativas"** em um ambiente funcional (Malakhovski & Shalyto, p. 1). Essa dependência da mutabilidade e de tipos fracos para o estado torna a verificação da corretude da máquina uma tarefa que recai pesadamente sobre testes em tempo de execução, expondo o sistema a erros lógicos e transições inválidas não detectadas previamente.

O presente projeto de pesquisa propõe abordar esse problema através da **formalização e implementação de Máquinas de Estados Finitos (FSMs) na linguagem de programação funcional pura Haskell**. Haskell é reconhecida por seu rigor matemático, enraizado na Teoria das Categorias, o que a torna um veículo ideal para espelhar estruturas formais. O sistema de tipos avançado da linguagem permite que a definição da FSM — sua tupla matemática de estados, alfabeto, estado inicial e função de transição — seja traduzida diretamente em tipos de dados, como os **Tipos de Dados Algébricos (ADTs)**, que são o **"conceito mais importante"** em Haskell (Hutton, **"Programming in Haskell"**, Cap. 5). Conforme demonstrado por Malakhovski e Shalyto, o uso de ADTs para representar eventos, estados e ações permite a **"verificação da correção do código das funções de transição no estágio de compilação pelo próprio compilador"** (Malakhovski & Shalyto, p. 20).

Além da segurança de tipos básica, a abordagem em Haskell permite a exploração de conceitos avançados para o tratamento do estado. Embora Haskell promova a pureza, é possível gerenciar a **"mudança de estado de forma pura"** através de abstrações de ordem superior. Estruturas como **Monads** fornecem uma ferramenta fundamental para sequenciar computações com efeitos colaterais (incluindo estado, como no _State Monad_) de maneira controlada, mantendo o código no domínio funcional (Jahn, **"Monads and their Applications in Haskell"**; Maia, **"Applied Category Theory: Monads and Haskell"**). Essa funcionalidade não apenas lida com o estado, mas também abre caminho para a **composição** de FSMs.

O estudo se aprofunda na capacidade de **composabilidade** de máquinas de estados. Frameworks recentes, como o Crem, ilustram como as _type-level features_ de Haskell podem ser usadas para **"especificar transições de estado permitidas e proibidas"** (Perone, p. 1), permitindo a construção de arquiteturas de software como a **"composição de máquinas de estados"** independentes, mantendo a coerência e a modularidade do domínio (Perone). O resultado é um sistema robusto, onde a lógica de domínio (as regras da FSM) é validada pelo compilador antes da execução.


### 1.1 JUSTIFICATIVA DO TEMA

A relevância deste projeto reside na busca por métodos de **engenharia de _software_** que aumentem a confiabilidade do código. Ao traduzir o rigor da teoria de autômatos para o sistema de tipos de Haskell, o projeto transforma a verificação da corretude de uma tarefa de teste em tempo de execução em uma **garantia de compilação**. Isso está alinhado com a justificação de Malakhovski e Shalyto sobre a importância da **"verificação da correção do código das funções de transição no estágio de compilação"** (Malakhovski & Shalyto, p. 20).

O foco na utilização de **Monads** para gerenciar o estado e na **composabilidade** estende o valor da pesquisa para o **Domain-Driven Design (DDD)**. A capacidade de compor máquinas, conforme exemplificado no trabalho de Perone, permite que sistemas de domínio complexos sejam construídos como a interconexão de subsistemas menores e verificados individualmente, o que contribui diretamente para a modularidade e a manutenibilidade de grandes projetos de software.

### 1.2 PROBLEMA DE PESQUISA

Considerando o descompasso entre a formalidade matemática das FSMs e a insegurança de tipos das implementações tradicionais, o problema de pesquisa é formulado como:

> De que forma a linguagem de programação funcional pura Haskell, explorando seu sistema de tipos avançado (ADTs) e suas abstrações de ordem superior (Monads e Composição), pode ser utilizada para obter uma formalização de Máquinas de Estados Finitos que ofereça garantias verificáveis de correção (_type safety_) e completude (_completeness_) na especificação das funções de transição, e que suporte a composição de FSMs complexas de maneira modular e representável?

### 1.2.1 Hipóteses

O presente trabalho de Iniciação Científica baseia-se em três hipóteses fundamentais que buscam responder à questão de pesquisa, as quais serão testadas e validadas por meio da formalização e implementação das Máquinas de Estados Finitos (FSMs) em Haskell. A primeira delas é a **Hipótese de Segurança de Tipos**, que postula que a utilização dos **Tipos de Dados Algébricos (ADTs)** de Haskell para a modelagem dos estados e eventos é suficiente para impor uma forte **garantia de _type safety_**. Acreditamos que, ao usar ADTs, a função de transição implementada via _pattern matching_ conseguirá **impedir a ocorrência de estados e transições logicamente impossíveis** (ou não definidas pela FSM) de forma mais eficaz do que o uso de tipos de baixo nível, como _strings_ ou inteiros, em linguagens imperativas. Em decorrência dessa segurança, surge a **Hipótese de Completude Funcional**: o sistema de tipos de Haskell e o uso do _pattern matching_ exaustivo no paradigma funcional garantem automaticamente a **completude (_completeness_)** da função de transição, alertando o desenvolvedor sobre quaisquer combinações válidas de (Estado $\times$ Evento) que tenham sido inadvertidamente omitidas. Essa característica confere à implementação em Haskell uma superioridade na verificação da lógica da FSM, transferindo a checagem da correção da fase de testes para a fase de compilação (Malakhovski & Shalyto). Por fim, a **Hipótese de Composabilidade e Modulação** sustenta que a aplicação de abstrações funcionais, notavelmente as **Monads** (como o _State Monad_ ou a Categoria Kleisli) e os recursos de _type-level_ de Haskell, é capaz de viabilizar a criação de **Máquinas de Estados Finitos Componíveis** de forma puramente funcional. Essa composabilidade resulta em uma arquitetura de _software_ significativamente mais modular e representável, facilitando a construção de sistemas complexos a partir da interconexão segura de subsistemas menores e verificados individualmente (Perone).

### 1.3 OBJETIVOS

#### 1.3.1 Objetivo Geral

Formalizar e implementar Máquinas de Estados Finitos Determinísticas (DFSMs) em Haskell, utilizando os recursos de tipagem avançada da linguagem e as estruturas funcionais para garantir a segurança de tipos e a completude na definição das funções de transição, e demonstrar sua aplicação em um contexto de composição de sistemas.

(Teste) O objetivo geral desta pesquisa busca formalizar e implementar Máquinas de Estados Finitos Determinísticas (DFSMs) em Haskell, explorando o sistema de tipagem avançado e as estruturas funcionais da linguagem para garantir a segurança e a completude na definição das funções de transição, com ênfase na demonstração de um modelo que suporte a composição de sistemas.

#### 1.3.2 Objetivos Específicos

Para alcançar o objetivo geral, o projeto se desdobra em quatro objetivos específicos. Inicialmente, será fundamental **definir modelos de dados em Haskell** que traduzam com precisão os elementos formais de uma FSM. Isso será realizado através do uso de **Tipos de Dados Algébricos (ADTs)** para a representação rigorosa de Estados, Eventos e Funções de Transição, conforme a metodologia funcional pura. Em seguida, será necessário **implementar o mecanismo de processamento de sequências de entrada**, explorando funções de alta ordem e o _pattern matching_ de Haskell. Essa etapa é crucial para demonstrar como o compilador verifica a **completude** da máquina, garantindo que todas as combinações (Estado, Evento) sejam tratadas, um diferencial em relação às implementações imperativas (Malakhovski & Shalyto). O terceiro objetivo visa **explorar e aplicar o _State Monad_** ou outras estruturas categoriais (como a Categoria Kleisli) para encapsular a mudança de estado de forma funcionalmente pura. O uso de **Monads**, que permite sequenciar computações com estado de maneira controlada (Jahn; Maia), facilitará o quarto e último objetivo, que é **demonstrar a composabilidade de transições**. Este ponto final ilustrará como a tipagem avançada de Haskell pode garantir transições válidas e o encapsulamento do domínio, permitindo que a arquitetura de _software_ seja construída como uma **composição de máquinas de estados** modulares (Perone).

1. Definir modelos de dados em Haskell utilizando **Tipos de Dados Algébricos (ADTs)** para a representação precisa de Estados, Eventos e Funções de Transição.
    
2. Implementar o mecanismo de processamento de sequências de entrada em Haskell, explorando as funções de alta ordem e o _pattern matching_ para validar a completude da máquina.
    
3. Explorar a aplicação do **State Monad** para gerenciar a mudança de estado de forma pura e demonstrar a composabilidade de transições através de estruturas monádicas ou da categoria **Kleisli**.
    
4. Demonstrar, por meio de um estudo de caso prático (e.g., um _parser_ simples ou uma máquina de protocolo), como a tipagem de Haskell pode ser utilizada para garantir transições válidas e impedir estados impossíveis.

Excelente. O **Referencial Teórico** é a base conceitual que sustenta o seu projeto. Ele deve cobrir os três pilares do seu trabalho: a teoria dos autômatos, o paradigma da programação funcional pura (Haskell), e as abstrações de alto nível para gerenciar estado e composição (Monads e Teoria das Categorias).

Abaixo está a proposta para o seu **2. Referencial Teórico Inicial**, utilizando o conteúdo dos PDFs fornecidos e integrando as citações necessárias.

## 2. REFERENCIAL TEÓRICO INICIAL (Detalhado)

A presente pesquisa baseia-se numa convergência teórica entre o rigor formal da Teoria de Autômatos, a disciplina da Programação Funcional Pura (PFP) e a abstração de alto nível da Teoria das Categorias. Este entrelaçamento visa construir um modelo de Máquinas de Estados Finitos (FSMs) em Haskell que não apenas funcione, mas que traga consigo garantias formais de corretude validadas em tempo de compilação.
### 2.1 A Máquina de Estados Finitos no Contexto Matemático e Programático

As FSMs são uma pedra angular da Ciência da Computação, fornecendo uma estrutura matemática precisa para modelar sistemas sequenciais e reativos. Formalmente, uma FSM Determinística é definida pela quíntupla $(Q, \Sigma, \delta, q_0, F)$, onde $Q$ é o conjunto finito de estados, $\Sigma$ é o alfabeto de entrada (eventos), e $\delta$ é a função de transição, o coração da máquina.

A tradução deste modelo para linguagens imperativas tradicionalmente viola a pureza do conceito. Em linguagens como C++, a função de transição é frequentemente implementada de forma a manipular um estado representado por variáveis mutáveis, como **"campo de classe (se a programação orientada a objetos for usada) ou uma variável global"** (Malakhovski & Shalyto, p. 1). Esta dependência do estado mutável é incompatível com a filosofia da Programação Funcional Pura, que se define pela **"ausência de variáveis"** no sentido imperativo. Por consequência, Malakhovski e Shalyto (p. 1) concluem que **"não se consegue aplicar diretamente os métodos utilizados na implementação de máquinas de estados finitos em linguagens de programação imperativas"** em ambientes puramente funcionais.

O paradigma de PFP, exemplificado por Haskell, exige que a transição de estado seja modelada como uma **função pura** ($\delta: \text{Estado}_{\text{antigo}} \to \text{Estado}_{\text{novo}}$) em resposta a um evento. Isto não só mantém o código **"claro, conciso e correto"** (Hutton, p. 2), mas força a implementação a permanecer fiel à imutabilidade e ao rigor do modelo matemático da FSM.

### 2.2 Haskell, Tipos de Dados Algébricos e a Segurança de Tipos

Haskell se distingue pela sua capacidade de converter o rigor matemático do modelo FSM em garantias de segurança de _software_.

O principal mecanismo para essa conversão é o uso de **Tipos de Dados Algébricos (ADTs)**. ADTs são cruciais para a modelagem de domínio, permitindo que os conjuntos finitos de Estados ($Q$) e Eventos ($\Sigma$) sejam declarados como **Tipos Soma** distintos. Esta prática encapsula o domínio da FSM no sistema de tipos.

A implementação da função de transição é realizada via **_pattern matching_**, uma técnica que **"examina a estrutura de um dado de entrada"** e define o comportamento com base nessa estrutura (Hutton, p. 49). A robustez do sistema de tipos de Haskell reside na sua capacidade de verificar a **exaustividade** do _pattern matching_. O compilador exige que a função de transição $\delta$ trate explicitamente **todos os pares possíveis** de $(\text{Estado} \times \text{Evento})$ definidos pelos ADTs. Essa verificação em tempo de compilação é o cerne da vantagem funcional, pois garante a **completude (_completeness_)** da lógica da FSM e permite a **"verificação da correção do código das funções de transição no estágio de compilação"** (Malakhovski & Shalyto, p. 20), prevenindo erros que apenas surgiriam em tempo de execução num modelo imperativo.

### 2.3 Teoria das Categorias, Monads e a Gestão Pura do Estado

Embora Haskell promova a pureza, a gestão da sequência de transições e dos efeitos inerentes ao estado exige abstrações de ordem superior. O alicerce dessas abstrações é a **Teoria das Categorias**.

- **Composição e Teoria das Categorias:** Milewski (p. 8) argumenta que **"Composition is the Essence of Programming"**. A Teoria das Categorias fornece o vocabulário e o formalismo para a composição de estruturas complexas, o que é fundamental para encadear múltiplas transições de FSMs.
    
- **Monads e Efeitos Controlados:** Monads são a ferramenta canónica em PFP para introduzir **"as indulgências de impureza com as bênçãos de pureza"** (Wadler, p. 1), permitindo **"concisely express in a pure functional language some programs that manipulate state"**. Sua origem matemática remonta à década de 1960, quando foram inventadas por teóricos de categorias para **"expressar concisamente certos aspectos da álgebra universal"**. Sua definição formal mais abstrata as coloca como um **"Monóide na Categoria dos Endofuntores"** (Jahn, p. 3). Para a FSM, a **`State Monad`** é o tipo específico que permite que a mudança de estado seja tratada por meio de uma função que recebe o estado, aplica a transformação e retorna o novo estado junto com um resultado (Milewski, p. 386), mantendo a **"mudança de estado de forma pura"**.
    
- **Categoria Kleisli:** O poder da Monad para a sequenciação e composição de FSMs é formalizado através da **Categoria Kleisli**. Esta construção categorial lida com **"morfismos $A \to M B$"** (Maia, p. 15), que são precisamente as funções monádicas que produzem um efeito (como a mudança de estado). A Kleisli fornece o formalismo para que múltiplas transições de estado monádicas sejam encadeadas de forma segura e coerente, sendo um pré-requisito para sistemas compostos.
    

### 2.4 A Composabilidade de FSMs: O Paradigma CREM

A aplicação prática destas abstrações culmina na capacidade de desenvolver arquiteturas de _software_ complexas, modulares e verificáveis, como demonstrado pelo _framework_ **Crème de la Crem (CREM)**.

- **Arquitetura Componível:** O CREM é um exemplo prático de como **"construir arquiteturas de software como uma composição de máquinas de estados"** independentes, aplicando princípios de _Domain-Driven Design_ (Perone, p. 1). Esta modularidade permite que subsistemas sejam desenvolvidos e verificados isoladamente antes de serem combinados em sistemas maiores.
    
- **_Type-Level Features_ e Representabilidade:** O diferencial do CREM é o uso dos **"recursos avançados de _type-level_ de Haskell"** para codificar as regras de transição. O _framework_ permite que o usuário **"especifique transições de estado permitidas e proibidas"** diretamente nos tipos de dados (Perone, p. 1). Isso significa que as restrições de domínio não são apenas verificações lógicas, mas propriedades do sistema de tipos. Qualquer violação da lógica de negócio (como tentar uma transição inválida) resulta em um erro de compilação, tornando a representação do sistema intrinsecamente segura e verificável. Essa abordagem garante que a **"implementação de um sistema se mantenha sincronizada com a sua representação gráfica"** (Perone, p. 1), estabelecendo um alto grau de representabilidade e integridade arquitetural.

