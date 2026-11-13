-- ============================================================================
-- TESTES BASEADOS EM MODELO (Hedgehog) — parecer de 03/11/2026, nível 3.
-- Rodar (na pasta validation/):   cabal test validation-model-tests
--
-- Por que Hedgehog e não QuickCheck State Machine: ver 07_estado-da-arte/FERRAMENTAS.md. Em resumo,
-- Hedgehog tem menos dependências e a FSM é pura (uma Mealy sem referências simbólicas): a propriedade
-- "para toda lista de ticks, o traço do CREM coincide com o do oráculo" é o teste baseado em modelo.
-- A API de máquinas de estado do Hedgehog (Command/Var) não foi usada porque aqui não há estado
-- opaco a ser referenciado entre comandos.
--
-- O que se obtém além da enumeração: cenários de comprimento até 60 (a enumeração original parava
-- em 4), geradores reprodutíveis e shrinking (o contraexemplo encolhe até um mínimo LOCAL: nenhuma
-- redução de um passo ainda falha; não é necessariamente o menor cenário que falha).
--
-- SEMENTE FIXA (`fixedSeed`): sem ela, cada execução sorteia outra semente e os tamanhos dos
-- contraexemplos reduzidos mudam de um log para outro. Uma HEDGEHOG_SEED definida de fora tem
-- precedência, para explorar outras sementes; a semente usada é impressa no início do log.
--
-- Propriedades marcadas "(falha esperada)" são MUTANTES: a propriedade deve ser REPROVADA, e a
-- reprovação, com o contraexemplo já reduzido, é o que prova que o teste consegue falhar.
-- ============================================================================
module Main (main) where

import Avionics.Crem (AvEvent (..), Output (..))
import qualified Avionics.Naive as N
import Avionics.Sim.Properties
import Avionics.Sim.Scenario (Scenario, TickInput (..), defaultInit)
import Avionics.Sim.Simulate (simulateClosed)
import Control.Monad (unless)
import Gen
import Hedgehog
import qualified Hedgehog.Internal.Seed as Seed
import System.Environment (lookupEnv, setEnv)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stdout, utf8)
import Validation.Boundary
import Validation.Compare
import Validation.RefModel
import Validation.Table
import Validation.Types

