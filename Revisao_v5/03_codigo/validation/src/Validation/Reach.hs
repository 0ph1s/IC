{-# LANGUAGE DataKinds #-}

-- ============================================================================
-- ALCANÇABILIDADE EXAUSTIVA DO LAÇO FECHADO (parecer de 03/11/2026, nível 2)
-- ----------------------------------------------------------------------------
-- Os 168 421 cenários da suíte original são uma enumeração LIMITADA (até 4 ticks): não
-- dizem nada sobre sequências mais longas. Mas o estado do laço entre dois ticks é só o
-- terno de vértices (aviônica, energia, ambiente): no máximo 4 x 3 x 4 = 48 estados. Logo
-- dá para explorar o grafo de estados alcançáveis até o FECHAMENTO, com o alfabeto completo
-- de entradas de um tick (20 símbolos), e conferir propriedades para TODAS as sequências,
-- de qualquer comprimento.
--
-- Duas explorações, comparadas aresta a aresta:
--   * `cremTS`: a IMPLEMENTAÇÃO. Cada passo constrói o laço `closedLoop` do CREM em um
--     terno de vértices qualquer (com `withSomeSing`) e o roda sobre um tick. Usa o
--     Feedback, a Mission e as ações reais, e não o simulador de cenários.
--   * `refTS` : o oráculo guiado pelas tabelas CSV (Validation.RefModel).
--
-- HIPÓTESE DA ABSTRAÇÃO (declarada, não provada): o comportamento futuro do laço depende
-- só do terno de vértices. Vale por construção de `closedLoop` (que é função dos três
-- vértices), e é conferida empiricamente por `faithful`: o terno e os passos obtidos por
-- iteração de `cremNext` coincidem com os do simulador de cenários.
--
-- O que isto prova e o que não prova: é uma prova de equivalência entre DUAS
-- representações escritas pela mesma pessoa, sob a hipótese acima; não prova que a
-- especificação reflete requisitos reais, nem que o CREM está correto.
-- ============================================================================
module Validation.Reach
  ( TS (..)
  , Graph (..)
  , explore
  , pathTo
  , edgeMap
  , AbsState (..)
  , prettyAbs
  , absOfRef
  , cremTS
  , refTS
  , cremNext
  , productTS
  , faithful
  , avSeqViolations
  , trapped
  , foreverBad
  , maxCascade
  ) where

import Avionics.Crem (AvionicsVertex (..), SAvionicsVertex)
import qualified Avionics.Naive as N
import Avionics.Power (PowerVertex (..), SPowerVertex)
import Avionics.Sim.Loop (LoopStep (..), closedLoop)
import Avionics.Sim.Mission (MissionVertex (..), SMissionVertex)
import Avionics.Sim.Observe (Observation (..))
import Avionics.Sim.Scenario (Scenario, Signal, TickInput, allTickInputs, externalSignals)
import Crem.StateMachine (StateMachineT, run)
import Data.Functor.Identity (Identity (..))
import Data.List (foldl')
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Data.Singletons (withSomeSing)
import Validation.Compare (cremSteps, pwOfVertex)
import Validation.RefModel
import Validation.Table (Tables)
import Validation.Types
import Avionics.Sim.Validate (naiveVertex)

-- | Um sistema de transições determinístico, finito, com alfabeto de ticks.
data TS s o = TS
  { tsStart :: s
  , tsInputs :: [TickInput]
  , tsNext :: s -> TickInput -> (s, o)
  -- ^ novo estado e uma observação (aqui, os passos do tick)
  }

-- | Grafo alcançável: profundidade BFS, pai (para reconstruir o caminho mais curto) e arestas.
data Graph s o = Graph
  { gStart :: s
  , gDepth :: M.Map s Int
  , gParent :: M.Map s (s, Int)
  -- ^ (estado anterior, índice da entrada em `tsInputs`)
  , gEdges :: [(s, Int, s, o)]
  -- ^ (origem, índice da entrada, destino, observação)
  }

-- | Busca em largura até o fechamento.
explore :: Ord s => TS s o -> Graph s o
explore ts = go [start] (M.singleton start 0) M.empty []
  where
    start = tsStart ts
    go [] depth parent edges = Graph start depth parent (reverse edges)
    go (s : queue) depth parent edges =
      let d = M.findWithDefault 0 s depth
          visit (q, dp, pr, es) (i, inp) =
            let (s', o) = tsNext ts s inp
                es' = (s, i, s', o) : es
             in if M.member s' dp
                  then (q, dp, pr, es')
                  else (q ++ [s'], M.insert s' (d + 1) dp, M.insert s' (s, i) pr, es')
          (queue', depth', parent', edges') = foldl' visit (queue, depth, parent, edges) (zip [0 ..] (tsInputs ts))
       in go queue' depth' parent' edges'

-- | Menor sequência de ticks que leva do início a `s`.
pathTo :: Ord s => TS s o -> Graph s o -> s -> [TickInput]
pathTo ts g = reverse . walk
  where
    walk x = case M.lookup x (gParent g) of
      Nothing -> []
      Just (p, i) -> (tsInputs ts !! i) : walk p

-- | As arestas indexadas por (origem, entrada), com as chaves já traduzidas.
edgeMap :: Ord k => (s -> k) -> Graph s o -> M.Map (k, Int) (k, o)
edgeMap f g = M.fromList [((f s, i), (f s', o)) | (s, i, s', o) <- gEdges g]

-- ----------------------------------------------------------------------------
-- A implementação em CREM
-- ----------------------------------------------------------------------------

-- | Terno de vértices (aviônica, energia, ambiente) como índices (a ordem de `avVs` etc.).
data AbsState = AbsState {asAv :: Int, asPw :: Int, asMs :: Int}
  deriving (Show, Eq, Ord)

avVs :: [AvionicsVertex]
avVs = [Grounded, InFlight, EmergencyLanding, Shutdown]

pwVs :: [PowerVertex]
pwVs = [Charged, Low, Critical]

msVs :: [MissionVertex]
msVs = [Standby, CriticalHeld, TouchdownHeld, CutoffHeld]

-- As funções de índice não têm curinga: um vértice novo quebra a compilação aqui.
avIdx :: AvionicsVertex -> Int
avIdx Grounded = 0
avIdx InFlight = 1
avIdx EmergencyLanding = 2
avIdx Shutdown = 3

pwIdx :: PowerVertex -> Int
pwIdx Charged = 0
pwIdx Low = 1
pwIdx Critical = 2

msIdx :: MissionVertex -> Int
msIdx Standby = 0
msIdx CriticalHeld = 1
msIdx TouchdownHeld = 2
msIdx CutoffHeld = 3

prettyAbs :: AbsState -> String
prettyAbs (AbsState a p q) = "(" ++ show (avVs !! a) ++ ", " ++ show (pwVs !! p) ++ ", " ++ show (msVs !! q) ++ ")"

-- | O terno do oráculo, para comparar com o da implementação. Só OneSlot (e Level) têm
-- correspondente: um slot com dois ou mais grupos (Queue) devolve -1.
absOfRef :: RefState -> AbsState
absOfRef (RefState av pw slot) = AbsState (fromEnum av) (fromEnum pw) (slotIdx slot)
  where
    slotIdx [] = 0
    slotIdx [GCrit] = 1
    slotIdx [GTouch] = 2
    slotIdx [GCut] = 3
    slotIdx _ = -1

-- | Roda uma lista de sinais, um a um, sobre a máquina (em `Identity`).
runAll :: StateMachineT Identity Signal [LoopStep] -> [Signal] -> [LoopStep]
runAll _ [] = []
runAll m (s : ss) =
  let (steps, m') = runIdentity (run m s)
   in steps ++ runAll m' ss

-- | Um tick da IMPLEMENTAÇÃO a partir de um terno qualquer: constrói o laço fechado do CREM com os
-- três vértices dados e aplica os sinais do tick (`Beat`, comando, energia).
cremNext :: AbsState -> TickInput -> (AbsState, [StepSum])
cremNext (AbsState a p q) inp =
  withSomeSing @AvionicsVertex (avVs !! a) $ \sa ->
    withSomeSing @PowerVertex (pwVs !! p) $ \sp ->
      withSomeSing @MissionVertex (msVs !! q) $ \sq ->
        summarize (machine sa sp sq)
  where
    machine :: SAvionicsVertex x -> SPowerVertex y -> SMissionVertex z -> [LoopStep]
    machine sa sp sq = runAll (closedLoop sa sp sq) (externalSignals inp)
    summarize steps = (end steps, map stepSum steps)
    end steps = case reverse steps of
      ls : _ -> AbsState (avIdx (obsVertex (lsAv ls))) (pwIdx (obsVertex (lsPow ls))) (msIdx (obsVertex (lsMission ls)))
      [] -> AbsState a p q
    stepSum ls =
      StepSum
        { ssTick = 0
        , ssAvIn = obsInput (lsAv ls)
        , ssPwIn = obsInput (lsPow ls)
        , ssAvOut = obsOutput (lsAv ls)
        , ssAv = naiveVertex (obsVertex (lsAv ls))
        , ssPw = pwOfVertex (obsVertex (lsPow ls))
        , ssMission = show (obsVertex (lsMission ls))
        }

-- | O sistema de transições da implementação.
cremTS :: TS AbsState [StepSum]
cremTS = TS {tsStart = AbsState 0 0 0, tsInputs = allTickInputs, tsNext = cremNext}

-- | O sistema de transições do oráculo (com a política dada).
refTS :: Tables -> Policy -> TS RefState [StepSum]
refTS t pol = TS {tsStart = initialRef, tsInputs = allTickInputs, tsNext = \s inp -> refTick t pol 0 s inp}

-- | Produto de dois sistemas sobre o MESMO alfabeto: os dois recebem a mesma entrada a cada tick.
-- Serve para procurar o primeiro ponto em que duas políticas (ou a implementação e um oráculo) divergem.
productTS :: TS s o -> TS t p -> TS (s, t) (o, p)
productTS a b =
  TS
    { tsStart = (tsStart a, tsStart b)
    , tsInputs = tsInputs a
    , tsNext = \(s, t) inp ->
        let (s', o) = tsNext a s inp
            (t', p) = tsNext b t inp
         in ((s', t'), (o, p))
    }

-- | Confere a hipótese da abstração num cenário: iterar `cremNext` dá os mesmos passos que o
-- simulador de cenários (os números de tick são ignorados), e o terno que a iteração carrega de um
-- tick para o outro é o terno final do simulador.
faithful :: Scenario -> Bool
faithful sc = concat stepsPerTick == map zeroTick simSteps && sFinal == simFinal
  where
    simSteps = cremSteps sc
    (sFinal, stepsPerTick) = foldl' (\(s, acc) inp -> let (s', ss) = cremNext s inp in (s', acc ++ [ss])) (tsStart cremTS, []) sc
    zeroTick x = x {ssTick = 0}
    -- terno lido do último passo do simulador (a ordem de `AvState` e de `Pw` é a de `avVs` e `pwVs`)
    simFinal = case reverse simSteps of
      s : _ -> AbsState (fromEnum (ssAv s)) (fromEnum (ssPw s)) (maybe (-1) id (lookup (ssMission s) msByName))
      [] -> tsStart cremTS
    msByName = [(show v, msIdx v) | v <- msVs]

-- ----------------------------------------------------------------------------
-- Propriedades sobre o grafo
-- ----------------------------------------------------------------------------

-- | Violações de segurança de TOPOLOGIA ao longo dos passos de uma aresta (um tick).
-- `a0` é a aviônica ao início do tick. Lista vazia = nenhuma violação.
avSeqViolations :: N.AvState -> [StepSum] -> [String]
avSeqViolations a0 steps = concat [check x y | (x, y) <- zip vs (drop 1 vs)]
  where
    vs = a0 : map ssAv steps
    check x y =
      [ "InFlight -> Shutdown direto" | x == N.InFlight, y == N.Shutdown ]
        ++ [ "Shutdown vindo de " ++ show x | y == N.Shutdown, x `notElem` [N.Grounded, N.Shutdown] ]
        ++ [ "EmergencyLanding vindo de " ++ show x | y == N.EmergencyLanding, x `notElem` [N.InFlight, N.EmergencyLanding] ]

-- | Estados alcançáveis em que `bad` vale e CONTINUA valendo para sempre sob ticks ociosos
-- (o primeiro símbolo do alfabeto, índice dado). Como o sistema é determinístico e finito,
-- basta seguir a sucessão até repetir. Equivale a "a propriedade `<>` não bad falha sob
-- justiça fraca do tick ocioso".
trapped :: Ord s => Int -> (s -> Bool) -> Graph s o -> [s]
trapped idleIx bad g = [s | s <- M.keys (gDepth g), bad s, loops S.empty s]
  where
    next = M.fromList [(s, s') | (s, i, s', _) <- gEdges g, i == idleIx]
    loops seen x
      | not (bad x) = False
      | x `S.member` seen = True
      | otherwise = maybe False (loops (S.insert x seen)) (M.lookup x next)

-- | Estados de que existe um caminho INFINITO, com QUAISQUER entradas, que permanece em `bad` para
-- sempre (maior ponto fixo de "bad e tem sucessor no conjunto"). É a negação de `[]<>(~bad)`, a
-- propriedade NoPermanentBlindness de 04_tla/AvionicsLoop.tla. Mais forte que `trapped`, que só
-- considera ticks ociosos.
foreverBad :: Ord s => (s -> Bool) -> Graph s o -> [s]
foreverBad bad g = S.toList (fixp (S.fromList [s | s <- M.keys (gDepth g), bad s]))
  where
    succs = M.fromListWith (++) [(s, [t]) | (s, _, t, _) <- gEdges g]
    fixp cur =
      let next = S.filter (\s -> any (`S.member` cur) (M.findWithDefault [] s succs)) cur
       in if S.size next == S.size cur then cur else fixp next

-- | Maior número de passos de um único tick, sobre todas as arestas: limite do número de
-- iterações do `Feedback` dentro de um tick (a realimentação termina?).
maxCascade :: Graph s [StepSum] -> Int
maxCascade g = maximum (0 : [length o | (_, _, _, o) <- gEdges g])
