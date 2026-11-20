-- ============================================================================
-- AMOSTRAGEM CONTRA FECHAMENTO (T16) E ENUMERAÇÃO LIMITADA POR PROFUNDIDADE (T17) — plano v2.
-- Rodar (na pasta validation/, por causa de spec/*.csv):   cabal run validation-sampling
--
-- O grafo alcançável é finito (26 ternos, 520 arestas); logo as probabilidades de um teste aleatório de
-- L ticks encontrar a lacuna são CALCULÁVEIS EXATAMENTE por programação dinâmica sobre o grafo, e não só
-- estimáveis por sorteio. Duas distribuições de tick:
--   uniforme : os 20 ticks possíveis, cada um com 1/20;
--   genTick  : a do gerador Hedgehog do projeto (test/Gen.hs): sem comando 3/5, cada um dos 4 comandos
--              1/10; sem energia 3/5, cada um dos 3 eventos 2/15.
-- Duas lacunas:
--   cegueira : a implementação termina o cenário num terno de que, só com ticks ociosos, nunca se sai
--              da cegueira (aviônica InFlight e bateria Critical) — o achado do TLC;
--   divergência OneSlot x Queue : alguma aresta do produto (implementação, oráculo Queue) em que os
--              passos diferem — o que um teste baseado em modelo contra o oráculo Queue acusaria.
-- Confere o cálculo exato com sorteio (gerador congruencial de semente fixa).
-- ============================================================================
module Main (main) where

import Avionics.Sim.Scenario (TickInput (..), allAvEvents, allPowerEvents, allTickInputs)
import Data.List (elemIndex, foldl')
import qualified Data.Map.Strict as M
import Data.Maybe (fromMaybe)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Text.Printf (printf)
import Validation.Reach
import Validation.RefModel ()
import Validation.Table
import Validation.Types

-- pesos dos 20 ticks, na ordem de allTickInputs
uniformW :: [Double]
uniformW = replicate (length allTickInputs) (1 / fromIntegral (length allTickInputs))

genTickW :: [Double]
genTickW = [wc c * wp p | TickInput c p <- allTickInputs]
  where
    wc Nothing = 3 / 5
    wc (Just _) = 2 / 5 / fromIntegral (length allAvEvents)
    wp Nothing = 3 / 5
    wp (Just _) = 2 / 5 / fromIntegral (length allPowerEvents)

-- | Distribuição do estado depois de L ticks (e massa já "absorvida" em `done`, se for o caso).
-- `absorb` marca, para cada aresta, se ela leva a massa ao conjunto absorvente (divergência).
stepDist :: Ord s => [(s, Int, s, Bool)] -> [Double] -> M.Map s Double -> (M.Map s Double, Double)
stepDist edges w d = (M.fromListWith (+) [(t, p * (w !! i)) | (s, i, t, ab) <- edges, not ab, Just p <- [M.lookup s d]], sum [p * (w !! i) | (s, i, _, ab) <- edges, ab, Just p <- [M.lookup s d]])

main :: IO ()
main = do
  hSetEncoding stdout utf8
  etables <- loadTables "spec/transition_table.csv" "spec/power_table.csv"
  tables <- either (\e -> putStrLn (renderTableError e) >> exitFailure) pure etables
  let g = explore cremTS
      edgesC = [(s, i, t, False) | (s, i, t, _) <- gEdges g]
      idleIx = fromMaybe 0 (elemIndex (TickInput Nothing Nothing) allTickInputs)
      trappedS = trapped idleIx (\s -> asAv s == 1 && asPw s == 2) g
      blindS = [s | s <- M.keys (gDepth g), asAv s == 1 && asPw s == 2]
      dist0 = M.singleton (tsStart cremTS) (1 :: Double)
      distsAt w = iterate (fst . stepDist edgesC w) dist0
      pIn set w l = sum [M.findWithDefault 0 s (distsAt w !! l) | s <- set]
      -- divergência com o oráculo Queue: arestas do produto em que os passos diferem
      prod = productTS cremTS (refTS tables Queue)
      gP = explore prod
      -- contra o oráculo Queue compara-se só o que a planta e o comando veem (o conteúdo do ambiente difere por construção)
      proj = map (\x -> x {ssMission = ""})
      edgesP = [(s, i, t, proj o1 /= proj o2) | (s, i, t, (o1, o2)) <- gEdges gP]
      pDiv w l = snd (foldl' (\(d, acc) _ -> let (d', a) = stepDist edgesP w d in (d', acc + a)) (M.singleton (tsStart prod) (1 :: Double), 0) [1 .. l])
      -- OneSlot x Level (a correção): idem
      prodL = productTS cremTS (refTS tables Level)
      gPL = explore prodL
      edgesPL = [(s, i, t, o1 /= o2) | (s, i, t, (o1, o2)) <- gEdges gPL]
      pDivL w l = snd (foldl' (\(d, acc) _ -> let (d', a) = stepDist edgesPL w d in (d', acc + a)) (M.singleton (tsStart prodL) (1 :: Double), 0) [1 .. l])
      lens = [1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 60]
      row l = (l, pIn trappedS uniformW l, pIn trappedS genTickW l, pIn blindS genTickW l, pDiv uniformW l, pDiv genTickW l, pDivL genTickW l)
  putStrLn "## T16 — probabilidade EXATA de um teste aleatório de L ticks achar a lacuna"
  putStrLn ""
  putStrLn ("Estados presos sob ticks ociosos: " ++ show (map prettyAbs trappedS) ++ "; cegos no fim do tick: " ++ show (map prettyAbs blindS))
  putStrLn ("Pares do produto implementação x Queue: " ++ show (M.size (gDepth gP)) ++ "; implementação x Level: " ++ show (M.size (gDepth gPL)))
  putStrLn ""
  putStrLn "| L | cegueira (uniforme) | cegueira (genTick) | testes esperados (genTick) | cego no fim (genTick) | divergência OneSlot x Queue (uniforme) | idem (genTick) | divergência impl. x Level (genTick) |"
  putStrLn "|---|---|---|---|---|---|---|---|"
  mapM_
    ( \l -> do
        let (_, a, b, c, d, e, f) = row l
        printf "| %d | %.6f | %.6f | %s | %.6f | %.6f | %.6f | %.6f |\n" l a b (if b > 0 then printf "%.0f" (1 / b) else "---" :: String) c d e f
    )
    lens
  putStrLn ""
  putStrLn "## T17 — enumeração exaustiva até a profundidade d (todas as 20^d sequências de d ticks)"
  putStrLn ""
  putStrLn "| d | sequências de d ticks | terminam em estado preso | fração | sequências com divergência impl. x Level até d | fração |"
  putStrLn "|---|---|---|---|---|---|"
  let cnt0 = M.singleton (tsStart cremTS) (1 :: Integer)
      cntStep d = M.fromListWith (+) [(t, c) | (s, _, t, _) <- gEdges g, Just c <- [M.lookup s d]]
      cnts = iterate cntStep cnt0
      -- divergência: contagem de sequências de d ticks que contêm alguma aresta divergente
      cntDiv d = go d (M.singleton (tsStart prodL) (1 :: Integer)) 0
        where
          go 0 _ acc = acc
          go k m acc =
            let divE = sum [c * 1 | (s, _, _, ab) <- edgesPL, ab, Just c <- [M.lookup s m]]
                nxt = M.fromListWith (+) [(t, c) | (s, _, t, ab) <- edgesPL, not ab, Just c <- [M.lookup s m]]
                -- sequências já divergentes viram 20^(restante) completações
             in go (k - 1) nxt (acc + divE * 20 ^ (k - 1))
  mapM_
    ( \d -> do
        let total = 20 ^ d :: Integer
            tr = sum [M.findWithDefault 0 s (cnts !! d) | s <- trappedS]
            dv = cntDiv d
        printf "| %d | %d | %d | %.6f | %d | %.6f |\n" d total tr (fromIntegral tr / fromIntegral total :: Double) dv (fromIntegral dv / fromIntegral total :: Double)
    )
    [1 .. 8 :: Int]
  putStrLn ""
  -- conferência por sorteio (gerador congruencial de semente fixa), distribuição genTick
  let lcg x = (1103515245 * x + 12345) `mod` 2147483648 :: Int
      draw w x = let x' = lcg x; u = fromIntegral (x' `div` 8) / 268435456 :: Double in (pick w u 0 0, x')
      pick (p : ps) u i acc = if u < acc + p || null ps then i else pick ps u (i + 1 :: Int) (acc + p)
      pick [] _ i _ = i
      runOne seed l = go (tsStart cremTS) seed l
        where
          go s _ 0 = s
          go s x k = let (i, x') = draw genTickW x; (s', _) = tsNext cremTS s (allTickInputs !! i) in go s' x' (k - 1 :: Int)
      nS = 200000 :: Int
      sample l = length [() | k <- [1 .. nS], runOne (20261118 + 7919 * k) l `elem` trappedS]
  putStrLn "## Conferência por sorteio (200 000 cenários, genTick, gerador congruencial, semente 20261118 + 7919k)"
  putStrLn ""
  putStrLn "| L | exato | sorteado |"
  putStrLn "|---|---|---|"
  mapM_ (\l -> printf "| %d | %.6f | %.6f |\n" l (pIn trappedS genTickW l) (fromIntegral (sample l) / fromIntegral nS :: Double)) [4, 8, 16, 32 :: Int]
