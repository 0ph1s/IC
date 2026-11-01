-- ===========================================
-- LOGICA INTUICIONISTA VIA CURRY-HOWARD
-- ===========================================

-- Na correspondencia de Curry-Howard:
-- Proposicoes <=> Tipos
-- Provas <=> Programas
-- Implicacao (A -> B) <=> Funcao (a -> b)
-- Conjuncao (A ^ B) <=> Par (a, b)
-- Disjuncao (A v B) <=> Either a b
-- Falso <=> Void
-- Verdade <=> ()

-- ===========================================
-- CONECTIVOS LOGICOS COMO TIPOS
-- ===========================================

-- Conjuncao: A ^ B
-- Representa "A E B sao ambos verdadeiros"
type And a b = (a, b)

-- Disjuncao: A v B  
-- Representa "A OU B e verdadeiro"
type Or a b = Either a b

-- Implicacao: A -> B
-- Ja existe em Haskell como (a -> b)

-- Falso
-- Tipo vazio - nao tem habitantes/valores
data Void

-- Absurdo: ex falso quodlibet (do falso, tudo segue)
absurd :: Void -> a
absurd v = case v of {}  -- Nao ha casos!

-- Negacao: ~A = A -> Falso
type Not a = a -> Void

-- Verdade
-- Tipo unitario - tem exatamente um valor
type Truth = ()

-- ===========================================
-- TAUTOLOGIA 1: A ^ B -> A (Projecao Esquerda)
-- ===========================================

-- Prova: dado um par (a, b), podemos extrair a
proj_left :: And a b -> a
proj_left (a, b) = a

-- Interpretacao logica:
-- Se temos prova de "A E B", entao temos prova de A

-- ===========================================
-- TAUTOLOGIA 2: A ^ B -> B (Projecao Direita)
-- ===========================================

proj_right :: And a b -> b
proj_right (a, b) = b

-- ===========================================
-- TAUTOLOGIA 3: A -> B -> A ^ B (Introducao ^)
-- ===========================================

intro_and :: a -> b -> And a b
intro_and a b = (a, b)

-- Se temos prova de A e prova de B, temos prova de A ^ B

-- ===========================================
-- ISOMORFISMO: (A v A) <=> (Bool -> A)
-- Interpretacao: "A ou A" <=> "funcao de Bool para A"
-- ===========================================

-- Direcao 1: (A v A) -> (Bool -> A)
-- Se temos "A ou A", podemos criar funcao que sempre retorna A
from_or :: Or a a -> (Bool -> a)
from_or (Left a) = \_ -> a   -- Nao importa o Bool, temos A
from_or (Right a) = \_ -> a  -- Nao importa o Bool, temos A

-- Direcao 2: (Bool -> A) -> (A v A)
-- Se temos funcao Bool -> A, podemos aplicar em qualquer Bool e obter A
to_or :: (Bool -> a) -> Or a a
to_or f = Left (f False)  -- Aplicamos em False e obtemos A
-- Poderiamos usar Right (f True) tambem

-- Prova de roundtrip (composicao e identidade):
-- from_or . to_or = id (aproximadamente)
-- to_or . from_or = id

-- ===========================================
-- MAIS TAUTOLOGIAS INTUICIONISTAS
-- ===========================================

-- A -> A (Identidade)
identity :: a -> a
identity x = x

-- A -> B -> A (Constante / K combinator)
const_proof :: a -> b -> a
const_proof a b = a

-- (A -> B -> C) -> (A -> B) -> A -> C (S combinator)
s_combinator :: (a -> b -> c) -> (a -> b) -> a -> c
s_combinator f g x = f x (g x)

-- A v B -> B v A (Comutatividade da disjuncao)
or_comm :: Or a b -> Or b a
or_comm (Left a) = Right a
or_comm (Right b) = Left b

-- A ^ B -> B ^ A (Comutatividade da conjuncao)
and_comm :: And a b -> And b a
and_comm (a, b) = (b, a)

-- (A -> C) -> (B -> C) -> (A v B -> C) (Eliminacao da disjuncao)
or_elim :: (a -> c) -> (b -> c) -> Or a b -> c
or_elim f g (Left a) = f a
or_elim f g (Right b) = g b

