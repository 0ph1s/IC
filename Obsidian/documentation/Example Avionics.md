# Prompt:

Você é um especialista em Programação Funcional Avançada, Teoria das Categorias e no Sistema de Tipos de Haskell.

Sua tarefa é gerar um arquivo de código formal em Haskell (`AvionicsFSM.hs`) que modele a Máquina de Estados Finitos (FSM) de um **Sistema de Aviônica e Controle de Voo Autônomo de Drone/UAV**. A implementação deve demonstrar formalmente os conceitos de Segurança de Tipos (Type Safety), Completude Funcional e Composabilidade Arquitetural conforme o framework CREM (Marco Perone).

### 1. REQUISITOS DO DOMÍNIO DE AVIÔNICA
Modelar a FSM com os seguintes conjuntos formais:
- **Estados ($Q$):** `Grounded` (Em Solo), `InFlight` (Em Voo), `EmergencyLanding` (Pouso de Emergência), `Shutdown` (Desligado).
- **Eventos ($\Sigma$):** `TakeoffSignal` (Sinal de Decolagem), `CriticalBattery` (Falha na Bateria), `LandedSignal` (Confirmação de Pouso em Solo), `SystemCutoff` (Desligamento de Segurança).
- **Regras do Domínio (Topologia):**
  - De `Grounded`, permite-se ir apenas para `InFlight` (via `TakeoffSignal`).
  - De `InFlight`, permite-se ir apenas para `EmergencyLanding` (via `CriticalBattery`).
  - De `EmergencyLanding`, permite-se ir apenas para `Grounded` (via `LandedSignal`).
  - De `Grounded`, permite-se ir para `Shutdown` (via `SystemCutoff`).
  - **Transição Proibida Crítica:** É EXPLICITAMENTE PROIBIDO ir do estado `InFlight` diretamente para o estado `Shutdown`.

### 2. REQUISITOS TÉCNICOS EM HASKELL
A implementação deve conter quatro seções organizadas:

#### SEÇÃO 1: FSM Ingênua e Pattern Matching Exaustivo (Fundamentação Teórica)
- Defina os Tipos Algébricos de Dados (ADTs) `State` e `Event` com `deriving (Show, Eq)`.
- Implemente a função de transição pura `transition :: State -> Event -> State`.
- Garanta Pattern Matching Exaustivo cobrindo todos os pares (Estado x Evento).

#### SEÇÃO 2: Encapsulamento com State Monad e Categoria Kleisli
- Modele a transição no contexto da `State Monad` (`StateMonad State Output`).
- Demonstre a composição de transições usando o operador de composição da Categoria Kleisli `(>=>)`.

#### SEÇÃO 3: Aplicação do Framework CREM (Type-Level Safety)
- Habilite as extensões de linguagem necessárias (`DataKinds`, `GADTs`, `TypeFamilies`, `TemplateHaskell`, `KindSignatures`, etc.).
- Use o Template Haskell do Singletons `$(singletons [d| data AvionicsVertex = Grounded | InFlight | EmergencyLanding | Shutdown ... |])` para promover os vértices ao nível de tipos.
- Defina o valor da topologia `avionicsTopology :: Topology AvionicsVertex` explicitando a lista de arestas permitidas.
- Implemente a ação da FSM `avionicsAction` utilizando o construtor `ActionResult` que requer a restrição de classe de tipos `AllowedTransition avionicsTopology initialVertex finalVertex`.

#### SEÇÃO 4: Teste de Invalidez de Tipagem e Composabilidade
- Inclua uma função/bloco comentado `invalidTransitionTest` que tente forçar uma transição direta de `SInFlight` para `SShutdown`.
- Explique nos comentários o erro de compilação esperado e por que isso comprova a eliminação de erros em runtime.
- Mostre como instanciar a máquina usando os construtores de composição do CREM (`Basic`, `Sequential` ou `Parallel`).

### 3. EXIGÊNCIAS DE FORMATO
- Todo o código deve ser valido sintaticamente e devidamente comentado, relacionando os recursos de linguagem (ADTs, Pattern Matching, State Monad, Singletons, Kleisli) com suas implicações de segurança e completude.
- Insira comentários explicativos sobre os conceitos categoriais aplicados no código.

# Roadmap:

![[Pasted image 20260923003050.png]]

### Fase 1: Fundamentação Matemática via ADTs e Pattern Matching Exaustivo

- **Objetivo:** Mapear os conjuntos finitos $Q$ (Estados) e $\Sigma$ (Eventos) em Tipos Soma (ADTs).
    
- **Construção:**
    
    1. Definir o ADT para Estados de Aviônica: `data State = Grounded | InFlight | EmergencyLanding | Shutdown`.
        
    2. Definir o ADT para Eventos de Sensores: `data Event = TakeoffSignal | CriticalBattery | LandedSignal | SystemCutoff`.
        
    3. Implementar a função de transição pura $\delta : Q \times \Sigma \to Q$ usando Currying (`State -> Event -> State`) e **Pattern Matching Exaustivo**.
        
- **Garantia de Pesquisa:** Confirmar a **Completude Funcional**. A compilação pelo GHC valida que todo par $(\text{Estado}, \text{Evento})$ possui um resultado definido, impedindo execeções/tratamentos omitidos em _runtime_.
    
### Fase 2: Gestão Pura de Estado via `State Monad` e Categoria Kleisli

- **Objetivo:** Encapsular a evolução temporal da FSM em computações puras.
    
- **Construção:**
    
    1. Refatorar a transição de estado na assinatura `Event -> StateMonad State Output` (transformação $s \to (a, s)$).
        
    2. Implementar a composição de transições monádicas usando a **Categoria Kleisli** e o operador `(>=>)`.
        
- **Garantia de Pesquisa:** Garantir o sequenciamento sem mutabilidade nem efeitos colaterais imperativos.
    
### Fase 3: Restrição de Topologia no Nível de Tipos via Framework CREM

- **Objetivo:** Elevar as regras de negócio de aviônica de validações sintáticas/dinâmicas para restrições formais do sistema de tipos.
    
- **Construção:**
    
    1. Codificar a `AvionicsTopology` identificando quais vértices de estados se conectam.
        
    2. Promover a topologia ao nível de tipos via Template Haskell e Singletons (`$(singletons [d| data AvionicsVertex = ... |])`).
        
    3. Definir a ação da FSM utilizando a restrição implícita `AllowedTransition topology initialVertex finalVertex` com `pureResult`.
        
- **Garantia de Pesquisa:** Garantir que transições proibidas (ex: passar de `InFlight` direto para `Shutdown`) sejam **rejeitadas estaticamente pelo compilador GHC**.
    
### Fase 4: Composabilidade Modular e Prova de Segurança (_Invalidez de Tipagem_)

- **Objetivo:** Demonstrar a composição de FSMs independentes e realizar os testes formais de invariante.
    
- **Construção:**
    
    1. Criar uma FSM secundária para o subsistema de energia/bateria (`PowerFSM`).
        
    2. Compor a `AvionicsFSM` com a `PowerFSM` utilizando os construtores algébricos do CREM (`Sequential`, `Parallel`, `Feedback`).
        
    3. **Teste de Invalidez de Tipagem:** Injetar intencionalmente um código de transição proibida e capturar o erro do compilador.
        
    4. Extrair e renderizar o diagrama topológico das máquinas de estado usando o módulo de renderização do CREM.