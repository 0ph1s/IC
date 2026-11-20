-- ============================================================================
-- DETERMINAÇÃO DO ESTADO (SD) a partir dos 48 ternos — tarefa T02 do plano v2 (14/11/2026).
-- Rodar (na pasta validation/):   cabal test validation-sd-tests
--
-- (SD): para QUALQUER terno de vértices (4 x 3 x 4 = 48, alcançáveis ou não) e qualquer cenário,
-- aplicar a UMA máquina os sinais de todos os ticks (`cremRunFrom`) dá os mesmos passos e o mesmo
-- terno final que reconstruir a máquina a cada tick só a partir do terno observado (`cremIterFrom`,
-- que é o que a exploração do grafo faz). Antes, `faithful` conferia isto só a partir do terno
-- inicial e contra o simulador de cenários.
--
-- Três partes:
--   1. exaustiva: os 48 ternos x todos os cenários de até 3 ticks (20 símbolos por tick);
--   2. Hedgehog: terno arbitrário e cenário de até 40 ticks (semente fixa, impressa);
--   3. controles negativos: duas versões deliberadamente erradas de `cremIterFrom` (terno fixo;
--      ambiente esquecido) têm de ser REPROVADAS pela mesma verificação, para provar que ela
--      consegue falhar.
-- ============================================================================
module Main (main) where

import Avionics.Sim.Scenario (Scenario, allTickInputs, sequencesUpTo)
import Control.Monad (unless)
import Data.List (foldl')
import Gen (genScenario)
import Hedgehog
import qualified Hedgehog.Gen as Gen
import qualified Hedgehog.Internal.Seed as Seed
import System.Environment (lookupEnv, setEnv)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Validation.Reach
import Validation.Types (StepSum)

allAbs :: [AbsState]
allAbs = [AbsState a p q | a <- [0 .. length avVs - 1], p <- [0 .. length pwVs - 1], q <- [0 .. length msVs - 1]]

sdHolds :: AbsState -> Scenario -> Bool
sdHolds s sc = cremRunFrom s sc == cremIterFrom s sc

-- | Controle negativo 1: reconstrói a máquina sempre no terno INICIAL do cenário (esquece o que o tick
-- anterior deixou). Tem de discordar de `cremRunFrom` em muitos casos.
brokenFixed :: AbsState -> Scenario -> (AbsState, [StepSum])
brokenFixed s0 = foldl' (\(_, acc) inp -> let (s', ss) = cremNext s0 inp in (s', acc ++ ss)) (s0, [])

-- | Controle negativo 2: carrega o terno, mas esquece o ambiente (volta a Standby a cada tick).
brokenMission :: AbsState -> Scenario -> (AbsState, [StepSum])
brokenMission s0 = foldl' (\(s, acc) inp -> let (s', ss) = cremNext s inp in (s' {asMs = 0}, acc ++ ss)) (s0, [])

propSD :: Property
propSD = withTests 5000 . property $ do
  s <- forAll (Gen.element allAbs)
  sc <- forAll (genScenario 40)
  cremRunFrom s sc === cremIterFrom s sc

fixedSeed :: IO String
fixedSeed = do
  existing <- lookupEnv "HEDGEHOG_SEED"
  case existing of
    Just v -> pure v
    Nothing -> do
      let Seed.Seed v g = Seed.from 20261114
          str = show v ++ " " ++ show g
      setEnv "HEDGEHOG_SEED" str
      pure str

main :: IO ()
main = do
  hSetEncoding stdout utf8
  seed <- fixedSeed
  putStrLn ("Semente do Hedgehog (HEDGEHOG_SEED): " ++ seed)
  let scs = sequencesUpTo 3 allTickInputs
      nCases = length allAbs * length scs
      bad = [(s, sc) | s <- allAbs, sc <- scs, not (sdHolds s sc)]
      okFixed = length [() | s <- allAbs, sc <- scs, cremRunFrom s sc /= brokenFixed s sc]
      okMission = length [() | s <- allAbs, sc <- scs, cremRunFrom s sc /= brokenMission s sc]
  putStrLn ("=== (SD) exaustiva: " ++ show (length allAbs) ++ " ternos x " ++ show (length scs) ++ " cenários de até 3 ticks = " ++ show nCases ++ " casos ===")
  putStrLn ("  casos em que (SD) falha: " ++ show (length bad))
  mapM_ (\(s, sc) -> putStrLn ("    contraexemplo: " ++ prettyAbs s ++ " com " ++ show (length sc) ++ " ticks")) (take 5 bad)
  putStrLn ("  controle negativo 1 (terno fixo)      : a verificação discorda em " ++ show okFixed ++ " casos")
  putStrLn ("  controle negativo 2 (ambiente esquecido): a verificação discorda em " ++ show okMission ++ " casos")
  okH <- check propSD
  let ok = null bad && okFixed > 0 && okMission > 0 && okH
  putStrLn (if ok then "\n(SD) VALE nos 48 ternos (exaustivo até 3 ticks; 5000 cenários aleatórios de até 40 ticks); os controles negativos reprovam." else "\nFALHA")
  unless ok exitFailure
