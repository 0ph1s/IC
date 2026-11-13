-- ============================================================================
-- TABELAS DE TRANSIÇÃO COMO DADOS (spec/transition_table.csv e spec/power_table.csv)
-- ----------------------------------------------------------------------------
-- O arquivo CSV é o artefato que a orientação revisa. Este módulo o lê, confere se
-- ele está BEM FORMADO (uma e só uma linha por par, todos os nomes conhecidos) e o
-- transforma em funções totais usadas pelo oráculo (Validation.RefModel) e pelos
-- testes de conformidade.
--
-- Nada aqui chama `Avionics.Naive.transition` nem `avionicsAction`.
-- ============================================================================
module Validation.Table
  ( Origin (..)
  , AvRow (..)
  , PwRow (..)
  , Tables (..)
  , TableError (..)
  , renderTableError
  , parseAvionicsTable
  , parsePowerTable
  , mkTables
  , loadTables
  , readUtf8
  , wellFormedAv
  , wellFormedPw
  , avEdges
  , pwEdges
  , allOutputs
  , allReports
  ) where

import Avionics.Crem (AvEvent, Output (..))
import qualified Avionics.Naive as N
import Avionics.Power (PowerEvent (..), PowerReport (..))
import Data.Char (isSpace)
import Data.List (dropWhileEnd, find, nub)
import System.IO (IOMode (ReadMode), hGetContents, hSetEncoding, utf8, withFile)
import Validation.Types

-- | De onde vem a regra de uma linha (ver o cabeçalho dos CSV).
data Origin = Req | Conv | Model
  deriving (Show, Eq)

data AvRow = AvRow
  { avFrom :: N.AvState
  , avEvent :: AvEvent
  , avTo :: N.AvState
  , avOut :: Output
  , avOrigin :: Origin
  }
  deriving (Show, Eq)

data PwRow = PwRow
  { pwFrom :: Pw
  , pwEvent :: PowerEvent
  , pwTo :: Pw
  , pwReport :: PowerReport
  , pwOrigin :: Origin
  }
  deriving (Show, Eq)

-- | As duas tabelas, já validadas, e as funções totais que elas definem.
data Tables = Tables
  { tAvRows :: [AvRow]
  , tPwRows :: [PwRow]
  , tAv :: N.AvState -> AvEvent -> (N.AvState, Output)
  , tPw :: Pw -> PowerEvent -> (Pw, PowerReport)
  }

data TableError
  = BadRow Int String
  -- ^ linha do CSV com número de colunas errado
  | UnknownName Int String String
  -- ^ (linha, coluna, valor) que não é nome conhecido
  | Malformed [String]
  -- ^ tabela que não é uma função total: pares ausentes ou repetidos
  deriving (Show, Eq)

renderTableError :: TableError -> String
renderTableError (BadRow n l) = "linha " ++ show n ++ ": número de colunas errado: " ++ show l
renderTableError (UnknownName n col v) = "linha " ++ show n ++ ": " ++ col ++ " desconhecido: " ++ show v
renderTableError (Malformed ms) = "tabela mal formada: " ++ unwords ms

allOutputs :: [Output]
allOutputs = [MsgTakeoff, MsgEmergency, MsgLanded, MsgShutdown, MsgIgnored]

allReports :: [PowerReport]
allReports = [ReportOk, ReportLow, ReportCritical]

allPowerEv :: [PowerEvent]
allPowerEv = [Drain, Recharge, ShedLoad]

-- ----------------------------------------------------------------------------
-- Leitura
-- ----------------------------------------------------------------------------

trim :: String -> String
trim = dropWhileEnd isSpace . dropWhile isSpace

splitOnComma :: String -> [String]
splitOnComma s = case break (== ',') s of
  (a, []) -> [a]
  (a, _ : rest) -> a : splitOnComma rest

-- | Linhas de dados (número, colunas), sem comentários (`#`) nem linhas em branco.
dataRows :: String -> [(Int, [String])]
dataRows txt =
  [ (n, map trim (splitOnComma l))
  | (n, raw) <- zip [1 ..] (lines txt)
  , let l = trim raw
  , not (null l)
  , take 1 l /= "#"
  ]

byShow :: Show a => [a] -> String -> Maybe a
byShow xs s = find ((== s) . show) xs

parseOrigin :: String -> Maybe Origin
parseOrigin "REQ" = Just Req
parseOrigin "CONV" = Just Conv
parseOrigin "MODEL" = Just Model
parseOrigin _ = Nothing

