-- ============================================================================
-- EXPORTA O GRAFO ALCANÇÁVEL E OS TRAÇOS DA IMPLEMENTAÇÃO (CREM) — tarefas T21, T14 e T12 do plano v2.
-- Rodar (na pasta validation/):   cabal run validation-export -- <pasta de saída>
--
--   T21  grafo_ternos.csv, grafo_arestas.csv: os ternos alcançáveis e as arestas da exploração;
--   T14  cegueira medida a CADA SINAL (definição do TLA+: aviônica InFlight e bateria Critical em
--        cada passo), e não só no fim do tick; resumo em cegueira_por_sinal.txt;
--   T12  TraceData.tla + tracos.csv: traços da IMPLEMENTAÇÃO (um passo por sinal) para o TLC validar
--        contra AvionicsLoop.tla (ver 04_tla/TraceCheck.tla e o script run_trace_validation.sh).
--
-- Codificação de um passo: 100*aviônica + 10*bateria + ambiente (índices de avVs, pwVs, msVs).
-- Um tick: <<comando (0 = nenhum, 1..4 = TakeoffSignal, CriticalBattery, LandedSignal, SystemCutoff),
--            evento de energia (0 = nenhum, 1..3 = Drain, Recharge, ShedLoad),
--            <<passos do tick>>>>.
-- Os passos vêm de `cremNext`, iterado a partir do terno inicial. Pela (SD) (validation-sd-tests), a
-- concatenação coincide com a de uma máquina única rodando o cenário inteiro; a fronteira entre ticks
-- só é conhecida na forma iterada.
-- ============================================================================
module Main (main) where

import Avionics.Sim.Scenario (Scenario, TickInput (..), allAvEvents, allPowerEvents, allTickInputs)
import Data.List (elemIndex, intercalate)
import qualified Data.Map.Strict as M
import qualified Data.Set as S
import Data.Maybe (fromMaybe)
import System.Directory (createDirectoryIfMissing)
import System.Environment (getArgs)
import System.FilePath ((</>))
import System.IO (IOMode (WriteMode), hPutStrLn, hSetEncoding, stdout, utf8, withFile)
import Validation.Reach
import Validation.Types

stepCode :: StepSum -> Int
stepCode s = 100 * fromEnum (ssAv s) + 10 * fromEnum (ssPw s) + fromMaybe 9 (lookup (ssMission s) [(show v, i) | (i, v) <- zip [0 ..] msVs])

tickCode :: TickInput -> (Int, Int)
tickCode t = (maybe 0 ((+ 1) . fromMaybe 9 . flip elemIndex allAvEvents) (tiCommand t), maybe 0 ((+ 1) . fromMaybe 9 . flip elemIndex allPowerEvents) (tiPower t))

-- | Um cenário a partir do terno inicial: por tick, a entrada codificada e os passos da implementação.
runTicks :: AbsState -> Scenario -> [((Int, Int), [Int])]
runTicks _ [] = []
runTicks s (i : is) = let (s', ss) = cremNext s i in (tickCode i, map stepCode ss) : runTicks s' is

tlaTrace :: [((Int, Int), [Int])] -> String
tlaTrace ts = "<< " ++ intercalate ",\n   " [ "<<" ++ show c ++ "," ++ show p ++ ", <<" ++ intercalate "," (map show ss) ++ ">>>>" | ((c, p), ss) <- ts ] ++ " >>"

-- | Gerador congruencial (semente fixa): independente do Hedgehog, para os cenários longos serem
-- reproduzíveis sem depender da versão da biblioteca.
lcg :: Int -> Int
lcg x = (1103515245 * x + 12345) `mod` 2147483648

randomScenario :: Int -> Int -> Scenario
randomScenario seed len = go seed len
  where
    go _ 0 = []
    go x n = let x' = lcg x in (allTickInputs !! ((x' `div` 65536) `mod` length allTickInputs)) : go x' (n - 1)

blindStep :: StepSum -> Bool
blindStep s = fromEnum (ssAv s) == 1 && ssPw s == PwCritical

