-- ============================================================================
-- CONFORMIDADE EXAUSTIVA com a tabela de transições revisável (spec/*.csv).
-- Rodar (na pasta validation/):   cabal test validation-conformance-tests
--
-- Parecer de 03/11/2026, nível 2: "tabela de transições e de políticas ... derivada dos
-- requisitos documentados em vez de copiar o código". As tabelas CSV são confrontadas com
-- quatro artefatos que antes eram comparados só entre si:
--   (A) a AÇÃO do CREM (avionicsAction / powerAction): destino e saída, lidos do ActionResult;
--   (B) a FSM ingênua (Avionics.Naive): transition e outputOf;
--   (C) a TOPOLOGIA do CREM (o valor avionicsTopology / powerTopology);
--   (D) as regras do domínio do pacote base (spec/domain_rules.txt), como conferência cruzada.
-- O domínio é finito (4 x 4 e 3 x 3 pares), então tudo é EXAUSTIVO.
-- Também se verifica que o próprio validador de tabelas consegue falhar.
-- ============================================================================
module Main (main) where

import Avionics.Crem
import qualified Avionics.Naive as N
import Avionics.Power
import Control.Monad (unless)
import Crem.BaseMachine (ActionResult (..))
import Crem.Topology (Topology (..))
import Data.Functor.Identity (Identity (..))
import Data.List (nub, sort)
import Data.Singletons (fromSing)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Validation.Table
import Validation.Types

check :: String -> Bool -> IO Bool
check name ok = do
  putStrLn ((if ok then "  [ok]    " else "  [FALHA] ") ++ name)
  pure ok

-- | Estado da aviônica -> singleton do CREM, sem tabela de tradução própria.
withSing :: N.AvState -> (forall v. SAvionicsVertex v -> r) -> r
withSing N.Grounded k = k SGrounded
withSing N.InFlight k = k SInFlight
withSing N.EmergencyLanding k = k SEmergencyLanding
withSing N.Shutdown k = k SShutdown

withSingPw :: Pw -> (forall v. SPowerVertex v -> r) -> r
withSingPw PwCharged k = k SCharged
withSingPw PwLow k = k SLow
withSingPw PwCritical k = k SCritical

-- | Destino (nome do vértice) e saída que a AÇÃO do CREM devolve.
cremAv :: N.AvState -> AvEvent -> (String, Output)
cremAv q e = withSing q $ \s -> case avionicsAction s e of
  ActionResult (Identity (o, s')) -> (show (fromSing s'), o)

cremPw :: Pw -> PowerEvent -> (String, PowerReport)
cremPw p e = withSingPw p $ \s -> case powerAction s e of
  ActionResult (Identity (r, s')) -> (show (fromSing s'), r)

-- | Pares (origem, destino) de uma topologia, como texto, sem repetição.
topoPairs :: Show v => Topology v -> [(String, String)]
topoPairs t = nub [(show a, show b) | (a, bs) <- edges t, b <- bs]

main :: IO ()
main = do
  hSetEncoding stdout utf8
  avTxt <- readUtf8 "spec/transition_table.csv"
  pwTxt <- readUtf8 "spec/power_table.csv"
  baseRules <- readUtf8 "../base/avionics-crem/spec/domain_rules.txt"
  let parsedAv = parseAvionicsTable avTxt
      parsedPw = parsePowerTable pwTxt
  case (parsedAv, parsedPw) of
    (Left e, _) -> putStrLn ("ERRO ao ler transition_table.csv: " ++ renderTableError e) >> exitFailure
    (_, Left e) -> putStrLn ("ERRO ao ler power_table.csv: " ++ renderTableError e) >> exitFailure
    (Right avRows, Right pwRows) -> do
      let avPairs = [(q, e) | q <- [minBound .. maxBound :: N.AvState], e <- [minBound .. maxBound :: AvEvent]]
          pwPairs = [(p, e) | p <- allPw, e <- [Drain, Recharge, ShedLoad]]
          reqRows = [r | r <- avRows, avOrigin r == Req]
          convRows = [r | r <- avRows, avOrigin r == Conv]
          row q e = [r | r <- avRows, avFrom r == q, avEvent r == e]
          pwRow p e = [r | r <- pwRows, pwFrom r == p, pwEvent r == e]
          -- regras do pacote base: "allow A B E"
          baseAllow = sort [(a, b, e) | ["allow", a, b, e] <- map words (lines baseRules)]
          tableReq = sort [(show (avFrom r), show (avTo r), show (avEvent r)) | r <- reqRows]
      putStrLn "=== 0. As tabelas lidas ==="
      s0 <-
        sequence
          [ check ("aviônica: " ++ show (length avRows) ++ " linhas (esperado 16), " ++ show (length reqRows) ++ " REQ e " ++ show (length convRows) ++ " CONV") (length avRows == 16 && length reqRows == 4 && length convRows == 12)
          , check "aviônica: função total e determinística (uma linha por par estado x evento)" (null (wellFormedAv avRows))
          , check ("energia: " ++ show (length pwRows) ++ " linhas (esperado 9), todas MODEL") (length pwRows == 9 && all ((== Model) . pwOrigin) pwRows)
          , check "energia: função total e determinística (uma linha por par estado x evento)" (null (wellFormedPw pwRows))
          ]
      putStrLn "\n=== (A) ação do CREM x tabela (16 + 9 pares: destino e saída/relato) ==="
      sA <-
        sequence
          [ check "avionicsAction: destino igual ao da tabela nos 16 pares"
              (and [fst (cremAv q e) == show (avTo r) | (q, e) <- avPairs, r <- row q e])
          , check "avionicsAction: saída igual à da tabela nos 16 pares"
              (and [snd (cremAv q e) == avOut r | (q, e) <- avPairs, r <- row q e])
          , check "powerAction: destino igual ao da tabela nos 9 pares"
              (and [fst (cremPw p e) == pwName (pwTo r) | (p, e) <- pwPairs, r <- pwRow p e])
          , check "powerAction: relato igual ao da tabela nos 9 pares"
              (and [snd (cremPw p e) == pwReport r | (p, e) <- pwPairs, r <- pwRow p e])
          ]
      putStrLn "\n=== (B) FSM ingênua x tabela (16 pares) ==="
      sB <-
        sequence
          [ check "transition: destino igual ao da tabela" (and [N.transition q e == avTo r | (q, e) <- avPairs, r <- row q e])
          , check "outputOf: saída igual à da tabela" (and [N.outputOf q e == avOut r | (q, e) <- avPairs, r <- row q e])
          ]
      putStrLn "\n=== (C) topologia do CREM x arestas da tabela ==="
      let tableAvEdges = nub [(show a, show b) | (a, b) <- avEdges avRows]
          tablePwEdges = nub [(pwName a, pwName b) | (a, b) <- pwEdges pwRows]
      sC <-
        sequence
          [ check ("arestas da aviônica: topologia == tabela (" ++ show (length tableAvEdges) ++ " arestas fora a identidade)")
              (sort (topoPairs avionicsTopology) == sort tableAvEdges)
          , check "InFlight -> Shutdown não é aresta da tabela nem da topologia (proibição explícita dos requisitos)"
              (("InFlight", "Shutdown") `notElem` tableAvEdges && ("InFlight", "Shutdown") `notElem` topoPairs avionicsTopology)
          , check ("arestas da energia: topologia == tabela (" ++ show (length tablePwEdges) ++ " arestas fora a identidade)")
              (sort (topoPairs powerTopology) == sort tablePwEdges)
          ]
      putStrLn "\n=== (D) conferência cruzada com spec/domain_rules.txt do pacote base ==="
      sD <-
        sequence
          [ check "as 4 linhas REQ da tabela == as 4 regras `allow` do pacote base (origem, destino, evento)" (tableReq == baseAllow)
          ]
      putStrLn "\n=== (E) o validador de tabelas consegue falhar (tabelas corrompidas à mão) ==="
      let missing = drop 1 avRows
          duplicated = head avRows : avRows
          badName = parseAvionicsTable "Grounded,Takeoff,InFlight,MsgTakeoff,REQ\n"
          badCols = parseAvionicsTable "Grounded,TakeoffSignal,InFlight\n"
          badPw = parsePowerTable "Charged,Drain,Medium,ReportLow,MODEL\n"
      sE <-
        sequence
          [ check "linha ausente é detectada (par sem linha)" (not (null (wellFormedAv missing)))
          , check "linha repetida é detectada (par com duas linhas)" (not (null (wellFormedAv duplicated)))
          , check "nome de evento desconhecido é recusado na leitura" (either (const True) (const False) badName)
          , check "número de colunas errado é recusado na leitura" (either (const True) (const False) badCols)
          , check "nível de bateria desconhecido é recusado na leitura" (either (const True) (const False) badPw)
          , check "mkTables recusa tabela mal formada" (either (const True) (const False) (mkTables missing pwRows))
          ]
      let results = concat [s0, sA, sB, sC, sD, sE]
          failed = length (filter not results)
      putStrLn ("\n" ++ show (length results) ++ " verificações, " ++ show failed ++ " falhas.")
      unless (failed == 0) exitFailure
