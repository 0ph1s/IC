-- ============================================================================
-- MODELO DE REFERÊNCIA (ORÁCULO) DO LAÇO FECHADO, GUIADO PELAS TABELAS CSV
-- ----------------------------------------------------------------------------
-- Reimplementa, em Haskell comum e SEM o CREM, o laço aviônica || energia -> ambiente
-- -> (liberação no Beat seguinte). Diferença em relação ao modelo de referência que já
-- existia (test/SpecPolicy.hs do pacote avionics-crem):
--
--   * lá, a planta usava `Avionics.Naive.transition` (código do mesmo autor);
--   * aqui, a planta lê spec/transition_table.csv e spec/power_table.csv, o artefato
--     que a orientação revisa. O oráculo passa a depender de dados revisáveis, e não de
--     uma função escrita pela mesma pessoa que escreveu o CREM.
--
-- O ambiente segue a descrição em spec/POLITICAS.md (e docs/simulador.md do pacote base).
-- Tudo isto continua sendo escrito pela mesma pessoa: o oráculo é INDEPENDENTE DO CÓDIGO
-- em teste, não de TERCEIROS (limitação registrada em 02_relatorio e em 06_artigos).
-- ============================================================================
module Validation.RefModel
  ( RefState (..)
  , initialRef
  , refTick
  , refRun
  , refSteps
  , stuckInFlight
  ) where

import Avionics.Crem (AvEvent (..), Output (..))
import qualified Avionics.Naive as N
import Avionics.Power (PowerEvent (..), PowerReport (..))
import Avionics.Sim.Scenario (Scenario, TickInput (..))
import Data.List (foldl')
import Validation.Table
import Validation.Types

-- | Estado completo do laço, entre dois ticks.
data RefState = RefState
  { rAv :: N.AvState
  , rPw :: Pw
  , rSlot :: [Group]
  -- ^ OneSlot e Level: no máximo um grupo; Queue: grupos em ordem de chegada, sem repetição
  }
  deriving (Show, Eq, Ord)

initialRef :: RefState
initialRef = RefState {rAv = N.Grounded, rPw = PwCharged, rSlot = []}

-- | Estímulos do laço.
data Sig = SigBeat | SigAv AvEvent | SigPw PowerEvent
  deriving (Show, Eq)

-- | Telemetria já classificada para o ambiente.
data Cue = CBeat | CCrit | CEmergency | CLanded | CQuiet
  deriving (Show, Eq)

-- | O que cada retenção libera no Beat seguinte, em ordem (spec/POLITICAS.md, tabela do ambiente).
release :: Group -> [Sig]
release GCrit = [SigAv CriticalBattery]
release GTouch = [SigPw ShedLoad, SigAv LandedSignal]
release GCut = [SigAv SystemCutoff]

groupOf :: Cue -> Maybe Group
groupOf CCrit = Just GCrit
groupOf CEmergency = Just GTouch
groupOf CLanded = Just GCut
groupOf CBeat = Nothing
groupOf CQuiet = Nothing

-- | A planta: aplica o sinal pelas TABELAS e classifica a telemetria.
plant :: Tables -> Sig -> RefState -> (RefState, Maybe AvEvent, Maybe PowerEvent, Maybe Output, Cue)
plant _ SigBeat m = (m, Nothing, Nothing, Nothing, CBeat)
plant t (SigAv e) m =
  let (q', o) = tAv t (rAv m) e
   in (m {rAv = q'}, Just e, Nothing, Just o, avCue o)
plant t (SigPw e) m =
  let (p', r) = tPw t (rPw m) e
   in (m {rPw = p'}, Nothing, Just e, Nothing, pwCue r)

avCue :: Output -> Cue
avCue MsgEmergency = CEmergency
avCue MsgLanded = CLanded
avCue MsgTakeoff = CQuiet
avCue MsgShutdown = CQuiet
avCue MsgIgnored = CQuiet

pwCue :: PowerReport -> Cue
pwCue ReportCritical = CCrit
pwCue ReportOk = CQuiet
pwCue ReportLow = CQuiet

-- | O ambiente: devolve o novo estado e os sinais que libera.
mission :: Policy -> Cue -> RefState -> (RefState, [Sig])
mission pol CBeat m =
  let released = concatMap release (rSlot m)
      -- Level: com o slot livre, bateria crítica e aviônica em voo, reage ao NÍVEL.
      level = [SigAv CriticalBattery | pol == Level, null (rSlot m), rPw m == PwCritical, rAv m == N.InFlight]
   in (m {rSlot = []}, released ++ level)
mission pol cue m = case groupOf cue of
  Nothing -> (m, [])
  Just g -> case pol of
    Queue -> (if g `elem` rSlot m then m else m {rSlot = rSlot m ++ [g]}, [])
    OneSlot -> (occupy g, [])
    Level -> (occupy g, [])
  where
    occupy g = if null (rSlot m) then m {rSlot = [g]} else m

-- | Processa um sinal e, em profundidade, tudo o que o ambiente liberar (é a ordem do
-- `Feedback` do CREM: primeiro o passo do sinal, depois a recursão sobre cada sinal liberado).
process :: Tables -> Policy -> Int -> Sig -> RefState -> (RefState, [StepSum])
process t pol tick sig m0 =
  let (m1, avIn, pwIn, avOut, cue) = plant t sig m0
      (m2, emitted) = mission pol cue m1
      here = StepSum tick avIn pwIn avOut (rAv m2) (rPw m2) (slotName (rSlot m2))
      (m3, rest) = foldl' (\(m, acc) s -> let (m', ss) = process t pol tick s m in (m', acc ++ ss)) (m2, []) emitted
   in (m3, here : rest)

-- | Um tick: o Beat, depois o comando, depois a energia (a mesma ordem de `externalSignals`).
refTick :: Tables -> Policy -> Int -> RefState -> TickInput -> (RefState, [StepSum])
refTick t pol n m0 inp =
  foldl'
    (\(m, acc) s -> let (m', ss) = process t pol n s m in (m', acc ++ ss))
    (m0, [])
    (SigBeat : map SigAv (maybe [] pure (tiCommand inp)) ++ map SigPw (maybe [] pure (tiPower inp)))

-- | Um cenário inteiro a partir do estado inicial padrão (Grounded, Charged, ambiente livre).
refRun :: Tables -> Policy -> Scenario -> (RefState, [StepSum])
refRun t pol sc =
  foldl'
    (\(m, acc) (n, inp) -> let (m', ss) = refTick t pol n m inp in (m', acc ++ ss))
    (initialRef, [])
    (zip [0 ..] sc)

-- | Só os passos de 'refRun'.
refSteps :: Tables -> Policy -> Scenario -> [StepSum]
refSteps t pol = snd . refRun t pol

-- | A bateria está crítica com a aviônica em voo: o estado em que o ambiente "não enxerga" o
-- NÍVEL (só reage à entrada da bateria em Critical).
stuckInFlight :: RefState -> Bool
stuckInFlight s = rAv s == N.InFlight && rPw s == PwCritical