named :: Int -> String -> Maybe a -> String -> Either TableError a
named n col m v = maybe (Left (UnknownName n col v)) Right m

parseAvionicsTable :: String -> Either TableError [AvRow]
parseAvionicsTable = traverse row . dataRows
  where
    row (n, [f, e, t, o, g]) =
      AvRow
        <$> named n "estado" (byShow [minBound .. maxBound] f) f
        <*> named n "evento" (byShow [minBound .. maxBound] e) e
        <*> named n "destino" (byShow [minBound .. maxBound] t) t
        <*> named n "saida" (byShow allOutputs o) o
        <*> named n "origem" (parseOrigin g) g
    row (n, cols) = Left (BadRow n (show cols))

parsePowerTable :: String -> Either TableError [PwRow]
parsePowerTable = traverse row . dataRows
  where
    pwByName = (\p -> (pwName p, p)) <$> allPw
    pw n col v = named n col (lookup v pwByName) v
    row (n, [f, e, t, r, g]) =
      PwRow
        <$> pw n "estado" f
        <*> named n "evento" (byShow allPowerEv e) e
        <*> pw n "destino" t
        <*> named n "relato" (byShow allReports r) r
        <*> named n "origem" (parseOrigin g) g
    row (n, cols) = Left (BadRow n (show cols))

-- ----------------------------------------------------------------------------
-- Boa formação: a tabela tem de ser uma função TOTAL e DETERMINÍSTICA
-- ----------------------------------------------------------------------------

-- | Violações (lista vazia = bem formada): cada par (estado, evento) deve ter exatamente uma linha.
wellFormedAv :: [AvRow] -> [String]
wellFormedAv rows =
  [ show q ++ "+" ++ show e ++ ": " ++ show k ++ " linhas (esperado 1)"
  | q <- [minBound .. maxBound :: N.AvState]
  , e <- [minBound .. maxBound :: AvEvent]
  , let k = length [() | r <- rows, avFrom r == q, avEvent r == e]
  , k /= 1
  ]

wellFormedPw :: [PwRow] -> [String]
wellFormedPw rows =
  [ pwName p ++ "+" ++ show e ++ ": " ++ show k ++ " linhas (esperado 1)"
  | p <- allPw
  , e <- allPowerEv
  , let k = length [() | r <- rows, pwFrom r == p, pwEvent r == e]
  , k /= 1
  ]

-- | Arestas entre estados DIFERENTES (a identidade é sempre permitida pelo CREM e não conta).
avEdges :: [AvRow] -> [(N.AvState, N.AvState)]
avEdges rows = nub [(avFrom r, avTo r) | r <- rows, avFrom r /= avTo r]

pwEdges :: [PwRow] -> [(Pw, Pw)]
pwEdges rows = nub [(pwFrom r, pwTo r) | r <- rows, pwFrom r /= pwTo r]

-- | Constrói as funções totais, recusando tabela mal formada.
mkTables :: [AvRow] -> [PwRow] -> Either TableError Tables
mkTables av pw = case wellFormedAv av ++ wellFormedPw pw of
  (v : vs) -> Left (Malformed (v : vs))
  [] -> Right Tables {tAvRows = av, tPwRows = pw, tAv = stepAv, tPw = stepPw}
  where
    -- `error` é inalcançável: a boa formação acima garante uma linha por par.
    stepAv q e = case [(avTo r, avOut r) | r <- av, avFrom r == q, avEvent r == e] of
      (x : _) -> x
      [] -> error "Validation.Table: tabela da aviônica validada, mas sem linha"
    stepPw p e = case [(pwTo r, pwReport r) | r <- pw, pwFrom r == p, pwEvent r == e] of
      (x : _) -> x
      [] -> error "Validation.Table: tabela de energia validada, mas sem linha"

-- | Lê um arquivo como UTF-8, qualquer que seja a codificação local (no Windows ela costuma
-- ser cp1252, e os comentários dos CSV têm acentos).
readUtf8 :: FilePath -> IO String
readUtf8 path = withFile path ReadMode $ \h -> do
  hSetEncoding h utf8
  s <- hGetContents h
  length s `seq` pure s

-- | Lê os dois arquivos (caminhos relativos ao diretório de trabalho) e valida.
loadTables :: FilePath -> FilePath -> IO (Either TableError Tables)
loadTables avPath pwPath = do
  avTxt <- readUtf8 avPath
  pwTxt <- readUtf8 pwPath
  pure (do av <- parseAvionicsTable avTxt; pw <- parsePowerTable pwTxt; mkTables av pw)
