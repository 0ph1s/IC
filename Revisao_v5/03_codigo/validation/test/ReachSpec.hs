-- ============================================================================
-- ALCANÇABILIDADE EXAUSTIVA DO LAÇO FECHADO — para TODAS as sequências, de qualquer comprimento.
-- Rodar (na pasta validation/):   cabal test validation-reach-tests
--
-- Parecer de 03/11/2026, nível 2: verificação de propriedades globais do laço (segurança da
-- topologia, composição, progresso/terminação, política da bateria). O parecer sugere TLA+/TLC;
-- esta suíte faz o equivalente sobre o PRÓPRIO CREM (e sobre o oráculo), em Haskell. A
-- especificação TLA+ (04_tla/) foi executada no TLC e confere: os mesmos 26 ternos (04_tla/cross_check.py).
--
-- Resultados rotulados "[ok]" são verificações que devem valer (código de saída); os rotulados
-- "[achado]" são MEDIDAS do comportamento do modelo. "[regressão do achado]" falha se o achado
-- deixar de se reproduzir (por exemplo, se a Mission for alterada): a documentação precisaria mudar.
-- ============================================================================
module Main (main) where

import Avionics.Sim.Scenario (allTickInputs, idle, sequencesUpTo)
import Control.Monad (unless)
import Data.List (elemIndex, minimumBy, sort)
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)
import Data.Ord (comparing)
import qualified Avionics.Naive as N
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Validation.Boundary (encodeScenario)
import Validation.Reach
import Validation.RefModel
import Validation.Table
import Validation.Types

check :: String -> Bool -> IO Bool
check name ok = do
  putStrLn ((if ok then "  [ok]    " else "  [FALHA] ") ++ name)
  pure ok