main :: IO ()
main = do
  hSetEncoding stdout utf8
  [out] <- getArgs
  createDirectoryIfMissing True out
  let g = explore cremTS
      ins = tsInputs cremTS
      states = M.keys (gDepth g)
      depthOf s = M.findWithDefault 0 s (gDepth g)
      blindEnd s = asAv s == 1 && asPw s == 2
      idleIx = fromMaybe 0 (elemIndex idle0 allTickInputs)
      idle0 = TickInput Nothing Nothing
      -- T14: cegueira por sinal. Uma aresta é "cega o tempo todo" se TODOS os passos do tick são cegos.
      allBlindEdge o = not (null o) && all blindStep o
      successors = M.fromListWith (++) [(s, [t]) | (s, _, t, o) <- gEdges g, allBlindEdge o]
      fixp cur =
        let next = S.filter (\s -> any (`S.member` cur) (M.findWithDefault [] s successors)) cur
         in if S.size next == S.size cur then cur else fixp next
      foreverPerSignal = S.toList (fixp (S.fromList (filter blindEnd states)))
      foreverEnd = foreverBad blindEnd g
      edgesWithBlindStep = length [() | (_, _, _, o) <- gEdges g, any blindStep o]
      edgesAllBlind = length [() | (_, _, _, o) <- gEdges g, allBlindEdge o]
      midOnly = length [() | (_, _, t, o) <- gEdges g, any blindStep o, not (blindEnd t)]
      trappedIdle = trapped idleIx blindEnd g
  -- T21: grafo
  withFile (out </> "grafo_ternos.csv") WriteMode $ \h -> do
    hSetEncoding h utf8
    hPutStrLn h "aviônica,bateria,ambiente,profundidade,cego_no_fim_do_tick,preso_sob_ticks_ociosos,cego_para_sempre_fim_do_tick,cego_para_sempre_por_sinal,pai_aviônica,pai_bateria,pai_ambiente,entrada_do_pai_comando,entrada_do_pai_energia"
    mapM_
      ( \s ->
          let parentCols = case M.lookup s (gParent g) of
                Nothing -> ["-", "-", "-", "-", "-"]
                Just (p, i) -> [show (avVs !! asAv p), show (pwVs !! asPw p), show (msVs !! asMs p), maybe "-" show (tiCommand (ins !! i)), maybe "-" show (tiPower (ins !! i))]
           in hPutStrLn h $ intercalate "," ([show (avVs !! asAv s), show (pwVs !! asPw s), show (msVs !! asMs s), show (depthOf s), yn (blindEnd s), yn (s `elem` trappedIdle), yn (s `elem` foreverEnd), yn (s `elem` foreverPerSignal)] ++ parentCols)
      )
      states
  withFile (out </> "grafo_arestas.csv") WriteMode $ \h -> do
    hSetEncoding h utf8
    hPutStrLn h "origem_aviônica,origem_bateria,origem_ambiente,comando,energia,destino_aviônica,destino_bateria,destino_ambiente,passos,passos_cegos"
    mapM_
      ( \(s, i, t, o) ->
          let ti = ins !! i
           in hPutStrLn h $ intercalate "," [show (avVs !! asAv s), show (pwVs !! asPw s), show (msVs !! asMs s), maybe "-" show (tiCommand ti), maybe "-" show (tiPower ti), show (avVs !! asAv t), show (pwVs !! asPw t), show (msVs !! asMs t), show (length o), show (length (filter blindStep o))]
      )
      (gEdges g)
  -- T14: resumo
  withFile (out </> "cegueira_por_sinal.txt") WriteMode $ \h -> do
    hSetEncoding h utf8
    let l = hPutStrLn h
    l ("ternos alcançáveis: " ++ show (length states) ++ "; arestas: " ++ show (length (gEdges g)))
    l ("ternos cegos no FIM do tick (aviônica InFlight e bateria Critical): " ++ show (length (filter blindEnd states)))
    l ("arestas com pelo menos um passo cego: " ++ show edgesWithBlindStep)
    l ("arestas com TODOS os passos cegos: " ++ show edgesAllBlind)
    l ("arestas com passo cego e destino NÃO cego no fim do tick (cegueira só no meio do tick): " ++ show midOnly)
    l ("cego para sempre, definição por fim de tick (foreverBad)   : " ++ show (length foreverEnd) ++ " " ++ show (map prettyAbs foreverEnd))
    l ("cego para sempre, definição por sinal (TLA+: toda a cauda)  : " ++ show (length foreverPerSignal) ++ " " ++ show (map prettyAbs foreverPerSignal))
    l ("as duas definições coincidem: " ++ show (foreverEnd == foreverPerSignal))
    l ("presos sob ticks ociosos (fim de tick): " ++ show (length trappedIdle) ++ " " ++ show (map prettyAbs trappedIdle))
  -- T12: traços
  let edgeTraces =
        [ ("E" ++ pad3 k, "aresta", runTicks (AbsState 0 0 0) (pathTo cremTS g s ++ [ins !! i]))
        | (k, (s, i, _, _)) <- zip [1 :: Int ..] (gEdges g)
        ]
      randTraces = [("R" ++ pad3 k, "aleatorio30", runTicks (AbsState 0 0 0) (randomScenario (20261118 + k) 30)) | k <- [1 .. 500]]
      corrupt (name, _, tr) =
        let (c, ss) = last tr
            lastStep = last ss
            bad = ((lastStep `div` 100 + 1) `mod` 4) * 100 + lastStep `mod` 100
         in ("C" ++ drop 1 name, "corrompido", init tr ++ [(c, init ss ++ [bad])])
      corrupted = map corrupt (take 100 edgeTraces)
      allTraces = edgeTraces ++ randTraces ++ corrupted
  withFile (out </> "TraceData.tla") WriteMode $ \h -> do
    hSetEncoding h utf8
    hPutStrLn h "---- MODULE TraceData ----"
    hPutStrLn h "\\* Gerado por validation-export (ExportTraces.hs). Não editar à mão."
    hPutStrLn h "EXTENDS Naturals, Sequences"
    hPutStrLn h ("Traces == <<\n  " ++ intercalate ",\n  " (map (\(_, _, t) -> tlaTrace t) allTraces) ++ "\n>>")
    hPutStrLn h "===="
  withFile (out </> "tracos.csv") WriteMode $ \h -> do
    hSetEncoding h utf8
    hPutStrLn h "indice,nome,tipo,ticks,passos"
    mapM_ (\(k, (n, ty, t)) -> hPutStrLn h (intercalate "," [show k, n, ty, show (length t), show (sum (map (length . snd) t))])) (zip [1 :: Int ..] allTraces)
  putStrLn ("ternos: " ++ show (length states) ++ ", arestas: " ++ show (length (gEdges g)) ++ ", traços: " ++ show (length allTraces) ++ " (" ++ show (length edgeTraces) ++ " de aresta, " ++ show (length randTraces) ++ " aleatórios de 30 ticks, " ++ show (length corrupted) ++ " corrompidos)")
  where
    yn b = if b then "sim" else "nao"
    pad3 k = let s = show k in replicate (3 - length s) '0' ++ s
