type And a b = (a, b)

type Or a b = Either a b

data Void

absurd :: Void -> a
absurd v = case v of {}

type Not a = a -> Void

type Truth = ()

proj_left :: And a b -> a
proj_left (a, b) = a

proj_right :: And a b -> b
proj_right (a, b) = b

intro_and :: a -> b -> And a b
intro_and a b = (a, b)

from_or :: Or a a -> (Bool -> a)
from_or (Left a) = \_ -> a
from_or (Right a) = \_ -> a

to_or :: (Bool -> a) -> Or a a
to_or f = Left (f False)

identity :: a -> a
identity x = x

const_proof :: a -> b -> a
const_proof a b = a

s_combinator :: (a -> b -> c) -> (a -> b) -> a -> c
s_combinator f g x = f x (g x)

or_comm :: Or a b -> Or b a
or_comm (Left a) = Right a
or_comm (Right b) = Left b

and_comm :: And a b -> And b a
and_comm (a, b) = (b, a)

or_elim :: (a -> c) -> (b -> c) -> Or a b -> c
or_elim f g (Left a) = f a
or_elim f g (Right b) = g b

intro_or_left :: a -> Or a b
intro_or_left = Left

intro_or_right :: b -> Or a b
intro_or_right = Right

double_neg_intro :: a -> Not (Not a)
double_neg_intro a = \na -> na a

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
  let either_val = Left 42 :: Or Int Int
  putStrLn $ "Valor inicial: " ++ show either_val
  let func = from_or either_val
  putStrLn $ "Aplicando funcao em False: " ++ show (func False)
  putStrLn $ "Aplicando funcao em True: " ++ show (func True)
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
  putStrLn "  OK double_neg_intro :: a -> Not (Not a)"
  
  putStrLn "\n=== CONCLUSAO ==="
  putStrLn "Toda funcao que tipa em Haskell e uma prova valida!"
  putStrLn "Logica intuicionista = Logica construtiva"
  putStrLn "Se conseguimos escrever a funcao, provamos o teorema."