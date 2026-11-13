-- ============================================================================
-- FRONTEIRA DE INTEGRAÇÃO TIPADA (parecer de 03/11/2026, seção 4)
-- ----------------------------------------------------------------------------
--   gerador externo / oráculo / arquivo de cenários
--        │  texto (bytes, String)             <- NÃO é tipado em Haskell
--        ▼
--   adaptador de fronteira  (este módulo): decodifica e valida
--        │  Either BoundaryError AvEvent     <- a partir daqui há ADTs
--        ▼
--   FSM em CREM  (restrições de topologia por aresta)
--        ▼
--   comparador de traços  (Validation.Compare)
--
-- O que este módulo garante: todo valor `AvEvent` / `PowerEvent` / `TickInput` que
-- sai daqui é um construtor válido; entrada fora do vocabulário vira `Left`, nunca
-- exceção. O que NÃO garante: que o evento escolhido leve ao destino semanticamente
-- correto. Isso é especificação e verificação próprias (spec/transition_table.csv
-- e a suíte de conformidade).
--
-- Formato de cenário (um tick por linha; `#` começa comentário; linha em branco é
-- ignorada):
--     TAKEOFF | CRITICAL | LANDED | CUTOFF     comando para a aviônica (no máximo um)
--     DRAIN | RECHARGE | SHEDLOAD              evento de energia (no máximo um)
--     IDLE                                     tick sem entrada (só, na linha)
--   Exemplos de linha:  `TAKEOFF`   `DRAIN`   `TAKEOFF DRAIN`   `IDLE`
--   A decodificação é ESTRITA: só maiúsculas, só este vocabulário.
-- ============================================================================
module Validation.Boundary
  ( BoundaryError (..)
  , renderBoundaryError
  , decodeEvent
  , encodeEvent
  , decodePowerEvent
  , encodePowerEvent
  , decodeTick
  , encodeTick
  , decodeScenario
  , encodeScenario
  , runExternalScenario
  ) where

import Avionics.Crem (AvEvent (..))
import Avionics.Power (PowerEvent (..))
import Avionics.Sim.Scenario (Scenario, TickInput (..), defaultInit, idle)
import Avionics.Sim.Simulate (simulateClosed)
import Avionics.Sim.Trace (Trace)
import Data.Either (lefts, rights)

-- | Por que uma entrada externa foi recusada.
data BoundaryError
  = UnknownToken String
  -- ^ palavra fora do vocabulário
  | AmbiguousTick [String]
  -- ^ tick vazio, `IDLE` misturado com outra palavra, ou mais de um comando / mais de um evento de energia
  | AtLine Int BoundaryError
  -- ^ o erro, com o número (a partir de 1) da linha do cenário
  deriving (Show, Eq)

renderBoundaryError :: BoundaryError -> String
renderBoundaryError (UnknownToken t) = "palavra desconhecida: " ++ show t
renderBoundaryError (AmbiguousTick ts) = "tick ambíguo ou vazio: " ++ show ts
renderBoundaryError (AtLine n e) = "linha " ++ show n ++ ": " ++ renderBoundaryError e

-- | Evento de comando recebido de fora. Equivale ao exemplo `decodeEvent` do parecer,
-- com erro tipado em vez de `String`.
decodeEvent :: String -> Either BoundaryError AvEvent
decodeEvent "TAKEOFF" = Right TakeoffSignal
decodeEvent "CRITICAL" = Right CriticalBattery
decodeEvent "LANDED" = Right LandedSignal
decodeEvent "CUTOFF" = Right SystemCutoff
decodeEvent other = Left (UnknownToken other)

-- | Inversa de 'decodeEvent'. Sem curinga: um construtor novo em `AvEvent` quebra a compilação aqui.
encodeEvent :: AvEvent -> String
encodeEvent TakeoffSignal = "TAKEOFF"
encodeEvent CriticalBattery = "CRITICAL"
encodeEvent LandedSignal = "LANDED"
encodeEvent SystemCutoff = "CUTOFF"

decodePowerEvent :: String -> Either BoundaryError PowerEvent
decodePowerEvent "DRAIN" = Right Drain
decodePowerEvent "RECHARGE" = Right Recharge
decodePowerEvent "SHEDLOAD" = Right ShedLoad
decodePowerEvent other = Left (UnknownToken other)

encodePowerEvent :: PowerEvent -> String
encodePowerEvent Drain = "DRAIN"
encodePowerEvent Recharge = "RECHARGE"
encodePowerEvent ShedLoad = "SHEDLOAD"

-- | Um tick a partir das palavras de uma linha.
decodeTick :: [String] -> Either BoundaryError TickInput
decodeTick ["IDLE"] = Right idle
decodeTick [] = Left (AmbiguousTick [])
decodeTick ws
  | "IDLE" `elem` ws = Left (AmbiguousTick ws) -- IDLE só vale sozinho (caso acima)
  | otherwise = do
      classified <- traverse classify ws
      let (cs, ps) = (lefts classified, rights classified)
      if length cs <= 1 && length ps <= 1
        then Right (TickInput {tiCommand = firstOf cs, tiPower = firstOf ps})
        else Left (AmbiguousTick ws)
  where
    classify w = case (decodeEvent w, decodePowerEvent w) of
      (Right e, _) -> Right (Left e)
      (_, Right p) -> Right (Right p)
      _ -> Left (UnknownToken w)
    firstOf (x : _) = Just x
    firstOf [] = Nothing

-- | Inversa de 'decodeTick' (um tick sem entrada vira `IDLE`).
encodeTick :: TickInput -> String
encodeTick (TickInput Nothing Nothing) = "IDLE"
encodeTick (TickInput c p) = unwords (maybe [] (pure . encodeEvent) c ++ maybe [] (pure . encodePowerEvent) p)

-- | Um cenário inteiro. `\r` (fim de linha do Windows) conta como espaço.
decodeScenario :: String -> Either BoundaryError Scenario
decodeScenario txt = traverse decodeLine numbered
  where
    numbered = [(n, ws) | (n, l) <- zip [1 ..] (lines txt), let ws = words (takeWhile (/= '#') l), not (null ws)]
    decodeLine (n, ws) = either (Left . AtLine n) Right (decodeTick ws)

encodeScenario :: Scenario -> String
encodeScenario = unlines . map encodeTick

-- | O caminho completo da fronteira: texto -> ADTs -> FSM em CREM (malha fechada, estado inicial padrão).
runExternalScenario :: String -> Either BoundaryError Trace
runExternalScenario txt = (\sc -> simulateClosed sc defaultInit) <$> decodeScenario txt