main :: IO ()
main = do
  hSetEncoding stdout utf8
  etables <- loadTables "spec/transition_table.csv" "spec/power_table.csv"
  tables <- either (\e -> putStrLn (renderTableError e) >> exitFailure) pure etables
  let gC = explore cremTS
      refG pol = explore (refTS tables pol)
      gOne = refG OneSlot
      gQ = refG Queue
      gL = refG Level
      idleIx = fromMaybe 0 (elemIndex idle allTickInputs)
      nStates g = M.size (gDepth g)
      nEdges g = length (gEdges g)
      badC s = asAv s == fromEnum N.InFlight && asPw s == fromEnum PwCritical
      trappedC = trapped idleIx badC gC
      trappedOne = trapped idleIx stuckInFlight gOne
      trappedQ = trapped idleIx stuckInFlight gQ
      trappedL = trapped idleIx stuckInFlight gL
      violC = [(prettyAbs s, v) | (s, _, _, o) <- gEdges gC, v <- avSeqViolations (toEnum (asAv s)) o]
      violL = [v | (s, _, _, o) <- gEdges gL, v <- avSeqViolations (rAv s) o]
      violQ = [v | (s, _, _, o) <- gEdges gQ, v <- avSeqViolations (rAv s) o]
      statesC = M.keys (gDepth gC)
      statesOne = sort (map absOfRef (M.keys (gDepth gOne)))
      shortest = case trappedC of
        [] -> Nothing
        ss -> Just (minimumBy (comparing (\s -> M.findWithDefault 0 s (gDepth gC))) ss)
  putStrLn ("=== Espaço de estados do laço fechado: 4 x 3 x 4 = 48 ternos possíveis, alfabeto de " ++ show (length allTickInputs) ++ " ticks ===")
  putStrLn ("  [medida] implementação (CREM): " ++ show (nStates gC) ++ " ternos alcançáveis, " ++ show (nEdges gC) ++ " arestas")
  putStrLn ("  [medida] oráculo OneSlot     : " ++ show (nStates gOne) ++ " estados, " ++ show (nEdges gOne) ++ " arestas")
  putStrLn ("  [medida] oráculo Queue       : " ++ show (nStates gQ) ++ " estados, " ++ show (nEdges gQ) ++ " arestas")
  putStrLn ("  [medida] oráculo Level       : " ++ show (nStates gL) ++ " estados, " ++ show (nEdges gL) ++ " arestas")
  -- lista dos ternos alcançáveis da implementação, para conferir com o TLC (04_tla, dump dos estados com fila vazia)
  putStrLn "  [lista]  ternos alcançáveis (aviônica, energia, ambiente) da implementação:"
  mapM_ (putStrLn . ("             " ++) . prettyAbs) statesC
  putStrLn "\n=== 1. A abstração (terno de vértices) é fiel ao simulador de cenários ==="
  let scenarios = sequencesUpTo 3 allTickInputs
  s1 <-
    sequence
      [ check ("iterar cremNext == simulateClosed (terno final e todos os passos) em " ++ show (length scenarios) ++ " cenários de até 3 ticks")
          (all faithful scenarios)
      ]
  putStrLn "\n=== 2. Segurança da topologia, para TODAS as arestas do grafo (qualquer comprimento) ==="
  s2 <-
    sequence
      [ check ("CREM: nenhum passo viola 'InFlight -> Shutdown', 'Shutdown só de Grounded', 'EmergencyLanding só de InFlight' em " ++ show (nEdges gC) ++ " arestas") (null violC)
      , check "oráculo (Queue e Level): idem" (null violL && null violQ)
      ]
  mapM_ (\(s, v) -> putStrLn ("            violação em " ++ s ++ ": " ++ v)) (take 3 violC)
  putStrLn "\n=== 3. Equivalência implementação x oráculo (política do projeto), para TODAS as sequências ==="
  s3 <-
    sequence
      [ check "mesmos estados alcançáveis" (statesC == statesOne)
      , check "mesmas arestas, com os mesmos passos (evento, saída, vértices e ambiente) em cada aresta"
          (edgeMap id gC == edgeMap absOfRef gOne)
      ]
  putStrLn "\n=== 4. Composição e terminação: a realimentação para dentro de cada tick? ==="
  s4 <-
    sequence
      -- A terminação em si é mostrada pela exploração ter fechado (uma realimentação sem fim travaria o
      -- programa, não devolveria False). O que se CONFERE aqui é o limite: Beat + até duas liberações do
      -- ambiente (TouchdownHeld libera ShedLoad e LandedSignal) + comando + energia = 5 passos.
      [ check ("a exploração fechou (" ++ show (nStates gC * length allTickInputs) ++ " combinações (estado, tick)) e nenhum tick passa de 5 passos (máximo observado: " ++ show (maxCascade gC) ++ ")") (maxCascade gC <= 5)
      , check "limite de passos por tick igual no oráculo OneSlot" (maxCascade gC == maxCascade gOne)
      ]
  putStrLn "\n=== 5. Política da bateria: reação à BORDA (OneSlot) versus ao NÍVEL (Level) ==="
  putStrLn ("  [achado] OneSlot (CREM): " ++ show (length trappedC) ++ " estado(s) alcançável(is) com aviônica InFlight e bateria Critical de que, só com ticks ociosos, nunca se sai")
  mapM_ (\s -> putStrLn ("           " ++ prettyAbs s ++ ", a " ++ show (M.findWithDefault 0 s (gDepth gC)) ++ " tick(s) do início")) trappedC
  mapM_
    ( \s -> do
        putStrLn ("           menor caminho até " ++ prettyAbs s ++ (if Just s == shortest then " [o mais curto]" else "") ++ " (formato da fronteira; depois, ticks ociosos à vontade):")
        putStr (unlines (map ("             " ++) (lines (encodeScenario (pathTo cremTS gC s)))))
    )
    trappedC
  let foreverC = foreverBad badC gC
      foreverQ = foreverBad stuckInFlight gQ
      foreverL = foreverBad stuckInFlight gL
  putStrLn ("  [achado] caminho infinito, com QUAISQUER entradas, sempre cego (NoPermanentBlindness do TLA+): OneSlot " ++ show (length foreverC) ++ " estado(s), Queue " ++ show (length foreverQ) ++ ", Level " ++ show (length foreverL))
  putStrLn ("  [achado] Queue  (oráculo): " ++ show (length trappedQ) ++ " estado(s) nessa situação (a fila sem perda não resolve a lacuna)")
  putStrLn ("  [achado] Level  (oráculo): " ++ show (length trappedL) ++ " estado(s) nessa situação")
  s5 <-
    sequence
      [ check "[regressão do achado] OneSlot: existe ao menos um estado preso (a lacuna borda x nível do relatório v4 se reproduz)" (not (null trappedC))
      , check "OneSlot: o oráculo e a implementação têm os MESMOS estados presos" (sort trappedC == sort (map absOfRef trappedOne))
      , check "Level elimina a lacuna: nenhum estado preso, para TODAS as sequências (não só até N = 8)" (null trappedL)
      , check "[regressão do achado] OneSlot viola NoPermanentBlindness (existe caminho infinito sempre cego) — o que o TLC deve mostrar com Policy = OneSlot" (not (null foreverC))
      , check "Level satisfaz NoPermanentBlindness: nenhum caminho infinito, com quaisquer entradas, fica cego para sempre — o que o TLC deve confirmar com Policy = Level" (null foreverL)
      ]
  putStrLn "\n=== 6. Descarte do slot: o relatório v4 mediu Queue x OneSlot só com alfabeto reduzido (4 ticks) e N = 8 ==="
  let prodQ = productTS (refTS tables OneSlot) (refTS tables Queue)
      gProd = explore prodQ
      project r = (rAv r, rPw r)
      differ (a, b) = project a /= project b
      diffStates = [p | p <- M.keys (gDepth gProd), differ p]
      nearest = case diffStates of
        [] -> Nothing
        ps -> Just (minimumBy (comparing (\p -> M.findWithDefault 0 p (gDepth gProd))) ps)
  putStrLn ("  [medida] produto OneSlot x Queue: " ++ show (nStates gProd) ++ " pares alcançáveis, alfabeto completo de " ++ show (length allTickInputs) ++ " ticks")
  putStrLn ("  [achado] pares alcançáveis em que (aviônica, energia) DIFEREM entre OneSlot e Queue ao fim de um tick: " ++ show (length diffStates))
  case nearest of
    Nothing -> pure ()
    Just p -> do
      putStrLn ("           menor caminho até um par que difere (a " ++ show (M.findWithDefault 0 p (gDepth gProd)) ++ " tick(s)):")
      putStr (unlines (map ("             " ++) (lines (encodeScenario (pathTo prodQ gProd p)))))
      putStrLn ("           OneSlot: " ++ show (project (fst p)) ++ "   Queue: " ++ show (project (snd p)))

  -- menor cenário em que a IMPLEMENTAÇÃO diverge, passo a passo, do oráculo Level (o mínimo GLOBAL;
  -- o shrinking do Hedgehog só garante um mínimo local, ver 03_model_hedgehog.txt)
  let prodL = productTS cremTS (refTS tables Level)
      gPL = explore prodL
      divEdges = [(M.findWithDefault 0 st (gDepth gPL), st, i) | (st, i, _, (o1, o2)) <- gEdges gPL, o1 /= o2]
  case divEdges of
    [] -> putStrLn "  [achado] a implementação não diverge do oráculo Level em nenhuma aresta"
    ds -> do
      let (d, st, i) = minimumBy (comparing (\(k, _, _) -> k)) ds
          path = pathTo prodL gPL st ++ [tsInputs prodL !! i]
      putStrLn ("  [achado] menor cenário em que o CREM (OneSlot) diverge, passo a passo, do oráculo Level: " ++ show (d + 1) ++ " ticks")
      putStr (unlines (map ("             " ++) (lines (encodeScenario path))))

  let results = concat [s1, s2, s3, s4, s5]
      failed = length (filter not results)
  putStrLn ("\n" ++ show (length results) ++ " verificações, " ++ show failed ++ " falhas.")
  unless (failed == 0) exitFailure
