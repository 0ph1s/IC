-- ============================================================================
-- TESTES DE CONTRATO DA FRONTEIRA (parecer de 03/11/2026, seção 4)
-- Rodar (na pasta validation/):   cabal test validation-boundary-tests
--
-- Contrato do adaptador: texto externo -> Either BoundaryError (ADTs) -> FSM em CREM.
--   1. todo token do vocabulário vira exatamente um construtor, e o ida-e-volta é a identidade;
--   2. qualquer outra coisa vira `Left`, nunca exceção;
--   3. erros de cenário carregam o número da linha;
--   4. o caminho completo (arquivo .scn -> CREM) reproduz os resultados esperados.
--
-- Estes testes NÃO afirmam que o evento escolhido leva ao destino correto: isso é a suíte de
-- conformidade (spec/*.csv) e o modelo de referência.
-- ============================================================================
module Main (main) where

import Avionics.Crem (AvEvent (..), AvionicsVertex (..), Output (..))
import Avionics.Power (PowerEvent (..), PowerVertex (..))
import Avionics.Sim.Scenario (TickInput (..), idle)
import Avionics.Sim.Trace (finalAvVertex, finalPowVertex, significantOutputs)
import Control.Exception (SomeException, evaluate, try)
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Validation.Boundary
import Validation.Table (readUtf8)

check :: String -> Bool -> IO Bool
check name ok = do
  putStrLn ((if ok then "  [ok]    " else "  [FALHA] ") ++ name)
  pure ok

allEvents :: [AvEvent]
allEvents = [minBound .. maxBound]

allPower :: [PowerEvent]
allPower = [Drain, Recharge, ShedLoad]

-- | Cadeias que um gerador externo malicioso ou descuidado poderia mandar.
garbage :: [String]
garbage =
  [ ""
  , " "
  , "takeoff"
  , "Takeoff"
  , "TakeoffSignal"
  , "TAKEOFF;"
  , "TAKEOFF,DRAIN"
  , "42"
  , "\0"
  , "TAKE OFF"
  , "ÇÃO"
  , "idle"
  , replicate 10000 'X'
  ]

-- | A avaliação não pode lançar exceção.
total :: Show a => a -> IO Bool
total x = do
  r <- try (evaluate (length (show x))) :: IO (Either SomeException Int)
  pure (either (const False) (const True) r)

main :: IO ()
main = do
  hSetEncoding stdout utf8
  putStrLn "=== 1. Vocabulário e ida-e-volta ==="
  s1 <-
    sequence
      [ check "decodeEvent . encodeEvent == Right nos 4 eventos de comando" (all (\e -> decodeEvent (encodeEvent e) == Right e) allEvents)
      , check "decodePowerEvent . encodePowerEvent == Right nos 3 eventos de energia" (all (\e -> decodePowerEvent (encodePowerEvent e) == Right e) allPower)
      , check "os 4 tokens de comando são distintos (a codificação é injetiva)" (length (nubOrd (map encodeEvent allEvents)) == 4)
      , check "exemplo do parecer: TAKEOFF -> TakeoffSignal, CRITICAL -> CriticalBattery, LANDED -> LandedSignal, CUTOFF -> SystemCutoff"
          (map decodeEvent ["TAKEOFF", "CRITICAL", "LANDED", "CUTOFF"] == map Right [TakeoffSignal, CriticalBattery, LandedSignal, SystemCutoff])
      , check "evento desconhecido vira Left (UnknownToken), como no exemplo do parecer" (decodeEvent "EXPLODE" == Left (UnknownToken "EXPLODE"))
      ]
  putStrLn "\n=== 2. Entrada arbitrária nunca lança exceção ==="
  s2 <-
    sequence
      [ check ("decodeEvent total sobre " ++ show (length garbage) ++ " cadeias hostis") . and =<< mapM (total . decodeEvent) garbage
      , check "decodeEvent recusa toda cadeia hostil acima" (all (either (const True) (const False) . decodeEvent) garbage)
      , check "decodeScenario total sobre as mesmas cadeias" . and =<< mapM (total . decodeScenario) garbage
      ]
  putStrLn "\n=== 3. Cenários: formato, comentários, erros com número de linha ==="
  let scn1 = "# comentário\nTAKEOFF  # decola\n\nDRAIN\nTAKEOFF DRAIN\nIDLE\n"
  s3 <-
    sequence
      [ check "comentários, linhas em branco e espaços extras são ignorados"
          (decodeScenario scn1 == Right [TickInput (Just TakeoffSignal) Nothing, TickInput Nothing (Just Drain), TickInput (Just TakeoffSignal) (Just Drain), idle])
      , check "fim de linha do Windows (CRLF) é aceito" (decodeScenario "TAKEOFF\r\nDRAIN\r\n" == Right [TickInput (Just TakeoffSignal) Nothing, TickInput Nothing (Just Drain)])
      , check "cenário vazio é um cenário válido de zero ticks" (decodeScenario "" == Right [] && decodeScenario "# só comentário\n" == Right [])
      , check "palavra desconhecida acusa a LINHA certa" (decodeScenario "TAKEOFF\nDRAIN\nFLY\n" == Left (AtLine 3 (UnknownToken "FLY")))
      , check "dois comandos no mesmo tick são recusados" (decodeScenario "TAKEOFF CUTOFF\n" == Left (AtLine 1 (AmbiguousTick ["TAKEOFF", "CUTOFF"])))
      , check "dois eventos de energia no mesmo tick são recusados" (decodeScenario "DRAIN RECHARGE\n" == Left (AtLine 1 (AmbiguousTick ["DRAIN", "RECHARGE"])))
      , check "IDLE misturado com outra palavra é recusado" (decodeScenario "IDLE DRAIN\n" == Left (AtLine 1 (AmbiguousTick ["IDLE", "DRAIN"])))
      , check "minúsculas são recusadas (decodificação estrita)" (decodeScenario "takeoff\n" == Left (AtLine 1 (UnknownToken "takeoff")))
      , check "encodeScenario . decodeScenario preserva a lista de ticks"
          (fmap (decodeScenario . encodeScenario) (decodeScenario scn1) == Right (decodeScenario scn1))
      ]
  putStrLn "\n=== 4. Caminho completo: arquivo .scn -> ADTs -> CREM ==="
  regr <- readUtf8 "scenarios/regressao_bateria_critica.scn"
  emer <- readUtf8 "scenarios/nominal_emergencia.scn"
  let run txt = either (const Nothing) Just (runExternalScenario txt)
  s4 <-
    sequence
      [ check "regressão (Drain, Drain, TakeoffSignal, Idle, Idle) em CREM: termina com aviônica InFlight e bateria Critical (política do projeto)"
          (fmap (\t -> (finalAvVertex t, finalPowVertex t)) (run regr) == Just (InFlight, Critical))
      , check "regressão em CREM: única saída significativa é MsgTakeoff (ninguém levou a aviônica à emergência)"
          (fmap significantOutputs (run regr) == Just [MsgTakeoff])
      , check "emergência (TAKEOFF, DRAIN, DRAIN, 3 ociosos): saídas [MsgTakeoff, MsgEmergency, MsgLanded, MsgShutdown], estado final Shutdown"
          (fmap significantOutputs (run emer) == Just [MsgTakeoff, MsgEmergency, MsgLanded, MsgShutdown] && fmap finalAvVertex (run emer) == Just Shutdown)
      , check "cenário inválido nunca chega ao CREM (devolve Left)" (either (const True) (const False) (runExternalScenario "TAKEOFF\nBOOM\n"))
      ]
  let results = concat [s1, s2, s3, s4]
      failed = length (filter not results)
  putStrLn ("\n" ++ show (length results) ++ " verificações, " ++ show failed ++ " falhas.")
  unless (failed == 0) exitFailure
  where
    nubOrd :: Eq a => [a] -> [a]
    nubOrd = foldr (\x acc -> x : filter (/= x) acc) []