-- | Oráculo da malha ABERTA, direto das tabelas: cada tick é um passo em que o comando e a
-- energia se aplicam às suas máquinas (a energia não influencia a aviônica sem o ambiente).
openOracle :: Tables -> Scenario -> [StepSum]
openOracle t = go 0 N.Grounded PwCharged
  where
    go _ _ _ [] = []
    go n av pw (TickInput c p : rest) =
      let (av', o) = case c of
            Just e -> let (q, out) = tAv t av e in (q, Just out)
            Nothing -> (av, Nothing)
          pw' = maybe pw (fst . tPw t pw) p
       in StepSum n c p o av' pw' "-" : go (n + 1) av' pw' rest

-- | Aplica um defeito a TODAS as linhas da aviônica (o defeito decide em quais mexer).
mutateAv :: (AvRow -> AvRow) -> Tables -> Tables
mutateAv f t = case mkTables (map f (tAvRows t)) (tPwRows t) of
  Right t' -> t'
  Left e -> error ("mutante inválido: " ++ renderTableError e)

-- ----------------------------------------------------------------------------
-- Propriedades que devem valer
-- ----------------------------------------------------------------------------

-- | CREM (malha fechada, política do projeto) == oráculo OneSlot, passo a passo.
propClosedLoop :: Tables -> Property
propClosedLoop t = withTests 5000 . property $ do
  sc <- forAll (genScenario 40)
  compareSteps (cremSteps sc) (refSteps t OneSlot sc) === Nothing

-- | CREM (malha aberta) == tabelas, passo a passo.
propOpenLoop :: Tables -> Property
propOpenLoop t = withTests 3000 . property $ do
  sc <- forAll (genScenario 40)
  compareSteps (cremOpenSteps sc) (openOracle t sc) === Nothing

-- | As propriedades de traço do pacote base, agora sobre cenários de até 60 ticks.
propTraceProperties :: Property
propTraceProperties = withTests 3000 . property $ do
  sc <- forAll (genScenario 60)
  let tr = simulateClosed sc defaultInit
  assert (shutdownOnlyAfterGrounded tr)
  assert (emergencyOnlyFromInFlight tr)
  assert (shedLoadNeverDrains tr)
  assert (releasesMatchRetention tr)

-- | Level (só no modelo): terminar com 2 ticks ociosos, aviônica em voo e bateria Critical não ocorre.
propLevelNeverStuck :: Tables -> Property
propLevelNeverStuck t = withTests 5000 . property $ do
  sc <- forAll (genScenario 40)
  let (end, _) = refRun t Level (sc ++ [TickInput Nothing Nothing, TickInput Nothing Nothing])
  assert (not (stuckInFlight end))

-- | Fronteira: ida-e-volta.
propRoundTrip :: Property
propRoundTrip = withTests 3000 . property $ do
  sc <- forAll (genScenario 30)
  decodeScenario (encodeScenario sc) === Right sc

-- | Fronteira: texto arbitrário nunca lança exceção, e o que for aceito é re-codificável.
propBoundaryTotal :: Property
propBoundaryTotal = withTests 5000 . property $ do
  txt <- forAll genWireText
  case decodeScenario txt of
    Left _ -> success
    Right sc -> decodeScenario (encodeScenario sc) === Right sc

-- | Fronteira: decodificação ESTRITA. Se uma palavra é aceita, ela é exatamente a codificação canônica.
propStrict :: Property
propStrict = withTests 5000 . property $ do
  w <- forAll genWireWord
  case decodeEvent w of
    Right e -> encodeEvent e === w
    Left _ -> success

-- ----------------------------------------------------------------------------
-- Mutantes: a propriedade de equivalência deve ser REPROVADA
-- ----------------------------------------------------------------------------

-- | Equivalência CREM x tabela (possivelmente com defeito), malha fechada.
equivWith :: Tables -> Property
equivWith t = withTests 3000 . property $ do
  sc <- forAll (genScenario 40)
  compareSteps (cremSteps sc) (refSteps t OneSlot sc) === Nothing

-- | Equivalência CREM x oráculo de OUTRA política (Level), que o CREM não implementa.
equivLevel :: Tables -> Property
equivLevel t = withTests 3000 . property $ do
  sc <- forAll (genScenario 40)
  compareSteps (cremSteps sc) (refSteps t Level sc) === Nothing

-- ----------------------------------------------------------------------------
-- Regressão prioritária: Drain, Drain, TakeoffSignal, Idle, Idle
-- ----------------------------------------------------------------------------

regression :: Tables -> Scenario -> [IO Bool]
regression t sc =
  [ ok "regressão: CREM e oráculo OneSlot coincidem passo a passo" (compareSteps (cremSteps sc) (refSteps t OneSlot sc) == Nothing)
  , ok "regressão, OneSlot: termina com aviônica InFlight, bateria Critical e ambiente livre (a lacuna borda x nível)"
      (fst (refRun t OneSlot sc) == RefState N.InFlight PwCritical [])
  , ok "regressão, OneSlot: a única saída significativa é MsgTakeoff" (significantOutputsOf (refSteps t OneSlot sc) == [MsgTakeoff])
  , ok "regressão, Level: o ambiente reage ao NÍVEL; aviônica vai a EmergencyLanding e pousa; bateria alivia a Low"
      (fst (refRun t Level sc) == RefState N.Grounded PwLow [GCut])
  , ok "regressão, Level: saídas [MsgTakeoff, MsgEmergency, MsgLanded]" (significantOutputsOf (refSteps t Level sc) == [MsgTakeoff, MsgEmergency, MsgLanded])
  , ok "regressão: o CREM termina em InFlight (não em Grounded) — Level e CREM divergem" (finalAvOf (cremSteps sc) == N.InFlight && finalAvOf (refSteps t Level sc) == N.Grounded)
  ]

ok :: String -> Bool -> IO Bool
ok name b = do
  putStrLn ((if b then "  [ok]    " else "  [FALHA] ") ++ name)
  pure b

-- | Roda a propriedade e imprime o rótulo; o relatório do Hedgehog (com semente e contraexemplo
-- reduzido) aparece logo abaixo quando há falha.
run :: String -> Property -> IO Bool
run name p = do
  putStrLn ("  -- " ++ name)
  check p

-- | Mutante: passa se, e só se, a propriedade for reprovada.
runMutant :: String -> Property -> IO Bool
runMutant name p = do
  putStrLn ("  -- " ++ name ++ "   (falha esperada: o relatório abaixo É o contraexemplo reduzido)")
  failed <- not <$> check p
  putStrLn ((if failed then "  [ok]    mutante detectado: " else "  [FALHA] mutante NÃO detectado: ") ++ name)
  pure failed

-- | Fixa a semente de todas as propriedades (o `check` do Hedgehog lê HEDGEHOG_SEED a cada chamada).
-- Se HEDGEHOG_SEED já estiver definida, ela é mantida.
fixedSeed :: IO String
fixedSeed = do
  existing <- lookupEnv "HEDGEHOG_SEED"
  case existing of
    Just s -> pure s
    Nothing -> do
      let Seed.Seed v g = Seed.from 20261113
          s = show v ++ " " ++ show g
      setEnv "HEDGEHOG_SEED" s
      pure s

main :: IO ()
main = do
  hSetEncoding stdout utf8
  seed <- fixedSeed
  putStrLn ("Semente do Hedgehog (HEDGEHOG_SEED): " ++ seed)
  etables <- loadTables "spec/transition_table.csv" "spec/power_table.csv"
  tables <- either (\e -> putStrLn (renderTableError e) >> exitFailure) pure etables
  regrTxt <- readUtf8 "scenarios/regressao_bateria_critica.scn"
  regrSc <- either (\e -> putStrLn (renderBoundaryError e) >> exitFailure) pure (decodeScenario regrTxt)

  putStrLn "=== 1. Equivalência CREM x oráculo (tabelas), cenários de até 40 ticks ==="
  r1 <- sequence [run "malha fechada" (propClosedLoop tables), run "malha aberta" (propOpenLoop tables)]

  putStrLn "\n=== 2. Propriedades de traço do pacote base em cenários de até 60 ticks ==="
  r2 <- sequence [run "Shutdown só após Grounded; EmergencyLanding só de InFlight; ShedLoad nunca descarrega; atraso de um tick" propTraceProperties]

  putStrLn "\n=== 3. Política da bateria no modelo ==="
  r3 <- sequence [run "Level: nunca termina preso (InFlight, Critical) após 2 ticks ociosos" (propLevelNeverStuck tables)]

  putStrLn "\n=== 4. Fronteira tipada ==="
  r4 <- sequence [run "ida-e-volta decodeScenario . encodeScenario" propRoundTrip, run "texto arbitrário: total e re-codificável" propBoundaryTotal, run "decodificação estrita" propStrict]

  putStrLn "\n=== 5. Traço de regressão prioritário (scenarios/regressao_bateria_critica.scn) ==="
  r5 <- sequence (regression tables regrSc)

  putStrLn "\n=== 6. Mutantes (defeitos injetados; cada um deve ser detectado e reduzido pelo shrinking) ==="
  let swapDest r
        | avFrom r == N.Grounded && avEvent r == TakeoffSignal = r {avTo = N.Shutdown}
        | otherwise = r
      illegalEdge r
        | avFrom r == N.InFlight && avEvent r == SystemCutoff = r {avTo = N.Shutdown, avOut = MsgShutdown}
        | otherwise = r
      swappedEvents r
        | avFrom r == N.Grounded && avEvent r == TakeoffSignal = r {avTo = N.Shutdown, avOut = MsgShutdown}
        | avFrom r == N.Grounded && avEvent r == SystemCutoff = r {avTo = N.InFlight, avOut = MsgTakeoff}
        | otherwise = r
      wrongOutput r
        | avFrom r == N.EmergencyLanding && avEvent r == LandedSignal = r {avOut = MsgIgnored}
        | otherwise = r
  r6 <-
    sequence
      [ runMutant "M1 destino errado em aresta permitida (Grounded+TakeoffSignal -> Shutdown)" (equivWith (mutateAv swapDest tables))
      , runMutant "M2 aresta ilegal (InFlight+SystemCutoff -> Shutdown)" (equivWith (mutateAv illegalEdge tables))
      , runMutant "M3 eventos trocados (TakeoffSignal <-> SystemCutoff em Grounded)" (equivWith (mutateAv swappedEvents tables))
      , runMutant "M4 saída errada (EmergencyLanding+LandedSignal emite MsgIgnored)" (equivWith (mutateAv wrongOutput tables))
      , runMutant "M5 política do ambiente: CREM (OneSlot) contra o oráculo Level — reencontra a lacuna borda x nível, reduzida" (equivLevel tables)
      ]

  let results = concat [r1, r2, r3, r4, r5, r6]
      failed = length (filter not results)
  putStrLn ("\n" ++ show (length results) ++ " verificações, " ++ show failed ++ " falhas.")
  unless (failed == 0) exitFailure
