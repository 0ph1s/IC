module Main where

-- Turnstile FSM: two states, two inputs
data State = Locked | Unlocked deriving (Show, Eq)
data Input = Coin | Push deriving (Show, Eq)

-- Transition function
transition :: State -> Input -> State
transition Locked   Coin  = Unlocked
transition Locked   Push  = Locked
transition Unlocked Coin  = Unlocked
transition Unlocked Push  = Locked

-- Run the FSM over a sequence of inputs
run :: State -> [Input] -> State
run = foldl transition

main :: IO ()
main = do
  let inputs = [Coin, Push, Push, Coin, Coin, Push]
  let final  = run Locked inputs
  putStrLn $ "Start: Locked"
  putStrLn $ "Inputs: " ++ show inputs
  putStrLn $ "Final state: " ++ show final
