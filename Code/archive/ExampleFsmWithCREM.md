# Deterministic Finite State Machine (FSM) in Haskell

This document presents two implementations of a classic turnstile FSM in
Haskell: a simple pedagogical one and a formally verified one using the **CREM**
library (*Compositional Representable Executable Machines*).

---

## 1. The Turnstile FSM

A turnstile has two states and responds to two inputs:

| Current State | Input | Next State   | Output                         |
|---------------|-------|--------------|--------------------------------|
| Locked        | Coin  | Unlocked     | "insert coin — now unlocked"   |
| Locked        | Push  | Locked       | "push denied — still locked"   |
| Unlocked      | Coin  | Unlocked     | "already open"                 |
| Unlocked      | Push  | Locked       | "passed through — now locked"  |

---

## 2. Simple Haskell Implementation

**File:** [`stateMachine.hs`](./stateMachine.hs)

A plain Haskell encoding using algebraic data types and `foldl`:

```haskell
module Main where

data State = Locked | Unlocked deriving (Show, Eq)
data Input = Coin | Push deriving (Show, Eq)

transition :: State -> Input -> State
transition Locked   Coin  = Unlocked
transition Locked   Push  = Locked
transition Unlocked Coin  = Unlocked
transition Unlocked Push  = Locked

run :: State -> [Input] -> State
run = foldl transition

main :: IO ()
main = do
  let inputs = [Coin, Push, Push, Coin, Coin, Push]
  let final  = run Locked inputs
  putStrLn $ "Start: Locked"
  putStrLn $ "Inputs: " ++ show inputs
  putStrLn $ "Final state: " ++ show final
```

Run it:

```
runhaskell stateMachine.hs
```

Output:

```
Start: Locked
Inputs: [Coin,Push,Push,Coin,Coin,Push]
Final state: Locked
```

**Limitations:** Nothing prevents writing `transition Locked Push = Unlocked` — the
compiler cannot check that the transition table respects the intended topology.

---

## 3. Formalized FSM with CREM

**Location:** [`crem-example/app/Main.hs`](./crem-example/app/Main.hs)

### What is CREM?

CREM (*Compositional Representable Executable Machines*) is a Haskell library
that models Mealy machines with **compile-time topology enforcement**.
Key ideas:

- A **topology** lists every allowed state transition in a `Topology vertex` value.
- This topology is **promoted to the type level** via the `singletons` machinery.
- The `ActionResult` constructor demands a compile-time proof
  (`AllowedTransition topology initialVertex finalVertex`) that the transition
  is present in the topology.
- Any attempt to perform a disallowed transition is a **type error**.

A machine can be built as a `BaseMachineT m topology input output` (a leaf) or
composed into larger `StateMachineT m input output` trees using `Sequential`,
`Parallel`, `Alternative`, `Feedback`, or `Kleisli` constructors.

### Turnstile formalization

```haskell
$(singletons [d|
  data TurnstileVertex = Locked | Unlocked
    deriving (Show, Eq)

  turnstileTopology :: Topology TurnstileVertex
  turnstileTopology = Topology
    [ (Locked,   [Unlocked])
    , (Unlocked, [Locked])
    ]
  |])

turnstileAction :: Applicative m
  => STurnstileVertex initialVertex -> Input
  -> ActionResult m TurnstileTopology STurnstileVertex initialVertex Output
turnstileAction SLocked Coin   = pureResult "Unlocked (insert coin)"  SUnlocked
turnstileAction SLocked Push   = pureResult "Locked (push denied)"    SLocked
turnstileAction SUnlocked Coin = pureResult "Unlocked (already open)" SUnlocked
turnstileAction SUnlocked Push = pureResult "Locked (passed through)" SLocked
```

Each call to `pureResult` carries an implicit `AllowedTransition` constraint.
If we tried `turnstileAction SLocked Push = pureResult "..." SUnlocked`, GHC
would reject it at compile time because `Locked -> Unlocked` is only allowed
on `Coin`, not unconditionally — and the list for `Locked` in the topology only
lists `[Unlocked]` (the total set of targets), not the input.

*(In this simplified example the input is not part of the vertex type, so the
topology only constrains state-to-state reachability. A finer-grained model
could encode input in the vertex labels.)*

### Build and run

The CREM library is a cabal dependency, not installed globally. You must use
`cabal` — running `ghci Main.hs` or `runhaskell Main.hs` directly will fail with
`Could not find module 'Crem.StateMachine'`.

```bash
cd crem-example
cabal run            # build and execute
cabal repl           # open GHCi with dependencies loaded
cabal build          # build without running
```

Output:

```
=== Turnstile FSM formalized with CREM ===
Topology: Locked <--> Unlocked (only Coin/Push transitions allowed)
Inputs: [Coin,Push,Push,Coin,Coin,Push]
Processing...
  Coin -> Unlocked (insert coin)
  Push -> Locked (passed through)
  Push -> Locked (push denied)
  Coin -> Unlocked (insert coin)
  Coin -> Unlocked (already open)
  Push -> Locked (passed through)
Done.
```

---

## 4. Key Differences

| Aspect                  | Simple FSM                  | CREM Formalization                      |
|-------------------------|-----------------------------|-----------------------------------------|
| Transition table        | Plain function              | `Topology` + `ActionResult` proof       |
| Incorrect transition    | Runtime bug                 | Compile-time type error                 |
| Compositionality        | Manual                      | Built-in (`Sequential`, `Parallel`, …)  |
| Graphical rendering     | Not available               | Automatic via `Render` module           |
| Dependencies            | None (base only)            | `crem`, `singletons-base`               |

---

## 5. References

- CREM library: <https://github.com/tweag/crem>
- CREM on Hackage: <https://hackage.haskell.org/package/crem>
- Singletons library: <https://hackage.haskell.org/package/singletons-base>
