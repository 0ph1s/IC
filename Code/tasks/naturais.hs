-- NATURAIS DE PEANO

data Nat = Zero | Succ Nat
  deriving (Show, Eq)

-- Succ (Succ (Succ Zero))

-- Conversão de Nat para Int
natToInt :: Nat -> Int
natToInt Zero = 0
natToInt (Succ n) = 1 + natToInt n

-- Conversão de Int para Nat (usando Maybe para tratar erro)
intToNat :: Int -> Maybe Nat
intToNat n
  | n < 0 = Nothing  -- Não existe natural negativo
  | n == 0 = Just Zero
  | otherwise = fmap Succ (intToNat (n - 1))

-- Soma: definição indutiva
-- add Zero n = n                    (caso base)
-- add (Succ m) n = Succ (add m n)   (caso indutivo)
add :: Nat -> Nat -> Nat
add Zero n = n
add (Succ m) n = Succ (add m n)

-- Multiplicação: definição indutiva
-- mult Zero n = Zero
-- mult (Succ m) n = add n (mult m n)
mult :: Nat -> Nat -> Nat
mult Zero _ = Zero
mult (Succ m) n = add n (mult m n)

-- Subtração segura (pode falhar se resultado for negativo)
safeSub :: Nat -> Nat -> Maybe Nat
safeSub n Zero = Just n
safeSub Zero (Succ _) = Nothing  -- Não há prova de número negativo
safeSub (Succ m) (Succ n) = safeSub m n

-- Exponenciação
power :: Nat -> Nat -> Nat
power _ Zero = Succ Zero  -- n^0 = 1
power base (Succ exp) = mult base (power base exp)

-- Comparações
lessThan :: Nat -> Nat -> Bool
lessThan _ Zero = False
lessThan Zero (Succ _) = True
lessThan (Succ m) (Succ n) = lessThan m n

equal :: Nat -> Nat -> Bool
equal Zero Zero = True
equal (Succ m) (Succ n) = equal m n
equal _ _ = False

-- Alguns números úteis
zero, one, two, three, four, five :: Nat
zero = Zero
one = Succ Zero
two = Succ one
three = Succ two
four = Succ three
five = Succ four

-- ===========================================
-- UTILITÁRIOS DE ENTRADA
-- ===========================================

-- Lê um número natural do usuário
readNat :: String -> IO (Maybe Nat)
readNat prompt = do
  putStr prompt
  input <- getLine
  case reads input :: [(Int, String)] of
    [(n, "")] -> return (intToNat n)
    _ -> do
      putStrLn "Entrada inválida! Digite um número inteiro."
      readNat prompt

-- Lê um natural garantido (repete até conseguir)
readNatSafe :: String -> IO Nat
readNatSafe prompt = do
  maybeNat <- readNat prompt
  case maybeNat of
    Just n -> return n
    Nothing -> do
      putStrLn "Número deve ser não-negativo!"
      readNatSafe prompt

-- ===========================================
-- DEMONSTRAÇÕES E TESTES
-- ===========================================

main :: IO ()
main = do
  putStrLn "=== NATURAIS DE PEANO - CALCULADORA INTERATIVA ==="
  putStrLn "\nDefinição indutiva:"
  putStrLn "  Zero :: Nat"
  putStrLn "  Succ :: Nat -> Nat"
  
  putStrLn "\n--- Exemplos pré-definidos ---"
  putStrLn $ "zero = " ++ show zero
  putStrLn $ "three = " ++ show three
  putStrLn $ "natToInt three = " ++ show (natToInt three)
  
  putStrLn "\n--- CALCULADORA INTERATIVA ---"
  
  -- Adição
  putStrLn "\n[ADIÇÃO]"
  a <- readNatSafe "Digite o primeiro número: "
  b <- readNatSafe "Digite o segundo número: "
  let soma = add a b
  putStrLn $ "Resultado: " ++ show (natToInt a) ++ " + " ++ show (natToInt b) ++ " = " ++ show (natToInt soma)
  putStrLn $ "Representação interna: " ++ show soma
  
  -- Multiplicação
  putStrLn "\n[MULTIPLICAÇÃO]"
  c <- readNatSafe "Digite o primeiro número: "
  d <- readNatSafe "Digite o segundo número: "
  let produto = mult c d
  putStrLn $ "Resultado: " ++ show (natToInt c) ++ " * " ++ show (natToInt d) ++ " = " ++ show (natToInt produto)
  
  -- Subtração segura
  putStrLn "\n[SUBTRAÇÃO SEGURA]"
  e <- readNatSafe "Digite o minuendo: "
  f <- readNatSafe "Digite o subtraendo: "
  case safeSub e f of
    Just resultado -> putStrLn $ "Resultado: " ++ show (natToInt e) ++ " - " ++ show (natToInt f) ++ " = " ++ show (natToInt resultado)
    Nothing -> putStrLn $ "Resultado: " ++ show (natToInt e) ++ " - " ++ show (natToInt f) ++ " = indefinido (seria negativo)"
  
  -- Exponenciação
  putStrLn "\n[EXPONENCIAÇÃO]"
  base <- readNatSafe "Digite a base: "
  expoente <- readNatSafe "Digite o expoente: "
  let potencia = power base expoente
  putStrLn $ "Resultado: " ++ show (natToInt base) ++ "^" ++ show (natToInt expoente) ++ " = " ++ show (natToInt potencia)
  
  -- Comparações
  putStrLn "\n[COMPARAÇÕES]"
  g <- readNatSafe "Digite o primeiro número: "
  h <- readNatSafe "Digite o segundo número: "
  putStrLn $ show (natToInt g) ++ " < " ++ show (natToInt h) ++ " = " ++ show (lessThan g h)
  putStrLn $ show (natToInt g) ++ " == " ++ show (natToInt h) ++ " = " ++ show (equal g h)
  
  putStrLn "\n=== FIM ==="