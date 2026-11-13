-- ============================================================================
-- Tipos compartilhados do pacote de validação.
-- ----------------------------------------------------------------------------
-- O oráculo (RefModel) NÃO usa as funções de transição do pacote avionics-crem
-- (nem `Avionics.Naive.transition`, nem `avionicsAction`): ele só usa os TIPOS de
-- dados de estado e de evento (AvState, AvEvent, Output, PowerEvent, PowerReport),
-- para poder comparar valores com a implementação. As regras de transição vêm de
-- spec/*.csv (ver Validation.Table).
--
-- `Pw` é uma enumeração própria do nível da bateria. `PowerVertex` (do CREM) não
-- tem `Ord`, que é preciso para usar o estado como chave de um `Map` na
-- alcançabilidade.
-- ============================================================================
module Validation.Types
  ( Pw (..)
  , allPw
  , pwName
  , Policy (..)
  , Group (..)
  , StepSum (..)
  , slotName
  ) where

import Avionics.Crem (AvEvent, Output)
import qualified Avionics.Naive as N
import Avionics.Power (PowerEvent)

-- | Nível da bateria.
data Pw = PwCharged | PwLow | PwCritical
  deriving (Show, Eq, Ord, Enum, Bounded)

allPw :: [Pw]
allPw = [minBound .. maxBound]

-- | Nome do nível, o mesmo usado em spec/power_table.csv e no CREM.
pwName :: Pw -> String
pwName PwCharged = "Charged"
pwName PwLow = "Low"
pwName PwCritical = "Critical"

-- | Política do ambiente (registrador do ambiente), descrita em spec/POLITICAS.md.
--
--   * OneSlot: um slot, quem chega primeiro fica (a do projeto, implementada por `Mission`);
--   * Queue  : fila sem perda (cada tipo de retenção entra uma vez);
--   * Level  : um slot e, além disso, reação ao NÍVEL da bateria.
--
-- Só OneSlot existe na implementação em CREM; as outras duas existem apenas no modelo.
data Policy = OneSlot | Queue | Level
  deriving (Show, Eq, Ord, Enum, Bounded)

-- | O que o ambiente retém.
data Group = GCrit | GTouch | GCut
  deriving (Show, Eq, Ord)

-- | Resumo de UM passo do laço (um sinal processado), na forma comum ao oráculo e
-- à implementação em CREM. É o que o comparador de traços confronta.
data StepSum = StepSum
  { ssTick :: Int
  , ssAvIn :: Maybe AvEvent
  , ssPwIn :: Maybe PowerEvent
  , ssAvOut :: Maybe Output
  , ssAv :: N.AvState
  , ssPw :: Pw
  , ssMission :: String
  -- ^ vértice do ambiente depois do passo ("Standby", "CriticalHeld", ...)
  }
  deriving (Show, Eq)

-- | Nome do vértice do ambiente equivalente a um conteúdo de slot. Só OneSlot e Level
-- (no máximo um grupo) têm vértice correspondente em `Avionics.Sim.Mission`.
slotName :: [Group] -> String
slotName [] = "Standby"
slotName [GCrit] = "CriticalHeld"
slotName [GTouch] = "TouchdownHeld"
slotName [GCut] = "CutoffHeld"
slotName gs = "Queue" ++ show gs