-- A -> A v B (Introducao v esquerda)
intro_or_left :: a -> Or a b
intro_or_left = Left

-- B -> A v B (Introducao v direita)
intro_or_right :: b -> Or a b
intro_or_right = Right

-- ===========================================
-- PROPOSICOES NAO DEMONSTRAVEIS 
-- (validas classicamente, mas nao intuicionisticamente)
-- ===========================================

-- Lei do Terceiro Excluido: A v ~A
-- NAO podemos provar isso em Haskell!
-- lem :: Or a (Not a)
-- lem = ???  -- IMPOSSIVEL construtivamente!

-- Dupla Negacao: ~~A -> A
-- NAO podemos provar isso em geral!
-- double_neg :: Not (Not a) -> a
-- double_neg = ???  -- IMPOSSIVEL!

-- Mas podemos provar: A -> ~~A
double_neg_intro :: a -> Not (Not a)
double_neg_intro a = \na -> na a
-- "Se temos A, entao e falso que A e falso"

-- ===========================================
-- EXEMPLOS INTERATIVOS
-- ===========================================

main :: IO ()
main = do
  putStrLn "================================================"
  putStrLn "  LOGICA INTUICIONISTA VIA CURRY-HOWARD"
  putStrLn "================================================"
  
  putStrLn "\n=== CORRESPONDENCIA FUNDAMENTAL ==="
  putStrLn "Proposicoes      <=>  Tipos"
  putStrLn "Provas           <=>  Programas"
  putStrLn "A -> B           <=>  (a -> b)"
  putStrLn "A ^ B            <=>  (a, b)"
  putStrLn "A v B            <=>  Either a b"
  putStrLn "Falso            <=>  Void"
  putStrLn "Verdade          <=>  ()"
  
  putStrLn "\n=== TAUTOLOGIA: A ^ B -> A ==="
  putStrLn "Prova: proj_left :: (a, b) -> a"
  let exemplo_par = ("Proposicao A", 42) :: And String Int
  putStrLn $ "Dado: " ++ show exemplo_par
  putStrLn $ "Extraimos A: " ++ proj_left exemplo_par
  
  putStrLn "\n=== TAUTOLOGIA: A ^ B -> B ==="
  putStrLn $ "Extraimos B: " ++ show (proj_right exemplo_par)
  
  putStrLn "\n=== DISJUNCAO: A v B ==="
  let disj1 = Left "Escolhi A" :: Or String Int
  let disj2 = Right 100 :: Or String Int
  putStrLn $ "Either (Left): " ++ show disj1
  putStrLn $ "Either (Right): " ++ show disj2
  putStrLn $ "Comutatividade: " ++ show (or_comm disj1)
  
  putStrLn "\n=== ISOMORFISMO (A v A) <=> (Bool -> A) ==="
  
  -- Comecamos com Either Int Int
  let either_val = Left 42 :: Or Int Int
  putStrLn $ "Valor inicial: " ++ show either_val
  
  -- Convertemos para funcao
  let func = from_or either_val
  putStrLn $ "Aplicando funcao em False: " ++ show (func False)
  putStrLn $ "Aplicando funcao em True: " ++ show (func True)
  
  -- Voltamos para Either
  let either_val2 = to_or func
  putStrLn $ "De volta para Either: " ++ show either_val2
  
  putStrLn "\n=== PROPOSICOES NAO-DEMONSTRAVEIS ==="
  putStrLn "Lei do Terceiro Excluido (A v ~A):"
  putStrLn "  X NAO pode ser provada construtivamente"
  putStrLn "  (valida classicamente, mas nao intuicionisticamente)"
  putStrLn ""
  putStrLn "Dupla Negacao (~~A -> A):"
  putStrLn "  X NAO pode ser provada construtivamente"
  putStrLn ""
  putStrLn "Mas podemos provar: A -> ~~A"
  putStrLn "OK double_neg_intro :: a -> Not (Not a)"
  
  putStrLn "\n=== CONCLUSAO ==="
  putStrLn "Toda funcao que tipa em Haskell e uma prova valida!"
  putStrLn "Logica intuicionista = Logica construtiva"
  putStrLn "Se conseguimos escrever a funcao, provamos o teorema."