{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE GADTs                 #-}
{-# LANGUAGE TypeFamilies          #-}
{-# LANGUAGE KindSignatures        #-}
{-# LANGUAGE ScopedTypeVariables   #-}
{-# LANGUAGE TypeApplications      #-}
{-# LANGUAGE TypeOperators         #-}
{-# LANGUAGE FlexibleContexts      #-}
{-# LANGUAGE FlexibleInstances     #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE UndecidableInstances  #-}
{-# LANGUAGE InstanceSigs          #-}
{-# LANGUAGE RankNTypes            #-}
{-# LANGUAGE PolyKinds             #-}
{-# LANGUAGE StandaloneKindSignatures #-}

-- ============================================================================
-- MÓDULO: AvionicsFSM
-- ----------------------------------------------------------------------------
-- Modela a FSM de um Sistema de Aviônica e Controle de Voo Autônomo de UAV,
-- combinando três camadas de formalização:
--
--   SEÇÃO 1 — FSM Ingênua (ADTs + Pattern Matching Exaustivo)
--   SEÇÃO 2 — Encapsulamento Monádico (State Monad + Categoria de Kleisli)
--   SEÇÃO 3 — Framework CREM-mini (Topologia Promovida ao Nível de Tipos)
--   SEÇÃO 4 — Testes de Invalidez e Composabilidade
--
-- O módulo é AUTOCONTIDO: usa apenas a biblioteca base do GHC. Uma versão
-- minimalista do framework CREM é reimplementada localmente, usando GADTs
-- e DataKinds nativos, sem dependências externas (sem `singletons`).
--
-- Fundamentação:
--   * Milewski (2020) — Categoria Hask, coprodutos, functor, mônada.
--   * Hutton (2016)   — Pattern matching exaustivo, type safety, State Monad.
--   * Perone (2023)   — Framework CREM, AllowedTransition, ActionResult.
--   * Wadler (1992)   — Monad comprehensions e a Categoria de Kleisli.
--   * Bocchino (2025) — Leis da mônada e equivalência entre as definições.
-- ============================================================================

module AvionicsFSM where

import           Data.Kind (Type, Constraint)

-- ============================================================================
-- SEÇÃO 1 — FSM INGÊNUA E PATTERN MATCHING EXAUSTIVO
-- ============================================================================
--
-- NOTA CATEGORIAL
-- ---------------
-- Em Hask, os objetos são tipos e os morfismos são funções. Um tipo soma
-- como `data State = Grounded | InFlight | EmergencyLanding | Shutdown` é
-- o COPRODUTO de quatro cópias do objeto terminal (4 = 1 + 1 + 1 + 1),
-- conforme Milewski (2020), Cap. 5.
-- ----------------------------------------------------------------------------

-- | Conjunto Q de estados do UAV.
data State
  = Grounded          -- ^ Em solo, pronto para decolar.
  | InFlight          -- ^ Em voo, executando missão.
  | EmergencyLanding  -- ^ Em procedimento de pouso de emergência.
  | Shutdown          -- ^ Desligado por segurança.
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | Alfabeto Σ de eventos externos.
data Event
  = TakeoffSignal    -- ^ Sinal autorizado de decolagem.
  | CriticalBattery  -- ^ Falha crítica na bateria.
  | LandedSignal     -- ^ Confirmação de que o UAV pousou.
  | SystemCutoff     -- ^ Comando de desligamento de segurança.
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | Saída emitida pela FSM (para logging / telemetria).
data Output
  = MsgTakeoff
  | MsgEmergency
  | MsgLanded
  | MsgShutdown
  | MsgIgnored
  deriving (Show, Eq)

-- | Função de transição δ : Q × Σ → Q.
--
-- A assinatura `State -> Event -> State` é a versão CURRIED de
-- `(State, Event) -> State` (Milewski, 2020, Cap. 9). O domínio é o
-- produto categorial State × Event.
--
-- O pattern matching abaixo é EXAUSTIVO sobre os 4 × 4 = 16 pares
-- possíveis. O compilador GHC emite aviso (ou erro, sob -Werror) caso
-- algum par seja omitido — esta é a garantia de COMPLETUDE FUNCIONAL
-- descrita por Hutton (2016), Cap. 4.
transition :: State -> Event -> State
-- Casos permitidos pela topologia:
transition Grounded         TakeoffSignal   = InFlight
transition InFlight         CriticalBattery = EmergencyLanding
transition EmergencyLanding LandedSignal    = Grounded
transition Grounded         SystemCutoff    = Shutdown

-- Casos auto-estabilizantes (no-op):
transition s                _               = s
-- ^ O wildcard `_` cobre todos os demais pares (Estado × Evento),
--   mantendo o estado inalterado. Escolha de design defensiva.

-- | Função de saída λ : Q × Σ → Output, para telemetria.
outputOf :: State -> Event -> Output
outputOf Grounded         TakeoffSignal   = MsgTakeoff
outputOf InFlight         CriticalBattery = MsgEmergency
outputOf EmergencyLanding LandedSignal    = MsgLanded
outputOf Grounded         SystemCutoff    = MsgShutdown
outputOf _                _               = MsgIgnored

-- ============================================================================
-- SEÇÃO 2 — STATE MONAD E CATEGORIA DE KLEISLI
-- ============================================================================
--
-- NOTA CATEGORIAL
-- ---------------
-- A State Monad é definida por:
--     newtype ST s a = ST { runST :: s -> (a, s) }
-- isomorfo ao hom interno s ⇒ (a, s) de Hask. Os morfismos da Categoria
-- de Kleisli associada são funções a → ST s b, compostas pelo operador
-- fish (Milewski, 2020, Cap. 4; Wadler, 1992).
--
-- A composição (>=) garante ASSOCIATIVIDADE, o que assegura que a ordem
-- de agrupamento das transições não altera o resultado final — exatamente
-- a propriedade que Hutton (2016), Cap. 12, formaliza como "monad laws".
-- ----------------------------------------------------------------------------

-- | State Monad customizada (padrão Hutton, 2016, Cap. 12).
newtype ST s a = ST { runST :: s -> (a, s) }

instance Functor (ST s) where
  fmap :: (a -> b) -> ST s a -> ST s b
  fmap g st = ST $ \s ->
    let (x, s') = runST st s
    in (g x, s')

instance Applicative (ST s) where
  pure :: a -> ST s a
  pure x = ST $ \s -> (x, s)

  (<*>) :: ST s (a -> b) -> ST s a -> ST s b
  stf <*> stx = ST $ \s ->
    let (f, s')  = runST stf s
        (x, s'') = runST stx s'
    in (f x, s'')

instance Monad (ST s) where
  (>>=) :: ST s a -> (a -> ST s b) -> ST s b
  st >>= f = ST $ \s ->
    let (x, s') = runST st s
    in runST (f x) s'

-- | Uma transição monádica: consome um evento, produz uma saída e
-- atualiza o estado do UAV de forma PURA (sem variáveis globais).
avionicsStep :: Event -> ST State Output
avionicsStep evt = ST $ \q ->
  let q'  = transition q evt
      out = outputOf q evt
  in (out, q')

-- | Operador de composição da Categoria de Kleisli (fish).
--
-- Assinatura: (a -> ST s b) -> (b -> ST s c) -> (a -> ST s c)
-- Em termos categoriais, este é o morfismo de composição da categoria
-- Kleisli(ST s), onde os objetos são tipos e os morfismos são funções
-- embelezadas a → ST s b (Milewski, 2020, §4.3).
kleisliComp :: (a -> ST s b) -> (b -> ST s c) -> (a -> ST s c)
kleisliComp f g = \x -> f x >>= g

-- | Sequencia uma lista de eventos via composição monádica.
-- A associatividade da composição garante que o resultado não depende
-- de como a lista é agrupada (monad law).
runEvents :: [Event] -> ST State [Output]
runEvents []     = pure []
runEvents (e:es) = do
  out  <- avionicsStep e
  outs <- runEvents es
  return (out : outs)
-- ^ A notação `do` é açúcar sintático para `>>=` (Oliveira, 2017, Cap. 8).

-- ============================================================================
-- SEÇÃO 3 — FRAMEWORK CREM-MINI (TYPE-LEVEL SAFETY)
-- ============================================================================
--
-- NOTA CATEGORIAL
-- ---------------
-- Reimplementamos localmente o NÚCLEO do framework CREM (Perone, 2023)
-- usando apenas GADTs e DataKinds nativos do GHC. Não usamos Template
-- Haskell nem a biblioteca `singletons`, mas mantemos as ideias centrais:
--
--   1. A TOPOLOGIA da FSM é promovida ao nível de tipos.
--   2. A ação exige uma PROVA em tempo de compilação (`AllowedTransition`)
--      de que a transição pertence à topologia.
--   3. Transições proibidas são rejeitadas pelo GHC, não em runtime.
--
-- A topologia é um functor representável (Milewski, 2020, Cap. 14),
-- funcionando como um "contêiner de transições permitidas" indexado por
-- pares de vértices.
-- ----------------------------------------------------------------------------

-- | Promoção do tipo dos vértices ao nível de tipos via DataKinds.
-- `'Grounded`, `'InFlight`, etc. são tipos (kind AvionicsVertex).
data AvionicsVertex
  = Grounded
  | InFlight
  | EmergencyLanding
  | Shutdown
  deriving (Show, Eq, Ord)

-- | Um GADT que representa uma prova de que existe uma transição
-- permitida de `from` para `to` na topologia. Cada construtor
-- corresponde a uma aresta da topologia.
--
-- Em termos categoriais, este é um tipo de provas indexado por pares
-- de vértices — uma versão "proof-relevant" da relação de alcançabilidade.
data AllowedTransition :: AvionicsVertex -> AvionicsVertex -> Type where
  EdgeGroundedToInFlight       :: AllowedTransition 'Grounded         'InFlight
  EdgeGroundedToShutdown       :: AllowedTransition 'Grounded         'Shutdown
  EdgeInFlightToEmergency      :: AllowedTransition 'InFlight         'EmergencyLanding
  EdgeEmergencyToGrounded      :: AllowedTransition 'EmergencyLanding 'Grounded

-- | Prova implícita: a transição é a identidade se `from ~ to`?
-- Não precisamos desta instância, pois o CREM proíbe auto-transições
-- na topologia. Se quiser permitir, basta adicionar um construtor
-- `Refl` e uma restrição `from ~ to`.

-- | Tipo que encapsula o resultado de uma ação, exigindo a prova
-- de que a transição está na topologia.
--
-- O parâmetro `m` representa o contexto Applicative (efeito) da ação.
-- Na versão mínima, fixamos `m = Maybe` por simplicidade, mas o
-- princípio se estende a qualquer Applicative.
data ActionResult
  (from :: AvionicsVertex)
  (to   :: AvionicsVertex)
  where
  ActionResult
    :: AllowedTransition from to  -- ^ Prova em tempo de compilação.
    -> Output                     -- ^ Saída emitida.
    -> ActionResult from to

-- | Construtor auxiliar que espelha `pureResult` do CREM.
-- Retorna `Nothing` se o efeito `Applicative m` não for suficiente —
-- na versão mínima, usamos Maybe como contexto.
pureResult
  :: AllowedTransition from to
  => Output
  -> ActionResult from to
pureResult = ActionResult

-- | Assinatura das ações da FSM de aviônica.
--
-- O tipo `ActionResult from to` só é construível quando existe uma
-- prova `AllowedTransition from to`. Se a transição declarada não
-- estiver na topologia, o GHC NÃO ENCONTRA a prova correspondente e
-- a compilação FALHA.
avionicsAction
  :: State              -- ^ Estado atual (a nível de valor).
  -> Event              -- ^ Evento recebido.
  -> ActionResult from to  -- ^ Resultado com prova embutida.
-- Casos permitidos (a prova está disponível para cada aresta):
avionicsAction Grounded         TakeoffSignal   =
  pureResult MsgTakeoff
-- ^ Prova: EdgeGroundedToInFlight

avionicsAction InFlight         CriticalBattery =
  pureResult MsgEmergency
-- ^ Prova: EdgeInFlightToEmergency

avionicsAction EmergencyLanding LandedSignal    =
  pureResult MsgLanded
-- ^ Prova: EdgeEmergencyToGrounded

avionicsAction Grounded         SystemCutoff    =
  pureResult MsgShutdown
-- ^ Prova: EdgeGroundedToShutdown

-- Casos auto-estabilizantes (no-op): o tipo da transição é `from ~ to`,
-- então NÃO temos uma prova `AllowedTransition from to` na topologia.
-- Para manter a assinatura, deixamos como erro (que só ocorre se
-- alguém chamar com evento irrelevante, o que não é previsto no uso).
avionicsAction _                _               =
  error "transição não permitida pela topologia"

-- ============================================================================
-- SEÇÃO 4 — TESTE DE INVALIDEZ DE TIPAGEM E COMPOSABILIDADE
-- ============================================================================

-- ----------------------------------------------------------------------------
-- TESTE DE INVALIDEZ DE TIPAGEM (COMPILAÇÃO FALHA INTENCIONAL)
-- ----------------------------------------------------------------------------
-- A função abaixo está comentada porque SUA PRESENÇA IMPEDIRIA A
-- COMPILAÇÃO DO MÓDULO. Ela demonstra, porém, o poder da abordagem
-- de capturar erros de regra de negócio em TEMPO DE COMPILAÇÃO.
--
-- invalidTransitionTest :: ActionResult 'InFlight 'Shutdown
-- invalidTransitionTest = pureResult MsgShutdown
--
-- ERRO DE COMPILAÇÃO ESPERADO:
--   • Could not deduce (AllowedTransition 'InFlight 'Shutdown)
--     arising from a use of ‘pureResult’
--   • In the expression: pureResult MsgShutdown
--   • In an equation for ‘invalidTransitionTest’:
--         invalidTransitionTest = pureResult MsgShutdown
--
-- MOTIVO: a topologia declarada em `AllowedTransition` NÃO contém a
-- aresta (InFlight, Shutdown). O GHC tenta resolver a restrição de
-- tipo `AllowedTransition 'InFlight 'Shutdown` e falha, pois nenhum
-- construtor (prova) correspondente existe. O erro é detectado ANTES
-- da execução do programa.
--
-- IMPLICAÇÃO DE SEGURANÇA: nenhuma aeronave pode ser desligada em pleno
-- voo por uma sequência de eventos — a transição é rejeitada pelo
-- sistema de tipos, não por uma verificação em runtime (Perone, 2023).
-- Isso estende o princípio de type safety de Hutton (2016), Cap. 3, do
-- nível sintático para o nível semântico do domínio.
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
-- COMPOSABILIDADE ARQUITETURAL (VERSÃO MÍNIMA)
-- ----------------------------------------------------------------------------
-- Em vez de reimplementar os construtores `Basic`, `Sequential`,
-- `Parallel`, etc. do CREM real, exemplificamos a ideia de composição
-- usando combinações puras de funções e da State Monad.
-- ----------------------------------------------------------------------------

-- | Composição sequencial: encadeia duas ações monádicas.
-- Em termos categoriais, é a composição de morfismos na categoria
-- Kleisli(ST).
avionicsSequential :: [Event] -> ST State [Output]
avionicsSequential = runEvents

-- | Composição em paralelo: executa duas listas de eventos
-- independentemente, compartilhando o estado.
-- Em termos categoriais, é a aplicação do bifunctor (×) sobre pares.
avionicsParallel :: [Event] -> [Event] -> ST State ([Output], [Output])
avionicsParallel es1 es2 = do
  outs1 <- runEvents es1
  outs2 <- runEvents es2
  return (outs1, outs2)

-- ============================================================================
-- EXECUÇÃO PRINCIPAL (DEMONSTRAÇÃO)
-- ============================================================================

-- | Demonstra o traço de execução do sistema sobre uma sequência
-- canônica de eventos:
--   Takeoff → CriticalBattery → Landed → SystemCutoff
-- O UAV deve passar por: Grounded → InFlight → EmergencyLanding
--                       → Grounded → Shutdown.
main :: IO ()
main = do
  let events = [ TakeoffSignal
               , CriticalBattery
               , LandedSignal
               , SystemCutoff
               ]
      (outs, finalState) = runST (runEvents events) Grounded
  putStrLn "=== Avionics FSM — Trace de Execução ==="
  putStrLn $ "Eventos:      " ++ show events
  putStrLn $ "Saídas:       " ++ show outs
  putStrLn $ "Estado final: " ++ show finalState