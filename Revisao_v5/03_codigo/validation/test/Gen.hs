-- ============================================================================
-- Geradores Hedgehog (reprodutíveis, com shrinking) — parecer de 03/11/2026, nível 3:
-- "o valor adicional está na diversidade dos cenários, nos geradores reprodutíveis e no shrinking".
--
-- O shrinking de `Gen.frequency` e de `Gen.element` vai em direção ao PRIMEIRO item; por isso os
-- itens ociosos vêm primeiro: um contraexemplo encolhe para a sequência mais curta e mais "vazia".
-- ============================================================================
module Gen
  ( genTick
  , genScenario
  , genWireWord
  , genWireText
  ) where

import Avionics.Sim.Scenario (Scenario, TickInput (..), allAvEvents, allPowerEvents)
import Hedgehog (Gen)
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Range as Range

-- | Um tick: 3/5 dos ticks sem comando, 2/5 com um dos 4 comandos; o mesmo para a energia.
-- Cobre as 20 entradas possíveis, mas favorece ticks pouco carregados (mais naturais).
genTick :: Gen TickInput
genTick =
  TickInput
    <$> Gen.frequency [(3, pure Nothing), (2, Just <$> Gen.element allAvEvents)]
    <*> Gen.frequency [(3, pure Nothing), (2, Just <$> Gen.element allPowerEvents)]

-- | Cenário de 0 a `maxLen` ticks. O comprimento passa de 4, o limite da enumeração original.
genScenario :: Int -> Gen Scenario
genScenario maxLen = Gen.list (Range.linear 0 maxLen) genTick

-- | Uma palavra do vocabulário da fronteira, uma variação de caixa ou lixo.
genWireWord :: Gen String
genWireWord =
  Gen.frequency
    [ (6, Gen.element ["TAKEOFF", "CRITICAL", "LANDED", "CUTOFF", "DRAIN", "RECHARGE", "SHEDLOAD", "IDLE"])
    , (2, Gen.element ["takeoff", "Takeoff", "TakeoffSignal", "drain", "Idle", "FLY", "42"])
    , (1, Gen.string (Range.linear 0 12) Gen.unicode)
    ]

-- | Texto de cenário arbitrário: linhas com 0 a 4 palavras, às vezes comentário.
genWireText :: Gen String
genWireText = do
  ls <- Gen.list (Range.linear 0 12) genLine
  pure (unlines ls)
  where
    genLine = do
      ws <- Gen.list (Range.linear 0 4) genWireWord
      c <- Gen.frequency [(4, pure ""), (1, pure " # comentário")]
      pure (unwords ws ++ c)
