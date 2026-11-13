-- ============================================================================
-- COMPARADOR DE TRAÇOS (parecer de 03/11/2026, seção 4: "confronta estado final, saídas,
-- passos intermediários e propriedades")
-- ----------------------------------------------------------------------------
-- A implementação em CREM (Avionics.Sim.Simulate.simulateClosed) e o oráculo
-- (Validation.RefModel) são reduzidos à MESMA lista de `StepSum`, um por sinal processado.
-- A comparação é por PASSO (o grão mais fino): se coincidir, coincidem também os vértices ao
-- fim de cada tick, as saídas e o estado final.
-- ============================================================================
module Validation.Compare
  ( cremSteps
  , cremOpenSteps
  , Divergence (..)
  , compareSteps
  , renderDivergence
  , significantOutputsOf
  , finalAvOf
  , finalPwOf
  , pwOfVertex
  ) where

import Avionics.Crem (Output (..))
import qualified Avionics.Naive as N
import Avionics.Power (PowerVertex (..))
import Avionics.Sim.Observe (Observation (..))
import Avionics.Sim.Scenario (Scenario, defaultInit)
import Avionics.Sim.Simulate (simulate, simulateClosed)
import Avionics.Sim.Trace
import Avionics.Sim.Validate (naiveVertex)
import Validation.Types

-- | Nível da bateria do CREM -> nível do oráculo.
pwOfVertex :: PowerVertex -> Pw
pwOfVertex Charged = PwCharged
pwOfVertex Low = PwLow
pwOfVertex Critical = PwCritical

stepSumOf :: Int -> StepRecord -> StepSum
stepSumOf tick s =
  StepSum
    { ssTick = tick
    , ssAvIn = obsInput av
    , ssPwIn = obsInput pw
    , ssAvOut = obsOutput av
    , ssAv = naiveVertex (obsVertex av)
    , ssPw = pwOfVertex (obsVertex pw)
    , ssMission = maybe "-" (show . obsVertex) (srMission s)
    }
  where
    av = srAv s
    pw = srPow s

-- | Passos da simulação em malha FECHADA (com o ambiente `Mission`), do estado inicial padrão.
cremSteps :: Scenario -> [StepSum]
cremSteps sc = [stepSumOf (tsTick tk) s | tk <- trTicks (simulateClosed sc defaultInit), s <- tsSteps tk]

-- | Passos da simulação em malha ABERTA (sem ambiente; o campo `ssMission` fica "-").
cremOpenSteps :: Scenario -> [StepSum]
cremOpenSteps sc = [stepSumOf (tsTick tk) s | tk <- trTicks (simulate sc defaultInit), s <- tsSteps tk]

-- | Primeiro ponto em que dois traços divergem.
data Divergence = Divergence
  { dvIndex :: Int
  -- ^ posição (a partir de 0) do passo na lista
  , dvActual :: Maybe StepSum
  -- ^ o que a implementação fez (`Nothing`: ela terminou antes)
  , dvExpected :: Maybe StepSum
  -- ^ o que o oráculo previu (`Nothing`: ele terminou antes)
  }
  deriving (Show, Eq)

-- | `Nothing` se os dois traços são iguais; senão, a primeira divergência.
compareSteps :: [StepSum] -> [StepSum] -> Maybe Divergence
compareSteps = go 0
  where
    go _ [] [] = Nothing
    go i (a : as) (e : es)
      | a == e = go (i + 1) as es
      | otherwise = Just (Divergence i (Just a) (Just e))
    go i (a : _) [] = Just (Divergence i (Just a) Nothing)
    go i [] (e : _) = Just (Divergence i Nothing (Just e))

renderDivergence :: Divergence -> String
renderDivergence d =
  "passo " ++ show (dvIndex d) ++ ": implementação=" ++ maybe "(fim)" show (dvActual d)
    ++ "  oráculo=" ++ maybe "(fim)" show (dvExpected d)

-- | Saídas da aviônica sem `MsgIgnored`.
significantOutputsOf :: [StepSum] -> [Output]
significantOutputsOf steps = [o | Just o <- map ssAvOut steps, o /= MsgIgnored]

-- | Estado final da aviônica (`Grounded` se não houve passo).
finalAvOf :: [StepSum] -> N.AvState
finalAvOf steps = case reverse steps of
  s : _ -> ssAv s
  [] -> N.Grounded

-- | Nível final da bateria (`PwCharged` se não houve passo).
finalPwOf :: [StepSum] -> Pw
finalPwOf steps = case reverse steps of
  s : _ -> ssPw s
  [] -> PwCharged
